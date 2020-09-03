#!/bin/bash

lyric_dir=~/.lyrics
state=$(mpc status | awk 'NR==2' | awk '{print $1}')

if [ "$state" == "[playing]" ]; then
    title=`mpc status | head -n 1|cut -d"/" -f2|cut -d"." -f1`
    ti=`echo "$title"|sed 's/.\{15\}/&\n/g'`
    echo "${ti}"|sed "s/.\{13\}/&\n/g"|head -n 1
fi
