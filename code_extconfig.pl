$EXTCONFIG = '.extconfig';

if (-f $EXTCONFIG)
{
	open file, $EXTCONFIG;
	map { eval } (<file>);
	close file;
}

1;
