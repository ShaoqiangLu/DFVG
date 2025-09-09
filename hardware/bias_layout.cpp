#include "bias_layout.h"
#include "utils.h"

#include <fstream>
#include <vector>
#include <cmath>

#include "nlohmann/json.hpp"

using namespace nlohmann;

void generate_bias_layout(std::string line, std::string bpath, std::ofstream &os) {
    json j = nlohmann::json::parse(line);
    int layer_index;
    int fraclen;
    j.at("layer index").get_to(layer_index);
    j.at("bias fraclen").get_to(fraclen);
    std::vector<std::pair<int, int>> range;
    j.at("range").get_to(range);
    int c_lb = range[0].first;
    int c_ub = range[0].second;

    //
    std::string b_filename = bpath + "/bias_" + std::to_string(layer_index - 1) + ".npy";
    std::vector<float> bias_original = ReadNpyAndSaturate(b_filename, fraclen, 16);
    
    // 
    int bias_c_num = c_ub - c_lb;
    std::vector<float> bias_new(64 * ceil((float)bias_c_num / 64), 0);
    int cnt = 64 - bias_c_num;
    for (int k = std::min(bias_c_num, 64) - 1; k > -1; k--) {
        bias_new[cnt] = (bias_original[c_lb + k]) * std::pow(2, fraclen);
        cnt++;
    }
    
    // 
    std::vector<char> bias_vector;
    for (auto v : bias_new) {
        int val = (int)v;
        bias_vector.push_back((int)floor((double)val / 256));
		bias_vector.push_back(val % 256);
    }
    //os.write(&bias_vector[0], bias_vector.size());
    for (auto v : bias_vector) {
        os << v;
    }
}

void BiasLayout::run(std::string filename, std::string bpath) {
    std::string bias_bin_file_path = "bias.bin";
    std::ofstream f_bin;
    f_bin.open(bias_bin_file_path, std::ios::out | std::ios::binary);
    std::ifstream inputFile(filename);
    for (std::string line; std::getline(inputFile, line); ) {
        generate_bias_layout(line, bpath, f_bin);
    } 
    f_bin.close();
}