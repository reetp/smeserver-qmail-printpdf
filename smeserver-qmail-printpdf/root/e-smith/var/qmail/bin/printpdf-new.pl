#!/usr/bin/perl -w

use MIME::Parser;
use MIME::WordDecoder;
use esmith::ConfigDB;
use strict;

my $configDB = esmith::ConfigDB->open_ro or die("can't open Config DB");

my ( $parser, $subject, $from, $entity, $num_parts, $part, $line);

my $status = $configDB->get_prop( 'qmail-printpdf', 'status' ) || 'disabled';

unless $status = 'enabled' {
  die("Qmail Print PDF Status is disabled");
  }

my $Printer = $configDB->get_prop( 'qmail-printpdf', 'PrinterName' ) or die("No printer defined");

my $Media    = $configDB->get_prop( 'qmail-printpdf', 'Media' )    || 'A4,tray1';
my $Password = $configDB->get_prop( 'qmail-printpdf', 'Password' ) || 'NoPasswordSet';
my $TmpDir   = $configDB->get_prop( 'qmail-printpdf', 'TmpDir' )   || '/tmp/printpdf';

# Mime-type to print:
my %type_ok = ( 'application/pdf'          => 1,
                'application/octet-stream' => 1 );
open( LOG, ">>", "/var/log/printpdf.log" );
print LOG "Received new email at " . localtime() . "\n";


# Use default settings if not provided in configuration-file

# $settings{"lp-options"} ||= "-o media=A4,tray1 -o fit-to-page -o position=top -o scaling=100";

$settings = "lp-options = -d $Printer -o media=$Media -o fit-to-page -o position=top -o scaling=100";

unless ( -e $TmpDir ) {
    print LOG "Creating new TmpDir: $TmpDir\n";
    system("mkdir -p $TmpDir");
}

# Create parser
$parser = MIME::Parser->new();
$parser->output_dir($TmpDir);

# Parse input
$entity = $parser->parse( \*STDIN ) or die "Parse failed\n";
$num_parts = $entity->parts;

# Handle mime parts
if ( $num_parts > 0 ) {
    $from    = unmime $entity ->head->get('from');
    $subject = unmime $entity ->head->get('subject');
    print LOG "Message from:\n$from\nSubject:\n$subject\n$num_parts mime parts\n";

    # Password ok?
    if ( exists( $Password ) && index( $subject, $Password ) < 0 ) {
        print LOG "Password not found in subject-field\n";
    }
    else {
        for ( my $i = 0 ; $i < $num_parts ; $i++ ) {
            $part = $entity->parts($i);
            if ( exists( $type_ok{ lc $part->mime_type } ) ) {
                my $bh = $part->bodyhandle;
                print LOG "Printing ", $bh->path, " ...\n";
                system( "lp " . $settings . ' "' . $bh->path . '"' . );
            }
        }
    }
}
$parser->filer->purge;
print LOG "Done!\n";
