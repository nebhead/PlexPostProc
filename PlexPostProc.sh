#!/bin/bash

#******************************************************************************
#******************************************************************************
#
#            Plex DVR Post Processing Script
#
#******************************************************************************
#******************************************************************************
#
#  Version: 2022.2.2
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
                  # "nvtrans" for Plex Transcoder with NVENC support
RES="720"         # Resolution to convert to:
                  # "480" = 480 Vertical Resolution
                  # "720" = 720 Vertical Resolution
                  # "1080" = 1080 Vertical Resolution


#**************************FFMPEG SPECIFIC SETTINGS****************************
AUDIO_CODEC="aac" # From best to worst: libfdk_aac > libmp3lame/eac3/ac3 > aac. But libfdk_acc requires manual compilaton of ffmpeg. For OTA DVR standard acc should be enough.
AUDIO_BITRATE=96
VIDEO_CODEC="libx265" # Will need Ubuntu 18.04 LTS or later. Otherwise change to "libx264". On average libx265 should produce files half in size of libx264  without losing quality. It is more compute intensive, so transcoding will take longer.
VIDEO_QUALITY=26 #Lower values produce better quality. It is not recommended going lower than 18. 26 produces around 1Mbps video, 23 around 1.5Mbps.
VIDEO_FRAMERATE="24000/1001" #Standard US movie framerate, most US TV shows run at this framerate as well

DOWNMIX_AUDIO=2 #Number of channels to downmix to, set to 0 to turn off (Make sure to increase audio bitrate to accomodate all the needed bitrate. For 5.1 Id set no lower than 320). 1 == mono, 2 == stereo, 6 == 5.1

#******************************************************************************
#  Do not edit below this line
#******************************************************************************

sleep 3

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

   FILENAME=$1  # %FILE% - Filename of original file

   FILESIZE="$(ls -lh "$FILENAME" | awk '{ print $5 }')"

   TEMPFILENAME="$(mktemp).mkv"  # Temporary File Name for transcoding

   LOCKFILE="$(mktemp).ppplock"  # [WORKAROUND] Temporary File for blocking simultaneous scripts from ending early
   touch $LOCKFILE # Create the lock file
   check_errs $? "Failed to create temporary lockfile: $LOCKFILE"

   LOGFILE="$TMPFOLDER/plex_DVR_post_processing_log"
   touch $LOGFILE # Create the log file

   # Uncomment if you want to adjust the bandwidth for this thread
   #MYPID=$$    # Process ID for current script
   # Adjust niceness of CPU priority for the current process
   #renice 19 $MYPID

   # ********************************************************
   # Starting Transcoding
   # ********************************************************

   printf "$(date +"%Y%m%d-%H%M%S"): Transcoding $FILENAME to $TEMPFILENAME\n" | tee -a $LOGFILE
   if [[ $ENCODER == "handbrake" ]]; then
     echo "You have selected HandBrake" | tee -a $LOGFILE
     HandBrakeCLI -i "$FILENAME" -f mkv --aencoder copy -e qsv_h264 --x264-preset veryfast --x264-profile auto -q 16 --maxHeight $RES --decomb bob -o "$TEMPFILENAME"
     check_errs $? "Failed to convert using Handbrake."
   elif [[ $ENCODER == "ffmpeg" ]]; then
     printf "Using FFMPEG" | tee -a $LOGFILE
     printf " [$FILESIZE -> " | tee -a $LOGFILE
     start_time=$(date +%s)
     if [[ $DOWNMIX_AUDIO -ne  0 ]]; then
         ffmpeg -i "$FILENAME" -s hd$RES -c:v "$VIDEO_CODEC" -r "$VIDEO_FRAMERATE"  -preset veryfast -crf "$VIDEO_QUALITY" -vf yadif -codec:a "$AUDIO_CODEC" -ac "$DOWNMIX_AUDIO" -b:a "$AUDIO_BITRATE"k -async 1 "$TEMPFILENAME"
     else
         ffmpeg -i "$FILENAME" -s hd$RES -c:v "$VIDEO_CODEC" -r "$VIDEO_FRAMERATE"  -preset veryfast -crf "$VIDEO_QUALITY" -vf yadif -codec:a "$AUDIO_CODEC" -b:a "$AUDIO_BITRATE"k -async 1 "$TEMPFILENAME"
     fi
     end_time=$(date +%s)
     seconds="$(( end_time - start_time ))"
     minutes_taken="$(( seconds / 60 ))"
     seconds_taken="$(( $seconds - (minutes_taken * 60) ))"
     printf "$(ls -lh $TEMPFILENAME | awk ' { print $5 }')] - [$minutes_taken min $seconds_taken sec]\n" | tee -a $LOGFILE
     check_errs $? "Failed to convert using FFMPEG."
   elif [[ $ENCODER == "nvtrans" ]]; then
     export FFMPEG_EXTERNAL_LIBS="$(find ~/Library/Application\ Support/Plex\ Media\ Server/Codecs/ -name "libmpeg2video_decoder.so" -printf "%h\n")/"
     check_errs $? "Failed to convert using smart Plex Transcoder (NVENC). libmpeg2video_decoder.so not found."
     export LD_LIBRARY_PATH="/usr/lib/plexmediaserver:/usr/lib/plexmediaserver/lib/"

     # Grab some dimension and framerate info so we can set bitrates
     HEIGHT="$(/usr/lib/plexmediaserver/Plex\ Transcoder -i "$FILENAME" 2>&1 | grep "Stream #0:0" | perl -lane 'print $1 if /, \d{3,}x(\d{3,})/')"
     FPS="$(/usr/lib/plexmediaserver/Plex\ Transcoder -i "$FILENAME" 2>&1 | grep "Stream #0:0" | perl -lane 'print $1 if /, (\d+(.\d+)*) fps/')"

     if [[ -z "${HEIGHT}" ]]; then
             # Failed to get dimensions of source... try a dumb transcode.
             /usr/lib/plexmediaserver/Plex\ Transcoder -y -hide_banner -hwaccel nvdec -i "$FILENAME" -s hd$RES -c:v h264_nvenc -preset veryfast -c:a copy "$TEMPFILENAME"
             check_errs $? "Failed to convert using simple Plex Transcoder (NVENC)."
           else
             # Smart transcode based on source dimensions and fps
       # Bitrate vlaues (Mb). Assuming 1080i30 (ATSC max) has same needs as 720p60
       # Assuming 60 fps needs 2x bitrate than 30 fps
       MULTIPLIER=$(echo - | perl -lane "if (${FPS} < 59) {print 1.0} else {print 2.0}")
       ABR=$(echo - | perl -lane "if (${HEIGHT} < 720) {print 1*${MULTIPLIER}} elsif (${HEIGHT} < 1080) {print 2*${MULTIPLIER}} else {print 4*${MULTIPLIER}}")
       MBR=$(echo - | perl -lane "print ${ABR} * 1.5")
       BUF=$(echo - | perl -lane "print ${MBR} * 2.0")
       /usr/lib/plexmediaserver/Plex\ Transcoder -y -hide_banner -hwaccel nvdec -i "$FILENAME" -c:v h264_nvenc -b:v "${ABR}M" -maxrate:v "${MBR}M" -profile:v high -bf:v 3 -bufsize:v "${BUF}M" -preset:v hq -forced-idr:v 1 -c:a copy "$TEMPFILENAME"
             check_errs $? "Failed to convert using smart Plex Transcoder (NVENC)."
          fi
   else
     echo "Oops, invalid ENCODER string.  Using Default [FFMpeg]." | tee -a $LOGFILE
     ffmpeg -i "$FILENAME" -s hd$RES -c:v libx264 -preset veryfast -vf yadif -c:a copy "$TEMPFILENAME"
     check_errs $? "Failed to convert using FFMPEG."
   fi

   # ********************************************************"
   # Encode Done. Performing Cleanup
   # ********************************************************"

   printf "$(date +"%Y%m%d-%H%M%S"): Finished transcode, " | tee -a $LOGFILE

   rm -f "$FILENAME" # Delete original in .grab folder
   check_errs $? "Failed to remove original file: $FILENAME"

   mv -f "$TEMPFILENAME" "${FILENAME%.ts}.mkv" # Move completed tempfile to .grab folder/filename
   check_errs $? "Failed to move converted file: $TEMPFILENAME"

   rm -f "$LOCKFILE" # Delete the lockfile after completing
   check_errs $? "Failed to remove lockfile."

   # [WORKAROUND] Wait for any other post-processing scripts to complete before exiting.
   timeout_counter=120
   while [ true ] ; do
     if ls "$TMPFOLDER/"*".ppplock" 1> /dev/null 2>&1; then
       if  [[ $timeout_counter -eq 0 ]]; then
           echo "Timeout reached, ending wait" | tee -a $LOGFILE
           break
       fi
       echo "\n$(date +"%Y%m%d-%H%M%S"): Looks like there is another scripting running.  Waiting." | tee -a $LOGFILE
       timeout_counter=$((timeout_counter-1))
       sleep 60
     else
       if  [[ $timeout_counter -lt 119 ]]; then
           echo "$(date +"%Y%m%d-%H%M%S"): It looks like all scripts are done running, exiting." | tee -a $LOGFILE
       fi
       break
     fi
   done

   printf "exiting. \n\n" | tee -a $LOGFILE

else
   echo "********************************************************" | tee -a $LOGFILE
   echo "PlexPostProc by nebhead" | tee -a $LOGFILE
   echo "Usage: $0 FileName" | tee -a $LOGFILE
   echo "********************************************************" | tee -a $LOGFILE
fi

rm -f "$TMPFOLDER/"*".ppplock"  # Make sure all lock files are removed, just in case there was an error somewhere in the script
sleep 2
rm -f "/tmp/tmp."* #Deleting other tmp files

sleep 5 #Time for things to settle down before PLEX takes over again
