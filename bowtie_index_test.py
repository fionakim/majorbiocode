#!/mnt/ilustre/users/sanger/app/Python/bin/python
from mbio.workflows.single import SingleWorkflow
from biocluster.wsheet  import Sheet
wsheet = Sheet("/mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/tooltest/bowtie_index.json")
wf = SingleWorkflow(wsheet)
wf.run()