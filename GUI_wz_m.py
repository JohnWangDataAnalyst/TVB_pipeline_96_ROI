#!/opt/python 3.3/bin/python3
# -*- coding: utf-8 -*-

import tkinter as tk
import os
import sys
import distutils.dir_util
import subprocess
import pprint
#import messagebox

WDprocessing_index = 0
Dataprocessing_index = 0
EnvironSet_index = 0
fields = ["Object ID", "T1 MRI Data Path", "dWMRI Data Path", "fMRI(Bold) Data Path", "Working Directory", "Number of ROI"]

curWD = os.getcwd()
EnvironVariablesDict = {"SGE_ROOT":"/usr/local/ge2011.11/",\
                        "FREESURFER_HOME":"/opt/freesurfer",\
                        "FSLDIR":"/opt/fsl",\
                        "scripts_path":"Scripts",\
                        "MRTrixDIR":"/opt/mrtrix2/bin",\
                        "MRTrix3DIR":"/home/jwang/local/MRtrix3bin",\
                        "FSLSUBALREADYRUN":"true"}

PathList = ["/home/jwang/codes/fsl/bin:/opt/afni:/usr/local/ge2011.11/bin/linux-x64:/sbin"]

SourceList = ["/opt/source/octave.sh", \
              "/opt/source/afni_fsl.sh",\
              "/opt/source/freesurfer.sh",\
              "/opt/freesurfer/SetUpFreeSurfer.sh",\
              "/opt/fsl/etc/fslconf/fsl.sh"]

fields_check =[ "T1 Prerocessing with FreeSurfer",\
                "DWI Prerocessing with FreeSurfer", \
                "DWI Prerocessing with MrTrix2", \
                "fMRI Preprocessing", \
                 "Generate mask",\
                 "Tracking", \
                 "Compute SC matrix", \
                 "Aggregate SC matrix", \
                 "Convert to TVB format and clean up results"]



script_dict = {

"title": "#!/bin/bash\n\
echo \"*************************************************************\"\n \
echo \"***               TVB empirical data pipeline             ***\" \n \
echo \"*************************************************************\"\n\
#unset SGE_ROOT \n",

"T1 Prerocessing with FreeSurfer":"echo \"************ T1 preprocessing with FreeSurfer *******\"\n\
qsub -V -q bigmem_16.q -l h_vmem=16G -cwd -N reconAll_${subID} ${scripts_path}/FreeSurfer_recon-all.sh \n",


"DWI Prerocessing with FreeSurfer":"echo \"********** DWI preprocessing with FreeSurfer ********\"\n\
qsub -hold_jid reconAll_${subID} -V -q bigmem_16.q -l h_vmem=16G -cwd -N dtRecon_${subID} ${scripts_path}/FreeSurfer_dt-recon.sh\n",


"DWI Prerocessing with MrTrix2":"echo \"********** DWI preprocessing with MRtrix2 ***********\"\n\
qsub -hold_jid dtRecon_${subID} -V -q bigmem_16.q -l h_vmem=16G -cwd -N mrPre_${subID} ${scripts_path}/MRtrix_prepro.sh\n",

"fMRI Preprocessing": "echo \"**************** fMRI preprocessing *****************\"\n\
qsub -hold_jid reconAll_${subID} -V -q bigmem_16.q -l h_vmem=16G -cwd -N fmri_1_${subID} ${scripts_path}/fmriFC1.sh\n\
qsub -hold_jid fmri_1_${subID} -V -q bigmem_16.q -l h_vmem=16G -cwd -N fmri_2_${subID} ${scripts_path}/fmriFC2.sh\n\
qsub -hold_jid feat5_stop -V -q bigmem_16.q -l h_vmem=16G -cwd -N fmri_3_${subID} ${scripts_path}/fmriFC3.sh\n",

"Generate mask": "echo \"****************** Generate mask ********************\"\n\
qsub -hold_jid dtRecon_${subID} -V -q bigmem_16.q -l h_vmem=16G -cwd -N mask_${subID} ${scripts_path}/mask.sh\n",

"Tracking": "echo \"********************* Tracking **********************\"\n\
qsub -hold_jid mask_${subID} -V -q bigmem_16.q -l h_vmem=16G -cwd -N tracking_1_${subID} ${scripts_path}/runTracking1.sh\n\
qsub -hold_jid mask_${subID} -V -q bigmem_16.q -l h_vmem=16G -cwd -N tracking_2_${subID} ${scripts_path}/runTracking2.sh\n\
qsub -hold_jid mask_${subID} -V -q bigmem_16.q -l h_vmem=16G -cwd -N tracking_3_${subID} ${scripts_path}/runTracking3.sh\n\
qsub -hold_jid mask_${subID} -V -q bigmem_16.q -l h_vmem=16G -cwd -N tracking_4_${subID} ${scripts_path}/runTracking4.sh\n\
qsub -hold_jid mask_${subID} -V -q bigmem_16.q -l h_vmem=16G -cwd -N tracking_5_${subID} ${scripts_path}/runTracking5.sh\n",

"Compute SC matrix":"echo \"************** Compute SC matrix  *******************\"\n\
qsub -hold_jid tracking_1_${subID},tracking_2_${subID},tracking_3_${subID},tracking_4_${subID},tracking_5_${subID} -V -q bigmem_16.q -l h_vmem=16G -cwd -N SC_${subID} ${scripts_path}/computeSC.sh\n",

"Aggregate SC matrix":"echo \"************** Aggregate SC matrix  *****************\"\n\
qsub -hold_jid SC_${subID} -V -q bigmem_16.q -l h_vmem=16G -cwd -N aggSC_${subID} ${scripts_path}/aggregateSC.sh\n",

"Convert to TVB format and clean up results":"echo \"**** Convert to TVB format and clean up results  ****\"\n\
qsub -hold_jid aggSC_${subID},tracking_5_${subID} -V -q bigmem_16.q -l h_vmem=16G -cwd -N convert_${subID} ${scripts_path}/convert2TVB.sh\n"}

"""
files_prepare_scripts = ["#!/bin/bash", \
                             "cd /", \
                             "if [ ! -d "+entries["Working Directory"].get()+"]; then", \
                             "mkdir "+entries["Working Directory"].get(), \
                             "fi", \
                             "cd "+entries["Working Directory"].get() ]"""


"""
files_prepare_scripts = ["#!/bin/bash", \
                             "cd /", \
                             "if [ ! -d "+entries["Working Directory"].get()+"]; then", \
                             "mkdir "+entries["Working Directory"].get(), \
                             "fi", \
                             "cd "+entries["Working Directory"].get() ]"""

def fetch(entries):
    for key in entries:

        text = entries[key].get()
        print('%s: "%s"' % (key, entries[key]))


def makeform(root, fields):
    entries = {}
    for field in fields:
        row = tk.Frame(root)
        lab = tk.Label(row, text = field, anchor = 'w')
        ent = tk.Entry(row)
        row.pack(side = tk.TOP, fill = tk.X, padx = 5, pady = 5)
        lab.pack(side = tk.LEFT)
        ent.pack(side = tk.RIGHT, expand = tk.YES, fill = tk.X)
        entries[field] = ent
    return entries


def makeform_check(root, fields):
    checks = {}
    for field in fields_check:
        row = tk.Frame(root)
        lab = tk.Label(row, text = "", anchor = 'w')
        var = tk.IntVar()
        ent = tk.Checkbutton(row,text = field, variable = var)
        row.pack(side = tk.TOP, fill = tk.X, padx = 5, pady = 5)
        lab.pack(side = tk.LEFT)
        ent.pack(side = tk.LEFT)
        checks[field] = var
    return checks




def WDprocessing(entries):
    global WDprocessing_index
    if WDprocessing_index == 1:
        ans_wd = input("changing working directory? y/n")
        ans_sub = input("changing working subject? y/n")

    Path_Check_Correct = True
    # check if the inputs from users are empty
    if WDprocessing_index == 0 or (WDprocessing_index == 1 and ans_wd.lower() in ["y", "yes"]):

        for key in entries:
            if entries[key].get() == " ":
                print("please input"+" "+key)
                Path_Check_Correct  = False
            elif key not in [ "Object ID", "Number of ROI" ]and not os.path.exists(entries[key].get()):
                if key == "Working Directory":
                    os.makedirs(entries[key].get())

                else:
                    print("please input valid"+" "+ key)
                    Path_Check_Correct  = False

    if Path_Check_Correct and (WDprocessing_index == 0 or (WDprocessing_index == 1 and ans_wd.lower() in ["y", "yes"])):
        #current_path = os.getcwd()
        distutils.dir_util.copy_tree(curWD+"/TVB", entries["Working Directory"].get())

    if Path_Check_Correct and (WDprocessing_index == 0 or \
            (WDprocessing_index == 1 and (ans_sub.lower() in ["y", "yes"] or ans_wd.lower() in ["y", "yes"]))):

        subjects_path = entries["Working Directory"].get()+"/subjects"
        subjectid_path = entries["Working Directory"].get()+"/subjects"+"/"+entries["Object ID"].get()
        rawdata_path = entries["Working Directory"].get()+"/subjects"+"/"+entries["Object ID"].get()+"/RAWDATA"
        dti_path = entries["Working Directory"].get()+"/subjects"+"/"+entries["Object ID"].get()+"/RAWDATA/DTI"
        T1_path = entries["Working Directory"].get()+"/subjects"+"/"+entries["Object ID"].get()+"/RAWDATA/MPRAGE"
        Bold_path = entries["Working Directory"].get()+"/subjects"+"/"+entries["Object ID"].get()+"/RAWDATA/BOLD-EPI"


        if not os.path.exists(subjects_path):
            os.makedirs(subjects_path)
        if not os.path.exists(subjectid_path):
            os.makedirs(subjectid_path)
        if not os.path.exists(rawdata_path):
            os.makedirs(rawdata_path)
        if not os.path.exists(dti_path):
            os.makedirs(dti_path)
        if not os.path.exists(T1_path):
            os.makedirs(T1_path)
        if not os.path.exists(Bold_path):
            os.makedirs(Bold_path)
        WDprocessing_index = 1

def Dataprocessing(entries):
    global Dataprocessing_index
    dti_path = entries["Working Directory"].get()+"/subjects"+"/"+entries["Object ID"].get()+"/RAWDATA/DTI"
    T1_path = entries["Working Directory"].get()+"/subjects"+"/"+entries["Object ID"].get()+"/RAWDATA/MPRAGE"
    Bold_path = entries["Working Directory"].get()+"/subjects"+"/"+entries["Object ID"].get()+"/RAWDATA/BOLD-EPI"
    if WDprocessing_index == 0:
        ans_wd_re = input("need run working directory process? y/n")

    if WDprocessing_index == 1 or (WDprocessing_index == 0 and ans_wd_re.lower() in ["n", "no"]):
        if len(os.listdir(entries["dWMRI Data Path"].get())) > 0:
            distutils.dir_util.copy_tree(entries["dWMRI Data Path"].get(), dti_path)
        if len(os.listdir(entries["fMRI(Bold) Data Path"].get()))>0:
            distutils.dir_util.copy_tree(entries["fMRI(Bold) Data Path"].get(), Bold_path)
        if len(os.listdir(entries["T1 MRI Data Path"].get())) > 0:
            distutils.dir_util.copy_tree(entries["T1 MRI Data Path"].get(), T1_path)
        Dataprocessing_index = 1




def EnvironSet(entries):
    global EnvironSet_index
    if WDprocessing_index*Dataprocessing_index == 0:
        ans_env_conf = input("are you sure you have done working directory and data process? y/n")
    if WDprocessing_index == 1 & Dataprocessing_index == 1 or \
            (WDprocessing_index*Dataprocessing_index == 0 and ans_env_conf.lower()in ["y", "yes"]):
        #os.environ["PATH"] += os.pathsep + os.pathsep.join(PathList)
        #os.environ["LD_LIBRARY_PATH"]+=os.pathsep+os.pathsep.join(["/opt/lib.exported"])
        for key in EnvironVariablesDict:
            os.environ[key] = EnvironVariablesDict[key]
        os.environ["subID"] = entries["Object ID"].get()
        os.environ["numROI"] = entries["Number of ROI"].get()
        os.environ["rootPath"] = entries["Working Directory"].get()

        for source in SourceList:
            command = ['bash', '-c', 'source '+source]
            proc = subprocess.Popen(command, stdout=subprocess.PIPE)

            for line in proc.stdout:
                (key, _, value) = line.partition("=")
                os.environ[key]=value

            proc.communicate()

        pprint.pprint(dict(os.environ))

        EnvironSet_index = 1


def sh_file_generation(entries, checks):
    open(entries["Working Directory"].get()+"/TVB_pipe.sh", "w")
    f = open(entries["Working Directory"].get()+"/TVB_pipe.sh", "r+")
    os.chmod(entries["Working Directory"].get()+"/TVB_pipe.sh", 0o755)
    f.write(script_dict["title"])
    for field in fields_check:
        if checks[field].get() ==1:
            f.write(script_dict[field])
    f.close()
    os.chdir(entries["Working Directory"].get())
    #qsub_call = "qsub -V -q bigmem_16.q -l h_vmem=16G -cwd %s"
    #qsub_call = "./"
    #subprocess.call("unset SGE_ROOT", shell=True)
    subprocess.call("./TVB_pipe.sh", shell=True)


"""
        open("files_prepare_scripts", "a")
        
        f = open("files_prepare_scripts", "r+")
        for script in files_prepare_scripts:
            f.write(script+"\n")

        f.close()"""




# class Checkbar(tk.Frame):
# 	def __init__(self, parent=None, picks=[], side = tk.LEFT, anchor = tk.W):
# 		tk.Frame.__init__(self, parent)
# 		self.vars = []
# 		for pick in picks:
# 			var = tk.IntVar()
# 			self.row = tk.Frame(self)
# 			chk = tk.Checkbutton(self.row,text = pick, variable = var)
# 			chk.pack(side = side, anchor = anchor, expand = tk.YES)
# 			self.vars.append(var)

# 	def state(self):
# 		return map((lambda var: var.get()), self.vars)





def quit_process():
    os.chdir(curWD)
    top.quit



if __name__ == '__main__':
    top = tk.Tk()
    ents = makeform(top, fields)
    #top.bind('<Return>', (lambda event, e=ents: fetch(e)))
    row = tk.Frame(top)
    title_check = tk.Label(row, text = "Choose the processes:")
    row.pack(side = tk.TOP, fill = tk.X, padx = 5, pady = 5)
    title_check.pack(side = tk.LEFT)
    chks = makeform_check(top,fields_check)
    b1 = tk.Button(top,text = 'Quit', command = top.quit)
    b1.pack(side =tk.LEFT, padx = 5, pady = 5)
    b2 = tk.Button(top,text = 'Run Working Directory Process', command = (lambda e=ents: WDprocessing(e)))
    b2.pack(side =tk.LEFT, padx = 5, pady = 5)

    b4 = tk.Button(top,text = 'Run Data Copy Process', command = (lambda e=ents: Dataprocessing(e)))
    b4.pack(side =tk.LEFT, padx = 5, pady = 5)

    b3 = tk.Button(top,text = 'Environ Set', command = (lambda e=ents: EnvironSet(e)))
    b3.pack(side =tk.LEFT, padx = 5, pady = 5)

    b5 = tk.Button(top,text = 'Sh Script', command = (lambda e1=ents, e2=chks: sh_file_generation(e1,e2)))
    b5.pack(side =tk.LEFT, padx = 5, pady = 5)


    top.mainloop()


#     CheckVar1 = tk.IntVar()
# CheckVar2 = tk.IntVar()
# CheckVar3 = tk.IntVar()
# CheckVar4 = tk.IntVar()
# CheckVar5 = tk.IntVar()
# CheckVar6 = tk.IntVar()
# CheckVar7 = tk.IntVar()
# CheckVar8 = tk.IntVar()
# CheckVar9 = tk.IntVar()

# tk.Label(top, text = "Object ID").grid(row = 0)
# tk.Label(top, text = "T1 MRI Data Path").grid(row = 1)
# tk.Label(top, text = "dWMRI Data Path").grid(row = 2)
# tk.Label(top, text = "fMRI(Bolt) Data Path").grid(row = 3)

# tk.Label(top, text = "Working Directory").grid(row = 4)





# e1 = tk.Entry(top)
# e2 = tk.Entry(top)
# e3 = tk.Entry(top)
# e4 = tk.Entry(top)
# e5 = tk.Entry(top)

# e1.grid(row = 0, column = 1)
# e2.grid(row = 1, column = 1)
# e3.grid(row = 2, column = 1)
# e4.grid(row = 3, column = 1)
# e5.grid(row = 4, column = 1)

# tk.Label(top, text = "Choose the processes:").grid(row = 6, sticky = tk.W)

# k=7;

# ObjectId = e1.get()
# T1Path = e2.get()
# DtiPath = e3.get()
# BoltPath = e4.get（）
# WorkPath = e5.get ()


# tk.Checkbutton(top, text = "T1 Prerocessing with FreeSurfer", variable = CheckVar1).grid(row = 0+k, sticky = tk.W)

# tk.Checkbutton(top, text = "DWI Prerocessing with FreeSurfer", variable = CheckVar2).grid(row = 1+k, sticky = tk.W)

# tk.Checkbutton(top, text = "DWI Prerocessing with MrTrix2", variable = CheckVar3).grid(row = 2+k, sticky = tk.W)
# tk.Checkbutton(top, text = "fMRI Preprocessing ", variable = CheckVar4).grid(row = 3+k, sticky = tk.W)
# tk.Checkbutton(top, text = "Generate mask ", variable = CheckVar5).grid(row = 4+k, sticky = tk.W)
# tk.Checkbutton(top, text = "Tracking ", variable = CheckVar6).grid(row = 5+k, sticky = tk.W)
# tk.Checkbutton(top, text = "Compute SC matrix ", variable = CheckVar7).grid(row = 6+k, sticky = tk.W)
# tk.Checkbutton(top, text = "Aggregate SC matrix", variable = CheckVar8).grid(row = 7+k, sticky = tk.W)
# tk.Checkbutton(top, text = "Convert to TVB format and clean up results ", variable = CheckVar9).grid(row = 8+k, sticky = tk.W)






#top.mainloop()
