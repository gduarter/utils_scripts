#!/usr/bin/env python
import sys
from numpy import array, array_split

### This script breaks larger mulitmol2 files (argv1)      ###
### into argv2 small chunks                                ###
### Usage: python split_DOCK_mol2files.py library.mol2     ###
### Written by Guilherme D. R. Matos and Lauren E. Prentis ###

infilename = sys.argv[1]
#chunk_num = int(sys.argv[2])
infile = open(infilename, 'r')

print(f"File to split:\t{infilename}")
#print(f"Number of chunks:\t{chunk_num}")
print("Starting partition procedure.")

# Find total number of lines
lines = infile.readlines()
num_lines = len(lines)
print(f"{infilename} read.")

# Find the position of each "0 ROOT" entry
end_mol = [] 
for idx, line in enumerate(lines):
    if "0 ROOT" in line:
        end_mol.append(idx)

# Find the name of each molecule
names = []
for idx, line in enumerate(lines):
    if '@<TRIPOS>MOLECULE' in line:
        names.append(lines[idx+1][:-1])

# Find starting position of each molecule
tmp = end_mol[:-1] # There is no molecule after the last one
start_mol = [0]
for idx in tmp:
    start_mol.append(idx+1)

#print(start_mol[:10], len(start_mol))
#print(end_mol[:10], len(end_mol))

# Split into chunk_num files
indices = array([start_mol,end_mol])
indices = indices.transpose()

# Create chunk files
for i, row in enumerate(indices):
    name = f"{names[i]}.mol2"
    # Identify the indices in `lines` where the chunk
    # begins and ends
    start_idx = row[0] # First line with @<TRIPOS>MOLECULE
    end_idx = row[1] # End of last molecule in chunk
    # Define lines to be printed to file
    to_file = lines[start_idx:end_idx+1]
    with open(name, "w+") as outfile:
        for elem in to_file:
            outfile.write(elem)

print(f"{infilename} split into individual molecules.")


