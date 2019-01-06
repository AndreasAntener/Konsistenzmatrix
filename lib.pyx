#!/usr/bin/env python
from __future__ import print_function
from cpython cimport array
from array import array
import time
from multiprocessing import Process
import csv
import numpy as np

def load_data():
    val = np.full(shape=(200,200), fill_value=0, dtype=np.int32)
    ifile = open("konsimatrix.csv", "rU")
    reader = csv.reader(ifile, delimiter=";")

    reader.next() # ignore header

    crow = 0
    for row in reader:
        cval = 0
        for value in row[1:]:
            if value is not None and value is not '':
                #print("%d,%d: %s" %(crow, cval, value))
                val[crow][cval] = int(value)
            cval += 1
        crow += 1

    ifile.close()
    return (val, crow)

# cdef void store_combination(f, int csum, int[:] combination, int factors):
#     cdef int x
#     for x in range(factors):
#         f.write("%d," % combination[x])
#     f.write(": %d\n" % csum)

def compute_chunk(py_pindex, py_factors, py_factor_index, py_predictions, py_chunk_count, py_data):
    # initialize
    cdef int factors = py_factors
    cdef int combination_sum = 0
    cdef long count = 0
    cdef long chunk_count = py_chunk_count
    cdef int[:] cpredictions = py_predictions
    cdef int[:] cfactor_index = py_factor_index
    cdef int x, y, posx, posy, single_val
    cdef int ignore = 0

    cdef const int[:,:] data = py_data

    f = open("workfile_%d" % py_pindex, 'w')
    buf = []

    cdef long start_time = time.time()

    # combine
    while True:
        # calculate combination sum
        # we're ignoring the first factor which is why we start on x (row) after cpredictions[0]
        posx = cpredictions[0]
        combination_sum = 0
        ignore = 0
        for x in range(1, factors):
            posy = 0
            # only iterate until x which ignores the last y (column)
            for y in range(x):
                single_val = data[posx + cfactor_index[x], posy + cfactor_index[y]]
                #print("single %d, %d, %d" %(single_val, posx + cfactor_index[x], posy + cfactor_index[y]))
                if single_val <= 1:
                    # ignore this combination
                    ignore = 1
                    break
                combination_sum += single_val
                posy += cpredictions[y]
            posx += cpredictions[x]

            if ignore == 1:
                break

        if ignore == 0:
            # write sum
            #store_combination(f, combination_sum, cfactor_index, factors)
            res = []
            for x in range(factors):
                res.append("%d," % cfactor_index[x])
            res.append(": %d\n" % combination_sum)
            buf.append(''.join(res))

        count += 1

        if count % 1e6 == 0:
            print(count)
            print(py_factor_index)
            print("estimated time until completion: %f hours" % (((time.time() - start_time) / (float(count) / float(chunk_count))) / 3600.0))
            write_time = time.time()
            f.writelines(buf)
            buf = []
            print("time to write buffer: %f" % (time.time() - write_time))

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

    f.close()
    print("done (%d): %d" % (py_pindex, count))
    print(py_factor_index)

def compute():
    # initialize
    #factors = 20
    #predictions = array('i', [3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4])
    factors = 5
    predictions = array('i', [3, 3, 4, 4, 4])

    factor_index = array('i')
    total_count = 1
    total_rows = 0
    chunk_size = 0

    if len(predictions) != factors:
        print("number of prediction counts not is equal number of factors")
        return

    for x in range(factors):
        factor_index.append(0)
        if x == factors - 1:
            chunk_size = total_count
        total_count = total_count * predictions[x]
        total_rows += predictions[x]

    print("total number of combinations: %d (chunk size: %d)" % (total_count, chunk_size))

    # load data and check for sanity
    data, num_rows = load_data()
    #print (data)

    if num_rows != total_rows:
        print("WARNING: number of loaded rows (%d) is not equal to total number of rows defined (%d)" % (num_rows, total_rows))
        #return

    # kick off multiple processes, each with its own data copy
    processes = []
    for x in range(predictions[factors - 1]):
        factor_index_copy = factor_index
        factor_index_copy[factors - 1] = int(x)
        p = Process(target=compute_chunk, args=(x, factors, factor_index_copy, predictions, chunk_size, data))
        p.start()
        processes.append(p)

    for x in range(predictions[factors - 1]):
        processes[x].join()
