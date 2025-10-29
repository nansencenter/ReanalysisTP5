
Rundir=$(pwd)

HomeAdir=/cluster/home/xiejp/REANALYSIS_TP5/
#Modir=/cluster/home/xiejp/REANALYSIS/FILES
Modir=${HomeAdir}/FILES
ln -sf ${Modir}/blkdat.input
ln -sf ${Modir}/regional.* .
ln -sf ${Modir}/grid.info .
ln -sf ${Modir}/depths*.uf .
ln -sf ${Modir}/meanssh.uf .
#ln -sf ${Modir}/re_sla.nc .

Idir=${HomeAdir}/PREOBS/Infile/

Odir_dt=/cluster/work/users/xiejp/DATA/data0/sst
Odir_nrt=/cluster/work/users/xiejp/DATA/data0/sst_nrt

Outdir0=/cluster/work/users/xiejp/work_2024/Data_TP5
Outdir=${Outdir0}/SST
if [ ! -s ${Outdir} ]; then
  mkdir ${Outdir}
fi

cd ${Rundir}

if [ ! -s ./prep_obs ]; then
  #ln -sf /cluster/home/xiejp/enkf/EnKF-MPI-TOPAZ5/Prep_Fram/prep_obs .
  ln -sf /cluster/home/xiejp/enkf/EnKF-MPI-TOPAZ/Prep_Fram/prep_obs .
fi

Jdy0=$(datetojul 1992 12 15 1950 1 1)
Jdy0=$(datetojul 2015  9  17 1950 1 1)
#Jdy0=$(datetojul 2020 12 1 1950 1 1)

Jdy1=$(datetojul 2024 12 31 1950 1 1)



#Strn1="depth-OSTIA-GLOB_ICDR2.1-v02.0-fv01.0.nc"
Strn1="depth-OSTIA-GLOB_CDR2.1-v02.0-fv01.0.nc"
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
    #Fini=${Sdate:0:8}120000-C3S-L4_GHRSST-SST${Strn1}
    if [ $Ny -le 2016 ]; then
       Fini=${Sdate:0:8}120000-ESACCI-L4_GHRSST-SST${Strn1}
       iflg=2
    elif [ $Ny -gt 2021 ]; then
#   20221229120000-C3S2-L4_GHRSST-SSTdepth-ISTskin-DMIOI-GLOB_ICDR1.0-v02.0-fv01.0.nc
       Fini=${Sdate:0:8}120000-C3S2-L4_GHRSST-SSTdepth-ISTskin-DMIOI-GLOB_ICDR1.0-v02.0-fv01.0.nc
       iflg=3
    else	    
#   20171231120000-C3S2-L4_GHRSST-SSTdepth-ISTskin-DMIOI-GLOB_CDR1.0-v02.0-fv01.0.nc
       Fini=${Sdate:0:8}120000-C3S2-L4_GHRSST-SSTdepth-ISTskin-DMIOI-GLOB_CDR1.0-v02.0-fv01.0.nc
       iflg=3
    fi
    if [ -s ${Odir_dt}/${Ny}/${Fini} ]; then
       echo ${Fini}
       ln -sf ${Odir_dt}/${Ny}/${Fini} ${Jdy}_sst.nc 
       ./prep_obs SST ${iflg}
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
       iflg=1
       echo "${Odir_nrt}/${Ny}/${Fini}"
       if [ -s ${Odir_nrt}/${Ny}/${Fini} ]; then
          echo ${Fini}
          ln -sf ${Odir_nrt}/${Ny}/${Fini} ${Jdy}_sst.nc 
          ./prep_obs SST ${iflg}
          if [ -s observations-SST.nc -a observations.uf ]; then
             mv observations-SST.nc ${Outdir}/${Fnc}
             mv observations.uf ${Outdir}/${Fuf}
             rm ${Jdy}_sst.nc
          fi 
       fi
    fi
  fi
done

