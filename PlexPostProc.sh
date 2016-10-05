#!/bin/sh

#****************************************************************************** 
#****************************************************************************** 
#
#            Plex DVR Post Processing w/Handbrake (H.264) Script
#
#****************************************************************************** 
#****************************************************************************** 
#  
#  Version: 1.0
#
#  Pre-requisites: 
#     HandBrakeCLI
#
#
#  Usage: 
#     'PlexPostProc.sh %1'
#
#  Description:
#      My script is currently pretty simple.  Here's the general flow:
#
#      1. Creates a temporary directory in the home directory for 
#      the show it is about to transcode.
#
#      2. Uses Handbrake (could be modified to use ffmpeg or other transcoder, 
#      but I chose this out of simplicity) to transcode the original, very 
#      large MPEG2 format file to a smaller, more manageable H.264 mp4 file 
#      (which can be streamed to my Roku boxes).
#
#	   3. Copies the file back to the original filename for final processing
#
#****************************************************************************** 

#****************************************************************************** 
#  Do not edit below this line
#****************************************************************************** 

FILENAME=$1 	# %FILE% - Filename of original file

TEMPFILENAME="$(mktemp)"  # Temporary File for transcoding

# Uncomment if you want to adjust the bandwidth for this thread
#MYPID=$$	# Process ID for current script
# Adjust niceness of CPU priority for the current process
#renice 19 $MYPID

echo "********************************************************"
echo "Transcoding, Converting to H.264 w/Handbrake"
echo "********************************************************"
HandBrakeCLI -i "$FILENAME" -o "$TEMPFILENAME" -e X264 -q 20 -a 1 -E copy:aac -B 160 -6 dp12 -R Auto -D0.0 --audio-copy-mask aac --audio-fallback faac -f mp4 --loose-anamorphic --modulus 2 -m --x264-preset veryfast --h264-profile auto --h264-level 4.0 --maxHeight 720

echo "********************************************************"
echo "Cleanup / Copy $TEMPFILENAME to $FILENAME"
echo "********************************************************"

rm -f "$FILENAME"
mv -f $TEMPFILENAME "$FILENAME"
chmod 777 "$FILENAME" # This step may no tbe neccessary, but hey why not.

echo "Done.  Congrats!"

