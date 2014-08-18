#!/usr/bin/perl
BEGIN {
	push(@INC, 'SSHManager/');
}

use strict;
use Getopt::Long;
use Term::ANSIColor;
use SSHManager::SSHManager;

main();

sub main {
	parseArguments();
}

sub parseArguments {
	GetOptions
	(
		"install-cron-script" => \&installCronScript
	);
}

sub installCronScript {
	die(colored("You need root access to add a new crontab fragment\n",'red')) if ( ! SSHManager::applicationRunsWithRootRights() );

	my $distributorPath = getUserInput("Full path to distributor.pl","^.*distributor.pl\$");
	my $executionInterval = getUserInput("Execution interval in minutes", "^[0-9]{1,2}\$");
	my $endpoint = getUserInput("Endpoint", "^(http|local)\$");
	my $location = getUserInput("Location", "^.*\$");

	my $fileContent = <<EOS;
# SSHManager crontab fragment
*/$executionInterval	*	*	*	*	root	( cd $distributorPath; perl distributor.pl --endpoint $endpoint --location \"$location\"; logger \"sshmanager: keys distributed\" );
EOS

	open(CRONFRAGMENT, ">/etc/cron.d/sshmanager");
	print CRONFRAGMENT $fileContent;
	close(CRONFRAGMENT);

	print("Done!\n");
}

sub getUserInput {
	my ( $question, $validationRegex ) = @_;
	my $input = '';

	do
	{
		print("$question: ");
		$input = <STDIN>;
		chomp($input);
	}
	while ( $input !~ $validationRegex );
	
	return $input;
}