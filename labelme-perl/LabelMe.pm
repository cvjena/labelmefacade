#!/usr/bin/perl -w

package LabelMe;
require Exporter;
@ISA = 'Exporter';
@EXPORT = qw(readAnnotations readAnnotationFile);

use strict;
use warnings;

use XML::SimpleObject;

####### readAnnotationFile () // code date : 29.04.08 ######
sub readAnnotationFile
{
    my $parser = XML::Parser->new(ErrorContext => 2, Style => "Tree");

    my $filename = shift;
    chomp $filename;
    my $db = shift;
    
    my $xso = XML::SimpleObject->new( $parser->parsefile($filename) );
    my @objects;

    for my $object ( $xso->child('annotation')->children('object') )
    {
	if ( ref($object) ne "XML::SimpleObject" )
	{
	    next;
	}

	my $name = $object->child('name')->{_VALUE};

	if ( !defined($name) ) {
	    next;
	}

	$name =~ s/^\n//g;
	$name =~ s/\n$//g;

	my @points;
	if ( defined ($object->child('polygon')) ) {
	    my @pts = $object->child('polygon')->children('pt');

	    for my $p ( @pts )
	    {
		my $x = $p->child('x')->{_VALUE};
		my $y = $p->child('y')->{_VALUE};
	    
		$x =~ s/^\n//g;
		$x =~ s/\n$//g;
		$y =~ s/^\n//g;
		$y =~ s/\n$//g;

		push @points, [$x, $y];
	    }
	} elsif ( defined ($object->child('bndbox') ) ) {
	    my $bb = $object->child('bndbox');
	    my $xmin = $bb->child('xmin')->{_VALUE};
	    my $ymin = $bb->child('ymin')->{_VALUE};
	    my $xmax = $bb->child('xmax')->{_VALUE};
	    my $ymax = $bb->child('ymax')->{_VALUE};

	    push @points, [$xmin, $ymin];
	    push @points, [$xmax, $ymin];
	    push @points, [$xmax, $ymax];
	    push @points, [$xmin, $ymax];
	} else {
	    die ("No sufficient annotation information found !\n");
	}

	$name =~ s/\s+/\+/g;

	my $info;
	
	$info->{'name'} = $name;
	$info->{'polygon'} = \@points;
	
	push @objects, $info;
    }

    my $finalinfo;
    $finalinfo->{'imagefile'} = $xso->child('annotation')->child('filename')->{_VALUE};
    $finalinfo->{'folder'} = $xso->child('annotation')->child('folder')->{_VALUE};
    $finalinfo->{'objects'} = \@objects;

    $db->{$filename} = $finalinfo;

    return $db;
}

####### readAnnotations () // code date : 10.11.09 ######
sub readAnnotations
{
    my $rootdir = shift @_;
    my $db = shift @_;

    open ( FILES, "find $rootdir -type f |" ) or die ("find; $!\n");

    my @files = <FILES>;

    close ( FILES );

    my $parser = new XML::Parser (ErrorContext => 2, Style => "Tree");
    my $i = 0;
    my $numdots = 20;
    my $k = 0;

    $|=1; # autoflush
    print "parsing annotations [";
    for (@files)
    {
	chomp;

	if ( exists $db->{$_} )
	{
	    next;
	}

	my $percent = $i / @files;
	if ( $percent*$numdots > $k )
	{
	    print ".";
	    $k++;
	}
	$i++;

	#print "reading annotations from $_\n";
	$db = readAnnotationFile ( $_, $db );

    }
    print "]\n";

    return $db;
}


####### objectInside () // code date : 10.11.09 ######
sub objectInside
{
    my $objects = shift @_;
    my $regex = shift @_;
    for my $object ( @{$objects} )
    {
	if ( $object->{'name'} =~ /$regex/ )
	{
	    return 1;
	}
    } 
    return 0;
}

1;
