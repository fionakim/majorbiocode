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
from ftp_class import debug_print
import time

parser = argparse.ArgumentParser(
    description='usage: python split_fa.py -i fasta  -o output_dir ')
parser.add_argument('-site', '--entry_site', help="input entry site", default=False)
parser.add_argument('-o', '--out', help="local root db dir", default=False)
parser.add_argument('-j', '--out_json', help="record info json file abs path", default=False)
args = parser.parse_args()
site = args.entry_site
local_db_root_dir = args.out
json_file_out = args.out_json

# site = 'http://metazoa.ensembl.org/species.html'
# local_db_root_dir = 'E:/mypiv2'
# json_file_out = 'E:/mypiv2/info.json'


all_info = {}
all_info['download_time'] = time.asctime()


# ==================================函数区================================
def check_folder(dir_path):
    if not os.path.isdir(dir_path):
        os.mkdir(dir_path)


def get_table_dic_from_file(table_file, delim, **kwargs):
    d = {}
    fr = open(table_file)
    for line in fr:
        sp_d = {}
        line = line.strip()
        arr = line.split(delim)
        if len(arr) >= max(kwargs.values()):
            key_col_no = kwargs['key']
            second_class_value_col_no = kwargs['second_class']
            sp_d['second_class'] = arr[second_class_value_col_no - 1]
            d[arr[key_col_no - 1].strip()] = sp_d
        else:
            print 'the length of the line arr split by table char is {}:'.format(len(arr))
    fr.close()
    return d


def delete_rep_item(sp_infos):
    new_info = {}
    for name in sp_infos.keys():
        m = re.match(r'^(.*)_pre$', name)
        if m:
            if m.group(1) not in sp_infos.keys():
                new_info[m.group(1)] = sp_infos[name]
        else:
            new_info[name] = sp_infos[name]
    return new_info


def download_file(host_site, user, code, sub_dir, port_no, pattern, save_folder, method):
    f = MYFTP(host_site, user, code, sub_dir, port_no, method)
    f.login()
    file_down_info_lst = f.download_files(save_folder, sub_dir, pattern)
    return file_down_info_lst


def down_files(dic_eg, usrername, password, port, infos_dic):
    for sp in dic_eg.keys():
        for file_name in dic_eg[sp].keys():
            host = dic_eg[sp][file_name]['server']
            print host
            file_parent_dir = dic_eg[sp][file_name]["dir"]
            print file_parent_dir
            file_pattern = dic_eg[sp][file_name]['pattern']
            save_dir = dic_eg[sp][file_name]['save_dir']
            down_method = dic_eg[sp][file_name]['download_method']
            print '开始下载文件{}的{}文件，ftp host地址是{}，用户名是{}，文件所处的ftp文件夹是{}，请求端口是{}，保存的本地地址是{},下载工具为{}。'.format(sp, file_name,
                                                                                                         server,
                                                                                                         username,
                                                                                                         file_parent_dir,
                                                                                                         port,
                                                                                                         save_dir,
                                                                                                         down_method)
            file_down_info_lst_per_item = download_file(host, usrername, password, file_parent_dir, port, file_pattern,
                                                        save_dir,
                                                        down_method)
            infos_dic[sp][file_name] = file_down_info_lst_per_item
    return infos_dic


# ==========================全局变量==================
username = 'anonymous'  # 用户名
password = None  # 密码
port = 21  # 端口号
sp_first_class = ''
sps_info_dic = {}
check_folder(local_db_root_dir)

# ============================step1: 获取总站物种list信息==================================
#
# main_site_sp_second_dic = get_table_dic_from_file(
#     '/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/ref_db_task/ensemble_main_site_species_second_class_table.txt',
#     '\t',
#     1, 2)
# main_site_sp_second_dic_file = 'E:\\majorbio-linfang.jin\\genome_database\\crawler\\ensemble_main_site_species_second_class_table.txt'
main_site_sp_second_dic_file = '/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/ref_db_task/ensemble_main_site_species_second_class_table.txt'
main_site_sp_second_dic = get_table_dic_from_file(
    main_site_sp_second_dic_file,
    '\t', key=1, latin_name=2, second_class=3, first_class=4)
sp_first_class_m = re.match(r'^http://([a-zA-Z0-9]+?)\..+$', site.strip())
if sp_first_class_m:
    sp_first_class = sp_first_class_m.group(1)
else:
    sp_first_class = 'unknown'
if 'asia' in sp_first_class:
    sp_first_class = 'vertebrate'

content = urllib2.urlopen(site)
content_soup = BeautifulSoup(content, "html.parser")

tables = content_soup.find_all('tbody')
for table in tables:
    for row in table.find_all('tr'):
        sp_info_dic = {}
        # 获取每个物种的信息
        sp_index_site = ''
        if re.match(r'http:\/\/asia.ensembl.org\/info\/about\/species\.html', site):  # main site
            sp_index_href = str(row.find_all('td')[0].find_all('a')[1].attrs['href'])
            sp_info_dic['tax_id'] = row.find_all('td')[2].text
            release_tag = str(row.find_all('td')[0].find_all('a')[1].attrs['class'])
            sp_info_dic['common_name'] = ''
            if sp_index_href.startswith('http:'):
                sp_index_site = sp_index_href
            if sp_index_href.startswith('/'):
                sp_index_site = re.sub(r'/info\/about\/species\.html', '', site.strip()) + sp_index_href
            sp_info_dic['sp_index_site'] = sp_index_site
            sp_name = sp_info_dic['tax_link_name'] = sp_index_site.rstrip('/').split('/')[-1]
            if sp_name in main_site_sp_second_dic.keys():
                sp_info_dic['second_class'] = main_site_sp_second_dic[sp_name]['second_class']
                sp_info_dic['first_class'] = 'vertebrates'
                sp_info_dic['download_method'] = 'wget'
                if 'pre_species' in release_tag:  #
                    sp_info_dic['release'] = 'pre'
                    sp_name_pre = "{}_pre".format(sp_name)  #
                    sps_info_dic[sp_name_pre] = sp_info_dic

                    ''' pre release的物种ftp地址在ftp://ftp.ensembl.org/pub/pre/'''
                else:
                    sp_info_dic['release'] = 'current'
                    sps_info_dic[sp_name] = sp_info_dic
        if re.match(r'http:\/\/metazoa.ensembl.org\/species\.html', site):  # part site
            sp_index_href = str(row.find_all('td')[0].find_all('a')[0].attrs['href'])
            sp_index_site = re.sub(r'species\.html', '', site.strip()).rstrip('/') + sp_index_href
            sp_info_dic['release'] = 'current'
            sp_info_dic['second_class'] = row.find_all('td')[2].text
            sp_info_dic['tax_id'] = row.find_all('td')[3].find_all('a')[0].text
            sp_name = sp_info_dic['tax_link_name'] = sp_index_site.rstrip('/').split('/')[-1]
            print sp_name
            sp_info_dic['sp_index_site'] = sp_index_site
            sp_info_dic['first_class'] = 'metazoa'
            sp_info_dic['download_method'] = 'wget'
            sps_info_dic[sp_name] = sp_info_dic

sps_info_dic = delete_rep_item(sps_info_dic)

for sp in sps_info_dic.keys():
    single_sp_info = sps_info_dic[sp]
    download_file_info_dic = {}
    sp_dna_ftp_root_dir = ''
    sp_cdna_ftp_root_dir = ''
    sp_pep_ftp_root_dir = ''
    sp_cds_ftp_root_dir = ''
    sp_gff3_ftp_root_dir = ''
    sp_link_name_lower = sp.lower()
    sp_vcf_ftp_root_dir = ''
    if 'current' not in sps_info_dic[sp]['release']:
        pre_download_ftp_root_dir = 'ftp://ftp.ensembl.org/pub/pre'
        sp_gff3_ftp_root_dir = '/'.join([pre_download_ftp_root_dir.rstrip('/'), 'gtf', sp_link_name_lower])
        sp_vcf_ftp_root_dir = '/'.join([pre_download_ftp_root_dir.rstrip('/'), 'vcf', sp_link_name_lower])
        sp_dna_ftp_root_dir = '/'.join([pre_download_ftp_root_dir.rstrip('/'), 'fasta', 'dna', sp_link_name_lower])
        sp_cdna_ftp_root_dir = '/'.join([pre_download_ftp_root_dir.rstrip('/'), 'fasta', 'cdna', sp_link_name_lower])
        sp_pep_ftp_root_dir = '/'.join([pre_download_ftp_root_dir.rstrip('/'), 'fasta', 'pep', sp_link_name_lower])
        sp_cds_ftp_root_dir = '/'.join([pre_download_ftp_root_dir.rstrip('/'), 'fasta', 'cds', sp_link_name_lower])
        server = 'ftp.ensembl.org'
        download_file_info_dic['server'] = server

    else:
        second_class_local_folder = os.path.join(local_db_root_dir, single_sp_info['second_class'])
        sp_local_folder = os.path.join(second_class_local_folder, sp_link_name_lower)
        sps_info_dic[sp]['save_sp_dir'] = sp_local_folder
        sp_index = urllib2.urlopen(single_sp_info['sp_index_site'])
        print '解析{}的主页成功'.format(sp)
        sp_html = BeautifulSoup(sp_index, "html.parser")
        h2_list = [h2 for h2 in sp_html.find_all('h2') if "Genome assembly:" in str(h2.text)]
        if h2_list:
            entry_div = h2_list[0].parent
            sp_ftp_dirs = entry_div.find_all('a', attrs={'href': re.compile('^ftp://ftp\.ensembl.*\.org\/pub.+$')})
            if len(sp_ftp_dirs) > 0:
                href_str = str(sp_ftp_dirs[0].attrs['href'])
                print href_str
                m = re.match(r'^ftp:\/\/(ftp\.ensembl.*\.org)(\/\S+)\/fasta', href_str)
                server = m.group(1)
                sub_path = m.group(2)
                download_file_info_dic['server'] = server
                # download_file_info_dic['sub_path'] = sub_path
                # if 'metazoa' in single_sp_info['first_class']:
                sp_gff3_ftp_root_dir = '/'.join([sub_path.rstrip('/'), 'gff3', sp_link_name_lower])
                sp_vcf_ftp_root_dir = '/'.join([sub_path.rstrip('/'), 'vcf', sp_link_name_lower])
                sp_dna_ftp_root_dir = '/'.join([sub_path.rstrip('/'), 'fasta', sp_link_name_lower, 'dna'])
                sp_cdna_ftp_root_dir = '/'.join([sub_path.rstrip('/'), 'fasta', sp_link_name_lower, 'cdna'])
                sp_pep_ftp_root_dir = '/'.join([sub_path.rstrip('/'), 'fasta', sp_link_name_lower, 'pep'])
                sp_cds_ftp_root_dir = '/'.join([sub_path.rstrip('/'), 'fasta', sp_link_name_lower, 'cds'])
                # if 'vertebrates' in single_sp_info['first_class']:
                #     pass
            else:
                print entry_div
    download_file_info_dic['dna_dir'] = sp_dna_ftp_root_dir
    download_file_info_dic['cds_dir'] = sp_cds_ftp_root_dir
    download_file_info_dic['pep_dir'] = sp_pep_ftp_root_dir
    download_file_info_dic['vcf_dir'] = sp_vcf_ftp_root_dir
    download_file_info_dic['gff3_dir'] = sp_gff3_ftp_root_dir
    download_file_info_dic['cdna_dir'] = sp_cdna_ftp_root_dir
    download_file_info_dic['dna_toplevel_name_pattren'] = re.compile(
        r'^' + sp + '\.([^\.\s]+\.){1,}dna\.toplevel\.fa\.gz$', re.I)
    download_file_info_dic['dna_sm_name_pattren'] = re.compile(
        r'^' + sp + '\.\S+?\.dna_sm\.toplevel\.fa\.gz$', re.I)  # pre 不一定有
    download_file_info_dic['cds_name_pattren'] = re.compile(r'^([^\.\s]+\.){1,}cds\.all\.fa\.gz$',re.I)  # pre 没有
    # download_file_info_dic['pep_name_pattren'] = re.compile(
    #     r'^[\._]([^\.\s]+\.){1,}(pre[\._])?pep\.(all\.)?fa\.gz$', re.I)  #
    download_file_info_dic['pep_name_pattren'] = re.compile(
        r'^([^\.\s]+\.){1,}(pre[\._])?pep\.(all\.)?fa\.gz$', re.I)
    download_file_info_dic['vcf_name_pattren'] = re.compile(r'^' + sp + '\.vcf\.gz$', re.I)
    download_file_info_dic['gff3_name_pattren'] = re.compile(
        r'^([^\.\s]+\.){1,}(gff3|pre\.gtf)\.gz$', re.I)
    download_file_info_dic['cdna_name_pattren'] = re.compile(r'^([^\.\s]+\.){1,}cdna\.fa\.gz$', re.I)
    sps_info_dic[sp]['download_files'] = download_file_info_dic

priority_dic = {}
follow_dic = {}
for species in sps_info_dic.keys():
    sp_priority_dic = {}
    sp_follow_dic = {}
    sp_info = sps_info_dic[species]
    sp_first_class_local_folder = os.path.join(local_db_root_dir, sp_info['first_class'])
    sp_second_class_local_folder = os.path.join(sp_first_class_local_folder, sp_info['second_class'])
    sp_save_local_dir = os.path.join(sp_second_class_local_folder, species)
    check_folder(sp_first_class_local_folder)
    check_folder(sp_second_class_local_folder)
    check_folder(sp_save_local_dir)
    if 'download_files' in sp_info.keys():
        download_info = sp_info['download_files']
        dna_toplevel_file_info = {'dir': download_info['dna_dir'], 'server': download_info['server'],
                                  'download_method': sp_info['download_method'],
                                  'save_dir': sp_save_local_dir,
                                  'pattern': download_info['dna_toplevel_name_pattren']}
        sp_priority_dic['dna_toplevel'] = dna_toplevel_file_info

        dna_sm_file_info = {'dir': download_info['dna_dir'], 'server': download_info['server'],
                            'download_method': sp_info['download_method'],
                            'save_dir': sp_save_local_dir,
                            'pattern': download_info['dna_sm_name_pattren']}
        sp_priority_dic['dna_sm'] = dna_sm_file_info

        cds_file_info = {'dir': download_info['cds_dir'], 'server': download_info['server'],
                         'download_method': sp_info['download_method'],
                         'save_dir': sp_save_local_dir,
                         'pattern': download_info['cds_name_pattren']}
        sp_priority_dic['cds'] = cds_file_info

        pep_file_info = {'dir': download_info['pep_dir'], 'server': download_info['server'],
                         'download_method': sp_info['download_method'],
                         'save_dir': sp_save_local_dir,
                         'pattern': download_info['pep_name_pattren']}
        sp_priority_dic['pep'] = pep_file_info

        vcf_file_info = {'dir': download_info['vcf_dir'], 'server': download_info['server'],
                         'download_method': sp_info['download_method'],
                         'save_dir': sp_save_local_dir,
                         'pattern': download_info['vcf_name_pattren']}
        sp_follow_dic['vcf'] = vcf_file_info

        gff3_file_info = {'dir': download_info['gff3_dir'], 'server': download_info['server'],
                          'download_method': sp_info['download_method'],
                          'save_dir': sp_save_local_dir,
                          'pattern': download_info['gff3_name_pattren']}
        sp_priority_dic['gff3'] = gff3_file_info
    priority_dic[species] = sp_priority_dic
    follow_dic[species] = sp_follow_dic
print priority_dic
print follow_dic
# print '开始下载priority{}的文件，参数是{}，{}，{}'.format(priority_dic, username, password, port)
sps_info_dic = down_files(priority_dic, username, password, port, sps_info_dic)
print '结束下载priority_dic的文件'
# print '开始下载follow的文件，参数是{}，{}，{}'.format(username, password, port)
sps_info_dic = down_files(follow_dic, username, password, port, sps_info_dic)
print '结束下载follow_dic的文件'

# 统计个文件更新日期信息
