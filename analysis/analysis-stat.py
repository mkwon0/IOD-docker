import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import scipy.stats as stats
import numpy as np
import pandas as pd
from collections import defaultdict

MAX_CONC=10
ARR_FS=["xfs"]
ARR_JOB=["rr", "sr", "rw", "sw"]
ARR_STORAGE=["volume"]

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

def main():
	# Parse contents
    regexBW = re.compile('BW=.*\(([\d.]+)([GMk])B/s\)')
    regexLatency = re.compile(' lat \(([mun])sec\):.*avg=([ \d.]+)')

    for JOB in ARR_JOB:
        print JOB

        dict_bw = {}
        dict_lat = {}

        for FS in ARR_FS:
            for STORAGE in ARR_STORAGE:
                dict_bw[(FS,STORAGE)] = {}
                dict_lat[(FS,STORAGE)] = {}
                for NUM_CONC in range(1,MAX_CONC+1):
                    arr_bw, arr_lat = [], [] 

                    for CONC_ID in range(1,NUM_CONC+1):
                        LOG_PATH="/mnt/resource/iod-naive/"+str(FS)+"/synthetic/"+str(STORAGE)+ \
                                "/conc"+str(NUM_CONC)+"/single/diff/"+str(JOB)+"/fiolog"+str(CONC_ID)
                        with open(LOG_PATH) as f:
                            f.seek(0)
                            for line in f:
                                match = regexBW.search(line)
                                if match:
                                    bw = float(match.group(1)) * convertBWUnit(match.group(2))
                                    arr_bw.append(bw)
                                match = regexLatency.search(line)
                                if match:
                                    lat = float(match.group(2)) * convertLatencyUnit(match.group(1))
                                    arr_lat.append(lat)
                    dict_bw[(FS,STORAGE)][str(NUM_CONC)] = float("{0:.2f}".format(np.mean(arr_bw)))
                    dict_lat[(FS,STORAGE)][str(NUM_CONC)] = float("{0:.2f}".format(np.mean(arr_lat)))

        df_bw = pd.DataFrame(dict_bw)
        df_lat = pd.DataFrame(dict_lat)

        print df_bw
        print df_lat

# Begin of program
if __name__ == "__main__":
	main()
