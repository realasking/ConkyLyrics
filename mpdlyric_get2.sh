#!/bin/bash
if [ -f "/tmp/music_segments" ];then
    aa=`tail -n 2 /tmp/music_segments|head -n 1`
fi
echo "${aa}"
