#!/bin/bash

# parameters common to both propagation and assimilation
#
ROOTDIR="/cluster/work/users/xiejp/TP5_SICAP"
FORECASTDIR="${ROOTDIR}/FORECAST"
TAPEDIR="/cluster/work/users/xiejp/TP5_SICAP"
BACKUPBUFDIR="${ROOTDIR}/TOBACKUP"
RESULTSDIR="${ROOTDIR}/RESULTS"
ANALYSISDIR="${ROOTDIR}/ANALYSIS"
MODELDIR="/cluster/work/users/xiejp/TP5_test/TP5a0.06/expt_02.0"
OUTPUTDIR="${ROOTDIR}/OUTPUT"
NESTINGDIR="${ROOTDIR}/NESTING"
HYCOMPREFIX="TP5"
ENSSIZE=100
IPERT=1
PPERT=2
# propagation specific parameters
#
EXPT=expt_02.0
EXPT_short=${EXPT#expt_}

# do not edit below
#
CWD=`pwd`
INFILEDIR="${CWD}/INFILE"
BINDIR="${CWD}/BIN"
JULDAY=26657
