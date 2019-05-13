import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np

NS=1
NUM_NS="1-noCache/summary-NS1"
ARR_JOB=["read", "write", "randread", "randwrite"]
ARR_NUM_CONT=[4,8,16,32,64,128,256,512]
ARR_QD=["4","16","32","64","128","256","512","1024","2048"]
ARR_BS=[4,16,32,64,128,256,512,1024]

def main():
	for REQ_TYPE in ARR_JOB:
		for BS in ARR_BS:
			output_bw_file = "/mnt/data/resource/NS"+str(NUM_NS)+"/"+REQ_TYPE+"-BS"+str(BS)+"k-bw.summary"
			output_lat_file = "/mnt/data/resource/NS"+str(NUM_NS)+"/"+REQ_TYPE+"-BS"+str(BS)+"k-lat.summary"
			output_bw = open(output_bw_file,'w')
			output_lat = open(output_lat_file,'w')

			##Generate header
			output_bw.write("Num-container "+" ".join(ARR_QD)+"\n")
			output_lat.write("Num-container "+" ".join(ARR_QD)+"\n")

			for NUM_CONT in ARR_NUM_CONT:
				output_bw.write(str(NUM_CONT)+" ")
				output_lat.write(str(NUM_CONT)+" ")
				for QD in ARR_QD:
					bw_file_name = "/mnt/data/resource/NS1-noCache/NS1/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS"+str(BS)+"k/summary-parse/nvme3n"+str(NS)+"-cont"+str(NUM_CONT)+"-bw.dat"
					lat_file_name = "/mnt/data/resource/NS1-noCache/NS1/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS"+str(BS)+"k/summary-parse/nvme3n"+str(NS)+"-cont"+str(NUM_CONT)+"-lat.dat"
					with open(bw_file_name) as fbw:
						for bw_line in fbw:
							bw=float("{0:.2f}".format(float(bw_line.strip("\n").split(" ")[1])))
							output_bw.write(str(bw)+" ")
					with open(lat_file_name) as flat:
						for lat_line in flat:
							lat=float("{0:.2f}".format(float(lat_line.strip("\n").split(" ")[1])))
							output_lat.write(str(lat)+" ")
				output_bw.write("\n")
				output_lat.write("\n")
			output_bw.close()
			output_lat.close()

# Begin of program
if __name__ == "__main__":
	main()
