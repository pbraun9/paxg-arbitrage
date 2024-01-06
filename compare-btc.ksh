#!/bin/ksh

export LC_NUMERIC=C

. ./driftlib.bash
. ./drift.conf

[[ ! -d $base ]] && echo define base workdir first && exit 1
[[ -z $email ]] && echo define email first && exit 1

date

[[ ! -f $base/drift.conf ]] && echo configure $base/drift.conf first && exit 1
. $base/drift.conf

btcusdt=`lynx -cookies -dump https://www.google.com/finance/quote/BTC-USDT \
	| sed -n '/^   Bitcoin to Tether/,/^   insightsKey events/p' \
	| grep -A1 Share | tail -1`
[[ -z $btcusdt ]] && echo -e could not determine btcusdt \\n && exit 1
echo -e btc/usdt is \\t\\t\\t $btcusdt

sleep 1
btcusd=`lynx -cookies -dump https://www.google.com/finance/quote/BTC-USD \
	| sed -n '/^   Bitcoin to United States Dollar/,/^   insightsKey events/p' \
	| grep -A1 Share | tail -1`
[[ -z $btcusd ]] && echo -e could not determine btcusd \\n && exit 1
echo -e btc/usd is \\t\\t\\t $btcusd

# crypto/crypto is leading, crypto/fiat is following
# therfore we care about btc/usd drift (substract btc/usdt from btc/usd)
float diff
(( diff = btcusd - btcusdt ))
echo -e drift is \\t\\t\\t $diff

# crypto/fiat drift is high, we sell
(( diff >= btcpip ))  && echo -e btc/usdt \\t$btcusdt \\nbtc/usd \\t$btcusd \\n$diff \\ntrigger \\t$btcpip \
	| mail -s "SELL BTC/USD ($diff)" $email

# crypto/fiat drift is low, we buy
(( diff <= -btcpip )) && echo -e btc/usdt \\t$btcusdt \\nbtc/usd \\t$btcusd \\n$diff \\ntrigger \\t-$btcpip \
	| mail -s "BUY BTC/USD ($diff)" $email

echo

