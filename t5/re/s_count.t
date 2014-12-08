#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    
}
print "1..2\n";

# See:
# https://github.com/fglock/Perlito/issues/28 .

my $string = "Test 1";

my $count = ($string =~ s/Test/Foo/);

print "not " if ($string ne "Foo 1");
print "ok 1\n";
print "not " if ($count ne 1);
print "ok 2\n";
