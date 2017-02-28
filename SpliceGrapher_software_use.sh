##SpliceGrapher使用流程

#特征：
#可以结合基因组注释文件，rna-seq文件，EST比对数据来寻找许多新AS事件
#使用Sam或bam文件做输入文件（任何mapping软件的输出结果都行，目前已测BWA, Bowtie, PASS, Tophat and MapSplice）；
#使用支持向量机分类器来识别剪接连接位点的序列特征，利用这些特征进行正确的剪接比对筛选
#为任意集合的剪接图计算可变剪接事件的统计信息
# 对剪接图，剪接位点，读长深度进行可视化
# 可以使用软件的pipeline，也可以使用它们的软件功能模块来建立自己的pipeline


#安装：
python setup.py install --home=/mnt/ilustre/users/sanger-dev/app/program/Python/lib/python2.7/site-packages  --install-scripts=/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/bin

#使用过程

#1. 训练SVM模型
#usage：
#Creates an organism's splice-site classifiers by performing the following steps:
#   1. Generates training data for each splice site dimer
#   2. Selects optimal parameters for each splice-site-dimer classifier
#   3. Creates a .zip file that contains the resulting classifiers

？


#2. 预测剪接图
#2.1 从sam文件里筛选出剪接位点处的比对信息
python ~/sg-users/jinlinfang/bin/sam_filter.py /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/app/SpliceGrapher-0.2.4/tutorial/alignments.sam.gz ./classifiers/Arabidopsis_thaliana.zip -o ./tutorial/filtered.sam -f ./tutorial/a_thaliana.fa.gz

#2.2 将sam文件整理为每个染色体一个sam文件
python ~/sg-users/jinlinfang/bin/sam_collate.py /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/app/SpliceGrapher-0.2.4/tutorial/filtered.sam  -d /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/app/SpliceGrapher-0.2.4/tutorial/filtered.sam.folder -z

#2.3 转sam文件为基因覆盖度文件（类似于wiggle），用于后续作图用
python ~/sg-users/jinlinfang/bin/sam_to_depths.py  /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/app/SpliceGrapher-0.2.4/tutorial/filtered.sam -o /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/app/SpliceGrapher-0.2.4/tutorial/filtered.sam.depth

#2.4 利用filtered.sam(总sam文件)，生成每个基因的splicegraph预测剪接图 ，在-d 设置的参数文件夹底下每一个染色体一个文件夹，里面是各个染色体上所有gene的model（剪接图），一个基因一个gff文件
python ~/sg-users/jinlinfang/bin/predict_graphs.py -d /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/app/SpliceGrapher-0.2.4/tutorial/predict_graphs_eg.pdf -m /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/app/SpliceGrapher-0.2.4/tutorial/a_thaliana.gff3.gz /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/app/SpliceGrapher-0.2.4/tutorial/filtered.sam.depth 

#2.5 为ref.gff3 生成剪接图文件
python ~/sg-users/jinlinfang/bin/gene_model_to_splicegraph.py  -m ./tutorial/a_thaliana.gff3.gz -A -o ./tutorial/a_thaliana.gff3.gz.splice_graph

