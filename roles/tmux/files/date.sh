#/bin/sh

# set -g status-right "%Z: %H:%M %d-%b-%y   #(date -u +'%Z: %H/%d')" doesn't
# work for the UTC time, so extract it into this script

date -u +'%Z: %H:%M %d-%b'
