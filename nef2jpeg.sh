#!/bin/bash
jpegfolder="jpeg_onbewerkt"

IFS=$'\n'
rawfiles=($(find $1 -type f -name "*NEF"))

for rawfile in "${rawfiles[@]}"
    do
    echo $rawfile
    rawfolder="$(dirname $rawfile)"
    
    rawfilename="$(basename $rawfile)"
    
    filename=${rawfilename%\.*}

    # Check if folder exists
    if [ ! -d $rawfolder/$jpegfolder ] ; then
	    mkdir $rawfolder/$jpegfolder; 
    fi

    # Get creation date
    datetime=$( exiftool -f -d '%Y-%m-%d_%H.%M.%S' -s3 -"DateTimeOriginal" "${rawfile}" )
	
	if [ "${datetime}" = '-' ]; then
        datetime=$( exiftool -f -d '%Y-%m-%d_%H.%M.%S' -s3 -"MediaCreateDate" "${rawfile}" )
    fi

    convertedfilename=${datetime}${filename}

    # Check if jpeg exists
    if [ -f "$rawfolder/$jpegfolder/$convertedfilename.jpg" ]
	then
		echo "Skipped - JPEG already exists"
	else
        echo "${rawfolder}/${jpegfolder}/${convertedfilename}.jpg"
        # Convert RAW to TIFF
        # https://www.image-engineering.de/library/technotes/720-have-a-look-at-the-details-the-open-source-raw-converter-dcraw
        # https://www.mankier.com/1/dcraw

        # Resize and convert to JPG

        # Copy Exif to JPG
    fi
done