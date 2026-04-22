mms="01 02 03 04 05 06 07 08 09 10 11 12"
Fstr0="ftp://ftp.awi.de/sea_ice/product//cryosat2_smos/v300/nh/"
Fstr2="W_XX-ESA,SMOS_CS2_S3A_S3B,NH_12P5KM_EASE2"
Fstr3="r_v300_01_l4sit.nc"
for iy in `seq 2010 2024`; do
#for iy in `seq 2010 2021`; do
   for im in ${mms}; do
      ymm=${iy}${im}
      echo "wget -np -L 1 --cut-dirs=100 ${Fstr0}${iy}/${im}/${Fstr2}*${ymm}*${Fstr3}"
      #wget -np -L 1 --cut-dirs=100 ${Fstr0}${iy}/${im}/${Fstr2}*${ymm}*_${Fstr3}
      wget ${Fstr0}${iy}/${im}/${Fstr2}*${ymm}*${Fstr3} ./v300
      


   done



done

