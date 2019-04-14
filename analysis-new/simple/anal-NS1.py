import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np

NUM_NS="1-noCache"
ARR_JOB=["read", "write", "randread", "randwrite"]
regexHeader = re.compile('microbenchmark of ([\w\d/]+)')
ARR_NUM_CONT=[4,8,16,32,64,128,256,512]
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
			for NUM_CONT in ARR_NUM_CONT:
				path= "/mnt/data/resource/NS"+str(NUM_NS)+"/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS4k/summary-parse/"
				os.system("mkdir -p %s" % path)
				bw_file_name = "/mnt/data/resource/NS"+str(NUM_NS)+"/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS4k/summary-parse/nvme3n1-cont"+str(NUM_CONT)+"-bw.dat"
				lat_file_name = "/mnt/data/resource/NS"+str(NUM_NS)+"/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS4k/summary-parse/nvme3n1-cont"+str(NUM_CONT)+"-lat.dat"
				bw_file = open(bw_file_name,'w')
				lat_file = open(lat_file_name,'w')
				bw_cont_id, lat_cont_id = [],[]
				for CONT_ID in xrange(1,NUM_CONT+1):
					LOG_PATH= "/mnt/data/resource/NS"+str(NUM_NS)+"/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS4k/summary/nvme3n1-cont"+str(NUM_CONT)+"ID"+str(CONT_ID)+".summary"
					with open(LOG_PATH) as f:
						f.seek(0)
						for line in f:
							match = regexBW.search(line)
							if match:
								bw = float(match.group(1)) * convertBWUnit(match.group(2))
							match = regexLatency.search(line)
							if match:
								lat = float(match.group(2)) * convertLatencyUnit(match.group(1))
						bw_cont_id.append(bw)
						lat_cont_id.append(lat)

					bw_file.write(str(NUM_CONT)+" "+str(np.mean(bw_cont_id))+" "+str(np.std(bw_cont_id))+"\n")
					lat_file.write(str(NUM_CONT)+" "+str(np.mean(lat_cont_id))+" "+str(np.std(lat_cont_id))+"\n")
				bw_file.close()
				lat_file.close()


# Begin of program
if __name__ == "__main__":
	main()
