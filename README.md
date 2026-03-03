# UK NNSS LAMMPS Benchmark

This repository contains information on the LAMMPS benchmark for the UK NNSS
procurement. 

This benchmark was originally part of the
[NERSC-10 Benchmark Suite](https://www.nersc.gov/systems/nersc-10/benchmarks).
Changes have been made to the original specification to match onto requirements
for the UK NNSS procurement.

## Benchmark Overview

A fundamental challenge for molecular dynamics (MD) simulation is to propagate the dynamics for a sufficiently long simulated time to sample all of the relevant molecular configurations.  Historical MD workflows have therefore consisted of long-running jobs (or sequences of jobs), where each time-step may be accelerated by disributing atoms across parallel processing units, but the series of time-steps progresses sequentially. Recent advances in MD sampling effectively provide routes to parallelise the time dimension of the simulation as well.  

This benchmark consists of a single run of the LAMMPS MD package, which is the performance critical component of such simulation workflows. The benchmark problem simulates the high-pressure BC8 phase of carbon using the Spectral Neighbor Analysis Potential (SNAP). LAMMPS's highly optimized implementation of the SNAP potential was written using the Kokkos portability layer, as described in: https://doi.org/10.1145/3458817.3487400

## Status

Stable

## Maintainers

- Andy Turner

**Important:** Please do not contact the benchmark maintainers directly with any questions. All questions on the benchmark must be submitted via the procurement response mechanism.

## Software

[https://github.com/lammps/lammps](https://github.com/lammps/lammps)

## Building the benchmark

Important: All results submitted should be based on the following repository commits:

- LAMMPS repository: [22 Jul 2025, update 3](https://github.com/lammps/lammps/releases/tag/stable_22Jul2025_update3)

Kokkos version 4.6.02 is distributed with and used by this LAMMPS version.
Results may use this version or any released version of Kokkos that work
with this version of LAMMPS.

The following three commands will clone the required version

```
    git clone --single-branch --branch stable https://github.com/lammps/lammps.git lammps_src
    cd lammps_src
    git checkout stable_22Jul2025_update3
```

### Baseline build

For the baseline run the only permitted modifications allowed are those that
modify the LAMMPS or Kokkos source code to resolve unavoidable compilation or
runtime errors.

#### Required LAMMPS patch

The required version of LAMMPS contains a bug that must be patched to allow it to build successfully
when Kokkos is used. The bug and fix are described in
[Issue 4837 in the LAMMPS Gihub repository](https://github.com/lammps/lammps/pull/4837).

This is the patch required:

```
diff --git a/src/KOKKOS/fix_electron_stopping_kokkos.h b/src/KOKKOS/fix_electron_stopping_kokkos.h
index 911ac06c329..db447210898 100644
--- a/src/KOKKOS/fix_electron_stopping_kokkos.h
+++ b/src/KOKKOS/fix_electron_stopping_kokkos.h
@@ -59,7 +59,7 @@ class FixElectronStoppingKokkos : public FixElectronStopping {
   typename AT::t_kkacc_1d_3 f;
   typename AT::t_kkfloat_1d_3 v;
   typename AT::t_int_1d_randomread type;
-  typename AT::t_int_1d_randomread tag;
+  typename AT::t_tagint_1d_const tag;
   typename AT::t_int_1d_const d_mask;
   typename AT::t_kkfloat_1d_randomread d_mass;
   typename AT::t_kkfloat_1d_const d_rmass;
```

and is also included as a file in this repository: [fix_electron_stopping_kokkos.patch](fix_electron_stopping_kokkos.patch)

### Optimised build

Any modifications to the source code are allowed as long as they are able to be provided
back to the community under the same licence as is used for the software package that is
being modified. Any submitted benchmark must clearly point to a publicly visible pull/merge request issued by the benchmarking team that contains all changes, i.e. the same (altered) code base as to be used for all benchmark runs.

The assessment team furthermore appreciates a description of any changes implemented by the benchmarking team.

### Build instructions

Detailed build instructions can be found in the [LAMMPS Documentation](https://lammps.sandia.gov/doc/Build.html).

As an example, we provide manual instructions for building LAMMPS on
[IsambardAI](https://docs.isambard.ac.uk/specs/#system-specifications-isambard-ai-phase-2).

- [Building LAMMPS on IsambardAI](build_isambardai.md)

## Running the benchmark

Input files and batch scripts for seven (7) problem sizes are provided in the benchmarks directory.
Responses should provide results (measured or projected) for the "target" problem size.
Other problem sizes have been provided as a convenience to facilitate profiling at different
scales (e.g. socket, node, blade or rack), and extrapolation to larger sizes.

This collection of problems form a weak scaling series where each successively larger problem
simulates eight times as many atoms as the previous one. Computational requirements are expected
to scale linearly with the number of atoms.

The following table lists the approximate system resources needed to run each of these jobs.
The capability factor (c) parameter is an estimate of the computational complexity
of the problem relative to the "reference" problem.


|Index | Size     |  #atoms | Capability Factor (c)|
|----- | ----     |  -----: | ------:         |
|0     | nano     |     65k |  8<sup>-5</sup> |
|1     | micro    |    524k |  8<sup>-4</sup> |
|2     | tiny     |   4.19M |  8<sup>-3</sup> |
|3     | small    |   33.6M |  8<sup>-2</sup> |
|4     | medium   |    268M |      0.125      |
|5     | reference|   2.15B |       1         |
|6     | target   |   17.2B |       8         |

Each problem has its own subdirectory within the benchmarks directory.
Within those directories, the `run_<size>_IsambardAI.sh` script shows
how the jobs were executed on IsambardAI. 

### Parallel decomposition - permitted input changes

LAMMPS uses a 3-D spatial domain decomposition to distribute atoms among MPI processes.
The default decomposition divides the simulated space into rectangular bricks.
The proportions of the bricks are automatically computed to minimises surface-to-volume
ratio of the bricks. LAMMPS will run correctly with any number of MPI processes,
but better performance is often obtained when the number of MPI processes is the product
of three near-equal integers.

If additional control of the domain decomposition is needed, the `processors` command may
(optionally) be added to the file `benchmarks/common/in.step.test`. The parameters of the
`in.snap.test` file may not be modified **except** for the addition of a `processors` command.
This command requires three integer parameters that correspond to the x,y,z dimensions of
the process grid. Changes to `processors` may require updates to the job submission script
so that the correct number of MPI processes is started. Refer to the LAMMPS documentation
for more information about the [`processors` command](https://docs.lammps.org/processors.html).

### Numerical reproducibility

The LAMMPS benchmark uses a random number generator (RNG), both during initialisation
and during the simulation loop, and can cause non-deterministic results. The absence
of exact numerical reproducibility creates validation challenges when porting or optimising
the code. *When debugging*, it may be useful to avoid the effects of the RNG by modifying
the input file (`in.snap.test`) as follows:
```
> diff in.snap.test in.snap.debug
52c52
< velocity        all create 800.0 4928459 loop local
---
> velocity        all create 800.0 4928459 loop geom
55c55
< fix             2 all langevin 800.0 800.0 0.025 398928
---
> fix             2 all langevin   0.0   0.0 0.025 398928
```

### Benchmark execution

The essential steps are to

1. add a link to the data that are common to all problem sizes: `ln -s ../../common`
2. load the size-specific simulation parameters into the BENCH_SPEC variable: `source <size>_spec.txt`
3. run the job: `srun -n #ranks  /path/to/lammps/lmp  <lammps_options>  ${BENCH_SPEC}`

The recommended lammps_options for IsmabardAI GPU system (and similar systems) are:
`-k on g $gpus_per_node -sf kk -pk kokkos newton on neigh half` 

where `$gpus-per-node` represents the number of GPU/GCD per node. However, bidders are
allowed to modify Kokkos options to achieve best performance in both the baseline and
optimised results.

## Results

### Correctness results

Correctness can be verified using the `benchmarks/validate.py` script,
which compares the total energy per unit cell after 100 time-steps
to the expected value on computed on NERSC Perlmutter (-8.7467391).
The tolerance for the relative error is a physics-motivated function of the problem size
and is more strict for larger problems.

Because this test is based on statistical properties of the simulated system,
it is not sensitive to this source of variation describe in [in the numerical reproducibility section](#numerical-reproducibility)
The result of the validation test is printed on the second line of the script output.
For example:

```
> validate.py --help
| validate.sh: test output correctness for the LAMMPS benchmark.
| Usage: validate.py <output_file>
|
> validate.py lmp_nano.out
| Found size: 0_nano
| Validation: PASSED
| BenchmarkTime (sec): 3.14565
```
### Performance results

In addition, `validate.py` will also print the BenchmarkTime,
which is the sole performance measurement for the benchmark.
The BenchmarkTime printed by `validate.py` corresponds to the
"Loop Time" in the LAMMPS output file,
and excludes the preliminary work needed to set-up the job.

To be a valid FoM, the following conditions must be met:

- LAMMPS must be compiled with the commits stated above
  and must meet any source code modification restrictions stated above
- The LAMMPS input files must not be modified except for permitted
  addition of the `processors` command as described above

### Required data

- **Target configuration:** There is *no minimum GPU count* for the LAMMPS benchmark.
- **Reference FoM:** The reference FoM is from the IsambardAI system using 2048 GH200 GPU (512 nodes): **19.0 s**.

The projected FoM submitted must give at least the same performance 
as the reference value.

### Example performance data

The sample data in the table below are measured BencharkTime from the IsambardAI GPU system.
IsambardAI's GPU nodes each have four NVIDIA GH200 superchips;
GPU jobs used four MPI processes per node, each with one GPU and 72 cores.
The upper rows of the table describe performance change as the problem size increases.
Lower rows describe the strong-scaling performance of LAMMPS when running the reference problem.

| Size      |  # GH200   | BenchmarkTime (sec) |
| ----      | ---------: | ------------------: |
| nano      |          1 |      1.1  |
| micro     |          1 |      8.5  |
| tiny      |          4 |     17.1  |
| small     |          4 |    137.3  |
| medium    |         32 |    139.1  |
| reference |        128 |    276.6  |
| reference |        256 |    140.0  |
| reference |        512 |     70.8  |
| reference |       1024 |     36.5  |
| reference |       2048 |     19.0* |

The reference time was determined
by running the reference problem on 1024 IsambardAI GH200 (128 GPU nodes)
and is marked by a *. The projected BenchmarkTime for the target problem
on the target system must not exceed this value.

## Reporting Results

The bidder should provide copies of:

- Details of any modifications made to the LAMMPS or Kokkos source code
- The compilation process and configuration settings used for the benchmark results - 
  including makefiles, compiler versions, dependencies used and their versions or
  Spack environment configuration and lock files if Spack is used
- The job submission scripts and launch wrapper scripts used (if any)
- The `in.snap.test` file used
- The output from the `validate.py` script
- All standard LAMMPS output files
- A list of options passed to LAMMPS (if any)

## License

This benchmark description and associated files are released under the
MIT license.


