

1.  Building and installing GMAP and GSNAP
==========================================

Prerequisites: a Unix system (including Cygwin on Windows), a C
compiler, and Perl

Step 1: Set your site-specific variables by editing the file
config.site.  In particular, you should set appropriate values for
"prefix" and probably for "with_gmapdb", as explained in that file.
If you are compiling this package on a Macintosh, you may need to edit
CFLAGS to be

CFLAGS = '-O3 -m64'

since Macintosh machines will make only 32-bit executables by default.


Step 2: Build, test, and install the programs, by running the
following GNU commands

    ./configure
    make
    make check   (optional)
    make install

Note 1: Instead of editing the config.site file in step 1, you may type
everything on the command line for the ./configure script in step 2,
like this

    ./configure --prefix=/your/usr/local/path --with-gmapdb=/path/to/gmapdb

If you omit --with-gmapdb, it defaults to ${prefix}/share.  If you
omit --prefix, it defaults to /usr/local.  Note that on the command
line, it is "with-gmapdb" with a hyphen, but in a config.site file,
it is "with_gmapdb" with an underscore.


Note 2: If you want to keep your version of config.site or have
multiple versions, you can save the file to a different filename, and
then refer to it like this

    ./configure CONFIG_SITE=<config site file>


Note 3: GSNAP is designed for short reads of a limited length, and
uses a configure variable called MAX_READLENGTH (default 300) as a
guide to the maximum read length.  You may set this variable by
providing it to configure like this

    ./configure MAX_READLENGTH=<length>

or by defining it in your config.site file (or in the file provided to
configure as the value of CONFIG_SITE).  Or you may set the value of
MAX_READLENGTH as an environment variable before calling ./configure.
If you do not set MAX_READLENGTH, it will have the default value shown
when you run "./configure --help".

Note that MAX_READLENGTH applies only to GSNAP.  GMAP, on the other
hand, can process queries up to 1 million bp.

Also, starting with version 2014-08-20, if your C compiler can
handle stack-based memory allocation using the alloca() function,
GSNAP ignores MAX_READLENGTH, and can handle reads longer than that
value.


Note 4: GSNAP can read from gzip-compressed FASTA or FASTQ input
files.  This feature requires the zlib library to be present
(available from http://www.zlib.net).  The configure program will
detect the availability of zlib automatically.  However, to disable
this feature, you can add "--disable-zlib" to the ./configure command
or edit your config.site file to have the command "disable_zlib".


Note 5: GSNAP can read from bzip2-compressed FASTA or FASTQ input
files.  This feature requires the bzlib library to be present.  The
configure program will detect the availability of bzlib automatically.
However, to disable this feature, you can add "--disable-bzlib" to the
./configure command or edit your config.site file to have the command
"disable_bzlib".



8.  Running GSNAP
=================

GSNAP uses the same database as GMAP does, so you will need to process
the genome using gmap_build as explained above, if you haven't done
that already.

To see the full set of options for GSNAP, type "gsnap --help".  A key
parameter you will need to set is the "-m" flag, which is the maximal
score you will allow per read (or each end of a paired-end read).  The
score equals the number of mismatches, plus penalties for indels and
local or distant splicing, if any.  If you do not set a value for
"-m", then GSNAP will pick a value, depending on the length of each
read, that will allow it to run fairly quickly.

For DNA-Seq, the automatic setting should be fine, unless you need to
accommodate penalty values for indels or splicing, or your reads are
of poor quality.

For RNA-Seq, in previous versions, we recommended a moderately high
value of -m, such as 10 or so, to handle alignments that cross an
intron-exon boundary.  But now that GSNAP can find terminal alignments
and has GMAP integrated in its algorithm, it is better to select a
small value for -m, such as the default value or something small like
4 or 5 for a 75-bp read.

Input to GSNAP should be either in FASTQ or FASTA format.  The FASTQ
input may include quality scores, which will then be included in SAM
output, if that output format is selected.  For single-end reads, the
FASTQ file may be piped into GSNAP, or given as its command-line
argument, like this

    cat <fastq_file> | gsnap -d <genome>

or

    gsnap -d <genome> <fastq_file>


For paired-end reads, the two corresponding FASTQ files should be
given as command-line arguments in pairs, like this

    gsnap -d <genome> <fastq_file_1> <fastq_file_2> [<fastq_file_3> <fastq_file_4>...]

A pipe cannot work since GSNAP needs to access both FASTQ files in
parallel.  The reads in FASTQ files may have varying lengths, if
desired.  Note that GSNAP can process multiple sets of paired-end
reads, by adding the files in pairs.  If you want to provide multiple
single-end files, you can either use "cat" to concatenate them into
the stdin of gsnap, like this:

    cat <fastq_file_1> [<fastq_file_2>...] | gsnap -d <genome>

or you can provide them all on the command line with the
--force-single-end flag, like this:

    gsnap -d <genome> --force-single-end <fastq_file_1> [<fastq_file_2>...]

which will process each FASTQ file one at a time as single-end reads,
and not try to pair them up.

GSNAP also has the ability to deal with files compressed with gzip, if
the configure script at compile time can find a zlib library in your
system (see Note 3 in the section above about building and installing
GMAP and GSNAP).  If so, and your files are gzipped, you can then read
in gzipped files directly like this

    gsnap --gunzip -d <genome> <fastq.gz>, or 
    gsnap --gunzip -d <genome> --force-single-end <fastq1.gz> [<fastq2.gz>...]

for single-end reads, or

    gsnap --gunzip -d <genome> <fastq_1.gz> <fastq_2.gz> [<fastq_3.gz> <fastq_4.gz>...]

for paired-end reads.

Likewise, GSNAP can handle files compressed with bzip2, if the
configure script at compile time can find a bzlib library in your
system (see Note 3 in the section above about building and installing
GMAP and GSNAP).  If so, and your files are bzip2-compressed, you can
then read in those files directly like this

    gsnap --bunzip2 -d <genome> <fastq.bz2>, or 
    gsnap --bunzip2 -d <genome> --force-single-end <fastq1.bz2> [<fastq2.bz2>...]

for single-end reads, or

    gsnap --bunzip2 -d <genome> <fastq_1.bz2> <fastq_2.bz2> [<fastq_1.bz2> <fastq_2.bz2>...]

for paired-end reads.


For FASTA format, you should include one line per read (or end of a
paired-end read).  The same FASTA file can have a mixture of
single-end and paired-end reads of varying lengths, if desired.

Single-end reads:

Each FASTA entry should contain one short read per line, like this

>Header information
AAAACATTCTCCTCCGCATAAGCCTGCGTCAGATTA

Each short read can have a different length.  However, the entire read
needs to be on a single line, and may not wrap around multiple lines.
If it extends to a second line, GSNAP will think that the read is
paired-end.


Paired-end reads:

Each FASTA entry should contain two short reads, one per line, like
this

>Header information
AAAACATTCTCCTCCGCATAAGCCTAGTAGATTA
GGCGTAGGTAGAAGTAGAGGTTAAGGCGCGTCAG

By default, the program assumes that the second end is in the reverse
complement direction compared with the first end.  If they are in the
same direction, you may need to use the --circular-input (or -c) flag.

GSNAP and GMAP can also read an extended FASTA format that include
quality scores, which look like this

    >Header information
    AAAACATTCTCCTCCGCATAAGCCTGCGTCAGATTA
    +
    <quality scores>

for single-end reads, or

    <Header information
    AAAACATTCTCCTCCGCATAAGCCTGCGTCAGATTA
    +
    <quality scores>

for the second-end of a paired-end read.  In addition, GSNAP can read
an extended FASTA format for paired-end reads, like this:

    >Header information
    AAAACATTCTCCTCCGCATAAGCCTAGTAGATTA
    GGCGTAGGTAGAAGTAGAGGTTAAGGCGCGTCAG
    +
    <quality scores 1>
    <quality scores 2>

This extended FASTA format is useful if paired-end information needs
to be piped into GSNAP via stdin.


As with gmap, gsnap is written for small genomes (less than 2^32 bp in
total length).  With large genomes, there is an equivalent program
called gsnapl, which you should run instead of gsnap.  The gsnapl
program is equivalent to gmap, and is based on the same source code,
but is compiled to use 64-bit index files instead of 32-bit files.
The gsnap and gsnapl programs will detect whether the genomes are the
correct size, and will exit if you try to run them on the wrong-sized
genomes.

9.  SAM output format
=====================

GSNAP can generate SAM output format, by providing the "-A sam" flag
to GSNAP.  In addition, GMAP can also print its alignments in SAM
output, using the "-f samse" or "-f sampe" options, for single-end or
paired-end data.  The sampe option will generate SAM flags to indicate
whether the read is the first or second end of a pair, which requires
that you provide GMAP with an extended FASTA format having a ">" or
"<" character in the header to indicate that information.  However,
the sampe option will change only the SAM flags, and not change the
underlying alignment algorithm.  GMAP does not know how to find
concordance between paired-end reads like GSNAP does.

GSNAP provides some special SAM flags as follows:

XQ: A non-normalized mapping quality score

X2: The second best XQ score among all multimapping alignments for a
given read.  If there is only a single alignment, this value is 0.

XO: Output type.  GSNAP categorizes its alignments into output types,
as follows.  Note that the --split-output option will create separate
output files for each output type.  Alternatively, if you use
sam_sort, you should provide --split-output to that program instead
and achieve the same functionality.  (The reason for this is that
there may be situations where GSNAP assigns different output types to
the first and second ends of the reads and sam_sort needs to see
alignments from both ends together.)  In either case, the output types
have the following meanings and filename suffixes:

  NM (nomapping) (filename suffix ".nomapping"): The entire read
  (single-end or paired-end) could not be aligned.  If the
  --failed-input=FILENAME flag is specified, then these reads are also
   printed in FASTQ or FASTA format (depending on the input format) in
  the given file (plus a .1 or .2 ending for the first and second ends
  of a paired-end read).

  CU (concordant unique) (filename suffix ".concordant_uniq"): Both
  ends of a paired-end read could be aligned concordantly to a single
  position in the genome.  For a definition of concordance, see the
  section "Output types" below.

  CM (concordant multiple) (filename suffix ".concordant_mult"): Both
  ends of a paired-end read could be aligned concordantly, but to more
  than one position in the genome.

  CX (concordant multiple excess) (filename suffix
  ".concordant_mult_xs"): Multiple concordant alignments, but user
  specified --quiet-if-excessive and the number of alignments exceeds
  "-n" threshold.  If the --failed-input option is given, these reads
  are also printed in FASTA or FASTQ format in the given file.

  CT (concordant translocation) (filename suffix
  ".concordant_transloc"): Both ends of a paired-end read could be
  aligned concordantly, but one end requires a split alignment to a
  distant location, such as another chromosome, or a different strand
  on that chromosome, or a far distance on that strand.  Note that
  translocation alignments need to be printed on two separate SAM
  lines.

  CC (concordant circular) (filename suffix ".concordant_circular"):
  Both ends of a paired-end read could be aligned concordantly, but
  one or both ends require an alignment that goes around the origin of
  a circular chromosome.  Circular chromosomes are specified in the
  gmap_build step by using the -c or --circular flag, as described
  previously.  Note that circular alignments need to be printed on two
  separate SAM lines.

  PI (paired unique inversion) (filename suffix ".paired_uniq_inv"):
  Both ends of a paired-end read could be aligned uniquely, but in a
  way that indicates that a genomic inversion has occurred between the
  two ends.

  PS (paired unique scramble) (filename suffix ".paired_uniq_scr"):
  Both ends of a paired-end read could be aligned uniquely, but in a
  way that indicates that the genomic order is scrambled.  This
  typically occurs because of tandem duplications.

  PL (paired unique long) (filename suffix ".paired_uniq_long"): Both
  ends of a paired-end read could be aligned uniquely, but in a way
  that indicates that a large genomic deletion has occurred between
  the two ends.

  PC (paired unique circular) (filename suffix
  ".paired_uniq_circular"): Both ends of a paired-end read could be
  aligned uniquely, but not concordantly, representing an inversion,
  scramble, or deletion.  In addition, one or both ends of the read
  goes around the origin of a circular chromosome.

  PM (paired multiple) (filename suffix ".paired_mult"): Both
  ends of a paired-end read could be aligned near each other,
  representing an inversion, scramble, or deletion, but there are
  multiple places in the genome where an alignment is found.

  PX (paired multiple excess) (filename suffix ".paired_mult_xs"):
  Multiple paired alignments, but user specified --quiet-if-excessive
  and the number of alignments exceeds the "-n" threshold.  If the
  --failed-input option is given, these reads are also printed in
  FASTA or FASTQ format in the given file.

  HU, HM, HT, HC (halfmapping unique, halfmapping multiple,
  halfmapping translocation, and halfmapping circular, respectively)
  (filename suffixes: ".halfmapping_uniq", ".halfmapping_mult",
  ".halfmapping_transloc", ".halfmapping_circular): Same as for the
  concordant output types, except that only one end of the paired-end
  read could be aligned, and the other end could not be aligned
  anywhere in the genome.

  HX (halfmapping multiple excess) (filename suffix
  ".halfmapping_mult_xs"): Multiple halfmapping alignments, but user
  specified --quiet-if-excessive and the number of alignments exceeds
  the "-n" threshold.  If the --failed-input option is given, these
  reads are also printed in FASTA or FASTQ format in the given file.

  UU, UM, UT, UC (unpaired unique, unpaired multiple, unpaired
  translocation, and unpaired circular, respectively) (filename
  suffixes: ".unpaired_uniq", ".unpaired_mult", ".unpaired_transloc",
  ".unpaired_circular): Same as for the concordant output types,
  except that the two ends could not be aligned concordantly or even
  paired.  These "unpaired" categories are also used for single-end
  reads, since they lack a mate end that can allow for concordance,
  pairing, or halfmapping.

  UX (unpaired multiple excess) (filename suffix ".unpaired_mult_xs"):
  Multiple unpaired alignments, but user specified
  --quiet-if-excessive and the number of alignments on one end exceeds
  the "-n" threshold.  If the --failed-input option is given, these
  reads are also printed in FASTA or FASTQ format in the given file.


XB: Prints the barcode extracted from the end of the read.  Applies only
if --barcode-length is not 0.

XP: Prints the primer inferred from a paired-end read.  Applies only
if the --adapter-strip flag is specified.

XH: Prints the part of the query sequence that was hard-clipped.
Sequence is printed in plus-genomic order and replaces the "H" part of
the CIGAR string.

XI: Prints the part of the quality string that was hard-clipped.
Sequence is printed in plus-genomic order and replaces the "H" part of
the CIGAR string.

XS: Prints the strand orientation (+ or -) for a splice.  Appears only
if splicing is allowed (-N or -s flag provided), and only for reads
containing a splice.  The value "+" means the expected GT-AG, GC-AG,
or AT-AC dinucleotide pair is on the plus strand of the genome, and
"-" means the dinucleotides are on the minus strand.  If the
orientation is not obvious, because the dinucleotides do not match
GT-AG, GC-AG, AT-AC, or their complements, then the program applies a
probabilistic splice model to determine the orientation.  If the
splice sites have low probability, then the program may not be able to
determine an orientation, and the result will be printed as XS:A:?.
To prevent this flag, which cannot be handled by such programs (such
as Cufflinks), use the --force-xs-dir flag.  However, this flag will
merely change occurrences of XS:A:? arbitrarily to XS:A:+.

XA: Indicates an ambiguous splice.  If GSNAP finds two or more
possible splices at a given position, it will try to resolve the
ambiguity if possible based on the other end of the paired-end read.
If the ambiguity cannot be resolved, GSNAP will not report any of the
splices, but will report a soft clip instead.  The XA field indicates
which end or ends are ambiguous and the number of matches found on
each ambiguous end, based on the output XA:Z:i,j.  If i or j is
greater than 0, that indicates that the lower or higher chromosomal
end is ambiguous, respectively.  The value given indicates the number
of matches found in the ambiguous end.  This number may be smaller
than the number of bases soft-clipped, due to mismatches.

XC: Indicates whether the alignment crosses over the origin of a
circular chromosome.  If so, the string XC:A:+ is printed.

XT: Prints the intron dinucleotides and splice probabilities around a
distant splicing event (genomic deletion, inversion, scramble, or
translocation).

XW and XV: Printed only when SNP-tolerant alignment is enabled.  XW
provides the number of mismatches against both the reference and
alternate alleles (or the "World" population).  Therefore, these are
true mismatches.  XV provides the number of positions that are
mismatches against the reference genome, but do match the alternate
genome.  Therefore, these are known variant positions.  The sum of XW
and XV provides the number of differences relative to the reference
genome, and with the exception of indels, should equal the value of
NM.

XG: Indicates which method within GSNAP generated the alignment.  A:
suffix array method, B: GMAP alignment produced from suffix array, M:
GMAP alignment produced from GSNAP hash table method, T: terminal
alignment, O: merging of overlaps.  Absence of XG flag indicates the
standard GSNAP hash table method.  (Note: older versions of GSNAP used
"PG:", but some downstream software required all PG methods to be
listed in the header section, so we changed the field name to "XG:")



10.  GSNAP output format
========================

By default, GSNAP prints its output in a FASTA-like format, which we
developed before we incorporated the SAM format.  The default GSNAP
output has some advantages over SAM output, especially for debugging
purposes.  However, we routinely use SAM output for our own pipeline,
and it has been subject to the most testing by ourselves and by outside
users.

Here is some output from GSNAP on a paired-end read:

>GGACTGCGCACCGAACGGCAGCGACTTCCCGTAGTAGCGGTGCTCCGCGAAGACCAGTAGAGCCCCCCGCTCGGCC   1 concordant    ILLUMINA-A1CCE9_0004:1:1:1510:2090#0
 GGACTGCGCACCGAACGGCAGCGACTTCCCGTAGTAGCGct-----------------------------------   1..39   +9:139128263..139128301 start:0..acceptor:0.99,dir:antisense,splice_dist:214,sub:0+0=0,label:NM_013379.DPP7.exon4/13  segs:2,align_score:2  pair_score:5,pair_length:112
,-------------------------------------acGTGCTCCGCGAAGACCAGTAGAGCCCCCCGCTCGGCC   40..76  +9:139128516..139128552 donor:0.96..end:0,dir:antisense,splice_dist:214,sub:0+0=0,label:NM_013379.DPP7.exon3/13
 
<CTTCGCCAACAACTCGGGCTTCGTCGCGGAGCTGGCGGCCGAGCGGGGGGCTCTACTGGTCTTCGCGGAGCACCGC   1 concordant    ILLUMINA-A1CCE9_0004:1:1:1510:2090#0
 CTTCGCCAACAACTCGGcCTTCGTCGCGGAGCTGGCGGCCGAGCGGGGGGCTCTACTGGTCTTCGCGGAGCACgtg   1..73   -9:139128588..139128516 start:0..end:3,sub:3+1=4      segs:1,align_score:3  pair_score:5,pair_length:112
 
Each end of a read gets its own block, with the first read starting
with ">" and the second read for paired-end reads starting with "<".
The block starts with a header line that has in column 1, the query
sequence in its original direction (and with lower-case preserved if
any); in column 2, the number of hits for that query and if the read
is paired-end, the relationship between the ends (as discussed in the
next paragraph); and in column 3, the accession number for the query.


11.  Output types
=================

The two ends of a paired-end read can have the following
relationships: "concordant", "paired", or "unpaired".  A paired-end
read is concordant if the ends align to the same chromosome, in the
expected relative orientations, and having an inferred insert length
greater than zero and within the "--pairmax" parameter.  The inferred
insert length is the distance from the end of the first-end alignment
to the start of the second-end alignment, plus the read lengths of the
two ends.  There may be more than one concordant alignment for a given
read, and if so, the alignments for each end are reported in
corresponding order.

If a concordant relationship cannot be found, then the program will
report any paired relationships it can find.  A paired alignment
occurs when the two ends align to the same chromosome, but fail some
criterion for concordance.  There are different subtypes of paired
alignments, depending on which criterion is violated.  If the
orientations are opposite what is expected, the paired subtype is
"inversion".  If they are in the expected orientation, but the
distance is greater than the "--pairmax" parameter, then the paired
subtype is "toolong".  If they are in the expected orientation, but
the inferred insert length appears to be negative, then the paired
subtype is "scramble".  In GSNAP output, a paired subtype is shown in
a label called "pairtype", which can have the values
"pairtype:inversion", "pairtype:toolong", and "pairtype:scramble".

Otherwise, if neither a concordant nor paired alignment can be found,
then the program will align each end separately, and report the
relationship as being "unpaired".

GSNAP can find translocation splices within a single end of a read,
but it tries to be conservative about reporting them.  If there is any
alignment that does not involve such a translocation, then it will not
report the translocation.  It therefore reports translocation splices
only when no other alignment is found within the concordant, paired,
or unpaired categories.  Therefore, such results are listed in the
header as having "(transloc)" appear after the "concordant", "paired",
or "unpaired" result type.

After the query line, each of the genomic hits is shown, up to the
'-n' parameter.  If too many hits were found (more than the '-n'
parameter), the behavior depends on whether the "--quiet-if-excessive"
flag is given to GSNAP.  If not, then the first n hits will be printed
and the rest will not be printed.  If the "--quiet-if-excessive" flag
is given to GSNAP, then no hits will be printed if the number exceeds
n.

Each of the genomic hits contains one or more alignment segments,
which is a region of continuous one-to-one correspondence (matches or
mismatches) between the query and the genome.  Multiple segments occur
when the alignment contains an insertion, deletion, or splice.  The
first segment is marked by a space (" ") at the beginning of the line,
while the second and following segments are marked by a comma (",") at
the beginning of the line.  (In the current implementation of GSNAP
that allows only a single indel or splice, the number of segments is
at most two.)

The segments contain information in tab-delimited columns as follows:

Column 1: Genomic sequence with matches in capital letters, mismatches
in lower-case letters, and regions outside the segment with dashes.
For deletions in the query, the deleted genomic sequence is also
included in lower case.  For spliced reads, the two dinucleotides at
the intron ends are included in lower case.

Column 2: Range of query sequence aligned in the segment.  Coordinates
are inclusive, with the first nucleotide considered to be position 1.

Column 3: Range of genomic segment aligned, again with inclusive
coordinates, with the first nucleotide in each chromosome considered
to be position 1.  Plus and minus strands are marked with a "+" or "-"
sign.

Column 4: Segment information, delimited by commas.  The first item
reports on the ends of the segment, which can be of type "start",
"end", "ins", "del", "donor", "acceptor", or "term".  After "start"
and "end", we report the number of nucleotides clipped or trimmed from
the segment.  In our example above, "end:3" means that 3 nucleotides
should be trimmed from the end.  Trimming finds a local maximum of
matches to mismatches from the end and is computed only if the "-T"
flag is specified, and the value for "-T" limits the amount of
trimming allowed.  After "ins" and "del", we report the number of
nucleotides that were inserted or deleted in the query relative to the
genome.  After "donor" or "acceptor", we report the probability of the
splice site, based on the MaxEnt model.  The "term" label indicate a
terminal segment, where the entire read could not be aligned, but more
than half of the read could be aligned from either end.

Each segment will also show after the "sub" tag, he number of
mismatches in that segment including the part that is trimmed, if any.
If SNP-tolerant alignment is chosen, then the number of SNPs is also
shown (see details below under SNP-tolerant alignment).  Other
information may also be included with the segment information, such as
the orientation and distance of the splice or known splice labels, if
appropriate flags and information are given to GSNAP.  Splices are
marked with a splice_type, which can be "consistent", "inversion",
"scramble", or "translocation".  A "translocation" splice includes
splices on the same chromosome where the splice distance exceeds the
parameter for localsplicedist.

Column 5: Alignment or hit information, delimited by commas.  For the
first segment in a hit (the one starting with a space), this column
provides the number of segments (denoted by "segs:") and the score of
the alignment (denoted by "align_score:").

Column 6: Pair information (for paired-end reads only).  For the first
segment in a hit (with the same information repeated on both ends of a
concordant pair), this column provides the score of the pair (which is
the sum of the alignment scores) and the inferred length of the insert
(ignoring splices within each segment, but not between segments).  


12.  Detecting known and novel splice sites in GSNAP
====================================================

GSNAP can detect splice junctions in individual reads.  You can detect
splices using a probabilistic model using the --novelsplicing (or -N)
flag.  You can also detect splices from a set of splice sites that you
provide, using the --splicesites (or -s) flag.  You may specify both
flags, which will report splice junctions involving both known and
novel sites.

Output for a splicing junction will look like this:

>TCCGTGACGTGGATTGGTGCTGCACCCCTCATC      1       Header
 TCCGTGACGTGGATTGgt---------------      1..16   +19:56050054..56050069  start:0..donor:0.99,splice_dist:1238,dir:sense,sub:0+0=0,label:NM_001648.KLK3.exon1/5|NM_001030047.KLK3.exon1/5|NM_001030048.KLK3.exon1/5|NM_001030049.KLK3.exon1/6|NM_001030050.KLK3.exon1/2       
,--------------agGTGCTGCACCCCTCATC      17..33  +19:56051308..56051324  acceptor:0.99..end:0,dir:sense,sub:0+0=0,label:NM_001648.KLK3.exon2/5|NM_001030047.KLK3.exon2/5|NM_001030048.KLK3.exon2/5|NM_001030049.KLK3.exon2/6|NM_001030050.KLK3.exon2/2
 
After the "donor:" or "acceptor:" splice site type, the model score
probability is given, even if the splice site is known.  For known
splice sites, the "label:" field will provide information about the
site.  If there is more than one known splice site at a genomic
position, the labels are separated by a "|" delimiter.

There are several advantages to specifying a database of known splice
sites.  First, GSNAP will then be able to detect splicing involving
atypical splice sites, that would otherwise give low scores using its
probabilistic model.  A known splice site is treated as if its model
probability is 1.0.  Second, GSNAP can find splicing involving short
exons.  Such cases have a single end aligning to three exons,
separated by two introns.  Third, GSNAP can identify splicing at the
ends of reads with greater sensitivity, even if they have short
overlaps onto the next exon.  Fourth, GSNAP can detect known long
splices, because expected splice lengths can be included with the
splice site information.

GSNAP allows for known splicing at two levels: at the level of known
splice sites and at the level of known introns.  At the site level,
GSNAP finds splicing between arbitrary combinations of donor and
acceptor splice sites, meaning that it can find alternative splicing
events.  At the intron level, GSNAP finds splicing only between the
set of given donor-acceptor pairs, so it is constrained not to find
alternative splicing events, only introns included in the given list.
For most purposes, I would recommend using known splice sites, rather
than known introns, unless you are certain that all alternative
splicing events are known are represented in your file.

GSNAP can tell the difference between known site-level and known
intron-level splicing based on the format of the input file.  To
perform known site-level splicing, you will need to create a file with
the following format:

>NM_004448.ERBB2.exon1 17:35110090..35110091 donor 6678
>NM_004448.ERBB2.exon2 17:35116768..35116769 acceptor 6678
>NM_004448.ERBB2.exon2 17:35116920..35116921 donor 1179
>NM_004448.ERBB2.exon3 17:35118099..35118100 acceptor 1179
>NM_004449.ERG.exon1 21:38955452..38955451 donor 783
>NM_004449.ERG.exon2 21:38878740..38878739 acceptor 783
>NM_004449.ERG.exon2 21:38878638..38878637 donor 360
>NM_004449.ERG.exon3 21:38869542..38869541 acceptor 360

Each line must start with a ">" character, then be followed by an
identifier, which may have duplicates and can have any format, with
the gene name or exon number shown here only as a suggestion.  Then
there should be the chromosomal coordinates which straddle the
exon-intron boundary, so one coordinate is on the exon and one is on
the intron.  (Coordinates are all 1-based, so the first character of a
chromosome is number 1.)  Finally, there should be the splice type:
"donor" or "acceptor".  You may optionally store the intron distance
at the end.  GSNAP can use this intron distance, if it is longer than
its value for --localsplicedist, to look for long introns at that
splice site.  The same splice site may have different intron distances
in the database; GSNAP will use the longest intron distance reported
in searching for long introns.
                                                                                                
Note that the chromosomal coordinates are in the sense direction.
Therefore, genes on the plus strand of the genome (like NM_004448) have
the coordinates in ascending order (e.g., 35110090..35110091).
Genes on the minus strand of the genome (like NM_004449) have the
coordinates in descending order (e.g., 38955452..38955451).
                                                                                                
On the other hand, to perform known intron-level splicing, you will need
to create a file with the following format:

>NM_004448.ERBB2.intron1 17:35110090..35116769
>NM_004448.ERBB2.intron2 17:35116920..35118100
>NM_004449.ERG.intron1 21:38955452..38878739
>NM_004449.ERG.intron2 21:38878638..38869541

Again, coordinates are 1-based, and specify the exon coordinates
surrounding the intron, with the first coordinate being from the donor
exon and the second one being from the acceptor exon.


There are several ways to help you generate these files.  First, if
you have a GTF file, you can use the included programs gtf_splicesites
and gtf_introns like this:

    cat <gtf file> | gtf_splicesites > foo.splicesites
    cat <gtf file> | gtf_introns > foo.introns

Second, if you retrieve an alignment tracks from UCSC, like this:

    ftp://hgdownload.cse.ucsc.edu/goldenPath/hg18/database/refGene.txt.gz

if you are aligning to genome hg18, or

    ftp://hgdownload.cse.ucsc.edu/goldenPath/hg19/database/refGene.txt.gz

if you are aligning to genome hg19, you can process this track using
the included program psl_splicesites or psl_introns, like this:

    gunzip -c refGene.txt.gz | psl_splicesites -s 1 > foo.splicesites
    gunzip -c refGene.txt.gz | psl_introns -s 1 > foo.introns

Note that alignment tracks in UCSC sometimes have an extra column on
the left.  The "-s" flag allows you to indicate how many columns
should be skipped.

Once you have built this splicesites or introns file, you process it
as a map file (see "Building map files" above), by doing

    cat foo.splicesites | iit_store -o <splicesitesfile>, or
    cat foo.introns | iit_store -o <intronsfile>

If you want to include more than one track, you can do this:

    gunzip -c refGene.txt.gz | psl_splicesites -s 1 > foo
    gunzip -c knownGene.txt.gz | psl_splicesites > bar
    cat foo bar | iit_store -o <splicesitesfile>


A third way to build a known splicesites or known introns file is
useful if you have cDNA sequences rather than an alignment track, or
if you do not trust the alignment track and prefer to use cDNA
sequences.  GMAP has an option "-f splicesites" that finds splice
sites in cDNA sequences and reports them in the correct splicesite
format.  Likewise, GMAP can build an intron file, with the option "-f
introns".

When processing known cDNA sequences, you should also run GMAP with
the "-n 1" flag, so you get the best alignment, and with the "-z
sense_force" or "-z sense_filter" flag.  The sense_force option will
help GMAP know that the introns in your cDNA sequences are in the
correct GT-AG sense, and is applicable when you have a high quality
set of cDNA sequences.  The sense_filter option will allow GMAP to try
either sense or antisense, and to filter out sequences that appear to
be antisense; this is applicable if you are uncertain about the
validity of your cDNA sequences.

Again once you have built either a known splicesites or known introns
file, you process it as a map file by doing

    cat <file> | iit_store -o <splicesitesfile>, or
    cat <file> | iit_store -o <intronsfile>
                                                                                                
which creates <splicesitesfile>.iit or <intronsfile>.iit.


Regardless of how you built <splicesitesfile>.iit or <intronsfile>.iit,
you put it in the maps subdirectory by doing
                                                                                                
    cp <splicesitesfile>.iit /path/to/gmapdb/<genome>/<genome>.maps, or
    cp <intronsfile>.iit /path/to/gmapdb/<genome>/<genome>.maps
                                                                                                
Then, you may use the file by doing this:
                                                                                                
    gsnap -d <genome> -s <splicesitesfile> <shortreads>, or
    gsnap -d <genome> -s <intronsfile> <shortreads>, or