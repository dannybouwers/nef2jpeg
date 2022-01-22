#!/bin/bash
#standard tool parameters
#imagick=(-resize 1920x1920 -colorspace HSL -channel B -auto-level +channel -colorspace sRGB)
#imagick=(-auto-level -auto-gamma -normalize -resize 1920x1920)
imagick=(-resize 1920x1920)
redist=(-m GLOBAL 60,80,40) #http://www.fmwconcepts.com/imagemagick/redist/index.php
dcraw=(-q 3 -o 1 -6 -g 2.4 12.92 -w) # https://www.image-engineering.de/library/technotes/720-have-a-look-at-the-details-the-open-source-raw-converter-dcraw

die() {
    printf '\033[1;31mERROR: %s\033[0m\n' "$@" >&2  # bold red
    exit 1
}

einfo() {
    printf '\n\033[1;36m%s\033[0m\n' "$@" >&2  # bold cyan
}

# parse params
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--temp) tmpfolder="$2"; shift ;;
        -p|--photos) photofolder="$2"; shift ;;
        -j|--jpeg) jpegfolder="$2"; shift ;;
        *) die "Unknown parameter passed: $1";;
    esac
    shift
done

# check dependencies
command -v exiftool >/dev/null 2>&1 || die "exiftool not available"
command -v /usr/lib/libraw/dcraw_emu >/dev/null 2>&1 || die "libraw-bin not available"
command -v convert >/dev/null 2>&1 || die "convert not available"
command -v bc >/dev/null 2>&1 || die "bc not available"

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

cd "`dirname "$0"`"

IFS=$'\n'
rawfiles=($(find "$photofolder" -type f -name "*NEF"))

for rawfile in "${rawfiles[@]}"
    do
    rawfolder="$(dirname $rawfile)"
    rawfilename="$(basename $rawfile)"
    filename=${rawfilename%\.*}

    # Check if folder exists
    if [ ! -d $rawfolder/$jpegfolder ]
    then
	    mkdir $rawfolder/$jpegfolder || die "Could not create folder ${rawfolder}/${jpegfolder}"

        ((logdirs+=1))
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
        (
            set -e
            # tmpfile=`echo -n "${jpegfile}" | md5sum | head -c 20`
            #tmpfile=$convertedfilename
            tmpfile="${tmpfolder}/${rawfilename}"
            
            # Convert RAW to JPEG
            #dcraw ${dcraw[@]} -c "${rawfile}" | convert - ${imagick[@]} "${tmpfolder}/${tmpfile}.jpg"
            # dcraw ${dcraw[@]} -c "${rawfile}" | convert - ${imagick[@]} MIFF:- | ./redist.sh ${redist[@]} MIFF:- "${tmpfolder}/${tmpfile}.jpg" \
            cp "${rawfile}" "${tmpfile}"

            /usr/lib/libraw/dcraw_emu ${dcraw[@]} "${tmpfile}" \
                || die "Could not convert file ${rawfilename} to PPM"

            convert "${tmpfile}.ppm" ${imagick[@]} MIFF:- | ./redist.sh ${redist[@]} MIFF:- "${tmpfile}.jpg" \
                || die "Could not convert file ${rawfilename}.ppm to JPG"

            # Copy Exif to JPG
            exiftool -quiet -overwrite_original -TagsFromFile "${tmpfile}" --Orientation "${tmpfile}.jpg" \
                || die "Could not copy EXIF from ${rawfilename}"

            #move file from temp
            cp --no-preserve=mode,ownership "${tmpfile}.jpg" "${jpegfile}"  \
                || die "Could not create ${jpegfile}"

            #clean up
            rm "${tmpfile}" "${tmpfile}.ppm" "${tmpfile}.jpg" \
                || die "Could not cleanup ${tmpfolder}/"
        )
        if [ $? -gt 0 ]
        then
            ((logerrors+=1))
        else
            ((logcreated+=1))
        fi
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
einfo "-- SETTINGS --"
echo "Scanned folder: ${photofolder}"
echo "Output folders: ${jpegfolder}"
einfo "-- RESULTS --"
echo "Processed RAW files: ${logfiles}"
echo "Folders created: ${logdirs}"
echo "Files created: ${logcreated}"
echo "Files Skipped: ${logskipped}"
echo "Runtime: $runhours:$runminutes:$runseconds (hh:mm:ss)"

#exit
if [ $logerrors -gt 0 ] ; then
    die "Errors: ${logerrors}"
else 
    exit 0
fi
