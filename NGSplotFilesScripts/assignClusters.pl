open(IN,$ARGV[0]);
open(OUT, ">$ARGV[1]");
$linecount = 0;
$cluster = 0;
$ascending = 0;
while($line=<IN>) {
	$line =~ s/"//g;
	$linecount++;
	chomp $line;
	@line = split(" ", $line);
	if ($linecount == 1) {
		next;
	}
	$loc = $line[0];
    $id = $line[1];
	if ($linecount == 2) {
		$cluster++;
		print OUT "$loc\t$cluster\n";
		$lastid = $id;
		next;
	}
	if ($linecount == 3) {
		if ($id < $lastid) {
			$ascending = 0;
		} else {
			$ascending = 1;
		}
		print OUT "$loc\t$cluster\n";
		$lastid = $id;
		next;
	}
	if ($ascending == 0) {
		if ($id < $lastid) {
			print OUT "$loc\t$cluster\n";
		} else {
			$cluster++;
			print OUT "$loc\t$cluster\n";
		}
	} else {
		if ($id > $lastid) {
			print OUT "$loc\t$cluster\n";
		} else {
			$cluster++;
			print OUT "$loc\t$cluster\n";
		}
	}
	$lastid = $id;
}			
