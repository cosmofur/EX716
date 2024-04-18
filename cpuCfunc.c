#include <Python.h>
#include <numpy/arrayobject.h>
#include <stdio.h>
#define NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION
//
// Compile with
//gcc -fPIC -shared -o cpuCfunc.so cpuCfunc.c -I /usr/include/python3.10/ -I/home/backs1/.local/lib/python3.10/site-packages/numpy/core/include -lpython3.10

void prtexample_arrays(PyObject* array1, PyObject* array2, int index1, int index2) {
  //    PyArrayObject* np_array1 = (PyArrayObject*)PyArray_FROM_OTF(array1, NPY_UINT8, NPY_ARRAY_INOUT_ARRAY);
  //    PyArrayObject* np_array2 = (PyArrayObject*)PyArray_FROM_OTF(array2, NPY_UINT8, NPY_ARRAY_INOUT_ARRAY);
  PyArrayObject* np_array1 = (PyArrayObject*)PyArray_FROM_O(array1);
  PyArrayObject* np_array2 = (PyArrayObject*)PyArray_FROM_O(array2);

    if (np_array1 == NULL || np_array2 == NULL) {
        PyErr_SetString(PyExc_TypeError, "Invalid input arrays");
        return;
    }

    // Perform the modification (add corresponding elements)

    
    uint8_t* data1 = (uint8_t*)PyArray_DATA(np_array1);
    uint8_t* data2 = (uint8_t*)PyArray_DATA(np_array2);

    // Ensure that the index is within the array bounds
    if (index1 >= 0 && index1 < PyArray_SIZE(np_array1) &&
        index2 >= 0 && index2 < PyArray_SIZE(np_array2)) {
      printf("Address: %04x is [%02x] - TOS is (%04x)\n", index1,data1[index1],data2[index2]);

        //        data1[index] += data2[index];
    } else {
        PyErr_SetString(PyExc_IndexError, "Index out of bounds");
    }
    

    // Clean up and return the modified arrays
    Py_XDECREF(np_array1);
    Py_XDECREF(np_array2);
}


static PyObject* c_prtexample_arrays(PyObject* self, PyObject* args) {
    PyObject* array1;
    PyObject* array2;
    int index1,index2;

    if (!PyArg_ParseTuple(args, "OOii", &array1, &array2, &index1, &index2, &index2)) {
        return NULL;
    }

    prtexample_arrays(array1, array2, index1, index2);

    // Return None (no need to return any value in this case)
    Py_RETURN_NONE;
}

static PyMethodDef cpuCfuncMethods[] = {
    {"prtexample_arrays", c_prtexample_arrays, METH_VARARGS, "Add corresponding elements of two NumPy arrays."},
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef cpuCfunc = {
    PyModuleDef_HEAD_INIT,
    "cpuCfunc",
    NULL,
    -1,
    cpuCfuncMethods
};

PyMODINIT_FUNC PyInit_cpuCfunc(void) {
    import_array();  // Initialize NumPy

    return PyModule_Create(&cpuCfunc);
}
