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

FNAME="02_obabel_convert"
SHFILE="${FNAME}.sh"
PYMFILE="${FNAME}.pml"

# Write pymol
function write_obabel_cmd {
echo "Writing obabel commands"
cd $PDBDIR

# Write execution file
cat <<EOF > $SHFILE
#!/usr/bin/env bash

obabel -ipdb  "01_${PDB}.pdb" -omol2 -O "02_${PDB}.mol2"
EOF
chmod +x $SHFILE

# Write pymol file
cat <<EOF > $PYMFILE
load 01_${PDB}.pdb
load 02_${PDB}.mol2
load ${PDB}_ligand.sdf
EOF

cd $CWD
} 

# Write pymol commands
if [ ! -f ${PDBDIR}/${SHFILE} ] || [ "$WFORCE" == "1" ]; then
    write_obabel_cmd
fi

# Execute if PDB does not exists
if [ ! -f ${PDBDIR}/02_${PDB}.mol2 ] || [ "$EFORCE" == "1" ]; then
    echo "Executing: ${SHFILE}"
    echo ""
    cd $PDBDIR
    ./${SHFILE}
    cd $CWD
fi


# End of file