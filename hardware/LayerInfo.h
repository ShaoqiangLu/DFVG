#ifndef LAYERINFO_H
#define LAYERINFO_H

#include <fstream>
#include <string>
#include <vector>

#include "nlohmann/json.hpp"

using json = nlohmann::json;

class LayerInfo {
 public:
  typedef int opu_int;
  opu_int type;
  std::vector<opu_int> input_layer;
  std::vector<opu_int> output_layer;
  std::vector<opu_int> input_size;
  std::vector<opu_int> output_size;
  std::vector<opu_int> ker_size;
  std::vector<opu_int> ker_stride;
  std::vector<opu_int> pooling_size;
  std::vector<opu_int> pooling_stride;
  opu_int pooling_type {0};
  std::vector<opu_int> pool_padding_size;
  std::vector<opu_int> padding_size;
  opu_int activation_type {0};
  opu_int residual {0};
  std::vector<opu_int> residual_source;
  std::vector<opu_int> output_choice {{3, -1}};
  opu_int res_position {3};
  opu_int group {0};
  opu_int channel_shuffle {0};
  opu_int upsample {0};
  // post padding
  opu_int extra_pre_padding {0};  // for testing purpose only
  std::vector<opu_int> post_padding_size;
  std::vector<opu_int> pre_remove_padding_size;
  opu_int post_padding {0};
  opu_int post_padding_mode {0};
  // temporary data structures
  std::string data_layout {""};
  std::string kernel_layout {""};
  std::vector<opu_int> dilation;
  std::string upsample_method {""};
  opu_int index;
  std::vector<std::string> op_dfs_order;
  std::unordered_map<std::string, int> op_dfs_order_idx_map;
  std::vector<opu_int> explicit_padding_size;
  opu_int explicit_pad {0};
  // quantization
  bool quantized {false};
  opu_int input_fraclen;
  opu_int output_fraclen;
  opu_int weight_fraclen;
  opu_int bias_fraclen;

  void to_json(json& j) {
    j["index"] = index;
    j["type"] = type;
    j["input_layer"] = input_layer;    
    j["output_layer"] = output_layer;    
    j["input_size"] = input_size;    
    j["output_size"] = output_size;    
    j["ker_size"] = ker_size;    
    j["ker_stride"] = ker_stride;    
    j["pooling_size"] = pooling_size;    
    j["pooling_stride"] = pooling_stride;    
    j["pooling_type"] = pooling_type; 
    j["pool_padding_size"] = pool_padding_size; 
    j["padding_size"] = padding_size; 
    j["activation_type"] = activation_type; 
    j["residual"] = residual; 
    j["residual_source"] = residual_source; 
    j["output_choice"] = output_choice; 
    j["res_position"] = res_position;    
    j["group"] = group;    
    j["channel_shuffle"] = channel_shuffle;    
    j["upsample"] = upsample;
    j["data_layout"] = data_layout;
    j["kernel_layout"] = kernel_layout;
    j["dilation"] = dilation;
    j["upsample_method"] = upsample_method;
    j["input_fraclen"] = input_fraclen;
    j["output_fraclen"] = output_fraclen;
    j["weight_fraclen"] = weight_fraclen;
    j["bias_fraclen"] = bias_fraclen;
    
    j["post_padding_size"] = post_padding_size; 
    j["pre_remove_padding_size"] = pre_remove_padding_size; 
    j["post_padding"] = post_padding;
    j["post_padding_mode"] = post_padding_mode;
    j["extra_pre_padding"] = extra_pre_padding;
  }
  
  void from_json(const json& j) {
    j.at("index").get_to(index);
    j.at("type").get_to(type);
    j.at("input_layer").get_to(input_layer);
    j.at("output_layer").get_to(output_layer);
    j.at("input_size").get_to(input_size);
    j.at("output_size").get_to(output_size);
    j.at("ker_size").get_to(ker_size);
    j.at("ker_stride").get_to(ker_stride);
    j.at("pooling_size").get_to(pooling_size);
    j.at("pooling_stride").get_to(pooling_stride);
    j.at("pooling_type").get_to(pooling_type);
    j.at("pool_padding_size").get_to(pool_padding_size);
    j.at("padding_size").get_to(padding_size);
    j.at("activation_type").get_to(activation_type);
    j.at("residual").get_to(residual);
    j.at("residual_source").get_to(residual_source);
    j.at("output_choice").get_to(output_choice);
    j.at("res_position").get_to(res_position);
    j.at("group").get_to(group);
    j.at("channel_shuffle").get_to(channel_shuffle);
    j.at("upsample").get_to(upsample);
    j.at("data_layout").get_to(data_layout);
    j.at("kernel_layout").get_to(kernel_layout);
    j.at("dilation").get_to(dilation);
    j.at("upsample_method").get_to(upsample_method);
    j.at("input_fraclen").get_to(input_fraclen);
    j.at("output_fraclen").get_to(output_fraclen);
    j.at("weight_fraclen").get_to(weight_fraclen);
    j.at("bias_fraclen").get_to(bias_fraclen);
    
    j.at("post_padding_size").get_to(post_padding_size);
    j.at("pre_remove_padding_size").get_to(pre_remove_padding_size);
    j.at("post_padding").get_to(post_padding);
    j.at("post_padding_mode").get_to(post_padding_mode);
    j.at("extra_pre_padding").get_to(extra_pre_padding);
  }
};

#endif
