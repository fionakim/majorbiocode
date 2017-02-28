#!/bin/bash
#SBATCH -c 10
#SBATCH -D /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J genomeCoverageBed
#SBATCH -t 10-00:00
#SBATCH -p SANGERDEV
#SBATCH --mem=100G
#SBATCH -o /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/code/bug/genomeCoverageBed_%j.out
#SBATCH -e /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/code/bug/genomeCoverageBed_%j.err
~/app/bioinfo/seq/bedtools-2.25.0/bin/genomeCoverageBed -ibam ~/sg-users/wangzhaoyue/Eukaryote/tophat2/NoS1.bam.sorted.bam  -g ref.fa.chr.len  -d  >~/sg-users/wangzhaoyue/Eukaryote/tophat2/test.NoS1.bam.cov.wiggle