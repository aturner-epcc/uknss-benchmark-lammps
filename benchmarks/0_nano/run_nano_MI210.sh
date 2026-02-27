#!/bin/bash -l

# spec.txt provides the input specification
# by defining the variables spec and BENCH_SPEC
source nano_spec.txt

mkdir lammps_$spec.$SLURM_JOB_ID
cd    lammps_$spec.$SLURM_JOB_ID
ln -s ../../common .
cp ${0} .
cp ../nano_spec.txt .

# This is needed if LAMMPS is built using cmake.
install_dir="../../../install_MI210"
export LD_LIBRARY_PATH=/opt/rocm-7.0.2/lib/llvm/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${install_dir}/lib64:$LD_LIBRARY_PATH
EXE=${install_dir}/bin/lmp

gpus_per_node=2

input="-k on g $gpus_per_node -sf kk -pk kokkos newton on neigh half ${BENCH_SPEC} " 
#input="${BENCH_SPEC} "

command="mpiexec -n 2 $EXE $input"

echo $command

$command