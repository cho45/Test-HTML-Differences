package Test::HTML::Differences;

use strict;
use warnings;
use parent qw(Exporter);
use Test::Differences;
use HTML::Parser;
use HTML::Entities;

our $VERSION = '0.01';

our @EXPORT = qw(
	eq_or_diff_html
);

sub eq_or_diff_html ($$;$) {
	my ($got, $expected, $desc) = @_;
	eq_or_diff(normalize_html($got), normalize_html($expected), $desc);
}

sub normalize_html {
	my ($s) = @_;

	my $root  = [ root => {} => [] ];
	my $stack = [ $root ];
	my $p = HTML::Parser->new(
		api_version => 3,
		handlers => {
			start => [
				sub {
					my ($tagname, $attr) = @_;
					my $e = [
						$tagname => $attr => []
					];
					push @{ $stack->[-1]->[2] }, $e;
					push @$stack, $e;
				},
				"tagname, attr"
			],
			end => [
				sub {
					pop @$stack;
				},
				"tagname",
			],
			comment => [
				sub {
					my ($text) = @_;
					push @{ $stack->[-1]->[2] }, $text;
				},
				"text"
			],
			text  => [
				sub {
					my ($dtext) = @_;
					$dtext =~ s/^\s+|\s+$//g;
					push @{ $stack->[-1]->[2] }, $dtext if $dtext =~ /\S/;
				},
				"dtext"
			]
		}
	);
	$p->unbroken_text(1);
	$p->empty_element_tags(1);
	$p->parse($s);
	$p->eof;

	my $ret = [];
	my $walker; $walker = sub {
		my ($parent, $level) = @_;
		my ($tag, $attr, $children) = @$parent;

		my $a = join ' ', map { sprintf('%s="%s"', $_, encode_entities($attr->{$_})) } sort { $a cmp $b } keys %$attr;
		my $has_element = grep { ref($_) } @$children;
		if ($has_element) {
			push @$ret, sprintf('%s<%s%s>', "  " x $level, $tag, $a ? " $a" : "") unless $tag eq 'root';
			for my $node (@$children) {
				if (ref($node)) {
					$walker->($node, $level + 1);
				} else {
					push @$ret, sprintf('%s%s', "  " x ($level + 1), $node);
				}
			}
			push @$ret, sprintf('%s</%s>', "  " x $level, $tag) unless $tag eq 'root';
		} else {
			push @$ret, sprintf('%s<%s%s>%s</%s>', "  " x $level, $tag, $a ? " $a" : "", join(' ', @$children), $tag) unless $tag eq 'root';
		}
	};
	$walker->($root, -1);

	$ret;
}


1;
__END__

=head1 NAME

Test::HTML::Differences - Compare two htmls and show differences if not ok

=head1 SYNOPSIS

  use Test::Base -Base;
  use Test::HTML::Differences;

  plan tests => 1 * blocks;
  
  run {
      my ($block) = @_;
      eq_or_diff_html(
          $block->input,
          $block->expected,
          $block->name
      );
  };

  __END__
  === test
  --- input
  <div class="section">foo <a href="/">foo</a></div>
  --- expected
  <div class="section">
    foo <a href="/">foo</a>
  </div>


=head1 DESCRIPTION

Test::HTML::Differences is test utility that compares two strings as HTMLs and show differences with Test::Differences.

Supplied HTML strings are normalized and show pretty formatted as it is shown.

=head1 AUTHOR

cho45 E<lt>cho45@lowreal.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
