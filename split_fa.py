# -*- coding: utf-8 -*-

# __author__ = 'linfang.jin'
# time: 2017/1/25 11:26

import re
import argparse
import fileinput
import os
from Bio import SeqIO


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
    try:
        seq_records = SeqIO.parse(f, 'fasta')
        for seq_record in seq_records:
            seq_seq = seq_record.seq
            seq_name = seq_record.name
            line = '>{}\n{}\n'.format(seq_name, seq_seq)
            open(os.path.join(output_dir, seq_name + '.fa'), 'w').write(line)
    except Exception:
        raise Exception("get split fa to single seqs failed")

parser = argparse.ArgumentParser(
    description='usage: python split_fa.py -i fasta  -o output_dir ')
parser.add_argument('-i', '--input', help="input fasta file", default=False)
parser.add_argument('-o', '--out', help="output fasta dir", default=False)
args = parser.parse_args()
fasta = args.input
out = args.out
split_single_seq(fasta,out)

# -*- coding: utf-8 -*-

# __author__ = 'linfang.jin'
# time: 2017/2/7 14:41

import urllib2
import argparse
import re
import os
import subprocess
import sys
import HTMLParser
from bs4 import BeautifulSoup
from ftp_class import MYFTP

parser = argparse.ArgumentParser(
    description='usage: python split_fa.py -i fasta  -o output_dir ')
parser.add_argument('-site', '--entry_site', help="input entry site", default=False)
parser.add_argument('-o', '--out', help="output dir", default=False)
args = parser.parse_args()
site = args.entry_site
out_dir = args.out

hostaddr = 'ftp.ensemblgenomes.org'  # ftp地址
username = 'anonymous'  # 用户名
password = ''  # 密码
port = 21  # 端口号


def check_folder(dir_path):
    if os.path.isdir(dir_path):
        os.mkdir(dir_path)


site = "http://metazoa.ensembl.org/species.html"
sp_first_class_m = re.match(r'^http://([a-zA-Z0-9]+?)\..+$', site.strip())
if sp_first_class_m:
    sp_first_class = sp_first_class_m.group(1)
else:
    sp_first_class = 'unknown'
local_db_root_dir = os.path.join("/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/ref_db_task/test_db_files",
                                 sp_first_class)
check_folder(local_db_root_dir)
content = urllib2.urlopen(site)

content_soup = BeautifulSoup(content, "html.parser")
tables = content_soup.find_all('tbody')
sps_info_dic = {}
for table in tables:
    n = 1
    for row in table.find_all('tr'):
        m = 1
        sp_info_dic = {}
        # 获取每个物种的信息
        sp_name = sp_info_dic['tax_name'] = row.find_all('td')[1].find_all('a')[0].text
        sp_info_dic['tax_second_class'] = row.find_all('td')[2].text
        sp_info_dic['tax_id'] = row.find_all('td')[3].find_all('a')[0].text
        sp_info_dic['tax_first_class'] = sp_first_class
        org_site = "http://metazoa.ensembl.org" + row.find_all('td')[0].find_all('a')[0].attrs['href']
        sp_info_dic['sp_site'] = org_site
        sps_info_dic[sp_name] = sp_info_dic
    m = m + 1
n = n + 1

for sp in sps_info_dic.keys():
    single_sp_info = sps_info_dic[sp]
    sp_link_name = '_'.join(single_sp_info['tax_name'].split())
    sp_index = urllib2.urlopen(single_sp_info['sp_site'])
    sp_html = BeautifulSoup(sp_index, "html.parser")
    target_divs = []
    temp1 = sp_html.find_all('div', {'class': 'box-right'})
    temp2 = sp_html.find_all('div', {'class': 'box-left'})
    temp1[len(temp1):len(temp2)] = temp2

    for div in temp1:
        if div.find('h2') and re.match(r'Genome assembly', div.find_all('h2')[0].text):
            sp_ftp_dirs = div.find_all('a', attrs={'href': re.compile('^ftp:\/\/ftp\.ensemblgenomes\.org\/')})
            if len(sp_ftp_dirs) > 0:
                href_str = str(sp_ftp_dirs[0].attrs['href'])
                m = re.match(r'^ftp:\/\/ftp\.ensemblgenomes\.org(\/\S+\/release-\S+)\/fasta', href_str)
                key_str = m.group(1)
                sp_fasta_ftp_root_dir = '/'.join(
                    ['ftp://ftp.ensemblgenomes.org', key_str.strip('/'), 'fasta', sp_link_name])
                sp_gff3_ftp_root_dir = '/'.join(
                    ['ftp://ftp.ensemblgenomes.org', key_str.strip('/'), 'gff3', sp_link_name])
                sp_vcf_ftp_root_dir = '/'.join(
                    ['ftp://ftp.ensemblgenomes.org', key_str.strip('/'), 'vcf', sp_link_name])
                sp_gvf_ftp_root_dir = '/'.join(
                    ['ftp://ftp.ensemblgenomes.org', key_str.strip('/'), 'gvf', sp_link_name])
                sp_vep_ftp_root_dir = '/'.join(
                    ['ftp://ftp.ensemblgenomes.org', key_str.strip('/'), 'vep', sp_link_name])
                sp_fasta_dna_ftp_root_dir = '/'.join([sp_fasta_ftp_root_dir.rstrip('/'), 'dna'])
                sp_fasta_cdna_ftp_root_dir = '/'.join([sp_fasta_ftp_root_dir.rstrip('/'), 'cdna'])
                sp_fasta_pep_ftp_root_dir = '/'.join([sp_fasta_ftp_root_dir.rstrip('/'), 'pep'])
                sp_fasta_cds_ftp_root_dir = '/'.join([sp_fasta_ftp_root_dir.rstrip('/'), 'cds'])




                #
                #     if data_format == 'FASTA':
                #         dna_seq_str = 'dna'
                #         cdna_seq_str = 'cdna'
                #         cds_seq_str = 'cds'
                #         pep_seq_str = 'pep'
                #         dna_seq_ftp_folder = "/".join(
                #             [re.sub('ftp:\/\/ftp\.ensemblgenomes\.org', '', str(data_ftp_root)).rstrip('/'), dna_seq_str])
                #         ##?要不要加sm 和rm
                #         cdna_seq_ftp_folder = "/".join(
                #             [re.sub('ftp:\/\/ftp\.ensemblgenomes\.org', '', str(data_ftp_root)).rstrip('/'), cdna_seq_str])
                #         cds_seq_ftp_folder = "/".join(
                #             [re.sub('ftp:\/\/ftp\.ensemblgenomes\.org', '', str(data_ftp_root)).rstrip('/'), cds_seq_str])
                #         pep_seq_ftp_folder = "/".join(
                #             [re.sub('ftp:\/\/ftp\.ensemblgenomes\.org', '', str(data_ftp_root)).rstrip('/'), pep_seq_str])
                #
                #     if data_format == 'GFF3':
                #         gff3_ftp_folder = "/".join([re.sub('ftp:\/\/ftp\.ensemblgenomes\.org', '', str(data_ftp_root)).rstrip('/'), 'gff3'])
                #     if data_format == 'GVF':
                #         gvf_ftp_folder = "/".join([re.sub('ftp:\/\/ftp\.ensemblgenomes\.org', '', str(data_ftp_root)).rstrip('/'), 'gvf'])
                #     if data_format == 'VCF':
                #         vcf_ftp_folder = "/".join([re.sub('ftp:\/\/ftp\.ensemblgenomes\.org', '', str(data_ftp_root)).rstrip('/'), 'vcf'])
                #     if data_format == 'VEP':
                #         vep_ftp_folder = "/".join(
                #             [re.sub('ftp:\/\/ftp\.ensemblgenomes\.org', '', str(data_ftp_root)).rstrip('/'), 'vep'])
                #     if data_format == 'Download genes, cDNAs, ncRNA, proteins':
                #         dna_seq_ftp_folder = "/".join(
                #             [re.sub('ftp:\/\/ftp\.ensemblgenomes\.org', '', str(data_ftp_root)).rstrip('/'), dna_seq_str])
                #         ##?要不要加sm 和rm
                #         cdna_seq_ftp_folder = "/".join(
                #             [re.sub('ftp:\/\/ftp\.ensemblgenomes\.org', '', str(data_ftp_root)).rstrip('/'), cdna_seq_str])
                #         cds_seq_ftp_folder = "/".join(
                #             [re.sub('ftp:\/\/ftp\.ensemblgenomes\.org', '', str(data_ftp_root)).rstrip('/'), cds_seq_str])
                #         pep_seq_ftp_folder = "/".join(
                #             [re.sub('ftp:\/\/ftp\.ensemblgenomes\.org', '', str(data_ftp_root)).rstrip('/'), pep_seq_str])
                #
                #         pass  # 例子物种：homo sapins http://asia.ensembl.org/Homo_sapiens/Info/Index
                #     if data_format == 'Download all variants':
                #         pass  # 例子物种：homo sapins http://asia.ensembl.org/Homo_sapiens/Info/Index
                #
                #     if data_format == 'GFF3':
                #         pass



                # sp_ftp_soup = BeautifulSoup(sp_ftp, "html.parser")
                # print "{}:\n======\n{}:\n{}\n==========\n".format(data_format,data_ftp_root,sp_ftp.read())
                # print 'e'

for species in sps_info_dic.keys():
    species


def download_file_from_ftp(remote, local, file_pattern):
    pass








