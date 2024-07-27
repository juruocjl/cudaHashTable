add_executable(main test_speed.cu)
add_executable(gen gen.cpp)
target_link_libraries(gen ${CUDA_curand_LIBRARY})