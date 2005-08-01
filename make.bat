@echo off

perl -x -S "make.bat"

goto EndOfPerl

#!perl

###
# Step 0: Initialize
#

	$PL_FILE = 'omnipatcher.pl';
	$EXE_FILE = 'omnipatcher.exe';
	$ICO_FILE = 'chip.ico';
	$ICO_ID = '!';
	$USE_GUI = 1;

	%info =
	(
		LegalCopyright   => 'Freeware; Copyright (C) 2004-2005 Code Guys.',
		CompanyName      => 'http://codeguys.rpc1.org/',
	);

	@trim_list =
	(
		'MIME::Base64',
	);

###
# Step 1: Application Info
#

	open file, "appinfo.txt";
	($app_title, $app_ver_int, $app_ver_disp) = split(/\n/, join('', <file>));
	close file;

	$curtime = time();
	$stamp = gmtime($curtime);
	$stamp_raw = pack("V", $curtime);

	open file, ">appinfo.pl";
	print file qq(\$PROGRAM_TITLE = '$app_title';\n);
	print file qq(\$PROGRAM_VERSION = '$app_ver_disp';\n);
	print file qq(\$BUILD_STAMP = '$stamp GMT';\n);
	print file qq(\$ICO_ID = '$ICO_ID';\n);
	close file;

	$info{'FileDescription'} = $app_title;
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
		"--norunlib",
		"--script $PL_FILE",
		"--trim " . join(';', @trim_list),
		"--trim-implicit",
		"--verbose",
	);

###
# Step 3: Build & compress
#

	&execute('perlapp ' . join(' ', @params));
	&execute("upx -9 $EXE_FILE");

###
# Step 4: Strip UPX tags and set the executable's build time
#

	$null4 = "\x00" x 4;

	open file, $EXE_FILE;
	binmode file;
	read(file, $data, -s file);
	close file;

	$data =~ s/UPX0/$null4/s;
	$data =~ s/UPX1/$null4/s;
	$data =~ s/1\.2\d\x00UPX/$null4$null4/s;
	$data =~ s/(PE\x00\x00....)..../$1$stamp_raw/s;

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
