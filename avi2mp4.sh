#! /bin/bash

DEBUG=0
VERSION=1
CONFIG=~/conf/avi2mp4.conf
LOG=~/log/avi2mp4.$(date +%F).log
OVERWRITE=1
FILE_LIST=''
SOURCE_DIR='/storage/mst3k/avi'
DEST_DIR='/storage/mst3k/'
IFS_BAK="$IFS"

# Encode video as h.264 which seems to be more efficient than mpeg4
# Set vbr quality to 20 (whatever that means) and enforce 30 fps
# Encode audio as aac. It is more efficient than mp3.
FFMPEG_OPTS='-c:v libx264 -q:v 20 -r 30 -c:a aac -strict -2'

################################################################################

log () {
	echo "$(date +%T) $@"
}

################################################################################

dep_check () {
	for app in ffmpeg; do
		which "$app" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			log "$app could not be found. Please install it."
			exit 1
		fi
	done

	# Check for ffmpeg codecs
	for codec in 'V* libx264 ' 'A* aac '; do
		ffmpeg -encoders 2>&1 | grep "$codec" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			log "ffmpeg does not have a required codec: $codec. Please install it."
#			exit 1
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
		CONFIG="$OPTARG"
		;;
	'D')
		DEBUG=1
		;;
	'V')
		echo "$VERSION"
		exit 0
		;;
	'?')
		usage
		exit 1
		;;
	esac
done

if [ ! -e "$CONFIG" ]; then
	log "Config file ($CONFIG) does not exist. I quit."
	exit 1
fi

source "$CONFIG"

if [ $DEBUG -eq 0 ]; then
	exec >> "$LOG" 2>&1
fi

log 'avi2mp4 started'

if [ ! -d "$SOURCE_DIR" ]; then
	log "SOURCE_DIR ($SOURCE_DIR) does not exist. I quit."
	exit 1
fi

if [ ! -d "$DEST_DIR" ]; then
	log "DEST_DIR ($DEST_DIR) does not exist. I quit."
	exit 1
fi

# Check for dependancies
dep_check

# If we weren't given a list of files on the command line, scan the source dir
if [ -z "$FILE_LIST" ]; then
	if [ -z "$SOURCE_DIR" ]; then
		log 'No files given on command line and no source directory set in config file.'
		exit 1
	fi
	FILE_LIST=$(find "$SOURCE_DIR" -maxdepth 1 -type f | sort)
fi

# Set field separator to newline so we can easily handle spaces in file names
IFS=$'\n'
for file in $FILE_LIST; do
	IFS="$IFS_BAK"
	file=$(echo "$file" | sed -e 's/ /\\ /g')
	# Replace suffix (i.e. .avi or .mpeg) with .mp4
	new_name=$(basename "$file" | sed -e 's/\.[[:alnum:]]\{3,4\}$/.mp4/')
	if [ -f "$DEST_DIR/$new_name" ] && [ $OVERWRITE -eq 0 ]; then
		log "Destination file $DEST_DIR/$new_name already exists. Skipping it."
		continue
	fi
	log "Starting $file to $DEST_DIR/$new_name"
	ffmpeg -y -v warning -i "$file" $FFMPEG_OPTS "$DEST_DIR/$new_name"
	log "Finished $file"
done
