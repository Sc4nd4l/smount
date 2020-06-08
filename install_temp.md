Temporary install instructions....

`cd ~/`

Clone repo, shmount branch

```
git clone https://github.com/maximuskowalski/smount.git --branch shmount && cd smount
```

Use `mount.sh` for this version. Make executable, set variables.

```
# VARIABLES
USER=max # user name
GROUP=max # group name

SA_PATH=/opt/mountsa # sharedrive mounting service accounts

MSTYLE=aio # OPTIONS: aio,strm,csd,cst All-In-One Streamer Cloudseed Custom

BINARY=/opt/crop/rclone_gclone # rclone or gclone binary to use

```

User & group, Service account path and MSTYLE is necessary. 

BINARY is not a proper variable yet so you will need to place the `rclone_gclone` in `/opt/crop/` and make executable.
Can be downloaded from here currently. https://gofile.io/d/D6jKeL You will need to download on a PC and upload, wget fails to pull file properly.

It does not use rclone.conf but builds a conf on the fly - this file will be added to only at present, not replaced or edited by the script so if you run the same set because of error you will end up with double ups of mounts.

Make Setfiles
`cp ~/smount/sets/aiosample.set ~/smount/sets/aio.set`
and/or
`cp ~/smount/sets/aiosample.set ~/smount/sets/csd.set`
`cp ~/smount/sets/aiosample.set ~/smount/sets/strm.set`
`cp ~/smount/sets/aiosample.set ~/smount/sets/cst.set`

Edit your sets using nano or however you prefer and save.
`nano ~/smount/sets/csd.set`

Run the script with the set for your mountstyle.

`./mount.sh aio.set`

If you want to add a cloudseed mount or a strm only mount edit sets for those and run again.

`./mount.sh csd.set`

Mergerfs not included at this stage, do not use.
