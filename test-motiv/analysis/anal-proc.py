import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np
import pandas as p

regexHeader = re.compile('microbenchmark of ([\w\d/]+)')
ARR_NUM_DEV=[1, 2, 4]
ARR_IO_TYPE=["read", "randread", "write", "randwrite"]
ARR_NUM_THREAD=[4, 16, 64, 256]

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
	regexBW = re.compile('BW=.*\(([\d.]+)([GMk])B/s\)')
	regexLatency = re.compile(' lat \(([mun])sec\):.*avg=([ \d.]+)')
	for IO_TYPE in ARR_IO_TYPE:
		avg_bw, avg_lat = {},{}
		for NUM_DEV in ARR_NUM_DEV:
			avg_bw[NUM_DEV] = {}
			avg_lat[NUM_DEV] = {}
			for NUM_THREAD in ARR_NUM_THREAD:
				bw_cont_id, lat_cont_id = [],[]
				LOG_PATH = "/mnt/data/motiv/proc/NS"+str(NUM_DEV)+"/all/"+str(IO_TYPE)+"-"+str(NUM_THREAD)+"/fio.summary"
				with open(LOG_PATH) as f:
					f.seek(0)
					for line in f:
						match = regexBW.search(line)
						if match:
							bw_cont_id.append(float(match.group(1)) * convertBWUnit(match.group(2)))
						match = regexLatency.search(line)
						if match:
							lat_cont_id.append(float(match.group(2)) * convertLatencyUnit(match.group(1)))
				avg_bw[NUM_DEV][NUM_THREAD]="%.2f" % np.mean(bw_cont_id)
				avg_lat[NUM_DEV][NUM_THREAD]="%.2f" % np.mean(lat_cont_id)
	
		print(p.DataFrame(avg_bw).T)
		print(p.DataFrame(avg_lat).T)

# Begin of program
if __name__ == "__main__":
	main()
