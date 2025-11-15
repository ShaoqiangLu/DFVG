#include "utils.h"

#include <vector>
#include <fstream>
#include <cmath>
#include <string>

#include "cnpy.h"

// only for checking purpose, input npy should already have been quantized
std::vector<float> ReadNpyAndSaturate(std::string filename, int frac_len, int bit_width) {
	// Check if file exists
	std::ifstream f(filename.c_str());
	if (!f.good()) { // file does not exist
		throw std::runtime_error("Filename does not exist: " + filename);
	}
	f.close();

	// Read npy array from file
	cnpy::NpyArray arr = cnpy::npy_load(filename);
	std::vector<float> data = arr.as_vec<float>(); 

	// Saturate
	float sat_max = pow(2, bit_width - 1) - 1;
	float sat_min = pow(-2, bit_width - 1);
	for (int i = 0; i < data.size(); i++) { // Saturate each element
		float val = data[i];
		val = val * pow(2, frac_len);
		val = std::min(sat_max, std::max(sat_min, val));
		val = val / pow(2, frac_len);
		data[i] = val;
	}

	return data;
}
