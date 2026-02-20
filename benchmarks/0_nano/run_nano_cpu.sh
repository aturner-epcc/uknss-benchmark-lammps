#!/bin/bash -l
#SBATCH -N 1
#SBATCH -C cpu
#SBATCH -t 00:10:00
#SBATCH -J lmp_nano_cpu
#SBATCH -o lmp_nano_cpu.o%j
#SBATCH -A nstaff
#SBATCH -q regular
#SBATCH -n 64
#SBATCH -c 2

# spec.txt provides the input specification
# by defining the variables spec and BENCH_SPEC
source nano_spec.txt

mkdir lammps_$spec.$SLURM_JOB_ID
cd    lammps_$spec.$SLURM_JOB_ID
ln -s ../../common .
cp ${0} .
cp ../nano_spec.txt .

# This is needed if LAMMPS is built using cmake.
install_dir="../../../install_cpu"
export LD_LIBRARY_PATH=${install_dir}/lib64:$LD_LIBRARY_PATH
EXE=${install_dir}/bin/lmp

# Match the build env.
#module load PrgEnv-gnu

input="${BENCH_SPEC} " 

command="mpirun --bind-to core -np 32 $EXE $input"

echo $command

$command
