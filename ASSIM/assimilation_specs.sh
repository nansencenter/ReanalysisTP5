JULDAY=26300
#!/bin/bash

# parameters common to both propagation and assimilation
#
ROOTDIR="/cluster/work/users/xiejp/TP5_Reanalysis"
FORECASTDIR="${ROOTDIR}/FORECAST"
TAPEDIR="/cluster/work/users/xiejp/TP5_Reanalysis"
BACKUPBUFDIR="${ROOTDIR}/TOBACKUP"
RESULTSDIR="${ROOTDIR}/RESULTS"
ANALYSISDIR="${ROOTDIR}/ANALYSIS"
MODELDIR="/cluster/work/users/xiejp/TP5_test/TP5a0.06/expt_02.0"
OUTPUTDIR="${ROOTDIR}/OUTPUT"
NESTINGDIR="${ROOTDIR}/NESTING"
HYCOMPREFIX="TP5"
ENSSIZE=100
IPERT=1
# assimilation specific parameters
#
OBSTYPES=""
if (( $JULDAY >= 23019 )); then
    OBSTYPES="TSLA SST TEM SAL ICEC IDRFT HICE SSS"
#    OBSTYPES="ICEC SST"
#    OBSTYPES="TSLA SST TEM SAL ICEC"
elif (( $JULDAY >= 22239 )); then
    OBSTYPES="TSLA SST TEM SAL ICEC HICE"
#    OBSTYPES="TSLA SST TEM SAL ICEC IDRFT HICE"
#    OBSTYPES="TSLA SST TEM SAL ICEC IDRFT HICE SKIM"
    #OBSTYPES="TSLA SST TEM GTEM SAL GSAL ICEC IDRFT"
fi

NPROC=72    # number of processors engaged in the EnKF analysis

# do not edit below unless you have to
#
PREPOBSDIR="${ROOTDIR}/PREPOBS"
OBSDIR="${ROOTDIR}/OBS"
CWD=`pwd`
BINDIR=`pwd`"/BIN"
FILESDIR=`pwd`"/FILES"

# add an branch for prepared observations as necessary format file
OBSREADY=1    # else =0
Obslink=/cluster/work/users/xiejp/work_2018/Data

if [ ${OBSREADY} == 1 ]; then
 Tdir=$(pwd)
 cd ${OBSDIR}
 Obslink=/cluster/work/users/xiejp/TP2_Reanalysis/DATA
 o=0
 for obsty in ${OBSTYPES} ; do
   if [ -r ${obsty} ]; then
     (( o = o +1 ))
   fi
 done
 if [ $o == 0 ]; then
   for obsty in ${OBSTYPES} ; do
     ln -sf ${Obslink}/${obsty} .
   done
 fi
 cd  ${Tdir}

fi

# Possible observation types:
#
# TSLA - track SLA
# SST - SST
# SAL - in-situ salinity from ARGO
# TEM - in-situ temperature from ARGO
# ICEC - ice concentration
# IDRFT - ice drift
# GSAL - in-situ salinity in "glider" format
# GTEM - in-situ temperature in "glider" format
JULDAYSTART=26300
CWD=/cluster/home/xiejp/REANALYSIS_TP5_spinup/ReanalysisTP5/ASSIM
