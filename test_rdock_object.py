from rdock import Rdock

rd = Rdock('1gpk_ligand.sd','1gpk_rdock.mol2', debug=True)

rd.dockruns = 12

#rd._write_parmfile()

#rd._make_activesite()


#rd.dock()

rd.dock_parallel()

#print(rd.get_best_rmsd())

#print(rd.get_scores())

#rd.pymol()

#del rd 



