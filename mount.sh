#!/bin/bash
#
# VARIABLES
USER=max # user name
GROUP=max # group name
SET_DIR=~/smount/sets # set file dir
SA_PATH=/opt/mountsa # sharedrive mounting service accounts
MOUNT_DIR=/mnt/sharedrives # sharedrive mount
MSTYLE=aio # OPTIONS: aio,strm,csd,cst All-In-One Streamer Cloudseed Custom
BINARY=/opt/crop/rclone_gclone # rclone or gclone binary to use
# MergerFS Variables
RW_LOCAL=/mnt/local # read write dir for merger
UMOUNT_DIR='/mnt/sharedrives/td_*' # if common prefix wildcard is possible (td_*) refer drive names in set file
MERGER_DIR=/mnt/unionfs # if this is a non empty dir or already in use by another merger service a reboot is required.

# count fuctions
get_port_no_count () {
  read count < port_no.count
  echo $(($count+1)) > port_no.count
}

get_sa_count () {
  read sacount < sa.count
  echo $(($sacount+1)) > sa.count
}

## mount functions
aio () {
  export user=$USER group=$GROUP rw_local=$RW_LOCAL umount_dir=$UMOUNT_DIR merger_dir=$MERGER_DIR mstyle=$MSTYLE sa_path=$SA_PATH binary=$BINARY
  envsubst '$user,$group,$sa_path,$binary' <./input/aio@.service >./output/aio@.service
  envsubst '$user,$group' <./input/primer@.service >./output/aio.primer@.service
  envsubst '$user,$group,$mstyle' <./input/primer@.timer >./output/aio.primer@.timer
  envsubst '$rw_local,$umount_dir,$merger_dir' <./input/smerger.service >./output/aio.merger.service
  #
  sudo bash -c 'cp ./output/aio@.service /etc/systemd/system/aio@.service'
  sudo bash -c 'cp ./output/aio.primer@.service /etc/systemd/system/aio.primer@.service'
  sudo bash -c 'cp ./output/aio.primer@.timer /etc/systemd/system/aio.primer@.timer'
  #
  sudo systemctl enable aio@.service
  sudo systemctl enable aio.primer@.service
  sudo systemctl enable aio.primer@.timer
}

strm () {
  export user=$USER group=$GROUP rw_local=$RW_LOCAL umount_dir=$UMOUNT_DIR merger_dir=$MERGER_DIR mstyle=$MSTYLE sa_path=$SA_PATH binary=$BINARY
  envsubst '$user,$group,$sa_path,$binary' <./input/strm@.service >./output/strm@.service
  envsubst '$user,$group' <./input/primer@.service >./output/strm.primer@.service
  envsubst '$user,$group,$mstyle' <./input/primer@.timer >./output/strm.primer@.timer
  envsubst '$rw_local,$umount_dir,$merger_dir' <./input/smerger.service >./output/strm.merger.service
  #
  sudo bash -c 'cp ./output/strm@.service /etc/systemd/system/strm@.service'
  sudo bash -c 'cp ./output/strm.primer@.service /etc/systemd/system/strm.primer@.service'
  sudo bash -c 'cp ./output/strm.primer@.timer /etc/systemd/system/strm.primer@.timer'
  #
  sudo systemctl enable strm@.service
  sudo systemctl enable strm.primer@.service
  sudo systemctl enable strm.primer@.timer
}

csd () {
  export user=$USER group=$GROUP rw_local=$RW_LOCAL umount_dir=$UMOUNT_DIR merger_dir=$MERGER_DIR mstyle=$MSTYLE sa_path=$SA_PATH binary=$BINARY
  envsubst '$user,$group,$sa_path,$binary' <./input/csd@.service >./output/csd@.service
  envsubst '$user,$group' <./input/primer@.service >./output/csd.primer@.service
  envsubst '$user,$group,$mstyle' <./input/primer@.timer >./output/csd.primer@.timer
  envsubst '$rw_local,$umount_dir,$merger_dir' <./input/smerger.service >./output/csd.merger.service
  #
  sudo bash -c 'cp ./output/csd@.service /etc/systemd/system/csd@.service'
  sudo bash -c 'cp ./output/csd.primer@.service /etc/systemd/system/csd.primer@.service'
  sudo bash -c 'cp ./output/csd.primer@.timer /etc/systemd/system/csd.primer@.timer'
  #
  sudo systemctl enable csd@.service
  sudo systemctl enable csd.primer@.service
  sudo systemctl enable csd.primer@.timer
}

cst () {
  export user=$USER group=$GROUP rw_local=$RW_LOCAL umount_dir=$UMOUNT_DIR merger_dir=$MERGER_DIR mstyle=$MSTYLE sa_path=$SA_PATH binary=$BINARY
  envsubst '$user,$group,$sa_path,$binary' <./input/cst@.service >./output/cst@.service
  envsubst '$user,$group' <./input/primer@.service >./output/cst.primer@.service
  envsubst '$user,$group,$mstyle' <./input/primer@.timer >./output/cst.primer@.timer
  envsubst '$rw_local,$umount_dir,$merger_dir' <./input/smerger.service >./output/cst.merger.service
  #
  sudo bash -c 'cp ./output/cst@.service /etc/systemd/system/cst@.service'
  sudo bash -c 'cp ./output/cst.primer@.service /etc/systemd/system/cst.primer@.service'
  sudo bash -c 'cp ./output/cst.primer@.timer /etc/systemd/system/cst.primer@.timer'
  #
  sudo systemctl enable cst@.service
  sudo systemctl enable cst.primer@.service
  sudo systemctl enable cst.primer@.timer
}

make_config () {
  sed '/^\s*#.*$/d' $SET_DIR/$1|\
    while read -r name other;do
      get_port_no_count
      conf="
      RCLONE_RC_PORT=$count
      SOURCE_REMOTE=$name:
      DESTINATION_DIR=$MOUNT_DIR/$name/
      SA_PATH=$SA_PATH
      BINARY=$BINARY
      ";
      echo "$conf" > /home/$USER/smount/sharedrives/$name.conf
    done
}

make_shmount.conf () {
  sed '/^\s*#.*$/d' $SET_DIR/$1|\
  while read -r name driveid;do 
  get_sa_count
  echo "
[$name]
type = drive
scope = drive
server_side_across_configs = true
team_drive = $driveid
service_account_file = "$SA_PATH/$sacount.json"
">>~/smount/smount.conf
  done; }

make_starter () {
  sed '/^\s*#.*$/d' $SET_DIR/$1|\
    while read -r name other;do
      echo "sudo systemctl enable $MSTYLE@$name.service && sudo systemctl enable $MSTYLE.primer@$name.service">>$MSTYLE.starter.sh
    done
    sed '/^\s*#.*$/d' $SET_DIR/$1|\
    while read -r name other;do
      echo "sudo systemctl start $MSTYLE@$name.service">>$MSTYLE.starter.sh
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



# Make Config Dirs
sudo mkdir -p /home/$USER/smount/sharedrives /home/$USER/smount/backup /home/$USER/smount/scripts /home/$USER/smount/config
sudo chown -R $USER:$GROUP /home/$USER/smount/sharedrives /home/$USER/smount/backup /home/$USER/smount/scripts /home/$USER/smount/config
sudo chmod -R 775 /home/$USER/smount/sharedrives /home/$USER/smount/backup /home/$USER/smount/scripts /home/$USER/smount/config

# rename existing starter and kill scripts if present
mv $MSTYLE.starter.sh ./backup/$MSTYLE.starter`date +%Y%m%d%H%M%S`.sh > /dev/null 2>&1
mv $MSTYLE.primer.sh ./backup/$MSTYLE.primer`date +%Y%m%d%H%M%S`.sh > /dev/null 2>&1
mv $MSTYLE.kill.sh ./backup/$MSTYLE.kill`date +%Y%m%d%H%M%S`.sh > /dev/null 2>&1

# enable new services TEST LATER
# sudo systemctl enable $MSTYLE@.service
# sudo systemctl enable $MSTYLE.primer@.service
# sudo systemctl enable $MSTYLE.primer@.timer



# Function calls
$MSTYLE  $1
make_shmount.conf $1
make_config $1
make_starter $1
make_primer $1
make_vfskill $1

# daemon reload - fire in the hole
sudo systemctl daemon-reload
chmod +x $MSTYLE.starter.sh $MSTYLE.primer.sh $MSTYLE.kill.sh
./$MSTYLE.starter.sh  #fire the starter
nohup sh ./$MSTYLE.primer.sh &>/dev/null &

echo "$MSTYLE mount script completed."
#eof
