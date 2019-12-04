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


