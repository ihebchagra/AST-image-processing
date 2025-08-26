import os
import sys
import subprocess
from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy

# --- Helper function to find compiler flags using pkg-config ---
def pkg_config(*packages):
    """
    Queries pkg-config for the necessary compiler and linker flags.
    """
    flag_map = {'-I': 'include_dirs', '-L': 'library_dirs', '-l': 'libraries'}
    try:
        cmd = ['pkg-config', '--libs', '--cflags'] + list(packages)
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output, _ = proc.communicate()
        if proc.returncode != 0:
            raise subprocess.CalledProcessError(proc.returncode, cmd)
        
        kw = {}
        for token in output.decode('utf-8').strip().split():
            if token[:2] in flag_map:
                kw.setdefault(flag_map[token[:2]], []).append(token[2:])
            else:
                kw.setdefault('extra_compile_args', []).append(token)
                kw.setdefault('extra_link_args', []).append(token)
        return kw
    except (OSError, subprocess.CalledProcessError):
        print(f"ERROR: pkg-config failed for {' '.join(packages)}. Is it installed and is the library in PKG_CONFIG_PATH?")
        sys.exit(1)

# --- Define Project Paths ---
CWD = os.path.dirname(os.path.abspath(__file__))
ASTIMP_INCLUDE_FOLDER = os.path.abspath(os.path.join(CWD, "../astimplib/include"))
ASTIMP_LIB_FOLDER = os.path.abspath(os.path.join(CWD, "../build/astimplib"))

# --- Find OpenCV ---
try:
    opencv_flags = pkg_config('opencv4')
except SystemExit:
    print("INFO: pkg-config could not find 'opencv4'. Trying 'opencv' instead...")
    opencv_flags = pkg_config('opencv')

# --- Define the Cython Extensions ---
ext_opencv_mat = Extension(
    "opencv_mat",
    sources=["opencv_mat.pyx"],
    language="c++",
    extra_compile_args=["-std=c++11"],
    include_dirs=[numpy.get_include()] + opencv_flags.get('include_dirs', []),
    library_dirs=opencv_flags.get('library_dirs', []),
    libraries=opencv_flags.get('libraries', []),
)

ext_astimp = Extension(
    "astimp",
    sources=["astimp.pyx"],
    language="c++",
    extra_compile_args=["-std=c++11"],
    include_dirs=[
        numpy.get_include(),
        ASTIMP_INCLUDE_FOLDER,
    ] + opencv_flags.get('include_dirs', []),
    library_dirs=opencv_flags.get('library_dirs', []),
    libraries=opencv_flags.get('libraries', []),
    extra_objects=[os.path.join(ASTIMP_LIB_FOLDER, "libastimp.so")]
)

# --- Main Setup Function ---
setup(
    name='astimp',
    version='1.1.4', # A new version for the corrected build
    author='Marco Pascucci & Iheb Chagra',
    description='Image processing for antibiotic susceptibility testing',
    packages=['astimp_tools'],
    install_requires=['Cython', 'imageio', 'matplotlib', 'pyyaml', 'numpy', 'opencv-python'],
    ext_modules=cythonize([ext_opencv_mat, ext_astimp]),
    zip_safe=False,
)
