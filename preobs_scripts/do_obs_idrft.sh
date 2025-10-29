
Mdir=/cluster/home/xiejp/REANALYSIS_TP5/FILES

ln -sf ${Mdir}/blkdat.input
ln -sf ${Mdir}/regional.* .
ln -sf ${Mdir}/grid.info .
ln -sf ${Mdir}/depths*.uf .
ln -sf ${Mdir}/meanssh*.uf .
ln -sf ${Mdir}/re_sla.nc .

Idir=/cluster/home/xiejp/REANALYSIS_TP5/preobs_scripts/Infile/

Odir0=/cluster/work/users/xiejp/DATA/data0/idrft
Outdir=/cluster/work/users/xiejp/work_2024/Data_TP5/IDRFT
if [ ! -s ${Outdir} ]; then
  mkdir ${Outdir}
fi

if [ ! -s ./prep_obs ]; then
  ln -sf /cluster/home/xiejp/enkf/EnKF-MPI-TOPAZ/Prep_Fram/prep_obs .
fi

Jdy0=15630
Jdy1=27570


for Jdy in `seq ${Jdy0} ${Jdy1}`; do
  Sdate=`jultodate ${Jdy} 1950 1 1`
  Ny=`echo ${Sdate:0:4}`
  Nm=`echo ${Sdate:4:2}`
  Nd=`echo ${Sdate:6:2}`

  for ii in `seq 1 5`; do
    let j_dy2=Jdy-ii
    sday1=$(jultodate ${j_dy1} 1950 1 1)
    [ -s idrft_osisaf.hdr ] && rm idrft_osisaf.hdr
    if [ $Ny -gt 2009 ]; then
       let j_dy1=j_dy2-2  # 2 days drift observation:
       sday2=$(jultodate ${j_dy2} 1950 1 1)
       Fnc=${sday2:0:4}/ice_drift_nh_polstere-625_multi-oi_${sday2}1200.nc
       ln -sf ${Idir}/idrft_osisaf.hdr .
    else                  # 24h drift observation:
       let j_dy1=j_dy2-1
       sday2=$(jultodate ${j_dy2} 1950 1 1)
       Fnc=${sday2:0:4}/ice_drift_nh_ease2-750_cdr-v1p0_24h-${sday2}1200.nc
       ln -sf ${Idir}/idrft_osisaf_24h.hdr idrft_osisaf.hdr 
    fi

    if [ -s ${Odir0}/${Fnc} ]; then
      sed "s/JULDDATE/${Jdy}/" ${Idir}/infile.data_idrft_osisaf | sed "s/idrfS/idrf${ii}/" > infile.data
      ln -sf ${Odir0}/${Fnc} ${Jdy}_idrft.nc
      Ffix=${ii}_${Jdy}
      echo ${Fnc} ${Ffix}
      if [ ! -s ${Outdir}/obs_IDRFT${Ffix}.uf ]; then
        ./prep_obs
        if [ -s observations.uf ]; then
          mv observations.uf ${Outdir}/obs_IDRFT${Ffix}.uf
          mv observations-DX${ii}.nc ${Outdir}/obs_DX${Ffix}.nc
          mv observations-DY${ii}.nc ${Outdir}/obs_DY${Ffix}.nc
        fi 
     fi

    #  rm ${Jdy}_idrft.nc
    fi
  done  # end cycle in one date
done

