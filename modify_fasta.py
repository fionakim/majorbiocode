# -*- coding: utf-8 -*-
# __author__ = fiona
# time: 2017/02/2017/2/23 19:11

import os
import fileinput
import Bio
from Bio import SeqIO

input = 'F:\\new_small_study\\src_data\\shsp_seq\\shsp_seq.fasta'
out = 'F:\\new_small_study\\src_data\\shsp_seq\\shsp_seq_simple_id.fasta'
handle = open(out,'w')
seq_Records = SeqIO.parse(input,'fasta')
for record in seq_Records:
	new_record = ">{}\n{}\n".format(record.id,record.seq)
	handle.write(new_record)
	
handle.close()
