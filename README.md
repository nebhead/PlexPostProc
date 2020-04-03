# PlexPostProc
Plex PostProcessing Script for DVR(Beta) on Ubuntu 14.04 (or later) Server or Official Docker

If you're like me, you probably just want a no-frills/no-fuss script to convert your recorded content from Plex DVR, down to a much smaller file size.  Personally, I wanted to downsize more significantly, so I convert to 720 as well.  Your mileage may vary and you can play with ffmpeg or handbrake's settings to get just the right config for you.  

I wanted to create a very, very simple script to do the conversion with no frills.  All seems to be working fine in its current state so I'm happy to share with the world.

2020-04-02 Update 1: Added some logging and lockfile capability (inspired by (this blog by thatvirtualboy)[https://thatvirtualboy.com/2017/11/28/plex-dvr-postprocessing-script.html]), to try and work around an issue with Plex where it deletes all .grab folders/files after one script completes.  This obviously isn't a good scenario if we have simultaneous scripts running.  

2020-04-02 Update 2: Converged handbrake and ffmpeg

## Prereqs
FFmpeg or HandBrakeCLI

### How to install the right version of ffmpeg on Ubuntu 14.04 server

Install FFMPEG from the native repository (optionally build your own or grab from another repo)  
~~~~
sudo apt-get update
sudo apt-get install ffmpeg
~~~~

### How to install the right version of Handbrake CLI on Ubuntu 14.04 server

If you already have handbrake installed from the default repository, you'll want to remove it first.  Last I checked, the default version dropped support for h264 natively.  
~~~~
sudo apt-get purge handbrake
~~~~

Now install this repository and the handbrake-cli (command line interface) software.

~~~~
sudo add-apt-repository ppa:stebbins/handbrake-releases
sudo apt-get update
sudo apt-get install handbrake-cli
~~~~

## Installation

First you will need to get the script onto your machine.  You can do this by cloning my git repository or simply downloading and placing in a directory of your choice.  

~~~~
sudo apt-get update
sudo apt-get install git
git clone -b FFMPEG-Branch https://github.com/nebhead/PlexPostProc
cd PlexPostProc
sudo chmod 777 PlexPostProc.sh
~~~~

Now go to Plex's webui and go to server settings > DVR (Beta) > DVR Settings

From there you should be able to enter the path to the post processing script and you should be done.  

For example:
~~~~
/home/[your-username]/PlexPostProc/PlexPostProc.sh
~~~~
_Where [your-username] is replaced with your username._

Finally, you may want to edit the script to customize some parameters at the top of the file.  Here are the defaults:

```
TMPFOLDER="/tmp"
ENCODER="ffmpeg"  # Encoder to use:
                  # "ffmpeg" for FFMPEG [DEFAULT]
                  # "handbrake" for HandBrake
RES="720"         # Resolution to convert to:
                  # "720" = 720 Vertical Resolution
                  # "1080" = 1080 Vertical Resolution
```

That's it.  

Happy Post-Processing!

**NOTE on Docker Installs:** _If you're using the official Docker, you'll need to install FFMPEG or HandbrakeCLI inside the Docker Container, and need this script itself to be inside the Docker Container or in a volume that is accessible by the Plex Docker Container.  I'll update these instructions in the future if there is a request._  

## Troubleshoooting

It has been noted that in some cases (for example on MacOS or FreeBSD OSes) the script will fail due to the fact that the FFMPEG or Handbrake binary is not found on the system.  In these cases, you may need to modify the script to include the full path to the executable.

For example, change this line:

~~~~
ffmpeg -i "$FILENAME" -s hd720 -c:v libx264 -preset veryfast -vf yadif -c:a copy "$TEMPFILENAME"
~~~~

To this:

~~~~
/usr/local/bin/ffmpeg -i "$FILENAME" -s hd720 -c:v libx264 -preset veryfast -vf yadif -c:a copy "$TEMPFILENAME"
~~~~

Where "/usr/local/bin" is the path to the executable.  
