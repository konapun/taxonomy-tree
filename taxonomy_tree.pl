#!/usr/bin/perl
#
# Output a newick string for any valid NCBI taxon ID or node name
#
# Example: perl getNCBIsubtree.pl "Homo Sapiens"  # automatically converts "Homo Sapiens to its NCBI node ID"
# Author: Bremen Braun
use strict;
use Bio::DB::Taxonomy;
use Bio::TreeIO;

die "Wrong number of arguments\nUsage: $0 <name_or_NCBI_id>\n" unless scalar(@ARGV) >= 1;
my ($nameOrID, $ancestorLevels) = @ARGV;
$ancestorLevels = 5 unless defined $ancestorLevels;
my $datapath = 'data/taxonomy';
my $db = Bio::DB::Taxonomy->new(
	-source    => 'flatfile',
	-nodesfile => "$datapath/nodes.dmp",
	-namesfile => "$datapath/names.dmp"
);

$nameOrID = $db->get_taxonid($nameOrID) unless $nameOrID =~ /d+/; # find the NCBI ID unless it's given
my $taxonID = $nameOrID;
my $targetNode = $db->get_taxon(-taxonid => $taxonID);
my $ancestorIncr = 0;
while ($ancestorIncr++ < $ancestorLevels && $targetNode->ancestor()) {
	$targetNode = $targetNode->ancestor();
}

print taxonTreeToNwk($db, $targetNode);

sub taxonTreeToNwkRec {
	my ($db, $node) = @_;
	
	my $nwk = "";
	my @children = $db->each_Descendent($node);
	if (scalar(@children) > 0) {
		$nwk .= '(';
		my $isFirst = 1;
		foreach my $child (@children) {
			$nwk .= ',' unless $isFirst;
			$nwk .= taxonTreeToNwkRec($db, $child);
			$isFirst = 0;
		}
		
		$nwk .= ')';
	}
	
	$nwk .= $node->name('scientific')->[0];
	# TODO: Branchlength if given
	return $nwk;
}

sub taxonTreeToNwk {
	return taxonTreeToNwkRec(shift, shift) . ';';
}
