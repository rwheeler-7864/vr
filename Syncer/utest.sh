#!/bin/bash
#***********************************************************************
#* FILENAME :        update.sh          DESIGN REF: NON-COMMERCIAL - BETA/MVP
#*
#* DESCRIPTION :  Process to begin update for attention repo, source and db (sync_manager.py)
#*     
#* PUBLIC FUNCTIONS :
#*      
#*
#* NOTES :  writing out p2additional git pull to cloudsync.log
#*          added in a prune for ref head errors on git that crop up from time to time
#*          Commented out, but the beginning of trapping the actual program name that caused the error.
#*          Will begin to add to this to have better error trapping. 
#*			Added in 
#* AUTHOR :           START DATE :    10 Feb 2019
#*
#* CHANGES :  
#*         Added in crontab to update 
#*		   adding in cp of sqlite3 db for backup,, including siam db
#* REF NO  VERSION DATE    WHO     DETAIL
#* 
#*
#**/

NAME="$(basename $0)"       # program name, can be alphanumeric string
LOCKFILE="/tmp/$NAME.lock"  # lock file to prevent concurrent runs
EMAIL="someone@example.com" # email to send fail log

tmpdir="$(mktemp -d /tmp/$NAME-XXXXXX)"
log="$tmpdir/log"
fifo="$tmpdir/fifo"

# log file
log="$(mktemp /tmp/$NAME.log.XXXXXX)"

error='' # error flag for functions below

# runs at exit, sends email if needed
exitHandler() {
	if [ "$error" ]; then
		echo "Keeping error log in $log"
		mpack2 -s 'Error log from $NAME' $log "$EMAIL"
	else
		rm -r $tmpdir
	fi
}

# runs on error
errorHandler() {
	error=1
	trap '' ERR # only do it once
}

# do the stuff
run() {
	trap errorHandler ERR
	trap exitHandler QUIT EXIT

	echo "Starting $NAME run"
	
	true
	
	echo "Finished $NAME run"
}

# set exit and error traps
trap exitHandler QUIT EXIT
trap errorHandler ERR

# lock to prevent concurrent execution
exec 9>>"$LOCKFILE"
flock --nonblock 9 #lock
if [ $? != 0 ]; then
	echo "Already running, lockfile $LOCKFILE"
	exit 1
fi

set -e # run trap on error

# write from fifo to syslog
mkfifo $fifo
(logger -t "$NAME" -f $fifo &)

# run and save output in log file and fifo
run 2>&1 |tee $log $fifo
ret=${PIPESTATUS[0]} # save exit code

exec 9>&- # relinquish lock

exit $ret
