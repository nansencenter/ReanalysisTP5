import numpy as np
import scipy.io.netcdf as sionet
import sys
import abfile.abfile as abf
import netCDF4
import logging
import argparse


# keep the fix order in the following parameters
def write_para_init(filename,idm,jdm):
   nc=sionet.netcdf_file(filename,"w")
   nc.createDimension("x",idm)
   nc.createDimension("y",jdm)

   nc.createVariable("rhos","double",("y","x",))
   nc.createVariable("rhoi","double",("y","x",))
   nc.createVariable("ice_ref_salt","double",("y","x",))
   nc.createVariable("emissi","double",("y","x",))
   nc.createVariable("floediam","double",("y","x",))
   nc.createVariable("iceruf","double",("y","x",))
   nc.createVariable("dragio","double",("y","x",))
   nc.createVariable("Pstar","double",("y","x",))
   nc.createVariable("rsnw_mlt","double",("y","x",))
   nc.createVariable("hi_ssl","double",("y","x",))
   nc.createVariable("R_snw","double",("y","x",))
   nc.createVariable("astar","double",("y","x",))
   nc.createVariable("mu_rdg","double",("y","x",))
   nc.createVariable("hs1","double",("y","x",))

   nc.variables["rhos"].units      ="kg/m3"
   nc.variables["rhoi"].units      ="kg/m3"
   nc.variables["ice_ref_salt"].units="psu"
   nc.variables["emissi"].units=""
   nc.variables["floediam"].units  ="m"

   nc.variables["iceruf"].units    =""
   nc.variables["dragio"].units    =""
   nc.variables["Pstar"].units     ="N/m2"

   nc.variables["rsnw_mlt"].units  ="m"
   nc.variables["hi_ssl"].units    ="m"
   nc.variables["R_snw"].units     =""

   nc.variables["astar"].units     =""
   nc.variables["mu_rdg"].units    =""
   nc.variables["hs1"].units       ="m"

   nc.variables["rhos"][:]      =330.
   nc.variables["rhoi"][:]      =917.
   nc.variables["ice_ref_salt"][:]=4.0
   nc.variables["emissi"][:]=0.95
   nc.variables["floediam"][:]  =300.
   nc.variables["iceruf"][:]    =0.0005
   nc.variables["dragio"][:]    =0.00536
   nc.variables["Pstar"][:]     =27500.
   nc.variables["rsnw_mlt"][:]  =750.
   nc.variables["hi_ssl"][:]    =0.05
   nc.variables["R_snw"][:]     =1.2
   nc.variables["astar"][:]     =0.05
   nc.variables["mu_rdg"][:]    =3.0
   nc.variables["hs1"][:]       =0.03

   # Given the parameter order:
   # It would be consistent with the defination in CICE code 
   nc.variables["Pstar"].long_name     ="P1"
   nc.variables["dragio"].long_name    ="P2"
   nc.variables["iceruf"].long_name    ="P3"
   nc.variables["rsnw_mlt"].long_name  ="P4"
   nc.variables["hi_ssl"].long_name    ="P5"
   nc.variables["R_snw"].long_name     ="P6"
   nc.variables["astar"].long_name     ="P7"
   nc.variables["mu_rdg"].long_name    ="P8"
   nc.variables["hs1"].long_name       ="P9"
   nc.variables["floediam"].long_name  ="P10"
   nc.variables["emissi"].long_name="P11"
   nc.variables["ice_ref_salt"].long_name="P12"
   nc.variables["rhoi"].long_name      ="P13"
   nc.variables["rhos"].long_name      ="P14"

   nc.close()

# first condition: random perturb all the parameter but limted by the input percentage
def write_allpara_percent(filename,Maxpert,Pnames):
   import random
   #Apert=1+Maxpert*np.random.normal(0,0.5,size=30)
   #Apert=Maxpert*random.random()  # random perturbation by percent.
   if len(Pnames)>1: 
      FldV1=Pnames
   else:
      #FldV1=["P1","P2","P7","P10"]
      FldV1=["P1","P2","P3","P7","P10","P11"]
   print(FldV1)
   dnc=netCDF4.Dataset(filename,mode='r+')
   vars=list(dnc.variables.keys())
   for fld in vars:
      Apert=1+Maxpert*np.random.normal(0,0.5,size=2)
      fldOrd=getattr(dnc.variables[fld],'long_name')
      if fldOrd not in FldV1:
         print("Skip "+fld)
         continue
      else:
        fld0=dnc[fld][:]
        ave0=np.nanmean(fld0)
        # additional defination about the parameter varied in a range. and its averaged mean.
        Minpert=0.4
        match fld:
          case "rhos":
              V0=ave0; V1=Minpert*ave0; V2=600;
          case "rhoi":
              V0=ave0; V1=Minpert*ave0; V2=998.;
          case "emissi":
              V0=ave0; V1=Minpert*ave0; V2=0.99;
          case "ice_ref_salt":
              V0=ave0; V1=Minpert*ave0; V2=8.;
          case "floediam":
              V0=ave0; V1=Minpert*ave0; V2=700;
          case "iceruf":
              V0=ave0; V1=Minpert*ave0; V2=0.1
          case "dragio":
              V0=ave0; V1=Minpert*ave0; V2=0.01
          case "Pstar":
              V0=ave0; V1=Minpert*ave0; V2=52000
          case "rsnw_mlt":
              V0=ave0; V1=Minpert*ave0; V2=1500
          case "hi_ssl":
              V0=ave0; V1=Minpert*ave0; V2=0.15
          case "R_snw":
              V0=ave0; V1=Minpert*ave0; V2=2.5
          case "astar":
              V0=ave0; V1=Minpert*ave0; V2=0.15
          case "hs1":
              V0=ave0; V1=Minpert*ave0; V2=0.15
          case _:
              V0=ave0; V1=max(0,ave0*(1-Maxpert)); V2=ave0*(1+Maxpert)
        tmpV=ave0*Apert[1];  
        tmpV=min(max(V1,tmpV),V2); fld0[:]=tmpV;
        dnc.variables[fld][:]=fld0
        print("%s: %.3f after perturbation %.3f"%(fld,ave0,tmpV))

def main(number,Pnames):
   # read plon plat
   # Some key parameters
   gfile=abf.ABFileGrid("regional.grid","r")
   plon=gfile.read_field("plon")
   plat=gfile.read_field("plat")
   gfile.close()
   Nj=np.size(plon,0)
   Ni=np.size(plon,1)
   # initializing all the parameters at first
   write_para_init("para_init.nc",Ni,Nj)
   if number>0:
      print("Randomly perturbing all the parameters with the input range of %.2f"%number)
      write_allpara_percent("para_init.nc",number,Pnames)

# Set up logger
#_loglevel=logging.DEBUG
#logger = logging.getLogger(__name__)
#logger.setLevel(_loglevel)
#formatter = logging.Formatter("%(asctime)s - %(name)10s - %(levelname)7s: %(message)s")
#ch = logging.StreamHandler()
#ch.setLevel(_loglevel)
#ch.setFormatter(formatter)
#logger.addHandler(ch)
#logger.propagate=False
if __name__ == "__main__":
   parser = argparse.ArgumentParser(description='Creat defined parameters for CICE model',usage='Argument (0) initiaizes the parameters; other input argument will be used as a random number.\n')
   parser.add_argument('number', type=float)
   parser.add_argument('Pnames',type=list)
   args = parser.parse_args()
   print(args)
   main(args.number,args.Pnames)
