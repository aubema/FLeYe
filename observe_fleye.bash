#!/bin/bash
#
#
#    Copyright (C) 2022  Martin Aube
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    Contact: martin.aube@cegepsherbrooke.qc.ca
#

#
# =============================
# find appropriate integration time
#
take_pictures() {
     	#  Take pictures of various integration times starting from a smaller to get the right integration time (max around 0.8)
	echo "Taking A picture"
	echo $path
	echo $cam $ta $gain
	rm -f $path"/capture_$cam*"
	/usr/bin/python3 /usr/local/bin/capture$cam.py -t $ta -g $gain
	if [ ! -f $path"/capture_$cam.dng" ]
		echo "Problem with " $cam "camera."
	fi
}





#
# ==================================
#
# main
#
#===================================
# setting constants
dayt=800
dayg=1
nightt=20000   		# 1/50s
nightg=16		# ISO 1600
user="sand"
gain=$nightg
ta=$nightt
sunset="2023-01-29T19:00:00 UTC"
sunrise="2023-01-30T06:00:00 UTC"
sset=`date -d "$sunset" "+%s"`
srise=`date -d "$sunrise" "+%s"`
cams=(A B C D)
basepath="/var/www/html/data"
backpath="/home/"$user"/data"
path="/home/"$user
#==================================
# wait 2 min to start (enough time for ntp sync)
echo "Waiting 2 min before starting measurements..."
/bin/sleep 120
start_date=`date +%Y-%m-%d_%H-%M-%S`
echo $start_date >> $path/sec_num.txt
if [ ! -f  $path/image_list.txt ]
then	echo "0 " $start_date > $path/image_list.txt
fi
while :
do 	tail -1 $path/image_list.txt > $path/seq_num.tmp 
	read secnum bidon < $path/seq_num.tmp
	time1=`date +%s`
	if [ $time1 -lt $sset ] || [ $time1 -ge $srise ]
	then 	echo "day"
		ta=$dayt
		gain=$dayg
	else	echo "night"
		ta=$nightt
		gain=$nightg
	fi
	echo "Shooting..."
	let n=0
	for cam in ${cams[@]}
	do 	take_pictures()
   		yy=`date +%Y`
   		mo=`date +%m`
		dd=`date +%d`
		basename=`date +%Y-%m-%d_%H-%M-%S`
		image=$basename"_"$cam"_"$ta"_"$gain
		image_list[$n]=$image"_"$secnum
		baseday=`date +%Y-%m-%d`
		# create directories
		if [ ! -d $basepath/$y ]
		then 	mkdir $basepath/$y
		fi
		if [ ! -d $basepath/$y/$mo ]
		then 	/bin/mkdir $basepath/$y/$mo
		fi
		if [ ! -d $backpath/$y ]
		then 	mkdir $backpath/$y
		fi
		if [ ! -d $backpath/$y/$mo ]
		then 	/bin/mkdir $backpath/$y/$mo
		fi
		echo "=============================="
		# rename pictures
		cp -f $path"/capture_$cam.dng" $basepath/$y/$mo/$image"_"$secnum".dng"
	    	cp -f $path"/capture_$cam.dng" $backpath/$y/$mo/$image"_"$secnum".dng"
		mv -f $path"/capture_$cam.jpg" $basepath/$y/$mo/$image"_"$secnum".jpg"
	    	mv -f $path"/capture_$cam.jpg" $backpath/$y/$mo/$image"_"$secnum".jpg"
		let n=n+1
	done
	let secnum=secnum+1
	echo $secnum ${image_list[@]} >> $path/image_list.txt
	cp -f $path"/image_list.txt $basepath/$y/$mo/
	cp -f $path"/image_list.txt $backpath/$y/$mo/
	time2=`date +%s`
	let idle=40-time2+time1  # one measurement every 40 sec 
	if [ $idle -lt 0 ] ; then let idle=0; fi
	echo "Wait " $idle "s before next reading."
	/bin/sleep $idle
done