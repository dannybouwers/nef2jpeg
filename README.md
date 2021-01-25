# nef2jpeg
Script to automatically convert (Nikon) RAW files to jpeg files on my NAS

## SYNOPSIS
```console
nef2jpeg.sh [-p|--photos "path/to/scan"] [-t|--temp "path/for/temp/files"] [-j|--jpeg "foldername_for_jpegs"]
```

## DESCRIPTION
The script will search for NEF files in a folder (and it's subfolders) and convert the to JPEG files. Before conversion some automatic processing is performed to enhance the curve and scale the image.

The script is designed to be used in a periodic cron job on a Synology NAS.

## OPTIONS
`-p path` or `--photos path`
: Specify the path to scan for NEF files. Subfolders will be scanned recursively. Default: homefolder (~/)

`-t path` or `--temp path`
: Specify the path of a folder to use for temporary files. Default: /tmp

`-j string` or `--jpeg string`
: A name for the folder where the JPEG files are stored. The folder is created on the same level the NEF file is found. Default: jpeg_unedited

## DEPENDENCIES
The script makes use of
- [Exiftool](https://exiftool.org/)
- [DCRaw](https://www.dechifro.org/dcraw/)
- [ImageMagick](https://imagemagick.org/)