#GSNAP（Genomic Short-read Nucleotide Alignment Program）是由Thomas D.Wu等人于2010年发表在bioinformatics上的一个快速、SNP兼容的转录组测序比对算法。
#它可以利用概率模型或者已知剪接位点的数据库发现非常短的以及很长的剪接序列。值得一提的是，GSNAP是本次所介绍的五种算法中唯一使用哈希算法的（Hash Table），由于哈希算法需要较大的内存空间，对设备的物理内存和运算性能要求较高。
#比如，SOAP需要大约14GB的内存来运行人类基因组的数据。为此，GSNAP采用了基因抽样的方法（sampling the genomic oligomers），每3nt取出12mers作为索引，从而把所需内存由14GB缩短到4GB。GSNAP采用的算法结构决定了其比对过程是基于核苷酸寡聚物层面的，而采用Burrows-Wheeler压缩转换算法的算法大多是基于核苷酸层面的。


##GSNAP使用流程
#1. 安装GSNAP

./configure --prefix=/mnt/ilustre/users/sanger-dev/app/bioinfo/rna/GSNAP-2015-09-29   MAX_READLENGTH=10000
make
make check
make install
#这样在${prefix}/bin底下生成可执行文件

#2. 使用GSNAP

##Setting up to build a GMAP/GSNAP database (one chromosome per FASTA entry)
##首先将物种基因组序列分割为一条序列一个文件
python ~/sg-users/jinlinfang/code/split_multi_fasta.py -i /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/test/ref/human/ref.fa   -o /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/test/ref/human/ref_fa_piece

