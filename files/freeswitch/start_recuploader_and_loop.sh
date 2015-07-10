#!/bin/bash
# Starts the Recordings Uploader
# Note that there may be some older scripts in the same dir as this script.
# Do not use them.
#
# Updated 2015/06/18 by Khalid J Hosein
# 2015/06/18 - now uses a generic JAR name so that the filename isn't hard-coded in.
#   - the deploy script will take care of getting the correct version.

cd /home/tradekernel/TRADE/bin
while [ true ];
do
    sleep 5
    /bin/nice -n 10 java -jar recording_uploader.jar 1>/dev/null 2>/dev/null
done
