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


# ==================================
# global positioning system
globalpos () {

     rm -f /root/*.tmp
     bash -c '/usr/bin/gpspipe -w -n 5 | sed -e "s/,/\n/g" | grep lat | tail -1 | sed "s/n\"/ /g" |sed -e "s/\"/ /g" | sed -e "s/:/ /g" | sed -e"s/lat//g" | sed -e "s/ //g" > /home/sand/coords.tmp'
     read lat < /home/sand/coords.tmp
     bash -c '/usr/bin/gpspipe -w -n 5 | sed -e "s/,/\n/g" | grep lon | tail -1 | sed "s/n\"/ /g" |sed -e "s/\"/ /g" | sed -e "s/:/ /g" | sed -e "s/lo//g" | sed -e "s/ //g" > /home/sand/coords.tmp'
     read lon < /home/sand/coords.tmp
     bash -c '/usr/bin/gpspipe -w -n 5 | sed -e "s/,/\n/g" | grep alt | tail -1 | sed "s/n\"/ /g" |sed -e "s/\"/ /g" | sed -e "s/:/ /g" | sed -e "s/alt//g" | sed -e "s/ //g" > /home/sand/coords.tmp'
     read alt < /home/sand/coords.tmp
     echo $lat $lon $alt
     if [ -z "${lon}" ]
     then let lon=0
          let lat=0
          let alt=0
     fi 
     # /bin/echo "GPS gives Latitude:" $lat ", Longitude:" $lon "and Altitude:" $alt
     /bin/echo "Lat.:" $lat ", Lon.:" $lon " Alt.:" $alt  > /home/sand/gps.log
     echo $gpsdate > /home/sand/date_gps.log
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
# start gps
sudo gpsd /dev/serial0 -F /var/run/gpsd.sock
# sync time
ntpdate 172.20.4.230   # SET THE RIGHT IP HERE: MASTER IP FOR THE SLAVE AND GONDOLA NTP IP FOR THE MASTER
syncflag=`exit $?`
if [ "$syncflag" == "0"]
then 	echo "Time has synced"
else 	echo "Unable to sync time"
	date -s '2000-01-01 00:00:00'
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
mm=`/usr/bin/date +%M`
ss=`/usr/bin/date +%S`
let wait=60-ss		# begin shots at the next minute
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
		ta=$dayt
		gain=$dayg
		/usr/bin/echo "You are observing during daytime"
	else	/usr/bin/echo "night"
		ta=$nightt
		gain=$nightg
		/usr/bin/echo "You are observig during nighttime"
	fi
	/usr/bin/echo "Shooting..."
	let n=0
	for cam in ${cams[@]}
	do 	/usr/bin/grep "Lens"$cam $configfile > $path/lenstmp
		read bidon bidon lens bidon < $path/lenstmp
		/usr/bin/grep "Posi"$cam $configfile> $path/positmp
		read bidon bidon posi bidon < $path/positmp
		take_pictures "$cam" "$gain" "$ta"
		# reading gps position
		globalpos
		gps_list[$n]=$lat"_"$lon"_"$alt
   		yy=`/usr/bin/date +%Y`
   		mo=`/usr/bin/date +%m`
		dd=`/usr/bin/date +%d`
		basename=`/usr/bin/date +%Y-%m-%d_%H-%M-%S`
		image=$basename"_"$cam"_"$lens"_"$posi"_"$ta"_"$gain
		image_list[$n]=$image"_"$secnum
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
		/usr/bin/cp -f $path"/capture_"$cam".dng" $yy/$mo/$image"_"$secnum".dng"
	    	/usr/bin/cp -f $path"/capture_"$cam".dng" $backpath/$yy/$mo/$image"_"$secnum".dng"
		/usr/bin/cp -f $path"/capture_"$cam".jpg" $basepath/$yy/$mo/$image"_"$secnum".jpg"
	    	/usr/bin/cp -f $path"/capture_"$cam".jpg" $backpath/$yy/$mo/$image"_"$secnum".jpg"
		/usr/bin/convert $path"/capture_"$cam".jpg" -resize 1080 $path"/small_"$cam".jpg"
		/usr/bin/cp -f $path"/small_"$cam".jpg" $basepath/
		let n=n+1
	done
	# flush ram cache to correct a memory leak in the camera library
	/usr/bin/sync
	/usr/bin/echo 3 > /proc/sys/vm/drop_caches
	let secnum=secnum+1
	# write data to the image_list.txt file
	/usr/bin/echo $secnum ${image_list[@]} ${gps_list[@]} >> $path/image_list.txt
	cp -f $path"/image_list.txt" $basepath/$yy/$mo/
	cp -f $path"/image_list.txt" $backpath/$yy/$mo/
	# calculate waiting time until next shooting
	ss=`/usr/bin/date +%S`
        let idle=60-ss		# begin shots at the next minute
	if [ $idle -lt 0 ]
	then 	let idle=0
		/usr/sbin/reboot
	fi
	/usr/bin/echo "Wait " $idle "s before next reading."
	/bin/sleep $idle
done