#!/usr/bin/env python
# -*- coding: utf-8 -*-
'''
@author: Fiona Kim
@file: rnaseq_asanalysis.py
@time: 2016/12/26 10:20
'''

import os
from biocluster.core.exceptions import OptionError
from biocluster.module import Module
from mbio.files.sequence.file_sample import FileSampleFile
import glob


class RnaseqAsAnalysisModule(Module):
    """
    refRNA的可变剪切分析工具：rmats，利用上游mapping提供的mapping后bam文件或者质控后的fastq测序文件和参考基因组的ref.gff文件，得到用户样本存在的可变剪切数据
    version 1.0
    author: jlf
    last modify: 2016.12.26
    """

    def __init__(self, work_id):
        super(RnaseqAsAnalysisModule, self)
        options = [

            {"name": "ref_genome", "type": "string"},  # 参考基因组，在页面上呈现为下拉菜单中的选项
            {"name": "ref_genome_custom", "type": "infile", "format": "sequence.fasta"},
            # 自定义参考基因组，用户选择customer_mode时，需要传入参考基因组
            {"name": "ASanalysis_method", "type": "string"},  # AS分析手段，分为rMATS和class2
            {"name": "seq_method", "type": "string"},  # 双端测序还是单端测序
            {"name": "fastq_dir", "type": "infile", "format": "sequence.fastq_dir"},  # fastq文件夹
            {"name": "single_end_reads", "type": "infile", "format": "sequence.fastq"},  # 单端序列
            {"name": "left_reads", "type": "infile", "format": "sequence.fastq"},  # 双端测序时，左端序列
            {"name": "right_reads", "type": "infile", "format": "sequence.fastq"},  # 双端测序时，右端序列
            {"name": "gff", "type": "infile", "format": "ref_rna.reads_mapping.gff"},  # gff格式文件
            {"name": "bam_input", "type": "infile", "format": "ref_rna.assembly.bam_dir"},  # 输入的bam
            {"name": "analysis_mode", "type": "string", "default": "U"},
            # 'P' is for paired analysis and 'U' is for unpaired analysis，Type of analysis to perform
        ]
        self.add_option(options)
        self.samples = {}
        self.tool_opts = {}
        self.tools = []

    def check_options(self):
        """
        检查参数
        :return:
        """
        if self.option(""):
            pass

    def get_opts(self):
        self.tool_opts = {
            "ref_genome": self.option("ref_genome"),
            "AS_analysis_method": self.option("mapping_method"),
            "seq_method": self.option("seq_method")

        }
        return True

    def rmarts_run(self):
        pass
    def class2_run(self):
        pass

    def asprofile_run(self):
        pass

    def mapsplice_run(self):
        pass

    def set_output(self):
        pass

    def run(self):
        super(RnaseqAsAnalysisModule, self).run()
        self.get_opts()

    def end(self):
        pass
