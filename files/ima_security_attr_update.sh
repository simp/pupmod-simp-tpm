#! /bin/bash
# This script is managed by Puppet
# is purpose is to measure files owned by root and add the security.ima
# attributed.
# It requires the ima-evm-util rpm to be installed.
# usage:
# ./ima_security_attr.sh <relabel file>
# where relabel file is file that exists to indicate that the system should be relabeled with
# security.ima attributes and will be removed when the relabeling is complete.


if [ $# -lt 1 ]; then
  logger -p local6.error "$0 - failed because the file arguement was not provided"
  exit
fi

if [ ! -f $1 ]; then
  logger -p local6.error "$0 - failed because the file $1 does not exist."
  exit
fi

relabel_file=$1

which evmctl > /dev/null
if [ "$?" != "0" ]; then
  logger -p local6.error "$0 - Failed because it could not find evmctl command.  Check if ima-evm-utils package installed and that the evmctl command is in the path."
else
  msg=$( find -P / -xautofs -uid 0 \( -fstype xfs -o -fstype ext4 \) -type f -exec evmctl ima_hash '{}' > /dev/null \;)

  rm -f  $relabel_file
  if [ "$?" != "0" ]; then
    logger -p local6.warn "$0 - completed adding the security.ima attribute but failed to remove $relabel_file with error code $?"
  else
    logger -p local6.info "$0  - completed.  $msg"
  fi
fi
