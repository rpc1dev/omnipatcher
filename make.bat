@echo off

perl -x -S "make.bat"

goto EndOfPerl

#!perl

###
# Step 0: Initialize
#

	$PL_FILE = 'dvdrw_omnipatcher.pl';
	$EXE_FILE = 'dvdrw_omnipatcher.exe';
	$ICO_FILE = 'chip.ico';
	$USE_GUI = 1;

	%info =
	(
		CompanyName      => 'http://codeguys.rpc1.org/',
		FileDescription  => 'OmniPatcher executable',
	);

	@trim_list =
	(
		'Errno',
		'File::Glob',
		'XSLoader',
		'PerlIO',
		'PerlIO::scalar',
		'attributes',
	);

###
# Step 1: Application Info
#

	open file, "appinfo.txt";
	($app_title, $app_ver_int, $app_ver_disp) = split(/\n/, join('', <file>));
	close file;

	$stamp = gmtime();

	open file, ">appinfo.pl";
	print file qq(\$PROGRAM_TITLE = '$app_title';\n);
	print file qq(\$PROGRAM_VERSION = '$app_ver_disp';\n);
	print file qq(\$BUILD_STAMP = '$stamp GMT';\n);
	close file;

	$info{'ProductName'} = $app_title;
	$info{'FileVersion'} = $app_ver_int;
	$info{'ProductVersion'} = $app_ver_int;

	$info{'OriginalFilename'} = uc($EXE_FILE);
	$info{'InternalName'} = $info{'OriginalFilename'};
	$info{'InternalName'} =~ s/\.EXE$//;

###
# Step 2: Prepare build params
#

	@params =
	(
		"--clean",
		"--exe $EXE_FILE",
		"--force",
		"--freestanding",
		($USE_GUI) ? "--gui" : "",
		"--icon $ICO_FILE",
		"--info " . join(';', map { qq($_="$info{$_}") } sort keys %info),
		"--nocompress",
		"--nologo",
		"--script $PL_FILE",
		"--trim " . join(';', @trim_list),
		"--verbose",
	);

###
# Step 3: Build & compress
#

	&execute('perlapp ' . join(' ', @params));
	&execute("upx -9 $EXE_FILE");

###
# Step 4: Strip UPX tags
#

	$null4 = "\x00" x 4;

	open file, $EXE_FILE;
	binmode file;
	read(file, $data, -s file);
	close file;

	$data =~ s/UPX0/$null4/;
	$data =~ s/UPX1/$null4/;
	$data =~ s/1\.2\d\x00UPX/$null4$null4/;

	open file, ">$EXE_FILE";
	binmode file;
	print file $data;
	close file;

###
# execute() function
#

	sub execute # ( command )
	{
		my($command) = @_;
		print "-" x 79, "\n";
		print "Executing command: $command\n";
		print "-" x 79, "\n";
		system($command);
		print "\n\n";
	}

__END__

:EndOfPerl
pause
