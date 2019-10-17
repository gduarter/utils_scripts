#!/bin/bash

# Author: Guilherme Duarte R. Matos
# Date: September 13, 2019


############# File check ###############
helpFunction(){
    echo ""
    echo "Usage: $0 -l ligandpdb -r receptorpdb"
    echo "Both parameters are needed"
    echo -e "\t-l ligand's filename"
    echo -e "\t-r receptor's filename"
    exit 1 # Exits script after printing help
}

# Assign typed in arguments to variables
while getopts "l:r:" opt
do
    case $opt in
        l ) LIG_NAME="$OPTARG";;
        r ) REC_NAME="$OPTARG";;
        ? ) helpFunction ;;
    esac
done

# Prints helpFunction in case there's only one parameter or
# parameters are missing
if [ -z "${LIG_NAME}" ] || [ -z "${REC_NAME}" ]
then
    echo "Some or all of the parameters are missing";
    helpFunction
fi
########################################


## Prep for AMBER simulations
# You can check the Amber manual for more details
# use antechamber to assign force field parameters for the ligand
echo "Script started at: "
date
echo "Starting Antechamber"
# run antechamber
antechamber -i ${LIG_NAME}.pdb -fi pdb -o ${LIG_NAME}.mol2 -fo mol2 -at gaff -c bcc -rn LIG -nc -1
# 'gaff2' is the force field
# 'bcc' indicates the method which generated the partial charges

# check missing force field parameters with parmchk2
echo "Starting parmchk2"
parmchk2 -i ${LIG_NAME}.mol2 -f mol2 -o ${LIG_NAME}.frcmod

# Create input files for tleap
############################### TLEAP INPUT FILE ###############################
cat << EOF > tleap.in
#!/usr/bin/sh

### Load Protein force field
source leaprc.protein.ff14SB
### Load GAFF force field (for our ligand)
source leaprc.gaff
### Load TIP3P (water) force field
source leaprc.water.tip3p
### Load Ions frcmod for the tip3p model
loadamberparams frcmod.ionsjc_tip3p
### Needed so we can use igb=8 model
set default PBradii mbondi3
### Load Protein pdb file
rec=loadpdb ${REC_NAME}.pdb
### Load Ligand frcmod/mol2
loadamberparams ${LIG_NAME}.frcmod
lig=loadmol2 ${LIG_NAME}.mol2

### Create gas-phase complex
gascomplex= combine {rec lig}
### Write gas-phase pdb
savepdb gascomplex complex_gas.pdb

### Write gas-phase toplogy and coord files for MMGBSA calc
saveamberparm gascomplex complex_gas.prmtop complex_gas.rst7
saveamberparm rec ${REC_NAME}.prmtop ${REC_NAME}.rst7
saveamberparm lig ${LIG_NAME}.prmtop ${LIG_NAME}.rst7

### Create solvated complex (albeit redundant)
solvcomplex= combine {rec lig}

### Solvate the system
solvateoct solvcomplex TIP3PBOX 12.0

### Neutralize system (it will add either Na or Cl depending on net charge)
addions solvcomplex Cl- 0
addions solvcomplex Na+ 0

### Write solvated pdb file
savepdb solvcomplex complex_solv.pdb

### Check system
charge solvcomplex
check solvcomplex
### Write Solvated topology and coordinate files
saveamberparm solvcomplex complex_solv.prmtop complex_solv.rst7
quit
EOF
######################### END OF TLEAP INPUT FILE ###############################

# generate simulation files with tleap
echo "Starting tleap:"
tleap -f tleap.in

# Generate simulation control files
#################################
cat << EOF > 01.min.mdin
#!/usr/bin/sh
Minmize all the hydrogens
&cntrl
imin=1,           ! Minimize the initial structure
maxcyc=5000,    ! Maximum number of cycles for minimization
ntb=1,            ! Constant volume
ntp=0,            ! No pressure scaling
ntf=1,            ! Complete force evaluation
ntwx= 1000,       ! Write to trajectory file every ntwx steps
ntpr= 1000,       ! Print to mdout every ntpr steps
ntwr= 1000,       ! Write a restart file every ntwr steps
cut=  8.0,        ! Nonbonded cutoff in Angstroms
ntr=1,            ! Turn on restraints
restraintmask=":1-131 & !@H=", ! atoms to be restrained
restraint_wt=5.0, ! force constant for restraint
ntxo=1,           ! Write coordinate file in ASCII format
ioutfm=0,         ! Write trajectory file in ASCII format
/
EOF

#################################
cat << EOF > 02.equil.mdin
#!/usr/bin/sh
MD simualation
&cntrl
imin=0,           ! Perform MD
nstlim=50000      ! Number of MD steps
ntb=2,            ! Constant Pressure
ntc=1,            ! No SHAKE on bonds between hydrogens
dt=0.001,         ! Timestep (ps)
ntp=1,            ! Isotropic pressure scaling
barostat=1        ! Berendsen
taup=0.5          ! Pressure relaxtion time (ps)
ntf=1,            ! Complete force evaluation
ntt=3,            ! Langevin thermostat
gamma_ln=2.0      ! Collision Frequency for thermostat
ig=-1,            ! Random seed for thermostat
temp0=298.15      ! Simulation temperature (K)
ntwx= 1000,       ! Write to trajectory file every ntwx steps
ntpr= 1000,       ! Print to mdout every ntpr steps
ntwr= 1000,       ! Write a restart file every ntwr steps
cut=  8.0,        ! Nonbonded cutoff in Angstroms
ntr=1,            ! Turn on restraints
restraintmask=":1-131 & !@H=", ! atoms to be restrained
restraint_wt=5.0, ! force constant for restraint
ntxo=1,           ! Write coordinate file in ASCII format
ioutfm=0,         ! Write trajectory file in ASCII format
iwrap=1,          ! iwrap is turned on
/
EOF

#################################
cat << EOF > 03.min.mdin
#!/usr/bin/sh
Minmize all the hydrogens
&cntrl
imin=1,           ! Minimize the initial structure
maxcyc=1000,    ! Maximum number of cycles for minimization
ntb=1,            ! Constant volume
ntp=0,            ! No pressure scaling
ntf=1,            ! Complete force evaluation
ntwx= 1000,       ! Write to trajectory file every ntwx steps
ntpr= 1000,       ! Print to mdout every ntpr steps
ntwr= 1000,       ! Write a restart file every ntwr steps
cut=  8.0,        ! Nonbonded cutoff in Angstroms
ntr=1,            ! Turn on restraints
restraintmask=":1-131 & !@H=", ! atoms to be restrained
restraint_wt=2.0, ! force constant for restraint
ntxo=1,           ! Write coordinate file in ASCII format
ioutfm=0,         ! Write trajectory file in ASCII format
/
EOF

#################################
cat << EOF > 04.min.mdin
#!/usr/bin/sh
Minmize all the hydrogens
&cntrl
imin=1,           ! Minimize the initial structure
maxcyc=1000,    ! Maximum number of cycles for minimization
ntb=1,            ! Constant volume
ntp=0,            ! No pressure scaling
ntf=1,            ! Complete force evaluation
ntwx= 1000,       ! Write to trajectory file every ntwx steps
ntpr= 1000,       ! Print to mdout every ntpr steps
ntwr= 1000,       ! Write a restart file every ntwr steps
cut=  8.0,        ! Nonbonded cutoff in Angstroms
ntr=1,            ! Turn on restraints
restraintmask=":1-131 & !@H=", ! atoms to be restrained
restraint_wt=0.1, ! force constant for restraint
ntxo=1,           ! Write coordinate file in ASCII format
ioutfm=0,         ! Write trajectory file in ASCII format
/
EOF

#################################
cat << EOF > 05.min.mdin
#!/usr/bin/sh
Minmize all the hydrogens
&cntrl
imin=1,           ! Minimize the initial structure
maxcyc=1000,    ! Maximum number of cycles for minimization
ntb=1,            ! Constant volume
ntp=0,            ! No pressure scaling
ntf=1,            ! Complete force evaluation
ntwx= 1000,       ! Write to trajectory file every ntwx steps
ntpr= 1000,       ! Print to mdout every ntpr steps
ntwr= 1000,       ! Write a restart file every ntwr steps
cut=  8.0,        ! Nonbonded cutoff in Angstroms
ntr=1,            ! Turn on restraints
restraintmask=":1-131 & !@H=", ! atoms to be restrained
restraint_wt=0.05, ! force constant for restraint
ntxo=1,           ! Write coordinate file in ASCII format
ioutfm=0,         ! Write trajectory file in ASCII format
/
EOF

#################################
cat << EOF > 06.equil.mdin
#!/usr/bin/sh
MD simualation
&cntrl
imin=0,           ! Perform MD
nstlim=50000      ! Number of MD steps
ntb=2,            ! Constant Pressure
ntc=1,            ! No SHAKE on bonds between hydrogens
dt=0.001,         ! Timestep (ps)
ntp=1,            ! Isotropic pressure scaling
barostat=1        ! Berendsen
taup=0.5          ! Pressure relaxtion time (ps)
ntf=1,            ! Complete force evaluation
ntt=3,            ! Langevin thermostat
gamma_ln=2.0      ! Collision Frequency for thermostat
ig=-1,            ! Random seed for thermostat
temp0=298.15      ! Simulation temperature (K)
ntwx= 1000,       ! Write to trajectory file every ntwx steps
ntpr= 1000,       ! Print to mdout every ntpr steps
ntwr= 1000,       ! Write a restart file every ntwr steps
cut=  8.0,        ! Nonbonded cutoff in Angstroms
ntr=1,            ! Turn on restraints
restraintmask=":1-131 & !@H=", ! atoms to be restrained
restraint_wt=1.0, ! force constant for restraint
ntxo=1,           ! Write coordinate file in ASCII format
ioutfm=0,         ! Write trajectory file in ASCII format
iwrap=1,          ! iwrap is turned on
/
EOF

#################################
cat << EOF > 07.equil.mdin
#!/usr/bin/sh
MD simulation
&cntrl
imin=0,           ! Perform MD
nstlim=50000      ! Number of MD steps
ntx=5,            ! Positions and velocities read formatted
irest=1,          ! Restart calculation
ntc=1,            ! No SHAKE on for bonds with hydrogen
dt=0.001,         ! Timestep (ps)
ntb=2,            ! Constant Pressure
ntp=1,            ! Isotropic pressure scaling
barostat=1        ! Berendsen
taup=0.5          ! Pressure relaxtion time (ps)
ntf=1,            ! Complete force evaluation
ntt=3,            ! Langevin thermostat
gamma_ln=2.0      ! Collision Frequency for thermostat
ig=-1,            ! Random seed for thermostat
temp0=298.15      ! Simulation temperature (K)
ntwx= 1000,       ! Write to trajectory file every ntwx steps
ntpr= 1000,       ! Print to mdout every ntpr steps
ntwr= 1000,       ! Write a restart file every ntwr steps
cut=  8.0,        ! Nonbonded cutoff in Angstroms
ntr=1,            ! Turn on restraints
restraintmask=":1-131 & !@H=", ! atoms to be restrained
restraint_wt=0.5, ! force constant for restraint
ntxo=1,           ! Write coordinate file in ASCII format
ioutfm=0,         ! Write trajectory file in ASCII format
iwrap=1,          ! iwrap is turned on
/
EOF

#################################
cat << EOF > 08.equil.mdin
#!/usr/bin/sh
MD simulations
&cntrl
imin=0,           ! Perform MD
nstlim=50000      ! Number of MD steps
ntx=5,            ! Positions and velocities read formatted
irest=1,          ! Restart calculation
ntc=1,            ! No SHAKE on for bonds with hydrogen
dt=0.001,         ! Timestep (ps)
ntb=2,            ! Constant Pressure
ntp=1,            ! Isotropic pressure scaling
barostat=1        ! Berendsen
taup=0.5          ! Pressure relaxtion time (ps)
ntf=1,            ! Complete force evaluation
ntt=3,            ! Langevin thermostat
gamma_ln=2.0      ! Collision Frequency for thermostat
ig=-1,            ! Random seed for thermostat
temp0=298.15      ! Simulation temperature (K)
ntwx= 1000,       ! Write to trajectory file every ntwx steps
ntpr= 1000,       ! Print to mdout every ntpr steps
ntwr= 1000,       ! Write a restart file every ntwr steps
cut=  8.0,        ! Nonbonded cutoff in Angstroms
ntr=1,            ! Turn on restraints
restraintmask=":1-131@CA,C,N", ! atoms to be restrained
restraint_wt=0.1, ! force constant for restraint
ntxo=1,           ! Write coordinate file in ASCII format
ioutfm=0,         ! Write trajectory file in ASCII format
iwrap=1,          ! iwrap is turned on
/
EOF

#################################
cat << EOF > 09.equil.mdin
#!/usr/bin/sh
MD simulations
&cntrl
imin=0,           ! Perform MD
nstlim=50000      ! Number of MD steps
ntx=5,            ! Positions and velocities read formatted
irest=1,          ! Restart calculation
ntc=1,            ! No SHAKE on for bonds with hydrogen
dt=0.001,         ! Timestep (ps)
ntb=2,            ! Constant Pressure
ntp=1,            ! Isotropic pressure scaling
barostat=1        ! Berendsen
taup=0.5          ! Pressure relaxtion time (ps)
ntf=1,            ! Complete force evaluation
ntt=3,            ! Langevin thermostat
gamma_ln=2.0      ! Collision Frequency for thermostat
ig=-1,            ! Random seed for thermostat
temp0=298.15      ! Simulation temperature (K)
ntwx= 1000,       ! Write to trajectory file every ntwx steps
ntpr= 1000,       ! Print to mdout every ntpr steps
ntwr= 1000,       ! Write a restart file every ntwr steps
cut=  8.0,        ! Nonbonded cutoff in Angstroms
ntr=1,            ! Turn on restraints
restraintmask=":1-131@CA,C,N", ! atoms to be restrained
restraint_wt=0.1, ! force constant for restraint
ntxo=1,           ! Write coordinate file in ASCII format
ioutfm=0,         ! Write trajectory file in ASCII format
iwrap=1,          ! iwrap is turned on
/
EOF

#################################
cat << EOF > 10.prod.mdin
#!/usr/bin/sh
MD simulations
&cntrl
imin=0,           ! Perform MD
nstlim=5000000,   ! Number of MD steps
ntx=5,            ! Positions and velocities read formatted
irest=1,          ! Restart calculation
ntc=2,            ! SHAKE on for bonds with hydrogen
dt=0.002,         ! Timestep (ps)
ntb=2,            ! Constant Pressure
ntp=1,            ! Isotropic pressure scaling
barostat=1        ! Berendsen
taup=0.5          ! Pressure relaxtion time (ps)
ntf=2,            ! No force evaluation for bonds with hydrogen
ntt=3,            ! Langevin thermostat
gamma_ln=2.0      ! Collision Frequency for thermostat
ig=-1,            ! Random seed for thermostat
temp0=298.15      ! Simulation temperature (K)
ntwx= 2500,       ! Write to trajectory file every ntwx steps
ntpr= 2500,       ! Print to mdout every ntpr steps
ntwr= 5000000,    ! Write a restart file every ntwr steps
cut=8.0,          ! Nonbonded cutoff in Angstroms
ntr=1,            ! Turn on restraints
restraintmask=":1-287@CA,C,N", ! atoms to be restrained
restraint_wt=0.1, ! force constant for restraint
ntxo=1,           ! Write coordinate file in ASCII format
ioutfm=0,         ! Write trajectory file in ASCII format
iwrap=1,          ! iwrap is turned on
EOF

#################################

date

echo "End of script"
