#! /bin/bash

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
	# TODO: Add check for h.265
	for codec in 'V* libx264 ' 'A* aac '; do
		ffmpeg -encoders 2>&1 | grep "$codec" > /dev/null 2>&1
		if [ $? -ne 0 ]; then
			log "ffmpeg does not have a required codec: $codec. Please install it."
			exit 1
		fi
	done
}

################################################################################

usage () {
	echo 'usage: avi2mp4.sh [options] [file or directory to convert] [destination directory]'
	echo '	-D		   Debug (log to stdout, not file)'
	echo '  -h         Use h.265 instead of h.264'
	echo '	-V		   Version'
	exit 1
}

################################################################################

main () (
	local -i DEBUG=0
	local -i VERSION=1
	local -i use_h265=0
	local    LOG=~/log/avi2mp4.$(date +%F).log
	local -i OVERWRITE=1
	local    SOURCE_LIST
	local    DEST_DIR
	local    IFS_BAK="$IFS"

	# We have presets for two codecs, h.264 and h.265. We'll set the video codec
	# later. For either, we enforce 30 fps. For audio we use aac. It is more
	# efficient than mp3.
	local    FFMPEG_OPTS='-r 30 -profile:v high -level 4.1 -c:a aac -strict -2'

	while getopts 'DhV' o; do
		case "$o" in
		'D')
			DEBUG=$((DEBUG + 1))
			;;
		'h')
			use_h265=1
			;;
		'V')
			echo "$VERSION"
			exit 0
			;;
		'?')
			usage
			;;
		esac
	done

	if [ "$use_h265" -gt 0 ]; then
		# For newer devices, like Roku 4, we can use x265
		FFMPEG_OPTS="'-c:v libx265 $FFMPEG_OPTS"
	else
		# Encode video as h.264 which seems to be more efficient than mpeg4
		FFMPEG_OPTS="'-c:v libx264 $FFMPEG_OPTS"
	fi

	# getopts uses OPTIND to indicate the next option to process
	# for simplicity, we'll just throw away everything it has processed
	# so down below we can use $1, $2, etc. instead of $OPTIND, $OPTIND+1, etc/
	shift $((OPTIND - 1))

	# Check to see if we were given directories and/or files on the command line
	if [ $# -lt 2 ]; then
		log "e: You must provide a source and destination"
		usage
	fi

	for

	if [ "$DEBUG" -eq 0 ]; then
		exec >> "$LOG" 2>&1
	fi

	if [ "$DEBUG" -gt 1 ]; then
        set -o xtrace
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
		# TODO: search based on file suffix?
		FILE_LIST=$(find "$SOURCE_DIR" -maxdepth 1 -type f | sort)
	fi

	# Set field separator to newline so we can easily handle spaces in file names
	# TODO: This does not properly handle file names with spaces
	IFS=$'\n'
	for file in $FILE_LIST; do
		IFS="$IFS_BAK"
		file=$(echo "$file" | sed -e 's/ /\\ /g')
		# Replace suffix (i.e. .avi or .mpeg) with .mp4
		new_name=$(basename "$file" | sed -e 's/\.[[:alnum:]]\{3,4\}$/.mp4/')
		if [ -f "$DEST_DIR/$new_name" ] && [ "$OVERWRITE" -eq 0 ]; then
			log "Destination file $DEST_DIR/$new_name already exists. Skipping it."
			continue
		fi
		log "Starting $file to $DEST_DIR/$new_name"
		ffmpeg -y -v warning -i "$file" $FFMPEG_OPTS "$DEST_DIR/$new_name"

		#TODO: Check return code

		log "Finished $file"
	done
)

main $@
