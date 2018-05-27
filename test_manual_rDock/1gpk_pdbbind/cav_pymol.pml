load 1gpk_protein_mol2.mol2
load 1gpk_ligand.sdf
load PRMFILE_cav1.grd

hide everything
show cartoon, 1gpk_protein_mol2
show sticks, 1gpk_ligand

isomesh cavity, PRMFILE_cav1, 0.99
