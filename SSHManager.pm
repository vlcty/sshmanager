package SSHManager;
use Term::ANSIColor;
require Exporter;

use strict;

our @ISA = qw(Exporter);
our @EXPORT = qw(trim getScoresAsLongAsString dieInRedColor);

sub trim {
	my $input = shift;
	chomp($input);
	$input =~ s/^\s+//ig;
	$input =~ s/\s+$//ig;
	return $input;
}

sub getScoresAsLongAsString {
	my $message = shift;
	my $result = '';

	for (my $i = 0; $i < length($message); $i++) {
		$result .= '-';
	}

	return $result;
}

1;