use 5.022 ;

my %szrank = ( XXS => 10,
	       XS => 11,
	       S  => 12,
	       M  => 13,
	       L  => 14,
	       XL => 15,
	      '2XL' => 16,
	      '3XL' => 17,
	       KS => 25,
	       KL => 26,
	       TW => 30,
	       OS => 31,
	       TC => 32,
	       K1 => 40,
	       K2 => 41,
	       K3 => 42,
	       K4 => 43,
	       K6 => 44,
	       K8 => 45,
	       K10 => 46,
	       K12 => 47,
	       K14 => 48,
	       KD2 => 50,
	       KD34 => 51,
	       KD56 => 52,
	       KD7 => 53,
	       KD810 => 54,
	       KD1214 => 55,
	       GEN => 90,
	      ) ;

my %szlabel = ( S => 'Small',
		M => 'Med',
		L => 'Large',
		KS => 'Kids Small',
		KL => 'Kids Large',
		TW => 'Tween',
		OS => 'One Size',
		TC => 'Tall & Curvy',
		KD2 => '2',
		KD34 => '3/4',
		KD56 => '5/6',
		KD7 => '7',
		KD810 => '8/10',
		KD1214 => '12/14'
	    ) ;

for ( sort { $szrank{$a} <=> $szrank{$b} } keys %szrank )
{
  my ($rank)= ( $szrank{$_} ) ;
  my $lab= $szlabel{$_} || $_ ;
  say "INSERT INTO sizes (code, label, ranking) VALUES ('$_', '$lab', $rank ) ;"
}


