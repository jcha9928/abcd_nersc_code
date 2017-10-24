#!/bin/bash

#list=$1
#year=2011
threads=4
adni=/ifs/scratch/pimri/posnerlab/1anal/adni

CMD1=/ifs/scratch/pimri/posnerlab/1anal/adni/adni_on_c2b2/job/cmd1.${list}
CMD2=/ifs/scratch/pimri/posnerlab/1anal/adni/adni_on_c2b2/job/cmd2.${list}
rm -rf $CMD1
rm -rf $CMD2

for s in `cat $adnidata/$list`
do

SUBJECTS_DIR=$adnifs

IMPATH=$adnidata/${s}
#EXPERTOPT=$SUBJECTS_DIR/expert.opt
FLAIR=`ls $IMPATH/${s}_Axial_FLAIR_Axial_FLAIR.nii.gz`
T1=`ls $IMPATH/${s}_Accelerated_SAG_IR-SPGR_Accelerated_SAG_IR-SPGR.nii.gz`
SUBJECT=${s}_1mm_flair

recon1=/ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job/recon1.${s}
rm -rf $recon1

if [ -z "$t1" ];then flairarg= ;else flairarge="-FLAIR $FLAIR -FLAIRpial"; fi

### 1 INITIAL RECON-ALL
cat<<EOC >$recon1
recon-all -all -s ${SUBJECT} -i $T1 -FLAIR $FLAIR -FLAIRpial -qcache
EOC

chmod +x $recon1



cat<<-EOM >>$CMD1
$recon1
EOM
done

#prejobid=`$code/fsl_sub_hpc_6 -t $CMD1`
echo $CMD1

for s in `cat $IDP/data/$list`
do
recon2=/ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job/recon2.${s}
rm -rf $recon2

### 2 HIPPOCAMPAL SEGMENTATION
cat<<EOC >$recon2
recon-all -s ${SUBJECT} -hippocampal-subfields-T1T2 $FLAIR flair -itkthreads ${threads} 
EOC

chmod +x $recon2


cat<<-EOM >>$CMD2
$recon2
EOM
done

#echo $CMD2
echo $code/fsl_sub_hpc_3 -j $prejobid -s smp,$threads -l /ifs/scratch/pimri/posnerlab/1anal/IDP/code/idp/job -t $CMD2
