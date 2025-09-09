#ifndef ENGINETYPE_H
#define ENGINETYPE_H

#include <string>

enum class EngineType {
  DMA,
  PE,
  UNKNOWN
};

std::string EngineType2String(EngineType engine);

#endif
