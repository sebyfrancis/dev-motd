#!/bin/bash

# Sometimes the S3 Fuse driver fails and the NFS-type mounts to S3 fail.
# This script checks that the mount (specifically /mnt/primary) is there,
# if not, restarts Fuse and remounts the bucket.
#
# Written by Khalid J Hosein, Platform28. 9 June 2015

NUM_MOUNTED=`df 2>/dev/null | grep "/mnt/primary" | wc -l`

if [[ $NUM_MOUNTED -eq 0 ]] ; then
    # make sure it's not mounted, in case it's 'stuck':
   /usr/local/bin/fusermount -uz /mnt/primary
   sleep 2
   service fuse stop
   sleep 2
   service fuse start
   sleep 2
   mount -a
   /bin/logger 'Mount /mnt/primary to S3 bucket not found. Restarted Fuse service and remounted.'
fi

exit 0
