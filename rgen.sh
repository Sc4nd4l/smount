#!/bin/bash
SET_DIR=~/smount/sets
sadir="/opt/mountsa"
token={"access_token":"ya"}

get_sa_count () {
  read count < sa.count
  echo $(($count+1)) > sa.count
}

make_smount.conf () {
  sed '/^\s*#.*$/d' $SET_DIR/$1|\
  while read -r name driveid;do 
  get_sa_count
  echo "
[$name]
type = drive
scope = drive
server_side_across_configs = true
team_drive = $driveid
service_account_file = "$sadir/$count.json"
">>~/smount/smount.conf
  done; }

make_shmount.conf $1
