$homerShellScript2 = $ARGV[1];
open(OUT, ">$homerShellScript2");
$assembly = $ARGV[2];
opendir(DIR, $ARGV[0]);
@files = grep /entrez/, readdir DIR;
close DIR;
$filecount = 0;
foreach $file (@files) {
	$filecount++;
	if ($filecount == 1) {
		$goDir = $ARGV[0] . "homerGO";
		#print OUT "module use /projects/b1025/tools/Modules\n";
		#print OUT "module load homer\n";
		#print OUT "which findGO.pl\n";
		#print OUT "mkdir $goDir\n";
		print OUT "#!/bin/bash\n";
		print OUT "#SBATCH -t 0-12:00\n";                         
		print OUT "#SBATCH -n 4\n";
		print OUT "#SBATCH -p short\n";                  
		print OUT "#SBATCH --mem=32000\n";
		print OUT "#SBATCH -o cc463_%j.out\n";        
		print OUT "#SBATCH -e cc463_%j.err\n";
		print OUT "#SBATCH --mail-type=ALL\n";
		print OUT "#SBATCH --mail-user=ccolling\@broadinstitute.org\n";
		print OUT "module load gcc/6.2.0\n";
		print OUT "module load R/3.2.5\n";
		#print OUT "module load homer/4.9\n";
		#print OUT "which annotatePeaks.pl\n";
		#print OUT "which findMotifsGenome.pl\n";
	}	
	($filename) = ($file =~ /(\S+)\.txt/);
	print OUT "# $filename\n";
	$goFileDir = $goDir . "/" . $filename . ".GO";
	print OUT "mkdir $goFileDir\n";
	if ($assembly eq 'hg18' || $assembly eq 'hg19') { 
		$organism = "human";
	} elsif ($assembly eq 'mm9' || $assembly eq 'mm10') {
                $organism = "mouse";
    } elsif ($assembly eq 'dm3' || $assembly eq 'dm6') {
                $organism = "fly";
    } else {
		$organsim = "yeast";
	}
	print OUT "findGO.pl $ARGV[0]\/$file $organism $goFileDir\n";  
}
