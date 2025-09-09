#include <fstream>
#include <iostream>

#include "nlohmann/json.hpp"

#include "accelerator.h"

int run_one_line(std::string line, Device* dev) {
    nlohmann::json j = nlohmann::json::parse(line);
    std::string opcode;
    j.at("opcode").get_to(opcode);
    if (opcode == "load") {
        auto load = dev->load_ins_;
        int load_type;
        std::vector<int> ddr_load_type;
        j.at("ddr_load_type").get_to(load_type);
        if (load_type & 0x1) {
            j.at("ddr_fm_addr_ini").get_to(load->ddr_fm_addr_ini);
            j.at("ddr_load_block_y_size").get_to(load->ddr_load_block_y_size);
            j.at("ddr_load_block_x_size").get_to(load->ddr_load_block_x_size);
            j.at("ddr_fm_read_num").get_to(load->ddr_fm_read_num);
            j.at("fm_in_y_size").get_to(load->fm_in_y_size);
            j.at("fm_in_x_size").get_to(load->fm_in_x_size);
            j.at("fm_bank_id").get_to(dev->fm_ram_id);
            ddr_load_type.push_back(OPU_MEM_ID_FM);
        }
        if (load_type & 0x2) {
            j.at("ddr_ker_addr_ini").get_to(load->ddr_ker_addr_ini);
            j.at("ddr_ker_read_num").get_to(load->ddr_ker_read_num);
            j.at("wgt_bank_id").get_to(dev->wgt_ram_id);
            ddr_load_type.push_back(OPU_MEM_ID_WGT);
        }
        if (load_type & 0x4) {
            j.at("ddr_bias_addr_ini").get_to(load->ddr_bias_addr_ini);
            j.at("ddr_bias_read_num").get_to(load->ddr_bias_read_num);
            j.at("bias_bank_id").get_to(dev->bias_ram_id);
            ddr_load_type.push_back(OPU_MEM_ID_BIAS);
        }
        if (load_type & 0x8) ddr_load_type.push_back(OPU_MEM_ID_RESIDUAL);
        j.at("ddr_load_single").get_to(load->ddr_load_single);
        if (load_type & 0x10) ddr_load_type.push_back(OPU_MEM_ID_INS);
        load->ddr_load_type = ddr_load_type;        
        dev->RunLoad(load);
    } else if (opcode == "store") {
        auto store = dev->store_ins_;
        j.at("ddr_save_pos").get_to(store->ddr_save_pos);
        j.at("ddr_save_des").get_to(store->ddr_save_des);
        j.at("residual").get_to(store->residual);
        j.at("activation").get_to(store->activation);
        j.at("activation").get_to(dev->reg_.activation);
        j.at("activation_type").get_to(store->activation_type);
        j.at("pooling").get_to(store->pooling);
        j.at("pooling").get_to(dev->reg_.pooling);
        j.at("pooling_type").get_to(store->pooling_type);
        j.at("pooling_x_size").get_to(store->pooling_x_size);
        j.at("pooling_y_size").get_to(store->pooling_y_size);
        j.at("pooling_x_stride").get_to(store->pooling_x_stride);
        j.at("pooling_y_stride").get_to(store->pooling_y_stride);
        j.at("ddr_save_block_x_size").get_to(store->ddr_save_block_x_size);
        j.at("ddr_save_block_y_size").get_to(store->ddr_save_block_y_size);
        //j.at("block_pool_x_size").get_to(store->block_pool_x_size);
        //j.at("block_pool_y_size").get_to(store->block_pool_y_size);
        j.at("fm_output_addr_ini").get_to(store->fm_output_addr_ini);
        j.at("ddr_save_fm_num").get_to(store->ddr_save_fm_num);
        j.at("padding").get_to(store->padding);
        j.at("padding_size").get_to(store->padding_size);
        j.at("fm_out_x_size").get_to(store->fm_out_x_size);
        j.at("fm_out_y_size").get_to(store->fm_out_y_size);
        j.at("channel_out").get_to(store->channel_out);
        j.at("upsample_output").get_to(store->upsample_output);
        store->out_y_max = 0;
        store->out_y_min = 0;
        store->out_x_max = 0;
        store->out_x_min = 0;
        store->out_y_stride = 0;
        store->out_x_stride = 0;
        dev->RunStore(store);
    } else if (opcode == "compute") {
        auto compute = dev->compute_ins_;
        j.at("fm_bank_id").get_to(compute->fm_ram_id);
        j.at("wgt_bank_id").get_to(compute->wgt_ram_id);
        if (j.at("add_bias"))
            j.at("bias_bank_id").get_to(compute->bias_ram_id);
        j.at("type").get_to(compute->type);
        j.at("dw_flag").get_to(compute->dw_flag);
        j.at("ker_x_size").get_to(compute->ker_x_size);
        j.at("ker_y_size").get_to(compute->ker_y_size);
        j.at("dma_block_x_size").get_to(compute->dma_block_x_size);
        j.at("dma_block_y_size").get_to(compute->dma_block_y_size);
        j.at("x_min").get_to(compute->dma_x_min);
        j.at("x_max").get_to(compute->dma_x_max);
        j.at("read_x_stride").get_to(compute->read_x_stride);
        j.at("y_min").get_to(compute->dma_y_min);
        j.at("y_max").get_to(compute->dma_y_max);
        j.at("read_y_stride").get_to(compute->read_y_stride);
        j.at("copy_mode").get_to(compute->copy_mode);
        j.at("ker_round").get_to(compute->ker_round);
        //j.at("ker_on_board").get_to(compute->ker_on_board);
        //j.at("ker_repeat").get_to(compute->ker_repeat);
        //j.at("ker_repeat_last").get_to(compute->ker_repeat_last);
        j.at("ker_addr_s").get_to(compute->ker_addr_s);
        j.at("ker_addr_e").get_to(compute->ker_addr_e);
        j.at("output_num").get_to(compute->output_num);
        j.at("channel_out").get_to(compute->channel_out);
        j.at("output_channel").get_to(compute->output_channel);
        j.at("shift_num_fm").get_to(compute->shift_num_fm);
        j.at("shift_num_bias").get_to(compute->shift_num_bias);
        j.at("add_bias").get_to(compute->add_bias);
        j.at("add_temp").get_to(compute->add_temp);
        j.at("final_output").get_to(compute->final_output);
        j.at("output_block_y_size").get_to(compute->output_block_y_size);
        j.at("output_block_x_size").get_to(compute->output_block_x_size);
        dev->RunCompute(compute);
    } else if (opcode == "barrier") {
        return 0;
    }
    return 1;
}

void run_one_layer(std::ifstream &inputStream, Device* dev) {
    for (std::string line; std::getline(inputStream, line); ) {
        if (run_one_line(line, dev) == 0) {
            break;
        }
    }  
}

int get_layer_cnt(std::string filename) {
    std::ifstream inputFile(filename);
    int layer_cnt = 0;
    for (std::string line; std::getline(inputFile, line); ) {
        nlohmann::json j = nlohmann::json::parse(line);
        std::string opcode;
        j.at("opcode").get_to(opcode);
        if (opcode == "barrier") {
            layer_cnt++;
        }
    }
    inputFile.close();
    return layer_cnt;
}

int main(int argc, char*argv[]) {
    Device* dev = new Device();
    std::string filename = argv[1];
    std::cout << "read from " << filename << "\n";
    int layer_cnt;
    if (argc == 2) {
        layer_cnt = get_layer_cnt(filename);
        std::cout << "#layer count = " << layer_cnt << "\n";
    } else {
        layer_cnt = std::atoi(argv[2]);
    }
    std::ifstream inputFile(filename);
    for (int i = 0; i < layer_cnt; i++) {
        if (i == layer_cnt - 1) {
            dev->dump = true;
        }
        run_one_layer(inputFile, dev);
    }
    inputFile.close();
    dev->os.close();
    return 0;
}