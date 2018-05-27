# Manual

* http://rdock.sourceforge.net/docking-in-3-steps/

We try first the data from Esben.

Then we will convert from the PDF file.

# Procedure

## Make dock.prm file

See file.

## Cavity Generation

```bash
alias drdc='docker run -ti --rm -p 8888:8888 -v "${PWD}":/home/jovyan/work --name rdock $USER/rdock'

drdc rbcavity -was -d -r dock.prm | tee log_01_cavity.log
```

Check generated cavity with pymol

```bash
pymol cav_pymol.pml
```

## Docking

```bash
drdc rbdock -i 1gpk_ligand.sd -o outdock_1gpk -r dock.prm -p dock.prm -n 50 | tee log_02_dock.log
```

