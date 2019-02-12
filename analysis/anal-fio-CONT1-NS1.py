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

ARR_QD=[1, 2, 4, 8, 16, 32, 64]
ARR_BS=[4, 8, 16, 32, 64, 128, 256, 512, 1024]
ARR_JOB=["read", "write", "randread", "randwrite"]
#ARR_JOB=["read"]

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
    pg.c('set xtics ("1" 1, "2" 2, "4" 3, "8" 4, "16" 5, "32" 6, "64" 7)')
    pg.c('set ytics ("4" 1, "8" 2, "16" 3, "32" 4, "64" 5, "128" 6, "256" 7, "512" 8, "1024" 9)')
    pg.c('splot file u 1:2:3:(rgbfudge($1)) with boxes fc rgb variable')

def multiplot(rr_x,rr_y,rr_z,sr_x,sr_y,sr_z,rw_x,rw_y,rw_z,sw_x,sw_y,sw_z,t):
    output='data.pdf'

    if (t == "bandwidth"):
        pg.c('TITLE="fio-CONT1-NS1-QDs-BSs (Bandwidth MB/s)"')
        pg.c('set autoscale z')
    else:
        pg.c('TITLE="fio-CONT1-NS1-QDs-BSs (Latency us)"')
        pg.c('set logscale z')

    pg.s([rr_x,rr_y,rr_z], filename="randread.csv")
    pg.s([sr_x,sr_y,sr_z], filename="read.csv")
    pg.s([rw_x,rw_y,rw_z], filename="randwrite.csv")
    pg.s([sw_x,sw_y,sw_z], filename="write.csv")
    pg.c('ARR_JOB_TYPE="randread read randwrite write"')
    pg.c('set autoscale x; set autoscale y')
    pg.c('set boxwidth 0.4 absolute; set boxdepth 0.3; set style fill solid 1.00 border')
    pg.c('set grid nopolar xtics nomxtics ytics nomytics ztics nomztics nortics nomrtics \
            nox2tics nomx2tics noy2tics nomy2tics nocbtics nomcbtics')
    pg.c('set grid vertical layerdefault lt 0 linecolor 0 linewidth 1.000, lt 0 linecolor 0 linewidth 1.000')
    pg.c('unset key')
    pg.c('set wall z0  fc  rgb "slategrey"  fillstyle  transparent solid 0.50 border lt -1')
    pg.c('set view 59, 24, 1, 1')
    pg.c('set style data lines')
    pg.c('set xyplane at 0')
    pg.c('set xlabel "Qdepth"; set ylabel "BlkSize (KB)"')
    pg.c('set pm3d depthorder')
    pg.c('set pm3d interpolate 1,1 flush begin noftriangles border lt black \
            linewidth 1.000 dashtype solid corners2color mean')
    pg.c('rgbfudge(x) = x*51*32768 + (11-x)*51*128 + int(abs(5.5-x)*510/9.)')
    pg.c('ti(col) = sprintf("%d",col)')
    pg.c('set xtics ("1" 1, "2" 2, "4" 3, "8" 4, "16" 5, "32" 6, "64" 7)')
    pg.c('set ytics ("4" 1, "8" 2, "16" 3, "32" 4, "64" 5, "128" 6, "256" 7, "512" 8, "1024" 9)')

    pg.c('set multiplot layout 2,2 title TITLE')
    pg.c('do for [job_id=1:words(ARR_JOB_TYPE)] {')
    pg.c('TITLE1=sprintf("%s",word(ARR_JOB_TYPE,job_id))')
    pg.c('set title TITLE1')
    pg.c('FILE=sprintf("%s.csv",word(ARR_JOB_TYPE,job_id))')
    pg.c('splot FILE u 1:2:3:(rgbfudge($1)) with boxes fc rgb variable')
    pg.c('}')
    pg.c('unset multiplot')

def main():
	# Parse contents
    regexBW = re.compile('BW=.*\(([\d.]+)([GMk])B/s\)')
    regexLatency = re.compile(' lat \(([mun])sec\):.*avg=([ \d.]+)')

    global_x, global_y, global_bw_z, global_lat_z = [],[],[],[]
    for JOB_TYPE in ARR_JOB:
        dict_bw = {}
        dict_lat = {}

        print JOB_TYPE
        for QD in ARR_QD:
            dict_bw[QD] = {}
            dict_lat[QD] = {}
            for BS in ARR_BS:
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

#        df_bw.columns = ['QD'+str(col) for col in df_bw.columns]
#        df_bw.index = ['BS'+str(idx)+'K' for idx in df_bw.index]
#        df_lat.columns = ['QD'+str(col) for col in df_lat.columns]
#        df_lat.index = ['BS'+str(idx)+'K' for idx in df_lat.index]

#        print "Bandwidth"
#        print df_bw
#        print "\n"
#        print "Latency"
#        print df_lat
#        print "\n"

        x, y, bw_z, lat_z = [],[],[],[]
        for qd_idx, qd_val in enumerate(ARR_QD):
            for bs_idx, bs_val in enumerate(ARR_BS):
                x.append(qd_idx+1)
                y.append(bs_idx+1)
                bw_z.append(df_bw.at[bs_val,qd_val])
                lat_z.append(df_lat.at[bs_val,qd_val])


        global_x.append(x)
        global_y.append(y)
        global_bw_z.append(bw_z)
        global_lat_z.append(lat_z)
#        print x
#        print y
#        print z
#        plot(x,y,z,JOB_TYPE)


#    multiplot(global_x[0],global_y[0],global_bw_z[0],\
#            global_x[1],global_y[1],global_bw_z[1],\
#            global_x[2],global_y[2],global_bw_z[2],\
#            global_x[3],global_y[3],global_bw_z[3],"bandwidth")


    multiplot(global_x[0],global_y[0],global_lat_z[0],\
            global_x[1],global_y[1],global_lat_z[1],\
            global_x[2],global_y[2],global_lat_z[2],\
            global_x[3],global_y[3],global_lat_z[3],"latency")

# Begin of program
if __name__ == "__main__":
	main()
