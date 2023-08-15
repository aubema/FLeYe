#!/bin/bash
while :
do 
        ls -l ~ | grep last_images > toto
        read bidon bidon bidon bidon bidon mymonth myday  mytime bidon < toto
        now=`date +%s`
        last=`date --date "$mymonth $myday $mytime" +%s`
        let delay=now-last
        if [ $delay -gt 300 ]
                then clear
                echo "PROBLEM"
        else
                ls -la ~/last_images/
        fi
        sleep 10
done
