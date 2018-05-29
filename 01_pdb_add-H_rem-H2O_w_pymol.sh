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

#Remove alternates
cmd.remove("not alt +A")
cmd.valence("guess", selection1='${PDB}_protein')

#Prepare molecules with polar hydrogens:
cmd.h_add("elem O or elem N or elem S")

#Delete Waters and Heteroatoms
cmd.remove("solvent")
cmd.remove("resn HOH")
cmd.remove("hetatm")

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
if [ ! -f ${PDBDIR}/${PYMFILE} ] || [ "$WFORCE" == "1" ]; then
    write_pymol_cmd
fi

# Execute if PDB does not exists
if [ ! -f ${PDBDIR}/01_${PDB}.pdb ] || [ "$EFORCE" == "1" ]; then
    echo "Executing: ${SHFILE}"
    echo ""
    cd $PDBDIR
    bash ${SHFILE}
    cd $CWD
fi


# End of file