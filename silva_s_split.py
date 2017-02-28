#!/usr/bin/python
# -*- coding: utf-8 -*-
# author__='wangzhaoyue'
import re
import subprocess
import argparse

# parser = argparse.ArgumentParser(description="s级重复字符")
# parser.add_argument("-i", "--tax_file", help="分类库文件", required=True)
# parser.add_argument("-o", "--new_tax", help="去掉单引号后的分类库文件", required=True)
# args = vars(parser.parse_args())
#
# old_tax = args["tax_file"]
# new_tax1 = args["new_tax"]

old_tax = 'Z:\\tmp_data\\test.tax'
new_tax1 = 'Z:\\tmp_data\\silva_new.tax'

fw = open(new_tax1, "w+")
all_list = []
level_list = set()
dic = dict()
tax_list = list()
"""
    all_list中存放数据库每行内容，s_level_list中存放s水平的所有不重复的元素
    例：detial：
    '144374:FJ821665.1.1403	d__Bacteria; k__norank; p__Proteobacteria; c__Alphaproteobacteria; o__Rhizobiales;
    f__Rhizobiaceae; g__Rhizobium; s__Rhizobium_sp._M20' '行号：内容'
    number_list:某一s水平对应所有行号信息列表
"""
with open(old_tax, "r")as r1:
    for line in r1:
            all_list.append(line)
            code_line = line.strip().split("\t")
            member = code_line[1].strip().split(";")
            level_list.add(member[-1])
    for i in level_list:
        detail = subprocess.Popen(['''grep -n "%s" ''' % i + old_tax], shell=True, stdout=subprocess.PIPE,
                                  stderr=subprocess.STDOUT)
        detail_out = detail.stdout.read()
        detail.communicate()
        number_list = []
        grep_line = detail_out.strip().split("\n")
        tax_line = set()
        for j in grep_line:
            line_number = j.split(":")
            number_list.append(line_number[0])
    # 判断s水平为i时，对应的这些序列是不是错误序列，=1正确，>1错误，进行处理
        if len(number_list) == 1:
            pass
        else:
            new_reference_list = list()
            reference = all_list[int(number_list[0])-1].strip().split("\t")[1]  # 取第一个序列作为参照
            reference_num = reference.split(";")
            for nu in range(0, 8):
                # print ji
                new_reference_list.append(reference_num[nu])
            reference_tax = ";".join(new_reference_list)
            for n in number_list:
                new_pending_list = list()
                pending = all_list[int(n)-1].strip().split("\t")[1]
                pending_num = pending.split(";")
                for nu in range(0, 8):
                    new_pending_list.append(pending_num[nu])
                pending_tax = ";".join(new_pending_list)
                if pending_tax == reference:
                    pass
                else:
                    tax_code = pending_tax.strip().split(";")
                    claList = list()
                    for level in range(0, 8):
                        tmp = re.split('__', tax_code[level])
                        claList.append([tmp[0], tmp[1]])  # [[d, ],[k, ],...[s, ]]
    # 取S水平的前一级，判断，为norank，再往前一级判断，直达有物种，将物种放到s级后面[[d, ],[k, ]...[g,xxx],[s,aaa[xxx]]]
                    for level in range(0, 7)[::-1]:
                        cla = claList[level][1]
                        if re.search("(uncultured|Incertae_Sedis|norank|unidentified|Unclassified)", cla, flags=re.I):
                            pass
                        else:
                            last_cla = "[" + cla + "]"
                            new_claList = str(claList[-1][1]) + last_cla
                            # print claList[-1][1]
                            # print all_list[int(n)-1]
                            # print new_claList
                            all_list[int(n)-1] = all_list[int(n)-1].replace("s__" + claList[-1][1], "s__" + new_claList)
                            # print all_list[int(n)-1]
                            break
                    # tmp_tax = list()
                    # for level in range(0, 8):
                    #     my_tax = "{}__{}".format(claList[level][0], claList[level][1])
                    #     tmp_tax.append(my_tax)
                    # new_tax = "; ".join(tmp_tax)
                    # all_list[int(n) - 1] = all_list[int(n) - 1].replace(pending_tax, new_tax)
final_tax = "".join(all_list)
fw.write(final_tax)
fw.close()
