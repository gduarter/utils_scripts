#!/bin/sh
#SBATCH --partition=rn-long-40core
#SBATCH --time=72:00:00
#SBATCH --nodes=2
#SBATCH --ntasks=8
#SBATCH --job-name=refine_covid
#SBATCH --output=%x-%j.o


# Functions
slurm_info_out(){
echo "============================= SLURM JOB ================================="
date
echo 
echo " The job will be started on the following node(s):"
echo $SLURM_JOB_NODELIST
echo
echo "Slurm user:                   $SLURM_JOB_USER"
echo "Run directory:                $(pwd)"
echo "Job ID:                       $SLURM_JOB_ID"
echo "Job name:                     $SLURM_JOB_NAME"
echo "Partition:                    $SLURM_JOB_PARTITION"
echo "Number of nodes:              $SLURM_JOB_NUM_NODES"
echo "Number of tasks:              $SLURM_NTASKS"
echo "Submitted from:               $SLURM_SUBMIT_HOST:$SLURM_SUBMIT_DIR"
echo "========================================================================="
echo
echo "--- SLURM job-script output ----"
}

slurm_startjob(){

################################
### WRITE YOUR COMMANDS HERE ###
################################

echo "Job started"
date

### NVT Equilibration

gmx grompp -f equil_nvt.mdp -c minimize.gro -p model.top -o equil_nvt.tpr
mpirun -np 16 gmx_mpi mdrun -deffnm equil_nvt

### NPT Equilibration 1

gmx grompp -f equil_npt.mdp -c equil_nvt.gro -p model.top -o equil_npt.tpr
mpirun -np 16 gmx_mpi mdrun -deffnm equil_npt

### NPT Equilibration 2

gmx grompp -f equil_npt2.mdp -c equil_npt -p model.top -o equil_npt2.tpr
mpirun -np 16 gmx_mpi mdrun -deffnm equil_npt2


date
echo "Job done"
}

### Include GMX stuff
source /gpfs/projects/rizzo/zzz.programs/gromacs-2019.4_intel/bin/GMXRC.bash 
slurm_info_out
slurm_startjob







