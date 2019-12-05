# ESiWACE2
# Container Hackathon for Modellers
Atmosphere and ocean models are characterised by complex dependencies, external configurations, and performance requirements.
The objective to containerise such software stacks helps to provide a consistent environment to ensure security, portability and performance.
Since the container is built only once, but then can be deployed on multiple platforms, productivity is increased.
ETH Zurich provides subsequent Docker/Shifter support for the teams to complete the containerisation of their models.

Head over to the [Wiki](https://github.com/eth-cscs/ContainerHackathon/wiki) for further details.

## Aim of the hackathon
To create containerised versions of Earth system models (e.g. COSMO, ICON, Nemo, OpenIFS, EC-Earth) using a Docker-compatible technologies and to identify representative test cases.
In order to help evaluating performance when containers are used and which adaptations are necessary, the ported Earth system models from the hackathon is going to be deployed on CSCS supercomputer (Piz Daint) using an HPC-oriented container runtime.
The Docker-compatible format of runtime will ease container portability across different systems and help collecting the performance figures from the representative test case.

## This repository
This area is meant for learning materials, examples, and sharing ideas about containerization of high-performance weather-simulation codes during the first Container Hackathon for Modellers between Dec. 3 - Dec 5 2019 in Lugano, Switzerland.

## Continuation of your work
Through the ESiWACE-2 project there is support available for the continuation of ESiWACE model containerization efforts leading to your team deliverables.  There are a couple of ways to continue:

  1.  Running your container on Piz Daint via SARUS: if you do not have access to Piz Daint, you would need to apply for a development project.  [Development projects](https://www.cscs.ch/user-lab/allocation-schemes/development-projects/)
  2.  Installation of SARUS on your home platform:   The SARUS group would help your system administrators install SARUS on the platform of your choice.
