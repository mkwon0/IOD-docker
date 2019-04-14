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
ARR_BS=["4k"]
ARR_NS=[1,2,3,4]
ARR_TARGET=["bw","lat"]
DEV="nvme3n"

def main():
	for REQ_TYPE in ARR_JOB:
		for QD in ARR_QD:
			for BS in ARR_BS:
				for TARGET in ARR_TARGET:
					path = "/mnt/data/resource/Interf-noCache/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS"+str(BS)
					file_name = path+"/timeseries"+TARGET+".dat"
					output = open(file_name,'w')
		
					file_list =[]	
					for NS in ARR_NS:
						file_name = "/mnt/data/resource/Interf-noCache/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS"+str(BS)+"/timelog/"+str(DEV)+str(NS)+"-cont1ID1_"+str(TARGET)+".1.log"
						file_list.append(open(file_name,'r'))
			
					for line1 in file_list[0]:	
						time = line1.strip('\n').split(',')[0]
						if int(time) < 15100:
							data1 = line1.strip('\n').split(',')[1]
							if TARGET == "bw":
								output.write(time+data1+"\n")
							else:
								data1 = float(data1) * 0.001
								output.write(time+" "+str(data1)+"\n")
						elif int(time) < 30100:
							line2 = file_list[1].readline()
							data1 = line1.strip('\n').split(',')[1]
							data2 = line2.strip('\n').split(',')[1]
							if TARGET == "bw":
								output.write(time+data1+data2+"\n")
							else:
								data1 = float(data1) * 0.001
								data2 = float(data2) * 0.001
								output.write(time+" "+str(data1)+" "+str(data2)+"\n")
						elif int(time) < 45100:
							line2 = file_list[1].readline()
							line3 = file_list[2].readline()
							data1 = line1.strip('\n').split(',')[1]
							data2 = line2.strip('\n').split(',')[1]
							data3 = line3.strip('\n').split(',')[1]
							if TARGET == "bw":
								output.write(time+data1+data2+data3+"\n")
							else:
								data1 = float(data1) * 0.001
								data2 = float(data2) * 0.001
								data3 = float(data3) * 0.001
								output.write(time+" "+str(data1)+" "+str(data2)+" "+str(data3)+"\n")
						elif int(time) < 60000:
							line2 = file_list[1].readline()
							line3 = file_list[2].readline()
							line4 = file_list[3].readline()
							data1 = line1.strip('\n').split(',')[1]
							data2 = line2.strip('\n').split(',')[1]
							data3 = line3.strip('\n').split(',')[1]
							data4 = line4.strip('\n').split(',')[1]
							if TARGET == "bw":
								output.write(time+data1+data2+data3+data4+"\n")
							else:
								data1 = float(data1) * 0.001
								data2 = float(data2) * 0.001
								data3 = float(data3) * 0.001
								data4 = float(data4) * 0.001
								output.write(time+" "+str(data1)+" "+str(data2)+" "+str(data3)+" "+str(data4)+"\n")
						else:
							break

					for fp in file_list:
						fp.close()
					output.close()

# Begin of program
if __name__ == "__main__":
	main()
