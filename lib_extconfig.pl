##
# External/Extended Configuration Common Library
# 2.0.0 (7 Nov 2004)
#

$EXTCONFIG_FILE = '.extconfig';

sub extconfig_load # ( )
{
	if (-f $EXTCONFIG_FILE)
	{
		open file, $EXTCONFIG_FILE;
		map { eval } (<file>);
		close file;
	}
}

1;
