#include <hip/hip_runtime.h>
#include "rocrand/rocrand.h"
#include "rocblas.h"

#include "dropout_layer.h"
#include "cuda.h"
#include "utils.h"

__global__ void yoloswag420blazeit360noscope(float *input, int size, float *rand, float prob, float scale)
{
    int id = (blockIdx.x + blockIdx.y*gridDim.x) * blockDim.x + threadIdx.x;
    if(id < size) input[id] = (rand[id] < prob) ? 0 : input[id]*scale;
}

void forward_dropout_layer_gpu(dropout_layer layer, network net)
{
    if (!net.train) return;
    int size = layer.inputs*layer.batch;
    hip_random(layer.rand_gpu, size);
    /*
    int i;
    for(i = 0; i < size; ++i){
        layer.rand[i] = rand_uniform();
    }
    hip_push_array(layer.rand_gpu, layer.rand, size);
    */

    hipLaunchKernelGGL((yoloswag420blazeit360noscope), dim3(hip_gridsize(size)), dim3(BLOCK), 0, 0, net.input_gpu, size, layer.rand_gpu, layer.probability, layer.scale);
    check_error(hipPeekAtLastError());
}

void backward_dropout_layer_gpu(dropout_layer layer, network net)
{
    if(!net.delta_gpu) return;
    int size = layer.inputs*layer.batch;

    hipLaunchKernelGGL((yoloswag420blazeit360noscope), dim3(hip_gridsize(size)), dim3(BLOCK), 0, 0, net.delta_gpu, size, layer.rand_gpu, layer.probability, layer.scale);
    check_error(hipPeekAtLastError());
}
