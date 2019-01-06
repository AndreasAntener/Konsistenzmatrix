#!/usr/bin/env python
from __future__ import print_function
from cpython cimport array
from array import array
import time
from multiprocessing import Process

cdef int get_consistency(int x, int y):
    return 1

cdef void store_combination(int csum, int[:] combination):
    pass

def compute_chunk(py_factors, py_factor_index, py_predictions, py_chunk_count):
    # initialize
    cdef int factors = py_factors
    cdef int combination_sum = 0
    cdef long count = 0
    cdef long chunk_count = py_chunk_count
    cdef int[:] cpredictions = py_predictions
    cdef int[:] cfactor_index = py_factor_index
    cdef int x, y
    cdef long start_time = time.time()

    # combine
    while True:
        # calculate combination sum
        for x in range(1, factors):
            # run through matrix, note that we start at 1 on x because 0,0 is on the diagonal
            for y in range(x + 1):
                combination_sum += get_consistency(cfactor_index[x], cfactor_index[y])

        count += 1
        store_combination(combination_sum, cfactor_index)

        if count % 1e7 == 0:
            print(count)
            print(py_factor_index)
            print("estimated time until completion: %f hours" % (((time.time() - start_time) / (float(count) / float(chunk_count))) / 3600.0))

        # advance indicies
        overflow = False
        for x in range(factors):
            overflow = False
            cfactor_index[x] += 1

            if cfactor_index[x] == cpredictions[x]:
                cfactor_index[x] = 0
                overflow = True

            if overflow is False:
                break

        if overflow is True or count >= chunk_count:
            # we're done
            break;

    print(count)
    print(py_factor_index)
    print("done")

def compute():
    # initialize
    factors = 20
    cdef predictions = array('i', [3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4])
    cdef factor_index = array('i', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    total_count = 1
    chunk_size = 0

    if len(predictions) != factors or len(factor_index) != factors:
        print("number of prediction counts not is equal number of factors")
        return

    for x in range(factors):
        #factor_index.append(0)
        if x == factors - 1:
            chunk_size = total_count
        total_count = total_count * predictions[x]

    print("total number of combinations: %d (chunk size: %d)" % (total_count, chunk_size))

    processes = []
    for x in range(predictions[factors - 1]):
        factor_index_copy = array('i', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, int(x)])
        p = Process(target=compute_chunk, args=(factors, factor_index_copy, predictions, chunk_size))
        p.start()
        processes.append(p)

    for x in range(predictions[factors - 1]):
        processes[x].join()
