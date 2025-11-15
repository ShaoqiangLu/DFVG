#ifndef DATA_LAYOUT_GEN_WEIGHT_LAYTOUT_H
#define DATA_LAYOUT_GEN_WEIGHT_LAYTOUT_H

#include <string>
#include <fstream>
#include <vector>

class WeightLayout {
 public:
  std::string filename_last_opened = "";
  std::vector<float> weight_original;  
  void run(std::string filename, std::string wpath);  
  void generate_weight_layout(std::string line, std::string wpath, std::ofstream &os);
};


#endif