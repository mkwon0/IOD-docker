#include <chrono>
#include <iostream>
#include <sstream>
#include <thread>

#include "memory.hh"

uint64_t getTick() {
  auto now = std::chrono::system_clock::now().time_since_epoch();
  return std::chrono::duration_cast<std::chrono::milliseconds>(now).count();
}

int main(int argc, char *argv[]) {
  std::string pid;
  uint64_t period;
  uint64_t duration;
  std::ofstream out(argv[4]);
  std::streambuf *contbuf = std::cout.rdbuf();
  std::cout.rdbuf(out.rdbuf());

  if (argc != 4) {
    std::cout << "Usage: stat [target pid] [period in ms] [duration in ms] [outputfile]" << std::endl;

    return -1;
  }

  // Convert
  pid=argv[1];
  period = strtoul(argv[2], nullptr, 10);
  duration = strtoul(argv[3], nullptr, 10);

  int count = duration / period;
  if (period == 0) {
    std::cout << "Invalid period " << argv[2] << std::endl;

    return -2;
  }

  std::cout << "Stat collector for docker" << std::endl;
  std::cout << " Period: " << period << " ms" << std::endl;
  std::cout << std::endl;

  std::chrono::milliseconds ms(period);

  // Stat definitions
  MemoryStat memory(pid);

  // Initial setup
  uint64_t now, idx, size;
  std::vector<std::string> list;
  std::vector<double> values;
  std::string str;

  memory.getStatList(list);

  size = list.size();

  {
    std::stringstream ss;

    for (idx = 0; idx < size; idx++) {
      ss << list.at(idx) << ", ";
    }

    str = ss.str();

    std::cout << "Time (ms), " << str << std::endl;
  }

  while (count > 0) {
    std::stringstream ss;

    values.clear();

    now = getTick();

    // Get values
    memory.getStatValues(values);

    // Print values
    ss.flush();

    for (idx = 0; idx < size; idx++) {
      ss << values.at(idx) << ", ";
    }

    str = ss.str();

    std::cout << now << ", " << str << std::endl;
    std::this_thread::sleep_for(ms);
    count -= 1;
  }

  if (out.is_open()){
    out.close();
  }
  return 0;
}
