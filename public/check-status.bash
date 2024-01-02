#!/bin/bash

echo
curl -s https://api.binance.com/sapi/v1/system/status | jq
echo

