#!/bin/bash
# Originally written 8 Dec 2014 by Khalid J Hosein, Platform28
#
# Fix permissions on files that get uploaded with 000 perms.
#
# Note that this does not work if the stat returns a 4-digit permission
# i.e. one with a 'special' perm (e.g. +s)
# However, that should not happen in this use case
# Also does not work against files with spaces in their names.

DIR="/mnt/primary/Platform28/reports/templates/"
cd $DIR

TARGETPERM=755

FILES=(*jasper *jrxml)
for file in ${FILES[@]}; do
  PERM=`/usr/bin/stat -c %a $file`
  if [[ $PERM -lt $TARGETPERM ]] ; then
    chmod ${TARGETPERM} $file
  fi
done
