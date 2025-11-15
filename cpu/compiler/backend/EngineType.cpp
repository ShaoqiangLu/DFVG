#include "EngineType.h"

std::string EngineType2String(EngineType engine) {
  std::string name;
  switch(engine) {
    case EngineType::DMA: name = "DMA"; break;
    case EngineType::PE: name = "PE"; break;
    default: name = "Unknown"; break;  
  }  
  return name;
}