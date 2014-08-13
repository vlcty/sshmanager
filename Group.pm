package Group;
use strict;
use SSHManager qw(trim);

sub new {
	my $class = shift;
	my @keys;
	my $keyss = \@keys;
	my $self = {
		alias => '',
		keys => $keyss
	};

	bless $self,$class;
	return $self;
}

sub readGroupsFromXML {
	my $document = shift;
	my @groups;

	foreach my $currentGroup ( $document->findnodes('/sshmanager/groups/group') ) {
		my $group = new Group();
		$group->setAlias($currentGroup->getAttribute('alias'));

		# Look for the keys
		foreach my $currentKey ( $currentGroup->findnodes('./keys/key') ) {
			push($group->getKeys(), $currentKey->textContent());
		}

		push(@groups, $group);
	}

	return @groups;
}

sub toString {
	my ( $self ) = @_;

	printf("-- Group %s:\n", $self->getAlias());

	my $counter = 0;
	foreach my $currentKey ( @{$self->getKeys()} ) {
		$counter++;
		printf("Key #%d: %s\n", $counter, $currentKey);
	}
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

sub setKeys {
	my ( $self, $value ) = @_;
	$self->{keys} = $value;
}

sub getKeys {
	my ( $self ) = @_;
	return $self->{keys};
}

1;