#include <fstream>
#include <vector>
#include <string>
#include <sstream>
#include <typeinfo>

#ifndef FSIM_BIT_UTIL_H_
#define FSIM_BIT_UTIL_H_

#define REVERSE_BYTES16(value) (((value & 0xFF) << 8) | ((value & 0xFF00) >> 8))
#define REVERSE_BYTES32(value) (((value & 0xFF) << 24) | ((value & 0xFF00) << 8) | ((value & 0xFF0000) >> 8) | ((value & 0xFF000000) >> 24))

/*
 * Deal with overflow. 
 */ 
template <typename T>
inline T Saturate(T x, bool positive, int wl) {
  T mask;
  if(typeid(T) == typeid(int)){
    mask = 0xFFFFFFFF << (wl-1);
  }
  else if(typeid(T) == typeid(long)){
    mask = 0xFFFFFFFFFFFFFFFF << (wl-1);
  }
  if (x == 0) {
    return x;
  } else if (!positive && ((mask & x) != mask)) {
    return mask;  // negative max, keep negative when extended to 32 bit int
  } else if (positive && (mask & x)) {
    return ~mask;
  }
  return x;
}

/*
 * Convert to big endian.
 */ 
template <typename T, int precision, int adder_num>
void convertToBigEndian(std::vector<T> &x){
  T *p = &x[0];
  for (int i = 0; i < x.size(); ++i)
  {
      if (precision * 2 == 16)
      {
          int16_t *value = reinterpret_cast<int16_t *>(&p[i]);
          int16_t tmp = REVERSE_BYTES16(*value);
          p[i] = static_cast<int>(tmp);
      }
      else if (precision * 2 == 32)
      {
          int32_t *value = reinterpret_cast<int32_t *>(&p[i]);
          int32_t tmp = REVERSE_BYTES32(*value);
          p[i] = static_cast<int>(tmp);
      }
  }
  std::memcpy(&x[0], p, adder_num);
}

template <typename T, int W>
  void writeOut(std::ofstream& os,
    std::vector<T> data, bool dump = false) {  // W - #char to print
    if (!dump) return;
    std::stringstream ss;
    for (auto item : data) {
      std::stringstream sstream;
      sstream << std::hex << static_cast<long>(item);
      std::string ret = sstream.str();
      if (ret.length() > W) {
        ret = ret.substr(ret.length() - W, W);
      } else if (ret.length() < W) {
        for (int ii = 0; ii <= W - ret.length(); ii++)
          ret = "0"+ret;
      }
      ss << ret << " ";
    }
    os << ss.str() << "\n";
  }
#endif  // FSIM_BIT_UTIL_H_
