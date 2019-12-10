# How to run the LFRic container with Sarus on Piz Daint

## LFRic Gungho benchmark

### Running with Sarus

After creating the Docker image of the `LFRic` Gungho benchmark, you load it with
`sarus` and run it on Piz Daint. The Slurm batch script below can be used as a
template for running the benchmark:
```
#!/bin/bash -l
#SBATCH --job-name=job_name
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=6
#SBATCH --cpus-per-task=1
#SBATCH --constraint=gpu
#SBATCH --output=lfric-gungho.%j.out
#SBATCH --error=lfric-gungho.%j.err

module load daint-gpu
module load sarus
module unload xalt
srun sarus run --mount=type=bind,source=$PWD/input/gungho,destination=/usr/local/src/LFRic_trunk/gungho/example \
               --mpi load/library/lfric-gungho:gnu \
               bash -c "export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK && gungho ./gungho_configuration.nml
```

### Inputs

The local folder `input/gungho` is a copy of the folder
`LFRIC_trunk/gungho/example` and contains:

- Namelist `gungho_configuration.nml`;
- Four mesh files required for the multigrid preconditioner (`l_multigrid` flag
  set to `.true` in the `&multigrid` namelist) used in Gungho (`mesh24.nc`,
  `mesh12.nc`, `mesh6.nc` and `mesh3.nc`);
- `iodef.xml` file required for parallel IO.

The IO file, however is not used as the `use_xios_io` flag in the `&io`
namelist is set to `.false.`. If no diagnostic output (e.g. plots) are
required, it is recommended that the `write_diag` flag in the `&io`
namelist is also set to `.false.`.

All files are available in the
[Gungho input archive](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/input-gungho.tar.gz)
on this repository.

To produce the mesh files and related namelists required for the Gungho higher
resolution tests below (`C48`, `C96` and `C192` mesh configurations), please
follow the instructions in the
[*LFRic mech generation*](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/MeshGeneration.md)
section.

### Outputs

The Gungho application will produce a single text output for a serial run
(single MPI task) or `PET**.gungho.Log` outputs for multiple MPI tasks, as well
as checksums stored in `gungho-checksum.txt` output. Depending on the `&io`
namelist's settings, it will also produce diagnostic outputs such as

* Overall application run times stored in `timer.txt` (set by the
  `subroutine_timers` flag to `.true.`);
* Overall application counter of halo calls stored in `halo_calls_counter.txt`
  (set by the `subroutine_counters` flag to `.true.`);
* Plots of the results (set by the `write_diag` and `diagnostic_frequency`
  options);
* `XIOS` client output and error logs (`xios_client.out` and `xios_client.err`
  for a serial run/single MPI task; `xios_client_**.out` and `xios_client_**.err`
  for multiple MPI tasks) if `use_xios_io` flag is set to `.true.`.

### Results

Below are times for completing the Gungho benchmark on Cray XC50 with different
mesh resolutions, number of nodes, MPI tasks and OpenMP threads. The times are
from the LFRic `timer.txt` outputs and Slurm job outputs. Note that the Slurm
completion times are longer, as they include overheads of job submission
(prologue and epilogue).

`C24` and `C48` mesh configurations were run on 1 compute node (1 and 6 MPI
tasks per node, respectively).

<table>
    <thead>
        <tr>
            <th rowspan=3>OMP threads</th>
            <th colspan=4>C24, 1 node</th>
        </tr>
        <tr>
            <th colspan=2>LFRic timer</th>
            <th colspan=2>Slurm time</th>
        </tr>
        <tr>
            <th>1 MPI p.n.</th>
            <th>6 MPI p.n.</th>
            <th>1 MPI p.n.</th>
            <th>6 MPI p.n.</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <th>1</th>
            <th>328.91 s</th>
            <th>72.22 s</th>
            <th>00:08:06 (486 s)</th>
            <th>00:01:56 (116 s)</th>
        </tr>
        <tr>
            <th>2</th>
            <th>185.56 s</th>
            <th>44.33 s</th>
            <th>00:03:24 (204 s)</th>
            <th>00:00:57 (57 s)</th>
        </tr>
    </tbody>
</table>

<table>
    <thead>
        <tr>
            <th rowspan=3>OMP threads</th>
            <th colspan=4>C48, 1 node</th>
        </tr>
        <tr>
            <th colspan=2>LFRic timer</th>
            <th colspan=2>Slurm time</th>
        </tr>
        <tr>
            <th>1 MPI p.n.</th>
            <th>6 MPI p.n.</th>
            <th>1 MPI p.n.</th>
            <th>6 MPI p.n.</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <th>1</th>
            <th>1354.05 s</th>
            <th>280.76 s</th>
            <th>00:22:51 (1371 s)</th>
            <th>00:05:00 (300 s)</th>
        </tr>
        <tr>
            <th>2</th>
            <th>776.13 s</th>
            <th>177.2 s</th>
            <th>00:13:18 (798 s)</th>
            <th>00:03:26 (206 s)</th>
        </tr>
    </tbody>
</table>

`C96` and `C192` mesh configurations were run on 6 compute nodes (6 MPI tasks
per node).

<table>
    <thead>
        <tr>
            <th rowspan=2>OMP threads</th>
            <th colspan=2>C96, 6 nodes, 6 MPI p.n.</th>
            <th colspan=2>C192, 6 nodes, 6 MPI p.n.</th>
        </tr>
        <tr>
            <th colspan=1>LFRic timer</th>
            <th colspan=1>Slurm time</th>
            <th colspan=1>LFRic timer</th>
            <th colspan=1>Slurm time</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <th>1</th>
            <th>194.59 s</th>
            <th>00:03:33 (213 s)</th>
            <th>801.52 s</th>
            <th>00:13:40 (820 s)</th>
        </tr>
        <tr>
            <th>2</th>
            <th>128.43 s</th>
            <th>00:02:57 (177 s)</th>
            <th>517.95 s</th>
            <th>00:08:57 (537 s)</th>
        </tr>
    </tbody>
</table>

Below are results of the additional tests for the `C24` mesh configuration,
run with 1 MPI task and on 1, 2 and 4 OpenMP threads, respectively:

| OMP threads  | LFRic timer | Slurm time       |
|--------------|-------------|------------------|
|       1      |  394.76 s   | 00:06:58 (418 s) |
|       2      |  231.69 s   | 00:04:32 (272 s) |
|       4      |  153.93 s   | 00:03:14 (194 s) |

## LFRic Gravity Wave benchmark

### Running with Sarus

After creating the Docker image of the `LFRic` Gravity Wave benchmark, you load
it with `sarus` and run it on Piz Daint. The Slurm batch script below can be used
as a template for running the Gravity Wave benchmark:
```
#!/bin/bash -l
#SBATCH --job-name=lfric-gwave
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=normal
#SBATCH --constraint=gpu

module load daint-gpu
module load sarus
module unload xalt
srun sarus run \ 
     --mount=type=bind,source=$PWD/input/gwave,destination=/usr/local/src/LFRic_trunk/gwave/example \
     --mpi load/library/lfric-gwave:gnu \
     bash -c "export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK && gravity_wave ./gravity_wave_configuration.nml"
```

### Inputs

The local folder `input/gwave` contains the namelist `gravity_wave_configuration.nml`
and the mesh file `mesh24.nc`: both files are available in the
[Gravity Wave input archive](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/input-gwave.tar.gz)
on this repository.

This folder is a trimmed-down copy of the folder
`LFRIC_trunk/miniapps/gravity_wave/example`. There are also other input files
present in the `LFRic` repository: `mesh12.nc`, `mesh6.nc` and `mesh3.nc` (for
the multigrid preconditioner) and `iodef.xml` (parallel IO). They are not
present in the `input/gwave` folder as neither `l_multigrid` nor `use_xios_io`
flags were set to `.true.` for the Piz Daint run.

### Outputs and results

The Gravity Wave application will produce outputs similar to the Gungho
application depending on the namelists' settings.

The Gravity Wave benchmark on a single MPI task takes around 5 minutes to
complete on a single Cray XC50 node:

```
Batch Job Summary Report for Job "lfric-gwave" (18507334) on daint
-----------------------------------------------------------------------------------------------------
             Submit            Eligible               Start                 End    Elapsed  Timelimit
------------------- ------------------- ------------------- ------------------- ---------- ----------
2019-12-04T12:06:36 2019-12-04T12:06:36 2019-12-04T12:06:38 2019-12-04T12:11:50   00:05:12   01:00:00
-----------------------------------------------------------------------------------------------------
Username    Account     Partition   NNodes   Energy
----------  ----------  ----------  ------  --------------
hck01       hck         normal           1   29.18K joules
```
