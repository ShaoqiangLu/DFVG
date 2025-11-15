#include "weight_layout.h"
#include "utils.h"

#include <fstream>
#include <vector>
#include <cmath>
#include <iostream>
#include <algorithm>

#include "nlohmann/json.hpp"

using namespace nlohmann;

void WeightLayout::generate_weight_layout(std::string line, std::string wpath, std::ofstream &os) {
    json j = nlohmann::json::parse(line);
    int layer_index;
    int fraclen;
    j.at("layer index").get_to(layer_index);
    j.at("weight fraclen").get_to(fraclen);
    int dram_addr_cnt;
    j.at("address count").get_to(dram_addr_cnt);
    bool channel_enhanced;
    j.at("channel enhanced").get_to(channel_enhanced);
    std::string format;
    j.at("format").get_to(format);
    assert(format == "KCRS");
    int Tk;
    j.at("output channel tiling size").get_to(Tk);
    std::vector<int> shape;
    j.at("shape").get_to(shape);  // global shape
    int K = shape[0];
    int C = shape[1];
    int R = shape[2];
    int S = shape[3];
    std::vector<std::pair<int, int>> range;
    j.at("range").get_to(range);  // local index
    int k_lb = range[0].first;
    int k_ub = range[0].second;
    int c_lb = range[1].first;
    int c_ub = range[1].second;
    int r_lb = range[2].first;
    int r_ub = range[2].second;
    int s_lb = range[3].first;
    int s_ub = range[3].second;
    int Tc = 64;
    if (c_ub - c_lb <= 16) {
        Tc = 16;
    } else if (c_ub - c_lb <= 32) {
        Tc = 32;
    }  
    //
    std::string w_filename = wpath + "/weights_" + std::to_string(layer_index - 1) + ".npy";
    if (w_filename != filename_last_opened) {
        // weight files are usually large so avoid loading the same data multiple times
        weight_original = ReadNpyAndSaturate(w_filename, fraclen, 8);  // RSCK
        if (channel_enhanced) {
            std::vector<int> raw_wshape;
            j.at("raw weight shape").get_to(raw_wshape);  // KCRS
            int C_raw = raw_wshape[1];
            int R_raw = raw_wshape[2];
            int S_raw = raw_wshape[3];
            std::vector<float> tmp;
            // target : w[][2][0][0], w[][2][0][1], w[][2][0][2], ...
            for (int c = 0; c < C_raw; c++) {
                for (int r = R_raw - 1; r > -1; r--) {
                    for (int s = S_raw - 1; s > -1; s--) {
                        for (int k = 0; k < K; k++) {
                            tmp.push_back(weight_original[r*S_raw*C_raw*K + s*C_raw*K + c*K + k]);
                        }
                    }
                }
            }
            weight_original = tmp;
        }
        filename_last_opened = w_filename;
    }

    int bytes = 0;
    for (int r = r_lb; r < r_ub; r++) {
        for (int s = s_lb; s < s_ub; s++) {
            for (int k_outer = 0; k_outer < std::ceil((float)(k_ub - k_lb) / Tk); k_outer++) {
                // input def to MACs in one cycle
                std::vector<float> data;
                int k_residue = (std::min(K, k_lb + (k_outer + 1) * Tk) - (k_lb + k_outer * Tk)) % Tk;
                int k_pad = 0;
                if (k_residue != 0) {
                    k_pad = Tk - k_residue;
                }
                for (int k = k_lb + k_outer * Tk; k < std::min(K, k_lb + (k_outer + 1) * Tk); k+=2) {
                    std::vector<float> channel_1;
                    // pad input channel for alignment
                    for (int p = 0; p < Tc - (c_ub - c_lb); p++) {
                        channel_1.push_back(0);
                    }
                    for (int c = c_lb; c < c_ub; c++) {
                        channel_1.push_back(weight_original[r*S*C*K + s*C*K + c*K + k] * std::pow(2, fraclen));
                    }
                    std::vector<float> channel_2;
                    for (int p = 0; p < Tc - (c_ub - c_lb); p++) {
                        channel_2.push_back(0);
                    }
                    for (int c = c_lb; c < c_ub; c++) {
                        channel_2.push_back(weight_original[r*S*C*K + s*C*K + c*K + k + 1] * std::pow(2, fraclen));
                    }
                    // interleave 
                    for (int i = 0; i < Tc; i++) {
                        data.push_back(channel_1[i]);
                        data.push_back(channel_2[i]);
                    } 
                }
                for (int p = 0; p < k_pad * Tc; p++) {
                    data.push_back(0);
                }
                // c[63] ... c[0]
                std::reverse(data.begin(), data.end());
                // write binary
                std::vector<char> weight_vector;
                for (auto v : data) {
                    weight_vector.push_back((int)v);
                }
                for (auto v : weight_vector) {
                    os << v;
                }
                // size check
                bytes += weight_vector.size();
            }
        }
    }
    if (bytes != dram_addr_cnt * 64) {
        std::cout << line << "\n";
        std::cout << bytes << " v.s. (expected)" << dram_addr_cnt * 64 << "\n";
        assert(0);
    }
}

void WeightLayout::run(std::string filename, std::string wpath) {
    std::string weight_bin_file_path = "weight.bin";
    std::ofstream f_bin;
    f_bin.open(weight_bin_file_path, std::ios::out | std::ios::binary);
    std::ifstream inputFile(filename);
    for (std::string line; std::getline(inputFile, line); ) {
        generate_weight_layout(line, wpath, f_bin);
    } 
    f_bin.close();
}