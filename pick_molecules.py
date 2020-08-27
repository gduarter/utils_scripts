#!/usr/bin/env python
import os, sys
import pandas as pd

#######################################################################
### This script reads text files containing ZINC IDs and fetch them ###
### from file-specified chunks                                      ###
#######################################################################

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


help = '''    ListOfZINCIDsFile should be a file containing one ZINC ID per line.
    Feel free to modify the code as you wish, but be careful and make
    the necessary changes to make it work for you.
'''


if sys.version_info[:1] < (3,):
    sys.exit("This is a Python 3 script. Python 2.7 is deprecated and should not be used")

if len(sys.argv) != 2:
    print(f"USAGE: python {sys.argv[0]} ListOfZINCIDsFile")

datfile = sys.argv[1]
chunk = datfile.split(".")[1].split("_")[1]
mol2file = f"{chunk}_scored.mol2"

# Get ZINC IDs from files
with open(datfile, "r+") as f:
    lines = f.readlines()
problem_ids = []
### Comment: The following lines can be modified to 
### read the ZINC ID in whichever position it is.
for line in lines:
    zinc = line.split()[0] # Each line should contain a single ZINC ID
    problem_ids.append(zinc)

# Extract all data from mol2 file
df = define_mol2_indices( mol2file )

# Prune dataframe
df = df[df["ZINC"].isin(problem_ids)]

# Open mol2 file
with open( mol2file ) as f:
    lines = f.readlines()

# Create list that will contain all lines of problematic ZINC IDs
newmol2file = []
for j, row in df.iterrows():
    newmol2file = newmol2file + lines[row["start_idx"]:(row["end_idx"]+1)]

with open(f"problems_{chunk}.mol2", "w+") as f:
    for line in newmol2file:
        f.write(line)


