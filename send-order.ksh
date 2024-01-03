#!/bin/ksh
set -e

test=1

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

# single lock - we are only buying or selling at once
# so that we do not care about trend for arbitrage

if [[ -f $base/LOCK ]]; then
	lock=`cat $base/LOCK`
	echo CANNOT $action: ON GOING TRADE
	echo -e "willing to $@\nbut got lock:\n$lock"
	echo -e "willing to $@\nbut got lock:\n$lock" | mail -s "CANNOT $action: ON-GOING TRADE" $email
	exit 1
fi

if [[ $type = MARKET ]]; then

	echo preparing an order on pair $pair -- $action $amount MARKET

	(( test == 1 )) && echo test mode enabled - exiting && exit 0

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
signature=$sig" && echo done && echo $@ > $base/LOCK

else

	echo preparing an order on pair $pair -- $action $amount LIMIT @$rate

	(( test == 1 )) && echo test mode enabled - exiting && exit 0

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
signature=$sig" && echo done && echo $@ > $base/LOCK

fi

