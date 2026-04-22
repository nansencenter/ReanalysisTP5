# Usage:
# prepare the ice parameters with or without perturbation for reanalysis run
# Reana_icepara.sh Nmem Fform Fldnames 
# Nmem:    ensemeble size
# Fform:   stardard file name (date)
# Fldnames: perturbed file stored

PP0=0.8    # maxmal percent in geneal (+-0.4 percent)

if [ $# -ge 3 ]; then
   Inidrt=$3
else
   Inidrt='/cluster/home/xiejp/REANALYSIS_TP5_spinup/ReanalysisTP5/PROP/BIN'
fi
prg=${Inidrt}/Para_v1.py
[ ! -r ${prg} ] && { echo "Missing the program under the directory ${Inidrt}"; 
                     exit 0; }

vars="Pstar dragio astar floediam"
N0=${#vars}
tmpvar=$(echo "$vars" | tr -d ' ')
N1=${#tmpvar}
if [ $N1 -lt $N0 ]; then
   (( NN= $N0 - $N1 ))
   echo $NN
   varnco=""
   i0=0
   for ii in ${vars}; do
      if [ $i0 -lt $NN ]; then
	 varnco=${varnco}${ii}","
      else
	 varnco=${varnco}${ii}
      fi
      (( i0 += 1 ))
   done
else
   varnco=${vars}
fi
echo ${varnco}


# work directory: needs to access regional.grib.?
if [ $# -eq 4 ]; then
   wrkdrt=$4
else
   wrkdrt='/cluster/work/users/xiejp/TP5_test/TP5a0.06/expt_02.1/SCRATCH'
fi
[ ! -r ${wrkdrt} ] && { echo "Missing the work directory $wrkdrt"; exit 0; }
cd ${wrkdrt}

File0=para_init.nc
Fsur0=icep.
if [ $1 -le 0 ];then
   echo "Wrong input $1 for ensemble size"	      
   exit 0
fi
Nmem=$1
if [ $# -ge 2 ]; then
   Fdate=$2
else
   echo "It needs two input parameters at least"	      
   exit 0
fi
for ii in `seq 1 ${Nmem}`; do
   [ -s ${File0} ] && rm ${File0}
   if [ $ii -gt 1 ]; then
      python ${prg} ${PP0} "" #${vars} 
   else
   # defaut setting for the first memeber using the constant parameters
      python ${prg} 0 "" #${vars} 
   fi
   if [ -s ${File0} ]; then
      Fmm=mem`echo 00$ii|tail -4c`
      ncks -Oh -v ${varnco} ${File0} ${Fsur0}${Fdate}_${Fmm}.nc
      rm ${File0}
   fi
done





