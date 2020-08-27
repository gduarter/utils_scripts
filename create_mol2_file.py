
import sys
import pandas as pd

# Exit if not Python 3.X
if sys.version_info[:1] < (3,):
    sys.exit("This is a Python 3 script. Python 2.7 is deprecated and should not be used.")

# Check if input was properly given
if len(sys.argv) != 3:
    print("You should use the script in the following way:")
    print(f"{sys.argv[0]} DAT_file user_DAT_file\n")
    print("This code is meant to be used with a DAT output file from:")
    print(">>>>>>>> make_csv_tables_from_mol2.py <<<<<<<<")
    print("and a user-generated list of ZINC ids.")
    sys.exit()

# Assign variables
datfile = sys.argv[1]
userfile = sys.argv[2]

# From DAT_file string, figure out primary score, secondary score
# and PDB code.
sep = "_" 
primary = sep.join(datfile.split(".")[1].split("_")[:2])
secondary = sep.join(datfile.split("_")[5:7])

# Create variable to hold name of mol2file
mol2file = f"{ sep.join( datfile.split('_')[1:] )[:-4] }.mol2"

# Open mol2file and store content in a list
with open(mol2file, "r+") as f:
    lines = f.readlines()

# Read index-containing DAT file using Pandas
indices = pd.read_csv(datfile, sep="\t") ## These are separated by tabs by design

# Read selected molecules using Pandas
selected = pd.read_csv(userfile, sep=" ") # These are separated by spaces because it is easier for the user.

# Read 'lines' and print new mol2file with selected molecules
multimol = []
indices = indices[indices["Name"].isin(list(selected["Name"]))]
for idx, row in indices.iterrows():
    mol2 = lines[row["begin_idx"]:row["end_idx"]+1]
    for line in mol2:
        multimol.append(line)
with open("selected_molecules.mol2", "w+") as f:
    for line in multimol:
        f.write(line) 







