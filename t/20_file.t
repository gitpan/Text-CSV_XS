#!/usr/bin/perl

use strict;
$^W = 1;	# use warnings;
$|  = 1;

use Test::More tests => 61;

BEGIN {
    use_ok "Text::CSV_XS";
    plan skip_all => "Cannot load Text::CSV_XS" if $@;
    }

use IO::Handle;

my $csv = Text::CSV_XS->new ();

ok (!$csv->print (*FH, ["abc", "def\007", "ghi"]), "print bad character");

for ( [  1, 1, 1, '""'				],
      [  2, 1, 1, '', ''			],
      [  3, 1, 0, '', 'I said, "Hi!"', ''	],
      [  4, 1, 0, '"', 'abc'			],
      [  5, 1, 0, 'abc', '"'			],
      [  6, 1, 1, 'abc', 'def', 'ghi'		],
      [  7, 1, 1, "abc\tdef", 'ghi'		],
      [  8, 1, 0, '"abc'			],
      [  9, 1, 0, 'ab"c'			],
      [ 10, 1, 0, '"ab"c"'			],
      [ 11, 0, 0, qq("abc\nc")			],
      [ 12, 1, 1, q(","), ','			],
      [ 13, 1, 0, qq("","I said,\t""Hi!""",""), '', qq(I said,\t"Hi!"), '' ],
      ) {
    my ($tst, $validp, $validg, @arg, $row) = @$_;

    open  FH, ">_test.csv" or die "_test.csv: $!";
    is ($csv->print (*FH, \@arg), $validp||"", "$tst - print ()");
    close FH;

    open  FH, ">_test.csv" or die "_test.csv: $!";
    print FH join ",", @arg;
    close FH;

    open  FH, "<_test.csv" or die "_test.csv: $!";
    $row = $csv->getline (*FH);
    unless ($validg) {
	is ($row, undef, "$tst - false getline ()");
	next;
	}
    ok ($row, "$tst - good getline ()");
    $tst == 12 and @arg = (",", "", "");
    foreach my $a (0 .. $#arg) {
	(my $exp = $arg[$a]) =~ s/^"(.*)"$/$1/;
	is ($row->[$a], $exp, "$tst - field $a");
	}
    }

unlink "_test.csv";

# This test because of a problem with DBD::CSV

ok (1, "Tests for DBD::CSV");
open  FH, ">_test.csv" or die "_test.csv: $!";
$csv->binary (1);
$csv->eol    ("\r\n");
ok ($csv->print (*FH, [ "id", "name"			]), "Bad character");
ok ($csv->print (*FH, [   1,  "Alligator Descartes"	]), "Name 1");
ok ($csv->print (*FH, [  "3", "Jochen Wiedmann"		]), "Name 2");
ok ($csv->print (*FH, [   2,  "Tim Bunce"		]), "Name 3");
ok ($csv->print (*FH, [ " 4", "Andreas K�nig"		]), "Name 4");
ok ($csv->print (*FH, [   5				]), "Name 5");
close FH;

my $expected = <<"CONTENTS";
id,name\015
1,"Alligator Descartes"\015
3,"Jochen Wiedmann"\015
2,"Tim Bunce"\015
" 4","Andreas K�nig"\015
5\015
CONTENTS

open  FH, "<_test.csv" or die "_test.csv: $!";
my $content = do { local $/; <FH> };
close FH;
is ($content, $expected, "Content");
open  FH, ">_test.csv" or die "_test.csv: $!";
print FH $content;
close FH;
open  FH, "<_test.csv" or die "_test.csv: $!";

my $fields;
print "# Retrieving data\n";
for (0 .. 5) {
    ok ($fields = $csv->getline (*FH),			"Fetch field $_");
    is ($csv->eof, "",					"EOF");
    print "# Row $_: $fields (@$fields)\n";
    }
is ($csv->getline (*FH), undef,				"Fetch field 6");
is ($csv->eof, 1,					"EOF");
