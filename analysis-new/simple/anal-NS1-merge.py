import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np

ARR_JOB=["read", "write", "randread", "randwrite"]
regexHeader = re.compile('microbenchmark of ([\w\d/]+)')
ARR_NUM_CONT=[4,8,16,32,64,128,256,512]
ARR_QD=[1]
NS=1

def main():
	for REQ_TYPE in ARR_JOB:
		for QD in ARR_QD:
			print("NS1-noCache/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS4k")
			print("bw-avg bw-std lat-avg lat-std num-container")
			for NUM_CONT in ARR_NUM_CONT:
				bw_file_name = "/mnt/data/resource/NS1-noCache/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS4k/summary-parse/nvme3n"+str(NS)+"-cont"+str(NUM_CONT)+"-bw.dat"
				lat_file_name = "/mnt/data/resource/NS1-noCache/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS4k/summary-parse/nvme3n"+str(NS)+"-cont"+str(NUM_CONT)+"-lat.dat"
				
				bw, lat = [],[]
				with open(bw_file_name) as fbw:
					for bw_line in fbw:
						bw.append(float(bw_line.strip("\n").split(" ")[1]))
				with open(lat_file_name) as flat:
					for lat_line in flat:
						lat.append(float(lat_line.strip("\n").split(" ")[1]))
				print(str(np.mean(bw))+" "+str(np.std(bw))+" "+str(np.mean(lat))+" "+str(np.std(lat))+" "+str(NUM_CONT))

# Begin of program
if __name__ == "__main__":
	main()
