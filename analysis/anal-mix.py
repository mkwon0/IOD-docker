import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np
import pandas as pd
import PyGnuplot as pg
from collections import defaultdict

ARR_READ_RATIO=(10 20 30 40 50 60 70 80 90)
ARR_NUM_CONT=[1,2,4,8,16,32,64,128,256,512,1024]
MIN_NUM_CONT=0
MAX_NUM_CONT=10

regexHeader = re.compile('microbenchmark of ([\w\d/]+)')

def convertBWUnit(unit):
  if unit == 'G':
    return 1000.
  elif unit == 'M':
    return 1.
  elif unit == 'k':
    return 0.001
  else:
    print('Unknown unit ' + unit)

def convertLatencyUnit(unit):
  if unit == 'm':
    return 1000.
  elif unit == 'u':
    return 1.
  elif unit == 'n':
    return 0.001
  else:
    print('Unknown unit ' + unit)

def plot(x,y,z,t):
    file='data.csv'
    output='data.pdf'
    pg.s([x,y,z], filename=file)
    pg.c('file="data.csv"')
    pg.c('set boxwidth 0.4 absolute; set boxdepth 0.3; set style fill solid 1.00 border')
    pg.c('set grid nopolar xtics nomxtics ytics nomytics ztics nomztics nortics nomrtics \
            nox2tics nomx2tics noy2tics nomy2tics nocbtics nomcbtics')
    pg.c('set grid vertical layerdefault lt 0 linecolor 0 linewidth 1.000, lt 0 linecolor 0 linewidth 1.000')
    pg.c('unset key')
    pg.c('set wall z0  fc  rgb "slategrey"  fillstyle  transparent solid 0.50 border lt -1')
    pg.c('set view 59, 24, 1, 1')
    pg.c('set style data lines')
    pg.c('set xyplane at 0')
#    pg.c('set title "Bandwidth (MB/s) of RAND READ')
    pg.c('set title "Latency (us) of READ')
    pg.c('set xlabel "Qdepth"; set ylabel "BlkSize"')
    pg.c('set autoscale x; set autoscale y; set logscale z')
    pg.c('set pm3d depthorder')
    pg.c('set pm3d interpolate 1,1 flush begin noftriangles border lt black \
            linewidth 1.000 dashtype solid corners2color mean')
    pg.c('rgbfudge(x) = x*51*32768 + (11-x)*51*128 + int(abs(5.5-x)*510/9.)')
    pg.c('ti(col) = sprintf("%d",col)')
    pg.c('splot file u 1:2:3:(rgbfudge($1)) with boxes fc rgb variable')

def main():
	# Parse contents
    regexBW = re.compile('BW=.*\(([\d.]+)([GMk])B/s\)')
    regexLatency = re.compile(' lat \(([mun])sec\):.*avg=([ \d.]+)')

    dict_bw = {}
    dict_lat = {}

    for READ_RATIO in ARR_READ_RATIO:
        dict_bw[READ_RATIO] = {}
        dict_lat[READ_RATIO] = {}
        for NUM_CONT in ARR_NUM_CONT:
            LOG_PATH="/mnt/resource/xfs-volume/fio-CONT1-NS1-QD-BS/"+ \
                    str(JOB_TYPE)+"_"+str(BS)+"K_"+str(QD)+".summary"
            with open(LOG_PATH) as f:
                f.seek(0)
                for line in f:
                    match = regexBW.search(line)
                    if match:
                        bw = float(match.group(1)) * convertBWUnit(match.group(2))
                    match = regexLatency.search(line)
                    if match:
                        lat = float(match.group(2)) * convertLatencyUnit(match.group(1))
            dict_bw[QD][BS] = float("{0:.2f}".format(bw))
            dict_lat[QD][BS] = float("{0:.2f}".format(lat))

    df_bw = pd.DataFrame(dict_bw)
    df_lat = pd.DataFrame(dict_lat)

    x,y,z=[],[],[]
    for qd_idx, qd_val in enumerate(ARR_QD):
        for bs_idx, bs_val in enumerate(ARR_BS):
            x.append(qd_idx+1)
            y.append(bs_idx+1)
            z.append(df_lat.at[bs_val,qd_val])
    plot(x,y,z,JOB_TYPE)

# Begin of program
if __name__ == "__main__":
	main()
