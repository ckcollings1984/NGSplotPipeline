#!/usr/bin/perl -w
use Getopt::Long qw(GetOptions);
use List::Util qw(max);
use strict;
use utf8;
use warnings;
my $ngsPlotFilesScriptsDirectory = "/n/data1/dfci/pedonc/kadoch/cc463/NGSplotPipeline/NGSplotFilesScripts";
my $outputShell = "./makeNGSplots.sh";
my $homerShellScript = "./homerShellScript.sh";
my $homerShellScript2 = "./homerShellScript2.sh";
# output directory for 'NGSplot' folder  (i.e. /projects/b1025/ckc/)
my $outputDirectory = "./";
# uses all samples in bam directory (all bai files must be present)
my $bamDirectory = "";
# uses only samples from list in text file (use full paths for each bam file, corresponding bai files must be present in same folder) 
# <sampleName>\t<path_to_bam>
my $sampleList = "";
# aligns data to bed files from list in text file (use full paths)
# <bedName>\t<path_to_bed>
my $bedList = "";                          
# window around peak center or around peak start and stops if useEqualPeakWidthforBedList = 1
my $bedLength = 2500;
# sort bed file by peak width
# note: ngsPlot often does a bad job at sorting the data from high to low on its own
# if you want the alignment to  be clustered, set bedListOrder to "km" and recommend setting sortBed to 0
my $sortBed = 1;                         # recommend if not clustering and wanting to sort data from high to low
my $useEqualPeakWidthforBedList = 0;     # recommend setting to 1 for km clustering
my $centerBed = 1;
my $bedOrder = "none";                   
my $bedClusters = 5; 
# general NGSplot arguments 
# for scale, use <min,max> i.e. 0,1 (default - ngsplot auto)
my $assembly = "";
my $heatmapScale = ""; 
my $heatmapColor = "red";
my $verticalLines = 0;
my $lineWidth = 1;
my $numProcessors = 4;
my $numBedProcessors = 4;
my $fragmentLength = 150;
# allows for alignments to certain features (in addition to bed files)
my $runTSS = 0;
my $runGenebody = 0;
my $runExon = 0;
my $lengthTSS = 2500;
my $lengthGenebody = 1000;
my $lengthExon = 500;
my $geneList = "";  # default is database - use geneOrder = "none" to use unsorted list
my $geneOrder = "km";
my $geneClusters = 5;  
# makes pairwise comparisons 
# outputs log2 changes in heatmap and avg plot form
# comparison list must be present to run and must be in the following format
# <comparison_name>\t<path_to_treated_bam>:<path_to_control_bam>  (use full paths)
# if comparisonBedList is blank, selectBedList is used
my $comparisons = "";
my $comparisonBedList = "";
my $comparisonBedLength = $bedLength;
my $comparisonSortBed = 0;
my $comparisonCenterBed = 0;
my $useEqualPeakWidthforComparisonBedList = 1;
my $comparisonBedOrder = "km";  #(set to "none" and comparisonSortBed to 0 if you want to use unsorted bed)
my $comparisonBedClusters = 5; 
my $runComparisonTSS = 0;
my $runComparisonGenebody = 0;
my $runComparisonExon = 0;
my $comparisonGeneList = $geneList; # input is list in text file of ensembl tids or gids
my $comparisonGeneOrder = $geneOrder;
my $comparisonGeneClusters = $geneClusters;
# if you want the alignment to not be clustered, set comparisonOrder to "none"
# if you want the alignment to bed files not be sorted, set sortBed to 0
# for comparison scale, use <min,max> i.e. -2,2 (default - ngsplot auto)
my $comparisonHeatmapScale = "";
my $comparisonHeatmapColors = "skyblue:black:yellow";   # must use colors in this format 
my $comparisonCD = "";                                  # recommend leaving blanking or setting to 1    
# run bed files in series or parallel
# note: all alignments to TSS, Genebody, and Exon will use all processors and be run in series
# especially recommended if number of peaks is less than 20000 or if a large number of alignments need to be made and km clustering is NOT being executed
my $runBedParallel = 0;
# <edgeR_name>\t<path_to_edgeR_file>  (use full paths)
my $edgeRlist = "";
my $edgeRpv = 0.05;
# Read in the command line arguments.
GetOptions('outputDirectory|o=s' => \$outputDirectory,
	    'outputShell|os=s' => \$outputShell,
	   'bamDirectory|bam=s' => \$bamDirectory,
	   'sampleList|s=s' => \$sampleList,
	   'bedList|b=s' => \$bedList,
	   'bedLength|bl=i' => \$bedLength,
	   'sortBed|sb=i' => \$sortBed,
	   'centerBed|cenb=i' => \$centerBed,
	   'useEqualPeakWidthforBedList|epw=i' => \$useEqualPeakWidthforBedList,
	   'bedOrder|bo=s' => \$bedOrder,
	   'bedClusters|bc=i' => \$bedClusters,
	   'assembly|g=s' => \$assembly,
	   'heatmapScale|hs=s' => \$heatmapScale, 
	   'heatmapColor|hc=s' => \$heatmapColor,
       	   'verticalLines|vl=i' => \$verticalLines,
           'lineWidth|lw=i' => \$lineWidth,
           'numProcessors|p=i' => \$numProcessors,
           'numBedProcessors|bp=i' => \$numBedProcessors,
           'fragmentLength|fl=i' => \$fragmentLength,
           'runTSS|rt=i' => \$runTSS,
	   'runGenebody|rgb=i' => \$runGenebody,
           'runExon|re=i' => \$runExon,
           'lengthTSS|tl=i' => \$lengthTSS,
           'lengthGenebody|gbl=i' => \$lengthGenebody,
           'lengthExon|el=i' => \$lengthExon,
           'geneList|gl=s' => \$geneList,
           'geneOrder|go=s' => \$geneOrder,
           'geneClusters|gc=i' => \$geneClusters, 
           'comparisons|c=s' => \$comparisons,
	   'comparisonBedList|cb=s' => \$comparisonBedList,
	   'comparisonBedLength|cbl=i' => \$comparisonBedLength,
	   'comparisonSortBed|csb=i' => \$comparisonSortBed,
	   'comparisonCenterBed|ccenb=i' => \$comparisonCenterBed,
           'useEqualPeakWidthforComparisonBedList|cepw=i' => \$useEqualPeakWidthforComparisonBedList,
           'comparisonBedOrder|cbo=s' => \$comparisonBedOrder,
           'comparisonBedClusters|cbc=i' => \$comparisonBedClusters, 
           'runComparisonTSS|rct=i' => \$runComparisonTSS,
           'runComparisonGenebody|rcgb=i' => \$runComparisonGenebody,
           'runComparisonExon|rce=i' => \$runComparisonExon,
           'comparisonGeneList|cgl=s' => \$comparisonGeneList,
           'comparisonGeneOrder|cgo=s' => \$comparisonGeneOrder,
           'comparisonGeneClusters|cgc=i' => \$comparisonGeneClusters,
	   'comparisonHeatmapScale|chs=s' => \$comparisonHeatmapScale,
           'comparisonHeatmapColors|chc=s' => \$comparisonHeatmapColors,    
           'comparisonCD|ccd=f' => \$comparisonCD,                                    
           'runBedParallel|rbp=i' => \$runBedParallel,
           'edgeRlist|erl=s' => \$edgeRlist,
           'ngsPlotFilesScriptsDirectory|ngs=s' => \$ngsPlotFilesScriptsDirectory,
           'homerShellScript|hss=s' => \$homerShellScript,
           'homerShellScript2|hss2=s' => \$homerShellScript2,
           'edgeRpv|erp=f' => \$edgeRpv
    ) ;
$numBedProcessors = $numProcessors;

open(OUT, ">$outputShell");
print OUT "#!/bin/bash\n";
print OUT "#SBATCH -t 0-12:00\n";
print OUT "#SBATCH -N 1\n";                         
print OUT "#SBATCH -c $numProcessors\n";
print OUT "#SBATCH -p short\n";
my $ram = $numProcessors * 8 * 1000;                  
print OUT "#SBATCH --mem=$ram\n";
print OUT "#SBATCH -o cc463_%j.out\n";        
print OUT "#SBATCH -e cc463_%j.err\n";
print OUT "#SBATCH --mail-type=ALL\n";
print OUT "#SBATCH --mail-user=ccolling\@broadinstitute.org\n";
print OUT "module load gcc/6.2.0\n";
print OUT "module load R/3.2.5\n";


# Define references.
my %geneAnno;
$geneAnno{"hg19"} = "$ngsPlotFilesScriptsDirectory\/hg19.ensembl.genebody.protein_coding.txt";
$geneAnno{"hg18"} = "$ngsPlotFilesScriptsDirectory\/hg18.ensembl.genebody.protein_coding.txt";
$geneAnno{"dm3"} = "$ngsPlotFilesScriptsDirectory\/dm3.ensembl.genebody.protein_coding.txt";
$geneAnno{"mm10"} = "$ngsPlotFilesScriptsDirectory\/mm10.ensembl.genebody.protein_coding.txt";
$geneAnno{"mm9"} = "$ngsPlotFilesScriptsDirectory\/mm9.ensembl.genebody.protein_coding.txt";
$geneAnno{"sacCer3"} = "$ngsPlotFilesScriptsDirectory\/sacCer3.ensembl.genebody.protein_coding.txt";
my %promoter1k;
$promoter1k{"hg19"} = "$ngsPlotFilesScriptsDirectory\/hg19.ensembl.promoter1k.protein_coding.bed";
$promoter1k{"hg18"} = "$ngsPlotFilesScriptsDirectory\/hg18.ensembl.promoter1k.protein_coding.bed";
$promoter1k{"dm3"} = "$ngsPlotFilesScriptsDirectory\/dm3.ensembl.promoter1k.protein_coding.bed";
$promoter1k{"mm10"} = "$ngsPlotFilesScriptsDirectory\/mm10.ensembl.promoter1k.protein_coding.bed";
$promoter1k{"mm9"} = "$ngsPlotFilesScriptsDirectory\/mm9.ensembl.promoter1k.protein_coding.bed";
$promoter1k{"sacCer3"} = "$ngsPlotFilesScriptsDirectory\/sacCer3.promoter1k.genebody.protein_coding.bed";
my %cgi;
$cgi{"hg19"} = "$ngsPlotFilesScriptsDirectory\/hg19.ensembl.cgi.Promoter1k.protein_coding.bed";
$cgi{"hg18"} = "$ngsPlotFilesScriptsDirectory\/hg18.ensembl.cgi.Promoter1k.protein_coding.bed";
$cgi{"mm10"} = "$ngsPlotFilesScriptsDirectory\/mm10.ensembl.cgi.Promoter1k.protein_coding.bed";
$cgi{"mm9"} = "$ngsPlotFilesScriptsDirectory\/mm9.ensembl.cgi.Promoter1k.protein_coding.bed";
my %entrez;
$entrez{"hg19"} = "/n/app/homer/4.9/data/accession/human.description";
$entrez{"hg18"} = "/n/app/homer/4.9/data/accession/human.description";
$entrez{"dm3"} = "/n/app/homer/4.9/data/accession/fly.description";
$entrez{"mm10"} = "/n/app/homer/4.9/data/accession/mouse.description";
$entrez{"mm9"} = "/n/app/homer/4.9/data/accession/mouse.description";
$entrez{"sacCer3"} = "/n/app/homer/4.9/data/accession/yeast.description";

if ($sampleList eq '' && $bamDirectory eq '' && $comparisons eq '') {
	print "Need Samples!!!\nProvide sample list, comparison list, or bam Directory!";
	exit;
}
my @bams;
my @samples;
if ($sampleList eq '' && $bamDirectory ne '') {
	$bamDirectory = $bamDirectory . "/";
	opendir(DIR, $bamDirectory);
	my @files = grep /bam/, readdir DIR;
	close DIR;
	foreach my $file (@files) {
		if ($file =~ /\.bai/) {
			next;
		} else {
			my $temp = $bamDirectory . $file;
			push @bams, $temp;
			(my $sample) = ($file =~ /(\S+)\.bam/);
			push @samples, $sample; 
		}
	}
} elsif ($sampleList ne '') {
	open(IN, $sampleList);
	while(my $line = <IN>) {
		chomp $line;
		my @line = split("\t", $line);
		my $temp = $line[1];
		push @bams, $temp;
		my $temp2 = $line[0];
		push @samples, $temp2; 
	}
	close(IN);
}
my @beds;
my @bedPeakCounts;
my @bedNames;
if ($bedList eq '') {
} else {
	open(IN, $bedList);
	while(my $line = <IN>) {
		chomp $line;
		my @line = split("\t", $line);
		my $temp = $line[1];
		push @beds, $temp;
		my $peakCount = `wc -l < $temp`;
		chomp $peakCount;
		push @bedPeakCounts, $peakCount;
		my $temp2 = $line[0];
		push @bedNames, $temp2;
		print "$temp	$peakCount	$temp2\n";
	}
	close(IN);
}
my @comparisons;
my @comparisonNames;
my @comparisonBeds;
my @comparisonBedPeakCounts;
my @comparisonBedNames;
if ($comparisons eq '') {
} else {
	open(IN, $comparisons);
	while(my $line = <IN>) {
		chomp $line;
		my @line = split("\t", $line);
		my $temp = $line[1];
		push @comparisons, $temp;
		my $temp2 = $line[0];
		push @comparisonNames, $temp2;
	}
	close(IN);
	if ($comparisonBedList eq '' && $bedList ne '') {
		open(IN, $bedList);
		while(my $line = <IN>) {
			chomp $line;
			my @line = split("\t", $line);
			my $temp = $line[1];
			push @comparisonBeds, $temp;
			my $peakCount = `wc -l < $temp`;
			chomp $peakCount;
			push @comparisonBedPeakCounts, $peakCount;
			my $temp2 = $line[0];
			push @comparisonBedNames, $temp2;
		}
		close(IN);
	} elsif ($comparisonBedList ne '') {
		open(IN, $comparisonBedList);
		while(my $line = <IN>) {
			chomp $line;
			my @line = split("\t", $line);
			my $temp = $line[1];
			push @comparisonBeds, $temp;
			my $peakCount = `wc -l < $temp`;
			chomp $peakCount;
			push @comparisonBedPeakCounts, $peakCount;
			my $temp2 = $line[0];
			push @comparisonBedNames, $temp2;
		}
		close(IN);
	}
}
my $ngsPlotDirectory = $outputDirectory . "/NGSplot";
my $mkdir_ngsplot_cmd = "mkdir $ngsPlotDirectory";
system($mkdir_ngsplot_cmd);
my %ngsplotcompcmd;
my %ngsplotcmd;
my @hs;
unless ($heatmapScale eq '') {
	@hs = split(",",$heatmapScale);
}
my @chs;
unless ($comparisonHeatmapScale eq '') {
	@chs = split(",",$comparisonHeatmapScale);
}
if ($useEqualPeakWidthforBedList == 1) {
	$centerBed = 0;
}
if ($useEqualPeakWidthforComparisonBedList == 1) {
	$comparisonCenterBed = 0;
}
my $output = "";
unless ($bedList eq '') {
	my $count = -1; 
	foreach my $bed (@beds) {
		$count++;
		my $bedname = $bedNames[$count];
		if ($useEqualPeakWidthforBedList == 1 && $sortBed == 0) {
			print OUT "perl $ngsPlotFilesScriptsDirectory\/convertToNGSplotBED.pl $bed $ngsPlotDirectory\/$bedname.same.bed\n";
        	} elsif ($useEqualPeakWidthforBedList == 1 && $sortBed == 1) {
            		print OUT "perl $ngsPlotFilesScriptsDirectory\/convertToNGSplotSortedBED.pl $bed $ngsPlotDirectory\/$bedname.sort.bed\n";
        	} elsif ($useEqualPeakWidthforBedList == 0 && $sortBed == 1 && $centerBed == 1)  {
            		print OUT "perl $ngsPlotFilesScriptsDirectory\/convertToNGSplotSortedCenteredBED.pl $bed $ngsPlotDirectory\/$bedname.sort.center.bed\n";
        	} else {
        		print OUT "perl $ngsPlotFilesScriptsDirectory\/convertToNGSplotCenteredBED.pl $bed $ngsPlotDirectory\/$bedname.center.bed\n";
        	}
		my $outfile = $ngsPlotDirectory . "/configuration.$bedname.txt";
		open(CNFG, ">$outfile");
		my $count2 = -1;
		foreach my $bam (@bams) {
			$count2++;
			my $samplename = $samples[$count2];
			if ($useEqualPeakWidthforBedList == 1 && $sortBed == 0) { 
				print CNFG "$bam\t$ngsPlotDirectory\/$bedname.same.bed\t\"$samplename\"\n";
			} elsif ($useEqualPeakWidthforBedList == 1 && $sortBed == 1) {
				print CNFG "$bam\t$ngsPlotDirectory\/$bedname.sort.bed\t\"$samplename\"\n";
			} elsif ($useEqualPeakWidthforBedList == 0 && $sortBed == 1 && $centerBed == 1) {
				print CNFG "$bam\t$ngsPlotDirectory\/$bedname.sort.center.bed\t\"$samplename\"\n";
			} else {
				print CNFG "$bam\t$ngsPlotDirectory\/$bedname.center.bed\t\"$samplename\"\n";
			}
		}
		close(CNFG);
		my $rr = int($bedPeakCounts[$count] / 3000) * 10;
		if ($rr < 30) {
			$rr = 30;
		}	
		if ($bedOrder eq "km") {
			if ($heatmapScale eq '') {
				$ngsplotcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $bedLength -R bed -C $outfile -RR $rr -GO $bedOrder -KNC $bedClusters -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.km.$bedClusters.$bedname";
			} else {
				$ngsplotcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $bedLength -R bed -C $outfile -RR $rr -GO $bedOrder -KNC $bedClusters -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.km.$bedClusters.$hs[0].$hs[1].$bedname -SC $heatmapScale";
			}
		} else {
			if ($sortBed == 1) {
				if ($centerBed == 1) {
					if ($heatmapScale eq '') {
						$ngsplotcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $bedLength -R bed -C $outfile -RR $rr -GO $bedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.sorted.centered.$bedname";
					} else {
						$ngsplotcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $bedLength -R bed -C $outfile -RR $rr -GO $bedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.sorted.centered.$hs[0].$hs[1].$bedname -SC $heatmapScale";
					}
				} else {
					if ($heatmapScale eq '') {
						$ngsplotcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $bedLength -R bed -C $outfile -RR $rr -GO $bedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.sorted.$bedname";
					} else {
						$ngsplotcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $bedLength -R bed -C $outfile -RR $rr -GO $bedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.sorted.$hs[0].$hs[1].$bedname -SC $heatmapScale";
					}
				}	
			} else {
				if ($centerBed == 1) {
					if ($heatmapScale eq '') {
						$ngsplotcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $bedLength -R bed -C $outfile -RR $rr -GO $bedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.centered.$bedname";
					} else {
						$ngsplotcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $bedLength -R bed -C $outfile -RR $rr -GO $bedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.centered.$hs[0].$hs[1].$bedname -SC $heatmapScale";
					}
				} else {
					if ($heatmapScale eq '') {
						$ngsplotcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $bedLength -R bed -C $outfile -RR $rr -GO $bedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.$bedname";
					} else {
						$ngsplotcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $bedLength -R bed -C $outfile -RR $rr -GO $bedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.$hs[0].$hs[1].$bedname -SC $heatmapScale";
					}
				}	
			}
		}		
	}
}
unless ($comparisons eq '') {
	if ($comparisonBedList eq '') {
		my $count = -1; 
		foreach my $bed (@beds) {
			$count++;
			my $bedname = $bedNames[$count]; 
			if ($useEqualPeakWidthforComparisonBedList == 1 && $comparisonSortBed == 0) {
						print OUT "perl $ngsPlotFilesScriptsDirectory\/convertToNGSplotBED.pl $bed $ngsPlotDirectory\/$bedname.same.bed\n";
            		} elsif ($useEqualPeakWidthforComparisonBedList == 1 && $comparisonSortBed == 1) {
            			print OUT "perl $ngsPlotFilesScriptsDirectory\/convertToNGSplotSortedBED.pl $bed $ngsPlotDirectory\/$bedname.sort.bed\n";
            		} elsif ($useEqualPeakWidthforComparisonBedList == 0 && $comparisonSortBed == 1 && $comparisonCenterBed == 1)  {
                		print OUT "perl $ngsPlotFilesScriptsDirectory\/convertToNGSplotSortedCenteredBED.pl $bed $ngsPlotDirectory\/$bedname.sort.center.bed\n";
            		} else { 
            			print OUT "perl $ngsPlotFilesScriptsDirectory\/convertToNGSplotCenteredBED.pl $bed $ngsPlotDirectory\/$bedname.center.bed\n";
            		}            		           
			my $outfile = $ngsPlotDirectory . "/configuration.comparison.$bedname.txt";
			open(CNFG, ">$outfile");
			my $count2 = -1;
			foreach my $bam (@comparisons) {
				$count2++;
				my $samplename = $comparisonNames[$count2];
				if ($useEqualPeakWidthforComparisonBedList == 1 && $comparisonSortBed == 0) { 
					print CNFG "$bam\t$ngsPlotDirectory\/$bedname.same.bed\t\"$samplename\"\n";
				} elsif ($useEqualPeakWidthforComparisonBedList == 1 && $comparisonSortBed == 1) {
					print CNFG "$bam\t$ngsPlotDirectory\/$bedname.sort.bed\t\"$samplename\"\n";
				} elsif ($useEqualPeakWidthforComparisonBedList == 0 && $comparisonSortBed == 1 && $comparisonCenterBed == 1)  {
					print CNFG "$bam\t$ngsPlotDirectory\/$bedname.sort.center.bed\t\"$samplename\"\n";
				} else {
					print CNFG "$bam\t$ngsPlotDirectory\/$bedname.center.bed\t\"$samplename\"\n";
				}
			}
			close(CNFG);
			my $rr = int($comparisonBedPeakCounts[$count] / 3000) * 10;
			if ($rr < 30) {
				$rr = 30;
			}
			if ($comparisonBedOrder eq "km") {
				if ($comparisonHeatmapScale eq '') {
					if ($comparisonCD eq '') {
						$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -KNC $comparisonBedClusters -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonBedClusters.$bedname";
					} else {
						$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -KNC $comparisonBedClusters -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonBedClusters.$bedname -CD $comparisonCD";
					}
				} else {
					if ($comparisonCD eq '') {
						$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -KNC $comparisonBedClusters -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonBedClusters.$chs[0].$chs[1].$bedname -SC $comparisonHeatmapScale";
					} else {
						$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -KNC $comparisonBedClusters -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonBedClusters.$chs[0].$chs[1].$bedname -CD $comparisonCD -SC $comparisonHeatmapScale";
					}
				}
			} else {
				if ($comparisonSortBed == 1) {
					if ($comparisonCenterBed == 1) {
						if ($comparisonHeatmapScale eq '') {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.centered.$bedname";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.centered.$bedname -CD $comparisonCD";
							}
						} else {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.centered.$chs[0].$chs[1].$bedname -SC $comparisonHeatmapScale";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.centered.$chs[0].$chs[1].$bedname -CD $comparisonCD -SC $comparisonHeatmapScale";
							}
						}
					} else {
						if ($comparisonHeatmapScale eq '') {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.$bedname";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.$bedname -CD $comparisonCD";
							}
						} else {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.$chs[0].$chs[1].$bedname -SC $comparisonHeatmapScale";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.$chs[0].$chs[1].$bedname -CD $comparisonCD -SC $comparisonHeatmapScale";
							}
						}
					}		
				} else {
					if ($comparisonCenterBed == 1) {
						if ($comparisonHeatmapScale eq '') {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.centered.$bedname";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.centered.$bedname -CD $comparisonCD";
							}
						} else {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.centered.$chs[0].$chs[1].$bedname -SC $comparisonHeatmapScale";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.centered.$chs[0].$chs[1].$bedname -CD $comparisonCD -SC $comparisonHeatmapScale";
							}
						}
					} else {
						if ($comparisonHeatmapScale eq '') {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$bedname";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$bedname -CD $comparisonCD";
							}
						} else {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$chs[0].$chs[1].$bedname -SC $comparisonHeatmapScale";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$chs[0].$chs[1].$bedname -CD $comparisonCD -SC $comparisonHeatmapScale";
							}
						}
					}	
				}	
			}
		}
	} elsif ($comparisonBedList ne '') {
		my $count = -1; 
		foreach my $bed (@comparisonBeds) {
			$count++;
			my $bedname = $comparisonBedNames[$count];            
            if ($useEqualPeakWidthforComparisonBedList == 1 && $comparisonSortBed == 0) {
            	print OUT "perl $ngsPlotFilesScriptsDirectory\/convertToNGSplotBED.pl $bed $ngsPlotDirectory\/$bedname.same.bed\n";
            } elsif ($useEqualPeakWidthforComparisonBedList == 1 && $comparisonSortBed == 1) {
            	print OUT "perl $ngsPlotFilesScriptsDirectory\/convertToNGSplotSortedBED.pl $bed $ngsPlotDirectory\/$bedname.sort.bed\n";
            } elsif ($useEqualPeakWidthforComparisonBedList == 0 && $comparisonSortBed == 1 && $comparisonCenterBed == 1)  {
                print OUT "perl $ngsPlotFilesScriptsDirectory\/convertToNGSplotSortedCenteredBED.pl $bed $ngsPlotDirectory\/$bedname.sort.center.bed\n";
            } else { 
            	print OUT "perl $ngsPlotFilesScriptsDirectory\/convertToNGSplotCenteredBED.pl $bed $ngsPlotDirectory\/$bedname.center.bed\n";
            } 
			my $outfile = $ngsPlotDirectory . "/configuration.comparison.$bedname.txt";
			open(CNFG, ">$outfile");
			my $count2 = -1;
			foreach my $bam (@comparisons) {
				$count2++;
				my $samplename = $comparisonNames[$count2];
				if ($useEqualPeakWidthforComparisonBedList == 1 && $comparisonSortBed == 0) { 
					print CNFG "$bam\t$ngsPlotDirectory\/$bedname.same.bed\t\"$samplename\"\n";
				} elsif ($useEqualPeakWidthforComparisonBedList == 1 && $comparisonSortBed == 1) {
					print CNFG "$bam\t$ngsPlotDirectory\/$bedname.sort.bed\t\"$samplename\"\n";
				} elsif ($useEqualPeakWidthforComparisonBedList == 0 && $comparisonSortBed == 1 && $comparisonCenterBed == 1)  {
					print CNFG "$bam\t$ngsPlotDirectory\/$bedname.sort.center.bed\t\"$samplename\"\n";
				} else {
					print CNFG "$bam\t$ngsPlotDirectory\/$bedname.center.bed\t\"$samplename\"\n";
				}
			}
			close(CNFG);
			my $rr = int($comparisonBedPeakCounts[$count] / 3000) * 10;
			if ($rr < 30) {
				$rr = 30;
			}
			if ($comparisonBedOrder eq "km") {
				if ($comparisonHeatmapScale eq '') {
					if ($comparisonCD eq '') {
						$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -KNC $comparisonBedClusters -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonBedClusters.$bedname";
					} else {
						$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -KNC $comparisonBedClusters -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonBedClusters.$bedname -CD $comparisonCD";
					}
				} else {
					if ($comparisonCD eq '') {
						$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -KNC $comparisonBedClusters -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonBedClusters.$chs[0].$chs[1].$bedname -SC $comparisonHeatmapScale";
					} else {
						$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -KNC $comparisonBedClusters -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonBedClusters.$chs[0].$chs[1].$bedname -CD $comparisonCD -SC $comparisonHeatmapScale";
					}
				}
			} else {
				if ($comparisonSortBed == 1) {
					if ($comparisonCenterBed == 1) {
						if ($comparisonHeatmapScale eq '') {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.centered.$bedname";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.centered.$bedname -CD $comparisonCD";
							}
						} else {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.centered.$chs[0].$chs[1].$bedname -SC $comparisonHeatmapScale";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.centered.$chs[0].$chs[1].$bedname -CD $comparisonCD -SC $comparisonHeatmapScale";
							}
						}
					} else {
						 if ($comparisonHeatmapScale eq '') {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.$bedname";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.$bedname -CD $comparisonCD";
							}
						} else {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.$chs[0].$chs[1].$bedname -SC $comparisonHeatmapScale";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.sorted.$chs[0].$chs[1].$bedname -CD $comparisonCD -SC $comparisonHeatmapScale";
							}
						}
					}
				} else {
					if ($comparisonCenterBed == 1) {
						if ($comparisonHeatmapScale eq '') {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.centered.$bedname";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.centered.$bedname -CD $comparisonCD";
							}
						} else {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.centered.$chs[0].$chs[1].$bedname -SC $comparisonHeatmapScale";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.centered.$chs[0].$chs[1].$bedname -CD $comparisonCD -SC $comparisonHeatmapScale";
							}
						}
					} else {
						if ($comparisonHeatmapScale eq '') {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$bedname";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$bedname -CD $comparisonCD";
							}
						} else {
							if ($comparisonCD eq '') {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$chs[0].$chs[1].$bedname -SC $comparisonHeatmapScale";
							} else {
								$ngsplotcompcmd{$bedname} = "ngs.plot.r -G $assembly -FL $fragmentLength -L $comparisonBedLength -R bed -C $outfile -RR $rr -GO $comparisonBedOrder -VLN $verticalLines -LWD $lineWidth -p $numBedProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$chs[0].$chs[1].$bedname -CD $comparisonCD -SC $comparisonHeatmapScale";
							}
						}
					} 
				}	
			}
		}	
	}
}	
my $ngsplottsscmd;
my $ngsplotgenebodycmd;
my $ngsplotexoncmd;
my $ngsplotcomptsscmd;
my $ngsplotcompgenebodycmd;
my $ngsplotcompexoncmd;
if ($runTSS == 1 || $runGenebody == 1 || $runExon == 1) {
	my $outfile = $ngsPlotDirectory . "/configuration.tss.genebody.exon.txt";
	open(CNFG, ">$outfile");
	my $count = -1;
	foreach my $bam (@bams) {
		$count++;
		my $samplename = $samples[$count];
		if ($geneList eq "" || $geneList eq "default") { 
			$geneList = "default";
			print CNFG "$bam\t-1\t\"$samplename\"\n";
		} else {
			print CNFG "$bam\t$geneList\t\"$samplename\"\n";
		}
	}
	close(CNFG);
	unless ($geneList eq "" || $geneList eq "default") {
		$geneList = "userGeneList"; 
	}
	my $rr = 30;
	unless ($assembly eq 'sacCer3') {
		$rr = 70;
	} 
	if ($runTSS == 1) {
		if ($geneOrder eq "km") {
			if ($heatmapScale eq '') {
				$ngsplottsscmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthTSS -R tss -C $outfile -RR $rr -GO $geneOrder -KNC $geneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.km.$geneClusters.$geneList.tss";
				$output = "$ngsPlotDirectory\/ngsplot.km.$geneClusters.$geneList.tss";
			} else {
				$ngsplottsscmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthTSS -R tss -C $outfile -RR $rr -GO $geneOrder -KNC $geneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.km.$geneClusters.$geneList.$hs[0].$hs[1].tss -SC $heatmapScale";
				$output = "$ngsPlotDirectory\/ngsplot.km.$geneClusters.$geneList.$hs[0].$hs[1].tss";
			}
		} else {
			if ($heatmapScale eq '') {
				$ngsplottsscmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthTSS -R tss -C $outfile -RR $rr -GO $geneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.$geneList.tss";
				$output = "$ngsPlotDirectory\/ngsplot.$geneList.tss";
			} else {
				$ngsplottsscmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthTSS -R tss -C $outfile -RR $rr -GO $geneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.$geneList.$hs[0].$hs[1].tss -SC $heatmapScale";
				$output = "$ngsPlotDirectory\/ngsplot.$geneList.$hs[0].$hs[1].tss";
			}
		}
		print OUT "$ngsplottsscmd\n";
		if ($geneOrder eq "km") {
		
			#####print OUT "tac gnames_km.txt | awk ' BEGIN {FS = \"\\t\"; cluster=0; last=0} {  if (\$2>0) {  if ( ( last == 0) || last < \$2 ) { cluster++} last = \$2;  print \$1\"\\t\"cluster; } }' - > $output.clusters.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/assignClusters.pl gnames_km.txt $output.clusters.txt\n";
            
            print OUT "unzip -o $output.zip -d $ngsPlotDirectory\n";
            #####print OUT "module load R\n";
            print OUT "Rscript $ngsPlotFilesScriptsDirectory\/getList.R --infile=$output/heatmap.RData --outfile=$output.order.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getTIDs.pl $output.order.txt $output.order.list.txt $geneAnno{$assembly} $entrez{$assembly}\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getClusters.pl $output.order.txt $output.order.list.txt\n";
            unless ($edgeRlist eq '') {
            	print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogFCcdt.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt $geneClusters\n";
            	#print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogCPMcdt.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt $geneClusters\n";
            	print OUT "Rscript $ngsPlotFilesScriptsDirectory\/makeRNAseqHeatmap.R --infile=$output.order.list.edgeR.logFC.cdt --outfile1=$output.order.list.edgeR.logFC.heatmap.-1.1.pdf --outfile2=$output.order.list.edgeR.logFC.heatmap.-1.5.1.5.pdf --outfile3=$output.order.list.edgeR.logFC.heatmap.-2.2.pdf\n";
            }
            	
        
            #####print OUT "module load ngsplot\n";
		}
	}
	if ($runGenebody == 1) {
		if ($geneOrder eq "km") {
			if ($heatmapScale eq '') {
				$ngsplotgenebodycmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthGenebody -R genebody -C $outfile -RR $rr -GO $geneOrder -KNC $geneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.km.$geneClusters.$geneList.genebody";
				$output = "$ngsPlotDirectory\/ngsplot.km.$geneClusters.$geneList.genebody";
			} else {
				$ngsplotgenebodycmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthGenebody -R genebody -C $outfile -RR $rr -GO $geneOrder -KNC $geneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.km.$geneClusters.$geneList.$hs[0].$hs[1].genebody -SC $heatmapScale";
				$output = "$ngsPlotDirectory\/ngsplot.km.$geneClusters.$geneList.$hs[0].$hs[1].genebody";
			}
		} else {
			if ($heatmapScale eq '') {
				$ngsplotgenebodycmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthGenebody -R genebody -C $outfile -RR $rr -GO $geneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.$geneList.genebody";
				$output = "$ngsPlotDirectory\/ngsplot.$geneList.genebody";
			} else {
				$ngsplotgenebodycmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthGenebody -R genebody -C $outfile -RR $rr -GO $geneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.$geneList.$hs[0].$hs[1].genebody -SC $heatmapScale";
				$output = "$ngsPlotDirectory\/ngsplot.$geneList.$hs[0].$hs[1].genebody";
			}
		}
		print OUT "$ngsplotgenebodycmd\n";
		if ($geneOrder eq "km") {
			
			#####print OUT "tac gnames_km.txt | awk ' BEGIN {FS = \"\\t\"; cluster=0; last=0} {  if (\$2>0) {  if ( ( last == 0) || last < \$2 ) { cluster++} last = \$2;  print \$1\"\\t\"cluster; } }' - > $output.clusters.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/assignClusters.pl gnames_km.txt $output.clusters.txt\n";
            
            print OUT "unzip -o $output.zip -d $ngsPlotDirectory\n";
            #####print OUT "module load R\n";
            print OUT "Rscript $ngsPlotFilesScriptsDirectory\/getList.R --infile=$output/heatmap.RData --outfile=$output.order.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getTIDs.pl $output.order.txt $output.order.list.txt $geneAnno{$assembly} $entrez{$assembly}\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getClusters.pl $output.order.txt $output.order.list.txt\n";
            unless ($edgeRlist eq '') {
            	print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogFCcdt.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt $geneClusters\n";
            	#print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogCPMcdt.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt $geneClusters\n";
            	print OUT "Rscript $ngsPlotFilesScriptsDirectory\/makeRNAseqHeatmap.R --infile=$output.order.list.edgeR.logFC.cdt --outfile1=$output.order.list.edgeR.logFC.heatmap.-1.1.pdf --outfile2=$output.order.list.edgeR.logFC.heatmap.-1.5.1.5.pdf --outfile3=$output.order.list.edgeR.logFC.heatmap.-2.2.pdf\n";
            }
            #####print OUT "module load ngsplot\n";
		}
	}
	$rr = 70;
	unless ($assembly eq 'sacCer3') {
		$rr = 200;
	} 
	if ($runExon == 1) {
		if ($geneOrder eq "km") {
			if ($heatmapScale eq '') {
				$ngsplotexoncmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthExon -R exon -C $outfile -RR $rr -GO $geneOrder -KNC $geneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.km.$geneClusters.$geneList.exon";
				$output = "$ngsPlotDirectory\/ngsplot.km.$geneClusters.$geneList.exon";
			} else {
				$ngsplotexoncmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthExon -R exon -C $outfile -RR $rr -GO $geneOrder -KNC $geneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.km.$geneClusters.$geneList.$hs[0].$hs[1].exon -SC $heatmapScale";
				$output = "$ngsPlotDirectory\/ngsplot.km.$geneClusters.$geneList.$hs[0].$hs[1].exon";
			}
		} else {
			if ($heatmapScale eq '') {
				$ngsplotexoncmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthExon -R exon -C $outfile -RR $rr -GO $geneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.$geneList.exon";
				$output = "$ngsPlotDirectory\/ngsplot.$geneList.exon";
			} else {
				$ngsplotexoncmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthExon -R exon -C $outfile -RR $rr -GO $geneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $heatmapColor -O $ngsPlotDirectory\/ngsplot.$geneList.$hs[0].$hs[1].exon -SC $heatmapScale";
				$output = "$ngsPlotDirectory\/ngsplot.$geneList.$hs[0].$hs[1].exon";
			}
		}
		print OUT "$ngsplotexoncmd\n";
		if ($geneOrder eq "km") {
            
            #####print OUT "tac gnames_km.txt | awk ' BEGIN {FS = \"\\t\"; cluster=0; last=0} {  if (\$2>0) {  if ( ( last == 0) || last < \$2 ) { cluster++} last = \$2;  print \$1\"\\t\"cluster; } }' - > $output.clusters.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/assignClusters.pl gnames_km.txt $output.clusters.txt\n";
            
            print OUT "unzip -o $output.zip -d $ngsPlotDirectory\n";
            #####print OUT "module load R\n";
            print OUT "Rscript $ngsPlotFilesScriptsDirectory\/getList.R --infile=$output/heatmap.RData --outfile=$output.order.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getTIDs.pl $output.order.txt $output.order.list.txt $geneAnno{$assembly} $entrez{$assembly}\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getClusters.pl $output.order.txt $output.order.list.txt\n";
            #####print OUT "module load ngsplot\n";
        }
	}
}		
unless ($comparisons eq '') {
if ($runComparisonTSS == 1 || $runComparisonGenebody == 1 || $runComparisonExon == 1) {
	my $outfile = $ngsPlotDirectory . "/configuration.comparison.tss.genebody.exon.txt";
	open(CNFG, ">$outfile");
	my $count = -1;
	foreach my $bam (@comparisons) {
		$count++;
		my $samplename = $comparisonNames[$count];
		if ($comparisonGeneList eq "" || $comparisonGeneList eq "default") {
			$comparisonGeneList = "default"; 
			print CNFG "$bam\t-1\t\"$samplename\"\n";
		} else {
			print CNFG "$bam\t$comparisonGeneList\t\"$samplename\"\n";
		}
	}
	close(CNFG);
	unless ($comparisonGeneList eq "" || $comparisonGeneList eq "default") {
    	$comparisonGeneList = "userCompGeneList";
    } 
	my $rr = 30;
	unless ($assembly eq 'sacCer3') {
		$rr = 70;
	} 
	if ($runComparisonTSS == 1) {		
		if ($comparisonGeneOrder eq "km") {
			if ($comparisonHeatmapScale eq '') {
				if ($comparisonCD eq '') {
					$ngsplotcomptsscmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthTSS -R tss -C $outfile -RR $rr -GO $comparisonGeneOrder -KNC $comparisonGeneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.tss";
					$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.tss";
				} else {
					$ngsplotcomptsscmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthTSS -R tss -C $outfile -RR $rr -GO $comparisonGeneOrder -KNC $comparisonGeneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.tss -CD $comparisonCD";
					$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.tss";
			        }
			} else {
				if ($comparisonCD eq '') {
					$ngsplotcomptsscmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthTSS -R tss -C $outfile -RR $rr -GO $comparisonGeneOrder -KNC $comparisonGeneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.$chs[0].$chs[1].tss -SC $comparisonHeatmapScale";
					$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.$chs[0].$chs[1].tss";
				} else {
					$ngsplotcomptsscmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthTSS -R tss -C $outfile -RR $rr -GO $comparisonGeneOrder -KNC $comparisonGeneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.$chs[0].$chs[1].tss -CD $comparisonCD -SC $comparisonHeatmapScale";
					$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.$chs[0].$chs[1].tss";
				}
			}
		} else {
			if ($comparisonHeatmapScale eq '') {
				if ($comparisonCD eq '') {
					$ngsplotcomptsscmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthTSS -R tss -C $outfile -RR $rr -GO $comparisonGeneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.tss";
					$output = "$ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.tss";
				} else {
					$ngsplotcomptsscmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthTSS -R tss -C $outfile -RR $rr -GO $comparisonGeneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.tss -CD $comparisonCD";
					$output = "$ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.tss";
				}
			} else {
				if ($comparisonCD eq '') {
					$ngsplotcomptsscmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthTSS -R tss -C $outfile -RR $rr -GO $comparisonGeneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.$chs[0].$chs[1].tss -SC $comparisonHeatmapScale";
					$output = "$ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.$chs[0].$chs[1].tss";
				} else {
					$ngsplotcomptsscmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthTSS -R tss -C $outfile -RR $rr -GO $comparisonGeneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.$chs[0].$chs[1].tss -CD $comparisonCD -SC $comparisonHeatmapScale";
					$output = "$ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.$chs[0].$chs[1].tss";
				}
			}
		}
		print OUT "$ngsplotcomptsscmd\n";
		if ($comparisonGeneOrder eq "km") {
            
            
            #####print OUT "tac gnames_km.txt | awk ' BEGIN {FS = \"\\t\"; cluster=0; last=0} {  if (\$2>0) {  if ( ( last == 0) || last < \$2 ) { cluster++} last = \$2;  print \$1\"\\t\"cluster; } }' - > $output.clusters.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/assignClusters.pl gnames_km.txt $output.clusters.txt\n";
            
            print OUT "unzip -o $output.zip -d $ngsPlotDirectory\n";
            #####print OUT "module load R\n";
            print OUT "Rscript $ngsPlotFilesScriptsDirectory\/getList.R --infile=$output/heatmap.RData --outfile=$output.order.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getTIDs.pl $output.order.txt $output.order.list.txt $geneAnno{$assembly} $entrez{$assembly}\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getClusters2.pl $output.order.txt $output.order.list.txt $edgeRlist $edgeRpv\n";
            unless ($edgeRlist eq '') {
            	print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogFCcdt.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt $comparisonGeneClusters\n";
            	#print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogCPMcdt.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt $comparisonGeneClusters\n";
            	print OUT "Rscript $ngsPlotFilesScriptsDirectory\/makeRNAseqHeatmap.R --infile=$output.order.list.edgeR.logFC.cdt --outfile1=$output.order.list.edgeR.logFC.heatmap.-1.1.pdf --outfile2=$output.order.list.edgeR.logFC.heatmap.-1.5.1.5.pdf --outfile3=$output.order.list.edgeR.logFC.heatmap.-2.2.pdf\n";
            }
            #####print OUT "module load ngsplot\n";
        }
        unless ($comparisonGeneList eq "" || $comparisonGeneList eq "default") {
        	
        	
        	
        	#####print OUT "tac gnames_km.txt | awk ' BEGIN {FS = \"\\t\"; cluster=0; last=0} {  if (\$2>0) {  if ( ( last == 0) || last < \$2 ) { cluster++} last = \$2;  print \$1\"\\t\"cluster; } }' - > $output.clusters.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/assignClusters.pl gnames_km.txt $output.clusters.txt\n";
            
            print OUT "unzip -o $output.zip -d $ngsPlotDirectory\n";
            #####print OUT "module load R\n";
            print OUT "Rscript $ngsPlotFilesScriptsDirectory\/getList.R --infile=$output/heatmap.RData --outfile=$output.order.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getTIDs.pl $output.order.txt $output.order.list.txt $geneAnno{$assembly} $entrez{$assembly} $entrez{$assembly}\n";
            unless ($edgeRlist eq '') {
            	print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogFCcdtForGeneList.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt\n";
            	#print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogCPMcdt.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt $comparisonGeneClusters\n";
            	print OUT "Rscript $ngsPlotFilesScriptsDirectory\/makeRNAseqHeatmap.R --infile=$output.order.list.edgeR.logFC.cdt --outfile1=$output.order.list.edgeR.logFC.heatmap.-1.1.pdf --outfile2=$output.order.list.edgeR.logFC.heatmap.-1.5.1.5.pdf --outfile3=$output.order.list.edgeR.logFC.heatmap.-2.2.pdf\n";
            }
        }
	}
	if ($runComparisonGenebody == 1) {		
		if ($comparisonGeneOrder eq "km") {
			if ($comparisonHeatmapScale eq '') {
				if ($comparisonCD eq '') {
					$ngsplotcompgenebodycmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthGenebody -R genebody -C $outfile -RR $rr -GO $comparisonGeneOrder -KNC $comparisonGeneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.genebody";
					$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.genebody";
				} else {
					$ngsplotcompgenebodycmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthGenebody -R genebody -C $outfile -RR $rr -GO $comparisonGeneOrder -KNC $comparisonGeneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.genebody -CD $comparisonCD";
					$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.genebody";
				}
			} else {
				if ($comparisonCD eq '') {
					$ngsplotcompgenebodycmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthGenebody -R genebody -C $outfile -RR $rr -GO $comparisonGeneOrder -KNC $comparisonGeneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.$chs[0].$chs[1].genebody -SC $comparisonHeatmapScale";
					$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.$chs[0].$chs[1].genebody";
				} else {
					$ngsplotcompgenebodycmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthGenebody -R genebody -C $outfile -RR $rr -GO $comparisonGeneOrder -KNC $comparisonGeneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.$chs[0].$chs[1].genebody -CD $comparisonCD -SC $comparisonHeatmapScale";
					$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.$chs[0].$chs[1].genebody";
				}
			}
		} else {
			if ($comparisonHeatmapScale eq '') {
				if ($comparisonCD eq '') {
					$ngsplotcompgenebodycmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthGenebody -R genebody -C $outfile -RR $rr -GO $comparisonGeneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.genebody";
					$output = "$ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.genebody";
				} else {
					$ngsplotcompgenebodycmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthGenebody -R genebody -C $outfile -RR $rr -GO $comparisonGeneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.genebody -CD $comparisonCD";
					$output = "$ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.genebody";
				}
			} else {
				if ($comparisonCD eq '') {
					$ngsplotcompgenebodycmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthGenebody -R genebody -C $outfile -RR $rr -GO $comparisonGeneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.$chs[0].$chs[1].genebody -SC $comparisonHeatmapScale";
					$output = "$ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.$chs[0].$chs[1].genebody";
				} else {
					$ngsplotcompgenebodycmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthGenebody -R genebody -C $outfile -RR $rr -GO $comparisonGeneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.$chs[0].$chs[1].genebody -CD $comparisonCD -SC $comparisonHeatmapScale";
					$output = "$ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.$chs[0].$chs[1].genebody";
				}
			}
		}
		print OUT "$ngsplotcompgenebodycmd\n";
		if ($comparisonGeneOrder eq "km") {
            
            
            
            #####print OUT "tac gnames_km.txt | awk ' BEGIN {FS = \"\\t\"; cluster=0; last=0} {  if (\$2>0) {  if ( ( last == 0) || last < \$2 ) { cluster++} last = \$2;  print \$1\"\\t\"cluster; } }' - > $output.clusters.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/assignClusters.pl gnames_km.txt $output.clusters.txt\n";
            
            
            
            print OUT "unzip -o $output.zip -d $ngsPlotDirectory\n";
            #####print OUT "module load R\n";
            print OUT "Rscript $ngsPlotFilesScriptsDirectory\/getList.R --infile=$output/heatmap.RData --outfile=$output.order.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getTIDs.pl $output.order.txt $output.order.list.txt $geneAnno{$assembly} $entrez{$assembly}\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getClusters2.pl $output.order.txt $output.order.list.txt $edgeRlist $edgeRpv\n";
            unless ($edgeRlist eq '') {
            	print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogFCcdt.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt $comparisonGeneClusters\n";
            	#print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogCPMcdt.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt $comparisonGeneClusters\n";
            	print OUT "Rscript $ngsPlotFilesScriptsDirectory\/makeRNAseqHeatmap.R --infile=$output.order.list.edgeR.logFC.cdt --outfile1=$output.order.list.edgeR.logFC.heatmap.-1.1.pdf --outfile2=$output.order.list.edgeR.logFC.heatmap.-1.5.1.5.pdf --outfile3=$output.order.list.edgeR.logFC.heatmap.-2.2.pdf\n";
            }
            #####print OUT "module load ngsplot\n";
        }
        unless ($comparisonGeneList eq "" || $comparisonGeneList eq "default") {
        	
        	#####print OUT "tac gnames_km.txt | awk ' BEGIN {FS = \"\\t\"; cluster=0; last=0} {  if (\$2>0) {  if ( ( last == 0) || last < \$2 ) { cluster++} last = \$2;  print \$1\"\\t\"cluster; } }' - > $output.clusters.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/assignClusters.pl gnames_km.txt $output.clusters.txt\n";
            
            print OUT "unzip -o $output.zip -d $ngsPlotDirectory\n";
            #####print OUT "module load R\n";
            print OUT "Rscript $ngsPlotFilesScriptsDirectory\/getList.R --infile=$output/heatmap.RData --outfile=$output.order.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getTIDs.pl $output.order.txt $output.order.list.txt $geneAnno{$assembly} $entrez{$assembly}\n";
            unless ($edgeRlist eq '') {
            	print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogFCcdtForGeneList.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt\n";
            	#print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogCPMcdt.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt $comparisonGeneClusters\n";
            	print OUT "Rscript $ngsPlotFilesScriptsDirectory\/makeRNAseqHeatmap.R --infile=$output.order.list.edgeR.logFC.cdt --outfile1=$output.order.list.edgeR.logFC.heatmap.-1.1.pdf --outfile2=$output.order.list.edgeR.logFC.heatmap.-1.5.1.5.pdf --outfile3=$output.order.list.edgeR.logFC.heatmap.-2.2.pdf\n";
            }
        }
	}
	$rr = 70;
	unless ($assembly eq 'sacCer3') {
		$rr = 200;
	} 
	if ($runComparisonExon == 1) {		
		if ($comparisonGeneOrder eq "km") {
			if ($comparisonHeatmapScale eq '') {
				if ($comparisonCD eq '') {
					$ngsplotcompexoncmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthExon -R exon -C $outfile -RR $rr -GO $comparisonGeneOrder -KNC $comparisonGeneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.exon";
					$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.exon";
				} else {
					$ngsplotcompexoncmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthExon -R exon -C $outfile -RR $rr -GO $comparisonGeneOrder -KNC $comparisonGeneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.exon -CD $comparisonCD";
					$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.exon";
				}
			} else {
				if ($comparisonCD eq '') {
					$ngsplotcompexoncmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthExon -R exon -C $outfile -RR $rr -GO $comparisonGeneOrder -KNC $comparisonGeneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.$chs[0].$chs[1].exon -SC $comparisonHeatmapScale";
					$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.$chs[0].$chs[1].exon";
				} else {
					$ngsplotcompexoncmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthExon -R exon -C $outfile -RR $rr -GO $comparisonGeneOrder -KNC $comparisonGeneClusters -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.$chs[0].$chs[1].exon -CD $comparisonCD -SC $comparisonHeatmapScale";
					$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonGeneClusters.$comparisonGeneList.$chs[0].$chs[1].exon";
				}
			}
		} else {
			if ($comparisonHeatmapScale eq '') {
				if ($comparisonCD eq '') {
					$ngsplotcompexoncmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthExon -R exon -C $outfile -RR $rr -GO $comparisonGeneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.exon";
					$output = "$ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.exon";
				} else {
					$ngsplotcompexoncmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthExon -R exon -C $outfile -RR $rr -GO $comparisonGeneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.exon -CD $comparisonCD";
					$output = "$ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.exon";
				}
			} else {
				if ($comparisonCD eq '') {
					$ngsplotcompexoncmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthExon -R exon -C $outfile -RR $rr -GO $comparisonGeneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.$chs[0].$chs[1].exon -SC $comparisonHeatmapScale";
					$output = "$ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.$chs[0].$chs[1].exon";
				} else {
					$ngsplotcompexoncmd = "ngs.plot.r -G $assembly -FL $fragmentLength -L $lengthExon -R exon -C $outfile -RR $rr -GO $comparisonGeneOrder -VLN $verticalLines -LWD $lineWidth -p $numProcessors -CO $comparisonHeatmapColors -O $ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.$chs[0].$chs[1].exon -CD $comparisonCD -SC $comparisonHeatmapScale";
					$output = "$ngsPlotDirectory\/ngsplot.comp.$comparisonGeneList.$chs[0].$chs[1].exon";
				}
			}
		}
		print OUT "$ngsplotcompexoncmd\n";
		if ($comparisonGeneOrder eq "km") {
            
            
            #####print OUT "tac gnames_km.txt | awk ' BEGIN {FS = \"\\t\"; cluster=0; last=0} {  if (\$2>0) {  if ( ( last == 0) || last < \$2 ) { cluster++} last = \$2;  print \$1\"\\t\"cluster; } }' - > $output.clusters.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/assignClusters.pl gnames_km.txt $output.clusters.txt\n";
            
            
            print OUT "unzip -o $output.zip -d $ngsPlotDirectory\n";
            #####print OUT "module load R\n";
            print OUT "Rscript $ngsPlotFilesScriptsDirectory\/getList.R --infile=$output/heatmap.RData --outfile=$output.order.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getTIDs.pl $output.order.txt $output.order.list.txt $geneAnno{$assembly} $entrez{$assembly}\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getClusters2.pl $output.order.txt $output.order.list.txt $edgeRlist $edgeRpv\n";
            #####print OUT "module load ngsplot\n";              
        }
        unless ($comparisonGeneList eq "" || $comparisonGeneList eq "default") {
        	
        	
        	#####print OUT "tac gnames_km.txt | awk ' BEGIN {FS = \"\\t\"; cluster=0; last=0} {  if (\$2>0) {  if ( ( last == 0) || last < \$2 ) { cluster++} last = \$2;  print \$1\"\\t\"cluster; } }' - > $output.clusters.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/assignClusters.pl gnames_km.txt $output.clusters.txt\n";
            
            print OUT "unzip -o $output.zip -d $ngsPlotDirectory\n";
            #####print OUT "module load R\n";
            print OUT "Rscript $ngsPlotFilesScriptsDirectory\/getList.R --infile=$output/heatmap.RData --outfile=$output.order.txt\n";
            print OUT "perl $ngsPlotFilesScriptsDirectory\/getTIDs.pl $output.order.txt $output.order.list.txt $geneAnno{$assembly} $entrez{$assembly}\n";
            unless ($edgeRlist eq '') {
            	print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogFCcdtForGeneList.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt\n";
            	#print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogCPMcdtForGeneList.pl $geneAnno{$assembly} $edgeRlist $output.order.list.txt $comparisonGeneClusters\n";
            	print OUT "Rscript $ngsPlotFilesScriptsDirectory\/makeRNAseqHeatmap.R --infile=$output.order.list.edgeR.logFC.cdt --outfile1=$output.order.list.edgeR.logFC.heatmap.-1.1.pdf --outfile2=$output.order.list.edgeR.logFC.heatmap.-1.5.1.5.pdf --outfile3=$output.order.list.edgeR.logFC.heatmap.-2.2.pdf\n";
            }
        }
	}
}
}
unless ($bedList eq '') {
	my $count = -1;
	my $count2 = 0; 
	foreach my $bed (@beds) {
		$count++;
		$count2++;
		my $bedname = $bedNames[$count]; 
		if  ($runBedParallel == 0) {
			print OUT "$ngsplotcmd{$bedname}\n";
			if ($bedOrder eq 'km') {
				if ($heatmapScale eq '') {
					$output = "$ngsPlotDirectory\/ngsplot.km.$bedClusters.$bedname";
				} else {
					$output = "$ngsPlotDirectory\/ngsplot.km.$bedClusters.$hs[0].$hs[1].$bedname";
				}
				
				
				#####print OUT "tac gnames_km.txt | awk ' BEGIN {FS = \"\\t\"; cluster=0; last=0} {  if (\$2>0) {  if ( ( last == 0) || last < \$2 ) { cluster++} last = \$2;  print \$1\"\\t\"cluster; } }' - > $output.clusters.txt\n";
            	print OUT "perl $ngsPlotFilesScriptsDirectory\/assignClusters.pl gnames_km.txt $output.clusters.txt\n";
            	
            	
            	print OUT "unzip -o $output.zip -d $ngsPlotDirectory\n";
            	#####print OUT "module load R\n";
            	print OUT "Rscript $ngsPlotFilesScriptsDirectory\/getList.R --infile=$output/heatmap.RData --outfile=$output.order.txt\n";
            	print OUT "perl $ngsPlotFilesScriptsDirectory\/getIDs.pl $output.order.txt $output.order.list.txt\n";
            	if ($useEqualPeakWidthforBedList == 1 && $sortBed == 0) { 
					print OUT "perl $ngsPlotFilesScriptsDirectory\/getBedClusters.pl $output.clusters.txt $ngsPlotDirectory\/$bedname.same.bed $output.order.txt\n";
				} elsif ($useEqualPeakWidthforBedList == 1 && $sortBed == 1) {
					print OUT "perl $ngsPlotFilesScriptsDirectory\/getBedClusters.pl $output.clusters.txt $ngsPlotDirectory\/$bedname.sort.bed $output.order.txt\n";
				} elsif ($useEqualPeakWidthforBedList == 0 && $sortBed == 1 && $centerBed == 1)  {
					print OUT "perl $ngsPlotFilesScriptsDirectory\/getBedClusters.pl $output.clusters.txt $ngsPlotDirectory\/$bedname.sort.center.bed $output.order.txt\n";
				} else {
					print OUT "perl $ngsPlotFilesScriptsDirectory\/getBedClusters.pl $output.clusters.txt $ngsPlotDirectory\/$bedname.center.bed $output.order.txt\n";
				}
            	#####print OUT "module load ngsplot\n";
			}
		} else {
			print OUT "$ngsplotcmd{$bedname} &\n";
			if ($count2 % $numProcessors == 0) {
				print OUT "wait\n";
			}
		}
	}
	if ($count2 % $numProcessors > 0 && $runBedParallel == 1) {
		print OUT "wait\n";
	}
}		
unless ($comparisons eq '') {
	if ($comparisonBedList eq '') {
		my $count = -1; 
		my $count2 = 0;
		foreach my $bed (@beds) {
			$count++;
			$count2++;
			my $bedname = $bedNames[$count]; 
			if  ($runBedParallel == 0) {
				print OUT "$ngsplotcompcmd{$bedname}\n";
				if ($comparisonBedOrder eq 'km') {
					if ($comparisonHeatmapScale eq '') {
						$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonBedClusters.$bedname";
					} else {
						$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonBedClusters.$chs[0].$chs[1].$bedname";
					}
                	
                	
                	#####print OUT "tac gnames_km.txt | awk ' BEGIN {FS = \"\\t\"; cluster=0; last=0} {  if (\$2>0) {  if ( ( last == 0) || last < \$2 ) { cluster++} last = \$2;  print \$1\"\\t\"cluster; } }' - > $output.clusters.txt\n";
            		print OUT "perl $ngsPlotFilesScriptsDirectory\/assignClusters.pl gnames_km.txt $output.clusters.txt\n";
            		
            		
            		print OUT "unzip -o $output.zip -d $ngsPlotDirectory\n";
            		#####print OUT "module load R\n";
            		print OUT "Rscript $ngsPlotFilesScriptsDirectory\/getList.R --infile=$output/heatmap.RData --outfile=$output.order.txt\n";
            		print OUT "perl $ngsPlotFilesScriptsDirectory\/getIDs.pl $output.order.txt $output.order.list.txt\n";
            		if ($useEqualPeakWidthforComparisonBedList == 1 && $comparisonSortBed == 0) { 
						print OUT "perl $ngsPlotFilesScriptsDirectory\/getBedClusters.pl $output.clusters.txt $ngsPlotDirectory\/$bedname.same.bed $output.order.txt\n";
					} elsif ($useEqualPeakWidthforComparisonBedList == 1 && $comparisonSortBed == 1) {
						print OUT "perl $ngsPlotFilesScriptsDirectory\/getBedClusters.pl $output.clusters.txt $ngsPlotDirectory\/$bedname.sort.bed $output.order.txt\n";
					} elsif ($useEqualPeakWidthforComparisonBedList == 0 && $comparisonSortBed == 1 && $comparisonCenterBed == 1)  {
						print OUT "perl $ngsPlotFilesScriptsDirectory\/getBedClusters.pl $output.clusters.txt $ngsPlotDirectory\/$bedname.sort.center.bed $output.order.txt\n";
					} else {
						print OUT "perl $ngsPlotFilesScriptsDirectory\/getBedClusters.pl $output.clusters.txt $ngsPlotDirectory\/$bedname.center.bed $output.order.txt\n";
					}
					unless ($edgeRlist eq '') {
            			print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogFCcdtForBed.pl $geneAnno{$assembly} $edgeRlist $output.order.bed $comparisonBedClusters $edgeRpv\n";
            			#print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogCPMcdtForBed.pl $geneAnno{$assembly} $edgeRlist $output.order.list.bed $comparisonBedClusters $edgeRpv\n";
            			print OUT "Rscript $ngsPlotFilesScriptsDirectory\/makeRNAseqHeatmap.R --infile=$output.order.edgeR.logFC.cdt --outfile1=$output.order.edgeR.logFC.heatmap.-1.1.pdf --outfile2=$output.order.edgeR.logFC.heatmap.-1.5.1.5.pdf --outfile3=$output.order.edgeR.logFC.heatmap.-2.2.pdf\n";
            		}
            		#####print OUT "module load ngsplot\n";
                }
			} else {
				print OUT "$ngsplotcompcmd{$bedname} &\n";
				if ($count2 % $numProcessors == 0) {
					print OUT "wait\n";
				}
			}
		}
		if ($count2 % $numProcessors > 0 && $runBedParallel == 1) {
			print OUT "wait\n";
		}
	} elsif ($comparisonBedList ne '') {
		my $count = -1; 
		my $count2 = 0;
		foreach my $bed (@comparisonBeds) {
			$count++;
			$count2++;	
			my $bedname = $comparisonBedNames[$count]; 
			if  ($runBedParallel == 0) {
				print OUT "$ngsplotcompcmd{$bedname}\n";
				if ($comparisonBedOrder eq 'km') {
					if ($comparisonHeatmapScale eq '') {
						$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonBedClusters.$bedname";
					} else {
						$output = "$ngsPlotDirectory\/ngsplot.comp.km.$comparisonBedClusters.$chs[0].$chs[1].$bedname";
					}
                	
                	
                	#####print OUT "tac gnames_km.txt | awk ' BEGIN {FS = \"\\t\"; cluster=0; last=0} {  if (\$2>0) {  if ( ( last == 0) || last < \$2 ) { cluster++} last = \$2;  print \$1\"\\t\"cluster; } }' - > $output.clusters.txt\n";
            		print OUT "perl $ngsPlotFilesScriptsDirectory\/assignClusters.pl gnames_km.txt $output.clusters.txt\n";
            		
            		
            		print OUT "unzip -o $output.zip -d $ngsPlotDirectory\n";
            		#####print OUT "module load R\n";
            		print OUT "Rscript $ngsPlotFilesScriptsDirectory\/getList.R --infile=$output/heatmap.RData --outfile=$output.order.txt\n";
            		print OUT "perl $ngsPlotFilesScriptsDirectory\/getIDs.pl $output.order.txt $output.order.list.txt\n";
            		if ($useEqualPeakWidthforComparisonBedList == 1 && $comparisonSortBed == 0) { 
						print OUT "perl $ngsPlotFilesScriptsDirectory\/getBedClusters.pl $output.clusters.txt $ngsPlotDirectory\/$bedname.same.bed $output.order.txt\n";
					} elsif ($useEqualPeakWidthforComparisonBedList == 1 && $comparisonSortBed == 1) {
						print OUT "perl $ngsPlotFilesScriptsDirectory\/getBedClusters.pl $output.clusters.txt $ngsPlotDirectory\/$bedname.sort.bed $output.order.txt\n";
					} elsif ($useEqualPeakWidthforComparisonBedList == 0 && $comparisonSortBed == 1 && $comparisonCenterBed == 1)  {
						print OUT "perl $ngsPlotFilesScriptsDirectory\/getBedClusters.pl $output.clusters.txt $ngsPlotDirectory\/$bedname.sort.center.bed $output.order.txt\n";
					} else {
						print OUT "perl $ngsPlotFilesScriptsDirectory\/getBedClusters.pl $output.clusters.txt $ngsPlotDirectory\/$bedname.center.bed $output.order.txt\n";
					}
					unless ($edgeRlist eq '') {
            			print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogFCcdtForBed.pl $geneAnno{$assembly} $edgeRlist $output.order.bed $comparisonBedClusters $edgeRpv\n";
            			#print OUT "perl $ngsPlotFilesScriptsDirectory\/makeEdgeRlogCPMcdtForBed.pl $geneAnno{$assembly} $edgeRlist $output.order.list.bed $comparisonBedClusters $edgeRpv\n";
            			print OUT "Rscript $ngsPlotFilesScriptsDirectory\/makeRNAseqHeatmap.R --infile=$output.order.edgeR.logFC.cdt --outfile1=$output.order.edgeR.logFC.heatmap.-1.1.pdf --outfile2=$output.order.edgeR.logFC.heatmap.-1.5.1.5.pdf --outfile3=$output.order.edgeR.logFC.heatmap.-2.2.pdf\n";
            		}
            		#####print OUT "module load ngsplot\n";       
                }
			} else {
				print OUT "$ngsplotcompcmd{$bedname} &\n";
				if ($count2 % $numProcessors == 0) {
					print OUT "wait\n";
				}
			}
		}
		if ($count2 % $numProcessors > 0 && $runBedParallel == 1) {
			print OUT "wait\n";
		}
	}
}
if ($assembly eq 'mm9' || $assembly eq 'mm10' || $assembly eq 'hg18' || $assembly eq 'hg19') {
	#print OUT "perl $ngsPlotFilesScriptsDirectory\/makeHOMERshellScript.pl $ngsPlotDirectory\/ $homerShellScript $assembly $promoter1k{$assembly} $cgi{$assembly}\n";
	print OUT "perl $ngsPlotFilesScriptsDirectory\/makeHOMERshellScript.pl $ngsPlotDirectory\/ $homerShellScript $assembly\n";
} else {
	#print OUT "perl $ngsPlotFilesScriptsDirectory\/makeHOMERshellScript.pl $ngsPlotDirectory\/ $homerShellScript $assembly $promoter1k{$assembly}\n";
	print OUT "perl $ngsPlotFilesScriptsDirectory\/makeHOMERshellScript.pl $ngsPlotDirectory\/ $homerShellScript $assembly\n";
}
print OUT "perl $ngsPlotFilesScriptsDirectory\/makeHOMERshellScript2.pl $ngsPlotDirectory\/ $homerShellScript2 $assembly\n";
close(OUT);


