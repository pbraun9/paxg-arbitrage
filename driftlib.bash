
function bomb {
        echo
        echo error: $@
        echo
        exit 1
}

function prep_btc {
        btcvalues=`grep '^drift is' $base/data/btc.txt | awk '{print $NF}' | tail -100`

        (( btclast = `echo "$btcvalues" | tail -1` ))
        (( btchigh = `echo "$btcvalues" | sort -n | tail -1` ))
        (( btclow =  `echo "$btcvalues" | sort -n | head -1` ))

        btcvalues_positive=`echo "$btcvalues" | sed -r 's/^-.*/0/'`
        btcvalues_no_negative=`echo "$btcvalues" | sed -r 's/^[^-].*/0/' | sed 's/-//g'`

        tmp=`echo "$btcvalues" | sed 's/$/ +/'`
        tmp2=`echo $tmp | sed 's/ +$//'`
        lines=`echo "$tmp" | wc -l`
        (( btcavg = ( $tmp2 ) / lines ))
        unset tmp tmp2 lines

        (( btc_variability = btclast - btcavg ))
}

function prep_eur {
        eurvalues=`grep '^drift is' $base/data/eur.txt | awk '{print $NF}' | tail -100`

        (( eurlast = `echo "$eurvalues" | tail -1` ))
        (( eurhigh = `echo "$eurvalues" | sort -n | tail -1` ))
        (( eurlow =  `echo "$eurvalues" | sort -n | head -1` ))

        eurvalues_positive=`echo "$eurvalues" | sed -r 's/^-.*/0/'`
        eurvalues_no_negative=`echo "$eurvalues" | sed -r 's/^[^-].*/0/' | sed 's/-//g'`

        tmp=`echo "$eurvalues" | sed 's/$/ +/'`
        tmp2=`echo $tmp | sed 's/ +$//'`
        lines=`echo "$tmp" | wc -l`
        (( euravg = ( $tmp2 ) / lines ))
        unset tmp tmp2 lines

        (( eur_variability = eurlast - euravg ))
}

function prep_paxg {
        paxgvalues=`grep '^drift is' $base/data/paxg.txt | awk '{print $NF}' | tail -100`

	[[ -z $paxgvalues ]] && bomb unable to define paxgvalues
	(( `echo "$paxgvalues" | wc -l` <= 5 )) && echo -e not enough data just yet\\n && exit 0

        (( paxglast = `echo "$paxgvalues" | tail -1` ))
        (( paxghigh = `echo "$paxgvalues" | sort -n | tail -1` ))
        (( paxglow =  `echo "$paxgvalues" | sort -n | head -1` ))

        paxgvalues_positive=`echo "$paxgvalues" | sed -r 's/^-.*/0/'`
        paxgvalues_no_negative=`echo "$paxgvalues" | sed -r 's/^[^-].*/0/' | sed 's/-//g'`

        tmp=`echo "$paxgvalues" | sed 's/$/ +/'`
        tmp2=`echo $tmp | sed 's/ +$//'`
        lines=`echo "$tmp" | wc -l`
        (( paxgavg = ( $tmp2 ) / lines ))
        unset tmp tmp2 lines

        (( paxg_variability = paxglast - paxgavg ))
}

