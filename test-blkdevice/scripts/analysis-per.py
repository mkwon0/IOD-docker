import sys
import os
import re
import math

regexHeader = re.compile('microbenchmark of ([\w\d/]+)')
regexMinBlockSize = re.compile('Min block size is (\d+)')
regexMaxBlockSize = re.compile('Max block size is (\d+)')
regexMinQDepth = re.compile('Min qdepth is (\d+)')
regexMaxQDepth = re.compile('Max qdepth is (\d+)')

def detectHeader(line, config):
  match = regexHeader.search(line)
  if match:
    config = {"minbs": 0, "maxbs": 0, "minqd": 0, "maxqd": 0, "mindev": 0, "maxdev": 3, "minns": 1, "maxdev":4}
    return [True, config]

  match = regexMinBlockSize.match(line)
  if match:
    config['minbs'] = int(match.group(1))
    return [True, config]

  match = regexMaxBlockSize.match(line)
  if match:
    config['maxbs'] = int(match.group(1))
    return [True, config]

  match = regexMinQDepth.match(line)
  if match:
    config['minqd'] = int(match.group(1))
    return [True, config]
  
  match = regexMaxQDepth.match(line)
  if match:
    config['maxqd'] = int(match.group(1))
    config['mindev'] = int(0)
    config['maxdev'] = int(5)
    config['minns'] = int(1)
    config['maxns'] = int(4)
    return [True, config]
 
  return [True, config]

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

def printData(data):
  dev = len(data)
  ns = len(data[0])
  blk = len(data[0][0])
  qd = len(data[0][0][0])

  if analType == "qd-all":
    for b in range(0, blk):
      sys.stdout.write('Results for block size {0:.2f}'.format(b))
      sys.stdout.write('\n')
      for q in range(0, qd):
        for d in range(0, dev):
          for n in range(0, ns):
            sys.stdout.write('{0:.2f}'.format(data[d][n][b][q]))
            if not (d == dev - 1 and n == ns - 1): 
              sys.stdout.write('\t')
        sys.stdout.write('\n')

  if analType == "qd-per":
    for b in range(0, blk):
      sys.stdout.write('Results for block size {0:.2f}'.format(b))
      sys.stdout.write('\n')
      for q in range(0, qd):
        for n in range(0, ns):
          for d in range(0, dev):
            sys.stdout.write('{0:.2f}'.format(data[d][n][b][q]))
            if d < dev - 1:
              sys.stdout.write('\t')
          sys.stdout.write('\n')
             
 
def main(args):
  global analType
  analType = args[2] 
  try:
    with open(args[1]) as f:
      config = {}
      
      # parse header
      for line in f:
        ret = detectHeader(line, config)
        config = ret[1]
        if not ret[0]:
          break

      config['bscount'] = int(math.log(
        config['maxbs'], 2) - math.log(config['minbs'], 2) + 1)
      config['qdcount'] = int(math.log(
        config['maxqd'], 2) - math.log(config['minqd'], 2) + 1)
      config['devcount'] = int(config['maxdev'] - config['mindev'] + 1)
      config['nscount'] = int(config['maxns'] - config['minns'] + 1)
      config['typecount'] = 4
 
      # Allocate data
      bw = [0] * config['typecount']
      for i in range(0, config['typecount']):
        bw[i] = [0] * config['devcount']
        for j in range(0, config['devcount']):
          bw[i][j] = [0] * config['nscount']
          for k in range(0, config['nscount']):
            bw[i][j][k] = [0] * config['bscount']
            for l in range(0, config['bscount']):
              bw[i][j][k][l] = [0] * config['qdcount']

      lat = [0] * config['typecount']
      for i in range(0, config['typecount']):
        lat[i] = [0] * config['devcount']
        for j in range(0, config['devcount']):
          lat[i][j] = [0] * config['nscount']
          for k in range(0, config['nscount']):
            lat[i][j][k] = [0] * config['bscount']
            for l in range(0, config['bscount']):
              lat[i][j][k][l] = [0] * config['qdcount']

      # Parse contents
      regexQDepth = re.compile('Testing for qdepth (\d+)')
      regexBlockSize = re.compile('Test for block size (\d+)')
      regexDeviceNum = re.compile('Test for device (\d+)')
      regexNamespace = re.compile(' Test for namespace (\d+)')
      regexIO = re.compile('Test for (seq|rand)(read|write)')
      regexBW = re.compile('BW=.*\(([\d.]+)([GMk])B/s\)')
      regexLatency = re.compile(' lat \(([mun])sec\):.*avg=([ \d.]+)')

      current = {'io': 0, 'qd': 0, 'bs': 0, 'dev': 0, 'ns': 0}

      f.seek(0)
      for line in f:
	
	match = regexDeviceNum.match(line)
	if match:
	  current['dev'] = int(match.group(1))
	
	match = regexNamespace.match(line)
	if match:
	  current['ns'] = int(match.group(1))-1

        match = regexQDepth.match(line)
        if match:
          current['qd'] = int(math.log(
            int(match.group(1)), 2) - math.log(config['minqd'], 2))

        match = regexIO.search(line)
        if match:
          current['io'] = 0
          if match.group(1) == 'rand':
            current['io'] += 1
          if match.group(2) == 'write':
            current['io'] += 2

        match = regexBlockSize.search(line)
        if match:
          current['bs'] = int(math.log(
            int(match.group(1)), 2) - math.log(config['minbs'], 2))
        
        match = regexBW.search(line)
        if match:
	  bw[current['io']][current['dev']][current['ns']][current['bs']][current['qd']] = float(
            match.group(1)) * convertBWUnit(match.group(2))
         
        match = regexLatency.search(line)
        if match:
          lat[current['io']][current['dev']][current['ns']][current['bs']][current['qd']] = float(
            match.group(2)) * convertLatencyUnit(match.group(1))


    if not bw[0][0][0][0][0] == 0:
      print('Bandwidth - Sequential Read')
      printData(bw[0])
      print('Latency - Sequential Read')
      printData(lat[0])

    if not bw[1][0][0][0][0] == 0:
      print('Bandwidth - Random Read')
      printData(bw[1])
      print('Latency - Random Read')
      printData(lat[1])
      
    if not bw[2][0][0][0][0] == 0:
      print('Bandwidth - Sequential Write')
      printData(bw[2])
      print('Latency - Sequential Write')
      printData(lat[2])
       
    if not bw[3][0][0][0][0] == 0:
      print('Bandwidth - Random Write')
      printData(bw[3])
      print('Latency - Random Write')
      printData(lat[3])

  except IOError:
    print('No such file exists')

# Begin of program
if len(sys.argv) == 3:
  main(sys.argv)
else:
  print('Usage: parse.py [file to parse] [parsing type]')
