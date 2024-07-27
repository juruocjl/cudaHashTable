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
const int BUFSIZE = 1 << 14;
const int TABLESIZE = 100000007;
typedef std :: pair<uint64_t, data> pr;

__global__ void insert_kernel(pr *hashtable, const pr *buf, int n){
  LIMITED_KERNEL_LOOP(i, n) {
    uint64_t key = buf[i].first;
    data val = buf[i].second;
    size_t slot = fasthash64_d(key) % TABLESIZE;
    while(1) {
      uint64_t prev = atomicCAS((unsigned long long int*)&hashtable[slot].first, 0ull, (unsigned long long int)key);
      if (prev == 0 || prev == key) {
        hashtable[slot].second = val;
        break;
      }
      slot = (slot + 1) % TABLESIZE;
    }
  }
}


pr *a_d, *b_d;
pr *a_buf_h, *b_buf_h, *a_buf_d, *b_buf_d;
bool *ab_buf;

void init(){
  cudaSetDevice(0);
  CHECK(cudaMalloc(&a_d, sizeof(pr) * TABLESIZE));
  cudaSetDevice(1);
  CHECK(cudaMalloc(&b_d, sizeof(pr) * TABLESIZE));
  a_buf_h = (pr*) malloc(sizeof(pr) * BUFSIZE);
  b_buf_h = (pr*) malloc(sizeof(pr) * BUFSIZE);
  cudaSetDevice(0);
  CHECK(cudaMalloc(&a_buf_d, sizeof(pr) * BUFSIZE));
  cudaSetDevice(1);
  CHECK(cudaMalloc(&b_buf_d, sizeof(pr) * BUFSIZE));
  ab_buf = (bool*) malloc(sizeof(bool) * (BUFSIZE * 2));
}

void insert(Loader<uint64_t> &keys, Loader<data> &vals){
  
  int cnta = 0, cntb = 0;
  for(size_t i = 0; i < keys.count(); i++) {
    uint64_t v = keys.get();
    if (fasthash64(v) & 1) {
      a_buf_h[cnta++] = std :: make_pair(v, vals.get());
    } else {
      b_buf_h[cntb++] = std :: make_pair(v, vals.get());
    }
    if (cnta == BUFSIZE) {
      cudaSetDevice(0);
      CHECK(cudaMemcpy(a_buf_d, a_buf_h, sizeof(pr) * cnta, cudaMemcpyHostToDevice));
      insert_kernel<<<MultiProcessorCount, 1024>>>(a_d, a_buf_d, cnta);
      cnta = 0;
    }
    if (cntb == BUFSIZE) {
      cudaSetDevice(1);
      CHECK(cudaMemcpy(b_buf_d, b_buf_h, sizeof(pr) * cntb, cudaMemcpyHostToDevice));
      insert_kernel<<<MultiProcessorCount, 1024>>>(b_d, b_buf_d, cntb);
      cntb = 0;
    }
  }
  cudaSetDevice(0);
  CHECK(cudaMemcpy(a_buf_d, a_buf_h, sizeof(pr) * cnta, cudaMemcpyHostToDevice));
  insert_kernel<<<MultiProcessorCount, 1024>>>(a_d, a_buf_d, cnta);
  
  cudaSetDevice(1);
  CHECK(cudaMemcpy(b_buf_d, b_buf_h, sizeof(pr) * cntb, cudaMemcpyHostToDevice));
  insert_kernel<<<MultiProcessorCount, 1024>>>(b_d, b_buf_d, cntb);
  
}



__global__ void find_kernel(const pr *hashtable, pr *buf, int n){
  LIMITED_KERNEL_LOOP(i, n) {
    uint64_t key = buf[i].first;
    size_t slot = fasthash64_d(key) % TABLESIZE;
    while(1) {
      if (hashtable[slot].first == 0|| hashtable[slot].first == key) {
        buf[i].second = hashtable[slot].second;
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
      a_buf_h[cnta++].first = v;
      ab_buf[cnt++] = 0;
    } else {
      b_buf_h[cntb++].first = v;
      ab_buf[cnt++] = 1;
    }
    if (cnta == BUFSIZE || cntb == BUFSIZE ) {
      cudaSetDevice(0);
      CHECK(cudaMemcpy(a_buf_d, a_buf_h, sizeof(pr) * cnta, cudaMemcpyHostToDevice));
      find_kernel<<<MultiProcessorCount, 1024>>>(a_d, a_buf_d, cnta);
      cudaSetDevice(1);
      CHECK(cudaMemcpy(b_buf_d, b_buf_h, sizeof(pr) * cntb, cudaMemcpyHostToDevice));
      find_kernel<<<MultiProcessorCount, 1024>>>(b_d, b_buf_d, cntb);
      cudaSetDevice(0);
      CHECK(cudaMemcpy(a_buf_h, a_buf_d, sizeof(pr) * cnta, cudaMemcpyDeviceToHost));
      cudaSetDevice(1);
      CHECK(cudaMemcpy(b_buf_h, b_buf_d, sizeof(pr) * cntb, cudaMemcpyDeviceToHost));
      cnta = cntb = 0;
      for (int i = 0; i < cnt; i++) {
        if (ab_buf[i] == 0) {
          vals.put(a_buf_h[cnta++].second);
        }else{
          vals.put(b_buf_h[cntb++].second);
        }
      }
      cnta = cntb = cnt = 0;
    }
  }
  cudaSetDevice(0);
  CHECK(cudaMemcpy(a_buf_d, a_buf_h, sizeof(pr) * cnta, cudaMemcpyHostToDevice));
  find_kernel<<<MultiProcessorCount, 1024>>>(a_d, a_buf_d, cnta);
  cudaSetDevice(1);
  CHECK(cudaMemcpy(b_buf_d, b_buf_h, sizeof(pr) * cntb, cudaMemcpyHostToDevice));
  find_kernel<<<MultiProcessorCount, 1024>>>(b_d, b_buf_d, cntb);
  cudaSetDevice(0);
  CHECK(cudaMemcpy(a_buf_h, a_buf_d, sizeof(pr) * cnta, cudaMemcpyDeviceToHost));
  cudaSetDevice(1);
  CHECK(cudaMemcpy(b_buf_h, b_buf_d, sizeof(pr) * cntb, cudaMemcpyDeviceToHost));
  cnta = cntb = 0;
  for (int i = 0; i < cnt; i++) {
    if (ab_buf[i] == 0) {
      vals.put(a_buf_h[cnta++].second);
    }else{
      vals.put(b_buf_h[cntb++].second);
    }
  }
}


void clear(){
  free(a_buf_h);
  free(b_buf_h);
  free(ab_buf);
  CHECK(cudaFree(a_d));
  CHECK(cudaFree(b_d));
  CHECK(cudaFree(a_buf_d));
  CHECK(cudaFree(b_buf_d));
}