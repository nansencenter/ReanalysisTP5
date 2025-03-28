HomeAdir=/cluster/home/xiejp/REANALYSIS_TP5/

Rundir=$(pwd)

#Modir=/cluster/home/xiejp/REANALYSIS/FILES
Modir=${HomeAdir}/FILES
ln -sf ${Modir}/blkdat.input
ln -sf ${Modir}/regional.* .
ln -sf ${Modir}/grid.info .
ln -sf ${Modir}/depths*.uf .
ln -sf ${Modir}/meanssh.uf .
#ln -sf ${Modir}/re_sla.nc .

Idir=${HomeAdir}/PREOBS/Infile/

Odir0=/cluster/work/users/xiejp/DATA/data0/sst
Odir2=/cluster/work/users/xiejp/DATA/data0/sst_nrt

Odir=/cluster/work/users/xiejp/work_2024/Data_TP5
cd ${Odir}
if [ ! -s ./SST ]; then
  mkdir SST 
fi
Outdir=${Odir}/SST

cd ${Rundir}

if [ ! -s ./prep_obs ]; then
  #ln -sf /cluster/home/xiejp/enkf/EnKF-MPI-TOPAZ5/Prep_Fram/prep_obs .
  ln -sf /cluster/home/xiejp/enkf/EnKF-MPI-TOPAZ/Prep_Fram/prep_obs .
fi

#Jdy0=$(datetojul 2020 12 1 1950 1 1)
Jdy0=$(datetojul 2022 1 1 1950 1 1)
Jdy1=$(datetojul 2025 1 1 1950 1 1)

#Jdy1=25201
#Jdy1=24837


echo ${Outdir}
Strn1="depth-OSTIA-GLOB_ICDR2.1-v02.0-fv01.0.nc"
Strn2="fnd-OSTIA-GLOB-v02.0-fv02.0.nc"

for Jdy in `seq ${Jdy0} ${Jdy1}`; do
  (( jjdy = Jdy + 1 ))
  Sdate=`jultodate ${Jdy} 1950 1 1`
  Ny=`echo ${Sdate:0:4}`
  Nm=`echo ${Sdate:4:2}`
  Nd=`echo ${Sdate:6:2}`
  echo ${Ny} ${Nm} ${Nd}
  Fnc=obs_SST_${jjdy}.nc
  Fuf=obs_SST_${jjdy}.uf
  echo "${Outdir}/${Fnc}"
  if [ ! -s ${Outdir}/${Fnc} ]; then
    sed "s/JULDDATE/${Jdy}/" ${Idir}/infile.data_ostia > infile.data
    Fini=${Sdate:0:8}120000-C3S-L4_GHRSST-SST${Strn1}
    #Fini=cdr2_sst_${Jdy}.nc
    #echo "${Odir0}/${Ny}/${Fini}"
    if [ -s ${Odir0}/${Ny}/${Fini} ]; then
       echo ${Fini}
       ln -sf ${Odir0}/${Ny}/${Fini} ${Jdy}_sst.nc 
       #./prep_obs
       ./prep_obs_hice
       if [ -s observations-SST.nc -a observations.uf ]; then
          mv observations-SST.nc ${Outdir}/${Fnc}
          mv observations.uf ${Outdir}/${Fuf}
          rm ${Jdy}_sst.nc
       fi 
    else
      if [ ! -s ./prep_obs_nrt ]; then
         ln -sf /cluster/home/xiejp/enkf/EnKF-MPI-TOPAZ/Prep_Fram/prep_obs_nrt .
      fi

       # replaced by nrt observations:
       #Fini=${Sdate:0:8}12-nrt-L4_SST${Strn2}
       Fini=${Sdate:0:8}120000-UKMO-L4_GHRSST-SST${Strn2}
       echo "${Odir2}/${Ny}/${Fini}"
       if [ -s ${Odir2}/${Ny}/${Fini} ]; then
          echo ${Fini}
          ln -sf ${Odir2}/${Ny}/${Fini} ${Jdy}_sst.nc 
          ./prep_obs_nrt
          if [ -s observations-SST.nc -a observations.uf ]; then
             mv observations-SST.nc ${Outdir}/${Fnc}
             mv observations.uf ${Outdir}/${Fuf}
             rm ${Jdy}_sst.nc
          fi 
       fi
    fi
  fi
done

