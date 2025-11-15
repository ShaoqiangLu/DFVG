#include <fstream>
#include <iostream>
#include "bir/Module.h"
#include "bir/Function.h"
#include "bir/BasicBlock.h"
#include "bir/Instruction.h"
#include "bir/NodeContainer.h"

#include "nlohmann/json.hpp"

#include "LayerInfo.h"

using namespace bir;

Module& Module::operator=(Module &&other) {
  NodeContainer<Module, Function>::operator=(std::move(other));
  return *this;
}

Function& Module::addFunction(const std::string &Name) {
  Function &function = NodeContainer<Module, Function>::insertElement<Function>(end(), Name);
  return function;  
}

void Module::removeFunction(Function &Func) {
  NodeContainer<Module, Function>::removeElement(Func);
}

Function* Module::getFunctionByName(const std::string &Name) {
  return NodeContainer<Module, Function>::getElementByName(Name);
}

void Module::load(const std::string &inputFileName) {
  std::ifstream inputFile(inputFileName);
  loadJson(inputFile);
}

void Module::loadJson(std::ifstream &inputStream) {
  // Parse from Json
  std::vector<LayerInfo*> layers;
  for (std::string line; std::getline(inputStream, line); ) {
    nlohmann::json json_str = nlohmann::json::parse(line);
    auto layer = new LayerInfo();
    layer->from_json(json_str);
    layers.push_back(layer);
  }
  // Build BIR Module (we assume layer by layer for now)
  Function& Func = addFunction("main");
  std::unordered_map<int, MemoryLocation*> m_x_map;
  std::unordered_map<int, MemoryLocation*> m_w_map;
  std::unordered_map<int, MemoryLocation*> m_b_map;
  for (int i = 0; i <= layers.size(); i++) {
    m_x_map[i] = new MemoryLocation("x" + std::to_string(i), MemoryType::DRAM);
    Func.addMemoryLocation(m_x_map[i]);
  }
  for (int i = 1; i <= layers.size(); i++) {
    m_w_map[i] = new MemoryLocation("w" + std::to_string(i), MemoryType::DRAM);
    Func.addMemoryLocation(m_w_map[i]);
  }
  for (int i = 1; i <= layers.size(); i++) {
    m_b_map[i] = new MemoryLocation("b" + std::to_string(i), MemoryType::DRAM);
    Func.addMemoryLocation(m_b_map[i]);
  }
  for (auto layer : layers) {
    std::string block_name = "layer_" + std::to_string(layer->index);
    BasicBlock &block = Func.addBasicBlock(block_name);
    // Extract layer info
    auto ishape = layer->input_size;
    int n = ishape[0];
    int h = ishape[1];
    int w = ishape[2];
    int c = ishape[3];
    auto oshape = layer->output_size;
    int k = oshape[3];
    auto kz = layer->ker_size;
    auto ks = layer->ker_stride;
    int r = kz[1];
    int s = kz[2];
    int stride = ks[1];
    int type = layer->type;
    int group = layer->group;
    std::string name = "op_" + std::to_string(layer->index);
    if (type == 1 && c != group) {
      block.addInstruction<Conv2dInst>(name, n, h, w, k, c, r, s, stride);
    } else if (type == 1 && c == group) {
      block.addInstruction<Conv2ddwInst>(name, n, h, w, k, c, r, s, stride);
    } else {
      std::cout << "Unsupported layer type : " << type << " group : " << group << "\n";
      exit(1);
    }
    m_w_map[layer->index]->setTensorshape(k, c, r, s);
    m_x_map[layer->index]->setTensorshape(n, k, oshape[1], oshape[2]);
    m_b_map[layer->index]->setTensorshape(k);
    Instruction &inst = block.instructions().back();
    block.addComplexInstruction(&inst);
    for (auto idx : layer->input_layer) {
      if (idx == 0) {
        m_x_map[idx]->setTensorshape(n, c, h, w);
      }
      inst.addInput(m_x_map[idx]);
    }
    inst.addInput(m_w_map[layer->index]);
    inst.addInput(m_b_map[layer->index]);
    inst.addOutput(m_x_map[layer->index]);
    // set attrs
    inst.setAttr("input fraclen", layer->input_fraclen);  // quatization
    inst.setAttr("output fraclen", layer->output_fraclen);
    inst.setAttr("weight fraclen", layer->weight_fraclen);
    inst.setAttr("bias fraclen", layer->bias_fraclen);
    inst.setAttr("post padding", layer->post_padding);  // padding
    auto pps = layer->post_padding_size;  
    inst.setAttr("post padding size u", pps[0]);  
    inst.setAttr("post padding size d", pps[1]);
    inst.setAttr("post padding size l", pps[2]);
    inst.setAttr("post padding size r", pps[3]);
    auto prp = layer->pre_remove_padding_size;
    inst.setAttr("pre remove padding u", prp[0]);
    inst.setAttr("pre remove padding d", prp[1]);
    inst.setAttr("pre remove padding l", prp[2]);
    inst.setAttr("pre remove padding r", prp[3]);
    inst.setAttr("pooling type", layer->pooling_type);  // pooling
    inst.setAttr("pool size r", layer->pooling_size[1]);
    inst.setAttr("pool size s", layer->pooling_size[2]);
    inst.setAttr("pool stride r", layer->pooling_stride[1]);
    inst.setAttr("pool stride s", layer->pooling_stride[2]);
    inst.setAttr("post order encoding", layer->res_position);
    // post ops
    // perhaps directly set attributes to avoid info restore in the later stage
    // e.g., inst.setAttr("activation_type") = 1
    // activation
    ActivationInst* act = nullptr;
    int activation_type = layer->activation_type;
    std::string act_name = name + "_activation_" + std::to_string(activation_type);
    if (activation_type == 1) {
      act = new ActivationInst(act_name, &block, "ReLU");
    } else if (activation_type == 2) {
      act = new ActivationInst(act_name, &block, "LeakyReLU", 0.1);
    } else if (activation_type == 0) {
    } else {
      std::cout << "Unsupported activation type : " << activation_type << "\n";
      exit(1);
    }
    if (act != nullptr)
      block.addComplexInstruction(act);
    // pooling
    PoolingInst* pool = nullptr;
    int pooling_type = layer->pooling_type;
    std::string pool_name = name + "_pool_" + std::to_string(pooling_type);
    auto pooling_size = layer->pooling_size;
    auto pooling_stride = layer->pooling_stride;
    int pool_r = pooling_size[1];
    int pool_s = pooling_size[2];
    int pool_sr = pooling_stride[1];
    int pool_ss = pooling_stride[2];
    if (pooling_type == 1) {
      pool = new PoolingInst(pool_name, &block, "max", pool_r, pool_s, pool_sr, pool_ss);
    } else if (pooling_type == 2) {
      pool = new PoolingInst(pool_name, &block, "avg", pool_r, pool_s, pool_sr, pool_ss);
    } else if (pooling_type == 0) {
    } else {
      std::cout << "Unsupported pooling type : " << pooling_type << "\n";
      exit(1);
    }
    if (pool != nullptr)
      block.addComplexInstruction(pool);
  }
}