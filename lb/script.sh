#!/bin/sh

#MSUB -l nodes=3
#MSUB -l walltime=03:00:00
#MSUB -V

rm -f partxyz*
rm -f partdata*
rm -f b3d0.f*
echo cylinder > SESSION.NAME
echo `pwd`'/' >> SESSION.NAME
rm -f rarefaction.sch
srun -n90 ./nek5000 > output.txt.centr.autolb.117
