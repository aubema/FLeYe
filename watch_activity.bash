!/bin/bash
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
if [ -f /home/sand/data/volume.txt ]
then	read oldvol < /home/sand/data/volume.txt
else	let oldvol=0
newvol=`du -ms /home/sand/data`
if [ $newvol -eq $oldvol ] 
then /usr/sbin/reboot
fi
/usr/bin/echo $newvol > /home/sand/data/volume.txt