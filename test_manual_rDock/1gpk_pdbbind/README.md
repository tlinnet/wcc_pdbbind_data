# Convert to mol2 from pdb

* http://rdock.sourceforge.net/docking-in-3-steps/
* https://openbabel.org/wiki/Tutorial:Basic_Usage

openbabel was installed with conda in Dockerfile

```bash
conda install -c bioconda openbabel
```

## pymol + openbabel conversion

```bash
# Make alias to Docker
alias drdc='docker run -ti --rm -p 8888:8888 -v "${PWD}":/home/jovyan/work --name rdock $USER/rdock'

# Set variable in local bash
PROT=1gpk
drdc echo $PROT

# Delete water in pymol
cat <<EOF > pym_rem_water.pml
load ${PROT}_protein.pdb

remove solvent
save ${PROT}_protein_wowater.pdb
EOF

# Convert 
drdc pymol -c pym_rem_water.pml


# Get info for babel
drdc babel -H
drdc babel -L pdb
drdc babel -L mol2
drdc babel -L descriptors

# It seems:
# 1gpk_pocket.pdb : Has no hydrogen
# 1gpk_protein.pdb : Aldready has hydrogen

# Without adding H
drdc babel -ipdb  "${PROT}_protein_wowater.pdb" -omol2 "${PROT}_protein_mol2.mol2"

# -p : add hydrogens appropriate for pH7.4
drdc babel -p 7.4 -ipdb  "${PROT}_protein_wowater.pdb" -omol2 "${PROT}_protein_mol2.mol2"
drdc babel ---errorlevel 2 -p 7.4 -ipdb  "${PROT}_protein_wowater.pdb" -omol2 "${PROT}_protein_mol2.mol2"
drdc babel ---errorlevel 5 -p 7.4 -ipdb  "${PROT}_protein_wowater.pdb" -omol2 "${PROT}_protein_mol2.mol2"
```

## See in pymol

```bash
pymol ${PROT}_protein_wowater.pdb ${PROT}_protein_mol2.mol2 ${PROT}_ligand.sdf
```

# use rDock

## Create PRMFILE

```bash
PROT=1gpk

cat <<EOF > PRMFILE.prm
RBT_PARAMETER_FILE_V1.00
TITLE ${PROT}

RECEPTOR_FILE ${PROT}_protein_mol2.mol2
RECEPTOR_FLEX 3.0

##################################################################
### CAVITY DEFINITION: REFERENCE LIGAND METHOD
##################################################################
SECTION MAPPER
    SITE_MAPPER RbtLigandSiteMapper
    REF_MOL ${PROT}_ligand.sdf
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
```

## Cavity Generation

```bash
alias drdc='docker run -ti --rm -p 8888:8888 -v "${PWD}":/home/jovyan/work --name rdock $USER/rdock'

drdc rbcavity -was -d -r PRMFILE.prm | tee log_01_cavity.log
```

Check generated cavity with pymol

```bash
PROT=1gpk

cat <<EOF > cav_pymol.pml
load ${PROT}_protein_mol2.mol2
load ${PROT}_ligand.sdf
load PRMFILE_cav1.grd

hide everything
show cartoon, ${PROT}_protein_mol2
show sticks, ${PROT}_ligand

isomesh cavity, PRMFILE_cav1, 0.99
EOF

pymol cav_pymol.pml
```

## Docking

```bash
drdc rbdock -i ${PROT}_ligand.sdf -o outdock_${PROT} -r PRMFILE.prm -p dock.prm -n 50 | tee log_02_dock.log
#drdc rbdock -i ${PROT}_ligand.sdf -o outdock_${PROT} -r PRMFILE.prm -p dock.prm -n 4 | tee log_02_dock.log
```

## Get best rmsd

```bash
drdc sdrmsd ${PROT}_ligand.sdf outdock_${PROT}.sd -o outdock_${PROT}_rmsd.sd | tee log_03_rmsd.log
```

Create the SCORE and RMSD in a file

```bash
drdc sdreport -cSCORE,RMSD outdock_${PROT}_rmsd.sd | tee log_04_score.log
```

Get the RMSD, from the lowest score, and list scores

```bash
cat <<EOF > pyt_rmsd.py
import pandas as pd

# Read csv file
results = pd.read_csv("log_04_score.log")
# Get the index of minimum value
min_index = results.SCORE.idxmin()
best_rmsd = str(results.RMSD[min_index])
best_rmsd_text = "Best RMSD: %s\n"%best_rmsd
print(best_rmsd_text)
print(results.SCORE)
EOF

drdc python pyt_rmsd.py
```
