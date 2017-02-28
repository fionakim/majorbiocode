#MapSplice是Kai Wang等人于2010年发表Nucleic Acids Research上的具有高度特异性和敏感性的转录组测序比对算法。由于大多数内含子剪切位点具有GT-AG模式，即经典剪切位点，为保证准确性并节省时间，TopHat只报告含有经典剪切位点的内含子。MapSplice并不依赖剪切位点的特性或内含子的长度，它可以更好地检测到新的经典剪切位点和非经典剪切位点。MapSplice在比对的质量与序列的多样性之间做了一个很好的权衡。算法分为两个步骤：标记比对（tag alignment）和拼接推理(splice inference)。在第一阶段，被标记的mRNA与参考基因组G进行比对，产生可能的组合。之后，出现一个或者更多标记比对的剪接位点被筛选出来进行分析，根据比对的质量和多样性打分.


##MapSplice使用流程

#1. 安装MapSplice,这样就可以在./bin文件夹底下产生可执行文件
make

#2.使用MapSplice
#sample_run.sh 样例：

#! /bin/bash  

#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J mapsplice_batch_mapping
#SBATCH -t 10-00:00
#SBATCH -p SANGERDEV
#SBATCH --mem=100G
#SBATCH -o /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/code/bug/mapsplice_batch_mapping_%j.out
#SBATCH -e /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/code/bug/mapsplice_batch_mapping_%j.err
 
MAPSPLICE_DIR=/mnt/ilustre/users/sanger-dev/app/bioinfo/rna/MapSplice-v2.1.8 
REF_GENOME=/mnt/ilustre/users/sanger-dev/app/database/refGenome/Animal/Primates/human/ref
BOWTIE_INDEX=/mnt/ilustre/users/sanger-dev/app/database/refGenome/Animal/Primates/human/ref
FQ_DIR=/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/test/fq_a_QC/human-lipei-project
OUTPUT_DIR=/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/test/mapsplice_test

for sample in NoS1 NoS2 NoS3 DeS1 DeS2 DeS3
do
SAMPLE_OUTPUT_DIR=${OUTPUT_DIR}/${sample}_mapsplice_mapping
READ_FILE_END1=${FQ_DIR}/${sample}_trim1.fq  
READ_FILE_END2=${FQ_DIR}/${sample}_trim2.fq
python $MAPSPLICE_DIR/mapsplice.py -1 $READ_FILE_END1 -2 $READ_FILE_END2 -c $REF_GENOME -x $BOWTIE_INDEX -p 8 -o ${SAMPLE_OUTPUT_DIR} 2 > ${SAMPLE_OUTPUT_DIR}/log.txt


