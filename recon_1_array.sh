#!/bin/bash
#usage: recon_1_array.sh b300_aa
# use this one: other versions failed
# trying single task (1 task per node)

list=${1}
N=`wc ${1} | awk '{print $1}'`

echo $list
threads=16

abcd=/global/cscratch1/sd/jcha9928/anal/ABCD/

CMD_batch=/global/cscratch1/sd/jcha9928/anal/ABCD/abcd_nersc_code/job/slurmjob.recon.batch${1}
rm -rf $CMD_batch

arrayfile=/global/cscratch1/sd/jcha9928/anal/ABCD/abcd_nersc_code/job/arrayfile.recon.batch${1}
rm -rf $arrayfile

i=1
for s in `cat /global/cscratch1/sd/jcha9928/anal/ABCD/abcd_nersc_code/\$list`
do

SUBJECT=${s}

#s=`echo $SUBJECT | egrep -o '[0-9]{8}'`
CMD=/global/cscratch1/sd/jcha9928/anal/ABCD/abcd_nersc_code/job/cmd.recon.batch${1}.${i}.${s}
rm -rf $CMD

#LOG=/global/cscratch1/sd/jcha9928/anal/ABCD/abcd_nersc_code/job/log.recon.taskid.
rm -rf global/cscratch1/sd/jcha9928/anal/ABCD/abcd_nersc_code/job/log.recon.batch${1}.taskid${i}.

#CMD_sub=/lus/theta-fs0/projects/AD_Brain_Imaging/anal/ABCD/abcd_alcf_code/job/cmd_sub.recon.${s}
#rm -rf $CMD_sub

#echo ${SUBJECT}
datafolder=/global/cscratch1/sd/jcha9928/anal/ABCD/data
t1=${datafolder}/${s}/ses-baselineYear1Arm1/anat/${s}_ses-baselineYear1Arm1_T1w.nii.gz
t2=${datafolder}/${s}/ses-baselineYear1Arm1/anat/${s}_ses-baselineYear1Arm1_T2w.nii.gz

#if [ ! -e /global/cscratch1/sd/jcha9928/anal/ABCD/fs/${SUBJECT}/scripts/recon-all.log ]; then
input_arg1="-all -i ${t1} "
  if [ ! -e $t2 ]; then t2_arg=" "
  else t2_arg=" -T2 $t2 -T2pial "
  fi

  if [ ! -e $t2 ]; then hippo_arg=" -hippocampal-subfields-T1 "
  else hippo_arg=" -hippocampal-subfields-T1T2 $t2 T1T2 "
  fi
input_arg2="${input_arg1} ${t2_arg} ${hippo_arg}"
#else 
#input_arg2="-make all "
#fi
  
#############################################CMD#####################################
cat<<EOC >$CMD
#!/bin/bash
source ~/.bashrc_jiook
FREESURFER_HOME=/global/homes/j/jcha9928/app/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh
#SUBJECTS_DIR=/global/cscratch1/sd/jcha9928/anal/ABCD/fs
mkdir -p \$DW_JOB_STRIPED/fs
SUBJECTS_DIR=\$DW_JOB_STRIPED/fs
#SUBJECTS_DIR=/global/cscratch1/sd/jcha9928/anal/ABCD/fs
ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$threads
#rm /global/cscratch1/sd/jcha9928/anal/ABCD/fs/${SUBJECT}/scripts/IsRunning*
#recon-all -all -s ${SUBJECT} -i ${t1} ${t2_arg} ${hippo_arg} -parallel -openmp 64 
recon-all -s ${SUBJECT} ${input_arg2} -parallel -openmp $threads

#echo now copying fs to local scratch
#cp -rfv \$DW_JOB_STRIPED/fs/${SUBJECT} /global/cscratch1/sd/jcha9928/anal/ABCD/fs
echo "I THINK RECON-ALL IS DONE BY NOW"
EOC
####################################################################################

chmod +x $CMD

#echo "aprun -n 1 -N 1 -d 64 -j 1 -cc depth -e OMP_NUM_THREADS=64 $CMD > ./job/log.recon.${SUBJECT} 2>&1 &">>$CMD_batch 
#echo "srun -N 1 -n 1 -c 64 --cpu_bind=threads $CMD > $LOG 2>&1 &">>$CMD_batch
############################# "-c is optional for MPI jobs"#################################
#echo "srun -N 1 -n 1 --cpu_bind=threads $CMD > $LOG 2>&1 &">>$CMD_batch

#echo "sleep 3">>$CMD_batch

i=$(($i+1))
#echo $i

echo $CMD >> $arrayfile

done

#SBATCH --tasks-per-node=8
####################################################################################
######################## BEGINNIGN OF BATCH SCRIPT ############################
####################################################################################
cat<<EOA >$CMD_batch
#!/bin/bash -l
#SBATCH -n $N
#SBATCH --array=1-$N
#SBATCH -C haswell
#SBATCH -q regular
#SBATCH -J $list
#SBATCH --mail-user=jiook.cha@nyspi.columbia.edu
#SBATCH --mail-type=ALL
#SBATCH -t 00:05:00
#SBATCH -L cscratch1
#DW jobdw capacity=10GB access_mode=striped type=scratch
#DW stage_out source=\$DW_JOB_STRIPED/fs destination=/global/cscratch1/sd/jcha9928/anal/ABCD/fs_from_dw type=directory
#OpenMP settings:

export OMP_NUM_THREADS=$threads
export OMP_PLACES=threads
export OMP_PROC_BIND=true


echo start............................................
echo "working directory is `pwd`"

echo "SLURM_JOBID: " \$SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " \$SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " \$SLURM_ARRAY_JOB_ID

#arrayfile=`echo "\`ls job/cmd.recon.batch${1}.*.* | awk -v line=\$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}'\`"`
#ls job/cmd.recon.batch${1}.*.* | awk -v line=\$SLURM_ARRAY_TASK_ID '{if (NR == line) print $0}'

echo "running array job"
$arrayfile

EOA
####################################################################################
######################## END OF BATCH SCRIPT ############################
####################################################################################
#echo "wait" >> $CMD_batch
### batch submission

echo $CMD_batch
chmod +x $CMD_batch 
echo "arrayfile is $arrayfile"
echo sbatch $CMD_batch


#$code/fsl_sub_hpc_2 -s smp,$threads -l /ifs/scratch/pimri/posnerlab/1anal/adni/adni_on_c2b2/job -t $CMD_batch
#$code/fsl_sub_hpc_6 -l /ifs/scratch/pimri/posnerlab/1anal/adni/adni_on_c2b2/job -t $CMD_batch
