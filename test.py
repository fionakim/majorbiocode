# -*- coding: utf-8 -*-
from Bio import SeqIO
import os

def split_single_seq(f, output_dir):
    '''
    author： jinlinfang
    date：20170125
    实现将目标fasta文件分割为数个文件，
    每个文件只包含其一条序列，且文件名为seq_name.fa,所有文件放在output_dir里
    :param output_dir:
    :return:
    '''
    if not os.path.exists(output_dir):
        os.mkdir(output_dir)

    seq_records = SeqIO.parse(f, 'fasta')
    for seq_record in seq_records:
        seq_seq = seq_record.seq
        seq_name = seq_record.name
        line = '>{}\n{}\n'.format(seq_name, seq_seq)
        open(os.path.join(output_dir, seq_name + '.fa'), 'w').write(line)

if __name__ == '__main__':
    fa = 'Z:\\pollen_wall_gene_family\\data\\seedgene\\protein\\FAR_family_seed_gene_protein_.fa'
    out = 'Z:\\pollen_wall_gene_family\\data\\seedgene\\protein\\test_single'
    split_single_seq(fa,out)

