use strict;
use warnings;

use Test::More;
eval "use Test::Compile";
plan skip_all => "Test::Compile required for testing compilation"  if $@;

 
#my @scripts = qw(list_all_submodules nuggit_add nuggit_branch nuggit_checkout_default nuggit_clone nuggit_commit nuggit_diff nuggit_fetch nuggit_merge nuggit_pull nuggit_push nuggit_rev_list nuggit_status);

my $test = Test::Compile->new();
$test->all_files_ok();
#$test->pl_file_compiles($_) for @scripts;
$test->done_testing();
