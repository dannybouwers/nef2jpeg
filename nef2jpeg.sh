#!/bin/bash
# parse params
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--temp) tmpfolder="$2"; shift ;;
        -p|--photos) photofolder="$2"; shift ;;
        -j|--jpeg) jpegfolder="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# verify params and set defaults
if [ -z "$tmpfolder" ]; then tmpfolder="/tmp/"; fi;
if [ -z "$photofolder" ]; then photofolder="~/"; fi;
if [ -z "$jpegfolder" ]; then jpegfolder="jpeg_unedited"; fi;

echo "tmpfolder: $tmpfolder"
echo "photofolder: $photofolder"
echo "jpegfolder: $jpegfolder"

exit 1

IFS=$'\n'
rawfiles=($(find "$photofolder" -type f -name "*NEF"))

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