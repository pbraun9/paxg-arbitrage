#!/bin/ksh

export LC_NUMERIC=C

. ./driftlib.bash
. ./drift.conf

[[ ! -d $base ]] && echo define base workdir first && exit 1
[[ -z $email ]] && echo define email first && exit 1

date

[[ ! -f $base/drift.conf ]] && echo configure $base/drift.conf first && exit 1
. $base/drift.conf

btcusd=`lynx -cookies -dump https://www.google.com/finance/quote/BTC-USD \
	| sed -n '/^   Bitcoin to United States Dollar/,/^   insightsKey events/p' \
	| grep -A1 Share | tail -1`
[[ -z $btcusd ]] && echo -e could not determine btcusd \\n && exit 1
echo -e btc/usd is \\t\\t\\t $btcusd

sleep 1
btcusdt=`lynx -cookies -dump https://www.google.com/finance/quote/BTC-USDT \
	| sed -n '/^   Bitcoin to Tether/,/^   insightsKey events/p' \
	| grep -A1 Share | tail -1`
[[ -z $btcusdt ]] && echo -e could not determine btcusdt \\n && exit 1
echo -e btc/usdt is \\t\\t\\t $btcusdt

float diff
(( diff = btcusd - btcusdt ))
echo -e difference is \\t\\t\\t $diff

# when diff is positive, it means crypto is cheaper
(( diff >= btcpip ))  && echo -e btc/usd $btcusd \\nbtc/usdt $btcusdt \\n$diff greater than $btcpip \
	| mail -s "BUY BTC/USDT:$diff" $email

# when diff is negative, it means forex/metal is cheaper
(( diff <= - btcpip )) && echo -e btc/usd $btcusd \\nbtc/usdt $btcusdt \\n$diff lower than - $btcpip\
	| mail -s "SELL BTC/USDT:$diff" $email

echo

