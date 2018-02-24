#!/bin/bash
#usage: recon_1.sh batch#

list=list_t1_batch${1}.txt

echo $list
threads=64

abcd=/lus/theta-fs0/projects/AD_Brain_Imaging/anal/ABCD/

CMD_batch=/lus/theta-fs0/projects/AD_Brain_Imaging/anal/ABCD/abcd_alcf_code/job/cobaltjob.recon.batch${1}
rm -rf $CMD_batch

####################################################################################
cat<<EOA >$CMD_batch
#!/bin/bash
#COBALT -t 720
#COBALT -n 1000
#COBALT --attrs mcdram=cache:numa=quad
#COBALT -A AD_Brain_Imaging
echo start............................................
#export n_nodes=$COBALT_JOBSIZE
#export n_mpi_ranks_per_node=202
#export n_mpi_ranks=202
#export n_openmp_threads_per_rank=64
#export n_hyperthreads_per_core=4
EOA
#####################################################################




i=1
for s in `cat /lus/theta-fs0/projects/AD_Brain_Imaging/anal/ABCD/abcd_alcf_code/\$list`
do
#s=`echo $SUBJECT | egrep -o '[0-9]{8}'`
CMD=/lus/theta-fs0/projects/AD_Brain_Imaging/anal/ABCD/abcd_alcf_code/job/cmd.recon.${s}
rm -rf $CMD

#CMD_sub=/lus/theta-fs0/projects/AD_Brain_Imaging/anal/ABCD/abcd_alcf_code/job/cmd_sub.recon.${s}
#rm -rf $CMD_sub

SUBJECT=${s}
echo ${SUBJECT}
datafolder=/lus/theta-fs0/projects/AD_Brain_Imaging/anal/ABCD/data
t1=${datafolder}/${s}/ses-baselineYear1Arm1/anat/${s}_ses-baselineYear1Arm1_T1w.nii.gz
t2=${datafolder}/${s}/ses-baselineYear1Arm1/anat/${s}_ses-baselineYear1Arm1_T2w.nii.gz
  if [ ! -e $t2 ]; then t2_arg=" "
  else t2_arg=" -T2 $t2 -T2pial "
  fi

  if [ ! -e $t2 ]; then hippo_arg=" -hippocampal-subfields-T1 "
  else hippo_arg=" -hippocampal-subfields-T1T2 $t2 T1T2 "
  fi

#############################################CMD#####################################
cat<<EOC >$CMD
#!/bin/bash
source ~/.bashrc
FREESURFER_HOME=/lus/theta-fs0/projects/AD_Brain_Imaging/app/freesurfer
source $FREESURFER_HOME/SetUpFreeSurfer.sh
SUBJECTS_DIR=/lus/theta-fs0/projects/AD_Brain_Imaging/anal/ABCD/fs
ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=64

recon-all -all -s ${SUBJECT} -i ${t1} ${t2_arg} ${hippo_arg} -parallel -openmp 64

echo "I THINK RECON-ALL IS DONE BY NOW"
EOC
####################################################################################

chmod +x $CMD

echo "aprun -n 1 -N 1 -d 64 -j 1 -cc depth -e OMP_NUM_THREADS=64 $CMD > ./job/log.recon.${SUBJECT} 2>&1 &">>$CMD_batch 
echo "sleep 0.5">>$CMD_batch

i=$(($i+1))
#echo $i

done

echo "wait" >> $CMD_batch
### batch submission

echo $CMD_batch
chmod +x $CMD_batch
qsub $CMD_batch
#$code/fsl_sub_hpc_2 -s smp,$threads -l /ifs/scratch/pimri/posnerlab/1anal/adni/adni_on_c2b2/job -t $CMD_batch
#$code/fsl_sub_hpc_6 -l /ifs/scratch/pimri/posnerlab/1anal/adni/adni_on_c2b2/job -t $CMD_batch
