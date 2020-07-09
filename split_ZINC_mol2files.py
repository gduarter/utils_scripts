#!/usr/bin/env python
import sys
from numpy import array, array_split

### This script breaks larger mulitmol2 files (argv1)      ###
### into argv2 small chunks                                ###
### Usage: python split_ZINC_mol2files.py library.mol2 50  ###
### Written by Guilherme D. R. Matos and Lauren E. Prentis ###

infilename = sys.argv[1]
chunk_num = int(sys.argv[2])
infile = open(infilename, 'r')

print(f"File to split:\t{infilename}")
print(f"Number of chunks:\t{chunk_num}")
print("Starting partition procedure.")

# Find total number of lines
lines = infile.readlines()
num_lines = len(lines)

# Find the position of each "@<TRIPOS>MOLECULE" entry
start_mol = [] # list of indices with the "@<TRIPOS>MOLECULE" entry
for idx, line in enumerate(lines):
    if "@<TRIPOS>MOLECULE" in line:
        start_mol.append(idx)

# Find end position of each molecule

## IMPORTANT: This portion of the script is valid for molecules 
## taken from ZINC. If the mol2 files were produced by DOCK6 you
## need to take in consideration the comments preceded by a string
## made of lots of pound signs.
## In this case, it is more useful to identify where molecules end
## instead and then discover their starting points.

tmp = start_mol[1:] #First index is 0, there's no negative index
tmp.append(num_lines) #Remember that it counts from 0 and the last line equals to (num_lines-1)
end_mol = []
for idx in tmp:
    end_mol.append(idx -1)

# Split into chunk_num files
indices = array([start_mol,end_mol])
indices = indices.transpose()
chunks = array_split(indices, chunk_num)

# Create chunk files
for i, chunk in enumerate(chunks):
    name = f"{infilename.split('.')[0]}_{i}.mol2"
    # Identify the indices in `lines` where the chunk
    # begins and ends
    start_idx = chunk[0][0] # First line with @<TRIPOS>MOLECULE
    end_idx = chunk[-1][1] # End of last molecule in chunk
    # Define lines to be printed to file
    to_file = lines[start_idx:end_idx+1]
    with open(name, "w+") as outfile:
        for elem in to_file:
            outfile.write(elem)

print(f"{infilename} split into {chunk_num} chunks")


