#! /bin/bash -l
# 
#  Make sure I use the correct shell.
#
##SBATCH -A nn2993k --qos=devel 
#SBATCH -A nn2993k --qos=preproc 
#
#SBATCH -J profweekly
#SBATCH --exclusive
#SBATCH --ntasks=12 --cpus-per-task=1
#SBATCH --mem-per-cpu=6000M

#SBATCH -o /cluster/work/users/xiejp/TP5_Reanalysis/preobs/profile/ARC_%J.out   #Standard output and error log
#SBATCH -e /cluster/work/users/xiejp/TP5_Reanalysis/preobs/profile/ARC_%J.err
## How long job takes, wallclock time hh:mm:ss
#SBATCH -t 24:00:00
##SBATCH -t 00:30:00

#ulimit -m unlimited
#ulimit 

# set up job environment
set -e # exit on error
set -u # exit on unset variables

Inidir='/cluster/home/xiejp/REANALYSIS_TP5_spinup/ReanalysisTP5/preobs_scripts/Infile2'
Rundir='/cluster/work/users/xiejp/TP5_Reanalysis/preobs/profile'

Fmal=${Inidir}/do_MYO_profile2024.mal
Fmal2=${Inidir}/do_MYO_profile.mal


cd ${Rundir}

Jdy2=22000
Jdy1=20000


Jdy1=25500
Jdy2=27030


Ncore=12
(( Delt = ${Jdy2} - ${Jdy1} ))
if [ ${Delt} -lt ${Ncore} ]; then
   Ncore=${Delt}
fi

if [ $# -gt 0 ]; then
   # dynamic search the job list
   # check the accessibility under the final direcotry which used in *.mal
   Foutdir=$(sed -n 's/Odir=//p' ${Fmal})
   echo ${Foutdir}

   Flist="list.log"
   [ -s ${Flist} ] && rm ${Flist}
 
   touch ${Flist}
   for i in `seq $Jdy1 $Jdy2`; do
       Files=${Foutdir}/SAL/obs_SAL_${i}
       Filet=${Foutdir}/TEM/obs_TEM_${i}
       if [ ! -s ${Files}.nc -o ! -s ${Files}.uf -o ! -s ${Filet}.nc -o ! -s ${Filet}.uf ]; then
	  echo $i >> ${Flist}
       fi
   done
   Nfile=$(cat ${Flist}|wc -l)
   if [ $Nfile -eq 0 ]; then
      echo "All files are ready at ${Foutdir}"
      exit 0
   fi
   (( Nmem=  ${Nfile} / ${Ncore} + 1 ))

else
   Nfile=0
   (( Nmem= ( ${Jdy2} -${Jdy1} + 1 ) / ${Ncore} + 1 ))
fi


echo $Ncore '~' $Nmem



for icore in `seq ${Ncore}`; do
   cd ${Rundir}
   Fsub=Prof_${icore}
   [ -r ${Fsub} ] && rm -rf ${Fsub}
   mkdir ${Fsub}
   if [ ${Nfile} -eq 0 ]; then
      (( J1 =  ( ${icore} - 1 ) * ${Nmem} + ${Jdy1} - 1 ))
      (( J2 =  ${Nmem} + ${J1} - 1))
      [ $J1 -gt ${Jdy2} ] && continue
      if [ $J2 -gt ${Jdy2} ]; then
         (( J2 = Jdy2 ))
      fi
      echo $J1 '~' $J2
      cd ${Fsub}
      cat ${Fmal} | sed "s/Jdate1/${J1}/" |\
         sed "s/Jdate2/${J2}/g" > do_${J1}.sh
         chmod +x do_${J1}.sh
         #srun -N1 -n1 ./do_${J1}.sh 
        ./do_${J1}.sh  > out.log & 

   else
      (( J1 =  ( ${icore} - 1 ) * ${Nmem} + 1 ))
      (( J2 =  ${Nmem} + ${J1} - 1))
      [ $J1 -gt ${Nfile} ] && continue
      [ $J2 -gt ${Nfile} ] && J2=${Nfile}
      echo $J1 '~' $J2
      cd ${Fsub}
      ln -sf ../${Flist} .
      cat ${Fmal2} | sed "s/Jline1/${J1}/" | sed "s#LOGFILE#${Flist}#" | \
          sed "s/Jline2/${J2}/g" > do_${icore}.sh
          chmod +x do_${icore}.sh
	  ./do_${icore}.sh $(Flist) > out${icore}.log & 

   fi

done
wait
exit $?
