#!/bin/ksh
set -e

(( dummy = 0 ))

export LC_NUMERIC=C

. ./driftlib.bash
. ./drift.conf

[[ -z $apikey ]]	&& bomb define apikey in drift.conf
[[ -z $secretkey ]]	&& bomb define secretkey in drift.conf

function usage {
	echo
	echo "usage: ${0##*/} <PAIR> <BUY|SELL> <AMOUNT> <RATE or MARKET>"
	echo
	exit 1
}

[[ -z $4 ]] && usage
pair=$1
action=$2
amount=$3

if [[ $4 = MARKET ]]; then
	type=MARKET
else
	type=LIMIT
	rate=$4
fi
time=`date +%s%3N`

existing_trades=`$base/current-open-orders.ksh PAXGUSDT | grep -v ^web_`

if (( `echo "$existing_trades" | wc -l` > paxg_trades )); then
	echo cannot $action: too many pending trades
	echo "$existing_trades"
	echo "$existing_trades" | mail -s "cannot $action: too many pending trades" $email
	exit 1
fi

if [[ $type = MARKET ]]; then

	echo preparing an order on pair $pair -- $action $amount MARKET

	(( dummy == 1 )) && echo dummy mode enabled - exiting && exit 0

	echo -n signing ...
	sig=`echo -n "symbol=$pair&\
side=$action&\
type=MARKET&\
quantity=$amount&\
timestamp=$time" | openssl dgst -sha256 -hmac "$secretkey" | awk '{print $NF}'` && echo done

	echo placing an order on pair $pair -- $action $amount MARKET
	curl -sH "X-MBX-APIKEY: $apikey" -X POST 'https://api.binance.com/api/v3/order' -d "symbol=$pair&\
side=$action&\
type=MARKET&\
quantity=$amount&\
timestamp=$time&\
signature=$sig" && echo done

else

	echo preparing an order on pair $pair -- $action $amount LIMIT @$rate

	(( dummy == 1 )) && echo dummy mode enabled - exiting && exit 0

	echo -n signing ...
	sig=`echo -n "symbol=$pair&\
side=$action&\
type=LIMIT&\
timeInForce=GTC&\
quantity=$amount&\
price=$rate&\
timestamp=$time" | openssl dgst -sha256 -hmac "$secretkey" | awk '{print $NF}'` && echo done

	echo placing an order on pair $pair -- $action $amount LIMIT $rate
	curl -sH "X-MBX-APIKEY: $apikey" -X POST 'https://api.binance.com/api/v3/order' -d "symbol=$pair&\
side=$action&\
type=LIMIT&\
timeInForce=GTC&\
quantity=$amount&\
price=$rate&\
timestamp=$time&\
signature=$sig" && echo done

fi

