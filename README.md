
# DFVG: A Heterogeneous Architecture for Speculative Decoding with Draft-on-FPGA and Verify-on-GPU

**DFVG (Draft-on-FPGA, Verify-on-GPU)** is a heterogeneous computing architecture designed for **speculative decoding** in large language models.  
The key idea is to perform the **draft generation** stage on FPGAs for fast parallel candidate generation, and the **verification** stage on GPUs for efficient matrix computation. This design fully leverages the complementary strengths of both hardware platforms to achieve **low latency and high throughput** decoding.

---

## 📷 Architecture

![DFVG Architecture](v80_fpga.jpg)
![DFVG RunTime](ChatOPU_gif.gif)
---

## ✨ Features

- **FPGA Draft Generation**: Fast candidate sequence generation with parallel computation  
- **GPU Verification**: Efficient verification leveraging GPU’s strong matrix operations  
- **Heterogeneous Collaboration**: Exploits FPGA and GPU complementarity to reduce latency and energy cost  
- **Modular Design**: Flexible deployment and easy extension across hardware platforms  

---




## 📂 Project Structure
DFVG/
├── fpga/ # Verilog HDL implementation & bitstream build
├── gpu/ # CUDA kernels & verification pipeline
├── runtime/ # Cross-device system controller
├── configs/ # Model and hardware configuration files
├── scripts/ # Experiment automation & utilities
├── datasets/ # Benchmark datasets (downloaded separately)
└── README.md
---

## 🚀 Getting Started

1. Clone the repository
```bash
git clone https://anonymous.4open.science/r/DFVG-DE39
cd DFVG

sudo apt update
sudo apt install build-essential cmake
pip install -r requirements.txt

open README.md

make build
./run_dfvg
source /opt/xilinx/xrt/setup.sh
export XILINX_VIVADO=/opt/Xilinx/Vivado/2024.1

cd fpga/
make synthesize
make implement
python scripts/run_experiments.py --config configs/llama7b.yaml
python scripts/collect_results.py --output results/

Guan Maochuang, DFVG: A Heterogeneous Architecture for Speculative Decoding with Draft-on-FPGA and Verify-on-GPU, 2025.

