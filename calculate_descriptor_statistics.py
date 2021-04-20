import os, sys
import glob
import numpy as np
from scipy import stats

if sys.version_info[:1] < (3,):
    sys.exit("This is a Python 3 script. Python 2.7 is deprecated and SHOULD NOT be used")

if len(sys.argv) != 2:
    sys.exit(f"USAGE: python {sys.argv[0]} denovo_build_mol2file")

# Important variables
mol2file = sys.argv[1]
observables = ["Stereocenters", "cLogP", "ESOL", "QED", "SA_Score"]#, "Layer_Completed"]

# Create txt files for analysis
for elem in observables:
    try:
        os.system(f"grep {elem} {mol2file} > {elem}_grep.txt") 
    except:
        print("Check MOL2 file")

# text files containing the data
all_txt = glob.glob("*_grep.txt")

tofile = f""
for elem in all_txt:
    tmpArr = np.genfromtxt(elem, dtype=float, usecols=2, comments="!")
    observable = elem.split("_grep")[0]
    if elem != "Stereocenters":
        mean = tmpArr.mean()
        std = tmpArr.std()
        message = f''' {observable}          
     average  = {mean:.2f}
     std dev  = {std:.2f}
 ======================
        '''
    else:
        median = np.median(tmpArr)
        mode = stats.mode(tmpArr)[0][0]
        freq = 100 * stats.mode(tmpArr)[1][0] / float(len(tmpArr))
        message = f'''
    median    = {median}
    mode      = {mode}
    mode freq = {freq:.2f}
=======================
        '''
    print(message)
    print(" ")
    tofile = tofile + "\n" + message

# Create name for results file
filename = mol2file.strip(".mol2")

# Save to file so you don't have to re-run this script many times 
with open(f"statistics_{filename}.txt", "w+") as f:
    f.write(tofile)

# Erase grep.txt files
for elem in all_txt:
    os.system(f"rm {elem}")

print("Analysis done!")
print(" ")
