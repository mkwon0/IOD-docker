#!/usr/bin/gnuplot -p
set macros
set loadpath '~/.gnuplot/color4'
set fontpath '/usr/share/fonts/msttcore'

## MACROS
FONT="arial,22"

## Frame info
set term png enhanced size 900,600 font FONT 
set style line 81 lt 0 lc rgb '#808080' lw 1
set grid back ls 81

## Target specific variables
ARR_JOB_TYPE="write randwrite"
ARR_TARGET_TYPE="bw lat"
ARR_NS="1"

## User defined plot info
XLABEL="Timeline (ms)"
#YLABEL="Bandwidth (MB/s)"
INPUT_PATH_SINGLE="/mnt/data/resource/NS1-noCache-60s"
INPUT_PATH_CONCUR="/mnt/data/resource/Interf-noCache"
OUTPUT_PATH="/mnt/data/resource/Interf-noCache"
QD="4"
BS="64k"

## Page info
Y1COLOR="#000000"
Y2COLOR="#5060D0"
set ytics nomirror
set xlabel XLABEL textcolor rgb Y1COLOR
#set ylabel YLABEL textcolor rgb Y1COLOR

set key out horiz center top

## Plot graph
do for [job_id=1:words(ARR_JOB_TYPE)] {
	do for [target_id=1:words(ARR_TARGET_TYPE)]{
		if (target_id == 1) {
			YLABEL="Bandwidth (MB/s)"
		} else {
			YLABEL="Latency (us)"
		}
		do for [ns_id=1:words(ARR_NS)]{
			TITLE=sprintf("Interference Test - NS%s\n(fio %s-QD%s-BS%s 60s execution)", \
				word(ARR_NS,ns_id),word(ARR_JOB_TYPE,job_id),QD,BS)
			INPUT_SINGLE=sprintf("%s/%s-QD%s-BS%s/timelog/nvme3n%s-cont1ID1_%s.1.log", \
				INPUT_PATH_SINGLE,word(ARR_JOB_TYPE,job_id),QD,BS,word(ARR_NS,ns_id),word(ARR_TARGET_TYPE,target_id))
			INPUT_CONCUR=sprintf("%s/startNS%s/%s-QD%s-BS%s/timelog/nvme3n%s-cont1ID1_%s.1.log", \
				INPUT_PATH_CONCUR,word(ARR_NS,ns_id),word(ARR_JOB_TYPE,job_id),QD,BS,word(ARR_NS,ns_id),word(ARR_TARGET_TYPE,target_id))
			FILE_PNG=sprintf("%s/figs/interftest-%s-QD%s-BS%s-%s-NS%s.png", \
				OUTPUT_PATH,word(ARR_JOB_TYPE,job_id),QD,BS,word(ARR_TARGET_TYPE,target_id),word(ARR_NS,ns_id))

			set output FILE_PNG
			set title TITLE
			set ylabel YLABEL textcolor rgb Y1COLOR
			set xrange [0:60000]
			set arrow from 15100,graph(0,0) to 15100,graph(1,1) nohead lw 3
			set arrow from 30100,graph(0,0) to 30100,graph(1,1) nohead lw 3
			set arrow from 45100,graph(0,0) to 45100,graph(1,1) nohead lw 3
		
			if (target_id == 1) {	
				plot INPUT_SINGLE u 1:2 w lp ls 1 t "single NS", \
					INPUT_CONCUR u 1:2 w lp ls 2 t "concurrent NS"
			} else {
				plot INPUT_SINGLE u 1:($2/1000) w lp ls 1 t "single NS", \
					INPUT_CONCUR u 1:($2/1000) w lp ls 2 t "concurrent NS"
			}
			print FILE_PNG
		}
	}
}
