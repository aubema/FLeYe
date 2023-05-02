#!/bin/bash
#
#
#    Copyright (C) 2023  Martin Aube
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
	cam=$1
	gain=$2
	ta=$3
	echo $path
	echo $cam $ta $gain
	rm -f $path"/capture_$cam*"
	/usr/bin/python3 /usr/local/bin/capture$cam.py -t $ta -g $gain
	if [ ! -f $path"/capture_$cam.dng" ]
	then	echo "Problem with " $cam "camera."
		reboot
	fi
}





#
# ==================================
#
# main
#
#===================================
# setting constants
dayt=20000
dayg=16
nightt=20000   		# 1/50s
nightg=16		# ISO 1600
user="sand"
gain=$nightg
ta=$nightt
cams=(A B C D)
basepath="/var/www/html/data"
backpath="/home/"$user"/data"
path="/home/"$user
configfile=$path/FLeYe_RPI_1_config
generalconfig=$path/FLeYe_general_config
# determine sunrise and sunset
grep "Delay2UTC" $generalconfig > $path/generaltmp
read bidon bidon DUTC bidon < $path/generaltmp
grep "Latitude" $generalconfig > $path/generaltmp
read bidon bidon LAT bidon < $path/generaltmp
grep "Longitude" $generalconfig > $path/generaltmp
read bidon bidon LON bidon < $path/generaltmp


/usr/bin/hdate -s -l $LAT -L $LON -z -$DUTC | grep sunrise > $path/suntmp
read bidon value bidon < $path/suntmp


echo "rise" $value

sunrise=`date --date="$value $DUTC hours" "+%Y-%m-%dT%H:%M:%S UTC"`
/usr/bin/hdate -s -l $LAT -L $LON -z -$DUTC | grep sunset > $path/suntmp
read bidon value bidon < $path/suntmp


echo "set" $value


sunset=`date --date="$value $DUTC hours" "+%Y-%m-%dT%H:%M:%S UTC"`
echo "Sunset= " $sunset
echo "Sunrise= " $sunrise
# convert sunset and sunrise in seconds today, yesterday and tomorrow (approximate values)
sset=`date -d "$sunset" +%s`
srise=`date -d "$sunrise" +%s`
now=`date +%s`
let ssetbefore=sset-86400
let ssetafter=sset+86400
let srisebefore=srise-86400
let sriseafter=srise+86400


yy=`date +%Y`
mo=`date +%m`
dd=`date +%d`
hh=`date +%H`
mm=`date +%M`
mm=${mm##+(0)}		# remove leading 0
if [ "$mm" == "09" ]; then let mm=9; fi   # seem to be a bug with 09???
let nextmm=mm+1
if [ $nextmm -lt 10 ]
then nextmm="0"$nextmm
fi
secnow=`date +%s`
secnextmin=`date -d "$yy-$mo-$dd"T"$hh:$nextmm:00 UTC" +%s`

let wait=secnextmin-secnow		# begin shots at the next minute
date
echo "Waiting " $wait " seconds"
/bin/sleep $wait  


start_date=`date +%Y-%m-%d_%H-%M-%S`
echo $start_date >> $path/sec_num.txt
if [ ! -f  $path/image_list.txt ]
then	echo "0 " $start_date > $path/image_list.txt
fi
while :
do 	time1=`date +%s`
	tail -1 $path/image_list.txt > $path/seq_num.tmp 
	read secnum bidon < $path/seq_num.tmp
	if [[ $time1 -lt $sset  &&  $time1 -ge $srise ]] || [[ $time1 -lt $ssetbefore  &&  $time1 -ge $srisebefore ]] || [[ $time1 -lt $ssetafter &&  $time1 -ge $sriseafter ]]
	then 	echo "day"
		ta=$dayt
		gain=$dayg
		echo "You are observing during daytime"
	else	echo "night"
		ta=$nightt
		gain=$nightg
		echo "You are observig during nighttime"
	fi
	echo "Shooting..."
	let n=0
	for cam in ${cams[@]}
	do 	grep "Lens"$cam $configfile > $path/lenstmp
		read bidon bidon lens bidon < $path/lenstmp
		grep "Posi"$cam $configfile> $path/positmp
		read bidon bidon posi bidon < $path/positmp
		take_pictures "$cam" "$gain" "$ta"
   		yy=`date +%Y`
   		mo=`date +%m`
		dd=`date +%d`
		basename=`date +%Y-%m-%d_%H-%M-%S`
		image=$basename"_"$cam"_"$lens"_"$posi"_"$ta"_"$gain
		image_list[$n]=$image"_"$secnum
		baseday=`date +%Y-%m-%d`
		# create directories
		if [ ! -d $basepath/$yy ]
		then 	mkdir $basepath/$yy
		fi
		if [ ! -d $basepath/$yy/$mo ]
		then 	/bin/mkdir $basepath/$yy/$mo
		fi
		if [ ! -d $backpath/$yy ]
		then 	mkdir $backpath/$yy
		fi
		if [ ! -d $backpath/$yy/$mo ]
		then 	/bin/mkdir $backpath/$yy/$mo
		fi
		echo "=============================="
		# renaming pictures
		cp -f $path"/capture_"$cam".dng" $basepath/$yy/$mo/$image"_"$secnum".dng"
	    	mv -f $path"/capture_"$cam".dng" $backpath/$yy/$mo/$image"_"$secnum".dng"
		cp -f $path"/capture_"$cam".jpg" $basepath/$yy/$mo/$image"_"$secnum".jpg"
	    	mv -f $path"/capture_"$cam".jpg" $backpath/$yy/$mo/$image"_"$secnum".jpg"
		let n=n+1
	done
	# flush ram cache to correct a memory leak in the camera library
	sync
	echo 3 > /proc/sys/vm/drop_caches
	let secnum=secnum+1
	# write data to the image_list.txt file
	echo $secnum ${image_list[@]} >> $path/image_list.txt
	cp -f $path"/image_list.txt" $basepath/$yy/$mo/
	cp -f $path"/image_list.txt" $backpath/$yy/$mo/
	# calculate waiting time until next shooting
	time2=`date +%s`
	let idle=60-time2+time1  # one measurement every 60 sec 
	if [ $idle -lt 0 ]
	then 	let idle=0
		# ici reboot? Si je ne reussis pas a regler le jam de l acquisition d images
	fi
	echo "Wait " $idle "s before next reading."
	/bin/sleep $idle
done