
# prepare the ice drift on the observation grid from model daily average
# It should be performed under the ANALYSIS work directory
# And requires the ensemble daily ice velocity available

prg=~/REANALYSIS_TP5_spinup/ReanalysisTP5/ASSIM/BIN/icedrift_osisafNC

Ficeens=$1
Ficeout=$2
NDAY=2
Nmem=100

osisaf_dir=/cluster/projects/nn2993k/TP4b0.12/idrft2d_osisaf/
if [ $# -eq 3 ]; then
   NDAY=1
   osisaf_dir=/cluster/projects/nn2993k/TP4b0.12/idrft_osisaf/
fi

if [ -s ${Ficeens} -a -s ${prg} ]; then
   ${prg} ${Ficeens} ${osisaf_dir} ${NDAY} ${Nmem} 
   Ftemp=${Ficeens%.nc}.uf
   if [ -s ${Ftemp} ]; then
      mv ${Ftemp} ${Ficeout}
   fi
fi







