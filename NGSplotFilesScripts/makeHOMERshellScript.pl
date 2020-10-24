$homerShellScript = $ARGV[1];
open(OUT, ">$homerShellScript");
$assembly = $ARGV[2];
$promoters = $ARGV[3];
$cgis = $ARGV[4];
opendir(DIR, $ARGV[0]);
@files = grep /bed/, readdir DIR;
close DIR;
$filecount = 0;
foreach $file (@files) {
	$filecount++;
	if ($filecount == 1) {
		$annoDir = $ARGV[0] . "homerAnnotation";
		$motifDir = $ARGV[0] . "homerMotifAnalysis";
		#print OUT "module use /projects/b1025/tools/Modules\n";
		
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
		print OUT "mkdir $annoDir\n";
		print OUT "mkdir $motifDir\n";
	}	
	($filename) = ($file =~ /(\S+)\.bed/);
	print OUT "# $filename\n";
	$annofile = $annoDir . "/" . $filename . ".anno.txt";
	$annostatsfile = $annoDir . "/" . $filename . ".annoStats.txt";
	unless ($cgis eq '') {
		$cgiDir = $motifDir . "/" . $filename. ".cgi.bg.1000";
		print OUT "mkdir $cgiDir\n";
	}
	$promoterDir = $motifDir . "/" . $filename. ".promoter.bg.1000";
	$genomeDir = $motifDir . "/" . $filename. ".genome.bg.1000";
	$genomeOntologyDir = $annoDir . "/" . $filename . ".genomeOntology";
	$geneOntologyDir = $annoDir . "/" . $filename . ".geneOntology";
	print OUT "mkdir $promoterDir\n";
	print OUT "mkdir $genomeDir\n";
	print OUT "mkdir $genomeOntologyDir\n";
	print OUT "mkdir $geneOntologyDir\n";
	print OUT "annotatePeaks.pl $ARGV[0]\/$file $assembly -annStats $annostatsfile -go $geneOntologyDir -genomeOntology $genomeOntologyDir > $annofile\n";
	print OUT "findMotifsGenome.pl $ARGV[0]\/$file $assembly $genomeDir -size 1000 -preparsedDir /n/data1/dfci/pedonc/kadoch/cc463/homer/\n"; 
	print OUT "findMotifsGenome.pl $ARGV[0]\/$file $assembly $promoterDir -bg $promoters -size 1000 -preparsedDir /n/data1/dfci/pedonc/kadoch/cc463/homer/\n";
	unless ($cgis eq '') {
		print OUT "findMotifsGenome.pl $ARGV[0]\/$file $assembly $cgiDir -bg $cgis -size 1000 -preparsedDir /n/data1/dfci/pedonc/kadoch/cc463/homer/\n";
	} 
}
