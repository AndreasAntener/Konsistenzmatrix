# Konsistenzmatrix

Added for a friend, a script calculating every possible scenario (sum) in a Konsistenzmatrix. Parallel execution built-in, no algorithm optimization.

Requires Python, NumPy and Cython

## Run

1. Put data (csv) in file `konsimatrix.csv`.

2. Mofify `lib.pyx` and set correct number of factors and array with number of predictions per factor:

```
factors = 5
predictions = array('i', [3, 3, 4, 4, 4])
```

3. Compile and run:

```
python setup.py build_ext --inplace && ./test.py
```
