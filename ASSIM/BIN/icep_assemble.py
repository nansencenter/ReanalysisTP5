import abfile
import numpy as np
import argparse
import glob
import os
import shutil
import netCDF4 as nc

# Created by JX at 22th April 2026:
# usage: extract the ice parameter analysis from .ab file and save to netCDF file
# requires: regional.grid/depth.ab, analysisfields_ice.in, enkf_diag.nc (for mask), 
#           forecast???.ab (for restart file header), and the relevant analysis???_proc???.ab
# output:   icep_analysis???.nc  
# 

# setting of the min/max threshold values.
def fld_valuebin(fldname,Minpert):
    V1=np.nan
    V2=np.nan
    match fldname:
        case "emissi":
            V0=0.95;
            V1=Minpert*V0; V2=0.99;
        case "iceruf":
            V0=0.0005;
            V1=Minpert*V0; V2=0.1;
        case "dragio":
            V0=0.00536;
            V1=Minpert*V0; V2=0.01;
        case "Pstar":
            V0=27500.;
            V1=Minpert*V0; V2=52000.;
        case "floediam":
            V0=300.;
            V1=Minpert*V0; V2=700.;
        case "astar":
            V0=0.05;
            V1=Minpert*V0; V2=0.15;
    return V1,V2

# 1) input: number in the ensemble.
parser = argparse.ArgumentParser()
parser.add_argument("-n", "--number", type=int, help="An input number in ensemble")
args = parser.parse_args()
print(f"Number in ensemble: {args.number}")

# 2) catch the header lines from forecast reastart file.
Fhycom='forecast%03d.b'%args.number
Fhycoma='%sa'%(Fhycom[0:-1])
if not os.path.isfile(Fhycoma):
   print('Missing the forecast file %s as reference!\n'%Fhycoma)
   quit
else:
    with open(Fhycom,'r') as f:
        Headlines=f.readlines()


# 3) search the ice parameter names involved in : number in the ensemble.
iceplist=[]
icepfilein='analysisfields_ice.in'
with open(icepfilein, 'r') as f:
    for line in f:
        columns = line.split()
        if columns:  # Check if the line is not empty
            if columns[0]!='ficem' and columns[0] !='hicem':
               iceplist.append(columns[0])
if np.size(iceplist)<1:
   print(f"No ice parameter defined : {icepfilein}")
   print("quit")
   quit
else:
   print(iceplist)

# 3) check the target file:
inifile='icep_analysis%03d.nc'%(args.number)
inifile0='icep_forecast%03d.nc'%(args.number)
if not os.path.isfile(inifile0):
   print('Missing file: %s'%inifile0)
   quit
else:
   shutil.copy2(inifile0,inifile)

# 4) model grid information
abgrid = abfile.ABFileGrid("regional.grid.a","r")
plon=abgrid.read_field("plon")
plat=abgrid.read_field("plat")
jdm,idm=plon.shape

abdepth = abfile.ABFileBathy("regional.depth.a","r",idm=idm,jdm=jdm)
depthm=abdepth.read_field("depth")

# 5) seaice observation mask from enkf_diag.nc
Fdiag='enkf_diag.nc'
varmask='dfs_ICEC'
if not os.path.isfile(Fdiag):
   print('Missing file: %s'%Fdiag)
   quit
ds=nc.Dataset(Fdiag,'r')
diagvars=list(ds.variables.keys())
if varmask in diagvars:
   dfs_ice=ds.variables[varmask][:]
ds.close()

# 6) check the available and relevant process files created by EnKF:
memfile='analysis%03d_proc*.b'%(args.number)
Enfiles=glob.glob(memfile)
print('\nSearching %d files for this member ... \n'%(np.size(Enfiles)))

for ivar in list(iceplist):
    varsig=0
    jvar=ivar
    Minvar,Maxvar=fld_valuebin(ivar,0.4)
    for ii in list(Enfiles):
       if varsig==1:
          continue
       with open(ii,'r') as f:
          #print(ii)
          for line in f:
              columns = line.split()
              if len(columns[0])>8:
                 Findstr=columns[0][0:8]
              else:
                 Findstr=columns[0]
              
              if Findstr == ivar:
                 print('\nfind %s in %s\n'%(ivar,ii))
                 varsig=1
                 # catch the fields lines
                 with open(ii,'r') as f1:
                     fldlines=f1.readlines()

                 # create the temperory files:
                 Ftmpb='tmp_%s'%ii
                 Ftmpa='tmp_%sa'%(ii[0:-1])
                 Fii='%sa'%(ii[0:-1])
                 # .a file:
                 shutil.copy2(Fii,Ftmpa)
                 # .b file:
                 with open(Ftmpb,'w') as f2:
                     for i, line in enumerate(Headlines):
                         if i <2:
                            f2.write(line)
                     for i, line in enumerate(fldlines):
                         if i>-1:
                            if line[0:8]=='floediam':
                               line='floedia '+line[8:] 
                            f2.write(line)

                 # extract the pointed field from the temperory file:
                 jj=0
                 rABres=abfile.ABFileRestart(Ftmpa,"r",idm=idm,jdm=jdm)
                 for ikey in sorted( rABres.fields.keys() ) :
                     fldname = rABres.fields[ikey]["field"]
                     k         = rABres.fields[ikey]["k"]
                     t         = rABres.fields[ikey]["tlevel"]
                     field     = rABres.read_field(fldname,k,t)
                     print(ikey)
                     if ikey>50:
                        quit()
                     if fldname=='floedia':
                        Mfldname='floediam'
                     else:
                        Mfldname=fldname

                     if ivar==Mfldname:
                         print('Updating ...')
                         # 1) Filter the values outside of thershold
                         #field[field>Maxvar]=Maxvar
                         #field[field<Minvar]=Minvar
                         np.place(field, field<Minvar, [Minvar])
                         np.place(field, field>Maxvar, [Maxvar])

                         # 2) limit the update happens due to sea ice observation
                         # replace the field in NetCDF file
                         with nc.Dataset(inifile,'r+') as ds:
                            fld0=ds.variables[ivar][0]
                            if 'dfs_ice' in locals():
                               maskice=np.where(dfs_ice>0)
                               fld0[maskice]=field[maskice]
                               ds.variables[ivar][0]=fld0
                            #ds.variables[ivar][0]=field

                         break

                 print('\nclean the temperory files ...')
                 os.remove(Ftmpa)
                 os.remove(Ftmpb)
print('Done!')
