#include <chrono>   // for timing
#include <iostream> // std::cout, std::endl
#include <iterator> // std::ostream_iterator
#include <cstdlib> // EXIT_SUCCESS
#include <vector>

#ifndef NO_OPENBLAS
#include <cblas.h>
#endif

#include "gemm_experiment.h"
#include "GEMM.h"

using namespace csc485b::a4;

/** 
 * main
 * @brief Performs GEMM on GPU CUDA Cores and Tensor Cores.
 */
int main(int argc, char **argv)
{   
    bool print_result = false;

    if (argc > 1 && !strncmp(argv[1], "-p", 3)) print_result = true;

    constexpr int original_n = 8192;
    constexpr int multiple = 32;
    constexpr int max_element = 40;

    // Create a random device
    std::random_device rd;
    // Generate a random seed to ensure all experiments use the same random values
    unsigned int seed = rd();

    /*
    ****************************
    * CUDA Core GEMM Experiment
    ****************************
    */
    
    GemmExperiment<uint32_t, uint32_t> cudaCoreExp{original_n, max_element, multiple, seed, print_result};
    cudaCoreExp.run_experiment( 
        [&cudaCoreExp] (uint32_t* a, uint32_t* b, uint32_t* c) {
            uint32_t block_dim_sz = (uint32_t)(cudaCoreExp.get_n() / 32);
            const dim3 gridDim{block_dim_sz, block_dim_sz, block_dim_sz};
            const dim3 blockDim{32, 32, 1};
            cudacores::matrix_mult<<< gridDim, blockDim >>>(a, b, c, cudaCoreExp.get_n()); 
            }, "CUDA Core GEMM Implementation" );

    /*
    **********************************
    * Tensor Core FP32 GEMM Experiment
    **********************************
    */
    
    GemmExperiment<half, float> tensorCoreExpFp32{original_n, max_element, multiple, seed, print_result};
    tensorCoreExpFp32.run_experiment(
        [&tensorCoreExpFp32] (half* a, half* b, float* c) {
            const dim3 blockDim { 128, 4, 1 };
            dim3 gridDim;
            gridDim.x = (tensorCoreExpFp32.get_n() + (16 * blockDim.x / 32 - 1)) / (16 * blockDim.x / 32);
            gridDim.y = (tensorCoreExpFp32.get_n() + 16 * blockDim.y - 1) / (16 * blockDim.y);
            tensorcores::gemm<half, float><<< gridDim, blockDim >>>(a, b, c, tensorCoreExpFp32.get_n());
            }, "Tensor Core GEMM FP32 Implementation" );

    /*
    **********************************
    * Tensor Core FP32 (multi-stream) GEMM Experiment
    **********************************
    */
    std::size_t superblock_sz = 128;
    GemmExperiment<half, float> tensorCoreExpFp32Streams{original_n, max_element, multiple, seed, print_result, superblock_sz};
    std::size_t new_n = tensorCoreExpFp32Streams.get_n();
    tensorCoreExpFp32Streams.run_experiment_streams( 
        [&tensorCoreExpFp32Streams, new_n, superblock_sz] (half *a, half *b, float *c, cudaStream_t stream) {
            const dim3 blockDim { 128, 4, 1 };
            dim3 gridDim;
            gridDim.x = (new_n + (16 * blockDim.x / 32 - 1)) / (16 * blockDim.x / 32);
            gridDim.y = (superblock_sz + 16 * blockDim.y - 1) / (16 * blockDim.y);
            tensorcores::gemm<half, float><<< gridDim, blockDim, 0, stream >>>(a, b, c, new_n, superblock_sz); 
            }, "Tensor Core GEMM FP32 (two streams) Implementation" );
    
    /*
    **********************************
    * Tensor Core FP16 GEMM Experiment
    **********************************
    */

    GemmExperiment<half, half> tensorCoreExpFp16{original_n, max_element, multiple, seed, print_result};
    new_n = tensorCoreExpFp16.get_n();
    tensorCoreExpFp16.run_experiment( 
        [&tensorCoreExpFp16, new_n] (half* a, half* b, half* c) {
            const dim3 blockDim { 128, 4, 1 };
            dim3 gridDim;
            gridDim.x = (new_n + (16 * blockDim.x / 32 - 1)) / (16 * blockDim.x / 32);
            gridDim.y = (new_n + 16 * blockDim.y - 1) / (16 * blockDim.y);
            tensorcores::gemm<half, half><<< gridDim, blockDim >>>(a, b, c, new_n); 
            }, "Tensor Core GEMM FP16 Implementation" );


    /*
    **********************************
    * Tensor Core FP16 (multi-stream) GEMM Experiment
    **********************************
    */

    superblock_sz = 128;
    GemmExperiment<half, half> tensorCoreExpFp16Streams{original_n, max_element, multiple, seed, print_result, superblock_sz};
    new_n = tensorCoreExpFp16Streams.get_n();
    tensorCoreExpFp16Streams.run_experiment_streams( 
        [&tensorCoreExpFp16Streams, new_n, superblock_sz] (half *a, half *b, half *c, cudaStream_t stream) {
            const dim3 blockDim { 128, 4, 1 };
            dim3 gridDim;
            gridDim.x = (new_n + (16 * blockDim.x / 32 - 1)) / (16 * blockDim.x / 32);
            gridDim.y = (superblock_sz + 16 * blockDim.y - 1) / (16 * blockDim.y);
            tensorcores::gemm<half, half><<< gridDim, blockDim, 0, stream >>>(a, b, c, new_n, superblock_sz); 
            }, "Tensor Core GEMM FP16 (two streams) Implementation" );

    /*
    **********************************
    * Tensor Core INT8 GEMM Experiment
    **********************************
    */

    GemmExperiment<unsigned char, int> tensorCoreExpInt8{original_n, max_element, multiple, seed, print_result};
    tensorCoreExpInt8.run_experiment(
        [&tensorCoreExpInt8] (unsigned char *a, unsigned char *b, int *c) {
            const dim3 blockDim { 128, 4, 1 };
            dim3 gridDim;
            gridDim.x = (tensorCoreExpInt8.get_n() + (16 * blockDim.x / 32 - 1)) / (16 * blockDim.x / 32);
            gridDim.y = (tensorCoreExpInt8.get_n() + 16 * blockDim.y - 1) / (16 * blockDim.y);
            tensorcores::gemm<unsigned char, int><<< gridDim, blockDim >>>(a, b, c, tensorCoreExpInt8.get_n());
            }, "Tensor Core GEMM INT8 Implementation" );

    return EXIT_SUCCESS;
}
