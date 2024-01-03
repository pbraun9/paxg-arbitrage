#!/bin/ksh
set -e

. ./driftlib.bash
. ./drift.conf

[[ ! -d $base ]]	&& bomb define base workdir in drift.conf
[[ -z $email ]]		&& bomb define email in drift.conf
[[ -z $goldapi_key ]]	&& bomb define goldapi_key in drift.conf
[[ -z $paxg_amount ]]	&& bomb define paxg_amount in drift.conf

[[ ! -x `whence jq` ]] && bomb install jq first

export LC_NUMERIC=C

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

typeset -F2 diff
(( diff = xauusd - paxgusd ))
echo -e "difference is \t\t\t $diff"

[[ ! -f $base/data/xau-paxg.txt ]] && bomb you need to redirect stdout to $base/data/xau-paxg.txt

prep_xau

[[ -z $xauavg ]] && bomb could not determine xauavg
[[ -z $xau_variability ]] && bomb could not determine xau_variability

typeset -F2 xauavg
echo -e "difference average is \t\t $xauavg"

typeset -F2 xau_variability
echo -e difference variability is \\t $xau_variability

# we should only proceed further if xau_variability is the same sign as difference
#if (( xau_variability > 0 && diff > 0 )); then
#	echo OK xau_variability and diff are both positive
#elif (( xau_variability < 0 && diff < 0 )); then
#	echo OK xau_variability and diff are both negative
#else
#	echo NOK xau_variability and diff are of different sign
#	echo
#	exit 0
#fi

# in case average is opposite sign, we should still be able to handle it

# in turns, there is another way to define the drift: volatility in percent
# show how much the current difference variability differs from the current drift
# we are not comparing against the drift average xauavg since that one can be zero (and it would be fine)
typeset -F2 volatility
(( volatility = xau_variability * 100 / diff ))

if (( volatility > 22.5 )); then

	echo OK volatility $volatility% higher or equal to 22.5%

else

	echo NOK volatility $volatility% lower than 22.5%
	echo
	exit 0

fi

# single lock - we are only buying or selling at once for arbitrage
# and we do not care about the trend

# diff avg metal price is higher than crypto, we are buying
if (( xau_variability > 0 )); then

	if (( paxgusd >= 2008 )); then
		echo NOK we do not buy >= 2008
		echo
		exit 0
	fi

	# difference variability positive hence substract
	integer target_profit_sell
	(( target_profit_sell = paxgusd - xau_variability * 1.618 ))
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

	# only t/p order if market order suceeded
	echo $base/send-order.ksh $pair BUY $paxg_amount MARKET
	echo $base/send-order.ksh $pair SELL $paxg_amount $target_profit_sell
	$base/send-order.ksh $pair BUY $paxg_amount MARKET \
		&& sleep 0.3 \
		&& $base/send-order.ksh $pair SELL $paxg_amount $target_profit_sell

	echo BUY/MARKET @$paxgusd and SELL/LIMIT @$target_profit_sell \
		| mail -s "TRADE BUY-AND-SELL PAXG/USDT $diff ($xau_variability)" $email

# diff avg metal price is lower than crypto, we are selling
elif (( xau_variability < 0 )); then

	if (( paxgusd <= 1954 )); then
		echo NOK we do not sell <= 1954
		echo
		exit 0
	fi

	# difference variability negative hence addition
	integer target_profit_buy
	(( target_profit_buy = paxgusd + xau_variability * 1.618 ))
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

	# only t/p order if market order suceeded
	echo $base/send-order.ksh $pair SELL $paxg_amount MARKET
	echo $base/send-order.ksh $pair BUY $paxg_amount $target_profit_buy
	$base/send-order.ksh $pair SELL $paxg_amount MARKET \
		&& sleep 0.3 \
		&& $base/send-order.ksh $pair BUY $paxg_amount $target_profit_buy

	echo SELL/MARKET @$paxgusd and BUY/LIMIT @$target_profit_buy \
		| mail -s "TRADE SELL-AND-BUY PAXG/USDT $diff ($xau_variability)" $email

else

	bomb xau_variability cannot be zero because program should have exited while evaluating volatility

fi

echo

