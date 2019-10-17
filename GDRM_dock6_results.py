#!/usr/bin/env python
# extract_data.py
#
# Extract data from test results
# by Guilherme D., September 2019
import pandas as pd
import datetime
import os, shutil
import sys
from numpy import nan
# The files are organized in the following way
#   Project space: zzz.distribution -->
#   Data folders: molecule acronym  -->
#   Test folders: name of the test -->
#   Results

# This script only does the rmsd analysis. It can be easily extended to include other
# analyses.

# Exit if not Python 3.X
if sys.version_info[:1] < (3,):
    sys.exit("This is a Python 3 script. Python 2.7 is deprecated and should not be used.")

# Check if input was properly given
if len(sys.argv) != 3:
    print("You should use the script in the following way:")
    print("{} TestName ListOfSystemsFile".format(sys.argv[0]))
    sys.exit()
testName = sys.argv[1]
systemNames = sys.argv[2]

# Read the name of the systems to be used in the test
folders = []
with open(systemNames, "r+") as f:
    lines = f.readlines()
    for line in lines:
        folders.append(line[:-1])

# Create directory for results if non-existent
root = os.getcwd()
result_path = os.path.join(root,"zzz.results_{}".format(testName))
try:
    os.makedirs(result_path)
except:
    pass

success = 0
scoring_failure = 0
sampling_failure = 0
incomplete = 0
RMSD_vals = [] # Add RMSD values to list for outputs.
category = []
# Loop over the systems' directories and find results.
for folder in folders:
    #print(folder)
    os.chdir(os.path.join(root, folder, testName))
    
    # Check if file exists
    if (not os.path.isfile("{}.{}_scored.mol2".format(folder, testName))):
        RMSD_vals.append(nan) # nan means "not a number"
        category.append('Unfinished')
        incomplete += 1
        continue
    elif (os.path.getsize("{}.{}_scored.mol2".format(folder, testName)) == 0):
        RMSD_vals.append(nan)
        category.append('Unfinished')
        incomplete += 1
        continue
    else:
        with open("{}.{}_scored.mol2".format(folder, testName), "r") as f:
            lines = f.readlines()

    # Creates an RMSD list
    RMSDList = []
    for line in lines:
        split_line = line.split()
        # The line of interest must obey the conditions below (check output, if necessary):
        if len(split_line) == 3:
            if split_line[1] == "HA_RMSDh:":
                RMSDList.append(float(split_line[2]))

    # Verifies successful poses
    # (Both score and RMSD are low)
    if RMSDList[0] <= 2.0:
        RMSD_vals.append(RMSDList[0])
        category.append('Success')
        success += 1
        continue
    else: pass

    # Verifies scoring failure
    # (RMSD is good, but score is bad)
    RMSDList.sort()
    if RMSDList[0] <= 2.0:
        RMSD_vals.append(RMSDList[0])
        category.append('Scoring failure')
        scoring_failure += 1
        continue
    else:
        RMSD_vals.append(RMSDList[0])
        category.append('Sampling failure')
        sampling_failure += 1
        continue

# Create storage object
data = pd.DataFrame()
data["System"] = folders
data["RMSD"] = RMSD_vals
data["Category"] = category

# Save to CSV file
result_file = "{}_{}.csv".format( str(datetime.date.today()), testName )
data.to_csv(result_file)
# Move to result directory
shutil.move( result_file, os.path.join(result_path,result_file) )

print("{} systems tested".format(len(folders)))
print("Successes:\t\t{} out of total -- {:.2f} %".format(success, 100*success/float(len(folders))))
print("Scoring failures:\t\t{} out of total -- {:.2f} %".format(scoring_failure, 100*scoring_failure/float(len(folders))))
print("Sampling failures:\t\t{} out of total -- {:.2f} %".format(sampling_failure, 100*sampling_failure/float(len(folders))))
print("Unfinished:\t\t{} out of total -- {:.2f} %".format(incomplete, 100*incomplete/float(len(folders))))




















