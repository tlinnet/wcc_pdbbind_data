#!/usr/bin/env bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
WFORCE=0
EFORCE=0
PDB=""

while getopts "h?wep:" opt; do
    case "$opt" in
    h|\?)
        echo "Trying to help:"
        exit 0
        ;;
    w)  WFORCE=1
        ;;
    e)  EFORCE=1
        ;;
    p)  PDBFILE=$OPTARG
        ;;
    esac
done
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

#echo "WFORCE=$WFORCE, EFORCE=$EFORCE, PDBFILE='$PDBFILE', Leftovers: $@"

# Exit, if PDB file not exists
[[ ! -f $PDBFILE ]] && echo "Please provide a file of PDB ids" && exit 1

CWD=`pwd`

# Run over PDB file
declare -a PDBARR

# Load file into array.
let i=0
while IFS=$'\n' read -r line_data; do
    PDBARR[i]="${line_data}"
    ((++i))
done < $PDBFILE

let i=0
while (( ${#PDBARR[@]} > i )); do
    PDB=${PDBARR[i++]}
    PDBDIR=${CWD}/pdbbind_v2017_refined/${PDB}

    # Read the number of poses
    echo $PDB
    rm -rf ${PDBDIR}/01_*
    rm -rf ${PDBDIR}/02_*
    rm -rf ${PDBDIR}/03_*
    rm -rf ${PDBDIR}/04_*
    rm -rf ${PDBDIR}/05_*

done
