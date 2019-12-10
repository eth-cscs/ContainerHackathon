# Containerisation of LFRic

## LFRic and PSyclone: A quick overview

`LFRic` is the new weather and climate modelling system being developed by the
UK Met Office to replace the existing Unified Model (UM) in preparation for
exascale computing in the 2020s. `LFRic` uses the GungHo dynamical core and runs
on a semi-structured cubed-sphere mesh.

The design of the supporting infrastructure follows object-oriented principles
to facilitate modularity and the use of external libraries. One of the guiding
design principles, imposed to promote performance portability, is
“separation of concerns” between the science code and parallel code. An
application called `PSyclone`, developed at the STFC Hartree Centre, can generate
the parallel code enabling deployment of a single source science code onto
different machine architectures.

`PSyclone` is a domain-specific compiler and source-to-source translator developed
for use in finite element, finite volume and finite difference codes. Using the
information from a supported API, `PSyclone` generates code exploiting different
parallel programming models.

More detailed information about `LFRic` and further references can be found in
[*Introduction to LFRic*](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/LFRicIntro.md) section.

## LFRic containers

Instructions on building and runing `LFRic` in two container platforms,
[Docker CE](https://docs.docker.com/install/) and
[Singularity](https://sylabs.io/docs/), can be found following the links below:

* [`LFRic` Docker container](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/README.md);
* [`LFRic` Singularity container](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/singularity/README.md).

For more information on building the `LFRic` Docker container please contact
[Iva Kavcic, Met Office](mailto:iva.kavcic@metoffice.gov.uk) and
[@lucamar, CSCS](https://github.com/lucamar) (mentor).

For more information on building the `LFRic` Singularity container please contact
[Simon Wilson, NCAS](mailto:simon.wilson@ncas.ac.uk) and
[@lucamar, CSCS](https://github.com/lucamar) (mentor).

## LFRic repository and wiki

The `LFRic` repository and the associated wiki are hosted at the Met Office
Science Repository Service [(MOSRS)](https://code.metoffice.gov.uk/trac/home).
The code is BSD-licensed, however browsing the
[`LFRic` wiki](https://code.metoffice.gov.uk/trac/lfric/wiki) and
[code repository](https://code.metoffice.gov.uk/trac/lfric/browser) requires
login access to MOSRS. Please contact the `LFRic` team manager,
[Steve Mullerworth](mailto:steve.mullerworth@metoffice.gov.uk), to be granted
access to the repository.

Once the access has been granted the `LFRic` trunk can be checked out using
[Subversion](https://subversion.apache.org/) or
[FCM](https://metomi.github.io/fcm/doc/) version control systems. `SVN` is
recommended for checking out the code for runs only as it is easier to install.

### LFRic code structure

The current `LFRic` trunk
[(revision 21509)](https://code.metoffice.gov.uk/trac/lfric/browser/LFRic/trunk?rev=21509)
is structured as follows:

* `bin` - `Rose` executables;

* `extra` - Utilities (e.g.job submission scripts);

* `GPL` - [`Rose`](https://github.com/metomi/rose/) source used in `LFRic`;

* `gungho` - Gungho dynamical core (one of the main science applications);

* `infrastructure` - `LFRic` infrastructure supporting science applications;

* `jules` - Interface to the MO [JULES land surface model](https://www.metoffice.gov.uk/research/approach/collaboration/jwcrp/jules);

* `lfric_atm` - `LFRic` atmospheric model (Gungho dynamical core, UM Physics,
                JULES and SOCRATES);

* `mesh_tools` - Mesh generation tools;

* `miniapps` - "Standalone" science and infrastructure applications (e.g.
                Gravity Wave application);

* `socrates` - Interface to the MO radiative transfer ("Suite Of Community
               RAdiative Transfer codes") model;

* `um_physics` - Interface to the MO UM Physics parameterisation schemes.

## PSyclone repository and wiki

Both [`PSyclone`](https://github.com/stfc/PSyclone) and the
[Fortran parser](https://github.com/stfc/fparser) it uses are open source and
hosted on GitHub.

Wikis are also hosted on GitHub:

* [`PSyclone` wiki](https://github.com/stfc/PSyclone/wiki);
* [`fparser` wiki](https://github.com/stfc/fparser/wiki).

The documentation is hosted on [Read the Docs](https://readthedocs.org/):

* [`PSyclone` documentation](https://psyclone.readthedocs.io/en/stable/);
* [`fparser` documentation](https://fparser.readthedocs.io/en/latest/);

or `PSyclone` and `fparser` repositories for functionality merged to master but
not yet part of an official release.

### PSyclone in LFRic

`LFRic` wiki hosts pages on the use of `PSyclone` in `LFRic`, starting with the
[`PSyclone` in `LFRic` wiki](https://code.metoffice.gov.uk/trac/lfric/wiki/PSycloneTool).

As mentioned in the
[*LFRic Docker container*](https://github.com/eth-cscs/ContainerHackathon/blob/master/LFRIC/docker/README.md)
section, not every `PSyclone` release works with every `LFRic` trunk revision. The `LFRic` - `PSyclone`
compatibility table is give in this
[`LFRic` wiki (requires login)](https://code.metoffice.gov.uk/trac/lfric/wiki/LFRicTechnical/VersionsCompatibility).
