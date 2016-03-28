use 5.020 ;


my @img= grep { $_ } map { /(DSC_\d+)\./ } <DSC_[0-9]*.JPG> ;
{
	open my $FI, '>', 'list.txt' ;
	for ( @img ) { say $FI "$_ 1 _" }
}

