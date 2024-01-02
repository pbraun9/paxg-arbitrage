#!/bin/ksh
set -e

# this script needs to remain silent

# https://binance-docs.github.io/apidocs/spot/en/#current-open-orders-user_data

export LC_NUMERIC=C

. ../driftlib.bash
. ../drift.conf

[[ -z $apikey ]]	&& echo define apikey && exit 1
[[ -z $secretkey ]]	&& echo define secretkey && exit 1

function usage {
	echo
	echo "usage: ${0##*/} <PAIR>"
	echo
	exit 1
}

[[ -z $1 ]] && usage
pair=$1

time=`date +%s%3N`

sig=`echo -n "symbol=$pair&\
timestamp=$time" | openssl dgst -sha256 -hmac "$secretkey" | awk '{print $NF}'`

# this one goes GET
curl -sH "X-MBX-APIKEY: $apikey" "https://api4.binance.com/api/v3/openOrders?symbol=$pair&\
timestamp=$time&\
signature=$sig" | jq -r '.[] | .clientOrderId + "," + .side + "," + .price' 2>/dev/null

