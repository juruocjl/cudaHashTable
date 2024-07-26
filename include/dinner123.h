#ifndef DINNER123_H
#define DINNER123_H

#include <cstdio>
#include <cuda_runtime.h>
#include <chrono>

#define CHECK(call)\
{\
  const cudaError_t error=call;\
  if(error!=cudaSuccess)\
  {\
      printf("ERROR: %s:%d,",__FILE__,__LINE__);\
      printf("code:%d,reason:%s\n",error,cudaGetErrorString(error));\
      exit(1);\
  }\
}
#define CUBLAS_CHECK(call)\
{\
  const cublasStatus_t  error=call;\
  if(error!=CUBLAS_STATUS_SUCCESS)\
  {\
      printf("ERROR: %s:%d,",__FILE__,__LINE__);\
      exit(1);\
  }\
}

namespace dinner123{
  float last_time;
  bool out_time = 1;
}

#define PrintTime() {\
dinner123::last_time = t.elapsed();\
if(dinner123 :: out_time)printf("%s use %lf ms\n", __func__, dinner123::last_time);\
}


#define RUN(X, ...) {\
double sum = 0;\
for(int i = 0; i < RUN_TIMES; i++){cudaTimer t; X(__VA_ARGS__); sum += t.elapsed();}\
if(RUN_TIMES > 1) printf("%s avg use %.5lf ms in %d tests\n", #X, sum / RUN_TIMES, RUN_TIMES);\
else printf("%s use %.5lf ms\n", #X, sum / RUN_TIMES);\
}

#define RUN_kernel(X, grid, block, ...) {\
double sum = 0;\
for(int i = 0; i < RUN_TIMES; i++){cudaTimer t; X<<<grid,block>>>(__VA_ARGS__); sum += t.elapsed();}\
if(RUN_TIMES > 1) printf("%s avg use %.5lf ms in %d tests\n", #X, sum / RUN_TIMES, RUN_TIMES);\
else printf("%s use %.5lf ms\n", #X, sum / RUN_TIMES);\
}

#define RUN_kernel_clear(X, grid, block, clear, ...) {\
double sum = 0;\
for(int i = 0; i < RUN_TIMES; i++){clear; cudaTimer t; X<<<grid,block>>>(__VA_ARGS__); sum += t.elapsed();}\
if(RUN_TIMES > 1) printf("%s avg use %.5lf ms in %d tests\n", #X, sum / RUN_TIMES, RUN_TIMES);\
else printf("%s use %.5lf ms\n", #X, sum / RUN_TIMES);\
}

class cudaTimer
{
public:
    cudaTimer() {
        // Allocate CUDA events that we'll use for timing
        CHECK(cudaEventCreate(&start));
        CHECK(cudaEventCreate(&stop));
        CHECK(cudaEventRecord(start, NULL));
      }
    void reset() {CHECK(cudaEventRecord(start, NULL)); }
    //默认输出毫秒
    float elapsed() const
    {
        CHECK(cudaEventRecord(stop, NULL));
        CHECK(cudaEventSynchronize(stop));
        float milliseconds = 0;
        CHECK(cudaEventElapsedTime(&milliseconds, start, stop));
        return milliseconds;
    }
private:
    cudaEvent_t start, stop;
};

const int multiProcessorCount = [](){
  cudaSetDevice(0);
  cudaDeviceProp deviceProp;
  cudaGetDeviceProperties(&deviceProp, 0);
  return deviceProp.multiProcessorCount;
}();


#define LIMITED_KERNEL_LOOP(i, n) \
  for (int i = blockIdx.x * blockDim.x + threadIdx.x; i < n; i += blockDim.x * gridDim.x)
#define LIMITED_BLOCK_LOOP(i, n) \
  for (int i = threadIdx.x; i < n; i += blockDim.x)
#include <cooperative_groups.h>
namespace cg = cooperative_groups;
#endif