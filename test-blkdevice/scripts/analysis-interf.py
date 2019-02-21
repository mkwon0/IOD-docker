import sys
import os
import numpy as np

inputFile="results-blktrace/nvme2n1.parsed"
fi = open(inputFile,"r")

D = []
C = []

for l in fi:
  s=l.split()
  if "CPU" in l:
    break

  if s[5] == "D":
    D.append(float(s[3]))
  elif s[5] == "C":
    C.append(float(s[3]))


prevDiff = []
postDiff = []
for i in range(len(D)):
  diff=C[i]-D[i]
  if D[i] < 20:
    prevDiff.append(diff)
  else:
    postDiff.append(diff)

print("prevDiff "+str(np.mean(prevDiff)*1E6))
print("postDiff "+str(np.mean(postDiff)*1E6))
  
