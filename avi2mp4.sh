#! /bin/bash

DEBUG=0
YEAR="`date +%Y`"
VERSION=1
CONFIG=~/stream2podcast.conf
OVERWRITE=1
FILE_LIST=''
SOURCE_DIR=''
DEST_DIR=''

# Encode video as h.264 which seems to be more efficient than mpeg4
# Set vbr quality to 20 (whatever that means) and enforce 30 fps
# Encode audio as mp3. I don't recall why I don't use AAC. The WD box probably
# didn't like it
FFMPEG_OPTS='-c:v libx264 -q:v 20 -r 30 -c:a mp3'

################################################################################

log () {
	echo `date +%T` "$@"
}

################################################################################

dep_check () {
	for app in ffmpeg; do
		which $app > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			log "$app could not be found. Please install it."
			exit 1
		fi
	done

	# Check for ffmpeg codecs
	for codec in 'V* libx264 ' 'A* mp3 '; do
		ffmpeg -codecs 2>&1 | grep "$codec" >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			log "ffmpeg does not have a required codec: $codec. Please install it."
			exit 1
		fi
	done
}

################################################################################

usage()
{
	echo "usage: avi2mp4.sh [options]"
	echo "	-c FILE	   Use FILE as the config file. Default is $CONFIG"
	echo '	-D		   Debug (log to stdout, not file)'
	echo '	-V		   Version'
	exit 1
}

################################################################################

while getopts 'c:DrV' o; do
	case "$o" in
	'c')
		CONFIG=$OPTARG
		;;
	'D')
		DEBUG=1
		;;
	'V')
		echo $VERSION
		exit 0
		;;
	'?')
		usage
		exit 1
		;;
	esac
done

FILE_LIST="$@"

if [ ! -e $CONFIG ]; then
	log "Config file ($CONFIG) does not exist. I quit."
	exit 1
fi

source $CONFIG

if [ $DEBUG -eq 0 ]; then
	exec >> $LOG 2>&1
fi

log 'stream2podcast started'

if [ ! -d $SOURCE_DIR ]; then
	log "SOURCE_DIR ($SOURCE_DIR) does not exist. I quit."
	exit 1
fi

if [ ! -d $DEST_DIR ]; then
	log "DEST_DIR ($DEST_DIR) does not exist. I will create it."
	mkdir -p $DEST_DIR
fi

# Check for dependancies
dep_check

# If we weren't given a list of files on the command line, scan the source
if [ -z "$FILE_LIST" ]; then
	if [ -z "$SOURCE_DIR" ]; then
		log 'No files or
	FILE_LIST=`find $SOURCE_DIR -type f`
fi

for file in "$FILE_LIST"; do
	# Replace suffix (i.e. .avi or .mpeg) with .mp4
	new_name="`basename $file | sed 's/\.[[:alnum:]]\{3,4\}$/.mp4/'`"
	if [ -f "$DEST_DIR/$new_name" -a $OVERWRITE -eq 0 ]; then
		log "Destination file $DEST_DIR/$new_name already exists. Skipping it."
		continue
	fi
	ffmpeg -i "$file" $FFMPEG_OPTS "$DEST_DIR/$new_name"
done
