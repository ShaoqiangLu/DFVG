#include <fstream> 
#include <iostream>
#include <string>

#include "bias_layout.h"
#include "weight_layout.h"

int main(int argc, char*argv[]){
    std::string weight_layout_filename = argv[1];
    std::string bias_layout_filename = argv[2];
    
    BiasLayout().run(argv[2], argv[3]);
    WeightLayout().run(argv[1], argv[3]);
    return 0;  
}