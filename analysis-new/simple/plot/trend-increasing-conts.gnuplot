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
ARR_JOB_TYPE="read randread write randwrite"
ARR_TARGET_TYPE="bw lat"
ARR_BS="4k 16k 32k 64k 128k 256k 512k 1024k"
ARR_QD="4 16 32 64 128 256 512 1024 2048"

## User defined plot info
XLABEL="Number of containers (concurrent execution)"
#YLABEL="Agg. bandwidth (MB/s)"
INPUT_PATH="/mnt/data/resource/NS1-noCache/summary-NS1"
OUTPUT_PATH="/mnt/data/resource/NS1-noCache/summary-NS1/figs"

## Page info
Y1COLOR="#000000"
Y2COLOR="#5060D0"
set ytics nomirror
set xlabel XLABEL textcolor rgb Y1COLOR
#set ylabel YLABEL textcolor rgb Y1COLOR
set key autotitle columnhead
set key out horiz center top

## Plot graph
do for [job_id=1:words(ARR_JOB_TYPE)] {
	do for [bs_id=1:words(ARR_BS)]{
		do for [target_id=1:words(ARR_TARGET_TYPE)]{
			FILE_PNG=sprintf("%s/trend-%s-BS%s-%s.png",OUTPUT_PATH,word(ARR_JOB_TYPE,job_id),word(ARR_BS,bs_id),word(ARR_TARGET_TYPE,target_id))
			TITLE=sprintf("%s-%s-trend (fio-direct-BS%s)",word(ARR_JOB_TYPE,job_id),word(ARR_TARGET_TYPE,target_id),word(ARR_BS,bs_id))
			INPUT=sprintf("%s/%s-BS%s-%s.summary",INPUT_PATH,word(ARR_JOB_TYPE,job_id),word(ARR_BS,bs_id),word(ARR_TARGET_TYPE,target_id))
			if (target_id == 1) {
				YLABEL="Agg. bandwidth (MB/s)"
			} else {
				YLABEL="Agg. latency (us)"
			}
		
			set output FILE_PNG
			set title TITLE
			set ylabel YLABEL textcolor rgb Y1COLOR
			plot for [col=2:10] INPUT u 0:col w lp ls (col-1)
			print FILE_PNG
		}
	}
}
