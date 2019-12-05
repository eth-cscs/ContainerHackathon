The teams are expected to do deliver a final report after the hackathon. Please
note that a report has to be delivered by each team before the end of the
hackathon.

Here is a breakdown of the report with more details:

A single paragraph abstract with the application description.

A short overview of the application (without mathematics!)

Break down of the containerisation approach:

Explain the starting point (e.g., CPU-code compiled with XXX compiler, GPU access using CUDA, etc)

Shortly describe the test case that verifies the code is functioning correctly

Steps you made porting the code to a Docker container (e.g., which components ported)

OPTIONAL Performance profile of the code running natively and from a container, e.g., speedup graph.

A final conclusion including:

Short feedback about your experiences

Obstacles you encountered, and how you solved them

Lessons that you would like to share with other teams, e.g., suggestions on how
to improve the process, better documentation, etc.

Last but not least, any general comments about this Container Hackathon for
Modellers will be really useful for the organisers.

# Introduction

NEMO for Nucleus for European Modelling of the Ocean is a state-of-the-art modelling framework for research activities and forecasting services in ocean and climate sciences, that has been developed in a sustainable way by a European consortium since 2008.
The NEMO ocean model has 3 major components:
- NEMO-OPA models the ocean {thermo}dynamics and solves the primitive equations (./src/OCE)
- NEMO-SI3 simulates sea ice {thermo}dynamics, brine inclusions and subgrid-scale thickness variations (./src/ICE)
- NEMO-TOP/PISCES models the {on,off}line oceanic tracers transport and biogeochemical processes (./src/TOP)
These physical core engines are described in their respective references that must be cited for any work related to their use.
Not only does the NEMO framework model the ocean circulation, it offers various features to enable
- The seamless creation of embedded zooms thanks to 2-way nesting package AGRIF
- The opportunity to integrate an external biogeochemistry model
- Versatile data assimilation
- The generation of diagnostics through effective XIOS_ system
- The roll-out Earth system modeling with coupling interface based on OASIS
Several built-in configurations are provided to evaluate the skills and performances of the model which can be used as templates for setting up new configurations (./cfgs).
The user can also check out available idealized test cases that address specific physical processes(./tests).



# Reproducibility experiments

## GYRE_namelist/repro_2x4_namelist_cfg

```
nn_it000=1
nn_itend=1080
nn_GYRE=1
ln_bench=.false.
jpnj=2 <---
jpni=4
ln_timing=.true.
```

## GYRE_namelist/repro_4x2_namelist_cfg

```
nn_it000=1
nn_itend=1080
nn_GYRE=1
ln_bench=.false.
jpnj=4 <---
jpni=2
ln_timing=.true.
```

for f in `\ls GYRE*.nc | grep -v restart`; do echo $f; cdo diff $f ../REPROD_JG_4x2_G/$f; done

# Restart experiments


for f in `\ls *SHORT*restart*.nc`; do echo $f; f1=${f/SHORT/LONG}; cdo diff $f ../RESTART_LONG_G/$f1; done

# Scalability experiments


