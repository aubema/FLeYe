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
	/usr/bin/echo $path
	/usr/bin/echo $cam $ta $gain
	rm -f $path"/capture_$cam*"
	/usr/bin/python3 /usr/local/bin/capture$cam.py -t $ta -g $gain
	if [ ! -f $path"/capture_$cam.dng" ]
	then	/usr/bin/echo "Problem with " $cam "camera."
		/usr/sbin/reboot
	fi
}





#
# ==================================
#
# main
#
#===================================
# setting constants
dayt=2000
dayg=1
nightt=128000   		# 0.128s
nightg=16		# ISO 1600
user="sand"
gain=$nightg
ta=$nightt
cams=(A B C D)
basepath="/var/www/html/data"
backpath="/home/"$user"/data"
path="/home/"$user
configfile=$path/FLeYe_RPI_3_config
generalconfig=$path/FLeYe_general_config
# sync time
/bin/sleep 300
#/usr/sbin/ntpdate 172.20.4.160   # SET THE RIGHT IP HERE: MASTER IP FOR THE SLAVE AND GONDOLA NTP IP FOR THE MASTER
# sync time with the master time
sudo -u sand sand@master date "+%Y-%m-%dT%H:%M:%S" > $path/master_time.txt
syncflag=`echo $?`
if [ $syncflag -eq 0 ] ; then
	read now bidon < $path/master_time.txt
	date -s $now
	echo "Time has synced with master"
else
	echo "Unable to sync time with master"
	# if time is earlier than the latest time used take the latest. 
	# The time will not be correctly set but at least will be later than other experiments.
	# read last time used
	read lastdate bidon < $path/lastdate.txt
	sec3=`/usr/bin/date +%s`
	sec4=`/usr/bin/date -d "$lastdate" +%s`
	if [ $sec4 -gt $sec3 ] ; then 
		/usr/bin/date -s $lastdate
	fi
fi
# determine sunrise and sunset
/usr/bin/grep "Delay2UTC" $generalconfig > $path/generaltmp
read bidon bidon DUTC bidon < $path/generaltmp
/usr/bin/grep "Latitude" $generalconfig > $path/generaltmp
read bidon bidon LAT bidon < $path/generaltmp
/usr/bin/grep "Longitude" $generalconfig > $path/generaltmp
read bidon bidon LON bidon < $path/generaltmp
/usr/bin/hdate -s -l $LAT -L $LON -z -$DUTC | /usr/bin/grep sunrise > $path/suntmp
read bidon value bidon < $path/suntmp
sunrise=`date --date="$value $DUTC hours" "+%Y-%m-%dT%H:%M:%S UTC"`
/usr/bin/hdate -s -l $LAT -L $LON -z -$DUTC | /usr/bin/grep sunset > $path/suntmp
read bidon value bidon < $path/suntmp
sunset=`/usr/bin/date --date="$value $DUTC hours" "+%Y-%m-%dT%H:%M:%S UTC"`
echo "Sunset= " $sunset
echo "Sunrise= " $sunrise
# convert sunset and sunrise in seconds today, yesterday and tomorrow (approximate values)
sset=`/usr/bin/date -d "$sunset" +%s`
srise=`/usr/bin/date -d "$sunrise" +%s`
now=`/usr/bin/date +%s`
let ssetbefore=sset-86400
let ssetafter=sset+86400
let srisebefore=srise-86400
let sriseafter=srise+86400
yy=`/usr/bin/date +%Y`
mo=`/usr/bin/date +%m`
dd=`/usr/bin/date +%d`
hh=`/usr/bin/date +%H`
mm=`/usr/bin/date +%-M`
ss=`/usr/bin/date +%-S`
let "nextcycle=1+(mm*60+ss)/120" 
let "wait=nextcycle*120-(mm*60+ss)"	# begin shots at the next cycle of 120 sec
/usr/bin/date
/usr/bin/echo "Waiting " $wait " seconds"
/bin/sleep $wait  
start_date=`/usr/bin/date +%Y-%m-%d_%H-%M-%S`
/usr/bin/echo $start_date >> $path/sec_num.txt
if [ ! -f  $path/image_list.txt ]
then	/usr/bin/echo "0 " $start_date > $path/image_list.txt
fi
while :
do 	time1=`/usr/bin/date +%s`
	tail -1 $path/image_list.txt > $path/seq_num.tmp 
	read secnum bidon < $path/seq_num.tmp
	if [[ $time1 -lt $sset  &&  $time1 -ge $srise ]] || [[ $time1 -lt $ssetbefore  &&  $time1 -ge $srisebefore ]] || [[ $time1 -lt $ssetafter &&  $time1 -ge $sriseafter ]]
	then 	/usr/bin/echo "day"
		tai=$dayt
		gain=$dayg
		fstop=2
		/usr/bin/echo "You are observing during daytime"
	else	/usr/bin/echo "night"
		tai=$nightt
		gain=$nightg
		fstop=20
		/usr/bin/echo "You are observing during nighttime"
	fi
	/usr/bin/echo "Shooting..."
	for f in 1 2 3
	do	let factor=(2*fstop)**f
		let ta=tai/factor
		let n=0
		for cam in ${cams[@]}
		do /usr/bin/grep "Lens"$cam $configfile > $path/lenstmp
			read bidon bidon lens bidon < $path/lenstmp
			/usr/bin/grep "Posi"$cam $configfile> $path/positmp
			read bidon bidon posi bidon < $path/positmp
			/usr/bin/date +%Y-%m-%dT%H:%M:%S > $path/lastdate.txt
			take_pictures "$cam" "$gain" "$ta"
   		yy=`/usr/bin/date +%Y`
   		mo=`/usr/bin/date +%m`
			dd=`/usr/bin/date +%d`
			basename=`/usr/bin/date +%Y-%m-%d_%H-%M-%S`
			image=$basename"_"$cam"_"$lens"_"$posi"_"$ta"_"$gain
			image_list[$n]=$secnum"_"$image
			baseday=`/usr/bin/date +%Y-%m-%d`
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
			/usr/bin/echo "=============================="
			# renaming pictures
			/usr/bin/cp -f $path"/capture_"$cam".dng" $basepath/$yy/$mo/$secnum"_"$image".dng"
			/usr/bin/cp -f $path"/capture_"$cam".dng" $backpath/$yy/$mo/$secnum"_"$image".dng"
			/usr/bin/cp -f $path"/capture_"$cam".jpg" $basepath/$yy/$mo/$secnum"_"$image".jpg"
			/usr/bin/cp -f $path"/capture_"$cam".jpg" $backpath/$yy/$mo/$secnum"_"$image".jpg"
			/usr/bin/convert $path"/capture_"$cam".jpg" -resize 1080 $path"/small_"$cam"_"$f".jpg"
			/usr/bin/cp -f $path"/small_"$cam"_"$f".jpg" $basepath/
			let n=n+1
		done
		# flush ram cache to correct a memory leak in the camera library
		/usr/bin/sync
		/usr/bin/echo 3 > /proc/sys/vm/drop_caches
		let secnum=secnum+1
		# write data to the image_list.txt file
		/usr/bin/echo $secnum ${image_list[@]} >> $path/image_list.txt
		cp -f $path"/image_list.txt" $basepath/$yy/$mo/
		cp -f $path"/image_list.txt" $backpath/$yy/$mo/
	done
	# calculate waiting time until next shooting
	mm=`/usr/bin/date +%-M`
	ss=`/usr/bin/date +%-S`
	let "nextcycle=1+(mm*60+ss)/120" 
	let "idle=nextcycle*120-(mm*60+ss)"	# begin shots at the next cycle of 120 sec
	if [ $idle -lt 0 ]
	then 	let idle=0
		/usr/sbin/reboot
	fi
	/usr/bin/echo "Wait " $idle "s before next reading."
	/bin/sleep $idle
done
