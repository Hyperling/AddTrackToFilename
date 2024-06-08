#!/bin/bash
# 2024-06-07 C.Greenwood
# Rename all files in a music library based on metadata.
# Uses the format "[Track]. [Title].mp3"

## Variables ##

PROG="`basename $0`"
#DIR="`dirname $0`"
DIR="`pwd`"
EXT=".mp3"

## Functions ##

function usage {
	cat <<- EOF
		Usage:
		  $PROG [-h] [-u]

		Parameters:
		  -h : Help, display the usage and exit succesfully.

		Place this file at the root of your music destined for a flash drive and run it without any parameters.
		It will dive through all folders and convert your MP3's to have the Track# and Title in the filename.

		This tool has a pre-requisite you should make sure you have installed:
		  - exiftool

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
time find $DIR -name "*${EXT}" | sort | while read file; do

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
	if [[ "$file" == "$new_file" ]]; then
		echo "SKIP: Filename already correct! :)"
		continue
	fi

	if [[ ! -z "$track" && ! -z "$title" ]]; then
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

echo -e "\nProcess has completed. Enjoy having your songs named correctly!"

exit 0
