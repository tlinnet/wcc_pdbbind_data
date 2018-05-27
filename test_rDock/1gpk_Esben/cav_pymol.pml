load 1gpk_rdock.mol2
load 1gpk_ligand.sd
load PRMFILE_cav1.grd

hide everything
show sticks, 1gpk_ligand
show cartoon, 1gpk_rdock

isomesh cavity, PRMFILE_cav1, 0.99