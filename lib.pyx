#!/usr/bin/env python
from __future__ import print_function
from cpython cimport array
from array import array
import time

cdef int get_consistency(int x, int y):
    return 1

cdef void store_combination(int csum, int[:] combination):
    pass

def compute():
    # initialize
    cdef int factors = 20
    cdef int combination_sum = 0
    cdef long count = 0
    cdef long start_time = 0
    cdef predictions = array('i', [3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4])
    cdef int[:] cpredictions = predictions
    cdef factor_index = array('i', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    cdef int[:] cfactor_index = factor_index
    cdef long total_count = 1
    cdef int x, y

    if len(predictions) != factors or len(factor_index) != factors:
        print("number of prediction counts not is equal number of factors")
        return

    #cdef factor_index = array('i')
    #cdef int cfactor_index[20]

    for x in range(factors):
        #factor_index.append(0)
        total_count = total_count * cpredictions[x]

    print("total number of combinations: %d" % total_count)

    start_time = time.time()

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
            print(factor_index)
            print("estimated time until completion: %f hours" % (((time.time() - start_time) / (float(count) / float(total_count))) / 3600.0))

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

        if overflow is True:
            # we're done
            break;

    print(count)
    print(factor_index)
    print("done")
