#include "dinner123.h"
#include "hash_table.h"
#include <bits/stdc++.h>
#include <cuda_runtime.h>
#include <map>
size_t size(){
  return 0;
}
size_t capacity(){
  return 0;
}
const int MultiProcessorCount = 80;
#define mix(h) ({					\
			(h) ^= (h) >> 23;		\
			(h) *= 0x2127599bf4325c37ULL;	\
			(h) ^= (h) >> 47; })


uint64_t fasthash64(uint64_t v) {
	const uint64_t m = 0x880355f21e6d1965ULL;
	uint64_t h = 1919810;
	h ^= mix(v);
	h *= m;
	return mix(h);
}

__device__ uint64_t fasthash64_d(uint64_t v) {
	const uint64_t m = 0x880355f21e6d1965ULL;
	uint64_t h = 114514;
	h ^= mix(v);
	h *= m;
	return mix(h);
}
const int BUFSIZE = 1 << 20;
const int TABLESIZE = 100000007;
typedef std :: pair<uint64_t, data> pr;

__global__ void insert_kernel(uint64_t *hashtable, uint64_t *buf, int n){
  LIMITED_KERNEL_LOOP(i, n) {
    uint64_t key = buf[i];
    size_t slot = fasthash64_d(key) % TABLESIZE;
    while(1) {
      uint64_t prev = atomicCAS((unsigned long long int*)&hashtable[slot], 0ull, (unsigned long long int)key);
      if (prev == 0 || prev == key){
        buf[i] = slot;
        break;
      }
      slot = (slot + 1) % TABLESIZE;
    }
  }
}


uint64_t *a_d, *b_d;
uint64_t *a_buf_h, *b_buf_h, *a_buf_d, *b_buf_d;
bool *ab_buf;
data *table_h;
void init(){
  cudaSetDevice(0);
  CHECK(cudaMalloc(&a_d, sizeof(uint64_t) * TABLESIZE));
  cudaSetDevice(1);
  CHECK(cudaMalloc(&b_d, sizeof(uint64_t) * TABLESIZE));
  a_buf_h = (uint64_t*) malloc(sizeof(uint64_t) * BUFSIZE);
  b_buf_h = (uint64_t*) malloc(sizeof(uint64_t) * BUFSIZE);
  cudaSetDevice(0);
  CHECK(cudaMalloc(&a_buf_d, sizeof(uint64_t) * BUFSIZE));
  cudaSetDevice(1);
  CHECK(cudaMalloc(&b_buf_d, sizeof(uint64_t) * BUFSIZE));
  ab_buf = (bool*) malloc(sizeof(bool) * (BUFSIZE * 2));
  table_h = (data*) malloc(sizeof(data) * TABLESIZE * 2);
}

void insert(Loader<uint64_t> &keys, Loader<data> &vals){
  int cnt = 0, cnta = 0, cntb = 0;
  for(size_t i = 0; i < keys.count(); i++) {
    uint64_t v = keys.get();
    if (fasthash64(v) & 1) {
      a_buf_h[cnta++] = v;
      ab_buf[cnt++] = 0;
    } else {
      b_buf_h[cntb++] = v;
      ab_buf[cnt++] = 1;
    }
    if (cnta == BUFSIZE || cntb == BUFSIZE) {
      cudaSetDevice(0);
      CHECK(cudaMemcpy(a_buf_d, a_buf_h, sizeof(uint64_t) * cnta, cudaMemcpyHostToDevice));
      insert_kernel<<<MultiProcessorCount, 1024>>>(a_d, a_buf_d, cnta);
      cudaSetDevice(1);
      CHECK(cudaMemcpy(b_buf_d, b_buf_h, sizeof(uint64_t) * cntb, cudaMemcpyHostToDevice));
      insert_kernel<<<MultiProcessorCount, 1024>>>(b_d, b_buf_d, cntb);
      cudaSetDevice(0);
      CHECK(cudaMemcpy(a_buf_h, a_buf_d, sizeof(uint64_t) * cnta, cudaMemcpyDeviceToHost));
      cudaSetDevice(1);
      CHECK(cudaMemcpy(b_buf_h, b_buf_d, sizeof(uint64_t) * cntb, cudaMemcpyDeviceToHost));
      cnta = cntb = 0;
      for (int i = 0; i < cnt; i++) {
        if (ab_buf[i] == 0) {
          table_h[a_buf_h[cnta++]] = vals.get();
        } else {
          table_h[b_buf_h[cntb++] + TABLESIZE] = vals.get();
        }
      }
      cnt = cnta = cntb = 0;
    }
    
  }
  printf("qwq");
  cudaSetDevice(0);
  CHECK(cudaMemcpy(a_buf_d, a_buf_h, sizeof(uint64_t) * cnta, cudaMemcpyHostToDevice));
  insert_kernel<<<MultiProcessorCount, 1024>>>(a_d, a_buf_d, cnta);
  cudaSetDevice(1);
  CHECK(cudaMemcpy(b_buf_d, b_buf_h, sizeof(uint64_t) * cntb, cudaMemcpyHostToDevice));
  insert_kernel<<<MultiProcessorCount, 1024>>>(b_d, b_buf_d, cntb);
  cudaSetDevice(0);
  CHECK(cudaMemcpy(a_buf_h, a_buf_d, sizeof(uint64_t) * cnta, cudaMemcpyDeviceToHost));
  cudaSetDevice(1);
  CHECK(cudaMemcpy(b_buf_h, b_buf_d, sizeof(uint64_t) * cnta, cudaMemcpyDeviceToHost));
  cnta = cntb = 0;
  for (int i = 0; i < cnt; i++) {
    if (ab_buf[i] == 0) {
      table_h[a_buf_h[cnta++]] = vals.get();
    } else {
      table_h[b_buf_h[cntb++] + TABLESIZE] = vals.get();
    }
  }
  cnt = cnta = cntb = 0;
}



__global__ void find_kernel(const uint64_t *hashtable, uint64_t *buf, int n){
  LIMITED_KERNEL_LOOP(i, n) {
    uint64_t key = buf[i];
    size_t slot = fasthash64_d(key) % TABLESIZE;
    while(1) {
      if (hashtable[slot] == 0|| hashtable[slot] == key) {
        buf[i] = slot;
        break;
      }
      slot = (slot + 1) % TABLESIZE;
    }
  }
}
void find(Loader<uint64_t> &keys, Checker<data> &vals){
  int cnta = 0, cntb = 0, cnt = 0;
  for (size_t i = 0; i < keys.count(); i++) {
    uint64_t v = keys.get();
    if (fasthash64(v) & 1) {
      a_buf_h[cnta++] = v;
      ab_buf[cnt++] = 0;
    } else {
      b_buf_h[cntb++] = v;
      ab_buf[cnt++] = 1;
    }
    if (cnta == BUFSIZE || cntb == BUFSIZE ) {
      cudaSetDevice(0);
      CHECK(cudaMemcpy(a_buf_d, a_buf_h, sizeof(uint64_t) * cnta, cudaMemcpyHostToDevice));
      find_kernel<<<MultiProcessorCount, 1024>>>(a_d, a_buf_d, cnta);
      cudaSetDevice(1);
      CHECK(cudaMemcpy(b_buf_d, b_buf_h, sizeof(uint64_t) * cntb, cudaMemcpyHostToDevice));
      find_kernel<<<MultiProcessorCount, 1024>>>(b_d, b_buf_d, cntb);
      cudaSetDevice(0);
      CHECK(cudaMemcpy(a_buf_h, a_buf_d, sizeof(uint64_t) * cnta, cudaMemcpyDeviceToHost));
      cudaSetDevice(1);
      CHECK(cudaMemcpy(b_buf_h, b_buf_d, sizeof(uint64_t) * cntb, cudaMemcpyDeviceToHost));
      cnta = cntb = 0;
      for (int i = 0; i < cnt; i++) {
        if (ab_buf[i] == 0) {
          vals.put(table_h[a_buf_h[cnta++]]);
        }else{
          vals.put(table_h[b_buf_h[cntb++] + TABLESIZE]);
        }
      }
      cnta = cntb = cnt = 0;
    }
  }
  cudaSetDevice(0);
  CHECK(cudaMemcpy(a_buf_d, a_buf_h, sizeof(uint64_t) * cnta, cudaMemcpyHostToDevice));
  find_kernel<<<MultiProcessorCount, 1024>>>(a_d, a_buf_d, cnta);
  cudaSetDevice(1);
  CHECK(cudaMemcpy(b_buf_d, b_buf_h, sizeof(uint64_t) * cntb, cudaMemcpyHostToDevice));
  find_kernel<<<MultiProcessorCount, 1024>>>(b_d, b_buf_d, cntb);
  cudaSetDevice(0);
  CHECK(cudaMemcpy(a_buf_h, a_buf_d, sizeof(uint64_t) * cnta, cudaMemcpyDeviceToHost));
  cudaSetDevice(1);
  CHECK(cudaMemcpy(b_buf_h, b_buf_d, sizeof(uint64_t) * cntb, cudaMemcpyDeviceToHost));
  cnta = cntb = 0;
  for (int i = 0; i < cnt; i++) {
    if (ab_buf[i] == 0) {
      vals.put(table_h[a_buf_h[cnta++]]);
    }else{
      vals.put(table_h[b_buf_h[cntb++] + TABLESIZE]);
    }
  }
}


void clear(){
  free(a_buf_h);
  free(b_buf_h);
  free(ab_buf);
  free(table_h);
  CHECK(cudaFree(a_d));
  CHECK(cudaFree(b_d));
  CHECK(cudaFree(a_buf_d));
  CHECK(cudaFree(b_buf_d));
}