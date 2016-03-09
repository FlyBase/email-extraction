#!/usr/bin/perl -w

use strict;
use Getopt::Long;

=head1 NAME

extract-emails-from-pdf.pl

=head1 SYNOPSIS

perl extract-emails-from-pdf.pl <input> [options]

Options:

--excludeList --> File with a list of email addresses to be excluded from the extraction

--noEmailLog --> File where to write the list of PDFs from which the script didn't manage to extract any email address

See L<Options> for full details.

e.g.

# no option:

	perl extract-emails-from-pdf.pl input.pdf > output-file.txt

# --excludeList option only:

	perl extract-emails-from-pdf.pl input.pdf --excludeList exclusion-list-file.txt > output-file.txt

# --noEmailLog option only:

	perl extract-emails-from-pdf.pl input.pdf --noEmailLog no-email-extracted-file.txt > output-file.txt

# all options:

	perl extract-emails-from-pdf.pl input.pdf --excludeList exclusion-list-file.txt --noEmailLog no-email-extracted-file.txt > output-file.txt

# In case you want to run the script on all the PDFs in a folder, from the PDF directory try for example:

	find -f . '*pdf' | cut -f 2 -d '/' | while read pdf; do perl extract-emails-from-pdf.pl $pdf --excludeList exclusion-list-file.txt --noEmailLog no-email-extracted-file.txt; done > output-file.txt


=head1 DESCRIPTION

This script extracts email addresses from PDF files. It takes as argument a PDF file to extract the email-address(es) from and then makes a system call to the program "pdftotext"
from the poppler-utils package, which is licensed under the GPL. You will need to install this package on your machine and make the pdftotext program available in your PATH.
You can either get the package from the associated website (https://poppler.freedesktop.org/), or using a package management system like MacPorts, Fink or Brew.

=head2 Options

=over 5

=item --excludeList <file>

List of email addresses that you want to be excluded from the extraction (e.g. email addresses of scientific journals)

=item --noEmailLog <file>

File in which the script will write (append) the name of the input PDF in case it didn't manage to extract any email address

=back

=head2 File formats

=over 5

=item --excludeList format

1 column-file with the list of email addresses to exclude

=item --noEmailLog format

Either an empty text file (the first time you run the script), or a previous noEmailLog file. The script will append the PDF file names to this file

=item Output format

The output format is tab delimited, with in the first column the name of the PDF file from which you performed the extraction and in the second column the email address(es) associated (one email address per line)

=back

=head1 AUTHOR

=over 5

=item Giulia Antonazzo, FlyBase

=back

=head1 LICENSE

Copyright (C) 2016 FlyBase

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
=cut

my $excludeList;
my $noEmailFile;	#if given, will print PDF file name to this file if the PDF does not contain any emails

GetOptions("excludeList=s" => \$excludeList, "noEmailLog=s" => \$noEmailFile);

#run pdftotxt directly on a PDF file and process without making a text file first
my $file = $ARGV[0];	#pdf file
my @content = `pdftotext $file -`;	#execute a system command with the pdftotext program, writing to standard output, and capturing the output into a perl array

#if there is an exclude list given, read the data from the file
my @excludeList;
if (defined($excludeList)) {
	open(EXCLUDELIST, $excludeList) || die "Did not find exclude list file $excludeList. Aborting.\n";
	@excludeList = <EXCLUDELIST>;	#slurp the contents of the file into the array
	close(EXCLUDELIST);
	
	#chomp all the emails
	chomp(@excludeList);	
} 

#join all lines into a single string
my $content = join("",@content);

#look for e-mails
my $foundEmail = 0;		#a variable to record if we have found any emails or not
EMAIL: while ($content =~ m/([\-\.a-zA-Z0-9_]+\@[\-\.a-zA-Z0-9_\n]+\.[a-zA-Z]{2,3})/gsi) {
	my $email = $1;
	
	#get rid of any newlines breaking up the e-mail
	$email =~ s/\n//gs;
	
	#check if the email is in the exclude list - if so, skip it
	foreach my $exclude (@excludeList) {
		if ($email eq $exclude) {
			next EMAIL;
		}
	}
	
	print $file."\t".$email,"\n";
	$foundEmail = 1;	#we have found and printed an email, so switch this variable to 1
}

#test if any emails were found or not
if ($noEmailFile && $foundEmail == 0) {
	#no e-mails were found - print the file name to a log file
	open(NOEMAIL, ">>$noEmailFile") || die "Could not write to no-email log file $noEmailFile\n";
	print NOEMAIL "$file\n";
	print STDERR "Printed file name of PDF with no e-mails found ($file) to $noEmailFile.\n";
	close(NOEMAIL);
}

exit;