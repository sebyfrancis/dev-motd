#!/bin/bash
# 
# Originally written 12 Dec 2014 by Khalid J Hosein, Platform28
# Updated 5 Jan 2015 to add function to email latest core files
# 
# Simple script to list the core files and stick them in a temp file
# for Nagios/Check_MK to pick up with the check_file_exists plugin.

cd /home/tradekernel/TRADE/bin
echo "`ls -1 core* 2> /dev/null | wc -l` core file(s) currently" > /tmp/trade-core-files.txt
ls -lth --time-style=+"%c" core* | awk '{print $6, $7, $8, $9, $10, $11, $12, ":", $5, ":", $13}' >> /tmp/trade-core-files.txt

######
# Send email alerts on finding new core files
# NOTE! This only works if the TIMEFRAME below matches how often this script is run out of cron (default: every 5 mins)

RECIPS="to:kernel-core-dumps@platform28.com"
SUBJECT="Subject: Core file(s) dumped by TRADE on $(hostname -s)"
PREAMBLE="\n
1 or more core files were recently dumped by the TRADE Kernel on host $(hostname -s). \n 
Please note that depending on when this script was called by cron, there may be duplicate listings, so don't assume that receipt of this email alert means there was necessarily a new core dump; please view the filenames and timestamps carefully. \n"

# number of minutes prior to look
TIMEFRAME=5

DIR="/home/tradekernel/TRADE/bin/"

find $DIR -regex '.*core.[0-9]+' -mmin -$TIMEFRAME | xargs -i ls -lh --time-style=+"%c" {} | awk '{print $6, $7, $8, $9, $10, $11, $12, ":", $5, ":", $13}'  > /tmp/recent-trade-cores.txt

if [[ $(wc -c /tmp/recent-trade-cores.txt|awk '{print $1}') -gt 0 ]]; then 
    cat  <(echo "$RECIPS") <(echo "$SUBJECT") <(echo) <(echo -e "$PREAMBLE") /tmp/recent-trade-cores.txt <(echo) > /tmp/email-temp.txt
    mailx -t < /tmp/email-temp.txt
fi
