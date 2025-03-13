#!/bin/bash -l


# useage to calcuate the ensemble mean for daily output in hycom_cice
# So it includes two parts: 1) dealing with hycom daily; 2) dailling with cice daily files

# The rquired inputs: file lists of archm/iceh; the predefined order in these files

if [ $# -lt 5 ]; then
   echo "Wrong input for $?"
   echo "ensemble_mean.sh <HYCOMlist> <CICElist> <DAYorder> <first mem> <last mem>"
   exit 0 
fi
Sourcmd=$0
Sourdir=${Sourcmd/ensemble_mean.sh*/}
Sourdir0=${Sourcmd/BIN*/}
echo 'Source directory:' ${Sourdir}
echo 'Source directory:' ${Sourdir0}

Hycomlist=$1
Cicelist=$2
Dorder=$3
mem1=$4
mem2=$5


# control the quality of files: same size


Fhycom=$(sed -n "${Dorder}p" ${Hycomlist})
Fcice=$(sed -n "${Dorder}p" ${Cicelist})
cmem0=${Fhycom/data*/}
cmem00=${cmem0/mem*/}

# step 1: hycom daily average:
dailybase=archm.$(echo ${Fhycom} | sed "s/.[ab]$//" | sed "s/.*archm.//")
# check the total files
N0=0
Ftemp=hycom_text.${Dorder}
[ -r ${Ftemp} ] && rm ${Ftemp}
touch ${Ftemp}
for imm in `seq ${mem1} ${mem2}`; do
   cmem1=mem`echo 00${imm}|tail -4c`/
   Finia=${cmem00}${Fhycom/${cmem0}/${cmem1}}
   Finib=${Finia:0:end-1}b
   #echo ${Finib}
   if [ -r ${Finia} -a -r ${Finib} ]; then
      (( N0 = N0 + 1 ))
      echo ${Finia} >> ${Ftemp}      
   fi
done
${Sourdir}check_listfiles.sh ${Ftemp}
N0=$(sed -n '$=' ${Ftemp})
if [ $N0 -gt 1 ]; then
   Fmean=meanhycom_${Dorder}.in
   [ -r ${Fmean} ] && rm ${Fmean}
   cat ${Sourdir0}FILES/mean_hycom.in.head | sed "s/NN/${N0}/g"  > ${Fmean} 
   cat ${Ftemp} >> ${Fmean}
   echo "   0     'narchs' = number of archives to read (==0 to end input)" >> ${Fmean}
   echo "${dailybase}" >> ${Fmean}
   echo " ${Sourdir}hycom_mean < ${Fmean}"
   ${Sourdir}hycom_mean < ${Fmean}
   if [ -r ${dailybase}.a -a -r ${dailybase}.b ]; then
      mv ${dailybase}.[ab] ../data/.
   fi
    # prepare the ensemble SSH
   echo "extract the SSH and save to ensemble data (.uf)"
   ${Sourdir}extract2ssh ${N0} ${Fmean}
   [ -s SSH_${Fmean}.uf ] && mv SSH_${Fmean}.uf ../data/${dailybase}_SSH.uf

fi
rm ${Ftemp}

# step 2: cice daily average:
cicebase=iceh.$(echo ${Fcice} | sed "s/.nc$//" | sed "s/.*iceh.//")
# check the total files
N0=0
Ftemp=meancice_${Dorder}.in
[ -r ${Ftemp} ] && rm ${Ftemp}
touch ${Ftemp}
#echo 'cmem0=' ${cmem0}
#echo 'cmem00=' ${cmem00}
for imm in `seq ${mem1} ${mem2}`; do
   cmem1=mem`echo 00${imm}|tail -4c`/
   Fmemnc=${cmem00}${Fcice/${cmem0}/${cmem1}}
   #echo ${Fmemnc}
   [ -r ${Fmemnc} ] && echo ${Fmemnc} >> ${Ftemp}      
done
${Sourdir}check_listfiles.sh ${Ftemp}
N0=$(sed -n '$=' ${Ftemp})

#module load NCO/5.0.3-intel-2021b
# changed at 7th April
#module load NCO/4.9.7-iomkl-2020a

Fmean=out_${Dorder}.nc
if [ $N0 -gt 1 ]; then
  Fice=$(cat ${Ftemp})
  echo ${Fice}
  [ -s ${Fmean} ] && rm ${Fmean}
  echo "ncea ${Fice} ${Fmean}"
  ncea ${Fice} ${Fmean}
  if [ -r ${Fmean} ]; then
     echo "   mv ${Fmean} ../data/cice/"
     mv ${Fmean} ../data/cice/${cicebase}.nc
#  elif [ $N0 -eq 100 ]; then
#     for icyc in `seq 1 10`; do
#        Ftmp=out_${Dorder}_${icyc}.nc
#        (( i1 = 1 + ( $icyc - 1 ) * 10 ))
#        (( i2 = $icyc * 10 ))
#        i0=0
#        for ii in `seq $i1 $i2`; do
#           cmem1=mem`echo 00${ii}|tail -4c`/
#           Fii=${cmem00}${Fcice/${cmem0}/${cmem1}}
#           if [ -s ${Fii} ]; then
#              (( i0 = i0 + 1 ))
#              if [ $i0 -eq 1 ]; then
#                 Fjj=`echo ${Fii}`
#              else
#                 Fjj=`echo ${Fjj} ${Fii}`
#              fi
#           fi
#        done
#        echo '${icyc}: ' ${Fjj}
#
#     done
#
#    
#
  fi
fi

