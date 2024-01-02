#!/bin/ksh
set -e

(( debug = 1 ))

. ./driftlib.bash
. ./drift.conf

[[ ! -d $base ]] && bomb define base workdir

export LC_NUMERIC=C

# https://git.zx2c4.com/spark/plain/spark.c
[[ ! -x `whence spark` ]] && bomb spark executable not found

while true; do
	prep_xau
	prep_btc
	prep_eur

	# we can only fix the amount of decimals once the variable has been set
	# besides, we need to apply this to the same function where the value gets printed

	typeset -F 2 xaulast
	typeset -F 2 xauhigh
	typeset -F 2 xaulow
	typeset -F 2 xauavg
	typeset -F 2 xau_variability

	typeset -F 2 btclast
	typeset -F 2 btchigh
	typeset -F 2 btclow
	typeset -F 2 btcavg
	typeset -F 2 btc_variability

	typeset -F 4 eurlast
	typeset -F 4 eurhigh
	typeset -F 4 eurlow
	typeset -F 4 euravg
	typeset -F 4 eur_variability

	# define max/trigger value to avoid 0 0 0 to show up as full bars
	# get rid of the floating point

	# TODO use floats in drift.conf

	typeset -F 2 xau_pip1
	(( `echo $xauhigh | sed 's/\.//g'` > xau_pip )) && (( xau_pip1 = xauhigh ))
	spark_xau_values_positive=`echo $xau_pip1 $xauvalues_positive | sed 's/\.//g'`
	spark_btc_values_positive=`echo $btc_pip $btcvalues_positive | sed 's/\.//g'`
	spark_eur_values_positive=`echo $eur_pip $eurvalues_positive | sed 's/\.//g'`

	# get rid of the first bar
	spark_xau_positive=`spark $spark_xau_values_positive | sed 's/^...//'`
	spark_btc_positive=`spark $spark_btc_values_positive | sed 's/^...//'`
	spark_eur_positive=`spark $spark_eur_values_positive | sed 's/^...//'`

	spark_xau_values_no_negative=`echo $xau_pip $xauvalues_no_negative | sed 's/\.//g'`
	spark_btc_values_no_negative=`echo $btc_pip $btcvalues_no_negative | sed 's/\.//g'`
	spark_eur_values_no_negative=`echo $eur_pip $eurvalues_no_negative | sed 's/\.//g'`

	spark_xau_no_negative=`spark $spark_xau_values_no_negative | sed 's/^...//'`
	spark_btc_no_negative=`spark $spark_btc_values_no_negative | sed 's/^...//'`
	spark_eur_no_negative=`spark $spark_eur_values_no_negative | sed 's/^...//'`

	clear
	echo
	echo " drifts between forex/metals and crypto"
	echo " timeframe 5 minutes - window 100 units"
	echo " --------------------------------------"
	echo

	(( xaulast >= xaupip )) && color='\033[1;32m' || color='\033[1m'	# crypto underrated
	(( xaulast <= -xaupip )) && color='\033[1;31m' || color='\033[1m'	# crypto overrated
	(( xau_variability > variability )) && color2='\033[1;32m' || color2='\033[1m'	# SELL action
	(( xau_variability < -variability )) && color2='\033[1;31m' || color2='\033[1m'	# BUY action
	echo -e " XAU/USD drift $color$xaulast\033[0m ($color2$xau_variability\033[0m) - high $xauhigh - avg $xauavg - low $xaulow"
	echo -e " \033[32m$spark_xau_positive\033[0m"
	echo -e " \033[31m$spark_xau_no_negative\033[0m"
	echo

	(( btclast >= btcpip )) && color='\033[1;32m' || color='\033[1m'	# crypto underrated
	(( btclast <= -btcpip )) && color='\033[1;31m' || color='\033[1m'	# crypto overrated
	echo -e " BTC/USD drift \033[1m$btclast\033[0m ($btc_variability) - high $btchigh - avg $btcavg - low $btclow"
	echo -e " \033[32m$spark_btc_positive\033[0m"
	echo -e " \033[31m$spark_btc_no_negative\033[0m"
	echo

	(( eurlast >= eurpip )) && color='\033[1;32m' || color='\033[1m'	# crypto underrated
	(( eurlast <= -eurpip )) && color='\033[1;31m' || color='\033[1m'	# crypto overrated
	echo -e " EUR/USD drift \033[1m$eurlast\033[0m ($eur_variability) - high $eurhigh - avg $euravg - low $eurlow"
	echo -e " \033[32m$spark_eur_positive\033[0m"
	echo -e " \033[31m$spark_eur_no_negative\033[0m"
	echo

	if (( debug > 0 )); then
		echo DEBUG XAU $xauvalues_positive
		echo DEBUG XAU $spark_xau_values_positive
		echo

		echo DEBUG XAU $xauvalues_no_negative
		echo DEBUG XAU $spark_xau_values_no_negative
		echo

		#echo DEBUG BTC $spark_btc_values_positive
		#echo DEBUG BTC $spark_btc_values_no_negative
		#echo
		#echo DEBUG EUR $spark_eur_values_positive
		#echo DEBUG EUR $spark_eur_values_no_negative
		#echo
	fi

	unset spark_xau spark_xau_values
	unset spark_btc spark_btc_values
	unset spark_eur spark_eur_values
	sleep 1
done

