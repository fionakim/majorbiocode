**tooltest样例


:<<
{
  "id":"cuffcompare_sample",
  "type":"tool",
  "name":"ref_rna.assembly.cuffcompare",
  "options":{
    "merged.gtf":"/mnt/ilustre/users/sanger-dev/sg-users/wangzhaoyue/tooltest/top_merged.gtf",
    "ref_fa":"/mnt/ilustre/users/sanger-dev/sg-users/wangzhaoyue/tooltest/ref.fa",
    "ref_gtf":"/mnt/ilustre/users/sanger-dev/sg-users/wangzhaoyue/tooltest/ref.gtf"
  }
}



{
  "id":"cufflinks_sample_01",
  "type":"tool",
  "name":"ref_rna.assembly.cufflinks",
  "options":{
    "sample_bam":"/mnt/ilustre/users/sanger-dev/sg-users/wangzhaoyue/tooltest/accepted_hits.bam",
    "ref_fa":"/mnt/ilustre/users/sanger-dev/sg-users/wangzhaoyue/tooltest/ref.fa",
    "ref_gtf":"/mnt/ilustre/users/sanger-dev/sg-users/wangzhaoyue/tooltest/ref.gtf",
    "fr_stranded":"fr-unstranded"
  }
}



'