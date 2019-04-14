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
    config = {"minbs": 0, "maxbs": 0, "minqd": 0, "maxqd": 0, "mindev": 0, "maxdev": 3}
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
  row = len(data)
  col = len(data[0])

  if analType == "per":
    for i in range(0, 4):
      for r in range(0, row):
        for c in range(0, col):
          idx=4*c+i
          sys.stdout.write('{0:.2f}'.format(data[r][c][idx]))
          if c < col - 1:
            sys.stdout.write('\t')
        sys.stdout.write('\n')
      sys.stdout.write('\n')
  elif analType == "blk":
    for c in range(0, col):
      for r in range(0, row):
        for i in range(0,4):
          idx=4*c+i
          sys.stdout.write('{0:.2f}'.format(data[r][c][idx]))
          if not (c == col - 1 and idx == col*4): 
            sys.stdout.write('\t')
      sys.stdout.write('\n')
  elif analType == "qd":
    for r in range(0,row):
      for c in range(0,col):
        for i in range(0,4):
          idx=4*c+i
          sys.stdout.write('{0:.2f}'.format(data[r][c][idx]))
          if idx < col * 4:
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
      
      # Allocate data
      bw = [0] * 4
      for i in range(0, 4):
        bw[i] = [0] * config['bscount']
        for j in range(0, config['bscount']):
          bw[i][j] = [[]] * config['qdcount']

      lat = [0] * 4
      for i in range(0, 4):
        lat[i] = [0] * config['bscount']
        for j in range(0, config['bscount']):
          lat[i][j] = [[]] * config['qdcount']

      # Parse contents
      regexQDepth = re.compile('Testing for qdepth (\d+)')
      regexBlockSize = re.compile('Test for block size (\d+)')
      regexDeviceNum = re.compile('Test for device (\d+)')
      regexIO = re.compile('Test for (seq|rand)(read|write)')
      regexBW = re.compile('BW=.*\(([\d.]+)([GMk])B/s\)')
      regexLatency = re.compile(' lat \(([mun])sec\):.*avg=([ \d.]+)')

      current = {'io': 0, 'qd': 0, 'bs': 0}

      f.seek(0)
      for line in f:
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
          bw[current['io']][current['bs']][current['qd']].append(float(
            match.group(1)) * convertBWUnit(match.group(2)))
         
        match = regexLatency.search(line)
        if match:
          lat[current['io']][current['bs']][current['qd']].append(float(
            match.group(2)) * convertLatencyUnit(match.group(1)))

    if bw[0][0][0]:
      print('Bandwidth - Sequential Read')
      printData(bw[0])
    if lat[0][0][0]:
      print('Latency - Sequential Read')
      printData(lat[0])
    if bw[1][0][0]:
      print('Bandwidth - Random Read')
      printData(bw[1])
    if lat[1][0][0]:
      print('Latency - Random Read')
      printData(lat[1])
    if bw[2][0][0]:
      print('Bandwidth - Sequential Write')
      printData(bw[2])
    if lat[2][0][0]:
      print('Latency - Sequential Write')
      printData(lat[2])
    if bw[3][0][0]:
      print('Bandwidth - Random Write')
      printData(bw[3])
    if lat[3][0][0]:
      print('Latency - Random Write')
      printData(lat[3])

  except IOError:
    print('No such file exists')

# Begin of program
if len(sys.argv) == 3:
  main(sys.argv)
else:
  print('Usage: parse.py [file to parse] [parsing type]')
