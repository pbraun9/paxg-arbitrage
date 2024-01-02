#!/bin/ksh
set -e

# https://developers.binance.com/docs/wallet/endpoints/all-coins-info

export LC_NUMERIC=C

. ../driftlib.bash
. ../drift.conf

[[ -z $apikey ]] && echo define apikey && exit 1
[[ -z $secretkey ]] && echo define secretkey && exit 1

time=`date +%s%3N`

echo -n sign request ...
sig=`echo -n "timestamp=$time" \
        | openssl dgst -sha256 -hmac "$secretkey" | awk '{print $NF}'` && echo done || echo FAIL

echo -n write to coins.$time.json ...
curl -sH "X-MBX-APIKEY: $apikey" \
	"https://api.binance.com/sapi/v1/capital/config/getall?timestamp=$time&signature=$sig" \
	| jq > coins.$time.json && echo -e done\\n

table=`cat coins.$time.json | jq -r '.[] | select(.free>"0" or .locked>"0") | .coin + "," + .free + "," + .locked'`
echo "$table" | while read line; do
	coin=`echo $line | cut -f1 -d,`
	free=`echo $line | cut -f2 -d,`
	locked=`echo $line | cut -f3 -d,`

	(( total = free + locked ))
	echo -e $coin\\t$total

	unset coin free locked
done
echo

echo all done
echo

