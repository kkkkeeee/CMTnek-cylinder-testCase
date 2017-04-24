#!/bin/sh

#MSUB -q psmall
#MSUB -l nodes=128
#MSUB -l partition=vulcan
#MSUB -l walltime=12:00:00
#MSUB -V
#MSUB -l gres=lscratchv

rm -f partxyz*
rm -f partdata*
rm -f b3d0.f*
echo b3d > SESSION.NAME
echo `pwd`'/' >> SESSION.NAME
rm -f b3d.sch
srun -n 128 ./nek5000 > output.txt-n128-orig-32k

