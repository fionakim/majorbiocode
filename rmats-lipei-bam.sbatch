#!/bin/bash
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J rmats-lipei-bam
#SBATCH -t 10-00:00
#SBATCH -p SANGERDEV
#SBATCH --mem=100G
#SBATCH -o /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/code/bug/Rmats_lipei-bam_%j.out
#SBATCH -e /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/code/bug/Rmats_lipei-bam_%j.err

export PATH=/mnt/ilustre/users/sanger-dev/app/bioinfo/rna/star-2.5/bin/Linux_x86_64:$PATH
export PYTHONPATH=/mnt/ilustre/users/sanger-dev/app/program/Python/lib/python2.7/site-packages:$PYTHONPATH
cd /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/test


python /mnt/ilustre/users/sanger-dev/app/bioinfo/rna/rMATS-3.2.2.beta/RNASeq-MATS.py -b1 /mnt/ilustre/users/sanger-dev/sg-users/yuguo/ref-rna/test-data/lipei_MJ201604191002/Pipeline/tophat_mapping/DeS1/accepted_hits.bam,/mnt/ilustre/users/sanger-dev/sg-users/yuguo/ref-rna/test-data/lipei_MJ201604191002/Pipeline/tophat_mapping/DeS2/accepted_hits.bam,/mnt/ilustre/users/sanger-dev/sg-users/yuguo/ref-rna/test-data/lipei_MJ201604191002/Pipeline/tophat_mapping/DeS3/accepted_hits.bam -b2 /mnt/ilustre/users/sanger-dev/sg-users/yuguo/ref-rna/test-data/lipei_MJ201604191002/Pipeline/tophat_mapping/NoS1/accepted_hits.bam,/mnt/ilustre/users/sanger-dev/sg-users/yuguo/ref-rna/test-data/lipei_MJ201604191002/Pipeline/tophat_mapping/NoS2/accepted_hits.bam,/mnt/ilustre/users/sanger-dev/sg-users/yuguo/ref-rna/test-data/lipei_MJ201604191002/Pipeline/tophat_mapping/NoS3/accepted_hits.bam -gtf /mnt/ilustre/users/sanger-dev/sg-users/yuguo/ref-rna/test-data/lipei_MJ201604191002/ref/ref_genome.gtf   -o /mnt/ilustre/users/sanger-dev/sg-users/yuguo/ref-rna/test-data/lipei_MJ201604191002/rmats_fastq_trimmed_output -t paired -len 150
