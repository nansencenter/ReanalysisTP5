# Usage: auto-detection the ensemble of analyszed model states in Hhycom_CICE
#
# ~ $Yr $Adir $Odir
#  
# Input requires: 
#     Adir-the source file diretory
#     Odir-the target file diretory
#     Yr-the expected year
#
# Created by JP on 1st Aug 2024
#
if [ ! $# -eq 3 -a ! $# -eq 1 ]; then
   echo "Usage:"
   echo "    ~ <Yr> <Adir> <Odir>"
   echo " Or "
   echo "    ~ <Yr>"
   exit 0
elif [ $# -eq 3 ]; then
   Adir=$2
   Odir=$3
else
   Adir='/cluster/work/users/xiejp/TP5_Reanalysis'
   Odir='/cluster/work/users/xiejp/TP5_Reanalysis/tardir'
fi
Yr=$1
if [ $Yr -lt 1900 -o $Yr -gt 2050 ]; then
   echo "Wrong input Yr: "$Yr
   #echo "1900~2050"
   exit 1
fi
if [ ! -s $Adir -o ! -s $Odir ]; then
   echo "Wrong input directories: " $Adir " or " $Odir
   exit 1
fi

# check the potential tar file numbers
cd ${Adir}

ik=0
J1=$(datetojul ${Yr} 1 1 1950 1 1)
(( Yr1 = Yr + 1 ))
J2=$(datetojul ${Yr1} 1 1 1950 1 1)

#for ii in $(ls iced.$Yr*mem001.nc); do
kk=0
for ii in `seq ${J1} ${J2}`; do
   cd ${Adir}
   if [ -s ./RESULTS/${ii} -a -s ./OUTPUT/${ii} ]; then
      echo 
      echo $ii
      #kk=$(datetojul ${ii:5:4} ${ii:10:2} ${ii:13:2} ${ii:5:4} 1 0|tail -4c) 
      #jj=restart.${ii:5:4}_${ii}_00_0000_mem001
      Fini=${Odir}/TP5_Out_${ii}.tgz
      Fini1=${Odir}/TP5_Result_${ii}.tgz
      if [ ! -s ${Fini} -a ! -s ./${Fini1} -a $kk -lt 25 ]; then
         (( kk = kk + 1 ))
         echo "compressing ${Fini} "
         echo " ... "
         tar -czvf ${Fini1} ${Adir}/RESULTS/${ii}/* > R${ii}.log 
         tar -czvf ${Fini} ${Adir}/OUTPUT/${ii}/* > O${ii}.log 
      fi
      
   fi
done


