#!/bin/bash

# REQUIRED VARIABLES
USER=max # user name
GROUP=max # group name
SET_DIR=~/.smount/sets # set file dir
MOUNT_DIR=/mnt/sharedrives # sharedrive mount
MSTYLE=aio # OPTIONS: aio,strm,csd

echo -e "MSTYLE mount building..."

# OPTIONAL MergerFS Variables 
# for example mergerfs service file. 
# NOT INSTALLED. PLACED in OUTPUT DIR as example only see options below to enable inline
RW_LOCAL=/mnt/local # read write local dir for merger service
UMOUNT_DIR=/mnt/sharedrives/td_* # if common prefix wildcard is possible (td_*)
MERGER_DIR=/mnt/unionfs # if this is a non empty dir or already in use by another merger service a reboot is required.

# Make Work Dirs
sudo mkdir -p /home/$user/.smount/sharedrives
sudo chown -R $USER:$GROUP /home/$user/.smount/sharedrives
sudo chmod -R 775 /home/$user/.smount/sharedrives

# Create and place service files
export user=$USER group=$GROUP rw_local=$RW_LOCAL umount_dir=$UMOUNT_DIR merger_dir=$MERGER_DIR mstyle=$MSTYLE
envsubst '$user,$group' <./input/aio@.service >./output/$MSTYLE.@.service
envsubst '$user,$group' <./input/primer@.service >./output/$MSTYLE.primer@.service
envsubst '$user,$group,$mstyle' <./input/primer@.timer >./output/$MSTYLE.primer@.timer
envsubst '$rw_local,$umount_dir,$merger_dir' <./input/smerger.service >./output/$MSTYLE.merger.service
sudo bash -c 'cp ./output/teamdrive@.service /etc/systemd/system/teamdrive@.service'
sudo bash -c 'cp ./output/aio_primer@.service /etc/systemd/system/$MSTYLE.primer@.service'
sudo bash -c 'cp ./output/teamdrive_primer@.timer /etc/systemd/system/$MSTYLE.primer@.timer'

# uncomment next two lines to copy smerger to /etc/systemd/system and enable
#sudo bash -c 'cp ./output/smerger.service /etc/systemd/system/smerger.service'
#sudo systemctl enable smerger.service

# enable new services
sudo systemctl enable teamdrive@.service
sudo systemctl enable teamdrive_primer@.service
sudo systemctl enable teamdrive_primer@.timer

# rename existing starter and kill scripts if present
#mv vfs_starter.sh vfs_starter_`date +%Y%m%d%H%M%S`.sh > /dev/null 2>&1
#mv vfs_primer.sh vfs_primer_`date +%Y%m%d%H%M%S`.sh > /dev/null 2>&1
#mv vfs_kill.sh vfs_kill_`date +%Y%m%d%H%M%S`.sh > /dev/null 2>&1

# Note that port default starting number=5575
# Read the current port no to be used then increment by +1
get_port_no_count () {
  read count < port_no.count
  echo $(($count+1)) > port_no.count
}

# config files
make_config () {
  sed '/^\s*#.*$/d' $SET_DIR/$1|\
    while read -r name other;do
      get_port_no_count
      conf="
      RCLONE_RC_PORT=$count
      SOURCE_REMOTE=$name:
      DESTINATION_DIR=$MOUNT_DIR/$name/
      ";
      echo "$conf" > /opt/sharedrives/$name.conf
    done
}

make_starter () {
  sed '/^\s*#.*$/d' $SET_DIR/$1|\
    while read -r name other;do
      echo "sudo systemctl enable $MSTYLE.@$name.service && sudo systemctl enable $MSTYLE.primer@$name.service">>$MSTYLE.starter.sh
    done
    sed '/^\s*#.*$/d' $SET_DIR/$1|\
    while read -r name other;do
      echo "sudo systemctl start $MSTYLE.@$name.service">>$MSTYLE.starter.sh
    done
}

make_primer () {
  sed '/^\s*#.*$/d' $SET_DIR/$1|\
    while read -r name other;do
      echo "sudo systemctl start $MSTYLE.primer@$name.service">>$MSTYLE.primer.sh
    done
}

make_vfskill () {
  sed '/^\s*#.*$/d' $SET_DIR/$1|\
    while read -r name other;do
      echo "sudo systemctl stop $MSTYLE@$name.service && sudo systemctl stop $MSTYLE.primer@$name.service">>$MSTYLE.kill.sh
    done
    sed '/^\s*#.*$/d' $SET_DIR/$1|\
    while read -r name other;do
      echo "sudo systemctl disable $MSTYLE@$name.service && sudo systemctl disable $MSTYLE.primer@$name.service">>$MSTYLE.kill.sh
    done
}

make_config $1
make_starter $1
make_primer $1
# daemon reload
sudo systemctl daemon-reload
make_vfskill $1
chmod +x $MSTYLE.starter.sh $MSTYLE.primer.sh $MSTYLE.kill.sh
./$MSTYLE.starter.sh  #fire the starter
nohup sh ./$MSTYLE.primer.sh &>/dev/null &

# Uncomment below line if using cloudbox merger service already and enabling extra merger
#sudo systemctl stop mergerfs.service

# uncomment below start smerger.service
#systemctl start mergerfs.service && sudo systemctl start smerger.service

echo "$MSTYLE mount script completed."
#eof