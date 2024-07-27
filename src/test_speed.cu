#include "reader.h"
#include "v5.cuh"
#include <bits/stdc++.h>
#include "dinner123.h"
#include <cuda_runtime.h>
using namespace std;
HashTable<uint64_t, float, 64> gpuhstb;

template <typename T>
double GPU_PERF(T func) {
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start);
	func();
	cudaEventRecord(stop);
	CHECK(cudaStreamSynchronize(0));
	float duration = 0;
	cudaEventElapsedTime(&duration, start, stop);
	return duration / 1000;
}
int main() {
	file_loader<uint64_t> insertion("/root/cudaHashTable/data/akdream1/A/part0.keys");
	file_loader<uint64_t> finding("/root/cudaHashTable/data/akdream1/A/part0.keys");
	//data_loader insertion("/root/cudaHashTable/data/sample/A/part_0");
	//file_loader<uint64_t> finding("/root/cudaHashTable/data/sample/A/part_0.keys");
	cerr << "load use " << 1. * clock() / CLOCKS_PER_SEC << endl;
	int n = insertion.count();
	cerr << "n = " << n << endl;
	uint64_t *answer_gpu;// = (uint64_t *)malloc(finding.count() * sizeof(uint64_t));
	CHECK(cudaHostAlloc(&answer_gpu, finding.count() * sizeof(uint64_t), cudaHostAllocMapped));
	bool  *exist_gpu;// = (bool *)malloc(finding.count() * sizeof(uint64_t));
	CHECK(cudaHostAlloc(&exist_gpu, finding.count() * sizeof(bool), cudaHostAllocMapped));

	double gpu_insert_time = GPU_PERF([&] { gpuhstb.insert(n, insertion.data(), 114514); });
	double gpu_insert_qps = n / gpu_insert_time;
	cerr << "insert_time=" << gpu_insert_time << endl;
	cerr << "insert_qps=" << gpu_insert_qps << endl;
	double gpu_find_time = GPU_PERF([&] { gpuhstb.find(n, finding.data(), answer_gpu, exist_gpu); });
	double gpu_find_qps = n / gpu_find_time;
	cerr << "find_time=" << gpu_find_time << endl;
	cerr << "find_qps=" << gpu_find_qps << endl;
	return 0;
}