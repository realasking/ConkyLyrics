#!/bin/bash
if [ -f "/tmp/music_segments" ];then
ab=`wc -l /tmp/music_segments|cut -d" " -f1`
if [ ${ab} -lt 2 ];then
	aa=""
else
	aa=`tail -n 1 /tmp/music_segments|head -n 1`
fi
fi
echo "${aa}"
