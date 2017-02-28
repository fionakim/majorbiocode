#! /bin/bash
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -J mapsplice_batch_mapping
#SBATCH -t 10-00:00
#SBATCH -p SANGERDEV
#SBATCH --mem=100G
#SBATCH -o /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/code/bug/mapsplice_batch_mapping_%j.out
#SBATCH -e /mnt/ilustre/users/sanger-dev/sg-users/jinlinfang/code/bug/mapsplice_batch_mapping_%j.err
python ~/sg-users/jinlinfang/code/split_multi_fasta.py -i /mnt/ilustre/users/sanger-dev/app/database/refGenome/Animal/Primates/human/ref/ref.fa   -o /mnt/ilustre/users/sanger-dev/app/database/refGenome/Animal/Primates/human/ref/ref_piece