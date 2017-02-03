#!/usr/bin/perl -w
use MIME::Parser;
use MIME::WordDecoder;
use strict;

my ($parser, $password, $subject, $from, $entity, $num_parts, $part, $line, %settings, $tmpdir);
# Mime-type to print:
my %type_ok = (
  'application/pdf' => 1,
  'application/octet-stream' => 1
  );
open (LOG, ">>", "/var/log/printpdf.log");
print LOG "Received new email at ".localtime()."\n";

# Get settings from configuration-file
my $config_file = "/etc/printpdf.conf";

if (-e $config_file) {
  open (CONF, "<", $config_file);
  while ($line = <CONF>) {
    chomp $line;
    $line =~ s/#.*//;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    next unless (length($line));
    my ($var, $value) = split (/\s*=\s*/, $line, 2);
    $settings{$var} = $value;
  }
}

# Use default settings if not provided in configuration-file
$settings{"tmpdir"} ||= "/tmp/printpdf";
$tmpdir = $settings{"tmpdir"};
$settings{"lp-options"} ||= "-o media=A4,tray1 -o fit-to-page -o position=top -o scaling=100";

unless (-e $tmpdir) {
  print LOG "Creating new tmpdir: $tmpdir\n";
  system("mkdir -p $tmpdir")
}

# Create parser
$parser = MIME::Parser->new();
$parser -> output_dir($tmpdir);

# Parse input
$entity = $parser -> parse(\*STDIN) or die "Parse failed\n";
$num_parts = $entity -> parts;

# Handle mime parts
if ($num_parts > 0) {
  $from    = unmime $entity -> head -> get('from');
  $subject = unmime $entity -> head -> get('subject');
  print LOG "Message from:\n$from\nSubject:\n$subject\n$num_parts mime parts\n";

# Password ok?
  if (exists($settings{"password"}) && index($subject, $settings{"password"}) < 0) {
    print LOG "Password not found in subject-field\n"
  } else {
    for (my $i = 0; $i < $num_parts; $i++) {
      $part = $entity -> parts($i);
      if (exists ($type_ok{lc $part -> mime_type})) {
        my $bh = $part -> bodyhandle;
        print LOG "Printing ", $bh -> path, " ...\n";
        system("lp " . $settings{"lp-options"} . ' "' . $bh->path . '"'.);
      }
    }
  }
}
$parser->filer->purge;
print LOG "Done!\n";