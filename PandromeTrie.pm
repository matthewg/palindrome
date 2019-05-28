# This is a subclass of Tree::Trie from CPAN (which I didn't write.)
#
# However, for my purposes, it's extremely useful to be able to ask the
# question "what is the deepest leaf node in the trie s.t. the path is a
# prefix of 'foo'".  For instance, if we insert "ogre" at the head of the
# palindrome, we either need something that has "ergo" as a suffix, or we need
# any of the extract strings "erg", "er", or "e".  So we'd first do a lookup
# for "ergo" or any of its children, but if that fails, we want to ask
# "give me every leaf node on the path 'erg', sorted by depth."  Tries can
# do this in O(1) time, but not with Tree::Trie's API.
#
# This trie will return these leaf-node sub-prefixes from a lookup.
#
# The trietest script tests this module.
#
package PandromeTrie;
use strict;
use warnings;
use Carp;
use Tree::Trie;
our @ISA = qw(Tree::Trie);

sub _pandrome_lookup {
	my($self, %data) = @_;
	my $word = $data{word};
	my $deepsearch = $self->deepsearch();

	my $do_lookup = sub {
		my($word, $suff_len) = @_;
		$data{data} ?
			$self->lookup_data($word, 1) :
			$self->lookup($word, $suff_len, 1);
	};
	my $get_submatches = sub {
		$word =~ s/.$//;
		my @subret;
		$self->deepsearch("choose");
		while($word) {
			my $w = scalar($do_lookup->($word));
			push @subret, $w if $w and $w eq $word;
			$word =~ s/.$//;
		}
		$self->deepsearch($deepsearch);
		return @subret;
	};

	if($data{want_arr}) {
		my @ret = $do_lookup->($word, $data{suff_len});
		push @ret, $get_submatches->();
		return @ret;
	} else {
		my $ret = $do_lookup->($word, $data{suff_len});
		return $ret if $ret and $deepsearch ne "count";
		my @subret = $get_submatches->();
		if($deepsearch eq "boolean") {
			return @subret ? 1 : 0;
		} elsif($deepsearch eq "choose" or $deepsearch eq "1") {
			return $subret[0];
		} elsif($deepsearch eq "count") {
			return @subret + $ret;
		} elsif($deepsearch eq "prefix") {
			return $subret[0];
		} else {
			croak "Invalid value '$deepsearch' for deepsearch!";
		}
	}
}

sub lookup_data {
	my($self, $word, $in_pl) = @_;
	if(!$in_pl) {
		$self->_pandrome_lookup(
			word => $word,
			want_arr => wantarray(),
			data => 1
		);
	} else {
		$self->SUPER::lookup_data($word);
	}
}
sub lookup {
	my($self, $word, $suff_len, $in_pl) = @_;
	if(!$in_pl) {
		$self->_pandrome_lookup(
			word => $word,
			want_arr => wantarray(),
			suff_len => $suff_len,
			data => 0
		);
	} else {
		$self->SUPER::lookup($word, $suff_len);
	}
}

1;
