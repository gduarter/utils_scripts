#!/bin/sh
#SBATCH --partition=rn-long-40core
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --job-name=test
#SBATCH --output=%x-%j.o

# Functions
slurm_info_out(){
echo "============================= SLURM JOB ================================="
date
echo
echo " The job will be started on the following node(s):"
echo "                              $SLURM_JOB_NODELIST"
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
## Call dock_prep script
echo "Preparing files for docking"
./prep_docking.sh -i 5tvn

## DOCK6.9 simulation
cd 07.virtual_screening
echo "Starting DOCK6.9 simulation"
dock6 -i flex.in -o flex.out
echo "Virtual screening done"
}

slurm_info_out
slurm_startjob

