package Key;
use strict;
use SSHManager qw(trim);

sub new {
	my $class = shift;
	my $self = {
		alias => '',
		key => ''
	};

	bless $self,$class;
	return $self;
}

sub readKeysFromXML {
	my $document = shift;
	my @keys;

	foreach my $currentKey ( $document->findnodes('/sshmanager/keys/key') ) {
		my $key = new Key();
		$key->setAlias(trim($currentKey->getAttribute('alias')));
		$key->setKey(trim($currentKey->textContent()));

		push(@keys, $key);
	}

	return @keys;
}

sub getUniqueKeys {
	my ( @unsortedKeys ) = @_;
	my @sortedKeys;

	foreach my $currentKey ( @unsortedKeys ) {
		my $found = 0;

		# Search for the key
		foreach my $currentSortedKey ( @sortedKeys ) {
			$found = 1 and last if ( $currentSortedKey->getAlias() eq $currentKey->getAlias() );
		}

		push(@sortedKeys, $currentKey) if ( ! $found );
	}

	return @sortedKeys;
}

sub toString {
	my ( $self ) = @_;

	printf("-- Key %s:\n", $self->getAlias());
	printf("%s\n", $self->getKey());
}

sub setAlias {
	my ( $self, $value ) = @_;
	$value = trim($value);
	$self->{alias} = $value;
}

sub getAlias {
	my ( $self ) = @_;
	return $self->{alias};
}

sub setKey {
	my ( $self, $value ) = @_;
	$value = trim($value);
	$self->{key} = $value;
}

sub getKey {
	my ( $self ) = @_;
	return $self->{key};
}

1;