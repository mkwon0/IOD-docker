import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np

NUM_NS=1
ARR_JOB=["read", "randread", "write", "randwrite"]
regexHeader = re.compile('microbenchmark of ([\w\d/]+)')
ARR_QD=[1]
ARR_NS=[1,2,3,4]

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
	for REQ_TYPE in ARR_JOB:
		for QD in ARR_QD:
			path = "/mnt/data/resource/Interf-noCache/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS4k/summary-parse"
			file_name = path + "/cont1ID1-summary.dat"
			os.system("mkdir -p %s" % path)			

			file = open(file_name,'w')
				
			for NS in ARR_NS:
				LOG_PATH= "/mnt/data/resource/Interf-noCache/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS4k/summary/nvme3n"+str(NS)+"-cont1ID1.summary"
				with open(LOG_PATH) as f:
					f.seek(0)
					for line in f:
						match = regexBW.search(line)
						if match:
							bw = float(match.group(1)) * convertBWUnit(match.group(2))
						match = regexLatency.search(line)
						if match:
							lat = float(match.group(2)) * convertLatencyUnit(match.group(1))
				file.write(str(bw)+" "+str(lat)+"\n")

			file.close()

# Begin of program
if __name__ == "__main__":
	main()
