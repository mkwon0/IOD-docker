#pragma once

#ifndef __BASE_STAT__
#define __BASE_STAT__

#include <cinttypes>
#include <string>
#include <vector>

class StatObject {
 public:
  StatObject() {}
  virtual ~StatObject() {}

  virtual void getStatList(std::vector<std::string> &) = 0;
  virtual void getStatValues(std::vector<double> &) = 0;
  virtual void resetStatValues() = 0;
};

#endif
