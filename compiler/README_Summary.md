# Important Data Structure and Functions

Data Structure

	MemOp    - Encapsulates source/destination address and size for memory operation

    SRAM     - Memory object used to allocate buffer for PE, accumulator, partial sum and create scratchpad memory.
        parameters: 
            bits : bits per element for one bank
            size : total element number for one bank
            banks : memory banks number
    
    IPA      - Inner product array. Includes the functional simulator for inner product and accumulate operation.
        parameters: 
            mac : number of multiply-accumulate units (DSP macros on FPGA) per PE
            pe : number of PE (processing unit), which is a bunch of macs followed by adder tree for reduction
            operand_bits : word lengths for mac operands (8 by default)
    
    Device   - Top abstraction for OPU overlay, including the memory buffer allocated for conventional and
               depthwise convolution, double buffering, IPA, the abstraction of control flow and functions
               for instructions.

Functions

    Run(N)      - Top function wrapper for running events in N phases. Events include LD (DDR load),
                  ST (DDR store), COMPUTE (pipeline : data fetch - compute - accumulate) may be run 
                  in parallel semantic.
    
    FetchInsn() - Operations for fetching one instruction block, including instruction fetching, register
                  file decode and update, and control flow update.
    
    RunLoad(OPUDDRLDInsn*) -   Function wrapper for DDR load instruction, which traverses load options
                               and perform memory transaction from DDR to SRAM accordingly for feature map, 
                               weight, bias, instruction.

    RunStore(OPUDDRSTInsn*) -  Function wrapper for DDR store instruction, which applies post conv processings
                               including activation, pooling, residual addition, padding, (upsampling) in the 
                               order dynamically specified by instructions.

    RunPostProcess(OPUDDRSTInsn*) - Run post-processing operation according to pooling's memory access pattern 
                                    and ddr_save_pos.

    RunPadding(OPUDDRSTInsn*) - Pad output feature map with zeros according to the specified padding size.

    RunCompute(OPUComputeInsn*) - Function wrapper for the functionality of running conv2d on IPA module.

    RunComputeDW(OPUComputeInsn*) - Run depthwise conv2d on IPA module.

    RunComputeFC(OPUComputeInsn*) - Run fully-connection (vector-matrix multiplication) on IPA module.