#!/usr/bin/perl -w
use strict;
use FindBin qw/$RealScript $RealBin/;
use Getopt::Long;
use File::Basename qw/dirname/;
use Cwd qw/abs_path/;
use lib "$RealBin/bin/perl_module";
use SVG;

# two command (stat and draw)
# genelist (-l para)
  # database: gtf, gene.psl,trans.psl (gtf for read soap and draw, two psl for read soap)
# Three type soap result (WG,Trans,Candidate-genes-denovo) (three para arrays) (-W -T -G)
# add read mpileup file function in stat
# output (two type command, but one -o para)
# add draw Tumor and Normal compare function

my ($gtf,$tpsl,$gpsl);
my ($uniq_map,$coding_only,$save_pseudo,$Help);
my ($sequence_base_num,$mode,@genelist,@mpileup,@WG_soap,@Trans_soap,@Gene_soap,@Gene_stat,$draw_compare_mode,$sample_id,$dregion_list);
my ($region_col,%depth_col,$backstage_col);
my ($intron_width,$exon_width,$cds_width);
my ($resolution,$intron_ratio);
my ($out);

my $bcftools = '/share/backup/jiawl/useful/code/samtools-0.1.17/bcftools/bcftools';
my $Standard_Seq_Bases_Number = 10E9; # just used when somatic (patient) draw mode 'P'
my ($T_sequence_base_num,$N_sequence_base_num) = (0,0);
my ($T_sequence_base_Snum,$N_sequence_base_Snum);
my $S_sequence_base_Snum;

GetOptions(
	"-l=s"   => \@genelist,
	"-co"    => \$coding_only,
	"-sp"    => \$save_pseudo,
	
	"-gtf=s" => \$gtf,
	"-tpsl=s"=> \$tpsl,
	"-gpsl=s"=> \$gpsl,

	"-sbn=s" => \$sequence_base_num,
	"-mode=s"=> \$mode,
	"-mp=s"  => \@mpileup,
	"-W=s"   => \@WG_soap,
	"-T=s"   => \@Trans_soap,
	"-G=s"   => \@Gene_soap,
	"-u"     => \$uniq_map,

	"-S=s"   => \@Gene_stat,

	"-si=s"  => \$sample_id,
	"-dl=s"  => \$dregion_list,
	"-rc=i"  => \$region_col,
	"-dc=s"  => \$depth_col{S},
	"-bc=i"  => \$backstage_col,
	"-iw=i"  => \$intron_width,
	"-ew=i"  => \$exon_width,
	"-cw=i"  => \$cds_width,
	"-er=i"  => \$resolution,
	"-ir=i"  => \$intron_ratio,
	"-o=s"   => \$out,

	"-h"     => \$Help
);

die "
Program:  gene_expression.pl
Function: stat and draw the expression data of each required gene based on specific soap results
Version:  0.1.7 at 07-15-2013
Autthor:  Jia Wenlong (jiawenlong\@genomics.org.cn)

Usage:    perl $RealScript <command> (Options)

Command:  stat      stat the coverage data of each required gene based on specific soap results, or mpileup files.
          draw      draw svg figures for each gene according to the stat result

" if(@ARGV!=1);

#------ system ----------
my (%gene,%trans_gene,%gene_trans);
my (%Depth,%TRANPOS,%Gene_region);
my (%STRAND,%CHR,%TRANS_EXON_LENGTH);
my %col_database;
my %detected_region;

#------ do as command -----
my $command = shift(@ARGV);
&load_col_database if($command eq 'draw');
my %func = (stat=>\&stat, draw=>\&draw);
die "Unknown command \"$command\".\n" if (!defined($func{$command}));
&{$func{$command}}();
exit(0);

#-------------------------------
#-------- Sub Routines ---------
#-------------------------------

#------------ stat function ----------
sub stat{
	die "\n\n\tPlease use SOAPfuse-S09-Expression-stat.pl to stat expression-depth.\n\tThis script's stat function has been outmoded.\n\n\tBut the draw function is ok!\n\n";
	#------- help -------
	&stat_alarm unless (&std_para('stat'));
	#------- list --------
	&read_list;
	#------- gtf ---------
	&load_gtf;
	if($mode eq 'soapfuse'){
		#------- WG soap -----
		&load_WG_soap;
		#----- trans soap -----
		&load_trans_soap;
		#----- candidate soap -----
		&load_candidate_soap; ## skip this foor less memory.
	}
	elsif($mode eq 'mpileup'){
		&load_mpileup;
	}
	else{
		&stat_alarm;
	}
	#----- output -----
	&stat_out;
}

#------------ draw function ----------
sub draw{
	#------- help -------
	&draw_alarm unless (&std_para('draw'));
	#------- list --------
	&read_list;
	#------- gtf ---------
	&load_gtf;
	#------- undef %Depth -------
	undef %Depth;
	#----- stat files ----
	&load_stat;
	#----- load detected region list if necessary ----
	&load_dregion if($dregion_list && -e $dregion_list);
	#----- draw svg ------
	&draw_svg;
}

#----------- standard the para -----------
sub std_para{
	my $func = shift;
	my $sign = 1;
	return 0 if($Help);
	if($func eq 'stat'){
		if(!$sequence_base_num || !$gtf || !$tpsl || !$gpsl){
			return 0;
		}
		if($mode eq 'soapfuse'){
			#------- WG soap ------
			return 0 if(!@WG_soap);
			#------- Trans soap -------
			return 0 if(!@Trans_soap);
			#------- Candidate soap from denovo -------
			return 0 if(!@Gene_soap);
			#------- the three type source files ------
			for(@WG_soap,@Trans_soap,@Gene_soap){
				die"Cannot find source file:\n$_\n" if(!-e $_);
				$_ = abs_path($_);
			}
		}
		elsif($mode eq 'mpileup'){
			#------- mpileup files ------
			return 0 if(!@mpileup);
			#------- check files existence ---------
			for(@mpileup){
				die"Cannot find source file:\n$_\n" if(!-e $_);
				$_ = abs_path($_);
			}
		}
		else{
			return 0;
		}
	}
	elsif($func eq 'draw'){
		#------- Gene stat -------
		return 0 if(!@Gene_stat || !$gtf || !$tpsl || !$gpsl || !$sequence_base_num);
		# modify the sequenced bases number
		if($sequence_base_num !~ /\d+,\d+/){
			$sequence_base_num = (int($sequence_base_num/(10**(length($sequence_base_num)-1))*1000)/1000).'E'.(length($sequence_base_num)-1);
			$Standard_Seq_Bases_Number = $sequence_base_num;
		}
		else{
			($T_sequence_base_num,$N_sequence_base_num) = ($sequence_base_num =~ /^(\d+),(\d+)$/);
			die "T-num is $T_sequence_base_num bp\nN-num is $N_sequence_base_num bp\n" if($T_sequence_base_num == 0 || $N_sequence_base_num == 0);
			$T_sequence_base_Snum = (int($T_sequence_base_num/(10**(length($T_sequence_base_num)-1))*1000)/1000).'E'.(length($T_sequence_base_num)-1);
			$N_sequence_base_Snum = (int($N_sequence_base_num/(10**(length($N_sequence_base_num)-1))*1000)/1000).'E'.(length($N_sequence_base_num)-1);
			$S_sequence_base_Snum = (int($Standard_Seq_Bases_Number/(10**(length($Standard_Seq_Bases_Number)-1))*1000)/1000).'E'.(length($Standard_Seq_Bases_Number)-1);
		}

		for(@Gene_stat){
			if(/^[TN]:/){
				$draw_compare_mode = 1;
				my ($type,$stat_file) = (split /:/)[0,1];
				die"Cannot find source file:\n$stat_file\n" if(!-e $stat_file);
				$_ = "$type:".abs_path($stat_file);
			}
			else{
				die"Cannot find source file:\n$_\n" if(!-e $_);
				$_ = 'S:'.abs_path($_);
			}
		}
		#------- svg paras -------
		$region_col = $col_database{$region_col||14} || $col_database{14};
		if($draw_compare_mode){
			my ($t,$n) = (split /,/,($depth_col{S} || '1,7'))[0,1];
			$t||=1;$n||=7;
			$depth_col{T} = $col_database{$t}||$col_database{1};
			$depth_col{N} = $col_database{$n}||$col_database{7};
			delete $depth_col{S};
		}
		else{
			$depth_col{S} = $col_database{$depth_col{S}||7} || $col_database{7};
		}
		$backstage_col = $col_database{$backstage_col||4} || $col_database{4};
		$intron_width ||= 3;
		$exon_width ||= 10;
		$cds_width ||= 20;
		$resolution ||= 5;
		$intron_ratio ||= 20;
	}
	else{
		die "Std_para failed!\nUnknown sub-routine-name: $func\n";
	}
	#------- shared para --------
	#------- genelist --------
	return 0 if(!@genelist);
	for(@genelist){
		die "Cannot find list: $_\n" if(!-e $_);
		$_ = abs_path($_);
	}
	#------- out ---------
	return 0 if(!$out);
	if($command eq 'stat'){
		system("mkdir -p ".dirname($out)) if(!-d dirname($out)); ## the directory where out exists
	}
	elsif($command eq 'draw'){
		`mkdir -p $out` if(!-d $out);
	}
	$out = abs_path($out);
	return 1;
}

#----------- show help of stat command -----------
sub stat_alarm{
 print STDERR "
 Usage:
     perl $RealScript stat [options]

 Options:
     -l    [s]  list file of genes. <required, multi type>
     -gtf  [s]  gtf database file. <required>
     -tpsl [s]  psl database file of transcript. <required>
     -gpsl [s]  psl database file of gene. <required>
     -co        only stat info of protein_coding transcripts. [disabled]
     -sp        save the pseudogenes. [disabled]
     -sbn  [i]  the number of bases sequenced. <required>
               standard the base number to 5000000000.
     -mode [s]  the mode of stat. ['soapfuse' or 'mpileup']
     -mp   [s]  mpileup files. <required, multi type>
     -W    [s]  soap results via aligning against Whole Genome, can be *.gz. <required, multi type>
     -T    [s]  soap results via aligning against Transcript sequence, can be *.gz. <required, multi type>
     -G    [s]  soap results via aligning against Candidate genes sequence, can be *.gz. <required, multi type>
     -u         sign of only deal uniq map reads. [disabled]
     -o    [s]  output file stores genepos depth infomation. <required>
                this file can be the -S para when use 'draw' command.
     -h         show this help.\n\n";
 exit(0);
}

#----------- show help of draw command -----------
sub draw_alarm{
 print STDERR "
 Usage:
     perl $RealScript draw [options]

 Options:
     -l    [s]  list file of genes. <required, multi type>
     -sbn  [s]  the number of bases sequenced. <required>
                For single sample, just input the sequenced bases number
                For somatic (paired T-N), use ',' to seperate the T-num and N-num, T is in front of N.
     -gtf  [s]  gtf database file. <required>
     -tpsl [s]  psl database file of transcript. <required>
     -gpsl [s]  psl database file of gene. <required>
     -co        only stat info of protein_coding transcripts. [disabled]
     -sp        save the pseudogenes. [disabled]
     -S    [s]  genepos depth files created by command 'stat' (-o para), can be *.gz. <required, multi type>
                If Tumor and Normal compare mode, add prefix 'T:' for tumor data, 'N:' for normal.
     -rc   [i]  region colour number. [14]
     -dc   [i]  depth spectrum colour number. [7]
                If Tumor and Normal compare mode, use comma to seperate two colours. [1,7]
     -bc   [i]  backstage colour number. [4]
     -iw   [i]  width of intron region. [3]
     -ew   [i]  width of exon region. [10]
     -cw   [i]  width of cds region.  [20]
     -er   [i]  resolution of exon region. [5]
     -ir   [i]  multi of intron's resolution to exon. [20]
                set -1, means automatically.
     -si   [s]  sample id for easy reading, display when set.
     -dl   [s]  list file of detected fuse-region supported, display when set.
                whatever mode, only use this single file to display.
     -o    [s]  the final svg figure dir. <required>
     -h         show this help.

 Colours:
     1:red      2:green     3:blue
     4:black    5:white     6:orange
     7:skyblue  8:purple    9:brown
    10:pink    11:yellow   12:gold
    13:tomato  14:lime     15:gray\n\n";
 exit(0);
}

#---------- read genelist -----------
sub read_list{
	foreach my $genelist (@genelist) {
		open (LIST,"$genelist")||die"fail $genelist: $!\n";
		while(<LIST>){
			my ($gene) = (split)[0];
			$gene{$gene} = 0;
		}
		close LIST;
	}
}

#--------- load gtf -----------
sub load_gtf{
	my (%Gene_Name_ID,%Tran_Name_ID);
	for my $i (1,2){
		if($i == 1){
			open (GTF,"awk '\$2==\"protein_coding\" || \$2==\"non_coding\"' $gtf | ") || die"fail $gtf: $!\n";
		}
		else{
			open (GTF,"awk '\$2!=\"protein_coding\" && \$2!=\"non_coding\"' $gtf | ") || die"fail $gtf: $!\n";
		}
		while(<GTF>){
			my ($chr,$gene_type,$type,$P5,$P3,$strand) = (split)[0,1,2,3,4,6];
			$chr =~ s/^chr//i; # discard prefix 'chr', for gencode (gtf-format file), whose seg_name has 'chr' prefix. Thanks to "Sachs, Joshua"<j.sachs@dkfz-heidelberg.de>
			next unless($chr=~/^[12]?\d$/ || $chr=~/^MT?$/i || $chr=~/^[XY]$/i);
			my ($gene_id,$trans_id,$gene_name,$trans_name) = (/gene_id\s\"([^\"]+)\".+transcript_id\s\"([^\"]+)\".+gene_name\s\"([^\"]+)\".+transcript_name\s\"([^\"]+)\"/);
			die "Fail to get gene_id, trans_id, gene_name, trans_name from GTF line:\n$_" if(!$gene_id || !$trans_id || !$gene_name || !$trans_name);
			# for multiple gene_ids of same gene_name
			$Gene_Name_ID{$gene_name}{$gene_id} = scalar(keys %{$Gene_Name_ID{$gene_name}})+1 if(!exists($Gene_Name_ID{$gene_name}{$gene_id}));
			my $Gene_Name_NO = $Gene_Name_ID{$gene_name}{$gene_id};
			my $gene = ($Gene_Name_NO == 1)?$gene_name:"${gene_name}SOAPfuse${Gene_Name_NO}SOAPfuse"; # if the first, use original gene_name
			# for multiple trans_ids of same trans_name
			$Tran_Name_ID{$trans_name}{$trans_id} = scalar(keys %{$Tran_Name_ID{$trans_name}})+1 if(!exists($Tran_Name_ID{$trans_name}{$trans_id}));
			my $Tran_Name_NO = $Tran_Name_ID{$trans_name}{$trans_id};
			my $trans = ($Tran_Name_NO == 1)?$trans_name:"${trans_name}SOAPfuse${Tran_Name_NO}SOAPfuse"; # if the first, use original tran_name
			# filter
			next if($coding_only && $gene_type ne 'protein_coding');
			next if(!$save_pseudo && $gene_type =~ /pseudo/);
			next unless(exists($gene{$gene}));
			$gene{$gene} = 1; ## record found
			#------- record the chromosome --------
			# modify the chr segment
			$chr = 'chr'.(($chr=~/^MT?$/i)?'M':$chr) if($chr !~ /^chr/);
			$CHR{$gene} = $chr unless(exists($CHR{$gene}));
			#------- record the gene region ----- positive strand 5'->3'
			$Gene_region{$chr}{$gene}{P5} = (!$Gene_region{$chr}{$gene}{P5} || $Gene_region{$chr}{$gene}{P5}>$P5)?$P5:$Gene_region{$chr}{$gene}{P5};
			$Gene_region{$chr}{$gene}{P3} = (!$Gene_region{$chr}{$gene}{P3} || $Gene_region{$chr}{$gene}{P3}<$P3)?$P3:$Gene_region{$chr}{$gene}{P3};
			#------- record the strand -------
			$STRAND{$gene} = $strand;
			#------- link gene and its transcripts -------
			$trans_gene{$trans} = $gene; # multi to one
			$gene_trans{$gene}{$trans} = 1; # one to multi
			#------- prepare the depth of concerned dnapos -------
			#%{$Depth{$chr}{$gene}{$_}} = () for ($P5 .. $P3);
			#--- record the transcript structure ---
			$TRANPOS{$trans}{$type}{$P5} = $P3; ## key => P5 for easy sorting by number to seek the turn of exons
			#--- accumulate the length of trans -----
			$TRANS_EXON_LENGTH{$trans} += $P3-$P5+1 if($type eq 'exon');
		}
		close GTF;
	}
	print STDERR "[gtf]:\t$gtf ok!\n";
	#------- check the required genes --------
	my @error_genes;
	foreach my $required_gene (sort keys %gene) {
		push @error_genes,$required_gene unless($gene{$required_gene});
	}
	if(@error_genes){
		print STDERR "<Warn>:\tCannot get information of following genes from gtf file:\n\t".join("\n\t",@error_genes)."\nThe gtf file is $gtf\n";
		print STDERR "[Info]:\tBecause -co is enabled, those genes may not be coding-genes.\n" if($coding_only);
		print STDERR "[Info]:\tBecause -sp is disabled, those genes may be the pseudogenes.\n" if(!$save_pseudo);
		#exit(1);
	}
	#------- check the trans CDS existence -------
	if($coding_only){
		print STDERR "-co is enabled. checking transcripts....\n";
		my @trans = keys %TRANPOS;
		foreach my $trans (@trans) {
			unless(exists($TRANPOS{$trans}{CDS})){
				print STDERR "<WARN>:\ttrans $trans lacks of 'CDS' region, so abandon it from gene $trans_gene{$trans}, and delete its all info.\n";
				delete $TRANPOS{$trans};
				delete $gene_trans{$trans_gene{$trans}}{$trans};
				delete $trans_gene{$trans};
				delete $TRANS_EXON_LENGTH{$trans};
			}
		}
	}
}

#-------- load the mpileup files (vcf4.1) --------
sub load_mpileup{
	foreach my $mpileup (@mpileup){
		open (MP,"$bcftools view $mpileup|")||die"fail $mpileup: $!\n";
		while(<MP>){
			next if(/^#/);
			my ($chr,$pos) = (split)[0,1];
			next unless(exists($Depth{$chr}));
			my ($depth) = /DP=(\d+);/;
			#my $gene = &test_WG_read(1,$chr,$pos);
			for (keys %{$Depth{$chr}}){
				$Depth{$chr}{$_}{$pos} += $depth if(exists($Depth{$chr}{$_}{$pos}));
			}
			print STDERR "$.\n" if($. % 100000 == 0);
		}
		close MP;
		print STDERR "[mpileup]:\t$mpileup loads ok!\n";
	}
}

#-------- laod the WG soap results -------
sub load_WG_soap{
	foreach my $WG_saop (@WG_soap) {
		open (WG,($WG_saop=~/\.gz$/)?"gzip -cd $WG_saop|":"$WG_saop")||die"fail $WG_saop: $!\n";
		while(<WG>){
			my ($map_loc_num,$readlen,$chr,$map_pos) = (split)[3,5,7,8];
			next if($map_loc_num !~ /^\d+$/ || $readlen !~ /^\d+$/ || $map_pos !~ /^\d+$/); ## avoid the soap format error
			next unless(exists($Depth{$chr}));
			next if($uniq_map && $map_loc_num != 1); ## && $some_anchor
			my $gene;
			if($gene = &test_WG_read($readlen,$chr,$map_pos)){
				for ($map_pos .. $map_pos+$readlen-1){
					if(exists($Depth{$chr}{$gene}{$_})){
						++$Depth{$chr}{$gene}{$_}; ## the depth add 1
					}
				}
			}
		}
		close WG;
		print STDERR "[WG]:\t$WG_saop loads ok!\n";
	}
}

#--------- test the read from WG soap for usefulness ---------
sub test_WG_read{
	my ($readlen,$chr,$map_pos) = @_[0,1,2];
	foreach my $gene (keys %{$Gene_region{$chr}}) {
		return $gene if(&test_overlap($Gene_region{$chr}{$gene}{P5},$Gene_region{$chr}{$gene}{P3},$map_pos,$map_pos+$readlen-1));
	}
	return 0;
}

#--------- test two region's overlap ---------
#------- even one bp, it is overlap ----------
sub test_overlap{
	my ($s1,$e1,$s2,$e2) = @_;
	($s1,$e1)=($e1,$s1) if($e1 < $s1);
	($s2,$e2)=($e2,$s2) if($e2 < $s2);
	return ((($s2-$e1)*($e2-$s1)>0)?0:1);
}

#--------- load transcript soap results --------
sub load_trans_soap{
	my (%TranPSL);
	&load_trans_psl(\%TranPSL);
	foreach my $trans_saop (@Trans_soap) {
		open (TS,($trans_saop=~/\.gz$/)?"gzip -cd $trans_saop|":"$trans_saop")||die"fail $trans_saop: $!\n";
		my @map;
		my $lastone = <TS>;
		my ($last_readid) = (split /\s+/,$lastone)[0];
		#push @map,$lastone;
		push @map,join("\t",(split /\s+/,$lastone)[0,7,-1,5,7,8,-2]);
		while(<TS>){
			my $readid = (split)[0];
			if($readid eq $last_readid){
				#push @map,$_;
				push @map,join("\t",(split)[0,7,-1]);
				next;
			}
			else{
				$lastone = $_;
				($last_readid) = (split /\s+/,$lastone)[0];
			}
			unless($uniq_map && &trans_soap_filter(\@map)){ ## this is a uniq map reads
				&deal_trans_soap_read($map[0],\%TranPSL);
			}
			@map = ();
			#push @map,$lastone;
			push @map,join("\t",(split /\s+/,$lastone)[0,7,-1,5,7,8,-2]);
		}
		close TS;
		&deal_trans_soap_read($map[0],\%TranPSL) unless($uniq_map && &trans_soap_filter(\@map));
		print STDERR "[TS]:\t$trans_saop loads ok!\n";
	}
}

#-------- load trans psl --------
sub load_trans_psl{
	my $TranPSL = $_[0];
	open (TPSL,$tpsl)||die"fail $tpsl: $!\n";
	while(<TPSL>){
		my ($strand,$trans,$chr,$length,$positive_st) = (split)[8,9,13,18,20];
		next unless(exists($trans_gene{$trans}));
		#-------- record the trans pos info --------
		my @length = split /,/,$length;
		my @positive_st = split /,/,$positive_st;
		&modify_pos_info(\@length,\@positive_st);
		my $sum = 0;
		if($strand eq '+'){
			push @{$$TranPSL{$trans}},$positive_st[$_]+1,($sum+=$length[$_]) for (0..$#length);
		}
		else{
			push @{$$TranPSL{$trans}},$positive_st[$_]+$length[$_],($sum+=$length[$_]) for reverse (0..$#length);
		}
	}
	close TPSL;
	print STDERR "[tpsl]:\t$tpsl ok!\n";
}

#----- filter the reads of trans soap -----
sub trans_soap_filter{
    my ($map_array) = $_[0];
	my $first_map = $$map_array[0];
	my ($freadid,$ftrans,$fciga) = (split /\s+/,$first_map)[0,1,2];
	return 1 if(!$freadid || !$ftrans || !$fciga);
	my $fgene = $trans_gene{$ftrans} || 'NA';
	return 1 if($fgene eq 'NA');
	my %trans;
	foreach my $map (@$map_array){
		my ($readid,$map_trans,$ciga) = (split /\s+/,$map)[0,1,2];
		return 1 if(!$readid || !$map_trans || !$ciga);
		die "Wrong format: should have same readid:$freadid\n".join("\n",@$map_array)."\n" if($readid ne $freadid);
		return 1 if(exists($trans{$map_trans})); # recurrent map_trans
		$trans{$map_trans} = 1; # record this map_trans
		return 1 if($ciga ne $fciga); # diff ciga, diff map_dna_loc
		return 1 if(!$trans_gene{$map_trans} || $trans_gene{$map_trans} ne $fgene); # diff gene, diff dna_loc (regardless of the overlap-genes)
	}
	return 0;
}

#------ deal the read of transcript soap results ------
sub deal_trans_soap_read{
	my ($readlen,$trans,$map_pos,$cigar) = (split /\s+/,$_[0])[3,4,5,6];
	return  unless(exists($trans_gene{$trans}));
	my $chr = $CHR{$trans_gene{$trans}};
	my $strand = $STRAND{$trans_gene{$trans}};

	my @map_pos;
	my @cigar_letter = grep {/\D/} split /\d+/,$cigar;
	my @map_len = grep {/\d/} split /\D+/,$cigar;

	my $now_map_pos = $map_pos;
	for (my $i=0;$i<@cigar_letter;$i++){
		my $add_sign;
		if($cigar_letter[$i] eq 'M'){ # M
			push @map_pos,$_ for ($now_map_pos .. $now_map_pos+$map_len[$i]-1);
			$add_sign = 1;
		}
		elsif($cigar_letter[$i] eq 'D'){ # D
			$add_sign = 1;
		}
		else{ ## S or I
			$add_sign = 0;
		}
		$now_map_pos += $map_len[$i] if($add_sign);
	}

	for (sort {$a<=>$b} @map_pos){
		my $convert_dna_pos = &convert_trans_to_dna_pos($_[1],$_,$trans,$strand);
		if(exists($Depth{$chr}{$trans_gene{$trans}}{$convert_dna_pos})){
			++$Depth{$chr}{$trans_gene{$trans}}{$convert_dna_pos}; ## the depth add 1
		}
	}
}

#-------- convert the trans_pos to dna_pos -------
sub convert_trans_to_dna_pos{
	my ($TranPSL,$transpos,$trans,$strand,$st_exon) = @_[0,1,2,3,4];
	my $pos_array = \@{$$TranPSL{$trans}};
	for(my $i=($st_exon)?$$st_exon:0;$i!=scalar(@$pos_array);$i+=2){
		my ($exon_st,$sum_len) = @$pos_array[$i,$i+1];
		next if($sum_len < $transpos);
		my $move_len = $transpos - (($i==0)?0:$$pos_array[$i-1]);
		$$st_exon = $i if($st_exon);
		return $exon_st + (($strand eq '+')?1:-1)*($move_len-1);
	}
}

#-------- load the candidate soap results ---------
sub load_candidate_soap{
	my (%GenePSL);
	&load_gene_psl(\%GenePSL);
	foreach my $candidate_soap (@Gene_soap) {
		my %ReadId;
		open (CS,($candidate_soap=~/\.gz$/)?"gzip -cd $candidate_soap|":"$candidate_soap")||die"fail $candidate_soap: $!\n";
		while(<CS>){
			my ($readid,$map_loc_num,$read_len,$gene,$map_pos) = (split)[0,3,5,7,8];
			next unless(exists($gene{$gene}));
			next if($uniq_map && $map_loc_num != 1); ## filter uniq
			next if(exists($ReadId{$readid})); ## one read one deal time
			$ReadId{$readid} = 1;
			my $chr = $CHR{$gene};
			my $strand = $STRAND{$gene};
			for ($map_pos .. $map_pos+$read_len-1){
				my $convert_dna_pos = &convert_gene_to_dna_pos(\%GenePSL,$_,$gene,$strand);
				if(exists($Depth{$chr}{$gene}{$convert_dna_pos})){
					++$Depth{$chr}{$gene}{$convert_dna_pos}; ## the depth add 1
				}
			}
		}
		close CS;
		print STDERR "[CS]:\t$candidate_soap loads ok!\n";
	}
}

#---------- load gene psl ----------
sub load_gene_psl{
	my $GenePSL = $_[0];
	open (GPSL,$gpsl)||die"fail $gpsl: $!\n";
	while(<GPSL>){
		my ($strand,$gene,$chr,$length,$positive_st) = (split)[8,9,13,18,20];
		next unless(exists($gene{$gene}));
		#-------- record the trans pos info --------
		my @length = split /,/,$length;
		my @positive_st = split /,/,$positive_st;
		&modify_pos_info(\@length,\@positive_st);
		my $sum = 0;
		if($strand eq '+'){
			push @{$$GenePSL{$gene}},$positive_st[$_]+1,($sum+=$length[$_]) for (0..$#length);
		}
		else{
			push @{$$GenePSL{$gene}},$positive_st[$_]+$length[$_],($sum+=$length[$_]) for reverse (0..$#length);
		}
	}
	close GPSL;
	print STDERR "[gpsl]:\t$gpsl ok!\n";
}

#-------- modify the gene psl pos info ----------
sub modify_pos_info{
	my ($length_array,$positive_st_array) = @_[0,1];
	my %uniq_pos;
	for (my $i=0;$i!=scalar(@$positive_st_array);++$i) {
		$uniq_pos{$_} = 1 for ($$positive_st_array[$i]+1 .. $$positive_st_array[$i]+$$length_array[$i]);
	}
	@$length_array = ();
	@$positive_st_array = ();
	my $lastpos = -1;
	my $now_len = 0;
	foreach my $pos (sort {$a<=>$b} keys %uniq_pos) {
		if($pos != $lastpos+1){ ## not continuous
			push @$positive_st_array,$pos-1;
			if($now_len != 0){
				push @$length_array,$now_len;
			}
			$now_len = 0;
		}
		++$now_len;
		$lastpos = $pos;
	}
	push @$length_array,$now_len;
}

#-------- convert the gene_pos to dna_pos -------
sub convert_gene_to_dna_pos{
	my ($GenePSL,$genepos,$gene,$strand,$st_exon) = @_[0,1,2,3,4];
	my $pos_array = \@{$$GenePSL{$gene}};
	for(my $i=($st_exon)?$$st_exon:0;$i!=scalar(@$pos_array);$i+=2){
		my ($exon_st,$sum_len) = @$pos_array[$i,$i+1];
		next if($sum_len < $genepos);
		my $move_len = $genepos - (($i==0)?0:$$pos_array[$i-1]);
		$$st_exon = $i if($st_exon);
		return $exon_st + (($strand eq '+')?1:-1)*($move_len-1);
	}
}

#-------- output stat result -------
sub stat_out{
	open (OUT,($out=~/\.gz$/)?"|gzip -c > $out":">$out")||die"fail $out: $!\n";
	foreach my $chr (sort keys %Depth) {
		foreach my $gene (sort keys %{$Depth{$chr}}) {
			foreach my $dnapos (sort {$a<=>$b} keys %{$Depth{$chr}{$gene}}) {
				my $depth = int($Depth{$chr}{$gene}{$dnapos} * $Standard_Seq_Bases_Number / $sequence_base_num);
				print OUT "$gene\t$chr\t$dnapos\t$STRAND{$gene}\t$depth\n";
			}
		}
	}
	close OUT;
}

#-------- load colour database ---------
sub load_col_database{
	%col_database=(
			1=>'red',
			2=>'green',
			3=>'blue',
			4=>'black',
			5=>'white',
			6=>'orange',
			7=>'skyblue',
			8=>'purple',
			9=>'brown',
			10=>'pink',
			11=>'yellow',
			12=>'gold',
			13=>'tomato',
			14=>'lime',
			15=>'gray'
		);
}

#-------- load stat files ---------
sub load_stat{
	my %type_record;
	foreach my $gene_stat (@Gene_stat) {
		my ($type,$stat_file) = (split /:/,$gene_stat)[0,1];
		$type_record{$type} = 1;
		open (STAT,($stat_file=~/\.gz$/)?"gzip -cd $stat_file|":"$stat_file")||die"fail $stat_file: $!\n";
		while(<STAT>){
			my ($gene,$chr,$dnapos,$depth) = (split)[0,1,2,4];
			$Depth{$chr}{$gene}{$dnapos}{$type} += $depth; ## accumulate depth for each pos
		}
		close STAT;
	}
	if($draw_compare_mode){
		die"Tumor Normal compare lacks 'T:' file input!\n" if(!exists($type_record{T}));
		die"Tumor Normal compare lacks 'N:' file input!\n" if(!exists($type_record{N}));
		# if T-N draw mode, should standard to same seq level
		for my $chr (keys %Depth){
			for my $gene (keys %{$Depth{$chr}}){
				$Depth{$chr}{$gene}{$_}{'T'} = int($Depth{$chr}{$gene}{$_}{'T'} * $Standard_Seq_Bases_Number / $T_sequence_base_num) for keys %{$Depth{$chr}{$gene}};
				$Depth{$chr}{$gene}{$_}{'N'} = int($Depth{$chr}{$gene}{$_}{'N'} * $Standard_Seq_Bases_Number / $N_sequence_base_num) for keys %{$Depth{$chr}{$gene}};
			}
		}
	}
}

#-------- load detected region file ---------
sub load_dregion{
	open (DTL,$dregion_list)||die"fail $dregion_list: $!\n";
	while(<DTL>){
		my ($gene,$loc,$region) = (split)[0,3,4];
		$detected_region{$gene}{$loc}{$region} = 1;
	}
	close DTL;
}

#-------- draw svg figure --------
sub draw_svg{
	foreach my $gene (sort keys %gene){
		my $chr = $CHR{$gene};
		my $strand = $STRAND{$gene};
		next if(!exists($Depth{$chr}{$gene}));
		#------- some defaults -------
		my ($y_max_height,$x_left_distance) = (250,150);
		my $gene_name_space = 50;
		my $trans_jump = int($cds_width * 2);
		my $y_zero = $y_max_height + $gene_name_space;
		my $Font_size = 16;
		my $Font_family = "Times New Roman"; # ArialNarrow, Arial
		my $axis_font_size = $Font_size-4;
		my $theme_font_size = $Font_size+5;
		my $region_height = 5;
		#------- modify the gene region -------
		my ($gene_st,$gene_end) = &modify_region($Gene_region{$chr}{$gene}{P5},$Gene_region{$chr}{$gene}{P3});
		#------- merge the gene pos -------
		my @gene_pos_array = ();
		&merge_gene_pos($gene,\@gene_pos_array);
		unshift @gene_pos_array,$gene_st;
		push @gene_pos_array,$gene_end;
		#------- modify the resolution -------
		my ($intron_resolution,$exon_resolution) = ($intron_ratio<=0)?(&modify_resolution($gene_end-$gene_st,scalar(keys %{$Depth{$chr}{$gene}}))):($intron_ratio*$resolution,$resolution);
		#------- define the exon loc --------
		my %gene_x_pos;
		my $x_pos = $x_left_distance;
		for (my $i=0;$i!=$#gene_pos_array;++$i) {
			if($i%2 == 0){ ## intron
					$x_pos += ($gene_pos_array[$i+1]-$gene_pos_array[$i]+1)/$intron_resolution;
			}
			else{ ## exon
				$gene_x_pos{$gene_pos_array[$i]}{end} = $gene_pos_array[$i+1];
				$gene_x_pos{$gene_pos_array[$i]}{xp} = $x_pos;
				$x_pos += ($gene_pos_array[$i+1]-$gene_pos_array[$i]+1)/($exon_resolution);
			}
		}
		my $seq_end = $x_pos;

		#------- calculate detected fuse region number for backstage defining --------
		my $region_num = 0;
		if(exists($detected_region{$gene})){
			for my $loc (keys %{$detected_region{$gene}}){
				$region_num++ for (keys %{$detected_region{$gene}{$loc}});
			}
		}

		#------- backstage -------
		my $trans_num = scalar(keys %{$gene_trans{$gene}});
		my $seq_ratio = 1.1;
		my $svg=SVG->new(width=>$seq_end*$seq_ratio,height=>($y_zero+$trans_num*$trans_jump+$region_num*$region_height)*$seq_ratio);
		$svg->rect(x=>0,y=>0,width=>$seq_end*$seq_ratio,height=>($y_zero+$trans_num*$trans_jump+$region_num*$region_height)*$seq_ratio,fill=>$backstage_col,stroke=>"none");
		$svg->text(x=>$seq_end*$seq_ratio/2,y=>$gene_name_space*0.85,fill=>$region_col,"font-family"=>$Font_family,'text-anchor'=>'middle',"font-size"=>$theme_font_size,'-cdata'=>$gene." ($chr/$strand/$gene_st-$gene_end) [Er:${exon_resolution}bp; Ir:${intron_resolution}bp] {".($sample_id||'').', sequenced-bases: '.(int($Standard_Seq_Bases_Number/(10**(length($Standard_Seq_Bases_Number)-1))*1000)/1000).'E'.(length($Standard_Seq_Bases_Number)-1)."}");
		# normalized-sequenced-bases: '.(int($Standard_Seq_Bases_Number/(10**(length($Standard_Seq_Bases_Number)-1))*100)/100).'E'.(length($Standard_Seq_Bases_Number)-1)."}" 

		#------- draw detected fuse region supported -------
		$region_num = 0;
		if(exists($detected_region{$gene})){
			for my $loc (keys %{$detected_region{$gene}}){
				for my $region (keys %{$detected_region{$gene}{$loc}}){
					$region_num++;
					my ($p5,$p3) = (split /\-/,$region)[0,1];
					my ($p5_x_pos,$merge_P5) = &seek_p5_x_pos(\%gene_x_pos,$p5);
					$p5_x_pos += ($p5-$merge_P5+1)/$exon_resolution;
					my ($p3_x_pos,$merge_P3) = &seek_p5_x_pos(\%gene_x_pos,$p3);
					$p3_x_pos += ($p3-$merge_P3+1)/$exon_resolution;
					my $y = $y_zero+0.2*$trans_jump+$region_num*$region_height-2+10+($axis_font_size);
					#--- draw the region line
					$svg->line(x1=>$p5_x_pos,y1=>$y,x2=>$p3_x_pos,y2=>$y,stroke=>'red',"stroke-width"=>1);
					my ($x_edge,$x_fpos) = ($loc eq 'up')?($p5_x_pos,$p3_x_pos):($p3_x_pos,$p5_x_pos);
					#--- draw non-fuse-point edge line
					$svg->line(x1=>$x_edge,y1=>$y-3,x2=>$x_edge,y2=>$y+3,stroke=>'red',"stroke-width"=>1);
					#--- draw fuse-point circle
					$svg->circle(cx=>$x_fpos,cy=>$y,r=>3,fill=>'red',stroke=>"none");
					#--- draw the transcript orientation
					my $sign = ($p5_x_pos<$p3_x_pos)?(-1):1;
					$svg->line(x1=>($p5_x_pos+$p3_x_pos)/2,y1=>$y,x2=>($p5_x_pos+$p3_x_pos)/2+$sign*5,y2=>$y-3,stroke=>'lime',"stroke-width"=>1);
					$svg->line(x1=>($p5_x_pos+$p3_x_pos)/2,y1=>$y,x2=>($p5_x_pos+$p3_x_pos)/2+$sign*5,y2=>$y+3,stroke=>'lime',"stroke-width"=>1);
				}
			}
		}

		#------- sort by the length of exon of trans -------
		my (%length2trans,@trans_sorted_by_length);
		push @{$length2trans{$TRANS_EXON_LENGTH{$_}}},$_ for sort keys %{$gene_trans{$gene}};
		push @trans_sorted_by_length,@{$length2trans{$_}} for sort {$b<=>$a} keys %length2trans;
		#------- draw trans sequence --------
		my $i=0.2+($region_num * $region_height)/$trans_jump;
		foreach my $trans (@trans_sorted_by_length) {
			$i++;
			#-------- draw intron -------
			$svg->rect(x=>$x_left_distance,y=>$y_zero+$i*$trans_jump-$intron_width/2,width=>$seq_end-$x_left_distance,height=>$intron_width,fill=>$region_col,stroke=>"none");
			#-------- draw exon ---------
			foreach my $exon_P5 (sort {$a<=>$b} keys %{$TRANPOS{$trans}{exon}}) {
				my $exon_P3 = $TRANPOS{$trans}{exon}{$exon_P5};
				my ($p5_x_pos,$merge_P5) = &seek_p5_x_pos(\%gene_x_pos,$exon_P5);
				$svg->rect(x=>$p5_x_pos+($exon_P5-$merge_P5+1)/$exon_resolution,y=>$y_zero+$i*$trans_jump-$exon_width/2,width=>($exon_P3-$exon_P5+1)/$exon_resolution,height=>$exon_width,fill=>$region_col,stroke=>"none");
			}
			#-------- draw CDS ---------
			foreach my $cds_P5 (sort {$a<=>$b} keys %{$TRANPOS{$trans}{CDS}}) {
				my $cds_P3 = $TRANPOS{$trans}{CDS}{$cds_P5};
				my ($p5_x_pos,$merge_P5) = &seek_p5_x_pos(\%gene_x_pos,$cds_P5);
				$svg->rect(x=>$p5_x_pos+($cds_P5-$merge_P5+1)/$exon_resolution,y=>$y_zero+$i*$trans_jump-$cds_width/2,width=>($cds_P3-$cds_P5+1)/$exon_resolution,height=>$cds_width,fill=>$region_col,stroke=>"none");
			}
			$svg->text(x=>$x_left_distance-15,y=>$y_zero+$i*$trans_jump+$Font_size/3,fill=>$region_col,"font-family"=>$Font_family,'text-anchor'=>'end',"font-size"=>$Font_size,'-cdata'=>$trans);
		}

		#-------- stat the depth spectrum -------
		my %depth_spectrum;
		my $max = 0;
		foreach my $merge_P5 (sort {$a<=>$b} keys %gene_x_pos) {
			my $merge_P3 = $gene_x_pos{$merge_P5}{end};
			my $x_pos = $gene_x_pos{$merge_P5}{xp};
			for (my $i=$merge_P5;$i<=$merge_P3;$i+=$exon_resolution) {
				my $j = 0;
				foreach my $pos ($i .. $i+$exon_resolution-1){
					if(exists($Depth{$chr}{$gene}{$pos})){
						$depth_spectrum{$x_pos}{$_} += $Depth{$chr}{$gene}{$pos}{$_} for keys %{$Depth{$chr}{$gene}{$pos}};
						++$j;
					}
				}
				foreach my $type (keys %{$depth_spectrum{$x_pos}}){
					$depth_spectrum{$x_pos}{$type} /= $j if($j != 0);
					$max = ($max>$depth_spectrum{$x_pos}{$type})?$max:$depth_spectrum{$x_pos}{$type};
				}
				++$x_pos;
			}
		}
		#--------- modify the most depth -------
		my  %jump = (1,5,2,10,3,100);
		my $jump = $jump{length(int($max))} || (($max<5000)?500:(($max<10000)?1000:2500));
		$max = (int($max/$jump)+1)*$jump;
		my $y_resolution = $max / $y_max_height;

		#--------- draw the spectrum ---------
		foreach my $x_pos (sort {$a<=>$b} keys %depth_spectrum) {
			my @spectrum_para = (@{$depth_spectrum{$x_pos}}{('S','T','N')},@depth_col{('S','T','N')});
			my @para = (!$draw_compare_mode)?@spectrum_para[0,3]:(($spectrum_para[1]>$spectrum_para[2])?@spectrum_para[1,4,2,5]:@spectrum_para[2,5,1,4]);
			for (my $j=0;$j<@para;$j+=2) {
				$svg->line(x1=>$x_pos,y1=>$y_zero,x2=>$x_pos,y2=>$y_zero-$para[$j]/$y_resolution,stroke=>$para[$j+1],"stroke-width"=>1,opacity=>1);
			}
		}

		#--------- draw the x axis ----------
		my $move = 5;
		my @x_lab = sort {$a<=>$b} keys %gene_x_pos;
		my $x_lab_gap = 10;
		my $x_lab_reach = -1 * $x_lab_gap;
		$svg->line(x1=>$x_left_distance,y1=>$y_zero+$move,x2=>$seq_end,y2=>$y_zero+$move,stroke=>'white',"stroke-width"=>1);
		for (my $j=0;$j!=@x_lab;++$j) {
			for ($x_lab[$j],$gene_x_pos{$x_lab[$j]}{end}){
				my $half_lab_span = length($_)*$axis_font_size/2/2;
				my $x_pos = $gene_x_pos{$x_lab[$j]}{xp} + ($_-$x_lab[$j])/$exon_resolution;
				if(($x_pos - $half_lab_span) > ($x_lab_reach + $x_lab_gap)){
					$svg->line(x1=>$x_pos,y1=>$y_zero+$move,x2=>$x_pos,y2=>$y_zero+$move+3,stroke=>'white',"stroke-width"=>1);
					$svg->text(x=>$x_pos,y=>$y_zero+$move+3+($axis_font_size),fill=>'white',"font-family"=>$Font_family,'text-anchor'=>'middle',"font-size"=>$axis_font_size,'-cdata'=>$_);
					$x_lab_reach =  $x_pos + $half_lab_span;
				}
			}
		}

		#--------- draw the y axis ----------
		my $y_lab_reach = $y_zero+100;
		$svg->line(x1=>$x_left_distance-$move,y1=>$y_zero,x2=>$x_left_distance-$move,y2=>$y_zero-$y_max_height,stroke=>'white',"stroke-width"=>1);
		for (my $y=0;$y<=$max;$y+=$jump){
			if($y_lab_reach-5 > $y_zero-$y/$y_resolution+($axis_font_size)/3){
				$svg->line(x1=>$x_left_distance-$move,y1=>$y_zero-$y/$y_resolution,x2=>$x_left_distance-3-$move,y2=>$y_zero-$y/$y_resolution,stroke=>'white',"stroke-width"=>1);
				$svg->text(x=>$x_left_distance-5-$move,y=>$y_zero-$y/$y_resolution+($axis_font_size)/3,fill=>'white',"font-family"=>$Font_family,'text-anchor'=>'end',"font-size"=>$axis_font_size,'-cdata'=>($y==$max)?"${y}X":$y);
				$y_lab_reach = $y_zero-$y/$y_resolution-($axis_font_size)/3;
			}
		}

		#--------- draw legend of Tumor Normal compare --------
		if($draw_compare_mode){
			my $distance = $move;
			my ($legend_height,$legend_width) = (10,25);
			for('T','N'){
				$svg->text(x=>$x_left_distance+$distance,y=>$gene_name_space*0.85,fill=>'white',"font-family"=>$Font_family,'text-anchor'=>'start',"font-size"=>$axis_font_size,'-cdata'=>$_);
				$distance += $move+$axis_font_size;
				$svg->rect(x=>$x_left_distance+$distance,y=>$gene_name_space*0.85-$legend_height,width=>$legend_width,height=>$legend_height,fill=>$depth_col{$_},stroke=>"none",opacity=>1);
				$distance += 3*$move+$legend_width;
			}
		}

		#--------- output svg figure ---------
		open (OUT,">$out/$gene.expression.svg")||die"fail $out/$gene.expression.svg: $!\n";
		print OUT $svg->xmlify;
		close OUT;
		print STDERR "[gene]:\t$gene figure ok!\n";
	}
}

#-------- modify the region of genes --------
sub modify_region{
	my ($gene_st,$gene_end) = @_[0,1];
	my $span = 50;
	$gene_st = (int($gene_st/$span)-1)*$span;
	$gene_end = (int($gene_end/$span)+1)*$span;
	return ($gene_st,$gene_end);
}

#-------- merge gene pos --------
sub merge_gene_pos{
	my ($gene,$array) = @_[0,1];
	my $chr = $CHR{$gene};
	my $lastpos = -1;
	foreach my $pos (sort {$a<=>$b} keys %{$Depth{$chr}{$gene}}) {
		if($pos != $lastpos+1){ ## not continuous
			push @$array,$lastpos,$pos;
		}
		$lastpos = $pos;
	}
	push @$array,$lastpos;
	shift @$array;
}

#-------- modify the resolution -------
sub modify_resolution{
	my ($whole_length,$exon_length) = @_[0,1];
	my $exon_resolution = $resolution;
	my $exon_ratio;
	if($exon_length<2500){
		$exon_ratio = 0.5;
	}
	elsif($exon_length>10000){
		$exon_ratio = 0.9;
	}
	else{
		$exon_ratio = 0.5 + ($exon_length-2500)*((0.9-0.5)/(10000-2500));
	}
	my $intron_resolution = int(($whole_length-$exon_length)/(1000-$exon_length/$exon_resolution));
	while(1){
		my $aim_figure_width = int($exon_length/$exon_resolution/$exon_ratio);
		$aim_figure_width = ($aim_figure_width<1000 && !($exon_resolution<=1 && $intron_resolution<=1))?1000:$aim_figure_width;
		$intron_resolution = int(($whole_length-$exon_length)/($aim_figure_width-$exon_length/$exon_resolution));
		if($intron_resolution == 0){
			return (1,1) if($exon_resolution == 1);
			$exon_resolution--;
		}
		else{
			return ($intron_resolution,$exon_resolution);
		}
	}
}

#-------- seek the p5 x pos -------
sub seek_p5_x_pos{
	my ($gene_x_pos,$P5) = @_[0,1];
	foreach my $merge_P5 (sort {$a<=>$b} keys %$gene_x_pos) {
		my $merge_P3 = $$gene_x_pos{$merge_P5}{end};
		return ($$gene_x_pos{$merge_P5}{xp},$merge_P5) if($P5>=$merge_P5 && $P5<=$merge_P3);
	}
	die"Cannot find the x_pos for $P5!\n";
}
