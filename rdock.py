# rDock python object

import os, re
import tempfile
import subprocess
import pandas as pd
from io import StringIO
import random

class Rdock(object):
	def __init__(self, ligandfile, receptorfile, outfile='/tmp/tester',autoboxligand = None, debug=False):
		self.ligandfile = ligandfile
		self.receptorfile = receptorfile
		self.dockruns = 50
		# -n <nRuns> - number of runs/ligand (default=1)
		self.n = 1
		if autoboxligand == None:
			self.autoboxligand = self.ligandfile
		else:
			self.autoboxligand = autoboxligand
		self.rdock = 'rbdock'
		self.debug = debug
		#Temporary files
		self.logfile = outfile + '.log'
		self.dockfile = outfile + '_dock'
		#self.minimfile = outfile + '_minim.pdbqt'
		(self.customfile_fd, self.customfile) = tempfile.mkstemp()
		self.tempfiles = []
		self.parmtemplate = """RBT_PARAMETER_FILE_V1.00
TITLE rDock_python_object_docking

RECEPTOR_FILE XXXRECEPTORXXX
RECEPTOR_FLEX 3.0

##################################################################
### CAVITY DEFINITION: REFERENCE LIGAND METHOD
##################################################################
SECTION MAPPER
    SITE_MAPPER RbtLigandSiteMapper
    REF_MOL XXXAUTOBOXLIGANDXXXX
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
END_SECTION"""

	def __del__(self):
		if not self.debug:
			for fil in [self.logfile, self.dockfile, self.dockfile + '.sd', self.customfile, self.customfile + '.as'] + self.tempfiles:
				self.deletefile(fil)
		try:
			os.close(self.customfile_fd)
		except:
			if self.debug: print("Exception in closing file descriptor")


	def deletefile(self, filename):
		if os.path.exists(filename):
			os.remove(filename)
		else:
			if self.debug:
				print("can't remove; %s does not exist"%filename)

	def execute_cmd(self,command):
		ext_process = subprocess.Popen(command.split(" "), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		return ext_process.communicate()
	
	def append_log(self,text):
		with open(self.logfile, "ab") as logfile:
		    logfile.write(text)

	def print_log(self):
		with open(self.logfile, "r") as logfile:
			print(logfile.read())


	def _write_parmfile(self):
		#Write the temporary parmsfile:
		parmstext = re.sub('XXXRECEPTORXXX',self.receptorfile, self.parmtemplate)
		parmstext = re.sub('XXXAUTOBOXLIGANDXXXX', self.autoboxligand, parmstext)
		tfile = open(self.customfile, "w")
		if self.debug: print(parmstext)
		tfile.write(parmstext)
		tfile.close()

	def _make_activesite(self):
		#Check if Parmfile is greater than 0 in size
		if os.stat(self.customfile).st_size == 0:
			self._write_parmfile()

		command = 'rbcavity -r %s -was'%self.customfile
		if self.debug: print(command)
		#Execute and append to log
		self.append_log(self.execute_cmd(command)[0])		

			
	def dock(self):
		#Check if active site file exists
		if not os.path.exists(self.customfile + '.as'):
			self._make_activesite()
		ligand = self.ligandfile
		parmfile = self.customfile
		if self.debug: print("Docking using %s"%self.customfile)
		# Dock using the customfile
		command = '%s -r %s -p dock.prm -n %s -i %s -o %s' % (self.rdock, self.customfile, self.n, ligand, self.dockfile)
		if self.debug: print(command)
		
		#self.append_log(self.execute_cmd(command)[0])


	def dock_parallel(self,n=4):
		#Check if active site file exists
		if not os.path.exists(self.customfile + '.as'):
			self._make_activesite()
		ligand = self.ligandfile
		receptor = self.receptorfile
		parmfile = self.customfile
		#Use a simple approach to parallelizing
		processes = []
		dockfiles = [self.dockfile + "_%s"%i for i in range(n)]
		for dockfile in dockfiles:
			#dockfile = self.dockfile + "_%s"%i
			#print(dockfile)
			command = '%s -r %s -p dock.prm -n %s -i %s -o %s -s %s' % (self.rdock, self.customfile, self.dockruns/n, ligand, dockfile, random.randint(0,100000000))
			f= os.tmpfile()
			#f = tempfile.TemporaryFile()
			p = subprocess.Popen(command.split(" "), stdout = f)
			processes.append((p,f))
		#Wait for processes to end in turn (secure all closed)
		for p,f in processes:
			p.wait()
			if self.debug:
				f.seek(0)
				print(f.read())
			f.close()

		#Concatenate output
		results = ""
		for dockfile in dockfiles:
			with open(dockfile + '.sd', "r") as resultfile:
				results = results + resultfile.read()
			self.deletefile(dockfile + '.sd')
		#Write to the dockfile			
		with open(self.dockfile + '.sd','w') as dockfile:
			dockfile.write(results)

	def get_best_rmsd(self):
		#use sdrmsd and sdreport to get scores and rmsd.
		command = ('sdrmsd %s %s -o %s')%(self.autoboxligand, self.dockfile + '.sd',self.dockfile + '_rmsd.sd')
		self.execute_cmd(command)
		#Move the new file back
		command = "mv %s %s"%(self.dockfile + '_rmsd.sd', self.dockfile + '.sd')
		os.system(command)
		command = 'sdreport -cSCORE,RMSD %s'%(self.dockfile + '.sd')
		#Load as a dataframe from a stringIO conversion of the output of the command
		results = pd.DataFrame.from_csv(StringIO(unicode(self.execute_cmd(command)[0])))
		#use argmin of Scores to find best RMSD
		best_rmsd = results.RMSD[results.SCORE.argmin()]
		self.append_log("Best RMSD: %s\n"%best_rmsd )
		return best_rmsd

	def get_scores(self):
		command = 'sdreport -cSCORE %s'%(self.dockfile + '.sd')
		#Load as a dataframe from a stringIO conversion of the output of the command
		results = pd.DataFrame.from_csv(StringIO(unicode(self.execute_cmd(command)[0])))
		return results.SCORE

	def get_result_csv(self):
		command = 'sdreport -cSCORE %s'%(self.dockfile + '.sd')
		return self.execute_cmd(command)[0]


	def sort_poses(self):
		command = "sdsort -n -f'SCORE' %s > %s"%(self.dockfile + '.sd', self.dockfile + '_sorted.sd')
		os.system(command)
		command = "mv %s %s"%(self.dockfile + '_sorted.sd', self.dockfile + '.sd')
		os.system(command)


	def pymol(self):
		command = "pymol %s %s %s"%(self.receptorfile, self.ligandfile, self.dockfile +'.sd')
		os.system(command)

