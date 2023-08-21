#!/usr/bin/bash

while :
do
	sshpass -p "lumin007" scp sand@master:small*_0* ./last_images/master_dir/
	montage -geometry 500x+1+1 -tile 2x2 ./last_images/master_dir/small*_0.jpg master

        sshpass -p "lumin007" scp sand@slave1:small*_0* ./last_images/slave1_dir/
        montage -geometry 500x+1+1 -tile 2x2 ./last_images/slave1_dir/small*_0.jpg slave1

        sshpass -p "lumin007" scp sand@slave2:small*_0* ./last_images/slave2_dir/
        montage -geometry 500x+1+1 -tile 2x2 ./last_images/slave2_dir/small*_0.jpg slave2

	montage -geometry 600x+2+2 -tile 3x1 master slave1 slave2 collage

	display collage &

	sleep 300
	killall display
done
