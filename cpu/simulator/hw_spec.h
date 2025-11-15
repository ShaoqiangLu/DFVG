#include <stdint.h>
#include <vector>
#include <algorithm>
#include <iterator>

#ifndef FSIM_HW_SPEC_H_
#define FSIM_HW_SPEC_H_

/*! Mem ID constant */
enum MemID
{
    // input feature map memory
    OPU_MEM_ID_FM,
    // kernel memory
    OPU_MEM_ID_WGT,
    // bias memory
    OPU_MEM_ID_BIAS,
    // residual memory
    OPU_MEM_ID_RESIDUAL,
    // instruction memory
    OPU_MEM_ID_INS
};

/*! DDR load trigger constant */
enum DDRLD
{
    OPU_DDRLD_TRIG_DDRLD,
    // dma done here means the completion of multiple consecutive dmas
    OPU_DDRLD_TRIG_DDRLD_DMA,
    OPU_DDRLD_TRIG_LAYER_START,
    OPU_DDRLD_TRIG_DDRST,
    OPU_DDRLD_TRIG_BRAMST = 5,
    OPU_DDRLD_TRIG_BRAMWB_DDRLD,
    OPU_DDRLD_TRIG_DDRLD_DDRST
};

/*! COMPUTE trigger constant */
enum DMATrig
{
    OPU_DMA_TRIG_DMA,
    OPU_DMA_TRIG_DDRLD,
    OPU_DMA_TRIG_DMA_DDRLD,
    OPU_DMA_TRIG_DDRST_NOT_1_6,
    OPU_DMA_TRIG_DDRST = 5
};

/*! DDR store trigger constant */
enum DDRSt
{
    OPU_DDRST_TRIG_BRAMST_DDRLD,
    OPU_DDRST_TRIG_DDRST,
    OPU_DDRST_TRIG_BRAMWB_DDRLD = 3,
    OPU_DDRST_TRIG_DDRLD,
    OPU_DDRST_TRIG_DDRLD_DDRST,
    OPU_DDRST_TRIG_SINGLE_DDRLD
};

/*! Layer type constant */
enum Layer
{
    OPU_LAYER_FC,
    OPU_LAYER_CONV2D,
    OPU_LAYER_SINGLE_POOL,
    OPU_LAYER_SE,
    OPU_LAYER_ZTCONV,
    OPU_LAYER_NTCONV,
    OPU_LAYER_CONV3D
};

/*! Copy mode for local input buffer of compute engine */
enum CopyMode
{
    OPU_COPY_MODE_REP_8,
    OPU_COPY_MODE_REP_16,
    OPU_COPY_MODE_REP_32
};

/*! Activation type */
enum Activation
{
    OPU_ACTIVATION_NONE,
    OPU_ACTIVATION_RELU,
    OPU_ACTIVATION_PRELU,
    OPU_ACTIVATION_HSIGMOID,
    OPU_ACTIVATION_HSWISH,
    OPU_ACTIVATION_LUT
};

/*! Pooling type */
enum Pool
{
    OPU_POOL_NONE,
    OPU_POOL_MAX,
    OPU_POOL_AVG
};

/*! IPA output number */
enum IPAOutNum
{
    OPU_IPA_OUT_NUM_2,
    OPU_IPA_OUT_NUM_4,
    OPU_IPA_OUT_NUM_8,
    OPU_IPA_OUT_NUM_16,
    OPU_IPA_OUT_NUM_32,
    OPU_IPA_OUT_NUM_64
};

/*! DDR write destination */
enum DDRWrite
{
    OPU_DDRST_TO_DDR,
    OPU_DDRST_TO_BRAM
};

#endif // FSIM_HW_SPEC_H_
