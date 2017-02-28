# -*- coding: utf-8 -*-

# __author__ = 'linfang.jin'
# time: 2017/1/22 16:55
import subprocess
from subprocess import Popen, PIPE

sample_as_path = '/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/tooltest/test_extract-as.as'

cmd = '/mnt/ilustre/users/sanger-dev/app/bioinfo/rna/ASprofile.b-1.0.4/extract-as  /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/tooltest/txpt_gtf/DeS1_out.gtf  /mnt/ilustre/users/sanger-dev/workspace/20170122/Single_asprofile_module_linfang_0001/Asprofile/AsprofileHdrs/output/ref.fa.fasta -r /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/tooltest/tmap/cuffcmp.DeS1_out.gtf.tmap /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/tooltest/ref.gtf'
pro = Popen(cmd, shell=True,stdout=PIPE, stderr=PIPE)
result = "".join(pro.stdout.readlines())
with open(sample_as_path, "w") as w:
    w.write(result)

