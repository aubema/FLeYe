#!/usr/bin/bash

while :
do
	#sshpass -p "lumin007" scp sand@master:small*_0* ./last_images/master
	montage -geometry 500x+1+1 -tile 2x2 small*_0.jpg master

        #sshpass -p "lumin007" scp sand@slave1:small*_0* ./last_images/slave1
        montage -geometry 500x+1+1 -tile 2x2 small*_0.jpg slave1

        #sshpass -p "lumin007" scp sand@slave2:small*_0* ./last_images/slave2
        montage -geometry 500x+1+1 -tile 2x2 small*_0.jpg slave2

	montage -geometry 600x+2+2 -tile 3x1 master slave1 slave2 collage

	display collage &

	sleep 10
	killall display
done
