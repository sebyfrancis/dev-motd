#!/bin/sh
#
# Restart the ACD app periodically
# Written by Khalid J Hosein, Platform28. Dec 2014.
#
# On the target system, first modify the pw comment field 
# to get a decent email sender name:
#   usermod -c `hostname -s` root
#
# This is for a CentOS 6.x system

# Modify the recipient as needed:
RECIP='noc+medexpert@platform28.com'
THISHOST=`uname -n`
IPADDR=`ip addr show  | grep 'inet ' | awk '/inet/ {print $2}' | grep -v '127.0.0.1'`

echo "Just restarted the ACD app on $THISHOST, $IPADDR" >  /var/resin/ACD-restart-log.log
echo "" >>  /var/resin/ACD-restart-log.log
echo "/var/log/resin/jvm*.log for 2 mins after restart:" >>  /var/resin/ACD-restart-log.log
echo "" >>  /var/resin/ACD-restart-log.log

/sbin/service resin stop
sleep 4
# Kill the process just in case
/usr/bin/pkill -9 -f resin
/sbin/service resin start

/usr/bin/timeout 2m tail -f /var/log/resin/jvm*.log >> /var/resin/ACD-restart-log.log

cat -v /var/resin/ACD-restart-log.log | mailx -s "Restarted ACD on $THISHOST" $RECIP 
