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
if [ -z "$tmpfolder" ]; then tmpfolder="/tmp"; fi;
if [ -z "$photofolder" ]; then photofolder="~/"; fi;
if [ -z "$jpegfolder" ]; then jpegfolder="jpeg_unedited"; fi;

# counters for logging
logfiles=0
logdirs=0
logerrors=0
logskipped=0
logcreated=0

IFS=$'\n'
rawfiles=($(find "$photofolder" -type f -name "*NEF"))

for rawfile in "${rawfiles[@]}"
    do
    rawfolder="$(dirname $rawfile)"
    rawfilename="$(basename $rawfile)"
    filename=${rawfilename%\.*}

    # Check if folder exists
    if [ ! -d $rawfolder/$jpegfolder ] ; then
	    mkdir $rawfolder/$jpegfolder; 

        if [ $? -eq 0 ] ; then
            ((logdirs+=1))
        else 
            echo "Could not create folder ${rawfolder}/${jpegfolder}" >&2
            exit 1
        fi
    fi

    # Get creation date
    datetime=$( exiftool -f -d '%Y-%m-%d_%H.%M.%S' -s3 -"DateTimeOriginal" "${rawfile}" )
	
	if [ "${datetime}" = '-' ]; then
        datetime=$( exiftool -f -d '%Y-%m-%d_%H.%M.%S' -s3 -"MediaCreateDate" "${rawfile}" )
    fi

    convertedfilename=${datetime}${filename}
    jpegfile="$rawfolder/$jpegfolder/$convertedfilename.jpg"

    # Check if jpeg exists
    if [ -f "$jpegfile" ]
	then
		((logskipped+=1))
	else
        tmpfile=$( echo -n "${jpegfile}" | openssl md5 )
        
        # Convert RAW to TIFF
        # https://www.image-engineering.de/library/technotes/720-have-a-look-at-the-details-the-open-source-raw-converter-dcraw
        # https://www.mankier.com/1/dcraw
        
        #dcraw -q 3 -o 1 -6 -g 2.4 12.92 -w -T -c "${rawfile}" | convert - -resize 1920x1920 -auto-gamma -auto-level -normalize "${tmpfolder}/${tmpfile}.jpg"
        dcraw -q 3 -o 1 -6 -g 2.4 12.92 -w -T -c "${rawfile}" | convert - -resize 1920x1920 -colorspace YCbCr -channel 0 -normalize +channel -colorspace sRGB "${tmpfolder}/${tmpfile}.jpg"
        
        if [ $? -gt 0 ] ; then
            echo "Could not convert file ${rawfile}" >&2
            ((logerrors+=1))
        fi

        # Copy Exif to JPG
        exiftool -quiet -overwrite_original -TagsFromFile "${rawfile}" --Orientation "${tmpfolder}/${tmpfile}.jpg"
        
        if [ $? -gt 0 ] ; then
            echo "Could not copy EXIF of ${rawfile}" >&2
            ((logerrors+=1))
        fi

        #move file from temp
        mv "${tmpfolder}/${tmpfile}.jpg" "${jpegfile}"

        if [ $? -gt 0 ] ; then
            echo "Could not move ${jpegfile}" >&2
            ((logerrors+=1))
        fi

        ((logcreated+=1))
    fi

    ((logfiles+=1))
done

echo ""
echo "-- SUMMARY --"
echo "Processed RAW files: ${logfiles}"
echo "Folders created: ${logdirs}"
echo "Files created: ${logcreated}"
echo "Files Skipped: ${logskipped}"
echo "Errors: ${logerrors}"

if [ $logerrors -gt 0 ] ; then
    exit 1
else 
    exit 0
fi