# -*- coding: utf-8 -*-

# __author__ = 'linfang.jin'
# time: 2017/1/3 19:54

import re
import argparse
import fileinput

parser = argparse.ArgumentParser(
    description='usage: python chr_len.py -i ')
parser.add_argument('-i', '--input', help="input fasta file", default=False)
parser.add_argument('-o', '--out', help="output chr length file", default=False)
args = parser.parse_args()

hdrs = args.input
out = args.out
fw_o = open(out,'w')
for line in fileinput.input(hdrs):
    m = re.search(r'^>(\S+)\s+/len=(\d+)\s+',line)
    if m:
        chr_id = m.group(1)
        chr_len = m.group(2)
        newline = "chr%s\t%s\n" % (str(chr_id),str(chr_len))
        fw_o.write(newline)

fw_o.close()




