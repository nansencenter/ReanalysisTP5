#!/bin/bash

# File: propagate.sh
# Author : Pavel Sakov; used original code by Francois Counillon
# Updated by Jiping Xie for TP5 in March 2022 
#
# Description:
#   This is a prototype of a top level script for propagation in TOPAZ4
#   reanalysis.
#
#   This procedure is supposed to be called from main.sh. Otherwise your
#   propagation_specs.sh may be outdated. If ran as a standalone script, it
#   should be launched from the directory one level up from here.
#
set -e # exit on error
set -u # exit on unset variables
set -p # nothing is inherited from the shell
#set -x    # debuging

MONITORINTERVAL=10 # time interval for periodic checks on job status
MONITORINTERVAL2=300
LAUNCHINTERVAL=3 # time interval for launching parallel jobs

nre=0 # number of members repropagated
Fdd=7
#
# 1. Read and report specifications for the assimilation
#
echo "1. Reading specifications:"
. ./propagation_specs.sh
export MODELDIR BINDIR ENSSIZE IPERT PPERT BACKUPBUFDIR 

echo ${BINDIR} " ens.size = " ${ENSSIZE}" fore.days = "${Fdd}

year1=`jultodate $JULDAY 1950 1 1 | cut -c1-4`
day0=`datetojul ${year1} 1 0 1950 1 1`
day1=`expr ${JULDAY} - ${day0}` 
if [ ${day1} -lt 1 ]; then
   echo "Model date is wrong for hycom_cice"
   stop
fi

(( day2 = ${day1} + ${Fdd} ))
year2=`jultodate $day2 $year1 1 0 | cut -c1-4`
if [ ${year2} -gt ${year1} ]; then
   tmp1=$(datetojul $year1 12 31 $year1 1 0 | tail -4c)
   (( day2 = $day2 - $tmp1 ))
fi

#(( tmp1 = ${JULDAY} + ${Fdd} ))
#tmp2=$(datetojul $year2 1 1 1950 1 1)
#if [ $tmp1 -eq $tmp2 ]; then
#  day2=0
#else
  # existing a dug if day2 equal 0
#(( day2 = ${JULDAY} + ${Fdd} - `datetojul $year2 1 1 1950 1 1` ))
#fi

#day1=`expr ${JULDAY} - ${day0} + 1` 
#
#echo $day0 $day1
#
#(( day2 = ${day1} + ${Fdd} ))
#year2=`jultodate $day2 $year1 1 1 | cut -c1-4`
#
#
#echo $year1 $year2
#
#if [ $year2 -gt $year1 ]; then
#  day_0=`datetojul ${year2} 1 1 1950 1 1`
#  echo $day_0 $day0 $day2
#  #(( day2 = ${day2} + ${day0} -${day_0} )) 
#  day2 =$(( ${day2} + ${day0} -${day_0} )) 
#  if [ "$day2" -eq 0 ]; then
#     echo "date:000"
#  fi
#   echo $day2
#fi

day_1=`echo 00$day1 | tail -4c`
day_2=`echo 00$day2 | tail -4c`

echo "   Going to propagate ensemble from day ${day_1} of ${year1} to day ${day_2} of ${year2}"

# PS 17042012 - introduced RESTART to make it easier ... to restart
#RESTART=`find ${MODELDIR}/SCRATCH -name ${HYCOMPREFIX}restart${year2}_${day2}_00_mem???.a | wc -l`
RESTART=`find ${MODELDIR}/SCRATCH -maxdepth 1 -name restart.${year2}_${day_2}_00_0000_mem???.a | wc -l`
RESTART2=`find ${MODELDIR}/data -maxdepth 1 -name restart.${year2}_${day_2}_00_0000_mem???.a | wc -l`
RESTART3=`find ${MODELDIR}/mem???/data -maxdepth 1 -name restart.${year2}_${day_2}_00_0000.a | wc -l`

echo "   "`date`
echo "2. define the start and end date for the model run: "
if [ ${day1} -gt 1 ]; then
   (( day0 = $day1 - 1 ))
else
   day0=0 
fi
tmpstr=`jultodate ${day0} ${year1} 1 1 | cut -c1-8`
strdate1="${tmpstr:0:4}-${tmpstr:4:2}-${tmpstr:6:2}"
echo $day2
if [ ${day2} -gt 1 ]; then
   (( day0 = $day2 - 1 ))
else
   day0=0 
fi
tmpstr=`jultodate $day0 ${year2} 1 1 | cut -c1-8`
strdate2="${tmpstr:0:4}-${tmpstr:4:2}-${tmpstr:6:2}"
echo "      " ${strdate1}  ' ~ ' ${strdate2}
echo "      " ${year1}_${day_1}  ' ~ ' ${year2}_${day_2}

if [ ${RESTART} == 0 -a ${RESTART2} == 0 ]
then

    ./SCRIPTS/check_directories.sh

    #
    # 2. Generate forcing
    #
    if [ ${RESTART3} == 0 ]; then
       # first attempt to run the ensemble 
       istep=1
    else
       # more attempt to run the ensemble 
       istep=0
    fi
    # first attempt to run the ensemble 
    if [ ${istep} -eq 1 ]; then  
       echo "   "`date`
       echo "Generating forcing and prepare the integration under the main directory:"

       # setting files for main SCRATCH
       # ice_in & blkdat.input
       [ -s ${MODELDIR}/ice_in ] && rm ${MODELDIR}/ice_in  
       [ -s ${MODELDIR}/hycom_opt ] && rm ${MODELDIR}/hycom_opt
       [ -s ${MODELDIR}/blkdat.input ] && rm ${MODELDIR}/blkdat.input

       cp ./FILES/hycom_opt_SICAP ${MODELDIR}/hycom_opt

       [ -s ./FILES/ice_in ] && rm ./FILES/ice_in
       [ -s ./FILES/blkdat.input ] && rm ./FILES/blkdat.input

       echo "debuging ..."
       echo $(pwd)
       if [ $PPERT -lt 1 ]; then
          ln -sf ./ice_in_V22 ./FILES/ice_in
          cp ./FILES/ice_in ${MODELDIR}/ice_in
          cp ./FILES/hycom_opt_Reana ${MODELDIR}/hycom_opt
       else
          ln -sf ./ice_in_Reana ./FILES/ice_in
          cp ./FILES/ice_in ${MODELDIR}/ice_in

          if [ $PPERT -eq 1 ]; then  # used for Reanalysis
             [ -s ./FILES/blkdat.input_Reana ] && { ln -sf ./blkdat.input_Reana ./FILES/blkdat.input; cp ./FILES/blkdat.input ${MODELDIR}/.; }
             echo " create the perturbed ice parameters ... "
	     echo ${strdate1}
	     cd ${MODELDIR}/SCRATCH
             Iceprg=${BINDIR}/Reana_icepara.sh
             echo " ${Iceprg} ${ENSSIZE} ${strdate1} ${BINDIR} ${MODELDIR}/SCRATCH"
             ${Iceprg} ${ENSSIZE} ${strdate1} ${BINDIR} ${MODELDIR}/SCRATCH
             mv ${MODELDIR}/SCRATCH/icep.${strdate1}_mem*.nc ${MODELDIR}/data/cice/.
             cd -
	  else
             [ -s ./FILES/blkdat.input_SICAP ] && { ln -sf ./blkdat.input_SICAP ./FILES/blkdat.input; cp ./FILES/blkdat.input ${MODELDIR}/.; }
             echo " Check the parameter ensemble ... "
	     echo ${strdate1}
             echo "${ENSSIZE} ${strdate2} ${BINDIR} ${MODELDIR}/SCRATCH"
	     Nline=$(ls ${MODELDIR}/data/cice/icep.${strdate1}_mem*.nc | sed -n '$=')
	     if [ ${Nline} -lt ${ENSSIZE} ]; then
	        echo "missing the icep files."
	        echo "stop  $0"
	        exit 0 
	     else
	        echo "The icep files are ready."
	     fi	     
	  fi
       fi


       [ -r ${MODELDIR}/preprocess_mem_new.sh ] && rm ${MODELDIR}/preprocess_mem_new.sh 
       cat ${CWD}/SCRIPTS/preprocess_mem.in |\
         sed "s/YDATE1/${strdate1}/" | sed "s/YDATE2/${strdate2}/" |\
         sed "s#FileDir#${CWD}/FILES#" |\
         sed "s#BINDIR#${BINDIR}#g" > ${MODELDIR}/preprocess_mem_new.sh

       # insert two lines for IPERT/PPERT 
       mapfile -t Aline < <(tail -n 2 ../common_specs.sh)
       cd ${MODELDIR}
       awk -v n=6 -v s=${Aline[0]} 'NR == n {print s} {print}' preprocess_mem_new.sh > 6.out
       awk -v n=7 -v s=${Aline[1]} 'NR == n {print s} {print}' 6.out > 7.out
       if [ -s 7.out ]; then
          mv 7.out preprocess_mem_new.sh
	  rm 6.out
       fi
       rm -rf log/*
       chmod +x preprocess_mem_new.sh
       ./preprocess_mem_new.sh 1 ${ENSSIZE} 0 > log/forcing_ini_${JULDAY}.log
    fi

    cd ${MODELDIR}
    echo $(pwd)
    #
    # 3. Launch the jobs
    #
    if [ ${RESTART3} == 0 ]; then
       echo "3. Launching the batch jobs:"
       echo "   "`date`
       cd ${MODELDIR}
       NN=7   # how many members in one batch 
       #NN=6   # how many members in one batch 
       #NN=5   # how many members in one batch 
       #NN=13      # how many members in one batch 
       (( NHYCOM = ($ENSSIZE - 1) / $NN + 1 ))
       for (( proc = 0; proc < $NHYCOM; ++proc ))
         do
         (( ESTART = $proc * $NN + 1 ))
         (( EEND = ($proc + 1) * $NN ))
         if (( $EEND > $ENSSIZE ))
           then
             EEND=$ENSSIZE
	 fi

	 #cat ${CWD}/SCRIPTS/sr_ensemble_batch.in |\
	 cat ${CWD}/SCRIPTS/sr_ensemble_aline.in |\
           sed "s/MEM1/${ESTART}/" |\
           sed "s/MEM2/${EEND}/" |\
	   sed "s/JNAME/${proc}/g" \
           > sr_hycombatch${proc}.sh 

         jobid[$proc]=`sbatch sr_hycombatch${proc}.sh ${ESTART} ${EEND} ${year2}_${day_2} | awk '{print $4}'`
         echo "   ${proc}: ${jobid[$proc]}: propagate members ${ESTART} - ${EEND}"
         sleep ${LAUNCHINTERVAL}
       done
       echo "   (launched)"

      #
      # 3.1. Wait until all jobs finished
      #
      echo -n "   now waiting for all HYCOM batch-jobs to finish:"
      imontor=0
      finished=0
      while (( ! finished ))
        do
          finished=1
          for (( proc = 0; proc < ${NHYCOM}; ++proc ))
            do
            if [ -z "${jobid[$proc]}" ]
              then
              continue
            fi
            answer=`squeue --job ${jobid[$proc]} 2>/dev/null | tail -1 | awk '{print $5}'`
	    #(( imontor = imontor + 1 ))
	    ((imontor+=1))
	    if [ ${imontor} -lt 4 ]; then
               sleep ${MONITORINTERVAL2}
	    else
               sleep ${MONITORINTERVAL}
	    fi
            echo ${jobid[$proc]}
            if [ -z "${answer}" -o "${answer}" == "ST" ] ; then
               if [ "${answer}" == "CG" ]; then
                  echo -n "."
                  finished=0
               else
                  jobid[$proc]=
                  echo -n ".${proc}"
               fi
            else
               echo -n "."
               finished=0
	       if [ ${imontor} -lt 3 ]; then
                  sleep ${MONITORINTERVAL2}
	       else
                  sleep ${MONITORINTERVAL}
	       fi
            fi
          done
      done
      echo "   "`date`
      echo -n "   4. checking that all members are ready, if not submitting jobs one by one:"
    else
      echo -n "   3. checking that all members are ready, if not submitting jobs one by one:"
    fi

    nbad=0
    for  (( e = 1; e <= ${ENSSIZE}; ++e ))
      do
        mem=`printf "%03d\n" ${e}`
        echo " member " ${mem}
        if [ ! -s ${MODELDIR}/mem${mem}/data ]; then
          RESTARTmem=0
          if [ -s ${MODELDIR}/mem${mem}/SCRATCH ]; then
             RESTARTmem=`find ${MODELDIR}/mem${mem}/SCRATCH -name restart.${year2}_${day_2}_00_0000.a | wc -l`
             echo ${RESTARTmem}
             if (( ${RESTARTmem} != 0 )); then
                mkdir ${MODELDIR}/mem${mem}/data
                mkdir ${MODELDIR}/mem${mem}/data/cice
                mv ${MODELDIR}/mem${mem}/SCRATCH/restart.${year2}*_00_0000.? ${MODELDIR}/mem${mem}/data/.
                mv ${MODELDIR}/mem${mem}/SCRATCH/archm.*_12.? ${MODELDIR}/mem${mem}/data/.
                mv ${MODELDIR}/mem${mem}/SCRATCH/cice/iced.*-*-00000.nc ${MODELDIR}/mem${mem}/data/cice/.
                mv ${MODELDIR}/mem${mem}/SCRATCH/cice/iceh.*-??-??.nc ${MODELDIR}/mem${mem}/data/cice/.
             fi
          fi
        else
          RESTARTmem=`find ${MODELDIR}/mem${mem}/data -name restart.${year2}_${day_2}_00_0000.a | wc -l`
        fi
        if (( ${RESTARTmem} == 0 )); then
           cd ${MODELDIR}
           echo "     member ${e} is missing; relaunching"
           if (( ${nbad} == 0 )); then
	      echo ""
           fi
           cat ${CWD}/SCRIPTS/sr_ensemble_one.in |\
             sed "s/MEM1/${e}/" |\
             sed "s/MEM2/${e}/" |\
             sed "s/BJNAME/_H${nbad}/" |\
             sed "s/JNAME/H${nbad}/g" \
             > sr_hycom_${nbad}.sh 
           jobid[$nbad]=`sbatch sr_hycom_${nbad}.sh ${e} ${e} ${year2}_${day_2} | awk '{print $4}'`
           echo "   ${nbad}: ${jobid[$nbad]}: re-propagate member ${e}"
           (( nbad += 1 ))
           (( nre += 1 ))
           sleep ${LAUNCHINTERVAL}
        fi
    done

    if (( ${nbad} == 0 ))
    then
       echo " OK"
    else
       echo -n "   now waiting for all HYCOM jobs to finish:"
       imontor=0
       finished=0
       while (( ! finished ))
         do
           finished=1
	   for (( proc = 0; proc < ${nbad}; ++proc ))
	     do
	       [ -z "${jobid[$proc]}" ] && continue
               answer=`squeue --job ${jobid[$proc]} 2>/dev/null | tail -1 | awk '{print $5}'`
	       ((imontor+=1))
	       if [ ${imontor} -lt 2 ]; then
                  sleep ${MONITORINTERVAL2}
	       else
                  sleep ${MONITORINTERVAL}
	       fi
               echo ${jobid[$proc]}
               while [ -n "${answer}" -a "${answer}" != "ST" ]; do
                 echo -n "." 
	         if [ ${imontor} -lt 2 ]; then
                    sleep ${MONITORINTERVAL2}
	         else
                    sleep ${MONITORINTERVAL}
	         fi
                 answer=`squeue --job ${jobid[$proc]} 2>/dev/null | tail -1 | awk '{print $5}'`
                 if [ -r break.out ]; then
                    answer="ST"     
                    echo " exit!"
                    exit
                 fi
               done
            done
       done
       echo ".done"
       echo -n "   checking that all HYCOM jobs have succeeded:"
       nbad=0
       for  (( e = 1; e <= ${ENSSIZE}; ++e ))
         do
	   mem=`printf "%03d\n" ${e}`
           cd ${MODELDIR}/mem${mem}/data
           if [ ! -f "restart.${year2}_${day_2}_00_0000.a" -o ! -f "restart.${year2}_${day_2}_00_0000.b" ] 
	     then
	       if (( ${nbad} == 0 ))
	         then
		   echo ""
	       fi
	       echo "ERROR: member ${e} is missing after second propagation attempt; bailing out"
	       exit 1
	   fi
       done
       echo " OK"

    fi

fi


if [ ${RESTART2} != ${ENSSIZE} ]; then

#
# 5.  now postprocessing include daily average, restart, and iced named as the required
#
echo -n "5. now preparing daily averages"
cd ${MODELDIR}

icepdrt=${BACKUPBUFDIR}/${JULDAY}/FORECAST
cat ${CWD}/SCRIPTS/sr_ensemble_post.in |\
    sed "s/JNAME/${year2}_${day_2}/" |\
    sed "s#BACKDIR#${icepdrt}#" |\
    sed "s#PROPDIR#${CWD}#g" \
    > sr_hycave_daily.sh


jobid_ave=`sbatch sr_hycave_daily.sh 1 ${ENSSIZE} | awk '{print $4}'`
sleep ${LAUNCHINTERVAL}
answer=`squeue --job ${jobid_ave} 2>/dev/null | tail -1 | awk '{print $5}'`
echo ${jobid_ave}
imontor=0
while [ -n "${answer}" -a "${answer}" != "ST" ]; do
   ((imontor+=1))
   if [ ${imontor} -lt 2 ]; then
      sleep ${MONITORINTERVAL2}
   else
      sleep ${MONITORINTERVAL}
   fi
   answer=`squeue --job ${jobid_ave} 2>/dev/null | tail -1 | awk '{print $5}'`
   echo -n "."
   if [ -r break.out ]; then
      answer="ST"     
      echo " exit!"
      exit
   fi
done
echo " done hycave!"


#
# 6. Check the complet of the last assimilation cycle 
#
echo -n "6.  check that creating archives (marched with assimilate.sh) has finished:"

jobid_clean2=`squeue |grep xiejp |grep en_clean2 |tail -1 |awk '{print $1}'`
if [ -n "${jobid_clean2}" ]; then
  answer=`squeue --job ${jobid_clean2} 2>/dev/null | tail -1 | awk '{print $5}'`
  sleep ${MONITORINTERVAL}
  while [ -n "${answer}" -a "${answer}" != "ST" ]
  do
      answer=`squeue --job ${jobid_clean2} 2>/dev/null | tail -1 | awk '{print $5}'`
      echo -n "."
      sleep ${MONITORINTERVAL}
  done
fi

#
# 7. Clean up
#
echo "7. Cleaning up:"
echo "   "`date`

# this final clean up / archiving continues for some time after assimlate.sh 
# finishes; we need to have the log as sometimes strange things happen
#
if stat -t ${ANALYSISDIR}/enkf_clean2.* > /dev/null 2>&1
then
    cp -f ${ANALYSISDIR}/enkf_clean2.* ${RESULTSDIR}/${JULDAY}/LOG
    chmod -R a+r+X ${RESULTSDIR}/${JULDAY}
fi

cd ${MODELDIR}
rm -f sr_hycom*.sh
#rm -f sr_hycave_daily.sh
#rm -f ${FORECASTDIR}/restart.${year1}_${day1}*
#rm -f ${FORECASTDIR}/cice/iced.${strdate1}-*_mem*.nc

#rm ${MODELDIR}/SCRATCH/arch*.?
#rm ${MODELDIR}/SCRATCH/restart.*.[ab]
#rm ${MODELDIR}/SCRATCH/forcing.*.[ab]
#rm ${MODELDIR}/SCRATCH/*
#rm ${MODELDIR}/SCRATCH/cice/*
#rm ${MODELDIR}/SCRATCH/KEEP/*

#set +e
#mv ${MODELDIR}/SCRATCH/${HYCOMPREFIX}AVE* -t ${FORECASTDIR}
#set -e
#mv ${MODELDIR}/SCRATCH/${HYCOMPREFIX}DAILY* -t ${FORECASTDIR}
#mv ${MODELDIR}/SCRATCH/${HYCOMPREFIX}restart${year2}_${day2}* -t ${FORECASTDIR}
mv ${MODELDIR}/log/* -t ${RESULTSDIR}/${JULDAY}/LOG
echo
echo "PROPAGATION FINISHED for day ${JULDAY}, time = "`date`", nre = ${nre}"

else
  echo
  echo "Restarts are accessible for day ${JULDAY}, time = "`date`", nre = ${nre}"

fi
