# -*- coding: utf-8 -*-

# __author__ = 'linfang.jin'
# time: 2017/1/13 15:12

from biocluster.iofile import File
from collections import defaultdict
import re
import subprocess
from biocluster.config import Config
import os
from biocluster.core.exceptions import FileError
from Bio import SeqIO


class FastaHdrsFile(File):
    """
    初始化时应传递一个与其对应的fasta文件对象
    """
    def __init__(self,fasta):
        super(FastaHdrsFile, self).__init__()




    def get_info(self):
        """
        获取文件属性
        :return:
        """
        super(FastaHdrsFile, self).get_info()
        seqinfo = self.get_seq_info()
        self.set_property("file_format", seqinfo[0])
        self.set_property("seq_type", seqinfo[1])
        self.set_property("seq_number", seqinfo[2])
        self.set_property("bases", seqinfo[3])
        self.set_property("longest", seqinfo[4])
        self.set_property("shortest", seqinfo[5])

    def check(self):
        """
        检测文件是否满足要求,发生错误时应该触发FileError异常
        满足要求的条件：名称为fasta_name.fasta;行数与fasta文件ID行数一样，
        且符合r'>(\S+)\s+/len=\d+\s+/nonNlen=\d+\s+/org=\S+'
        :return:
        """





        return True
    def check_line_format(self):
        '''

        :return: hdrs文件里每行注释的id集合
        '''

        hdrs_abs_path = ""
        co_fa_path = ""
        id_set = set()
        try:
            with open(hdrs_abs_path) as hdrs:
                line = hdrs.readline()
                m = re.match(r'>(\S+)\s+/len=\d+\s+/nonNlen=\d+\s+/org=\S+',line.strip())
                id = m.group(1)
                id_set.add(id)
        except Exception as e:
                raise FileError("{}的hdrs文件：{}不符合要求".format(co_fa_path,hdrs_abs_path))
        return id_set



    def check_coherence(self):
        fasta_seq_id_set = set()












