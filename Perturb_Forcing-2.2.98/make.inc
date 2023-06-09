# include file for fimm, intel compilers
CF90 = ifort
CF77 = $(CF90)
CC = icc
LD =  $(CF90)

# CPP, used internally by compilers - note that some compilers
# need special options for this, consult compiler manual if in trouble
CPP= /usr/bin/cpp -P -traditional-cpp
CPPARCH = -DIA32 -DREA8 -DSERIA_IO -DTIMER -DIARGC -DFFTW -DLAPACK
#NCAR graphics compiler wrappers
#NCARGCF90=ncargf90
#NCARGCF77=ncargf77
#NCARGCC=ncargcc
#NCARGLD=ncargf90

# Flags for fixed/free format
F90FLG= -free
F77FLG = -nofree

NETCDF_INCLUDE_OPTS=/cluster/software/netCDF-Fortran/4.5.2-iimpi-2020a/include
# Compiler flags - real*8 version 
#FFLAGS= -real_size 64 -convert big_endian -O2  -g
FFLAGS= -g -convert big_endian -assume byterecl -cm -vec_reprot0 -w -O2 -r8 -I$(NETCDF_INCLUDE_OPTS)
#FFLAGS= -g -convert big_endian -assume byterecl -O2 -r8 -I$(NETCDF_INCLUDE_OPTS)
CFLAGS= -O2

# Compiler flags - real*4 version (Needed for NCARG routines)
FFLAGSR4= -real_size 32 -convert big_endian -O2  -g
CFLAGSR4= -O2

# Linker flags
LINKFLAGS= $(FFLAGS)  


#LD_LIBRARY_PATH=/cluster/software/netCDF-Fortran/4.5.2-iimpi-2019b/lib:/cluster/software/netCDF/4.7.1-iimpi-2019b/lib64:$LD_LIBRARY_PATH
#Libraries, Netcdf, FFTW, LAPACK
LIBS = -lnetcdf -lnetcdff -lfftw3 -lmkl

# Define CPP flags consistent with libs above
CPPFLAGS=-DFFTW -DLAPACK
