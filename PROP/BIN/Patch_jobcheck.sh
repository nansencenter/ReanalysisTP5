
# Due to freqenty jobs issue on Betzy
# A patch scirpt checks the statement of the deliver job,
# if it is failed, deleting it and then tries onece time resubmit
#  For example:
#    JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
# 1517783   normal  SICB10   xiejp PD    0:00   4 (launch failed requeued held)
#
#      #echo "sbatch ${jobname} ${mem0} ${mem1} ${Mdate}"
#
if [ $# -ge 5 ]; then
   jobnum=$1
   jobname=$2
   mem0=$3
   mem1=$4
   Mdate=$5
else
   echo ${jobnum}	
   exit 0
fi

ansfirst=`squeue --job ${jobnum} 2>/dev/null | tail -1 | awk '{print $5}'`
if [[ "${ansfirst}" == "PD" ]]; then
   anssecond=`squeue --job ${jobnum} 2>/dev/null | tail -1 | awk '{print $9}'`
   if [[ "${anssecond}" == "failed" ]]; then
      # submit a new one
      jobaa=`sbatch ${jobname} ${mem0} ${mem1} ${Mdate} | awk '{print $4}'`
      echo ${jobaa}
      if [ $# -eq 5 ]; then
         scancel ${jobnum}
      fi
   fi
else
   echo ${jobnum}	
fi
