# Usage: auto-detection the ensemble of analyszed model states in Hhycom_CICE
#
# The filename format should be like: 
#         restart.2021_011_00_0000_mem011.a and iced.2021-01-25-00000_mem046.nc
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
   Adir='/cluster/work/users/xiejp/TP5_Reanalysis/TOBACKUP'
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
   if [ -s ./$ii ]; then
      echo 
      echo $ii
      #kk=$(datetojul ${ii:5:4} ${ii:10:2} ${ii:13:2} ${ii:5:4} 1 0|tail -4c) 
      #jj=restart.${ii:5:4}_${ii}_00_0000_mem001
      Fini=${Odir}/TP5_Fore_${ii}.tgz
      if [ ! -s ${Fini} -a -s ./${ii} -a $kk -lt 25 ]; then
         (( kk = kk + 1 ))
         echo "compressing ${Fini} "
         echo " ... "
         tar -czvf ${Fini} ./${ii}/* > ../Fore_${ii}.log 
      fi
      
   fi
done


