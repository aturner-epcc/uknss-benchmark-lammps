#!/bin/bash

set -e

# The build instructions have been verified for the following git sha.
# LAMMPS version - 29th July 2024
LAMMPS_COMMIT=abfdbec

HOME_BASE=$(pwd)
LAMMPS_SRC="${HOME_BASE}/lammps_src"
LAMMPS_BUILD_DIR="build_cpu"
INSTALL_PREFIX="${HOME_BASE}/install_cpu"
BUILD_THREADS=4

# Clone just the stable branch of LAMMPS if not already cloned.
if [ ! -d ${LAMMPS_SRC} ]; then
    git clone --single-branch --branch stable https://github.com/lammps/lammps.git ${LAMMPS_SRC}
fi

# Enter the lammps directory.
cd ${LAMMPS_SRC}
git checkout ${LAMMPS_COMMIT}

# Create the build dir .
if [ ! -d ${LAMMPS_BUILD_DIR} ]; then
    mkdir ${LAMMPS_BUILD_DIR}
fi
cd ${LAMMPS_BUILD_DIR}
rm -rf *

cmake -D CMAKE_INSTALL_PREFIX=${INSTALL_PREFIX} \
      -D CMAKE_CXX_COMPILER=g++ \
      -D CMAKE_Fortran_COMPILER=gfortran \
      -D BUILD_MPI=yes \
      -D MPI_CXX_COMPILER=mpicxx \
      -D PKG_USER-OMP=ON \
      -D PKG_KOKKOS=ON \
      -D DOWNLOAD_KOKKOS=ON \
      -D Kokkos_ARCH_FIXME=ON \
      -D PKG_ML-SNAP=ON \
      -D CMAKE_POSITION_INDEPENDENT_CODE=ON \
      -D CMAKE_EXE_FLAGS="-dynamic" \
      ../cmake

make -j${BUILD_THREADS}
make install -j${BUILD_THREADS}
