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
               K2 => 40,
               K4 => 41,
               K6 => 42,
               K8 => 43,
               K10 => 44,
               K12 => 45,
               K14 => 46,
               GEN => 50,
              ) ;

my %szlabel = ( S => 'Small',
		M => 'Med',
		L => 'Large',
		KS => 'Kids Small',
		KL => 'Kids Large',
		TW => 'Tween',
		OS => 'One Size',
		TC => 'Tall & Curvy'
	      ) ;

for ( sort { $szrank{$a} <=> $szrank{$b} } keys %szrank )
{
  my ($rank)= ( $szrank{$_} ) ;
  my $lab= $szlabel{$_} || $_ ;
  say "INSERT INTO sizes (code, label, ranking) VALUES ('$_', '$lab', $rank ) ;"
}


