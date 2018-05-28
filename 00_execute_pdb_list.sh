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

echo "WFORCE=$WFORCE, EFORCE=$EFORCE, PDBFILE='$PDBFILE', Leftovers: $@"

# Exit, if PDB file not exists
[[ ! -f $PDBFILE ]] && echo "Please provide a file of PDB ids" && exit 1

CWD=`pwd`

# Set N
N=$@
[[ -z $@ ]] && N="n 3"
#echo $N

# Run over PDB file
declare -a PDBARR

# Load file into array.
let i=0
while IFS=$'\n' read -r line_data; do
    PDBARR[i]="${line_data}"
    ((++i))
done < $PDBFILE

# Explicitly report array content.
let i=0
while (( ${#PDBARR[@]} > i )); do
    PDB=${PDBARR[i++]}
    #echo $PDB
    #printf "${PDB}\n"

    [[ "$WFORCE $EFORCE" == "0 0" ]] && CMD=""
    [[ "$WFORCE $EFORCE" == "1 0" ]] && CMD="-w"
    [[ "$WFORCE $EFORCE" == "0 1" ]] && CMD="-e"
    [[ "$WFORCE $EFORCE" == "1 1" ]] && CMD="-w -e"

    ./01_pdb_add-H_rem-H2O_w_pymol.sh -p $PDB $CMD
    ./02_convert_pdb_to_mol2_w_obabel.sh -p $PDB $CMD
    ./03_create_rDock_cavity.sh -p $PDB $CMD
    ./04_perform_rdock.sh -p $PDB $CMD $N
    ./05_get_rmsd.sh -p $PDB $CMD
done

# Now collect the timings

echo ""
echo "---------------------"
echo ""

echo "NR,PDB,N,SEC" > ${PDBFILE}.sec

let i=0
while (( ${#PDBARR[@]} > i )); do
    PDB=${PDBARR[i++]}
    PDBDIR=${CWD}/pdbbind_v2017_refined/${PDB}

    # Read the number of poses
    N=`cat ${PDBDIR}/04_out_${PDB}.sd | grep '$$$$' | wc -l`

    # Read the amount of seconds used on docking
    read SEC < $PDBDIR/04_create_rdock_cavity.sec

    echo "${i},${PDB},${N},${SEC}" >> ${PDBFILE}.sec
done

cat ${PDBFILE}.sec
