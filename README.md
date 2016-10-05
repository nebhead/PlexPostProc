# PlexPostProc
Plex PostProcessing Script for DVR(Beta) on Ubuntu 14.04 Server

If you're like me, you probably just want a no-frills/no-fuss script to convert your recorded content from Plex DVR, down to a much smaller file size.  Personally, I wanted to downsize more significantly, so I convert to 720p as well.  Your mileage may vary and you can play with handbrakes settings to get just the righ config.  

I was getting frustrated trying to get FFMpeg and Comskip working / built / installed so I basically went the easy route and just install handbrake CLI (for headless operation) and a very, very simple script to do the conversion.  All seems to be working fine in its current state so I'm happy to share with the world. 

## Prereqs
Handbrake CLI

### How to install the right version of Handbrake CLI on Ubuntu 14.04 server

If you already have handbrake install from the default repository, you'll want to remove it first.  Last I checked, the default version dropped support for h264 natively.  
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

First you will need to get the script onto your machine.  You can do this by cloning my git repository or simlpy downloading and placing in a directory of your choice.  

~~~~
sudo apt-get update
sudo apt-get install git
git clone https://github.com/nebhead/PlexPostProc
cd PlexPostProc
sudo chmod 777 PlexPostProc.sh
~~~~

Now go to Plex's webui and goto server settings > DVR (Beta) > DVR Settings

From there you should be able to enter the path to the post processing script and you should be done.  

For example: 
~~~~
\home\[your-username]\PlexPostProc\PlexPostProc.sh
~~~~
_Where [your-username] is replaced with your username._

That's it.  

Happy Post-Processing!
