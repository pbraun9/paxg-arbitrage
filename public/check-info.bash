#!/bin/bash

echo
echo -n writing to exchangeInfo.json ...
curl -s https://api.binance.com/api/v3/exchangeInfo | jq > exchangeInfo.json && echo done
echo

