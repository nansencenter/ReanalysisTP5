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
   Adir='/cluster/work/users/xiejp/TP5_Reanalysis/TOBACKUP/ANALYSIS'
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
for ii in $(ls iced.$Yr*mem001.nc); do
   cd ${Adir}
   if [ -s $ii ]; then
      echo 
      echo $ii
      kk=$(datetojul ${ii:5:4} ${ii:10:2} ${ii:13:2} ${ii:5:4} 1 0|tail -4c) 
      jj=restart.${ii:5:4}_${kk}_00_0000_mem001
      Fini=${Odir}/TP5_Analy_${ii:5:4}_${kk}.tgz
      if [ -s ${jj}.a -a -s ${jj}.b -a ! -s ${Fini} -a $ik -lt 6 ]; then
         echo "compressing ${Fini} "
         echo " ... "
         ss=${ii:5:4}_${kk}
         [ -r $ss ] && rm -rf $ss
         mkdir $ss
         mv ${ii%mem*}mem???.nc ${ss}/.
         mv ${jj%mem*}mem???.? ${ss}/.
         cd ${ss}
         tar -czvf ${Fini} *mem* > ../${ss}.log 
      fi
      
   fi
done


