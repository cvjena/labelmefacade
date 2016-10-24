#!/usr/bin/perl -w

use FindBin;
use lib $FindBin::Bin;

#[colors]
#various = 0:0:0
#building = 128:0:0
#car = 128:0:128
#door = 128:128:0
#pavement = 128:128:128
#road = 128:64:0
#sky = 0:128:128
#vegetation = 0:128:0
#window = 0:0:128


my @essential_objects = qw(building window sky);
my @draw_categories = qw(unknown sky building house window door pavement sidewalk sideway road street vegetation tree car);
my $colors_ref = {
    'unknown' => '0,0,0',

    'building' => '128,0,0',
    'house' => '128,0,0',

    'car' => '128,0,128',
    'door' => '128,128,0',

    'pavement' => '128,128,128',
    'sidewalk' => '128,128,128',
    'sideway' => '128,128,128',

    'road' => '128,64,0',
    'street' => '128,64,0', # = road

    'sky' => '0,128,128',

    'vegetation' => '0,128,0',
    'tree' => '0,128,0', # = vegetation

    'window' => '0,0,128'
};
my %colors = %{ $colors_ref };
my $maximum_unlabeled_area = 0.2;

########################################################

use LabelMe;
use Tie::Persistent;
use Image::Magick;
# use MLDBM qw(DB_File Storable );

use strict;


####### round () // code date : 11.11.09 ######
sub round
{
    my $x = shift @_;
    return ( int($x + 0.5) );
}

####### getBase () // code date : 11.11.09 ######
sub getBase
{
    my ($file1, $file2) = @_;

    my $i = 0;
    while ( (substr($file1,$i,1) eq substr($file2,$i,1)) && ($i < length($file1)) &&
	    ($i < length($file2) ) )
    { $i++ };

    my ( $dir, $base ) = ( "", "" );
    if ( $i != 0 ) {
	$dir = substr($file1, 0, $i);
    }

    if ( $i != length($file1) ) {
	$base = substr($file1, $i, length($file1) - $i );
    }

    return ( $dir, $base );

}

####### createLabeledImage () // code date : 11.11.09 ######
sub createLabeledImage
{
    my ( $db, $image, $imagedir, $draw_categories, $colors ) = @_;

    my @objects = @{ $db->{$image}->{'objects'} };

    print "image: $image\n";

    my $imagefile = $db->{$image}->{'imagefile'};
    my $folder =  $db->{$image}->{'folder'};
    $imagefile =~ s/[[:cntrl:]]+//g;
    $folder =~ s/[[:cntrl:]]+//g;;
    my $imagefn = $imagedir . "/" . $folder . "/" . $imagefile;
    print "$imagefn\n";

    if ( ! -f $imagefn ) {
	warn ("createLabeledImage: unable to find source image file !\n");
	return;
    }


    my $imageO = Image::Magick->new();
    my ($owidth, $oheight, $osize, $oformat) = $imageO->Ping($imagefn);
    my ($width, $height, $scale);

    if ( $owidth > $oheight ) { # landscape
	$height = 512;
	$width = round($owidth*$height/$oheight);
	$scale = $height/$oheight;
    } else {
	$width = 512;
	$height = round($oheight*$width/$owidth);
	$scale = $width/$owidth;
    }

    my $imageS = Image::Magick->new(size=>$width."x".$height);
    $imageS -> ReadImage("xc:black");

    #my $imageS = Image::Magick->new();
    #$imageS -> ReadImage($imagefn);
    # clear image
    #my ( $width, $height ) = $imageS -> Get("width", "height");
    #$imageS -> Draw ( fill => 'black', primitive => 'rectangle', points => "0,0 $width,$height" );

    print "size: $width x $height ( $owidth x $oheight )\n";

    for my $draw_category ( @{$draw_categories} )
    {
	for my $object ( @objects )
	{
	    if ( $object->{'name'} =~ /$draw_category/ ) {
		my @points = @{ $object->{'polygon'} };
		my $polygontext = "";
		for my $point ( @points )
		{
		    my ( $x, $y ) = ( round($point->[0]*$scale), round($point->[1]*$scale) );
		    if ( length($polygontext) > 0 )
		    {
			$polygontext .= " ";
		    }
		    $polygontext .= "$x,$y";
		}

		$imageS->Draw ( fill => 'rgb(' . $colors->{$draw_category} . ')', primitive => 'polygon', 
		    points=>$polygontext, antialias=>'false' );
	    }
	}
    }

    # count unlabeled region
    my @histogram = $imageS->Histogram();
    print scalar(@histogram)."\n";
    my %hist;

    while (@histogram)
    {
        my ($red, $green, $blue, $opacity, $count) = splice(@histogram, 0, 5);
	# BE CAREFUL ! 
	$red = $red % 256;
	$green = $green % 256;
	$blue = $blue % 256;

	for my $category ( @{$draw_categories} ) {
	    my ( $r, $g, $b ) = split /,/, $colors->{$category};
	    if ( ($red == $r) && ($green == $g) && ($blue == $b) ) {
		$hist{$category} = $count / ($width*$height); 
		print "$category: $hist{$category}\n";
		last;
	    }
	}
    }

################################## SPECIFIC criteria
    if ( (! exists $hist{'unknown'}) || ( $hist{'unknown'} > $maximum_unlabeled_area ) )
    {
	print "image rejected due to a large unlabeled area\n";
	return;
    }

##################################

    my $labeled_tgt = $folder . "__" . $imagefile;
    $labeled_tgt =~ s/\....$/.png/;

    my $orig_tgt = $folder . "__" . $imagefile;

    print "orig: $orig_tgt; labels: $labeled_tgt\n";

    $imageS->Write('filename'=>$labeled_tgt, compression=>'None' );
    
    $imageO->ReadImage ( $imagefn );

    $imageO->Resize(width=>$width, height=>$height);

    $imageO->WriteImage($orig_tgt);

}


my $dbfile = shift @ARGV;
my $annotationdir = shift @ARGV;
my $imagedir = shift @ARGV;

if ( !defined($dbfile) || !defined($imagedir) )
{
    die ("usage: $0 <db-file (Tie::Persistent)> <image-dir>\n");
}

my %db;

print "reading Tie::Persistent structure ...\n";
tie %db, 'Tie::Persistent', $dbfile, 'r';
# alternative: tie %ata, 'MLDBM', 'labelme', O_CREAT|O_RDWT, 0644 or die "Trouble opening $dbfile: $!\n";

printf ("Images in database: %d\n", scalar keys %db);

for my $image ( keys %db )
{
    my $objects = $db{$image}->{'objects'};
    my $match = 1;

    for my $essential_object ( @essential_objects )
    {
	if ( ! LabelMe::objectInside ( $objects, $essential_object ) ) {
	    $match = 0;
	    last;
	}
    }

    if ( ! $match ) {
	next;
    }

    createLabeledImage ( \%db, $image, $imagedir, \@draw_categories, \%colors ); 
}

untie %db;

