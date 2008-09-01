#! /usr/bin/awk -f

#
# Use this to extract documentation from Bill modules.
#

BEGIN {
	in_comment = 0;
}


/^#\+\+[:space:]*$/ {
	in_comment = 1;
	next;
}


/^#\+\+/ {
	in_comment = 1;
	print "\n";
	$0 = substr($0, 5);
	print $1;
	underscores = $1;
	gsub(/./, "-", underscores);
	print underscores;
	print "\n::\n\n  " $0 "\n";
	next;
}


/^#--/ {
	print "\n";
	in_comment = 0;
	next;
}


{
	if (in_comment) {
		print substr($0, 5);
	}
}

