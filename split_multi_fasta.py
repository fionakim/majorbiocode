# -*- coding: utf-8 -*-

# __author__ = 'linfang.jin'
# time: 2017/1/4 11:41
import re
import argparse
import subprocess
import os

def check_folder(folder):
    if not os.path.isdir(folder):
        os.mkdir(folder)
    return 0

def get_seq_name(f):
    name = ""
    for line in open(f):
        m = re.search(r'^>(\S+)\s+', line)
        if m:
            name = m.group(1)
            break
    if name:
        return str(name)
    else:
        return os.path.basename(f).split(".")[0]


parser = argparse.ArgumentParser(
    description='usage: split_multi_fasta.py -i multi_seq_fasta   -o  single_seq_fasta_dir ')
parser.add_argument('-i', '--input', help="input multi_seq_fasta", default=False)
parser.add_argument('-o', '--out', help="output single_seq_fasta_root_dir", default=False)
args = parser.parse_args()

input_fa = args.input
out_dir = args.out
check_folder(out_dir)
cmd = "awk 'BEGIN {n_seq=0;} /^>/ {{file=sprintf(\""+out_dir+"/myseq%d.fa\",n_seq);} print >> file; n_seq++; next;} { print >> file; }' < "+input_fa
pro = subprocess.call(cmd, shell=True)
for piece_file in os.listdir(out_dir):
    piece_file_path = os.path.join(out_dir, piece_file)
    seq_name = get_seq_name(piece_file_path)
    filename = "chr"+seq_name + ".fa"
    new_piece_file_path = os.path.join(out_dir, filename)
    subprocess.call("mv %s %s" % (piece_file_path, new_piece_file_path),shell=True)
