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
    p)  PDB=$OPTARG
        ;;
    esac
done
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

echo "WFORCE=$WFORCE, EFORCE=$EFORCE, PDB='$PDB', Leftovers: $@"

# Exit, if empty PDB id
[[ -z $PDB ]] && echo "Please provide a PDB id" && exit 1

# Exit, if PDB dir does not exist
CWD=`pwd`
PDBDIR=${CWD}/pdbbind_v2017_refined/${PDB}
[[ ! -d "$PDBDIR" ]] && echo PDB dir does not exists: $PDBDIR && exit 1

FNAME="05_get_rmsd"
SHFILE="${FNAME}.sh"
LOGFILE="${FNAME}.log"
SCOREFILE="${FNAME}.score"

# Write rdock
function write_rdock_cmd {
echo "Writing rdock commands"
cd $PDBDIR

# Write execution file
cat <<EOF > $SHFILE
#!/usr/bin/env bash

# Get best rmsd
sdrmsd ${PDB}_ligand.sdf 04_out_${PDB}.sd -o 04_out_${PDB}_rmsd.sd | tee $LOGFILE

# Create the SCORE and RMSD in a file
sdreport -cSCORE,RMSD 04_out_${PDB}_rmsd.sd | tee $SCOREFILE
EOF
chmod +x $SHFILE

cd $CWD
} 

# Write commands
if [ ! -f ${PDBDIR}/${SHFILE} ] || [ "$WFORCE" == "1" ]; then
    write_rdock_cmd
fi

# Execute if PDB does not exists
if [ ! -f ${PDBDIR}/${SCOREFILE} ] || [ "$EFORCE" == "1" ]; then
    echo "Executing: ${SHFILE}"
    echo ""
    cd $PDBDIR
    ./${SHFILE}
    cd $CWD
fi


# End of file