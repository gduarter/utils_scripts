#!/usr/bin/env python

# Basic python packages
import os, shutil
import glob, sys
import argparse
import pandas as pd

# Chemistry package
from openbabel import pybel as pb 

#####################
# UTILITY FUNCTIONS #
#####################

def define_mol2_indices( mol2file ):
    with open( mol2file, "r+" ) as f:
        lines = f.readlines()

    # Find the position of each "0 ROOT" entry
    end_mol = []
    for idx, line in enumerate(lines):
        if "0 ROOT" in line:
            end_mol.append(idx)

    # Find starting position of each molecule
    tmp = end_mol[:-1]
    start_mol = [0]
    for idx in tmp:
        start_mol.append(idx + 1)

    # Find ZINC IDs to be used as reference
    fzincids = []
    for line in lines:
        if "Name:" in line:
            zinc = line.split()[2]
            fzincids.append(zinc)

    if len(fzincids) != len(end_mol):
        print("ERROR: Number of 'Name' entries does not match number of molecules")
        sys.exit()
    else: pass

    filename = [ mol2file for i in range( len(fzincids) ) ]

    # Create dataframe containing indices and names
    df = pd.DataFrame()
    df["ZINC"] = fzincids
    df["start_idx"] = start_mol
    df["end_idx"] = end_mol
    df["file"] = filename

    return df


########
# MAIN #
########

parser = argparse.ArgumentParser()
parser.add_argument("-f", "--mol2file", help="input mol2 file", type=str, nargs=1, required=True)
args = parser.parse_args()
if len(args.mol2file) != 1:
    parser.print_help()
    sys.exit()

# Open file and read molecules
all_mols_file = args.mol2file[0] 
with open(all_mols_file, "r+") as f:
    lines = f.readlines()

# Create molecule indices dataframe
df = define_mol2_indices( all_mols_file )

# Create mol2files
for j, row in df.iterrows():
    newmol = lines[row["start_idx"]: (row["end_idx"]+1)]
    with open( f"{row['ZINC']}.mol2", "w+") as f:
        for line in newmol:
            f.write(line)

# Organize paths
root = os.getcwd()
print(f"The root directory is {root}")
mol2dir = os.path.join(root,"zzz.problematic_molecules")
dirname = all_mols_file.split(".")[0]
exptdir = os.path.join(mol2dir, dirname)
print(f"mol2 files will be stored at {exptdir}")

# Move mol2 files to their directory
os.makedirs(exptdir, exist_ok=True)
all_mol2 = glob.glob("*.mol2")
all_mol2.remove(all_mols_file)
for elem in all_mol2:
    shutil.move(os.path.join(root,f"{elem}"),os.path.join(exptdir,f"{elem}"))

# Change directory and create SDF files
os.chdir(exptdir)
for elem in all_mol2:
    for mol in pb.readfile("mol2", f"{elem}"):
        outsdf = pb.Outputfile("sdf", f"{elem[:-5]}.sdf", overwrite=True)
        outsdf.write(mol)
        outsdf.close()
os.chdir(root)



