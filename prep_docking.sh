#!/bin/bash

# Author: Guilherme Duarte Ramos Matos
# Date: February 2019
#

#### help function #######
helpFunction(){
    echo ""
    echo "Usage: $0 -i pdbcode"
    echo "A parameter is required (lower case)"
    echo -e "\t-i PDB_code"
    exit 1 # Exits script after printing help
}

###
# Assign typed in arguments to variables
while getopts ":i:" opt
do
    case $opt in
        i ) PDB_CODE="$OPTARG";;
        ? ) helpFunction ;;
    esac
done

# Prints helpFunction in case there's only one parameter or
# parameters are missing
if [ -z "${PDB_CODE}" ]
then
    echo "You are missing a parameter";
    helpFunction
fi

########################

# This script assumes that you have prepared the ligand mol2 file,
# the receptor mol2 file with and without hydrogens, generated the
# DMS file in Chimera and created the folders (directories) where
# output files will be placed

# Checks if directories exist

directories=(02.surface_spheres 03.gridbox 04.minimize)
for element in ${directories[@]}
do
    if [ -d $element ]; then
        echo "$element exists"
    else 
        mkdir $element
    fi
done

# Name variables
LIG_NAME="${PDB_CODE}_ligand_withH"
REC_NAME_NOH="${PDB_CODE}_receptor_noH"
REC_NAME="${PDB_CODE}_receptor_withH"

cd 02.surface_spheres
[ -f ./INSPH ] && { rm INSPH; } 

# Create file on the run
echo "Creating INSPH file"
cat << EOF > INSPH
${REC_NAME_NOH}.dms
R
X
0.0
4.0
1.4
${PDB_CODE}_rec.sph
EOF

# Erase pre-existing files
[ -f ./OUTSPH ] && { rm OUTSPH; }
[ -f ./${PDB_CODE}_rec.sph ] && { rm ${PDB_CODE}_rec.sph; }
[ -f ./selected_spheres.sph ] && { rm selected_spheres.sph; }
[ -f ./temp1.ms ] && { rm temp1.ms; }
[ -f ./temp3.atc ] && { rm temp3.atc; }
if [ -f ./${PDB_CODE}_receptor_noH.dms ]; then
    echo "${PDB_CODE}_receptor_noH.dms exists"
else
    echo "You do not have prepared the ligand dms file on Chimera"
    exit 1
fi

# Generate spheres
echo "Generating spheres"
sphgen -i INSPH -o OUTSPH

# Select spheres about 10 angstrom around the ligand
echo "Selecting spheres"
sphere_selector ${PDB_CODE}_rec.sph ../01.dockprep/${LIG_NAME}.mol2 10.0

# Move out of 02.surface_spheres
cd ../
cd 03.gridbox

# create input file for showbox
[ -f ./showbox.in ] && { rm showbox.in; }
[ -f ./showbox.out ] && { rm showbox.out; }
echo "Creating showbox input file"
cat << EOF > showbox.in
Y
0.8
../02.surface_spheres/selected_spheres.sph
1
${PDB_CODE}.box.pdb
EOF

# Run showbox
echo "Running showbox"
showbox < showbox.in

# Create grid input file
[ -f ./grid.in ] && { rm grid.in; }
[ -f ./grid.out ] && { rm grid.out; }
echo "Creating grid input file"
cat << EOF > grid.in
compute_grids                             yes
grid_spacing                              0.4
output_molecule                           no
contact_score                             no
energy_score                              yes
energy_cutoff_distance                    9999
atom_model                                a
attractive_exponent                       6
repulsive_exponent                        9
distance_dielectric                       yes
dielectric_factor                         4
bump_filter                               yes
bump_overlap                              0.75
receptor_file                             ../01.dockprep/${REC_NAME}.mol2
box_file                                  ${PDB_CODE}.box.pdb
vdw_definition_file                       /gpfs/projects/AMS536/zzz.programs/dock6.9_release/parameters/vdw_AMBER_parm99.defn
score_grid_prefix                         grid
EOF

# Run grid
echo "Running grid"
grid -i grid.in -o grid.out

# Move out of 03.grid
cd ..
cd 04.minimize

# Create minimization input file
echo "Creating minimization input file"
cat << EOF > min.in
conformer_search_type                                        rigid
use_internal_energy                                          yes
internal_energy_rep_exp                                      12
internal_energy_cutoff                                       100.0
ligand_atom_file                                             ../01.dockprep/${LIG_NAME}.mol2
limit_max_ligands                                            no
skip_molecule                                                no
read_mol_solvation                                           no
calculate_rmsd                                               yes
use_rmsd_reference_mol                                       yes
rmsd_reference_filename                                      ../01.dockprep/${LIG_NAME}.mol2
use_database_filter                                          no
orient_ligand                                                no
bump_filter                                                  no
score_molecules                                              yes
contact_score_primary                                        no
contact_score_secondary                                      no
grid_score_primary                                           yes
grid_score_secondary                                         no
grid_score_rep_rad_scale                                     1
grid_score_vdw_scale                                         1
grid_score_es_scale                                          1
grid_score_grid_prefix                                       ../03.gridbox/grid
multigrid_score_secondary                                    no
dock3.5_score_secondary                                      no
continuous_score_secondary                                   no
footprint_similarity_score_secondary                         no
pharmacophore_score_secondary                                no
descriptor_score_secondary                                   no
gbsa_zou_score_secondary                                     no
gbsa_hawkins_score_secondary                                 no
SASA_score_secondary                                         no
amber_score_secondary                                        no
minimize_ligand                                              yes
simplex_max_iterations                                       1000
simplex_tors_premin_iterations                               0
simplex_max_cycles                                           1
simplex_score_converge                                       0.1
simplex_cycle_converge                                       1.0
simplex_trans_step                                           1.0
simplex_rot_step                                             0.1
simplex_tors_step                                            10.0
simplex_random_seed                                          0
simplex_restraint_min                                        yes
simplex_coefficient_restraint                                10.0
atom_model                                                   all
vdw_defn_file                                                /gpfs/projects/AMS536/zzz.programs/dock6.9_release/parameters/vdw_AMBER_parm99.defn
flex_defn_file                                               /gpfs/projects/AMS536/zzz.programs/dock6.9_release/parameters/flex.defn
flex_drive_file                                              /gpfs/projects/AMS536/zzz.programs/dock6.9_release/parameters/flex_drive.tbl
ligand_outfile_prefix                                        ${PDB_CODE}.lig.min
write_orientations                                           no
num_scored_conformers                                        1
rank_ligands                                                 no
EOF

# Run minimization
echo "Running minimization"
dock6 -i min.in -o min.out

