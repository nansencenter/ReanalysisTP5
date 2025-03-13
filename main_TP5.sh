#!/bin/bash

# File: main_ensemble.sh
# Author : Jiping XIE 
# Date: April in 2022
#
# Description:
#   This is the top level script for data assimilation cycle 
#   in TOPAZ5 reanalysis.

STARTASSIM=0      # 1 is default, enter 0 to skip the very first assimilation
#STARTASSIM=0 # 1 is default, enter 0 to skip the very first assimilation
#JULDAYSTART0=18938
JULDAYSTART0=24000

set -e # exit on error
set -u # exit on unset variables
set -p # nothing is inherited from the shell
#set -x # for debuging

#source /nird/home/xiejp/bash_profile_enkf-default

. common_specs.sh
./SCRIPTS/check_directories.sh

JULDAYSTART=`cat JULDAY.txt`
#((JULDAYEND = 26600)) 
((JULDAYEND = 26307)) 

echo "  JULDAYSTART = ${JULDAYSTART}"
echo "  JULDAYEND = ${JULDAYEND}"

for (( day = ${JULDAYSTART}; day <= ${JULDAYEND}; day += 7 ))
do

    if (( ${STARTASSIM} || ${day} > ${JULDAYSTART} ))
    #if (( ${STARTASSIM} && ${day} > ${JULDAYSTART} ))
    then
	echo
	echo "Starting assimilation for day ${day} since 1 Jan 1950"
	echo

        #[ -s Twostep ] && rm Twostep
        touch STOP
        echo 'Initial assimilation: ${day}' > STOP

	cd ASSIM
	echo "JULDAY=${day}" > assimilation_specs.sh
	cat ../common_specs.sh >> assimilation_specs.sh
	cat assimilation_specs.in >> assimilation_specs.sh
	echo "JULDAYSTART=${JULDAYSTART}" >> assimilation_specs.sh
	echo "CWD="`pwd` >> assimilation_specs.sh
	(( ncycle = ( ${day} - ${JULDAYSTART0} ) / 7 ))
	if (( $ncycle <= 20 ))
	then
	    (( RFACTOR = 8 ))
	elif (( $ncycle <= 35 ))
	then
	    (( RFACTOR = 4 ))
	elif (( $ncycle <= 45 ))
	then
	    (( RFACTOR = 2 ))
	else
	    (( RFACTOR = 1 ))
	fi
	cat ./FILES/enkf.in |\
	    awk -f SCRIPTS/setparameter.awk -v PRM=rfactor1 -v VAL=${RFACTOR} |\
	    awk -f SCRIPTS/setparameter.awk -v PRM=enssize -v VAL=${ENSSIZE} \
	    > enkf.prm
	./SCRIPTS/assimilate_betzy.sh
	cd ..
        if [ -f STOP ]
        then
            exit
        fi
    fi

    echo

    echo "Starting propagation for day ${day} since 1 Jan 1950"
    echo

    cd PROP
    cp -f ../common_specs.sh propagation_specs.sh
    cat propagation_specs.in >> propagation_specs.sh
    echo "JULDAY=${day}" >> propagation_specs.sh
    ./SCRIPTS/propagate_sr.sh
    cd ..

    if [ -f STOP ]
    then
	exit
    fi
done
