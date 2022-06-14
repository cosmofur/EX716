# This is for cython speed up

from setuptools import setup
from Cython.Build import cythonize 
setup(
           ext_modules=cythonize("cpu.py",language_level=3),
           )
