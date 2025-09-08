mms="01 02 03 04 05 06 07 08 09 10 11 12"
Fstr0="ftp://ftp.awi.de/sea_ice/product//cryosat2_smos/v206/nh/"
Fstr2="W_XX-ESA,SMOS_CS2,NH_25KM_EASE2"
Fstr3="r_v206_01_l4sit.nc"
for iy in `seq 2023 2023`; do
#for iy in `seq 2010 2021`; do
   for im in ${mms}; do
      ymm=${iy}${im}
      echo "wget -np -L 1 --cut-dirs=100 ${Fstr0}${iy}/${im}/${Fstr2}*${ymm}*_${Fstr3}"
      #wget -np -L 1 --cut-dirs=100 ${Fstr0}${iy}/${im}/${Fstr2}*${ymm}*_${Fstr3}
      wget ${Fstr0}${iy}/${im}/${Fstr2}*${ymm}*_${Fstr3}
      


   done



done

