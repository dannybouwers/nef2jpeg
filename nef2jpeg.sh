#!/bin/bash
#standard tool parameters
#imagick=(-resize 1920x1920 -colorspace LAB -channel 0 -auto-level +channel -colorspace sRGB)
imagick=(-auto-level -auto-gamma -normalize -resize 1920x1920)
dcraw=(-q 3 -o 1 -6 -g 2.4 12.92 -w -T) # https://www.image-engineering.de/library/technotes/720-have-a-look-at-the-details-the-open-source-raw-converter-dcraw


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

#starttime
starttime=`date +%s`

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
        
        # Convert RAW to JPEG
        dcraw ${dcraw[@]} -c "${rawfile}" | convert - ${imagick[@]} "${tmpfolder}/${tmpfile}.jpg"
        
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

#calculate runtime
endtime=`date +%s`
runtime=$((endtime-starttime))
runhours=$((runtime / 3600));
runminutes=$(( (runtime % 3600) / 60 ));
runseconds=$(( (runtime % 3600) % 60 )); 

#print statistics
echo "-- SETTINGS --"
echo "Scanned folder: ${photofolder}"
echo "Output folders: ${jpegfolder}"
echo "-- RESULTS --"
echo "Processed RAW files: ${logfiles}"
echo "Folders created: ${logdirs}"
echo "Files created: ${logcreated}"
echo "Files Skipped: ${logskipped}"
echo "Errors: ${logerrors}"
echo "Runtime: $runhours:$runminutes:$runseconds (hh:mm:ss)"

#exit
if [ $logerrors -gt 0 ] ; then
    exit 1
else 
    exit 0
fi