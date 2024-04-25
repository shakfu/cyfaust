from distutils.core import setup
from Cython.Build import cythonize

setup(
    name = 'demo',
    ext_modules = cythonize('*.pyx'),
)
