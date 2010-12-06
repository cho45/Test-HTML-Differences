use strict;
use warnings;
use Test::Base -Base;
use Test::Differences;
use Test::HTML::Differences;

plan tests => 1 * blocks;

sub test_test (&) { # from Test::Test::More written by id:wakabatan
	my $code = shift;
	
	open my $file1, '>', \(my $s = '');
	open my $file2, '>', \(my $t = '');
	open my $file3, '>', \(my $u = '');
	
	{
		my $builder = Test::Builder->create;
		$builder->output($file1);
		$builder->failure_output($file2);
		$builder->todo_output($file3);
		no warnings 'redefine';
		local *Test::More::builder = sub { $builder };

		# For Test::Class
		my $diag = \&Test::Builder::diag;
		local *Test::Builder::diag = sub {
			shift;
			$diag->($builder, @_);
		};

		# For Test::Differences
		local *Test::Builder::new = sub { $builder };
		
		$code->();
	}
	
	close $file1;
	close $file2;
	close $file3;

	return {output => $s, failure_output => $t, todo_output => $u};
}

run {
	my ($block) = @_;
	my $obj = test_test {
		eq_or_diff_html(
			$block->test_input,
			$block->test_expected
		);
	};

	for my $key (keys %$obj) {
		$obj->{$key} =~ s{^\s+|\s+$}{}g;
	}

	my $test_result = $block->test_result;
	$test_result =~ s{^\s+|\s+$}{}g;

	eq_or_diff $obj->{failure_output}, $test_result;
};

__DATA__
=== test
--- test_input
<div class="section">
foo <a href="/">foo</a>
</div>
--- test_expected
<foo>
<div class="section">
  foo
  <a href="/">foo</a>
</div>
</foo>
--- test_result
#   Failed test at t/03_output.t line 47.
# +----+-----------------------+----+-------------------------+
# | Elt|Got                    | Elt|Expected                 |
# +----+-----------------------+----+-------------------------+
# |    |                       *   0|<foo>                    *
# |   0|<div class="section">  |   1|  <div class="section">  |
# |   1|  foo                  |   2|    foo                  |
# |   2|  <a href="/">foo</a>  |   3|    <a href="/">foo</a>  |
# |   3|</div>                 |   4|  </div>                 |
# |    |                       *   5|</foo>                   *
# +----+-----------------------+----+-------------------------+

