#!/bin/bash
#usage: recon_1.sh list_t1_batch32_*
cd /global/cscratch1/sd/jcha9928/anal/fs_tbd
sleep 0.5

list=`ls batch32*`
#N=`wc ${1} | awk '{print $1}'`

echo $list
threads=1

fs_tbd=/global/cscratch1/sd/jcha9928/anal/fs_tbd

CMD_batch=/global/cscratch1/sd/jcha9928/anal/fs_tbd/job/slurmjob.recon.fs_tbd.batch
rm -rf $CMD_batch

####################################################################################
cat<<EOA >$CMD_batch
#!/bin/bash -l
#SBATCH -N 2
#SBATCH -C haswell
#SBATCH -q premium
#SBATCH -J recon
#SBATCH --mail-user=jiook.cha@nyspi.columbia.edu
#SBATCH --mail-type=ALL
#SBATCH -t 30:00:00
#SBATCH -L cscratch1
#OpenMP settings:
export OMP_NUM_THREADS=1
export OMP_PLACES=threads
export OMP_PROC_BIND=true
echo start............................................
echo "working directory is `pwd`"
EOA
#####################################################################

i=1
for l in `echo $list`
do

batchname=`echo $l`
datafolder=/global/cscratch1/sd/jcha9928/anal/fs_tbd/data

CMD=/global/cscratch1/sd/jcha9928/anal/fs_tbd/job/cmd.recon.fs_tbd.${batchname}
rm -rf $CMD

log=/global/cscratch1/sd/jcha9928/anal/fs_tbd/job/log.recon.${batchname}
rm -rf $log

#############################################################################################
cat<<EOC >$CMD
  #!/bin/bash
  source ~/.bashrc_jiook
  FREESURFER_HOME=/global/homes/j/jcha9928/app/freesurfer
  source $FREESURFER_HOME/SetUpFreeSurfer.sh
  SUBJECTS_DIR=/global/cscratch1/sd/jcha9928/anal/fs_tbd
  module load parallel
  sleep 3
  cd /global/cscratch1/sd/jcha9928/anal/fs_tbd
  
  ### using GNIU parallel###
  echo "cat $list | parallel --delay .2 --jobs $N \"ulimit -m 4000000 && ulimit -v 4000000 && \
    srun -n 1 -c 1 --cpu_bind=cores /global/cscratch1/sd/jcha9928/anal/ABCD/abcd_nersc_code/job/cmd.recon.{} \"" >>$CMD_batch 

#  cat $l | parallel --delay .2 --jobs 32 "ulimit -m 4000000 && ulimit -v 4000000 && recon-all \
#  -s {} \
#  -i ${datafolder}/{}_acq-HCP_T1w.nii.gz \
#  -hippocampal-subfields-T1 \
#  -all \
#  -qcache"  
  
  #################use this when there is no T2w images###################
  #cat $l | parallel --jobs 32 recon-all \
  #-s {} \
  #-i ${datafolder}/anat/{}_t1w.nii.gz \
  #-hippocampal-subfields-T1 ${datafolder}/anat/{}_t2w.nii.gz  \
  #-all \
  #-qcache 
  
  echo "I THINK RECON-ALL IS DONE BY NOW"
EOC

#############################################################################################
chmod +x $CMD

echo "srun -N 1 -n 1 -c 32 --cpu_bind=cores $CMD > ${log} 2>&1 &">>$CMD_batch
echo "sleep 0.1">>$CMD_batch

i=$(($i+1))
#echo $i

done

echo "wait" >> $CMD_batch
### batch submission

echo $CMD_batch
chmod +x $CMD_batch 
echo sbatch $CMD_batch


#$code/fsl_sub_hpc_2 -s smp,$threads -l /ifs/scratch/pimri/posnerlab/1anal/adni/adni_on_c2b2/job -t $CMD_batch
#$code/fsl_sub_hpc_6 -l /ifs/scratch/pimri/posnerlab/1anal/adni/adni_on_c2b2/job -t $CMD_batch
