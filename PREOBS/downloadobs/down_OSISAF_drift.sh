
obsnam='idrft'

Rundir='/cluster/work/users/xiejp/DATA/data0'
cd ${Rundir}
[ ! -r ${obsnam} ] && mkdir ${obsnam}
cd ./${obsnam}


#ftp://osisaf.met.no/reprocessed/ice/drift_lr/v1/merged/1991/01/ice_drift_sh_ease2-750_cdr-v1p0_24h-199101311200.nc
Fdirpre='ftp://osisaf.met.no/reprocessed/ice/drift_lr/v1/merged/'
Fdirpre2='ftp://osisaf.met.no/archive/ice/drift_lr/merged/'

#1991/01/ice_drift_sh_ease2-750_cdr-v1p0_24h-199101311200.nc
str0='1991/01/ice_drift_nh_ease2-750_cdr-v1p0_24h-199101311200.nc'

#wget ${Fsur}${str0}
Y1=2025
Y2=2025

for iyr in `seq $Y1 $Y2`; do
   J1=$(datetojul ${iyr} 1 1 1950 1 1)      
   J2=$(datetojul ${iyr} 12 31 1950 1 1)      
   for jj in `seq ${J1} ${J2}`; do
      Sdate=$(jultodate ${jj} 1950 1 1)
      if [ $iyr -lt 2018 ]; then   # 24 hours products
         Fini=${Sdate:0:4}/${Sdate:4:2}/ice_drift_nh_ease2-750_cdr-v1p0_24h-${Sdate:0:8}1200.nc
         Fname=ice_drift_nh_ease2-750_cdr-v1p0_24h-${Sdate:0:8}1200.nc
         Fdir=${Fdirpre}
      else
         (( ii = jj - 2 ))
         Sdate0=$(jultodate ${ii} 1950 1 1)
         Fini=${Sdate:0:4}/${Sdate:4:2}/ice_drift_nh_polstere-625_multi-oi_${Sdate0:0:8}1200-${Sdate:0:8}1200.nc
         Fname=ice_drift_nh_polstere-625_multi-oi_${Sdate:0:8}1200.nc
         Fdir=${Fdirpre2}
      fi
      if [ ! -s ${Fname} ]; then
         wget -O ${Fname} ${Fdir}${Fini}
	 [ ! -s ${Fname} ] && rm ${Fname}
      fi
   done
done
