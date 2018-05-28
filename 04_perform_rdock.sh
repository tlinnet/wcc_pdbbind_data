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

# Set N
N=$@
[[ -z $@ ]] && N="n 3"
#echo $N

# Exit, if PDB dir does not exist
CWD=`pwd`
PDBDIR=${CWD}/pdbbind_v2017_refined/${PDB}
[[ ! -d "$PDBDIR" ]] && echo PDB dir does not exists: $PDBDIR && exit 1

FNAME="04_create_rdock_cavity"
SHFILE="${FNAME}.sh"
LOGFILE="${FNAME}.log"
SECFILE="${FNAME}.sec"
TIMEFILE="${FNAME}.time"

# Write rdock
function write_rdock_cmd {
echo "Writing rdock commands"
cd $PDBDIR

# Write execution file
cat <<EOF > $SHFILE
#!/usr/bin/env bash

rbdock -i ${PDB}_ligand.sdf -o 04_out_${PDB} -r 03_create_rdock_cavity.prm -p dock.prm -$N | tee $LOGFILE

echo \$SECONDS > $SECFILE
times > $TIMEFILE

EOF
chmod +x $SHFILE

cd $CWD
} 

# Write commands
if [ ! -f ${PDBDIR}/${SHFILE} ] || [ "$WFORCE" == "1" ]; then
    write_rdock_cmd
fi

# Execute if PDB does not exists
if [ ! -f ${PDBDIR}/04_out_${PDB}.sd ] || [ "$EFORCE" == "1" ]; then
    echo "Executing: ${SHFILE}"
    echo ""
    cd $PDBDIR
    ./${SHFILE}
    cd $CWD
fi


# End of file