import warnings
warnings.filterwarnings('ignore')
import sys
import os
import re
import math
import numpy as np
import pandas as pd

regexTime=re.compile('.*May\s*[\d]+\s*[\d]+:([\d]+):([\d]+)')
LOG_MSEC=100 #millisec
RUN_TIME=120 #seconds
NUM_LINES=1000/LOG_MSEC
#ARR_NUM_DEV=[1, 2, 4]
#ARR_IO_TYPE=["read", "randread", "write", "randwrite"]
#ARR_NUM_THREAD=[4, 16, 64, 256, 512]
ARR_NUM_DEV=[1]
ARR_IO_TYPE=["write", "randwrite"]
ARR_NUM_THREAD=[4, 16, 64, 256, 512]

def main():
	for NUM_DEV in ARR_NUM_DEV:
		RESULT_DIR="/mnt/data/motiv/cont-fio/NS"+str(NUM_DEV)+"/"
		for IO_TYPE in ARR_IO_TYPE:
			for NUM_THREAD in ARR_NUM_THREAD:
				INTERNAL_DIR=RESULT_DIR+str(IO_TYPE)+"-"+str(NUM_THREAD)+"/"
				TIME_DIR=INTERNAL_DIR+"timelog/"

				print(IO_TYPE+str(NUM_THREAD))
				# Find all_start_time and one_end_time
				arr_time=[]
				for CONT_ID in range(1,NUM_THREAD+1):
					SUMMARY_FILE=INTERNAL_DIR+"ID"+str(CONT_ID)+".summary"
					with open(SUMMARY_FILE) as f:
						f.seek(0)
						for line in f:
							match = regexTime.search(line)
							if match:
								mins = float(match.group(1))
								secs = float(match.group(2))
								total = mins * 60 + secs # seconds
								arr_time.append(total)

				all_start_time=np.max(arr_time)
				one_end_time=np.min(arr_time)+RUN_TIME

				# Remain reasonable time range (all containers are running)
				for CONT_ID in range(1,NUM_THREAD+1):
					bw_file=TIME_DIR+"ID"+str(CONT_ID)+"_bw.1.log"
					lat_file=TIME_DIR+"ID"+str(CONT_ID)+"_lat.1.log"

					parsed_bw_file=TIME_DIR+"ID"+str(CONT_ID)+"_bw.1.log.parsed"
					parsed_lat_file=TIME_DIR+"ID"+str(CONT_ID)+"_lat.1.log.parsed"
				
					if os.path.exists(parsed_bw_file):	
						os.remove(parsed_bw_file)
					if os.path.exists(parsed_bw_file):	
						os.remove(parsed_lat_file)

					start_line=(all_start_time-arr_time[CONT_ID-1])*NUM_LINES
					end_line=(one_end_time-arr_time[CONT_ID-1])*NUM_LINES

					os.system("awk 'NR>=%s&&NR<=%s' %s > %s" % (str(start_line),str(end_line),bw_file,parsed_bw_file))
					os.system("awk 'NR>=%s&&NR<=%s' %s > %s" % (str(start_line),str(end_line),lat_file,parsed_lat_file))

	
# Begin of program
if __name__ == "__main__":
	main()
