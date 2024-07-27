#ifndef DINNER123_H
#define DINNER123_H

#include <bits/stdc++.h>

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

class Timer{
  private:
  std::chrono::system_clock::time_point start,end;
  public:
  Timer() {
    start = std::chrono::system_clock::now();
  }
  void reset() {
    start = std::chrono::system_clock::now();
  }
  float elapsed() {
    end = std::chrono::system_clock::now();
    return std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
  }
};

class CTimer{
  private:
  Timer t;
  float tot;
  bool running;
  public:
  CTimer(): tot(0), running(false), t() {} 
  void start() {
    if (!running) {
      t.reset();
      running = 1;
    }
  }
  void stop() {
    if (running) {
      tot += t.elapsed();
      running = 0;
    }
  }
  void reset(){
    tot = 0, running = false;
  }
  float elapsed(){
    stop();
    return tot;
  }
};

#define LIMITED_KERNEL_LOOP(i, n) \
  for (int i = blockIdx.x * blockDim.x + threadIdx.x; i < n; i += blockDim.x * gridDim.x)
#define LIMITED_BLOCK_LOOP(i, n) \
  for (int i = threadIdx.x; i < n; i += blockDim.x)


#endif