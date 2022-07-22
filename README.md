# nef2jpeg
Script to automatically convert (Nikon) RAW files to jpeg files on my NAS

## SYNOPSIS
```console
nef2jpeg.sh [-p|--photos "path/to/scan"] [-t|--temp "path/for/temp/files"] [-j|--jpeg "foldername_for_jpegs"]
```

## DESCRIPTION
The script will search for NEF files in a folder (and it's subfolders) and convert the to JPEG files. Before conversion some automatic processing is performed to level enhancement and scale the image. The image is scaled to fit FullHD resolution (i.e. max 1920x1920). Level enhancement is performed using Fred Weinhaus' [redist](http://www.fmwconcepts.com/imagemagick/redist/index.php) with settings `-m GLOBAL 60,90,30`. Whitebalance is corrected using Fred Weinhaus' [whitebalancing](http://www.fmwconcepts.com/imagemagick/whitebalancing/index.php) with default settings.

## OPTIONS
`-p path` or `--photos path`
: Specify the path to scan for NEF files. Subfolders will be scanned recursively. Default: homefolder (~/)

`-t path` or `--temp path`
: Specify the path of a folder to use for temporary files (without tailing /). Default: /tmp

`-j string` or `--jpeg string`
: A name for the folder where the JPEG files are stored. The folder is created on the same level the NEF file is found. Default: jpeg_unedited

## DEPENDENCIES
The script makes use of
- [Exiftool](https://exiftool.org/)
- [LibRaw dcraw_emu](https://www.libraw.org/docs/Samples-LibRaw.html)
- [ImageMagick](https://imagemagick.org/)
- [bc](https://www.gnu.org/software/bc/)

It is tested on Ubuntu 20.04