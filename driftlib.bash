
function bomb {
        echo
        echo error: $@
        echo
        exit 1
}

function prep_btc {
        btcvalues=`grep '^difference is' $base/data/btc.txt | awk '{print $NF}' | tail -100`

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
        eurvalues=`grep '^difference is' $base/data/eur.txt | awk '{print $NF}' | tail -100`

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

function prep_xau {
        xauvalues=`grep '^difference is' $base/data/xau-paxg.txt | awk '{print $NF}' | tail -100`

        (( xaulast = `echo "$xauvalues" | tail -1` ))
        (( xauhigh = `echo "$xauvalues" | sort -n | tail -1` ))
        (( xaulow =  `echo "$xauvalues" | sort -n | head -1` ))

        xauvalues_positive=`echo "$xauvalues" | sed -r 's/^-.*/0/'`
        xauvalues_no_negative=`echo "$xauvalues" | sed -r 's/^[^-].*/0/' | sed 's/-//g'`

        tmp=`echo "$xauvalues" | sed 's/$/ +/'`
        tmp2=`echo $tmp | sed 's/ +$//'`
        lines=`echo "$tmp" | wc -l`
        (( xauavg = ( $tmp2 ) / lines ))
        unset tmp tmp2 lines

        (( xau_variability = xaulast - xauavg ))
}

