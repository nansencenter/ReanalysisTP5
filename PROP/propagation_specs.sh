#!/bin/bash

# parameters common to both propagation and assimilation
#
ROOTDIR="/cluster/work/users/xiejp/TP5_Reanalysis"
FORECASTDIR="${ROOTDIR}/FORECAST"
TAPEDIR="/cluster/work/users/xiejp/TP5_Reanalysis"
BACKUPBUFDIR="${ROOTDIR}/TOBACKUP"
RESULTSDIR="${ROOTDIR}/RESULTS"
ANALYSISDIR="${ROOTDIR}/ANALYSIS"
MODELDIR="/cluster/work/users/xiejp/TOPAZ/TP5a0.06/expt_02.1"
OUTPUTDIR="${ROOTDIR}/OUTPUT"
NESTINGDIR="${ROOTDIR}/NESTING"
HYCOMPREFIX="TP5"
ENSSIZE=100
# propagation specific parameters
#

# do not edit below
#
EXPT=expt_02.1
EXPT_short=${EXPT#expt_}
CWD=`pwd`
INFILEDIR="${CWD}/INFILE"
BINDIR="${CWD}/BIN"
JULDAY=26293
