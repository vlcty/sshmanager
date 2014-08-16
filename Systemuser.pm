package Systemuser;
use strict;

sub new {
	my $class = shift;
	my $self = {
		username => '',
		userID => 0,
		groupID => 0,
		comment => '',
		homeDir => '',
		shell => ''
	};

	bless $self,$class;
	return $self;
}

sub toString {
	my ( $self ) = @_;

	printf("-- Systemuser: %s\n", $self->getUsername());
	printf("UserID: %d\n", $self->getUserID());
	printf("GroupID: %d\n", $self->getGroupID());
	printf("Comment: %s\n", $self->getComment());
	printf("Home: %s\n", $self->getHomeDir());
	printf("Shell: %s\n", $self->getShell());
}

sub hasSSHDirectory {
	my ( $self ) = @_;

	return 1 if ( -d  $self->getHomeDir() . "/.ssh" );
	return 0;
}

sub createSSHDirectory {
	my ( $self ) = @_;

	return 0 if ( ! $self->hasSSHDirectory() );

	system(sprintf("mkdir %s/.ssh", $self->getHomeDir()));
	system(sprintf("chown 600 %s/.ssh", $self->getHomeDir()));

	return 1;
}

sub getSystemUsers {
	my @users;

	open(DATA, "</etc/passwd");
	while ( <DATA> ) {
		# Prepare the line
		my $line = $_;
		chomp($line);

		# Split and sanitize it
		my @parts = split(/:/, $line);
		next if ( scalar(@parts) != 7 );
		$parts[4] =~ s/,//ig;

		# Build the user
		my $user = new Systemuser();
		$user->setUsername($parts[0]);
		$user->setUserID($parts[2]);
		$user->setGroupID($parts[3]);
		$user->setComment($parts[4]);
		$user->setHomeDir($parts[5]);
		$user->setShell($parts[6]);

		push(@users, $user);
	}
	close(DATA);

	return @users;
}

sub setUsername {
	my ( $self, $value ) = @_;
	$self->{username} = $value;
}

sub getUsername {
	my ( $self ) = @_;
	return $self->{username};
}

sub setUserID {
	my ( $self, $value ) = @_;
	$self->{userID} = $value;
}

sub getUserID {
	my ( $self ) = @_;
	return $self->{userID};
}

sub setGroupID {
	my ( $self, $value ) = @_;
	$self->{groupID} = $value;
}

sub getGroupID {
	my ( $self ) = @_;
	return $self->{groupID};
}

sub setComment {
	my ( $self, $value ) = @_;
	$self->{comment} = $value;
}

sub getComment {
	my ( $self ) = @_;
	return $self->{comment};
}

sub setHomeDir {
	my ( $self, $value ) = @_;
	$self->{homeDir} = $value;
}

sub getHomeDir {
	my ( $self ) = @_;
	return $self->{homeDir};
}

sub setShell {
	my ( $self, $value ) = @_;
	$self->{shell} = $value;
}

sub getShell {
	my ( $self ) = @_;
	return $self->{shell};
}

1;