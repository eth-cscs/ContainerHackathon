# Containerisation of LFRic

## LFRic and PSyclone - a quick overview

LFRic is the new weather and climate modelling system being developed by the UK
Met Office to replace the existing Unified Model in preparation for exascale
computing in the 2020s. LFRic uses the GungHo dynamical core and runs on a
semi-structured cubed-sphere mesh.

The design of the supporting infrastructure follows object-oriented principles
to facilitate modularity and the use of external libraries. One of the guiding
design principles, imposed to promote performance portability, is
“separation of concerns” between the science code and parallel code. An
application called PSyclone, developed at the STFC Hartree Centre, can generate
the parallel code enabling deployment of a single source science code onto
different machine architectures.

PSyclone is a domain-specific compiler and source-to-source translator developed
for use in finite element, finite volume and finite difference codes. Using the
information from a supported API, PSyclone generates code exploiting different
parallel programming models.

More detailed information about LFRic and further references can be found in
[*Introduction to LFRic*](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/LFRicIntro.md) section.

A quick guide for obtaining LFRic and PSyclone codes/releases can be found in
[*LFRic and PSyclone repositories and code*](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/LFRicPSycloneRepoCode.md) section.

## LFRic containers

Instructions on building and runing LFRic in two container platforms,
[Docker CE](https://docs.docker.com/install/) and
[Singularity](https://sylabs.io/docs/), can be found following the links below:

- [LFRic Docker container](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/README.md);
- [LFRc Singularity container](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/singularity/README.md).




