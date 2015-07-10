#!/bin/bash

# Written 17 Jun 2015 by Khalid J Hosein, Platform28
#
# This deploys the Recording Uploader JAR on a FreeSWITCH server
# You must specify the name of the JAR as an argument to this script.
#
# Here's how it works:
#   * downloads JAR specified as argument to this script
#   * gives it a generic name (recording_uploader.jar)
#   * restarts the uploader
#   * puts the version (filename) of the JAR into a txt file.

if [[ "$#" == "0" ]]; then
    echo "Error: You need to specify the name of the JAR as an argument to this script."
    exit 1
fi

# Edit the base URL where EARs can be pulled from:
REPOBASE='http://repo.platform28.com/apps/'

JAR=$1
FULLURL="$REPOBASE$JAR"
GENERIC_NAME='recording_uploader.jar'

cd /home/tradekernel/TRADE/bin
rm -f "$GENERIC_NAME"
curl -s "$FULLURL" -o "$GENERIC_NAME"
chown tradekernel:tradekernel "$GENERIC_NAME"
echo "Current version of Recording Uploader: $JAR" > recording_uploader.version.txt
chown tradekernel:tradekernel recording_uploader.version.txt

# Restart Recording Uploader:
/sbin/stop recording_uploader
/sbin/start recording_uploader

logger "Deployed new Recording Uploader in /home/tradekernel/TRADE/bin - $JAR."
sleep 6
echo "--"
ps auxw | grep -E "PID|recording" | grep -v grep

exit 0
