#!/bin/bash
#usage: recon_1.sh list_t1_batch60_aa

list=${1}
N=`wc ${1} | awk '{print $1}'`

echo $list
threads=1

#abcd=/global/cscratch1/sd/jcha9928/anal/ABCD/

CMD_batch=/global/cscratch1/sd/jcha9928/anal/fs_tbd/job/slurmjob.recon.fs_tbd.batch
rm -rf $CMD_batch

####################################################################################
cat<<EOA >$CMD_batch
#!/bin/bash -l
#SBATCH -N $((($N+31)/32))
#SBATCH -C haswell
#SBATCH -q premium
#SBATCH -J recon
#SBATCH --mail-user=jiook.cha@nyspi.columbia.edu
#SBATCH --mail-type=ALL
#SBATCH -t 00:05:00
#SBATCH -L cscratch1
#OpenMP settings:
#export OMP_NUM_THREADS=32
#export OMP_PLACES=threads
#export OMP_PROC_BIND=true
echo start............................................
echo "working directory is `pwd`"
EOA
#####################################################################

i=1
for s in `cat $list`
do
#s=`echo $SUBJECT | egrep -o '[0-9]{8}'`
CMD=/global/cscratch1/sd/jcha9928/anal/fs_tbd/job/cmd.recon.${s}
rm -rf $CMD
rm -rf /global/cscratch1/sd/jcha9928/anal/fs_tbd/job/log.recon.${SUBJECT}

#CMD_sub=/lus/theta-fs0/projects/AD_Brain_Imaging/anal/ABCD/abcd_alcf_code/job/cmd_sub.recon.${s}
#rm -rf $CMD_sub

SUBJECT=${s}
#echo ${SUBJECT}
datafolder=/global/cscratch1/sd/jcha9928/anal/fs_tbd/data
  
#############################################CMD#####################################
cat<<EOC >$CMD
#!/bin/bash
source ~/.bashrc_jiook
FREESURFER_HOME=/global/homes/j/jcha9928/app/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh
#SUBJECTS_DIR=/global/cscratch1/sd/jcha9928/anal/ABCD/fs
#mkdir \$DW_JOB_STRIPED/fs
#SUBJECTS_DIR=\$DW_JOB_STRIPED/fs
SUBJECTS_DIR=/global/cscratch1/sd/jcha9928/anal/fs_tbd
ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1

#recon-all -all -s ${SUBJECT} -i ${t1} ${t2_arg} ${hippo_arg} -parallel -openmp 64 
rm \${SUBJECTS_DIR}/$SUBJECT/scripts/IsRunning*

ulimit -m 4000000 && ulimit -v 4000000

recon-all -s ${s} -i ${datafolder}/${s}_acq-HCP_T1w.nii.gz -hippocampal-subfields-T1 -all -qcache

echo "I THINK RECON-ALL IS DONE BY NOW"
EOC
####################################################################################

chmod +x $CMD


done

#echo "cat $list | parallel --delay .2 --jobs $N \" /global/cscratch1/sd/jcha9928/anal/fs_tbd/job/cmd.recon.{} \"" >>$CMD_batch 
echo "cat $list | parallel --delay .2 --jobs $N \" /global/cscratch1/sd/jcha9928/anal/fs_tbd/job/cmd.recon.{} > /global/cscratch1/sd/jcha9928/anal/fs_tbd/job/log.recon.{} 2>&1 \"" >>$CMD_batch 


#echo "aprun -n 1 -N 1 -d 64 -j 1 -cc depth -e OMP_NUM_THREADS=64 $CMD > ./job/log.recon.${SUBJECT} 2>&1 &">>$CMD_batch 
#echo "srun -N 1 -n 1 -c 1 --cpu_bind=cores $CMD > ./job/log.recon.${SUBJECT} 2>&1 &">>$CMD_batch
echo "echo check if it's done">>$CMD_batch

#echo "wait" >> $CMD_batch

### batch submission

echo $CMD_batch
chmod +x $CMD_batch 
sbatch $CMD_batch


#$code/fsl_sub_hpc_2 -s smp,$threads -l /ifs/scratch/pimri/posnerlab/1anal/adni/adni_on_c2b2/job -t $CMD_batch
#$code/fsl_sub_hpc_6 -l /ifs/scratch/pimri/posnerlab/1anal/adni/adni_on_c2b2/job -t $CMD_batch
