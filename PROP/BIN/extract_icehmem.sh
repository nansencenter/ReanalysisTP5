#!/bin/bash -l


# useage to calcuate the ensemble mean for daily output in hycom_cice
# So it includes two parts: 1) dealing with hycom daily; 2) dailling with cice daily files

# The rquired inputs: file lists of archm/iceh; the predefined order in these files

if [ $# -lt 2 ]; then
   echo "Wrong input for $?"
   echo "extract_icemem.sh <iceh.name> <member>  "
   echo "Or. extract_icemem.sh <iceh.name> <member> <PrefixOUT> "
   exit 0 
fi

ficeh=$1
Emem=$2

#module load NCO/4.9.7-iomkl-2020a

if [ ! -s ${ficeh} ]; then
   echo "Missing the input file:" ${ficeh}
   exit 0
fi

Ftemp=${ficeh#*iceh.}
Fjuly=${Ftemp%.nc*}


if [ $# -gt 2 ]; then
   Fout=ICEDRIFT.$3_mem`echo 00${Emem}|tail -4c`.nc
else

   Fout=ICEDRIFT.${Fjuly}_mem`echo 00${Emem}|tail -4c`.nc
fi
Fout0=ICEtemp.${Fjuly}_mem`echo 00${Emem}|tail -4c`.nc

#icevars="hisnap_d,aisnap_d,vvel_d,uvel_d,ice_present_d"
icevars="hisnap_d,aisnap_d,vvel_d,uvel_d,aice_d"
ncks -v ${icevars} ${ficeh} ${Fout0}
if [ -s ${Fout0} ]; then
   ncks -C -h -O -x -v time_bounds ${Fout0} ${Fout}
   [ -s ${Fout} ] && rm ${Fout0}
fi
