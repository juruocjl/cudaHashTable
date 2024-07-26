#ifndef HASH_TABLE_H
#define HASH_TABLE_H

#include "data_loader.h"
#include "data_checker.h"

const size_t dim = 64;

size_t size();
size_t capacity();
void insert(Loader<uint64_t> &, Loader<float> &);
void find(Loader<uint64_t> &, Checker<float> &);

#endif