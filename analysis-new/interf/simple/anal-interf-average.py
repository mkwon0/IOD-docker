import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np

NUM_NS=1
ARR_JOB=["read", "randread", "write", "randwrite"]
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
		
					file_list =[]	
					for NS in ARR_NS:
						file_name = "/mnt/data/resource/Interf-noCache/"+str(REQ_TYPE)+"-QD"+str(QD)+"-BS"+str(BS)+"/timelog/"+str(DEV)+str(NS)+"-cont1ID1_"+str(TARGET)+".1.log"
						file_list.append(open(file_name,'r'))
		
					array_ns1_t1, array_ns1_t2, array_ns1_t3, array_ns1_t4 = [],[],[],[]	
					array_ns2_t2, array_ns2_t3, array_ns2_t4 = [],[],[]
					array_ns3_t3, array_ns3_t4 = [],[]
					array_ns4_t4 = []

					for line1 in file_list[0]:	
						time = line1.strip('\n').split(',')[0]
						if int(time) < 15100:
							data1 = float(line1.strip('\n').split(',')[1])
							if TARGET == "bw":
								array_ns1_t1.append(data1)
							else:
								array_ns1_t1.append(data1 * 0.001)
						elif int(time) < 30100:
							line2 = file_list[1].readline()
							data1 = float(line1.strip('\n').split(',')[1])
							data2 = float(line2.strip('\n').split(',')[1])
							if TARGET == "bw":
								array_ns1_t2.append(data1)
								array_ns2_t2.append(data2)
							else:
								array_ns1_t2.append(data1 * 0.001)
								array_ns2_t2.append(data2 * 0.001)
						elif int(time) < 45100:
							line2 = file_list[1].readline()
							line3 = file_list[2].readline()
							data1 = float(line1.strip('\n').split(',')[1])
							data2 = float(line2.strip('\n').split(',')[1])
							data3 = float(line3.strip('\n').split(',')[1])
							if TARGET == "bw":
								array_ns1_t3.append(data1)
								array_ns2_t3.append(data2)
								array_ns3_t3.append(data3)
							else:
								array_ns1_t3.append(data1 * 0.001)
								array_ns2_t3.append(data2 * 0.001)
								array_ns3_t3.append(data3 * 0.001)
						elif int(time) < 60000:
							line2 = file_list[1].readline()
							line3 = file_list[2].readline()
							line4 = file_list[3].readline()
							data1 = float(line1.strip('\n').split(',')[1])
							data2 = float(line2.strip('\n').split(',')[1])
							data3 = float(line3.strip('\n').split(',')[1])
							data4 = float(line4.strip('\n').split(',')[1])
							if TARGET == "bw":
								array_ns1_t4.append(data1)
								array_ns2_t4.append(data2)
								array_ns3_t4.append(data3)
								array_ns4_t4.append(data4)
							else:
								array_ns1_t4.append(data1 * 0.001)
								array_ns2_t4.append(data2 * 0.001)
								array_ns3_t4.append(data3 * 0.001)
								array_ns4_t4.append(data4 * 0.001)
						else:
							break

					for fp in file_list:
						fp.close()


					os.system('mkdir -p %s/summary-parse' % path)
					output_file=open(path+"/summary-parse/cont1ID1-summary-"+str(TARGET)+".dat",'w+')
#					output_file.write("NS0 "+str(np.mean(array_ns1_t1))+" "+str(np.mean(array_ns1_t2))+" "+str(np.mean(array_ns1_t3))+" "+str(np.mean(array_ns1_t4))+"\n")
#					output_file.write("NS1  "+str(np.mean(array_ns2_t2))+" "+str(np.mean(array_ns2_t3))+" "+str(np.mean(array_ns2_t4))+"\n")
#					output_file.write("NS2   "+str(np.mean(array_ns3_t3))+" "+str(np.mean(array_ns3_t4))+"\n")
#					output_file.write("NS3    "+str(np.mean(array_ns4_t4))+"\n")
					output_file.write("TS1 "+str(np.mean(array_ns1_t1))+"   \n")
					output_file.write("TS2 "+str(np.mean(array_ns1_t2))+" "+str(np.mean(array_ns2_t2))+"  \n")
					output_file.write("TS3 "+str(np.mean(array_ns1_t3))+" "+str(np.mean(array_ns2_t3))+" "+str(np.mean(array_ns3_t3))+" \n")
					output_file.write("TS4 "+str(np.mean(array_ns1_t4))+" "+str(np.mean(array_ns2_t4))+" "+str(np.mean(array_ns3_t4))+" "+str(np.mean(array_ns4_t4))+"\n") 
					output_file.close()
# Begin of program
if __name__ == "__main__":
	main()
