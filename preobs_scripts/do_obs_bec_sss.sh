HomeAdir=/cluster/home/xiejp/REANALYSIS_TP5/

Rundir=$(pwd)

#Modir=/cluster/home/xiejp/REANALYSIS/FILES
Modir=${HomeAdir}/FILES
ln -sf ${Modir}/blkdat.input
ln -sf ${Modir}/regional.* .
ln -sf ${Modir}/grid.info .
ln -sf ${Modir}/depths*.uf .
ln -sf ${Modir}/meanssh.uf .

Idir=${HomeAdir}/preobs_scripts/Infile/


Odir=/cluster/work/users/xiejp/work_2024/Data_TP5/SSS
if [ ! -s ${Odir} ]; then
  mkdir ${Odir}
fi

[ -s ./prep_obs ] && rm ./prep_obs

if [ ! -s ./prep_obs ]; then
  ln -sf /cluster/home/xiejp/enkf/EnKF-MPI-TOPAZ4/Prep_Fram/prep_obs_hice prep_obs 
fi
Odir0=./data0


Jdy0=25933
Jdy1=26663

#  "BEC_OACOR_B_20120308_025_001.nc"

ilink=0
if [ $ilink -eq 1 ]; then
  [ ! -r data0 ] && mkdir data0
  #Obsdir0='/cluster/work/users/xiejp/DATA/data0/sss_BEC3/L3/9-days/'
  Obsdir0='/cluster/work/users/xiejp/DATA/data0/sss/'
  #Fprefix='BEC-L3-SSS-ARCTIC-025km-'
  Fprefix='BEC-L3-SSS-ARCTIC-025km-'
  for Jdy in `seq ${Jdy0} ${Jdy1}`; do
     (( idy = Jdy - 8 ))
     Sdate0=$(jultodate ${idy} 1950 1 1)
     Sdate1=$(jultodate ${Jdy} 1950 1 1)
     Fprefix=${Obsdir0}${Sdate1:0:4}/'BEC_SSS___SMOS__ARC_L3__B_'
     Fnc0=${Fprefix}${Sdate1:0:8}T120000_25km__9d_REP_v4.0.nc 
     echo ${Fnc0}
     if [ -s ${Fnc0} ]; then
       #ln -sf ${Obsdir0}${Fnc0} ./data0/BEC_SSS_V301_${Jdy}.nc
       ln -sf ${Fnc0} ./data0/BEC_SSS_V4_${Jdy}.nc
     fi
  done
fi


for Jdy in `seq ${Jdy0} ${Jdy1}`; do
  #let Jdy0=Jdy-5
  let Jdy0=Jdy
  Sdate=`jultodate ${Jdy0} 1950 1 1`
#  Ny=`echo ${Sdate:0:4}` #  Nm=`echo ${Sdate:4:2}`
#  Nd=`echo ${Sdate:6:2}`
  echo ${Ny} ${Nm} ${Nd}
  Fnc=obs_SSS_${Jdy}.nc
  Fuf=obs_SSS_${Jdy}.uf
  if [ ! -s ${Odir}/${Fnc} ]; then
    sed "s/JULDDATE/${Jdy}/" ${Idir}/infile.data_bec > infile.data
    #Fini=BEC_OACOR_B_${Sdate:0:8}_025_001.nc
    Fini=BEC_SSS_V4_${Jdy0}.nc
    if [ -s ./data0/${Fini} ]; then
      ln -sf ./data0/${Fini} ${Jdy}_sss.nc 
      ./prep_obs
      if [ -s observations-SSS.nc -a observations.uf ]; then
         mv observations-SSS.nc ${Odir}/${Fnc}
         mv observations.uf ${Odir}/${Fuf}
      fi 
      rm ${Jdy}_sss.nc
    fi
  fi
done

