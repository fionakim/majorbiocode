# -*- coding: utf-8 -*-

# __author__ = 'linfang.jin'
# time: 2017/1/23 9:28

import re
import unittest

def format_check(path):
    with open(path, 'r') as f:
        line = f.readline().rstrip()
        print line
        # head = re.sub(r".+#", "#", line[0])
        # print head
        # if not re.search("^#", head):
        #     raise Exception("该group文件不含表头，group表第一列应该以#号开头")
        # line = line.split("\t")
        # length = len(line)
        # print line
        # if length < 2:
        #     raise Exception('group_table 文件至少应该有两列')
        # for i in line[1:]:
        #     if re.search("\s", i):
        #         raise Exception('分组方案名里不可以包含空格')
    # with open(path, 'r') as f:
    #     for line in f:
    #         if "#" in line:
    #             continue
    #         line = line.rstrip()
    #         line = re.split("\t", line)
    #         for l in line:
    #             if re.search("\s", l):
    #                 raise Exception('分组名里不可以包含空格')
    #         len_ = len(line)
    #         if len_ != length:
    #             raise Exception("文件的列数不相等")


if __name__ == '__main__':
    f_path = 'E:\\majorbio-linfang.jin\\majorBioCode\\test_group.txt'
    format_check(f_path)