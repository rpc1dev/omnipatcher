##
# XFlash-X Common Library
# 1.1.1 (16 June 2004)
#

require "lib_xflashx_config.pl";

$XFX_PATTERN = &xfx_initpattern();

sub xfx_nulltrim # ( str )
{
	my($str) = @_;
	$str =~ s/\x00+$//g;
	return $str;
}

sub xfx_notstr # ( str )
{
	return join('', map { chr(ord($_) ^ 0xFF) } split(//, $_[0]));
}

sub xfx_sum # ( array )
{
	my($ret) = 0;
	map { $ret += $_ } @_;
	return $ret;
}

sub xfx_initpattern # ( )
{
	my($count_pattern, $start_pattern, $size_pattern, $name_pattern, $i);

	$count_pattern = 'HOW_MANY_BIN=(\d+\x00+)';

	foreach $i (1 .. 4)
	{
		$start_pattern .= 'BIN_START' . $i . '=(\d{10})\x00';
		$size_pattern .= 'BIN_SIZE' . $i . '=(\d{10})\x00';
		$name_pattern .= 'NEW_FW' . $i . '=([\w\x00].{6})\x00';
	}

	return "$count_pattern$start_pattern$size_pattern$name_pattern";
}

sub xfx_check_helper # ( )
{
	if (-f $XFX_HELPER)
	{
		return 1;
	}
	else
	{
		XFX_HELPER_ERR();
		return 0;
	}
}

sub xfx_debug # ( str )
{
	print @_ if ($XFX_PRINT_DEBUG);
}

sub xfx_status # ( str )
{
	print @_ if ($XFX_PRINT_STATUS);
}

sub xfx_crypt_mode3 # ( str, key, fwrev )
{
	my($str, $key, $fwrev) = @_;

	my($fwkey) = xfx_sum( map { ord } split(//, $fwrev) ) % 256;

	my($count);
	my($curkey);
	my($changepos);
	my($changebyte);
	my($fibcur) = 1;
	my($fibold) = 0;

	foreach $count (0 .. length($key) - 1)
	{
		$curkey = ord(substr($key, $count, 1));

		if (($count + 1) % 3 == 0)
		{
			$changepos = $curkey & 0x07;
		}
		elsif (($count + 1) % 3 == 1)
		{
			$changepos = $curkey % 7;
		}
		else
		{
			$changepos = $curkey % 5;
		}

		$changepos += $count * (length($str) / length($key));
		$changebyte = ord(substr($str, $changepos, 1));

		($fibold, $fibcur) = ($fibcur, $fibold + $fibcur);

		if ($fibcur % 9 == 1)
		{
			substr($str, $changepos, 1, chr($changebyte ^ $fwkey));
		}
		elsif ($fibcur % 9 == 2)
		{
			substr($str, $changepos, 1, chr($changebyte ^ 0xFF));
		}
		else
		{
			substr($str, $changepos, 1, chr($changebyte ^ $curkey));
		}

		unless ($fibcur <= 0x2AF90C18)
		{
			$fibcur = 1;
			$fibold = 0;
		}
	}

	return $str;
}

sub xflashx # ( f_in )
{
	my($f_in) = @_;
	my(@ret);

	my($data, $mode, $loaded);
	my($f_upx);

	my($offset, $nbins, @bins);
	my($start, $flag_fail, $scrammode, $skip_pre, $skip_len, $s_bin, $bin_fw);

	xfx_status "Loading and analyzing...\n\n";

	###
	# Determine Mode
	#
	xfx_debug "Performing initial analysis... ";

	$loaded = 0;

	if ($XFX_SCRAMSIZE == -1)
	{
		open file, $f_in;
		binmode file;
		$data = join("", <file>);
		close file;

		$loaded = 1;
		$mode = ($data =~ /$XFX_PATTERN/g) ? 1 : 2;
		pos($data) = 0;
	}
	else
	{
		$mode = ((-s $f_in) > $XFX_SCRAMSIZE) ? 1 : 2;
	}

	xfx_debug "done, entering mode $mode\n\n";

	###
	# UPX
	#
	if ($mode == 2)
	{
		return [ [ ], [ ] ] unless(xfx_check_helper());

		$f_upx = $f_in;
		$f_upx =~ s/\.exe$/$XFX_TEMP_SUFFIX.exe/i;

		xfx_debug "Creating temp file '$f_upx'...\n\n";

		unless ($loaded)
		{
			open file, $f_in;
			binmode file;
			$data = join("", <file>);
			close file;
		}

		$loaded = 0;

		substr($data, 0x2F8, 4, "UPX0");
		substr($data, 0x320, 4, "UPX1");
		substr($data, 0x3DB, 8, "1.24\00UPX");

		open file, ">$f_upx";
		binmode file;
		print file $data;
		close file;

		xfx_debug "Preparing '$f_upx'...\n\n";

		system(qq($XFX_HELPER -d -q "$f_upx"));

		$f_in = $f_upx;
	}

	###
	# Read input
	#
	xfx_debug "Reading input file '$f_in'...\n\n";

	unless ($loaded)
	{
		open file, $f_in;
		binmode file;
		$data = join("", <file>);
		close file;
	}

	unlink $f_upx if ($mode == 2 && $XFX_DELETE_TEMP);

	xfx_debug "Searching for the BIN descriptor table...\n";

	if ($data =~ /$XFX_PATTERN/g)
	{
		xfx_debug "BIN descriptor table found... parsing...\n\n";

		$offset = pos($data);

		# Store the results of the table read before using any more regexp
		# calls that might screw this up.
		#
		$nbins = $1;

		push @bins, [$10, $2, $6];
		push @bins, [$11, $3, $7];
		push @bins, [$12, $4, $8];
		push @bins, [$13, $5, $9];

		# Now that it's stored, it's safe to use regexp calls to do some
		# cleanup and some output.
		#
		$nbins = xfx_nulltrim($nbins) + 0;

		foreach $i (0 .. 3)
		{
			$bins[$i][0] = xfx_nulltrim($bins[$i][0]);
			$bins[$i][1] += 0;
			$bins[$i][2] += 0;

			xfx_debug sprintf("[BIN%d] Name: %s, Start: 0x%X, Size: 0x%06X\n", $i + 1, @{$bins[$i]});
		}

		xfx_debug sprintf("\nOffset: 0x%X\n", $offset);
		xfx_debug "Number of BINs: $nbins\n\n";

		foreach $i (0 .. $nbins - 1)
		{
			next if ($bins[$i][2] == 0);

			$start = $bins[$i][1] + $offset;
			xfx_debug sprintf("Extracting '%s.BIN': 0x%06X bytes at offset 0x%X (0x%X + 0x%X)...\n", $bins[$i][0], $bins[$i][2], $start, $bins[$i][1], $offset);

			$flag_fail = 0;

			if ($mode == 2)
			{
				if ($data =~ /r\]\x00(v2\.0\.5)\x00/)
				{
					$scrammode = 1;
					$skip_pre = 0x000000;
					$skip_len = 0x000000;
				}
				elsif ($data =~ /r\]\x00(v2\.1\.0)\x00/)
				{
					if ($data =~ /\xFF{256}/)
					{
						$scrammode = 2;
						$skip_pre = 0x000400;
						$skip_len = 0x001000;
					}
					else
					{
						$scrammode = 3;
					}
				}
				else
				{
					$scrammode = 0;
					$flag_fail = 1;
				}

				xfx_debug "Using unscrambler for XFlash $1, mode $scrammode...\n" unless($flag_fail);

				unless ($scrammode == 3)
				{
					$s_bin  = xfx_notstr(substr($data, $start, $skip_pre));
					$s_bin .= substr($data, $start + $skip_pre + $skip_len, $bins[$i][2] - $skip_pre);
					$bin_fw = $s_bin;

					substr($bin_fw, 0x0, 0x8000, reverse(substr($s_bin, length($s_bin) - 0x8000, 0x8000)));
					substr($bin_fw, length($s_bin) - 0x8000, 0x8000, reverse(substr($s_bin, 0x0, 0x8000)));
				}
				else
				{
					$bin_fw = xfx_crypt_mode3(substr($data, $start + 0x1000, $bins[$i][2]), substr($data, $offset + 0x400 * $i, 0x400), $bins[$i][0]);
				}
			}
			else
			{
				$bin_fw = substr($data, $start, $bins[$i][2]);
			}

			if ($XFX_VERIFYFW)
			{
				for ($bank = 0; $bank < length($bin_fw); $bank += 0x10000)
				{
					$flag_fail = 1 if (substr($bin_fw, $bank, 1) ne "\x02");
				}
			}

			unless ($flag_fail)
			{
				push @ret, [ $bins[$i][0], $bin_fw, $start, $offset + 0x400 * $i ];
				xfx_status "'$bins[$i][0]' has been extracted...\n\n";
			}
			else
			{
				push @ret, [ $bins[$i][0], '', 0, 0 ];
				xfx_status "Error extracting '$bins[$i][0]'...\n\n";
			}
		}
	}
	else
	{
		xfx_debug "BIN descriptor table could not be found...\n\n";
	}

	if ($XFX_RET_EXTENDED)
	{
		return [ [ @ret ], [ $data, $mode, $scrammode, $skip_pre, $skip_len ] ];
	}
	else
	{
		return [ [ @ret ], [ ] ];
	}
}

1;
