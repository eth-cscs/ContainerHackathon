# Introduction to LFRIC

The Unified Model uses a latitude-longitude coordinate system to create a mesh
of points covering Earth's surface. Numerical solutions to Newton's laws
applied to a gas then predict the weather and climate at each of those points.
In our current operational weather forecast model, those points are 10km apart
in the North-South direction. The convergence of the meridians of the
latitude-longitude system means that just next to the North and South poles
those points are little more than 10m apart in the East-West direction, a
factor of 1000 smaller than the separation in the North-South direction.
This presents a huge challenge to solving the equations efficiently: many
more calculations have to be done than would otherwise be the case because of
this clustering of points near the poles; and these calculations require a
lot of data to be moved about in the computer's memory which, on the massive
supercomputers that are used today for weather and climate prediction, costs time.

In the future, unless we do something about it, this problem will get increasingly
worse for two reasons. The first is that to increase the detail and accuracy of
our weather and climate forecasts we want to continue to reduce the spacing of
the mesh points. This will increase the clustering of points near the poles.
For example, if we reduced the North-South spacing to 1km then the East-West
spacing near the poles would reduce to around 10cm! The second is that for the
next generation of supercomputers to deliver the required increase in speed,
rather than having faster processors they will have many more core processing
units. There may well be 10 or a 100 times more cores but each of them will only
have a relatively small amount of memory. This means that moving memory about
will be even more of a hindrance to achieving computing speed than it currently is.

## GungHo - rising to that challenge

Recognizing this problem, in 2011 the Met Office initiated a project jointly with
the Natural Environment Research Council (NERC) and the Science and Technology
Facilities Council (STFC) to redesign the way that the Unified Model solves
Newton's laws (the part of the model that is referred to as the dynamical core).
The project was called GungHo and ran for 5 years and involved natural and
computational scientists from the Met Office, the universities of Bath, Exeter,
Leeds, Manchester, Reading, Warwick, Imperial College and STFC's Hartree Centre.

The challenge of the project was to design a dynamical core that retains the
advantages of the current one but that is significantly more efficient on
future supercomputer architectures. There were three principal recommendations
of the project. The first is to change from using the latitude-longitude mesh
to what is called a cubed-sphere mesh. This can be thought of as a Rubik's cube
made of rubber that has been inflated to fill a sphere. The second is to use an
alternative numerical method to solve the equations so that at least the same
level of accuracy is retained on the new mesh. This involves changing from what
is termed a finite-difference method to a mixed finite-element method. The third
is to implement what is referred to as the "separation of concerns". This
approach to designing a model is a critical aspect to future-proofing the design,
i.e. making the design as independent as possible of the details of any specific
supercomputer whilst still being able to optimize the model for a specific
supercomputer. It does this by separating the natural science aspects (for
example, how Newton's equations are solved) from the technical implementation
(for example, how data is moved about within a computer's memory). A key
element in achieving this, that GungHo recommended, is to use automatic
code generation.

## LFRic – realising L F Richardson’s fantasy 100 years on

To implement these changes to deliver a modelling system that is fit for future
computers requires the development of a radically new software infrastructure
to replace that of the Unified Model. Thus the LFRic project was born. This is
pronounced "elfrick" and was chosen in recognition of Lewis Fry Richardson and
his vision of how to make a weather forecast. His method is based on solving
essentially the same equations as we use today and by quite similar methods. But,
being some decades ahead of when electronic computers were invented, there was no
practical way to solve the equations fast enough for the result to be of any
practical use. Richardson's fantasy for how to achieve this was to solve the
equations by coordinating the efforts of thousands of human processors, each one
working on their own small area of Earth's atmosphere - an approach remarkably
similar to how we use the thousands of processors within a modern supercomputer.
Richardson eloquently described his fantasy in his book "Weather Prediction by
Numerical Process" (Cambridge University Press, 1922; see also "Richardson's
Fantastic Forecast Factory" by Peter Lynch in Weather January 2016 71:1).

LFRic continues the formal collaboration with STFC that was established as part
of GungHo. In particular STFC have developed the application called PSyclone
which auto-generates parallel code used by LFRic. The project also benefits
from the continued engagement of the GungHo partners via the NERC funded GungHo
Network. Additionally, it is beginning to engage across the whole of the UM
Partnership.

## Exascale

The term used to describe the next generation of supercomputer is “exascale”
from their target speed of an exaflop. This means being able to make a billion
billion calculations per second. With this speed of computing comes a similarly
staggering amount of data that will challenge traditional methods of data management.

Although the dynamical core is perhaps the part of the system most impacted by
the challenges of exascale computers, it is by no means the only one. Others
range from the data assimilation system that processes observations, through
the ocean and chemistry models, to the systems that process the forecast data
to create meaningful products for our customers. The Met Office is therefore
spinning up the Exascale Programme to consider all aspects of the end-to-end
weather and climate prediction system. The programme will coordinate this
exciting, challenging, and extensive work, targeting the supercomputers that
are envisaged becoming operational in the middle of the next decade.

**References**

- Adams SV, Ford RW, Hambley M, Hobson JM, Kavcic I, Maynard CM, Melvin T,
  Mueller EH, Mullerworth S, Porter AR, Rezny M, Shipway BJ and Wong R (2019):
  [LFRic: Meeting the challenges of scalability and performance portability in
  Weather and Climate models.](https://doi.org/10.1016/j.jpdc.2019.02.007) Journal of Parallel and Distributed Computing.
- [MO Research News, May 2019](https://www.metoffice.gov.uk/research/news/2019/gungho-and-lfric)
- [MO LFRic Modelling approach](https://www.metoffice.gov.uk/research/approach/modelling-systems/lfric)
