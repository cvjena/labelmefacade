#!/usr/bin/perl -w

use FindBin;
use lib $FindBin::Bin;

use LabelMe;

use Tie::Persistent;
# use MLDBM qw(DB_File Storable );

use strict;

my $root = shift @ARGV;

if ( !defined($root) )
{
    die ("usage: $0 <root-dir-annotations>\n");
}

my %db;

my $dbfile = 'labelme';
tie %db, 'Tie::Persistent', $dbfile, 'rw';
# alternative: tie %ata, 'MLDBM', 'labelme', O_CREAT|O_RDWT, 0644 or die "Trouble opening $dbfile: $!\n";

printf ("Images in database $dbfile: %d\n", scalar keys %db);

#use autosync: (tied %db)->autosync(1);  
LabelMe::readAnnotations ( $root, \%db );

printf ("Images in database $dbfile: %d\n", scalar keys %db);

(tied %db)->sync();
untie %db;

