#!/bin/bash

#****************************************************************************** 
#****************************************************************************** 
#
#            Plex DVR Post Processing w/ffmpeg (H.264) Script
#
#****************************************************************************** 
#****************************************************************************** 
#  
#  Version: 1.0
#
#  Pre-requisites: 
#     ffmpeg
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
#      2. Uses ffmpeg (could be modified to use handbrake or other transcoder, 
#      but I chose this out of simplicity) to transcode the original, very 
#      large MPEG2 format file to a smaller, more manageable H.264 mp4 file 
#      (which can be streamed to my Roku boxes).
#
#      3. Copies the file back to the original filename for final processing
#
#****************************************************************************** 

#****************************************************************************** 
#  Do not edit below this line
#****************************************************************************** 

if [ ! -z "$1" ]; then 
# The if selection statement proceeds to the script if $1 is not empty.

   FILENAME=$1 	# %FILE% - Filename of original file

   TEMPFILENAME="$(mktemp).mkv"  # Temporary File for transcoding

   # Uncomment if you want to adjust the bandwidth for this thread
   #MYPID=$$	# Process ID for current script
   # Adjust niceness of CPU priority for the current process
   #renice 19 $MYPID

   echo "********************************************************" 
   echo "Starting Transcoding: Converting to H.264 w/ffmpeg @720p" 
   echo "********************************************************" 

   ffmpeg -i "$FILENAME" -s hd720 -c:v libx264 -preset veryfast -vf yadif -c:a copy "$TEMPFILENAME" 

   echo "********************************************************" 
   echo "Cleanup / Copy $TEMPFILENAME to $FILENAME" 
   echo "********************************************************" 

   rm -f "$FILENAME" # Delete original
   mv -f "$TEMPFILENAME" "$FILENAME" # Move completed temp to original filename
   chmod 777 "$FILENAME" # This step may not be neccessary, but hey why not.

   echo "********************************************************" 
   echo "Done.  Success!" 
   echo "********************************************************" 
else
   echo "********************************************************" 
   echo "PlexPostProc by nebhead"
   echo "Usage: $0 FileName" 
   echo "********************************************************" 
fi

