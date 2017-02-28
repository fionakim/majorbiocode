# -*- coding: utf-8 -*-

# __author__ = 'linfang.jin'
# time: 2017/2/6 15:12
import os
import re

list_file = "/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/tooltest/test_fq/list.txt"
direction_dic = {"1": "l", "2": "r"}
fw = open(list_file, 'w')
file_name_list = [path.strip() for path in os.listdir(os.path.dirname(list_file)) if
                  re.match(r'^\S+.fq$', path.strip())]
for name in file_name_list:
    m = re.match(r"^(\S+)\.(\d{1})\.fq$", name)
    if m:
        newline = "\t".join([name, m.group(1), direction_dic[m.group(2)]]) + "\n"
        fw.write(newline)
fw.close()
