
Mdir=/cluster/home/xiejp/REANALYSIS_TP5/FILES

ln -sf ${Mdir}/blkdat.input
ln -sf ${Mdir}/regional.* .
ln -sf ${Mdir}/grid.info .
ln -sf ${Mdir}/depths*.uf .
ln -sf ${Mdir}/meanssh*.uf .
ln -sf ${Mdir}/re_sla.nc re_sla.nc 

if [ ! -s ./prep_obs ]; then
  ln -sf /cluster/home/xiejp/enkf/EnKF-MPI-TOPAZ/Prep_Fram/prep_obs .
else
  rm ./prep_obs
  ln -sf /cluster/home/xiejp/enkf/EnKF-MPI-TOPAZ/Prep_Fram/prep_obs prep_obs
fi

Idir=/cluster/home/xiejp/REANALYSIS_TP5/preobs_scripts/Infile/

Odir_dt=./weekly
Odir_nrt=./nrt_weekly

Pobsdir=/cluster/work/users/xiejp/work_2024/Data_TP5/TSLA
if [ ! -s ${Pobsdir} ]; then
  mkdir ${Pobsdir}
fi


Jdy0=15650
Jdy1=27331


#Satn="al alg c2 c2n e2 en enn g2 h2a h2ag h2b j2 j2g j2n j3 s3a s3b"
Satn="al alg c2 c2n h2 h2b h2c h2g h2ag j2 j2g j2n j3 j3n s3a s3b s6b"

# Full tsla data
Satn="al alg c2 c2n e1 e1g e2 en enn g2 h2 h2a h2b h2c h2g h2ag j1 j1g j1n j2 j2g j2n j3 j3n s3a s3b s6a swon swonc s6a tp tpn"


for jday in `seq ${Jdy0} ${Jdy1}`; do
  rm observations*
  rm observations*
  if [ ${jday} -gt 27360 ]; then
     Odir=${Odir_nrt} 
  else
     Odir=${Odir_dt} 
  fi
  if [ ! -s ${Pobsdir}/obs_TSLA_${jday}.nc -o ! -s ${Pobsdir}/obs_TSLA_${jday}.uf ]; then
     ifile=0
     for isat in ${Satn}; do
        Fnam=sla_${jday}_${isat}.nc
        if [ -r ${Odir}/${Fnam} ]; then
           ln -sf ${Odir}/${Fnam} .
           let ifile=ifile+1
        fi
     done
     if [ ${ifile} -gt 0 ]; then
        sed "s/JULDDATE/${jday}/" ${Idir}/infile.data_tslaMYO > infile.data

        ./prep_obs TSLA 1 

        if [ -s observations.uf -a -s observations-TSLA.nc ]; then
           mv observations.uf ${Pobsdir}/obs_TSLA_${jday}.uf
           mv observations-TSLA.nc ${Pobsdir}/obs_TSLA_${jday}.nc
           rm sla_${jday}_*.nc
        fi
     fi

   fi  
done
