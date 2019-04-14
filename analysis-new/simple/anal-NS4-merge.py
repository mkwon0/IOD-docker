import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np

ARR_JOB=["write"]
regexHeader = re.compile('microbenchmark of ([\w\d/]+)')
ARR_NUM_CONT=[1,2,4,8,16,32,64,128]
ARR_QD=[1]
ARR_NS=[1,2,3,4]

def main():
	for REQ_TYPE in ARR_JOB:
		for QD in ARR_QD:
			print("NS4-noCache/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS4k")
			print("bw-avg bw-std lat-avg lat-std num-container")
			for NUM_CONT in ARR_NUM_CONT:
				bw, lat = [],[]
				for NS in ARR_NS:
					bw_file_name = "/mnt/data/resource/NS4-noCache/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS4k/summary-parse/nvme3n"+str(NS)+"-cont"+str(NUM_CONT)+"-bw.dat"
					lat_file_name = "/mnt/data/resource/NS4-noCache/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS4k/summary-parse/nvme3n"+str(NS)+"-cont"+str(NUM_CONT)+"-lat.dat"
					bw_file = open(bw_file_name,'r')
					lat_file = open(lat_file_name,'r')
					bw_line = bw_file.read().rstrip('\n').split(" ")
					lat_line = lat_file.read().rstrip('\n').split(" ")
					bw.append(float(bw_line[1]))
					lat.append(float(lat_line[1]))
				print(str(np.mean(bw))+" "+str(np.std(bw))+" "+str(np.mean(lat))+" "+str(np.std(lat))+" "+str(NUM_CONT*4))

# Begin of program
if __name__ == "__main__":
	main()
