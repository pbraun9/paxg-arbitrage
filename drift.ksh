#!/bin/ksh
set -e

(( debug = 0 ))

export LC_NUMERIC=C

. ./driftlib.bash
. ./drift.conf

[[ ! -d $base ]] && bomb define base workdir

# https://git.zx2c4.com/spark/plain/spark.c
[[ ! -x `whence spark` ]] && bomb spark executable not found

while true; do
	prep_paxg
	prep_btc
	prep_eur

	# we can only fix the amount of decimals once the variable has been set
	# besides, we need to apply this to the same function where the value gets printed

	typeset -F 2 paxglast
	typeset -F 2 paxghigh
	typeset -F 2 paxglow
	typeset -F 2 paxgavg
	typeset -F 2 paxg_variability

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

	# get rid of the floating point
	# TODO use floats in drift.conf

	# define max/trigger value to dispose the chart at its best
	# and to avoid 0 0 0 to show up as full bars
	#if (( `echo $paxghigh | sed 's/\.//g'` == 0  )); then
	#	(( paxg_pipfix = paxg_pip ))

	# starting the spark with a lower bar makes the rest of it higher
	# avoid that lower bar
	if (( paxghigh > paxgpip )); then
		(( paxg_pipfix = `echo $paxghigh | sed 's/\.//g'` ))
	else
		(( paxg_pipfix = paxg_pip ))
	fi

	spark_paxg_values_positive=`echo $paxg_pipfix $paxgvalues_positive | sed 's/\.//g'`
	spark_btc_values_positive=`echo $btc_pip $btcvalues_positive | sed 's/\.//g'`
	spark_eur_values_positive=`echo $eur_pip $eurvalues_positive | sed 's/\.//g'`

	# get rid of the first bar
	spark_paxg_positive=`spark $spark_paxg_values_positive | sed 's/^...//'`
	spark_btc_positive=`spark $spark_btc_values_positive | sed 's/^...//'`
	spark_eur_positive=`spark $spark_eur_values_positive | sed 's/^...//'`

	spark_paxg_values_no_negative=`echo $paxg_pipfix $paxgvalues_no_negative | sed 's/\.//g'`
	spark_btc_values_no_negative=`echo $btc_pip $btcvalues_no_negative | sed 's/\.//g'`
	spark_eur_values_no_negative=`echo $eur_pip $eurvalues_no_negative | sed 's/\.//g'`

	spark_paxg_no_negative=`spark $spark_paxg_values_no_negative | sed 's/^...//'`
	spark_btc_no_negative=`spark $spark_btc_values_no_negative | sed 's/^...//'`
	spark_eur_no_negative=`spark $spark_eur_values_no_negative | sed 's/^...//'`

	clear
	echo
	echo " drifts between forex/metals and crypto"
	echo " timeframe 5 minutes - window 100 units"
	echo " --------------------------------------"
	echo

	(( paxglast >= paxgpip )) && color='\033[1;32m' || color='\033[1m'
	(( paxglast <= -paxgpip )) && color='\033[1;31m' || color='\033[1m'
	(( paxg_variability > variability )) && color2='\033[1;32m' || color2='\033[1m'
	(( paxg_variability < -variability )) && color2='\033[1;31m' || color2='\033[1m'
	# metal leads - we look at crypto drift
	echo -e " PAXG/USDT drift vs. XAU/USD $color2$paxg_variability\033[0m - last $color$paxglast\033[0m - high $paxghigh - avg $paxgavg - low $paxglow"
	echo -e " \033[32m$spark_paxg_positive\033[0m"
	echo -e " \033[31m$spark_paxg_no_negative\033[0m"
	echo

	(( btclast >= btcpip )) && color='\033[1;32m' || color='\033[1m'
	(( btclast <= -btcpip )) && color='\033[1;31m' || color='\033[1m'
	# crypto leads - we look at forex drift
	echo -e " BTC/USD drift vs. BTC/USDT $btc_variability - last \033[1m$btclast\033[0m - high $btchigh - avg $btcavg - low $btclow"
	echo -e " \033[32m$spark_btc_positive\033[0m"
	echo -e " \033[31m$spark_btc_no_negative\033[0m"
	echo

	(( eurlast >= eurpip )) && color='\033[1;32m' || color='\033[1m'
	(( eurlast <= -eurpip )) && color='\033[1;31m' || color='\033[1m'
	# forex leads - we look at crypto drift
	echo -e " EUR/USD drift vs. EUR/USDT $eur_variability - last \033[1m$eurlast\033[0m - high $eurhigh - avg $euravg - low $eurlow"
	echo -e " \033[32m$spark_eur_positive\033[0m"
	echo -e " \033[31m$spark_eur_no_negative\033[0m"
	echo

	if (( debug > 0 )); then
		echo DEBUG PAXG $spark_paxg_values_positive
		echo DEBUG PAXG $spark_paxg_values_no_negative
		echo

		echo DEBUG BTC $spark_btc_values_positive
		echo DEBUG BTC $spark_btc_values_no_negative
		echo

		echo DEBUG EUR $spark_eur_values_positive
		echo DEBUG EUR $spark_eur_values_no_negative
		echo
	fi

	unset spark_paxg spark_paxg_values
	unset spark_btc spark_btc_values
	unset spark_eur spark_eur_values
	sleep 1
done

