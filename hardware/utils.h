#ifndef DATA_LAYOUT_GEN_UTILS_H
#define DATA_LAYOUT_GEN_UTILS_H

#include <vector>
#include <string>

// only for checking purpose, input npy should already have been quantized
std::vector<float> ReadNpyAndSaturate(std::string filename, int frac_len, int bit_width);

#endif 
