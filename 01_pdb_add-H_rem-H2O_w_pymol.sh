#!/usr/bin/env bash

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our own variables:
FORCE=0
PDB=""

while getopts "h?fp:" opt; do
    case "$opt" in
    h|\?)
        echo "Trying to help:"
        exit 0
        ;;
    f)  FORCE=1
        ;;
    p)  PDB=$OPTARG
        ;;
    esac
done
shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

echo "FORCE=$FORCE, PDB='$PDB', Leftovers: $@"

# Exit, if empty PDB id
[[ -z $PDB ]] && echo "Please provide a PDB id" && exit 1

# Exit, if PDB dir does not exist
CWD=`pwd`
PDBDIR=${CWD}/pdbbind_v2017_refined/${PDB}
[[ ! -d "$PDBDIR" ]] && echo PDB dir does not exists: $PDBDIR && exit 1

FNAME="01_pym_rem_water"
PYMFILE="${FNAME}.pml"
SHFILE="${FNAME}.sh"

# Write pymol
function write_pymol_cmd {
echo "Writing pymol commands"
cd $PDBDIR

# Write pymol file
cat <<EOF > $PYMFILE
load ${PDB}_protein.pdb

remove solvent
save 01_${PDB}.pdb
EOF

# Write execution file
cat <<EOF > $SHFILE
#!/usr/bin/env bash

pymol -c $PYMFILE
EOF
chmod +x $SHFILE

cd $CWD
} 

# Write pymol commands
if [ ! -f ${PDBDIR}/${PYMFILE} ] || [ "$FORCE" == "1" ]; then
    write_pymol_cmd
fi

# Execute if PDB does not exists
if [ ! -f ${PDBDIR}/01_${PDB}.pdb ] || [ "$FORCE" == "1" ]; then
    cd $PDBDIR
    ./${SHFILE}
    cd $CWD
fi


# End of file