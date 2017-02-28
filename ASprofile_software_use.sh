##ASprofileʹ������

#1. ����ref.fa��.hdrs �ļ�
~/app/bioinfo/rna/ASprofile.b-1.0.4/count_ref.pl ref.fa 
#ע����hdrs�ļ�����ref.faͬ�������䴦��ͬһ���ļ�����

#2.extract-as����coffcompare���combined.gtf�г���as�¼�
#cuffcompare������ת¼����ref.gtf �ļ���Ĺ�ϵ�У�qual, contained, new splice isoform, intron-located, pre-mRNA fragment, repeat �ȡ���ASprofile�����߽����� ��contained��, or ��new splice isoforms�� ��Ϊ�и����Ŷȵ�ת¼����
#[usage] ./extract-as txptgtf genome_hdrs [-r tmap goldref]
#����:
~/app/bioinfo/rna/ASprofile.b-1.0.4/extract-as  /mnt/ilustre/users/sanger-dev/workspace/20161019/Single_assembly_module_tophat_cufflinks/Assembly/Cuffcompare/output/cuffcmp.combined.gtf ref.fa > test_asprofile.txt

#3. summarize_as.pl������summarize_as����һ���������ֿɱ�����¼��ķ������б�
#[usage] ./summarize_as.pl gtf_file as_file -p prefix
#����:
perl ./summarize_as.pl /mnt/ilustre/users/sanger-dev/workspace/20161019/Single_assembly_module_tophat_cufflinks/Assembly/Cuffcompare/output/cuffcmp.combined.gtf   ~/sg-users/wangzhaoyue/Eukaryote/tophat2/test_asprofile.txt -p ~/sg-users/wangzhaoyue/Eukaryote/tophat2/test-sum
#ע�������� prefix.as.summary �� prefix.as.nr�����ļ�.����.nr�ļ�����¼�idҲ�п����ж��м�¼����Ҫ����ÿһ�м�¼�Ĵ˱���¼�����ʼ�������оֲ��Ĳ�ͬ���������£�
#grep "1218049" test-sum.as.nr 
#1218049	MSKIP_OFF	XLOC_036715	21	44787920	44801398	44777417,44801706	-
#1218049	MSKIP_OFF	XLOC_036715	21	44787920	44788095	44777417,44801706	-
#1218049	MSKIP_OFF	XLOC_036715	21	44785666	44788095	44777417,44801706	-
#1218049	MSKIP_OFF	XLOC_036715	21	44779144	44788095	44777417,44801706	-

#4. extract-as-fpkm ��ȡAS�¼��ı����
#[usage] ./extract-as-fpkm txptgtf genome_hdrs eventsnr -W wiggle_file
#���ӣ�N����D����Ʒ��AS�¼�������ļ�
for sample in NoS1 NoS2 NoS3 DeS1 DeS2 DeS3 
do
~/app/bioinfo/seq/bedtools-2.25.0/bin/genomeCoverageBed  -ibam ~/sg-users/wangzhaoyue/Eukaryote/tophat2/${sample}.bam.sorted.bam  -g ref.fa.chr.len  -d > test.${sample}.bam.cov.wiggle
~/app/bioinfo/rna/ASprofile.b-1.0.4/extract-as-fpkm /mnt/ilustre/users/sanger-dev/workspace/20161019/Single_assembly_module_tophat_cufflinks/Assembly/Cuffcompare/output/cuffcmp.combined.gtf ref.fa test_asprofile.txt -W test.${sample}.bam.cov.wiggle >test_asprofile-fpkm-${sample}.txt
done
#ע��-wiggle is what��
#�� wiggle��ʽ���ǻ�������ÿ��λ���ϸ��Ƕȵ��ļ���һ����bam���
#~/app/bioinfo/seq/bedtools-2.25.0/bin/genomeCoverageBed -ibam ~/sg-users/wangzhaoyue/Eukaryote/tophat2/NoS1.bam.sorted.bam  -g ref.fa.chr.len  -d > file.wiggle

#5. collect-fpkm 
#[usage] /mnt/ilustre/users/sanger-dev/app/bioinfo/rna/ASprofile.b-1.0.4/collect_fpkm.pl set1,set2,... -s set_id
#���ӣ�

/mnt/ilustre/users/sanger-dev/app/program/perl-5.24.0/bin/perl  /mnt/ilustre/users/sanger-dev/app/bioinfo/rna/ASprofile.b-1.0.lustre/users/sanger-dev/sg-users/jinlinfang/tooltest/txpt_gtf/DeS1_out.gtf  /mnt/ilustre/users/sanger-dev/workspace/20170122/Single_asprofile_as_linfang_2/AsprofileAs/DeS1.as -p /mnt/ilustre/users/sanger-dev/workspace/20170122/Single_asprofile_as_linfang_2/AsprofileAs/DeS1

