#!/bin/bash
# 2024-06-07 C.Greenwood
# Rename all files in a music library based on metadata.
# Uses the format "[Track]. [Title].mp3"

# TBD Remove all the stuff from AddTrackToTitle.

# 2022-08-30 Hyperling
# Put the files' Track in their Title so that Toyota Entune plays the songs in the right frikken order!!!
# At least with the 2019 RAV4, it acknowledges the Track#, but still sorts albums alphabetically for whatever reason.
#
# Return Codes:
#  0) Success!
#  1) Parameter passed
#  2) Pre-requisite tool not installed
#  3) Failure to find music metadata
#  4) Failure to create fixed file
#  5) Fixed file is missing
#  6) Unknown operator
#


## Variables ##

PROG="`basename $0`"
#DIR="`dirname $0`"
DIR="`pwd`"
EXT=".mp3"
ADD="(Fixed)"
TIME="`which time`"
TRUE="T"
FALSE="F"
UNDO="$FALSE"


## Functions ##

function usage {
	cat <<- EOF
		Usage:
		  $PROG [-h] [-u]

		Parameters:
		  -h : Help, display the usage and exit succesfully.

		Place this file at the root of your music destined for a flash drive and run it without any parameters.
		It will dive through all folders and convert your MP3's to have the Track# in the Title.
		The process changes the filenames to contain (Fixed) so you know it's touched the file.
		Please be sure you only run this on a copy of your music, not the main source!

		This tool has a few pre-requisites you should make sure you have installed:
		  - exiftool
		  - ffmpeg

		Thanks for using $PROG!
	EOF
	exit $1
}

function error {
	num_chars=$(( 7 + ${#1} ))
	echo ""
	printf '*%.0s' $(seq 1 $num_chars)
	echo -e "\nERROR: $1"
	printf '*%.0s'  $(seq 1 $num_chars)
	echo -e "\n"
	usage $2
}


## Validations ##

# Check for parameters.
while getopts ":h" opt; do
	case "$opt" in
		h) usage 0
		;;
		*) error "Operator $OPTARG not recognized." 6
		;;
	esac
done

# Ensure critical tools are available.
if [[ ! `which exiftool` ]]; then
	error "exiftool not found" 2
fi


## Main ##

# Loop through all files in and lower than the current directory.
count=0
total="`find $DIR -name "*${EXT}" -printf . | wc -c`"
avg_time=0
total_time=0
time_count=0
est_guess=0
time find $DIR -name "*${EXT}" | sort | while read file; do
	count=$(( count + 1 ))

	echo -e "\n$file"

	# Retrieve and clean the Track#
	track=""
	# Get raw value
	track="`exiftool -Track "$file"`"
	# Filter the header
	track="${track//Track   /}"
	track="${track//   : /}"
	# Remove disk designations
	track="${track%%/*}"
	# Remove any whitespace before/after
	track="`echo $track`"
	# Add a leading 0 to single digits.
	[[ ${#track} == 1 ]] && track="0$track"
	echo "Track=$track"

	# Retrieve and clean the Title
	title=""
	title="`exiftool -Title "$file"`"
	title="${title//Title   /}"
	title="${title//   : /}"
	title="${title//[^[:alnum:][:space:].]/}"
	title="`echo $title`"
	while [[ "$title" == *"  "* ]]; do
		title="${title//  / }"
	done
	echo "Title=$title"

	# Create the new file with the correct filename.
	new_file="`dirname "$file"`/$track. $title$EXT"

	if [[ ! -z "$track" && ! -z "$title" ]]; then
		if [[ "$file" == "$new_file" ]]; then
			echo "SKIP: Filename already correct! :)"
			continue
		fi
		echo "Creating '`basename "$new_file"`'."
		mv -v "$file" "$new_file"
	elif [[ -z "$track" && ! -z "$title" ]]; then
		echo "No Track# found, leaving Title alone."
		continue
	else
		echo "File does not have Track or Title metadata."
		continue
	fi

	# Confirm the new file exists and remove the old file if so
	if [[ -e "$new_file" ]]; then
		echo "Success!"
	else
		error "$new_file was not created successfully." 5
	fi
done

echo -e "\nProcess has completed. Enjoy having your songs in album-order!"

exit 0
