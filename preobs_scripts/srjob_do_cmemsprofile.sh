#! /bin/bash -l
# 
#  Make sure I use the correct shell.
#
#SBATCH -A nn9481k 
#SBATCH -J TP5prof
#SBATCH -N 4
#SBATCH --exclusive
#SBATCH --ntasks=15 --cpus-per-task=1

#SBATCH -o /cluster/work/users/xiejp/TP5prof_%J.out   #Standard output and error log
#SBATCH -e /cluster/work/users/xiejp/TP5prof_%J.err
## How long job takes, wallclock time hh:mm:ss
#SBATCH -t 12:00:00

# set up job environment
set -e # exit on error
set -u # exit on unset variables

Jdy1=26300
Jdy2=26360

Jdy1=26934
Jdy2=26966

Ncore=10

(( Delt = ${Jdy2} - ${Jdy1} ))
if [ ${Delt} -lt ${Ncore} ]; then
   Ncore=${Delt}
fi


(( Nmem= ( ${Jdy2} -${Jdy1} + 1 ) / ${Ncore} + 1 ))
echo $Ncore '~' $Nmem

Inidir='/cluster/home/xiejp/REANALYSIS_TP5/preobs_scripts'
Rundir='/cluster/work/users/xiejp/TP5_Reanalysis/preobs/profile_sr'
[ ! -r ${Rundir} ] && mkdir ${Rundir}


for icore in `seq ${Ncore}`; do
   cd ${Rundir}
   (( J1 =  ( ${icore} - 1 ) * ${Nmem} + ${Jdy1} - 1 ))
   (( J2 =  ${Nmem} + ${J1} - 1))
   [ $J1 -gt ${Jdy2} ] && continue
   if [ $J2 -gt ${Jdy2} ]; then
      (( J2 = Jdy2 ))
   fi
   echo $J1 '~' $J2
   Fsub=Prof_${icore}
   [ -r ${Fsub} ] && rm -rf ${Fsub}
   mkdir ${Fsub}

   cd ${Fsub}
   cat ${Inidir}/do_cmems_profile.mal |\
      sed "s/Jdate1/${J1}/" |\
      sed "s/Jdate2/${J2}/g"\
      > do_${J1}.sh
   chmod +x do_${J1}.sh
   #srun -N1 -n1 ./do_${J1}.sh 
   ./do_${J1}.sh  > out.log & 
done
wait
exit $?
