#!/bin/bash
#SBATCH --job-name=EXAALT-micro
#SBATCH --nodes=1
#SBATCH --exclusive
#SBATCH --tasks-per-node=1
#SBATCH --cpus-per-task=72
#SBATCH --gpus-per-node=1
#SBATCH --hint=nomultithread
#SBATCH --time=2:0:0

# spec.txt provides the input specification
# by defining the variables spec and BENCH_SPEC
source micro_spec.txt

module load craype-network-ofi
module load PrgEnv-gnu
module load gcc-native/13.2
module load cray-mpich
module load cuda/12.6
module load craype-accel-nvidia90
module load craype-arm-grace
module load cray-python
module load cray-fftw

mkdir lammps_$spec.$SLURM_JOB_ID
cd    lammps_$spec.$SLURM_JOB_ID
ln -s ../../common .
cp ${0} .
cp ../${spec}_spec.txt .

# This is needed if LAMMPS is built using cmake.
install_dir="/projects/u6cb/software/LAMMPS/22Jul2025"
export LD_LIBRARY_PATH=${install_dir}/lib64:$LD_LIBRARY_PATH
EXE=${install_dir}/bin/lmp

export OMP_PROC_BIND=true
export MPICH_GPU_SUPPORT_ENABLED=1

gpus_per_node=1

input="-k on g $gpus_per_node -sf kk -pk kokkos newton on neigh half ${BENCH_SPEC} " 

command="srun --cpu-bind=socket -n $SLURM_NTASKS $EXE $input"

export LD_PRELOAD=/opt/cray/pe/mpich/8.1.32/gtl/lib/libmpi_gtl_cuda.so

echo $command

$command
