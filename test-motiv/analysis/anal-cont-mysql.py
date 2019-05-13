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
ARR_IO_TYPE=["oltp_read_only", "oltp_write_only"]
ARR_NUM_THREAD=[4, 16, 64, 256]

def main():
	regexAvg = re.compile('avg:\s*(\d+\.\d+)') # ms unit
	for IO_TYPE in ARR_IO_TYPE:
		avg_lat = {}
		for NUM_DEV in ARR_NUM_DEV:
			avg_lat[NUM_DEV] = {}
			for NUM_THREAD in ARR_NUM_THREAD:
				lat_cont_id = []
				for CONT_ID in range(1,NUM_THREAD+1): 
					LOG_PATH = "/mnt/data/motiv/cont-mysql/NS"+str(NUM_DEV)+"/all/"+str(IO_TYPE)+"-"+str(NUM_THREAD)+"/sysbench"+str(CONT_ID)+".output"
					with open(LOG_PATH) as f:
						f.seek(0)
						for line in f:
							match = regexAvg.search(line)
							if match:
								lat_cont_id.append(float(match.group(1)))
				avg_lat[NUM_DEV][NUM_THREAD]="%.2f" % np.mean(lat_cont_id)
		print(p.DataFrame(avg_lat).T)

# Begin of program
if __name__ == "__main__":
	main()
