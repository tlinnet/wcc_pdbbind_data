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

FNAME="03_create_rdock_cavity"
RDFILE="${FNAME}.prm"
SHFILE="${FNAME}.sh"
LOGFILE="${FNAME}.log"
PYMFILE="${FNAME}.pml"
CAVFILE="${FNAME}_cav1.grd"

# Write rdock
function write_rdock_cmd {
echo "Writing rdock commands"
cd $PDBDIR

# Write rdock file
cat <<EOF > $RDFILE
RBT_PARAMETER_FILE_V1.00
TITLE ${PDB}

RECEPTOR_FILE 02_${PDB}.mol2
RECEPTOR_FLEX 3.0

##################################################################
### CAVITY DEFINITION: REFERENCE LIGAND METHOD
##################################################################
SECTION MAPPER
    SITE_MAPPER RbtLigandSiteMapper
    REF_MOL ${PDB}_ligand.sdf
    RADIUS 6.0
    SMALL_SPHERE 1.0
    MIN_VOLUME 100
    MAX_CAVITIES 1
    VOL_INCR 0.0
   GRIDSTEP 0.5
END_SECTION

#################################
#CAVITY RESTRAINT PENALTY
#################################
SECTION CAVITY
    SCORING_FUNCTION RbtCavityGridSF
    WEIGHT 1.0
END_SECTION
EOF

# Write execution file
cat <<EOF > $SHFILE
#!/usr/bin/env bash

rbcavity -was -d -r $RDFILE | tee $LOGFILE
EOF
chmod +x $SHFILE

# Write python file
cat <<EOF > $PYMFILE
load 02_${PDB}.mol2
load ${PDB}_ligand.sdf
load ${CAVFILE}

hide everything
show cartoon, 02_${PDB}
show sticks, ${PDB}_ligand

isomesh cavity, ${FNAME}_cav1, 0.99
EOF

cd $CWD
} 

# Write commands
if [ ! -f ${PDBDIR}/${RDFILE} ] || [ "$WFORCE" == "1" ]; then
    write_rdock_cmd
fi

# Execute if PDB does not exists
if [ ! -f ${PDBDIR}/${FNAME}.as ] || [ "$EFORCE" == "1" ]; then
    echo "Executing: ${SHFILE}"
    echo ""
    cd $PDBDIR
    ./${SHFILE}
    cd $CWD
fi


# End of file