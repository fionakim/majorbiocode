#rMATS使用手册
#版本：3.2.5
#运行时间大概为30h/(3*2human sample)
#1. bam文件输入

python ~/app/bioinfo/rna/rMATS.3.2.5/RNASeq-MATS.py -b1 ~/sg-users/wangzhaoyue/Eukaryote/tophat2/NoS1.bam.sorted.bam  -b2 ~/sg-users/wangzhaoyue/Eukaryote/tophat2/DeS1.bam.sorted.bam    -gtf ~/sg-users/wangzhaoyue/Eukaryote/tophat2/ref.gtf  -o ~/sg-users/wangzhaoyue/Eukaryote/tophat2/rMATS_test_20170110 -t paired -len 150 -a 8  -c 0.05 -analysis P

#PAIRED analysis(指定分析模式为P) requires the same number of replicates per sample.The number of replicate must be greater than 2 for paired analysis.

#2. fastq格式输入


