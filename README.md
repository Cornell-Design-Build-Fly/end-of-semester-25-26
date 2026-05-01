# End of Semester Plane Design
## What is AVL?
AVL (Athena Vortex Lattice) is a program made by MIT to
analyze airfoils and aircraft. It is similar in function 
to XFLR5. The main difference is that AVL is mainly
accessible through the command line, whereas XFLR5 has
a purpose-built user interface. This means it is harder
to work with single-handedly; but it presents an
opportunity. Writing code in MATLAB, you can integrate AVL
with a program to analyze lots of different aircraft and
rapidly make changes.

## Script Goals
The goal of this program will be to give you an intuition
on three crucial things:
- How wing and tail dimensions impact aerodynamic stability
- Acceptable ranges for static margin, elevator trim, 
doubling times, and climb rates
- The corrolation of aircraft parameters with expected 
mission score

## Getting started
Before doing anything, right click on the `src` folder and
select 'add to path > Selected folder and subfolders'. This
ensures MATLAB has access to all the necessary files we'll
be using. Now we can start!

First, walk through the `avlInteractive.mlx` file, which 
discusses the geomtry and aerodynamics of the 2025-26
DBF plane design. Values don't really need to be changed
here, but experimenting is encouraged.

Next, look into the `scenarios` folder and open up
`design-scenarios-challenges.pdf` file. This will walk
you through the three scenarios, each of which present a
viable plane in all but one or two key characteristics. Your
goal will be to identify this flaw and fix the aircraft.
In the challenges section, you are encouraged to edit
the initial interactive design we started with and try your
best with each challenge.