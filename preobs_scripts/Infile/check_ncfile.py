import numpy as np
import sys
import netCDF4 as nc

# chech the input netcdf file
# N_PROF and N_LEVELS both >0: return 1
# else return 0

argc=len(sys.argv)
if argc>1:
   file0=sys.argv[1]
else:
   print("Input the netcdf file")
   quit()
   
ds=nc.Dataset(file0,'r')
#print(ds.dimensions.keys())

n_prof=ds.dimensions['N_PROF'].size
n_lev=ds.dimensions['N_LEVELS'].size
#tt=ds.variables['TEMP'][:]
#print(tt)
#print(n_lev)
#print(n_prof)
if n_lev*n_prof>0:
   print(1)
else:
   print(0)
