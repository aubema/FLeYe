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
	let ta=nightt
	let gain=nightg
	let satmax=1000
	rm -f $path"/capture_$cam*"
	/usr/bin/python3 /usr/local/bin/capture$cam.py -t $ta -g $gain
	if [ ! -f $path"/capture_$cam.dng" ]
		echo "Problem with " $cam "camera."
	fi
}



	/usr/bin/python3 /usr/local/bin/capture$cam.py -t $ta -g $gain
	if [ -f $path"/capture_$cam.dng" ]
	then 	/usr/local/bin/lisc perc $path"/capture_$cam.dng" -p 99.9  > $path"/saturation.tmp"
		/usr/bin/python3 /usr/local/bin/maxsatpercent.py > $path"/capture.tmp"
		read satmax bidon  < $path"/capture.tmp"
		echo "satmax=" $satmax
		if [ "$satmax" -ge 100 ]
		then 	let ta=moont
			let gain=nightg
			rm -f $path"/capture_$cam*"
			/usr/bin/python3 /usr/local/bin/capture$cam.py -t $ta -g $gain
			if [ -f $path"/capture_1.dng" ]
			then 	/usr/local/bin/lisc perc $path"/capture_$cam.dng" -p 99.9  > $path"/saturation.tmp"
				/usr/bin/python3 /usr/local/bin/maxsatpercent.py > $path"/capture.tmp"
				read satmax bidon  < $path"/capture.tmp"
				echo "satmax=" $satmax
				if [ "$satmax" -ge 100 ]
				then 	let ta=dayt
					let gain=dayg
					rm -f $path"/capture_1*"
					/usr/bin/python3 /usr/local/bin/capture$cam.py -t $ta -g $gain
				else
					/usr/bin/python3 /usr/local/bin/captureB.py -t $ta -g $gain
				fi
			else 	echo "Problem with " $cam " camera."
				exit 0
			fi
			rm -f $path"/capture_1*"
			rm -f $path"/capture_2*"
			/usr/bin/python3 /usr/local/bin/capture$cam.py -t $ta -g $gain

		else
			/usr/bin/python3 /usr/local/bin/captureB.py -t $ta -g $gain
		fi
	else 	echo "Problem with " $cam "camera."
		exit 0
	fi
	echo  $ta > $path"/Current_tint.tmp"
	echo  $gain > $path"/Current_gain.tmp"



#
# ==================================
#
# main
#
# setting constants
dayt=800
dayg=1
nightt=20000   		# 1/50s
nightg=16		# ISO 1600
user="sand"
gain=$nightg
ta=$nightt
max_lum=100000  # 1000000 = 1sec
cams=(A B C D)
basepath="/var/www/html/data"
backpath="/home/"$user"/data"
path="/home/"$user
# get the site name
# wait 2 min to start (enough time for ntp sync)
echo "Waiting 2 min before starting measurements..."
/bin/sleep 120

while :
do time1=`date +%s`
	echo "Shooting..."
	let n=0
	for cam in ${cams[@]}
	do 	take_pictures()
   		yy=`date +%Y`
   		mo=`date +%m`
		dd=`date +%d`
		basename_tmp=`date +%Y-%m-%d_%H-%M-%S`
		echo $basenameA
		baseday=`date +%Y-%m-%d`
		basename[$n]="$basename_tmp"

		read  tv toto < $path"/Current_tint.tmp"
		read  gain toto < $path"/Current_gain.tmp"
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
	 if [ $ta -ge $max_lum ]
	 then
      cp -f $path"/capture_1.dng" $basepath/$y/$mo/$basenameA"_A_"$ta"_"$gain".dng"
	    cp -f $path"/capture_1.dng" $backpath/$y/$mo/$basenameA"_A_"$ta"_"$gain".dng"
	    cp -f $path"/capture_1.dng" $path/$basenameA"_A_"$ta"_"$gain".dng"
   fi
   cp -f $path"/capture_1.jpg" $basepath/$y/$mo/$basenameA"_A_"$ta"_"$gain".jpg"
   cp -f $path"/capture_1.jpg" $backpath/$y/$mo/$basenameA"_A_"$ta"_"$gain".jpg"
	 cp -f $path"/capture_1.jpg" $path/$basenameA"_A_"$ta"_"$gain".jpg"
   basename[1]="$basenameB"
   read  tb toto < $path"/Current_tint.tmp"
   echo "=============================="
   # rename pictures
	 if [ $ta -ge $max_lum ]
	 then
      cp -f $path"/capture_2.dng" $basepath/$y/$mo/$basenameB"_B_"$tb"_"$gain".dng"
	    cp -f $path"/capture_2.dng" $backpath/$y/$mo/$basenameB"_B_"$tb"_"$gain".dng"
	    cp -f $path"/capture_2.dng" $path/$basenameB"_B_"$tb"_"$gain".dng"
   fi
   cp -f $path"/capture_2.jpg" $basepath/$y/$mo/$basenameB"_B_"$tb"_"$gain".jpg"
   cp -f $path"/capture_2.jpg" $backpath/$y/$mo/$basenameB"_B_"$tb"_"$gain".jpg"
	 cp -f $path"/capture_2.jpg" $path/$basenameB"_B_"$tb"_"$gain".jpg"
   # check for the night by reading the latest optimal integration time
	 limit=`cat /sys/class/gpio/gpio5/value`
	 # limit = 1 => cameras inside
	 # limit = 0 => cameras outside
   if [ $ta -lt $max_lum ]
   then echo "Too much light. It is probably daytime."
	    if [ "$limit" == "0" ]
			then
				 echo "Moving cameras..."
         /usr/bin/python3 /usr/local/bin/move_cams.py -1400 1
			fi
      echo "Let's keep the camera inside for 15 min"
			processflag=0
   else /usr/bin/python3 /usr/local/bin/move_cams.py 2000 1
		  processflag=1
   fi
   echo "=============================="
	 if [ $processflag -eq 1 ]
	 then
      # process sky IMAGES
      let n=0
      for b in ${bands[@]}
      do if [ $n -eq 0 ]
         then let t=ta
         else let t=tb
         fi
				 # determine the zeropoint according to the integration time and camera
				 #
				 #
				 #

         /usr/bin/python3 /usr/local/bin/ProcessNightMon.py -i ${basename[$n]}"_"${cams[$n]}"_"$t"_"$gain".dng" -d $path"/git/nightmon/data/Darks/"$darkimg -b $b -e ${extinct[$n]} -m $model
         if [ -f $path"/"$b"_calibration_"${basename[$n]}".png" ]
         then
				    mv $path"/"$b"_calibration_"${basename[$n]}".png" $basepath/$y/$mo/
					  cp -f $basepath"/"$y"/"$mo"/"$b"_calibration_"${basename[$n]}".png" $backpath"/"$y"/"$mo"/"
				 fi
				 if [ -f $path"/"$b"_calSbBkg_"${basename[$n]}".png" ]
				 then
					 mv $path"/"$b"_calSbBkg_"${basename[$n]}".png" $basepath/$y/$mo/
					 cp -f $basepath"/"$y"/"$mo"/"$b"_calSbBkg_"${basename[$n]}".png" $backpath"/"$y"/"$mo"/"
			   fi
				 if [ -f $path"/"$b"_calSbTot_"${basename[$n]}".png" ]
				 then
					 mv $path"/"$b"_calSbTot_"${basename[$n]}".png" $basepath/$y/$mo/
					 cp -f $basepath"/"$y"/"$mo"/"$b"_calSbTot_"${basename[$n]}".png" $backpath"/"$y"/"$mo"/"
			   fi
				 if [ -f $path"/"$b"_Stars_Match_"${basename[$n]}".png" ]
				 then
					 mv $path"/"$b"_Stars_Match_"${basename[$n]}".png" $basepath/$y/$mo/
					 cp -f $basepath"/"$y"/"$mo"/"$b"_Stars_Match_"${basename[$n]}".png" $backpath"/"$y"/"$mo"/"
			   fi
				 # backup calibration file
         if [ -f $path"/"$b"_calibration_stars_"${basename[$n]}".csv" ]
         then mv $path"/"$b"_calibration_stars_"${basename[$n]}".csv" $basepath/$y/$mo/
              cp -f $basepath"/"$y"/"$mo"/"$b"_calibration_stars_"${basename[$n]}".csv" $backpath"/"$y"/"$mo"/"
         fi




         # backup output files
         if [ -f $basepath"/"$y"/"$mo"/calibrated_"$baseday"_sky.csv" ]
         then cat $path"/calibrated_"$b"_"$baseday"_sky.csv" | grep -v "Loc_Name" | grep -v "(pixel)"  >> $basepath"/"$y"/"$mo"/calibrated_"$baseday"_sky.csv"
         else cat $path"/calibrated_"$b"_"$baseday"_sky.csv"  > $basepath"/"$y"/"$mo"/calibrated_"$baseday"_sky.csv"
         fi
         cp -f $basepath"/"$y"/"$mo"/calibrated_"$baseday"_sky.csv" $backpath"/"$y"/"$mo"/"




         # clean directory
         rm $path"/"${basename[$n]}"_"${cams[$n]}"_"$t"_"$gain".dng"
         rm $path"/calibrated_"$b"_"$baseday"_sky.csv"
         let n=n+1
      done
   fi
   time2=`date +%s`
   let idle=900-time2+time1  # one measurement every 15 min (15*60=900)
   if [ $idle -lt 0 ] ; then let idle=0; fi
   echo "Wait " $idle "s before next reading."
   /bin/sleep $idle
	 time1=`date +%s`
	 rm -f $path/*.dng
	 rm -f $path/*.jpg
done
