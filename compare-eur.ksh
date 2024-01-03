#!/bin/ksh

export LC_NUMERIC=C

. ./driftlib.bash
. ./drift.conf

[[ ! -d $base ]] && echo define base workdir first && exit 1
[[ -z $email ]] && echo define email first && exit 1

date

[[ ! -f $base/drift.conf ]] && echo configure $base/drift.conf first && exit 1
. $base/drift.conf

eurusd=`lynx -cookies -dump https://www.google.com/finance/quote/EUR-USD \
	| sed -n '/^   Euro to United States Dollar/,/^   insightsKey events/p' \
	| grep -A1 Share | tail -1`
[[ -z $eurusd ]] && echo -e could not determine eurusd \\n && exit 1
echo -e eur/usd is \\t\\t\\t $eurusd

sleep 1
eurusdt=`lynx -cookies -dump https://www.google.com/finance/quote/EUR-USDT \
	| sed -n '/^   Euro to Tether/,/^   insightsKey events/p' \
	| grep -A1 Share | tail -1`
[[ -z $eurusdt ]] && echo -e could not determine eurusdt \\n && exit 1
echo -e eur/usdt is \\t\\t\\t $eurusdt

float diff
(( diff = eurusd - eurusdt ))
echo -e difference is \\t\\t\\t $diff

# when diff is positive, it means crypto is cheaper
(( diff >= eurpip ))  && echo -e eur/usdt $eurusdt \\neur/usd $eurusd \\n$diff greater than $eurpip \
	| mail -s "BUY EUR/USDT:$diff" $email

# when diff is negative, it means forex/metal is cheaper
(( diff <= - eurpip )) && echo -e eur/usdt $eurusdt \\neur/usd $eurusd \\n$diff lower than - $eurpip \
        | mail -s "SELL EUR/USDT:$diff" $email

echo

