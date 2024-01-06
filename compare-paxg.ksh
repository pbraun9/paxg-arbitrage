#!/bin/ksh
set -e

export LC_NUMERIC=C

. ./driftlib.bash
. ./drift.conf

[[ ! -d $base ]]	&& bomb define base workdir in drift.conf
[[ -z $email ]]		&& bomb define email in drift.conf
[[ -z $goldapi_key ]]	&& bomb define goldapi_key in drift.conf
[[ -z $paxg_amount ]]	&& bomb define paxg_amount in drift.conf

[[ ! -x `whence jq` ]] && bomb install jq first

# this script is XAU vs. PAXG specific
pair=PAXGUSDT

date

typeset -F2 xauusd

xauusd=`lynx -cookies -dump "https://www.xe.com/currencyconverter/convert/?Amount=1&From=XAU&To=USD" \
	| grep -A2 '1.00 Gold' | tail -1 | awk '{print $1}' | sed 's/,//g'`

# goldapi
#xauusd=`curl -s "https://www.goldapi.io/api/XAU/USD" -H "x-access-token: $goldapi_key" | jq .price`

# metalprice
#xauusd=`curl -s "https://api.metalpriceapi.com/v1/latest?api_key=$metalprice_key&base=XAU&currencies=USD" | jq .rates.USD`

[[ -z $xauusd ]] && bomb could not determine xauusd
(( ! xauusd > 0 )) && bomb something went wrong while grabbing xauusd: should be a number

echo -e "xau/usd is \t\t\t $xauusd"

typeset -F2 paxgusd

#paxgusd=`lynx -cookies -dump https://finance.yahoo.com/quote/PAXG-USD/ \
#	| grep -B1 'UTC. Market' | head -1 | cut -f1 -d+ | sed 's/,//g'`

# avg 5 mins
#paxgusd=`curl -s "https://api.binance.com/api/v3/avgPrice?symbol=$pair" | jq .price -r`

# latest price
paxgusd=`curl -s "https://api.binance.com/api/v3/ticker/price?symbol=$pair" | jq .price -r`

[[ -z $paxgusd ]] && bomb could not determine paxgusd
(( ! paxgusd > 0 )) && bomb something went wrong while grabbing paxgusd: should be a number
echo -e "paxg/usd is \t\t\t $paxgusd"

# XAU is leading, PAXG is following
# therefore we care about PAXG drifts (substract xau from paxg)
typeset -F2 diff
(( diff = paxgusd - xauusd ))
echo -e drift is \\t\\t\\t $diff

[[ ! -f $base/data/paxg.txt ]] && bomb you need to redirect stdout to $base/data/paxg.txt

prep_paxg

[[ -z $paxgavg ]] && bomb could not determine paxgavg
[[ -z $paxg_variability ]] && bomb could not determine paxg_variability

typeset -F2 paxgavg
echo -e "drift average is \t\t $paxgavg"

typeset -F2 paxg_variability
echo -e drift variability is \\t\\t $paxg_variability

# we should only proceed further if paxg_variability is the same sign as drift
#if (( paxg_variability > 0 && diff > 0 )); then
#	echo OK paxg_variability and diff are both positive
#elif (( paxg_variability < 0 && diff < 0 )); then
#	echo OK paxg_variability and diff are both negative
#else
#	echo NOK paxg_variability and diff are of different sign
#	echo
#	exit 0
#fi

# in case average is opposite sign, we should still be able to handle it

# in turns, there is another way to define the drift: volatility in percent
# show how much the current drift variability differs from the current drift
# we are not comparing against the drift average paxgavg since that one can be zero (and it would be fine)
typeset -F2 volatility

if (( paxg_variability > 0 && diff > 0 )); then
	#echo OK paxg_variability and drift are both positive
	#(( volatility = paxg_variability * 100 / diff ))
	(( volatility = paxg_variability * 100 / paxgavg ))
elif (( paxg_variability < 0 && diff < 0 )); then
	#echo OK paxg_variability and drift are both negative
	#(( volatility = paxg_variability * 100 / diff ))
	(( volatility = paxg_variability * 100 / paxgavg ))
else
	echo WARN paxg_variability and drift are of different sign
	#(( volatility = -paxg_variability * 100 / diff ))
	(( volatility = -paxg_variability * 100 / paxgavg ))
fi

echo -e drift volatility is \\t\\t$volatility

if (( volatility < volatility_trigger )); then
	echo NOK volatility $volatility% lower than $volatility_trigger%
	echo
	exit 0

fi

# actual drift is negative meaning we need to buy
if (( paxg_variability < 0 )); then

	if (( paxgusd > paxg_max )); then
		echo NOK we do not buy above $paxg_max
		echo
		exit 0
	fi

	# drift variability positive hence substract
	integer target_profit_sell
	(( target_profit_sell = paxgusd - paxg_variability * 1.618 ))
	[[ -z $target_profit_sell ]] && bomb could not define target_profit_sell
	echo target_profit_sell is $target_profit_sell

	# not worth it for less than 10 e.g. buy 1980 sell 1985 with amount 0.1
	# would pay 2 x 0.14 usd as fees anyhow leaving only 0.70 usd for profit
	(( profit = target_profit_sell - paxgusd ))
	if (( profit >= 9.2 )); then
		typeset -F2 profit
		echo OK profit $profit would be above or equal to 9.2
	else
		typeset -F2 profit
		echo NOK profit $profit would be below 9.2
		echo
		exit 0
	fi

	echo BUY/MARKET @$paxgusd and SELL/LIMIT @$target_profit_sell \
		| mail -s "buy-n-sell PAXG/USDT $paxg_variability (drift $drift)" $email

	# only t/p order if market order suceeded
	echo $base/send-order.ksh $pair BUY $paxg_amount MARKET
	echo $base/send-order.ksh $pair SELL $paxg_amount $target_profit_sell
	$base/send-order.ksh $pair BUY $paxg_amount MARKET \
		&& sleep 0.3 \
		&& $base/send-order.ksh $pair SELL $paxg_amount $target_profit_sell

# actual drift is positive meaning we need to sell
elif (( paxg_variability > 0 )); then

	if (( paxgusd <= paxg_min )); then
		echo NOK we do not sell at $paxg_min and below
		echo
		exit 0
	fi

	# drift variability negative hence addition
	integer target_profit_buy
	(( target_profit_buy = paxgusd + paxg_variability * 1.618 ))
	[[ -z $target_profit_buy ]] && bomb could not define target_profit_buy
	echo target_profit_buy is $target_profit_buy

	# same as above but e.g. sell 1985 buy 1980
	(( profit = paxgusd - target_profit_buy ))
	if (( profit >= 9.2 )); then
		typeset -F2 profit
		echo OK profit $profit would be above or equal to 9.2
	else
		typeset -F2 profit
		echo NOK profit $profit would be below 9.2
		echo
		exit 0
	fi

	echo SELL/MARKET @$paxgusd and BUY/LIMIT @$target_profit_buy \
		| mail -s "sell-n-buy PAXG/USDT $paxg_variability (drift $drift)" $email

	# only t/p order if market order suceeded
	echo $base/send-order.ksh $pair SELL $paxg_amount MARKET
	echo $base/send-order.ksh $pair BUY $paxg_amount $target_profit_buy
	$base/send-order.ksh $pair SELL $paxg_amount MARKET \
		&& sleep 0.3 \
		&& $base/send-order.ksh $pair BUY $paxg_amount $target_profit_buy

else

	bomb paxg_variability cannot be zero because program should have exited while evaluating volatility

fi

echo

