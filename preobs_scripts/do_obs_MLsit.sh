Mdir=/cluster/home/xiejp/REANALYSIS_TP5/FILES

ln -sf ${Mdir}/blkdat.input
ln -sf ${Mdir}/regional.* .
ln -sf ${Mdir}/grid.info .
ln -sf ${Mdir}/depths*.uf .
ln -sf ${Mdir}/meanssh*.uf .
ln -sf ${Mdir}/re_sla.nc .

Idir=/cluster/home/xiejp/REANALYSIS_TP5/preobs_scripts/

Odir0=/cluster/work/users/xiejp/DATA/data0/sit
Outdir=/cluster/work/users/xiejp/work_2024/Data_TP5/HICE
if [ ! -s ${Outdir} ]; then
  mkdir ${Outdir}
fi

if [ ! -s ./prep_obs ]; then
  ln -sf /cluster/home/xiejp/enkf/EnKF-MPI-TOPAZ/Prep_Fram/prep_obs_hice prep_obs
fi



Jd1=15340
Jd2=22280


for Jdy in `seq ${Jd1} ${Jd2}`; do
  #rm ?????_hice.nc infile.data
  #let Ndy=Jdy-6
  Sdate=`jultodate ${Jdy} 1950 1 1`
  #Fnc="W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_${Sdate0:0:8}_${Sdate:0:8}_r_v205_01_l4sit.nc"   # updated at 6th August 2021
  # ML-based sit in Oct 2025:
  Fnc=SIT_TOPAZ4-ML_${Sdate:0:8}.nc
  echo ${Fnc} ${Jdy}
  if [ -s ${Odir0}/${Sdate:0:4}/${Fnc} -a ! -s ${Outdir}/obs_HICE_${Jdy}.nc ]; then
    sed "s/JULDDATE/${Jdy}/" ${Idir}Infile/infile.data_MLTP4 > infile.data
    echo ${Fnc}
    ln -sf ${Odir0}/${Sdate:0:4}/${Fnc} ${Jdy}_hice.nc
    ./prep_obs
    if [ -s observations-HICE.nc -a observations.uf ]; then
      mv observations-HICE.nc ${Outdir}/obs_HICE_${Jdy}.nc
      mv observations.uf ${Outdir}/obs_HICE_${Jdy}.uf
    fi
  fi
done



