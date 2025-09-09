#include "accelerator.h"
#include "bit_util.h"
#include <gtest/gtest.h>
#include <cmath>
#include <assert.h>

#define PRECISION 8
using acc_type = int;
using input_type = int8_t;
using output_type = int16_t;

/*
 * Golden case of vector inner-product between ifm, wgt_a, wgt_b
 *
 * Example: 
 *
 * intput : 
 *   ifm = [x1, x2, x3, x4], wgt_a = [a1, a2, a3, a4], wgt_b = [b1, b2, b3, b4]
 * return : 
 *   res = [x1*a1, x1*b1, x2*a2, x2*b2, x3*a3, x3*b3, x4*a4, x4*b4]
 */
std::vector<acc_type> inner_product(std::vector<acc_type> ifm, std::vector<acc_type> wgt_a, std::vector<acc_type> wgt_b)
{
    int wgt_a_size = wgt_a.size();
    int wgt_b_size = wgt_b.size();
    int ifm_size = ifm.size();
    assert(wgt_a_size == wgt_b_size);
    assert(ifm_size == wgt_b_size);

    std::vector<acc_type> res;
    for (int i = 0; i < ifm_size; ++i)
    {
        res.push_back(ifm[i] * wgt_a[i]);
        if (PRECISION == 8)
            res.push_back(ifm[i] * wgt_b[i]);
    }
    return res;
}

/*
 * Golden case of elementwise vector addition between adder_a, adder_b
 */
std::vector<acc_type> accumulate(std::vector<acc_type> adder_a, std::vector<acc_type> adder_b)
{
    if (adder_a.size() != adder_b.size())
    {
        adder_a.insert(adder_a.begin(), adder_b.size() - adder_a.size(), 0);
    }
    assert(adder_a.size() == adder_b.size());

    std::vector<acc_type> res;
    for (auto it1 = adder_a.begin(), it2 = adder_b.begin(); it1 != adder_a.end(), it2 != adder_b.end(); ++it1, ++it2)
    {
        acc_type sum = *it1 + *it2;
        res.push_back(sum);
    }
    return res;
}

/*
 * Test of inner-product(ifm, wgt) + bias, where ifm, wgt, bias are vectors
 */
TEST(IPATEST, Forward_Accumulate)
{
    const int pe_num = 32;
    using IPA_t = IPA<1, pe_num, PRECISION>;

    IPA_t ipa_;

    int pe_bytes = sizeof(IPA_t::PE_buf_t::DType); // 32 (* 8b)

    int length = pe_bytes / (PRECISION / 8); // input vector length = 32

    // Initialize input vector fm and copy to IPA input fm_buf_
    input_type *fm = new input_type[length];
    for (int i = 0; i < length; ++i)
    {
        fm[i] = input_type(i);
    }
    ipa_.fm_buf_.Load<pe_num * PRECISION>(MemOp(0, 1, 0), fm);
    delete[] fm;

    // Initialize input vectors wgt_a, wgt_b and copy to IPA inputs wgt_buf_a_, wgt_buf_b_ which share another input fm_buf_ as the common operand of inner-product
    input_type *wgt_a = new input_type[length];
    input_type *wgt_b = new input_type[length];
    for (int i = 0; i < length; ++i)
    {
        wgt_a[i] = 1;
        wgt_b[i] = 0;
    }
    ipa_.wgt_buf_a_.Load<pe_num * PRECISION>(MemOp(0, 1, 0), wgt_a);
    ipa_.wgt_buf_b_.Load<pe_num * PRECISION>(MemOp(0, 1, 0), wgt_b);
    delete[] wgt_a;
    delete[] wgt_b;

    /* 
     * Part 1 : inner-product
     */
    // Run IPA to compute inner-product between its inputs: fm_buf, wgt_buf_a, wgt_buf_b
    ipa_.Forward(pe_num * 2);

    ASSERT_EQ(pe_num * 2, ipa_.GetOutputNum());

    // Get inner_product golden case for comparison
    std::vector<acc_type> ifm = ipa_.fm_buf_.AsVec(0, pe_num, PRECISION);
    std::vector<acc_type> wt_a = ipa_.wgt_buf_a_.AsVec(0, pe_num, PRECISION);
    std::vector<acc_type> wt_b = ipa_.wgt_buf_b_.AsVec(0, pe_num, PRECISION);
    std::vector<acc_type> ip_res = inner_product(ifm, wt_a, wt_b);
    std::vector<acc_type> psum_ = ipa_.psum;

    // Compare algorithmic output and IPA (i.e. hardware) output
    for (int i = 0; i < ip_res.size(); ++i)
        ASSERT_EQ(ipa_.psum[i], ip_res[i]);

    /*
     * Part 2: accumulate inner-product results with bias
     */
    // SRAM<#bit per element, #element per bank, #bank> is on-chip buffer
    using Tmp_buf_t = SRAM<32 * pe_num * 2, 1, 1>;
    Tmp_buf_t tmp_buf_;
    std::ofstream os;

    // Convert psum to big endian
    convertToBigEndian<acc_type, PRECISION, pe_num * 2>(ipa_.psum);

    // Initialize bias vector adder and copy to IPA input adder_buf_b_
    output_type *adder = new output_type[pe_num * 2];
    for (int i = 0; i < pe_num * 2; ++i)
    {
        adder[i] = i;
    }

    ipa_.adder_buf_b_.Load<pe_num * 2 * PRECISION * 2>(MemOp(0, 1, 0), adder);
    std::vector<acc_type> bias = ipa_.adder_buf_b_.AsVec(0, pe_num * 2, PRECISION * 2);
    for (auto value : bias)
    {
        ipa_.adder_b.push_back(value << 10);
    }

    // Add the output of ipa_.psum and adder_b and copy to partial sum buffer tmp_buf_
    ipa_.Accumulate(10, pe_num, 0, tmp_buf_.BeginPtr(0), os, false);

    // Get accumulate golden case for comparison
    std::vector<acc_type> add_bias;
    for (int i = 0; i < pe_num * 2; ++i)
    {
        add_bias.push_back(adder[i]);
    }
    std::vector<acc_type> acc_res = accumulate(psum_, add_bias);

    // Fetch IPA output from the partial sum buffer for algorithmic comparison
    output_type *tmp = reinterpret_cast<output_type *>(tmp_buf_.BeginPtr(0));
    for (int i = 0; i < acc_res.size(); ++i)
        ASSERT_EQ(tmp[i], acc_res[i]);
}

int main(int argc, char **argv)
{
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
