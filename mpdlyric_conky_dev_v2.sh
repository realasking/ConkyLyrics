#!/bin/bash
#Conky+mpd用的歌词分析
#注：暂不支持offset，因为conky中有延迟，识别offset则打乱更严重
#作者：realasking
#授权：GPLv3
#2020-09-02
#用法：
#${color lightgrey}${font Sarasa UI SC:style=Bold:size=14}放音乐 ${execi 0.25 /home/realasking/bin/mpd_mfile.sh}状态: ${color 68c14f}$mpd_status${color}${execi 0.5 /home/realasking/bin/mpdlyric_conky_dev_v2.sh}
#$color$stippled_hr
#${if_mpd_playing}\
#${voffset 4}${alignc}${color 68c14f}${execi 1 /home/realasking/bin/mpdlyric_get1.sh}
#${voffset 4}${alignc}${color lightgrey}${execi 1 /home/realasking/bin/mpdlyric_get2.sh}
#${voffset 4}${alignc}${color 68c14f}${execi 1 /home/realasking/bin/mpdlyric_get3.sh}
#${voffset 4}${goto 32}${color 68c14f}$mpd_elapsed/$mpd_length${color} ${alignr}${color2}${mpd_bar 8,360}${color}\${else}\
#      说点什么
#      说点什么
#      说点什么
#${endif}

lyric_dir=~/.lyrics
state=$(mpc status | awk 'NR==2' | awk '{print $1}')

if [ "$state" == "[playing]" ]; then
	#artist这行正则是很久前从某个ubuntu社区的帖子里抄的，没有仔细验证，一直使用貌似没有什么问题，没有仔细验证
	#最近又进行搜索，没能找到原始帖子，暂且继续这么使用
	artist=$(mpc -f %artist% | head -n 1 | tr '[:upper:]' '[:lower:]' | sed 's/[/\, .;:%$!#^&@*{}<>]//g;s/&/ /g')
	title=$(mpc -f %title% | head -n 1 | tr '[:upper:]' '[:lower:]')
	if [ "$title""x" == "x" ]; then
		title=$(mpc status | head -n 1 | cut -d"/" -f2 | cut -d"." -f1)
	fi
	cnt=0
	for i in "$artist-$title.lrc" "$artist - $title.lrc" "$title.lrc" "(未知Artist) - $title.lrc"; do
		now_playing="$i"
		cnt=$(echo "$cnt +1" | bc)
		if [ -f "$lyric_dir"/"$now_playing" ]; then
			time=$(mpc status | head -n 2 | tail -n 1 | cut -d "/" -f2 | awk '{print $2}')
			t1=$(echo $time | cut -d":" -f1)
			if [ ${#t1} -lt 2 ]; then
				time=$(echo "0"${time})
			fi
			if [ "$time" == "00:00" ]; then
				rm /tmp/music_segments
				rm /tmp/musicLrc
				#rm /tmp/muLrc
				#展开写在一行里的重复出现的歌词，应该是展开到第六层，先实现功能，有空再打磨
				cat "$lyric_dir"/"$now_playing" >>/tmp/musicLrc
				cat "$lyric_dir"/"$now_playing" | cut -d"]" -f1 --complement | grep "^\[" >>/tmp/musicLrc
				cat "$lyric_dir"/"$now_playing" | cut -d"]" -f1 --complement | grep "^\[" | cut -d"]" -f1 --complement | grep "^\[" >>/tmp/musicLrc
				cat "$lyric_dir"/"$now_playing" | cut -d"]" -f1 --complement | grep "^\[" | cut -d"]" -f1 --complement | grep "^\[" | cut -d"]" -f1 --complement | grep "^\[" >>/tmp/musicLrc
				cat "$lyric_dir"/"$now_playing" | cut -d"]" -f1 --complement | grep "^\[" | cut -d"]" -f1 --complement | grep "^\[" | cut -d"]" -f1 --complement | grep "^\[" | cut -d"]" -f1 --complement | grep "^\[" >>/tmp/musicLrc
				cat "$lyric_dir"/"$now_playing" | cut -d"]" -f1 --complement | grep "^\[" | cut -d"]" -f1 --complement | grep "^\[" | cut -d"]" -f1 --complement | grep "^\[" | cut -d"]" -f1 --complement | grep "^\[" | cut -d"]" -f1 --complement | grep "^\[" >>/tmp/musicLrc
				cat /tmp/musicLrc | grep -v al\: | grep -v ti\: | grep -v ar\: | grep -v ed\: | grep -v http | sort -n >/tmp/muLrc
				touch /tmp/music_segments
				echo "$title" | dos2unix >/tmp/music_segments
				echo "$artist" | dos2unix >>/tmp/music_segments
				echo "" >>/tmp/music_segments
				echo "00" >/tmp/musicTimer
				#不加这一句有些歌词会缺第一句，加上这一句有些歌词中插入的非歌词信息的最后一句会重复出现
				cat /tmp/muLrc | grep "^\[" | head -n 1 | sed 's/\[[^]]*]//g' | sed 's/\\r//'| dos2unix|sed 's/[　\t]*$//g|sed 's/[ \t]*$//g'' >>/tmp/music_segments
			fi
			#这种写法有些歌曲会漏掉一些歌词
			nlin=$(cat /tmp/muLrc | grep -n "\[$time" | awk -F ':' '{print $1}' | head -n 1)
			nlinNxt=$(echo " ${nlin} + 1 " | bc)
			Nxt=$(cat /tmp/muLrc | head -n ${nlinNxt} | tail -1 | dos2unix)
			NlI=$(cat /tmp/muLrc | head -n ${nlin} | tail -1 | dos2unix)
			#这种写法有些歌曲会发生歌词重复
			#nlin=`cat /tmp/muLrc | grep -n "\[$time" |awk -F ':' '{print $1}'`
			#for j in $nlin; do
			#	nlinNxt=$(echo " ${j} + 1 " | bc)
			#Nxt=${Nxt}" "`cat /tmp/muLrc|head -n ${nlinNxt} | tail -1 | dos2unix`
			#done
			#同样是用来解决歌词重复问题的
			Sec=$(echo $Nxt | cut -d "[" -f2 | cut -d"]" -f1 | cut -d"." -f1)
			TSec=$(cat /tmp/musicTimer | head -n 1)
			if [ ${Sec} == ${TSec} ]; then
				echo ${Sec} >/tmp/musicTimer
			else
				aac=$(echo $Nxt | sed 's/\[[^]]*]//g' | sed 's/\\r//' |sed 's/[　\t]*$//g'| grep -o "[^ ]\+\( \+[^ ]\+\)*" | sed -e '/^$/d')
				#aaee用来解决漏掉歌词问题
				aaee=$(echo $NlI | sed 's/\[[^]]*]//g' | sed 's/\\r//' |sed 's/[　\t]*$//g'| grep -o "[^ ]\+\( \+[^ ]\+\)*" | sed -e '/^$/d')
				aar=$(cat /tmp/music_segments | tail -1)
				if [ "${aaee}""x" == "${aar}""x" ]; then
					aaee=""
				fi
				for j in aaee aac; do
					tmc=$(eval echo '$'"$j")
					if [ "${tmc}""x" == "x" ]; then
						aae=""
					else
						if [ ! "$(echo "$tmc" | tr -s ' ')" == " " ]; then
							if [ ${#tmc} -gt 28 ]; then
								if [ ${#tmc} -lt 57 ]; then
									sn=$(echo " ${#tmc} / 2 " | bc)
									echo ${tmc} | sed "s/.\{$sn\}/&\n/g" >>/tmp/music_segments
								else
									echo ${tmc} | sed "s/.\{20\}/&\n/g" >>/tmp/music_segments
								fi
							else
								echo ${tmc} >>/tmp/music_segments
							fi
						fi
					fi

				done
				Nxt=""
				echo ${Sec} >/tmp/musicTimer
			fi
			exit
		else
			if (($cnt == 4)); then
				echo "正在播放无歌词曲目" >/tmp/music_segments
			fi
		fi
	done
fi
