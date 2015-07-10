#!/bin/bash
#
# Originally written 22 Dec 2014 by Khalid J Hosein, Platform28
#
# Simple script to list the TRADE SCL out files and stick them in a temp file
# for Nagios/Check_MK to pick up with the check_file_exists plugin.

cd /home/tradekernel/TRADE/bin/scl
ls -ltr --time-style=+"%a %d %b %Y %H:%M %Z" *out | awk '{print $6, $7, $8, $9, $10, $11, ":", $5, ":", $12}' > /tmp/trade-scl-files.txt
md5sum /tmp/trade-scl-files.txt >> /tmp/trade-scl-files.txt
tac /tmp/trade-scl-files.txt > /tmp/z
mv /tmp/z /tmp/trade-scl-files.txt
