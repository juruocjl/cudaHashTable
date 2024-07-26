#ifndef DATA_CHECKER_H
#define DATA_CHECKER_H

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <cassert>
#include "data_loader.h"

template<class T>
class Checker{
  private:
  data_loader a;
  public:
  Writer(const char *file, int buffer_size = 1 << 18) : a(file, buffer_size){}
  ~Writer(void) {}
  void put(T x) {
    if (p1 == p2) {
        reflush();
    }
    *p1 = x;
    p1++;
  }
};
#endif