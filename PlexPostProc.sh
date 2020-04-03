#!/bin/bash

#******************************************************************************
#******************************************************************************
#
#            Plex DVR Post Processing Script
#
#******************************************************************************
#******************************************************************************
#
#  Version: 2.0
#
#  Pre-requisites:
#     ffmpeg or handbrakecli
#
#  Usage:
#     'PlexPostProc.sh %1'
#
#  Description:
#      My script is currently pretty simple.  Here's the general flow:
#
#      1. Creates a temporary directory in the /tmp directory for
#      the show it is about to transcode.
#
#      2. Uses the selected encoder to transcode the original, very
#      large MPEG2 format file to a smaller, more manageable H.264 mkv file
#      (which can be streamed to various devices more easily).
#
#      3. Copies the file back to the original .grab folder for final processing
#
#  Log:
#     Logs will be generated for each encode with the format:
#         plexppYYYYMMDD-HHMMSS.logging
#     Note: Logs are not deleted, so some cleanup of the temp directory may be
#       required, or a server reboot should clear this folder.
#
#******************************************************************************

TMPFOLDER="/tmp"
ENCODER="ffmpeg"  # Encoder to use:
                  # "ffmpeg" for FFMPEG [DEFAULT]
                  # "handbrake" for HandBrake
RES="720"         # Resolution to convert to:
                  # "720" = 720 Vertical Resolution
                  # "1080" = 1080 Vertical Resolution

#******************************************************************************
#  Do not edit below this line
#******************************************************************************

check_errs()
{
        # Function. Parameter 1 is the return code
        # Para. 2 is text to display on failure
        if [ "${1}" -ne "0" ]; then
           echo "ERROR # ${1} : ${2}" | tee -a $LOGFILE
           exit ${1}
        fi
}

if [ ! -z "$1" ]; then
# The if selection statement proceeds to the script if $1 is not empty.
   if [ ! -f "$1" ]; then 
      fatal "$1 does not exist"
   fi
   # The above if selection statement checks if the file exists before proceeding. 
   
   FILENAME=$1 	# %FILE% - Filename of original file

   TEMPFILENAME="$(mktemp).mkv"  # Temporary File Name for transcoding

   LOCKFILE="$(mktemp).ppplock"  # [WORKAROUND] Temporary File for blocking simultaneous scripts from ending early
   touch $LOCKFILE # Create the lock file
   check_errs $? "Failed to create temporary lockfile: $LOCKFILE"

   LOGFILE="$TMPFOLDER/plexpp$(date +"%Y%m%d-%H%M%S").log" # Create a unique log file.
   touch $LOGFILE # Create the log file

   # Uncomment if you want to adjust the bandwidth for this thread
   #MYPID=$$	# Process ID for current script
   # Adjust niceness of CPU priority for the current process
   #renice 19 $MYPID

   # ********************************************************
   # Starting Transcoding
   # ********************************************************

   echo "$(date +"%Y%m%d-%H%M%S"): Starting transcode of $FILENAME to $TEMPFILENAME" | tee -a $LOGFILE
   if [[ $ENCODER == "handbrake" ]]; then
     echo "You have selected HandBrake" | tee -a $LOGFILE
     HandBrakeCLI -i "$FILENAME" -f mkv --aencoder copy -e qsv_h264 --x264-preset veryfast --x264-profile auto -q 16 --maxHeight $RES --decomb bob -o "$TEMPFILENAME"
     check_errs $? "Failed to convert using Handbrake."
   elif [[ $ENCODER == "ffmpeg" ]]; then
     echo "You have selected FFMPEG" | tee -a $LOGFILE
     ffmpeg -i "$FILENAME" -s hd$RES -c:v libx264 -preset veryfast -vf yadif -c:a copy "$TEMPFILENAME"
     check_errs $? "Failed to convert using FFMPEG."
   else
     echo "Oops, invalid ENCODER string.  Using Default [FFMpeg]." | tee -a $LOGFILE
     ffmpeg -i "$FILENAME" -s hd$RES -c:v libx264 -preset veryfast -vf yadif -c:a copy "$TEMPFILENAME"
     check_errs $? "Failed to convert using FFMPEG."
   fi

   # ********************************************************"
   # Encode Done. Performing Cleanup
   # ********************************************************"

   echo "$(date +"%Y%m%d-%H%M%S"): Finished transcode of $FILENAME to $TEMPFILENAME" | tee -a $LOGFILE

   rm -f "$FILENAME" # Delete original in .grab folder
   check_errs $? "Failed to remove original file: $FILENAME"

   mv -f "$TEMPFILENAME" "${FILENAME%.ts}.mkv" # Move completed tempfile to .grab folder/filename
   check_errs $? "Failed to move converted file: $TEMPFILENAME"

   rm -f "$LOCKFILE" # Delete the lockfile after completing
   check_errs $? "Failed to remove lockfile."

   # [WORKAROUND] Wait for any other post-processing scripts to complete before exiting.
   while [ true ] ; do
     if ls "$TMPFOLDER/"*".ppplock" 1> /dev/null 2>&1; then
       echo "$(date +"%Y%m%d-%H%M%S"): Looks like there is another scripting running.  Waiting." | tee -a $LOGFILE
       sleep 5
     else
       echo "$(date +"%Y%m%d-%H%M%S"): It looks like all scripts are done running, exiting." | tee -a $LOGFILE
       break
     fi
   done

   echo "$(date +"%Y%m%d-%H%M%S"): Encode done.  Exiting." | tee -a $LOGFILE

else
   echo "********************************************************" | tee -a $LOGFILE
   echo "PlexPostProc by nebhead" | tee -a $LOGFILE
   echo "Usage: $0 FileName" | tee -a $LOGFILE
   echo "********************************************************" | tee -a $LOGFILE
fi

rm -f "$TMPFOLDER/"*".ppplock"  # Make sure all lock files are removed, just in case there was an error somewhere in the script
