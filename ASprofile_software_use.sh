##ASprofile使用流程

#1. 生成ref.fa的.hdrs 文件
~/app/bioinfo/rna/ASprofile.b-1.0.4/count_ref.pl ref.fa 
#注：此hdrs文件名与ref.fa同名，与其处于同一个文件夹下

#2.extract-as：从coffcompare后的combined.gtf中抽提as事件
#cuffcompare结果里的转录本和ref.gtf 文件里的关系有：qual, contained, new splice isoform, intron-located, pre-mRNA fragment, repeat 等。在ASprofile中作者仅用了 ‘contained’, or ‘new splice isoforms’ 作为有高置信度的转录本。
#[usage] ./extract-as txptgtf genome_hdrs [-r tmap goldref]
#例子:
~/app/bioinfo/rna/ASprofile.b-1.0.4/extract-as  /mnt/ilustre/users/sanger-dev/workspace/20161019/Single_assembly_module_tophat_cufflinks/Assembly/Cuffcompare/output/cuffcmp.combined.gtf ref.fa > test_asprofile.txt

#3. summarize_as.pl：运行summarize_as生成一个包含各种可变剪切事件的非冗余列表
#[usage] ./summarize_as.pl gtf_file as_file -p prefix
#例子:
perl ./summarize_as.pl /mnt/ilustre/users/sanger-dev/workspace/20161019/Single_assembly_module_tophat_cufflinks/Assembly/Cuffcompare/output/cuffcmp.combined.gtf   ~/sg-users/wangzhaoyue/Eukaryote/tophat2/test_asprofile.txt -p ~/sg-users/wangzhaoyue/Eukaryote/tophat2/test-sum
#注：会生成 prefix.as.summary 和 prefix.as.nr两个文件.其中.nr文件里的事件id也有可能有多行记录，主要由于每一行记录的此编号事件在起始坐标上有局部的不同。例子如下：
#grep "1218049" test-sum.as.nr 
#1218049	MSKIP_OFF	XLOC_036715	21	44787920	44801398	44777417,44801706	-
#1218049	MSKIP_OFF	XLOC_036715	21	44787920	44788095	44777417,44801706	-
#1218049	MSKIP_OFF	XLOC_036715	21	44785666	44788095	44777417,44801706	-
#1218049	MSKIP_OFF	XLOC_036715	21	44779144	44788095	44777417,44801706	-

#4. extract-as-fpkm 提取AS事件的表达量
#[usage] ./extract-as-fpkm txptgtf genome_hdrs eventsnr -W wiggle_file
#例子：N组与D组样品的AS事件表达量文件
for sample in NoS1 NoS2 NoS3 DeS1 DeS2 DeS3 
do
~/app/bioinfo/seq/bedtools-2.25.0/bin/genomeCoverageBed  -ibam ~/sg-users/wangzhaoyue/Eukaryote/tophat2/${sample}.bam.sorted.bam  -g ref.fa.chr.len  -d > test.${sample}.bam.cov.wiggle
~/app/bioinfo/rna/ASprofile.b-1.0.4/extract-as-fpkm /mnt/ilustre/users/sanger-dev/workspace/20161019/Single_assembly_module_tophat_cufflinks/Assembly/Cuffcompare/output/cuffcmp.combined.gtf ref.fa test_asprofile.txt -W test.${sample}.bam.cov.wiggle >test_asprofile-fpkm-${sample}.txt
done
#注：-wiggle is what？
#答： wiggle格式，是基因组上每个位点上覆盖度的文件，一般由bam获得
#~/app/bioinfo/seq/bedtools-2.25.0/bin/genomeCoverageBed -ibam ~/sg-users/wangzhaoyue/Eukaryote/tophat2/NoS1.bam.sorted.bam  -g ref.fa.chr.len  -d > file.wiggle

#5. collect-fpkm 
#[usage] /mnt/ilustre/users/sanger-dev/app/bioinfo/rna/ASprofile.b-1.0.4/collect_fpkm.pl set1,set2,... -s set_id
#例子：

/mnt/ilustre/users/sanger-dev/app/program/perl-5.24.0/bin/perl  /mnt/ilustre/users/sanger-dev/app/bioinfo/rna/ASprofile.b-1.0.lustre/users/sanger-dev/sg-users/jinlinfang/tooltest/txpt_gtf/DeS1_out.gtf  /mnt/ilustre/users/sanger-dev/workspace/20170122/Single_asprofile_as_linfang_2/AsprofileAs/DeS1.as -p /mnt/ilustre/users/sanger-dev/workspace/20170122/Single_asprofile_as_linfang_2/AsprofileAs/DeS1

