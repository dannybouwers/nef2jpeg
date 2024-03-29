#!/bin/bash
#
# Developed by Fred Weinhaus 3/31/2020 .......... revised 7/7/2020
#
# ------------------------------------------------------------------------------
# 
# Licensing:
# 
# Copyright © Fred Weinhaus
# 
# My scripts are available free of charge for non-commercial use, ONLY.
# 
# For use of my scripts in commercial (for-profit) environments or 
# non-free applications, please contact me (Fred Weinhaus) for 
# licensing arrangements. My email address is fmw at alink dot net.
# 
# If you: 1) redistribute, 2) incorporate any of these scripts into other 
# free applications or 3) reprogram them in another scripting language, 
# then you must contact me for permission, especially if the result might 
# be used in a commercial or for-profit environment.
# 
# My scripts are also subject, in a subordinate manner, to the ImageMagick 
# license, which can be found at: http://www.imagemagick.org/script/license.php
# 
# ------------------------------------------------------------------------------
# 
####
#
# USAGE: whitebalancing [-b blackpt ] [-w whitept] [-g gammaval] [-s sigmoid] 
# [-v vibrance] infile outfile
# USAGE: whitebalancing [-h or -help]
# 
# OPTIONS:
#
# -b     blackpt      black point percent value for level adjustment of the L 
#                     channel; 0<=integer<=100; default=0 (no change)                   
# -w     whitept      white point percent value for level adjustment of the L 
#                     channel; 0<=integer<=100; default=100 (no change)
# -g     gammaval     gamma value for non-linear adjustment on the L channel;  
#                     float>0; default=1 (no change)
# -s     sigmoid      sigmoidal contrast value for non-linear adjustment of 
#                     the L channel; float (positive or negative); default=0 
#                     (no change)                      
# -v     vibrance     percent change in color vibrance (saturation); integer 
#                     (positive or negative; default=0 (no change)                      
# 
###
# 
# NAME: WHITEBALANCING
# 
# PURPOSE: To apply white balancing to an image and optionally apply 
# brightness/contrast/vibrance enhancement.
# 
# DESCRIPTION: WHITEBALANCING applies white balancing to an image according  
# to a gray world method in LAB colorspace and optionally applies 
# brightness/contrast/vibrance enhancement. There are no specific arguments 
# for adjusting the white balancing.
# 
# Arguments: 
# 
# -b blackpt ... BLACKPT is the black point percent value for level adjustment 
# of the L channel. Values are integers between 0 and 100. The default=0 
# (no change) 
#                  
# -w whitept ... WHITEPT is the white point percent value for level adjustment 
# of the L channel. Values are integers between 0 and 100. The default=0 
# (no change)
#               
# -g gammaval ... GAMMAVAL is the gamma value for non-linear adjustment on the 
# L channel. Values are floats greater than 0. The default=1 (no change)
# 
# -s sigmoid ... SIGMOID is the sigmoidal contrast value for non-linear 
# adjustment of the L channel. Values are floats (positive or negative). The
# default=0 (no change)
#                      
# -v vibrance ... VIBRANCE is the percent change in color vibrance 
# (saturation). Values are integers (positive or negative). The default=0 
# (no change)                      
# 
# REQUIREMENTS: IM 6.7.8.2 or higher, when the LAB colorspace conversions were 
# fixed. But requires HDMI for correct output results
# 
# REFERENCES: 
# https://pippin.gimp.org/image-processing/chapter-automaticadjustments.html
# http://digital-photography-school.com/turn-ho-hum-color-into-wow-with-photoshop
# 
# CAVEAT: No guarantee that this script will work on all platforms, 
# nor that trapping of inconsistent parameters is complete and 
# foolproof. Use At Your Own Risk. 
# 
######
#

# set default values
blackpt=0			# blackpt percent for level operation on L channel; integer 0 to 100
whitept=100			# whitept percent for level operation on L channel; integer 0 to 100
gammaval=1			# gamma amount for level operation on L channel; float>0
sigmoid=0			# sigmoidal contrast operation on L channel; float (positive or negative)
vibrance=0			# color enhancement percent level operation of AB channels; integer 0 to 100

# set directory for temporary files
dir="."    # suggestions are dir="." or dir="/tmp"

# set up functions to report Usage and Usage with Description
PROGNAME=`type $0 | awk '{print $3}'`  # search for executable on path
PROGDIR=`dirname $PROGNAME`            # extract directory of program
PROGNAME=`basename $PROGNAME`          # base name of program
usage1() 
	{
	echo >&2 ""
	echo >&2 "$PROGNAME:" "$@"
	sed >&2 -e '1,/^####/d;  /^###/g;  /^#/!q;  s/^#//;  s/^ //;  4,$p' "$PROGDIR/$PROGNAME"
	}
usage2() 
	{
	echo >&2 ""
	echo >&2 "$PROGNAME:" "$@"
	sed >&2 -e '1,/^####/d;  /^######/g;  /^#/!q;  s/^#*//;  s/^ //;  4,$p' "$PROGDIR/$PROGNAME"
	}

# function to report error messages
errMsg()
	{
	echo ""
	echo $1
	echo ""
	usage1
	exit 1
	}

# function to test for minus at start of value of second part of option 1 or 2
checkMinus()
	{
	test=`echo "$1" | grep -c '^-.*$'`   # returns 1 if match; 0 otherwise
    [ $test -eq 1 ] && errMsg "$errorMsg"
	}

# test for correct number of arguments and get values
if [ $# -eq 0 ]
	then
	# help information
	echo ""
	usage2
	exit 0
elif [ $# -gt 12 ]
	then
	errMsg "--- TOO MANY ARGUMENTS WERE PROVIDED ---"
else
	while [ $# -gt 0 ]
		do
		# get parameters
		case "$1" in
	  -h|-help)    # help information
				   echo ""
				   usage2
				   ;;
			-b)    # get blackpt
				   shift  # to get the next parameter
				   # test if parameter starts with minus sign 
				   errorMsg="--- INVALID BLACKPT SPECIFICATION ---"
				   checkMinus "$1"
				   blackpt=`expr "$1" : '\([0-9]*\)'`
				   [ "$blackpt" = "" ] && errMsg "--- BLACKPT=$blackpt MUST BE AN INTEGER ---"
				   test1=`echo "$blackpt < 0" | bc`
				   test2=`echo "$blackpt > 100" | bc`
				   [ $test1 -eq 1 -o $test2 -eq 1 ] && errMsg "--- BLACKPT=$blackpt MUST BE AN INTEGER BETWEEN 0 AND 100 ---"
				   ;;
			-w)    # get whitept
				   shift  # to get the next parameter
				   # test if parameter starts with minus sign 
				   errorMsg="--- INVALID WHITEPT SPECIFICATION ---"
				   checkMinus "$1"
				   whitept=`expr "$1" : '\([0-9]*\)'`
				   [ "$whitept" = "" ] && errMsg "--- WHITEPT=$whitept MUST BE AN INTEGER ---"
				   test1=`echo "$whitept < 0" | bc`
				   test2=`echo "$whitept > 100" | bc`
				   [ $test1 -eq 1 -o $test2 -eq 1 ] && errMsg "--- WHITEPT=$whitept MUST BE AN INTEGER BETWEEN 0 AND 100 ---"
				   ;;
			-g)    # get gammaval
				   shift  # to get the next parameter
				   # test if parameter starts with minus sign 
				   errorMsg="--- INVALID GAMMAVAL SPECIFICATION ---"
				   checkMinus "$1"
				   gammaval=`expr "$1" : '\([.0-9]*\)'`
				   [ "$gammaval" = "" ] && errMsg "--- GAMMAVAL=$gammaval MUST BE A NON-NEGATIVE FLOAT (with no sign) ---"
				   test1=`echo "$gammaval <= 0" | bc`
				   [ $test1 -eq 1 ] && errMsg "--- GAMMAVAL=$gammaval MUST BE A POSITIVE FLOAT ---"
				   ;;
			-s)    # get sigmoid
				   shift  # to get the next parameter
				   # test if parameter starts with minus sign 
				   errorMsg="--- INVALID SIGMOID SPECIFICATION ---"
				   #checkMinus "$1"
				   sigmoid=`expr "$1" : '\([-.0-9]*\)'`
				   [ "$sigmoid" = "" ] && errMsg "--- SIGMOID=$sigmoid MUST BE A FLOAT ---"
				   ;;
			-v)    # get vibrance
				   shift  # to get the next parameter
				   # test if parameter starts with minus sign 
				   errorMsg="--- INVALID VIBRANCE SPECIFICATION ---"
				   #checkMinus "$1"
				   vibrance=`expr "$1" : '\([-0-9]*\)'`
				   [ "$vibrance" = "" ] && errMsg "--- VIBRANCE=$vibrance MUST BE AN INTEGER ---"
				   ;;
			 -)    # STDIN and end of arguments
				   break
				   ;;
			-*)    # any other - argument
				   errMsg "--- UNKNOWN OPTION ---"
				   ;;
			*)     # end of arguments
				   break
				   ;;
		esac
		shift   # next option
	done
	# get infile and outfile
	infile="$1"
	outfile="$2"
	dir=`dirname $outfile`
fi

# test that infile provided
[ "$infile" = "" ] && errMsg "--- NO INPUT FILE SPECIFIED ---"

# test that outfile provided
[ "$outfile" = "" ] && errMsg "--- NO OUTPUT FILE SPECIFIED ---"

# get im_version
im_version=`convert -list configure | \
	sed '/^LIB_VERSION_NUMBER */!d; s//,/;  s/,/,0/g;  s/,0*\([0-9][0-9]\)/\1/g' | head -n 1`

# test for hdri enabled
# NOTE: must put grep before trap using ERR in case it does not find a match
if [ "$im_version" -ge "07000000" ]; then
	hdri_on=`convert -version | grep "HDRI"`	
else
	hdri_on=`convert -list configure | grep "enable-hdri"`
fi
[ "$hdri_on" = "" ] && echo "--- WARNING: REQUIRES HDRI ENABLED IN IM COMPILE FOR PROPER RESULTS ---"

# test for proper IM version for LAB processing
[ "$im_version" -lt "06070802" ] && errMsg "--- REQUIRES IM 6.7.8.2 OR HIGHER  ---"

# set up temp file
tmpA1="$dir/whitebalancing_1_$$.pfm"
tmpA2="$dir/whitebalancing_2_$$.pfm"
trap "rm -f $tmpA1 $tmpA2;" 0
trap "rm -f $tmpA1 $tmpA2; exit 1" 1 2 3 15
#trap "rm -f $tmpA1 $tmpA2; exit 1" ERR


# read the input image into the temp files and test validity.
convert -quiet "$infile" +repage "$tmpA1" ||
	errMsg "--- FILE $infile1 DOES NOT EXIST OR IS NOT AN ORDINARY FILE, NOT READABLE OR HAS ZERO SIZE  ---"


# set up colorization to be symmetric linear transform properly centered and used equally on both A and B channels
low=$vibrance
high=$((100-$vibrance))

# test for sign to use for sigmoidal-contrast function
test=`convert xc: -format "%[fx:$sigmoid<0?1:0]" info:`
if [ $test -eq 1 ]; then 
	sign="+"
else
	sign="-"
fi


# allow sigmoidal contrast of zero to be close to zero but not exactly equal where it degenerates
# convert sigmoid to absolute value
sigmoid=`convert xc: -format "%[fx:abs($sigmoid)]" info:`

# test if sigmoid too close to zero
[ "$sigmoid" = "0" ] && sigmoid=0.001
	

# process image
if [ "$blackpt" = "0" -a "$whitept" = "100" -a "$gammaval" = "1" -a "$sigmoid" = "0" -a "$vibrance" = "0" ]; then

	convert $tmpA1 -colorspace LAB -separate +channel $tmpA2
	meanA=`convert $tmpA2[1] -format "%[fx:(mean-0.5)]" info:`
	meanB=`convert $tmpA2[2] -format "%[fx:(mean-0.5)]" info:`
	convert $tmpA2[0] +write mpr:lum \
		\( $tmpA2[1]  \( mpr:lum -evaluate multiply $meanA \) +swap -define compose:clamp=off \
			-compose minus -composite \) \
		\( $tmpA2[2]  \( mpr:lum -evaluate multiply $meanB \) +swap -define compose:clamp=off \
			-compose minus -composite \) \
		-set colorspace LAB -combine -colorspace sRGB \
		"$outfile"

else

	convert $tmpA1 -colorspace LAB -separate +channel $tmpA2
	meanA=`convert $tmpA2[1] -format "%[fx:(mean-0.5)]" info:`
	meanB=`convert $tmpA2[2] -format "%[fx:(mean-0.5)]" info:`
	convert $tmpA2[0] +write mpr:lum \
		-level ${blackpt}%,${whitept}%,$gammaval ${sign}sigmoidal-contrast ${sigmoid},50% +channel \
		\( $tmpA2[1]  \( mpr:lum -evaluate multiply $meanA \) +swap -define compose:clamp=off \
			-compose minus -composite -level ${low}%,${high}% +channel \) \
		\( $tmpA2[2]  \( mpr:lum -evaluate multiply $meanB \) +swap -define compose:clamp=off \
			-compose minus -composite -level ${low}%,${high}% +channel \) \
		-set colorspace LAB -combine -colorspace sRGB \
	"$outfile"

fi


exit 0