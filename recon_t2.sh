#!/bin/bash

list=$1
#year=2011
threads=4 # this is unused

adni=/ifs/scratch/pimri/posnerlab/1anal/adni
adnidata=/ifs/scratch/pimri/posnerlab/1anal/adni/data/nii

CMD1=/ifs/scratch/pimri/posnerlab/1anal/adni/adni_on_c2b2/job/cmd1.${list}
rm -rf $CMD1

for s in `cat \$adnidata/\$list`
do
echo $s
SUBJECTS_DIR=$adnifs

IMPATH=$adnidata
#EXPERTOPT=$SUBJECTS_DIR/expert.opt
FLAIR=`ls $IMPATH/${s}_*FLAIR.nii.gz`
T1=`ls $IMPATH/${s}*SPGR*.nii.gz`
SUBJECT=${s}_1mm_flair

recon1=/ifs/scratch/pimri/posnerlab/1anal/adni/adni_on_c2b2/job/recon1.${s}
rm -rf $recon1

if [ -z "$t1" ];then flair_arg= ;else flair_arg="-FLAIR $FLAIR -FLAIRpial"; fi

### 1 INITIAL RECON-ALL
cat<<EOC >$recon1
recon-all -all -s ${SUBJECT} -i $T1 $flair_arg -qcache
EOC

chmod +x $recon1

cat<<-EOM >>$CMD1
$recon1
EOM
done


$code/fsl_sub_hpc_6 -t $CMD1
echo $CMD1

#for s in `cat $adnidata/$list`
#do
#recon2=/ifs/scratch/pimri/posnerlab/1anal/adni/adni_on_c2b2/job/recon2.${s}
#rm -rf $recon2

#if [ -z "$t1" ];then hippo_arg="-hippocampal-subfields-T1" ;else hippo_arg="-hippocampal-subfields-T1T2 $FLAIR flair"; fi

### 2 HIPPOCAMPAL SEGMENTATION
#cat<<EOC >$recon2
#recon-all -s ${SUBJECT} $hippo_arg -itkthreads ${threads} 
#EOC

#chmod +x $recon2


#cat<<-EOM >>$CMD2
#$recon2
#EOM
#done

#echo $CMD2
#echo $code/fsl_sub_hpc_3 -j $prejobid -s smp,$threads -l /ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job -t $CMD2
