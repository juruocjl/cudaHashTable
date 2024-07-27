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
  Loader<T> a;
  size_t tot, ok;
  bool flag;
  public:
  Checker(const char *file, CTimer *_, int buffer_size = 1 << 18) : a(file, _, buffer_size = buffer_size), flag(1), tot(0), ok(0) {}
  ~Checker(void) {}
  void put(T x) {
    tot++;
    ok += (x == a.get());
  }
  double acc() {
    assert(tot == a.count());
    return 1. * ok / tot;
  }
};
#endif