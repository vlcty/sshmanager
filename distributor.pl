#!/usr/bin/perl
use strict;
use XML::LibXML;
use Getopt::Long;
use LWP::UserAgent;
use Term::ANSIColor;
use Systemuser;
use Key;
use Group;
use SSHManager;

# Config
our $verbose = 0;
our $dry = 0;
our $hostname = '';
our $endpoint = '';
our $location = '';
our $version = "1.0";
our $debug = 0;

# Resources
our @systemUsers;
our @keys;
our @groups;

main();

sub main {
	parseOptions();
	printPrologue() if ( $verbose );
	printDebugInformation() if ( $debug );
	checkForRootPrivileges();
	determineHostname();
	loadSystemUsers();

	my $xml = retrieveXML();
	my $document = XML::LibXML->load_xml( string => $xml );

	parseKeysFromXML($document);
	parseGroupsFromXML($document);

	distributeForThisHost($document);
	printEndmessage() if ( $verbose );

	exit 0;
}

sub parseOptions {
	GetOptions
	(
		"verbose" => \$verbose,
		"hostname=s" => \$hostname,
		"endpoint=s" => \$endpoint,
		"location=s" => \$location,
		"dry" => \$dry,
		"debug" => \$debug
	);

	$verbose = 1 if ( $dry );
	$verbose = 1 if ( $debug );

	dieInRedColor("Didn't get an endpoint. Please use the --endpoint option!\n") if ( length($endpoint) == 0 );
	dieInRedColor("Didn't get an URI. Please use the --uri option!\n") if ( length($location) == 0 );
}

sub printPrologue {
	my $message = <<EOS;

SSH manager - Distribute ssh keys for system user accounts
Version: $version
Copyright (C) 2014  Josef 'veloc1ty' Stautner ( hello\@veloc1ty.de );

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

EOS

	print(colored($message,'bold white'));
}

sub printDebugInformation {
	print(colored("Debug information:\n",'bold white'));
	print("\n");
	print("Verbose: $verbose\n");
	print("Dry: $dry\n");
	print("Hostname: $hostname\n");
	print("Endpoint: $endpoint\n");
	print("Location: $location\n");
	print("Version: $version\n");
	print("Debug: $debug\n");
	print("\n");
}

sub checkForRootPrivileges {
	if ( $< != 0 ) {
		dieInRedColor("This script has to run with root privileges in order to work correctly!\n");
	}
}

sub determineHostname {
	if ( length($hostname) == 0 ) {
		$hostname = `hostname`;
		chomp($hostname);
	}
	
	dieInRedColor("Was not able to retrieve a hostname. Try using the --hostname option!\n") if ( length($hostname) == 0 );
	printf(colored("Hostname: $hostname\n",'bold white')) if ( $verbose );
}

sub loadSystemUsers {
	@systemUsers = Systemuser::getSystemUsers();

	if ( $verbose ) {
		printf(colored("Found %d system users:\n",'bold white'), scalar(@systemUsers));
		print("\n");
		printf("%s = User has a .ssh directory\n", colored('blubbl','green on_green'));
		printf("%s = User hasn't a .ssh directory\n", colored('blubbl','yellow on_yellow'));
		print("\n");

		foreach my $currentUser ( @systemUsers ) {
			my $color = ( $currentUser->hasSSHDirectory() ) ? 'bold green' : 'yellow';
			my $message = sprintf("User %-20s (UID: %-5d, GID: %-5d) with home in %s\n",
				$currentUser->getUsername(),
				$currentUser->getUserID(),
				$currentUser->getGroupID(),
				$currentUser->getHomeDir()
				);

			print(colored($message, $color));
		}

		print("\n");
	}
}

sub parseKeysFromXML {
	@keys = Key::readKeysFromXML(shift);

	if ( $verbose ) {
		printf(colored("Found %d key(s) in the XML\n",'bold white'), scalar(@keys));

		foreach my $currentKey ( @keys ) {
			$currentKey->toString();
			print("\n");
		}

		print("\n");
	}
}

sub parseGroupsFromXML {
	@groups = Group::readGroupsFromXML(shift);

	if ( $verbose ) {
		printf(colored("Found %d group(s) in the XML\n",'bold white'), scalar(@groups));

		foreach my $currentGroup ( @groups ) {
			$currentGroup->toString();
			print("\n");
		}

		print("\n");
	}
}

sub distributeForThisHost {
	my $hostnode = getNodeForThisHost(shift);

	foreach my $currentUser ( $hostnode->findnodes('./users/user') ) {
		my $user = getSystemuser($currentUser->getAttribute('name'));
		printf(colored("Doing keys for user %s:\n",'bold white'), $user->getUsername()) if ( $verbose );
		my @keysToWrite;

		# Is it even possible?
		die(colored("Not able to distribute keys because the user has no .ssh directory\n", 'red')) if ( ! $user->hasSSHDirectory() );

		# Get the single keys
		foreach my $currentKey ( $currentUser->findnodes('./keys/key') ) {
			push(@keysToWrite, getKeyForAlias($currentKey->textContent()));
		}

		# Get the group keys
		foreach my $currentGroup ( $currentUser->findnodes('./groups/group') ) {
			push(@keysToWrite, getKeysForGroup($currentGroup->textContent()));
		}

		@keysToWrite = Key::getUniqueKeys(@keysToWrite);

		if ( $dry ) {
			printKeysWhichWouldBeWrittenToAuthorizedKeysFile(@keysToWrite);
		}
		else {
			writeKeysToUsersAuthorizedKeysFile($user, @keysToWrite);
		}

		print("\n") if ( $verbose );
	}
}

sub printEndmessage {
	my $message = ( $dry ) ? 'Keys would be distributed as honest as possible' : 'Keys as honest as possible distributed!';

	my $scores = getScoresAsLongAsString($message);

	print("\n");
	print(colored($scores,'green')."\n");
	print(colored($message,'green')."\n");
	print(colored($scores,'green')."\n");
	print("\n");
}

sub getSystemuser {
	my $name = shift;

	foreach my $currentUser ( @systemUsers ) {
		return $currentUser if ( $currentUser->getUsername() eq $name );
	}

	dieInRedColor(sprintf("No user with the name %s exists on this system\n", $name));
}

sub printKeysWhichWouldBeWrittenToAuthorizedKeysFile {
	my ( @keys ) = @_;

	if ( scalar(@keys) == 1 ) {
		printf("Would write key %s to users authorized_keys file\n",$keys[0]->getAlias());
	}
	else {
		print("Would write the following keys to users authorized_keys file:\n");
		foreach my $currentKey ( @keys ) {
			printf("- %s\n", $currentKey->getAlias());
		}
	}
}

sub writeKeysToUsersAuthorizedKeysFile {
	my ( $user, @keys ) = @_;

	open(DATA, sprintf(">%s/.ssh/authorized_keys", $user->getHomeDir()));
	foreach my $currentKey ( @keys ) {
		print DATA $currentKey->getKey()."\n";
		printf("Wrote key %s to users %s authorized_keys file\n",
			$currentKey->getAlias(),
			$user->getUsername()
			) if ( $verbose );
	}
	close(DATA);
}

sub getKeyForAlias {
	my $keyAlias = shift;

	foreach my $currentKey ( @keys ) {
		return $currentKey if ( $currentKey->getAlias() eq $keyAlias );
	}

	dieInRedColor("Was not able to find a key for alias $keyAlias\n");
}

sub getKeysForGroup {
	my $groupAlias = shift;
	my @keys;

	foreach my $currentGroup ( @groups ) {
		if ( $currentGroup->getAlias() eq $groupAlias ) {
			foreach my $currentKeyAlias ( @{$currentGroup->getKeys()} ) {
				push(@keys, getKeyForAlias($currentKeyAlias));
			}
			last;
		}
	}

	return @keys;
}

sub getNodeForThisHost {
	my $document = shift;

	foreach my $currentHost ( $document->findnodes('/sshmanager/hosts/host') ) {
		return $currentHost if ( $currentHost->getAttribute('name') eq $hostname );
	}

	dieInRedColor("No node for this host found :-(\n");
}

sub retrieveXML {
	if ( $endpoint eq 'local' ) {
		return readLocalXMLFile();
	}
	elsif ( $endpoint eq 'http' ) {
		return readXMLViaHTTP();
	}
	else {
		dieInRedColor("Endpoint $endpoint can't be handled.\n");
	}
}

sub readLocalXMLFile {
	my $file = "";

	open(FILE, "<$location");
	while ( <FILE> ) {
		$file .= $_;
	}
	close(FILE);

	return $file;
}

sub readXMLViaHTTP {
	my $userAgent = new LWP::UserAgent();
	$userAgent->agent("sshmanager distribution script v$version");

	my $response = $userAgent->get($location);
	dieInRedColor("Was not able to fetch the XML via HTTP under '$location'.\n") if ( ! $response->is_success );
	$response = $response->decoded_content;

	return $response;
}