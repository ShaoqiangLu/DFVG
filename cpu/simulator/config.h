//#define DEBUG_DMA_FM
//#define DEBUG_DMA_KER
//#define DEBUG_OUT_ADDER_A
//#define DEBUG_OUT_ADDER_B
//#define DEBUG_OUT_ADDER_RES
//#define DEBUG_CUT_16
//#define DEBUG_CUT_8
#define DEBUG_POST_OUT

#define ONEDRESNET

#ifdef ONEDRESNET
#define INS_FILE_PATH "/home/tiandong/GITHUB/testing/OPU_Compiler/example/1dresnet/1dResNet_ins.bin"
#define IFM_FILE_PATH "/home/tiandong/GITHUB/testing/OPU_Compiler/example/1dresnet/ifm_reshaped.bin"
#define WGT_FILE_PATH "/home/tiandong/GITHUB/testing/OPU_Compiler/example/1dresnet/Ins/1dResNet_output/on_board_files/weights.bin"
#define BIAS_FILE_PATH "/home/tiandong/GITHUB/testing/OPU_Compiler/example/1dresnet/Ins/1dResNet_output/on_board_files/bias_21.bin"

#define FM_ADDR_INI 0
#define WGT_ADDR_INI 1638400
#define BIAS_ADDR_INI 5734400
#define INS_ADDR_INI 8835248

#define IFM_BYTES 119*64
#define WGT_BYTES 3907584//5316608
#define BIAS_BYTES 26368//30844

#define LAYER_CNT 22
#define RELU_CODE 0
#define LEAKY_RELU_CODE 1
#define NO_RELU_CODE 2
#endif

#ifndef ONEDCNN
#else

#define INS_FILE_PATH "1dcnn_ins.bin"
#define IFM_FILE_PATH "/home/tiandong/GITHUB/OPU_Simulator/fsim/example/tinyyolo/ifm.bin"
#define WGT_FILE_PATH "/home/tiandong/GITHUB/OPU/artifects/be_dump/1dcnn_output/on_board_files/weights.bin"
#define BIAS_FILE_PATH "/home/tiandong/GITHUB/OPU/artifects/be_dump/1dcnn_output/on_board_files/bias_5.bin"

#define FM_ADDR_INI 0
#define WGT_ADDR_INI 1638400
#define BIAS_ADDR_INI 5734400
#define INS_ADDR_INI 8835248

#define IFM_BYTES 416*416*64
#define WGT_BYTES 3145728
#define BIAS_BYTES 21124

#define LAYER_CNT 6
#define RELU_CODE 0
#define LEAKY_RELU_CODE 1
#define NO_RELU_CODE 2

#endif

#ifndef TESTTN
#else

#define INS_FILE_PATH "/home/tiandong/GITHUB/yyx/OPU_compiler_backend/Ins/TN_output/on_board_files/ins.bin"
#define IFM_FILE_PATH "tinyyolo/ifm.bin"
#define WGT_FILE_PATH "/home/tiandong/GITHUB/yyx/OPU_compiler_backend/Ins/TN_output/on_board_files/weights.bin"
#define BIAS_FILE_PATH "/home/tiandong/GITHUB/yyx/OPU_compiler_backend/Ins/TN_output/on_board_files/bias_8.bin"

#define FM_ADDR_INI 0
#define WGT_ADDR_INI 1638400
#define BIAS_ADDR_INI 5734400
#define INS_ADDR_INI 8835248

#define IFM_BYTES 416*416*64
#define WGT_BYTES 246336*64
#define BIAS_BYTES 51656

#define LAYER_CNT 9
#define RELU_CODE 0
#define LEAKY_RELU_CODE 1
#define NO_RELU_CODE 2

#endif

#ifndef TEST
#else

#define INS_FILE_PATH "/home/tiandong/GITHUB/OPU_compiler_backend/Ins/MBv2_output/on_board_files/ins.bin"
#define IFM_FILE_PATH "mobilenetv1/ifm.bin"
#define WGT_FILE_PATH "/home/tiandong/GITHUB/yyx/OPU_compiler_backend/Ins/TinyYOLO_output/on_board_files/weights.bin"
#define BIAS_FILE_PATH "/home/tiandong/GITHUB/yyx/OPU_compiler_backend/Ins/TinyYOLO_output/on_board_files/bias_8.bin"

#define FM_ADDR_INI 0
#define WGT_ADDR_INI 1638400
#define BIAS_ADDR_INI 5734400
#define INS_ADDR_INI 8835248

#define IFM_BYTES 224*224*64
#define WGT_BYTES 246336*64
#define BIAS_BYTES 51656

#define LAYER_CNT 58
#define RELU_CODE 0
#define LEAKY_RELU_CODE 1
#define NO_RELU_CODE 2

#endif


#ifndef MOBILENETV1
#else

#define INS_FILE_PATH "mobilenetv1/ins.bin"
#define IFM_FILE_PATH "mobilenetv1/ifm.bin"
#define WGT_FILE_PATH "mobilenetv1/weights.bin"
#define BIAS_FILE_PATH "mobilenetv1/bias.bin"

#define FM_ADDR_INI 0
#define WGT_ADDR_INI 1638400
#define BIAS_ADDR_INI 4096000
#define INS_ADDR_INI 5835248

#define IFM_BYTES 224*224*64
#define WGT_BYTES 4186112
#define BIAS_BYTES 45104

#define LAYER_CNT 28
#define RELU_CODE 0
#define LEAKY_RELU_CODE 1
#define NO_RELU_CODE 2

#endif

#ifndef YOLOV3
#else

#define INS_FILE_PATH "yolov3/ins.bin"
#define IFM_FILE_PATH "yolov3/ifm.bin"
#define WGT_FILE_PATH "yolov3/weights.bin"
#define BIAS_FILE_PATH "yolov3/bias.bin"

#define FM_ADDR_INI 0
#define WGT_ADDR_INI 1638400
#define BIAS_ADDR_INI 5734400
#define INS_ADDR_INI 5835248

#define IFM_BYTES 416*416*64
#define WGT_BYTES 61897728
#define BIAS_BYTES 301640

#define LAYER_CNT 75
#define RELU_CODE 0
#define LEAKY_RELU_CODE 1
#define NO_RELU_CODE 2

#endif

#ifndef TINYYOLO
#else

#define INS_FILE_PATH "tinyyolo/ins.bin"
#define IFM_FILE_PATH "tinyyolo/ifm.bin"
#define WGT_FILE_PATH "tinyyolo/weights.bin"
#define BIAS_FILE_PATH "tinyyolo/bias.bin"

#define FM_ADDR_INI 819200
#define WGT_ADDR_INI 3276800
#define BIAS_ADDR_INI 6144000
#define INS_ADDR_INI 6154100

#define IFM_BYTES 416*416*64
#define WGT_BYTES 246336*64
#define BIAS_BYTES 51648

#define LAYER_CNT 9
#define RELU_CODE 1
#define LEAKY_RELU_CODE 0
#define NO_RELU_CODE 2

#endif
