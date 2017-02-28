##Spladder使用流程

#1. basic use
python .py  -a -b  -o  

##这种基础用法主要使得程序走如下流程：
#a.将注释转义为剪接图格式数据
#b.为每一个bam文件产生一个扩展的剪接图（通过插入内含子保留数据，插入可选外显子/盒式外显子/发生外显子跳跃的）
    
	
	
	
	transform annotation into splicing graph representation
    generate an augmented splicing graph for each alignment file by inferring and adding the following elements:
        insert intron retentions
        insert cassette exons
        insert new intron edges
    merge the augmented splicing graphs into a common splicing graph
    extract the following alternative splicing events:
        exon skip
        intron retention
        alternative 3'/5' splice site
        multiple exon skip
        mutually exclusive exons
    quantify all alternative splicing events on each of the provided alignment files
、

#注：想法暂且不说，一直报错，这个软件不能用，难怪没人引用
#报错：spladder报错信息看有道云笔记
