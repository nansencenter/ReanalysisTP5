import copernicusmarine
import numpy as np

#copernicusmarine.login()
# Using the acount information to download data from Copernicus marine data store
USER="XXXX";
UWORD="XXXXXXX";

YY=2023

VARs={'SIC':'conc','SST':'sst','SLA':'tsla','PROF':'profile'}

# Satellite series used here
Allsat={"al":[2013,2015], "alg":[2015,2023], "c2":[2010,2020], "c2n":[2020,2023], "e1":[1992,1995],
        "e1g":[1994,1995], "e2":[1995,2002], "en":[2002,2010], "enn":[2010,2012], "g2":[2000,2008],
        "h2a":[2014,2016], "h2ag":[2016,2020], "h2b":[2019,2023], #    "h2c":[2021,2021],
        "j1":[2002,2008], "j1g":[2012,2013], "j1n":[2009,2012], "j2":[2008,2016], "j2g":[2017,2017],
        "j2n":[2016,2017], "j3":[2015,2022], "j3n":[2021,2023], "s3a":[2016,2023], "s3b":[2018,2023],
        "s6a":[2021,2023], "tp":[1992,2002], "tpn":[2002,2005]}
Recsat={"alg":[2015,2023], "c2n":[2020,2023], "h2b":[2019,2023],"j3":[2015,2022],"j3n":[2021,2023],
        "s3a":[2016,2023], "s3b":[2018,2023],"swon":[2023,2024],"swonc":[2023,2024],"s6a-lr":[2021,2024]} 

Ltname=""
for ivar in VARs.keys():
   #print(ivar+' ~ '+VARs[ivar])
   if ivar=='PROF':
      dataidN="cmems_obs-ins_glo_phy-temp-sal_my_cora_irr"   # dt  profiles
      Fsur="global/"+str(YY)+"/"+"CO_DMQCGL01_"
      Ltname=Fsur+str(YY)+"????_??_??.nc"

   elif ivar=='SST':
      dataidN="METOFFICE-GLO-SST-L4-NRT-OBS-SST-V2"            # dt SST
                                                               # subproductid needed and yearly-based
      if YY>2024:
         dataidN = "METOFFICE-GLO-SST-L4-NRT-OBS-SST-V2" 
         Fsur    = "????120000-UKMO-L4_GHRSST-SSTfnd-OSTIA-GLOB-v02.0-fv02.0.nc"
      elif YY>2016:
         dataidN = "C3S-GLO-SST-L4-REP-OBS-SST"  
         #Fsur    = "????120000-C3S-L4_GHRSST-SSTdepth-OSTIA-GLOB_ICDR2.1-v02.0-fv01.0.nc"
         if YY>2021:
            Fsur    = "????120000-C3S2-L4_GHRSST-SSTdepth-ISTskin-DMIOI-GLOB_ICDR1.0-v02.0-fv01.0.nc"
         else:
            Fsur    = "????120000-C3S2-L4_GHRSST-SSTdepth-ISTskin-DMIOI-GLOB_CDR1.0-v02.0-fv01.0.nc"
      else:
         dataidN = "ESACCI-GLO-SST-L4-REP-OBS-SST"  
         Fsur    = "????120000-ESACCI-L4_GHRSST-SSTdepth-OSTIA-GLOB_CDR2.1-v02.0-fv01.0.nc"
      Ltname  = str(YY)+Fsur


   elif ivar=='SIC':
      dataidN="SEAICE_GLO_SEAICE_L4_REP_OBSERVATIONS_011_009"  # dt SIC
                                                               # subproductid needed and yearly-based
      if YY<2021:
         dataidN="OSISAF-GLO-SEAICE_CONC_TIMESERIES-NH-LA-OBS"
         Ltname="ice_conc_nh_ease2-250_cdr-v3p0_"+str(YY)+"????1200.nc"
      else:
         dataidN="OSISAF-GLO-SEAICE_CONC_CONT_TIMESERIES-NH-LA-OBS"
         Ltname="ice_conc_nh_ease2-250_icdr-v3p0_"+str(YY)+"????1200.nc"
   else:
      # keep it for SLA
      dataidN="cmems_obs-sl_glo_phy-ssh_nrt_??-l3-duacs_PT1S"  # nrt-TSLA id varied with satellite as well
      dataidN="cmems_obs-sl_glo_phy-ssh_my_??-l3-duacs_PT1S"  # dt-TSLA id varied with satellite as well
                                                               # subproductid needed and satellite-based

   OUTDIR="./"+VARs[ivar]+"/"+str(YY)
   print("")
   # Call the get function to save data
   if ivar=='SLA':
      if YY>2022:
         datasat=Recsat
      else:
         datasat=Allsat
      print(dataidN)
      for kk,yrs in datasat.items():
         #print(kk,yrs)
         if YY>=yrs[0] and YY<=yrs[1]+2:
            dataidN="cmems_obs-sl_glo_phy-ssh_my_"+kk+"-l3-duacs_PT1S"  # dt  TSLA
            if kk=="s6a-lr":
               Fsur="dt_global_s6a_lr_phy_l3_1hz_"
            else:
               Fsur="dt_global_"+kk+"_phy_l3_1hz_"
            Ltname=Fsur+str(YY)+"*_*.nc"
            print(Ltname)
            get_Yrdata = copernicusmarine.get(dataset_id=dataidN,
                output_directory=OUTDIR, filter=Ltname,overwrite=True,
                no_directories=True,username=USER,password=UWORD)
         else:
            print("skipping "+kk+" ...")
            print("")
   else:
      print(" download "+ivar+" devloping ... ")
      print(dataidN)
      print(Ltname)
      print(" ")
      get_Yrdata = copernicusmarine.get(dataset_id=dataidN,
              output_directory=OUTDIR, filter=Ltname,overwrite=True,
              no_directories=True,username=USER,password=UWORD)


