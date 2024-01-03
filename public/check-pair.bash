#!/bin/bash

[[ -z $1 ]] && echo pair? && exit 1
pair=$1

echo
echo write to exchangeInfo.$pair.json ...
curl -s https://api.binance.com/api/v3/exchangeInfo?symbol=$pair | jq > exchangeInfo.$pair.json && echo done
echo

