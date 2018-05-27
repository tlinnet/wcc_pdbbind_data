# Manual

* http://rdock.sourceforge.net/docking-in-3-steps/

We try first the data from Esben.

Then we will convert from the PDF file.

# Procedure

## Make PRMFILE.prm file

See file.

## Cavity Generation

```bash
alias drdc='docker run -ti --rm -p 8888:8888 -v "${PWD}":/home/jovyan/work --name rdock $USER/rdock'

drdc rbcavity -was -d -r PRMFILE.prm | tee log_01_cavity.log
```

Check generated cavity with pymol

```bash
pymol cav_pymol.pml
```

## Docking

```bash
drdc rbdock -i 1gpk_ligand.sd -o outdock_1gpk -r PRMFILE.prm -p dock.prm -n 50 | tee log_02_dock.log
#drdc rbdock -i 1gpk_ligand.sd -o outdock_1gpk -r PRMFILE.prm -p dock.prm -n 4 | tee log_02_dock.log
```

## Get best rmsd

```bash
drdc sdrmsd 1gpk_ligand.sd outdock_1gpk.sd -o outdock_1gpk_rmsd.sd | tee log_03_rmsd.log
```

Create the SCORE and RMSD in a file

```bash
drdc sdreport -cSCORE,RMSD outdock_1gpk_rmsd.sd | tee log_04_score.log
```

Get the RMSD, from the lowest score, and list scores

```bash
drdc python pyt_rmsd.py
```