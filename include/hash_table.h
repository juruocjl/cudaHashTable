#include "data_loader.h"
#include "data_writer.h"

size_t size();
size_t capacity();
void insert(data_loader keys, data_loader vals);
void find(data_loader keys, data_writer vals);