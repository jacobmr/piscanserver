# piscanserver

Printers share attributes with fiberglass boats in that they do last a long time - especially if well cared for.  

We've had an HP Laserjet 1320 in the house for decades and it's been quite reliable.  Our challenge is that it's a USB (or parallel port) printer and we've struggled with the network contraptions I've built to connect it to our home network - so when I found a printer that uses the same toner cartridges, low page count, embedded scanner and networking capability on eBay - I jumped and spent $80 to upgrade us to another (very) old printer.

So long as the hardware works - we're good - right?  

No.  What I learned from this little escapade is that unlike the Day Sailer - printers can be made obsolete by the companies that built them by making the software incompatible with the legacy hardware.   

(You may wonder why I chose this path.  The short version is that toner is expensive and we have plenty of it, I don't like inkjet, we only rarely print things but when we do, it needs to just work, and I like the thought of a low-stress MFP that can scan and (gosh) even fax or copy.)

Things started well:  the printer has an RJ-45 jack and I plugged it into the network, it got an IP address and the computers in the house were able to find it and print quite easily using native drivers.

Scanning was another matter - hence this post.

a) The device is an HP M2727nf MFP
b) HP has software for scanning that runs on Macs and PCs.  It looks like it's going to work (it "sees" the device) but it does not work - and HP's site confirms that this printer isn't supported by HP Smart - the software that seems to be replacing all previous products.  
c) Neither Mac OS nor Windows 11 will let me install older versions of HP scanning software

So ... what to do to scan?

The sort version:

a) Find Raspberry pi in basement
b) Reinstall the OS
c) Install SANE (Scanner Access Now Easy) 
d) Install Dropbox (so I can get the scanned files from anywhere - even when not @ home)
e) Make a script that scans:

#!/bin/bash
DATE=$(date +"%Y%m%d_%H%M")
scanimage --format=pdf > ~/Dropbox/Scans/$DATE.pdf

e) Automate the script with a cron job
f) Fix, enhance.

Bottom line:  this works.  Plop paper in the feeder, wait 59 seconds or less (the cron job runs every minute - checking to see if there is paper) and it scans, uploads to dropbox, deletes the local file.  It works remarkably well. I even made a little web page to manage the settings. Here's the code on Github.  The API doesn't work yet ... but it will soon - then Alexa integration (its already connected to a cloudflare tunnel.)

Oh - and - yeh - ChatGPT wrote 95% of the code for this and helped me debug it.  I couldn't have done this without this assistance.
