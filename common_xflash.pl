##
# Code Guys Perl Projects
# Common : XFlash functions
#
# Modified: 2005/06/25, C64K
# Revision: 2.2.0
#
# Implicit dependencies: common_util.pl
#

use Digest::MD5 qw(md5_hex);

##
# Default config variables for this module.
# Override these in each program's own config file.
#
$COM_XF_OUT_DEBUG            = sub { dbgout("$_[0]\n"); };
$COM_XF_UPX                  = 'upx.exe';		# UPX filename
$COM_XF_UPX_ERR              = sub { $COM_XF_OUT_DEBUG->("... '$COM_XF_UPX' could not be found!"); };
$COM_XF_UPX_SYSTEM           = 0;				# Use system() to invoke UPX?
$COM_XF_EXTR_UPX_TEMP_SUFFIX = '.upx-temp';	# UPX temporary file suffix
$COM_XF_EXTR_UPX_KEEP_TEMP   = 0;				# Keep the UPX temp file?
$COM_XF_EXTR_UNSCRAMBLE      = 0;				# Allow unscrambling of scrambled firmwares?
$COM_XF_EXTR_SCRAMSIZE       = -1;				# Scrambled flasher threshold size; -1 to disable
$COM_XF_EXTR_VERIFYFW        = 1;				# Verify firmwares?
$COM_XF_EXTR_FINGERPRINT     = 1;				# Output a md5sum of the firmware?

##
# Extraction pattern
#
$COM_XF_PATTERN = sub
{
	my($count_pattern, $start_pattern, $size_pattern, $name_pattern);

	$count_pattern = '(?:HOW_MANY_BIN|PARA_OPT)=(\d+\x00+).*?';

	foreach my $i (1 .. 4)
	{
		$start_pattern .= 'BIN_START' . $i . '=(\d{10})\x00';
		$size_pattern .= 'BIN_SIZE' . $i . '=(\d{10})\x00';
		$name_pattern .= 'NEW_FW' . $i . '=([\w\x00].{6})\x00';
	}

	return "$count_pattern$start_pattern$size_pattern$name_pattern";
}->();

##
# Scrambling routines
#
sub com_xf_scram1_dec # ( str, skip_pre, skip_len )
{
	my($str, $skip_pre, $skip_len) = @_;
	my($temp_bin);

	$temp_bin  = notstr(substr($str, 0x0, $skip_pre));
	$temp_bin .= substr($str, $skip_pre + $skip_len);

	$str = $temp_bin;

	substr($str, 0x0, 0x8000, reverse(substr($temp_bin, length($temp_bin) - 0x8000)));
	substr($str, length($temp_bin) - 0x8000, 0x8000, reverse(substr($temp_bin, 0x0, 0x8000)));

	return $str;
}

sub com_xf_scram1_enc # ( str, skip_pre )
{
	my($str, $skip_pre) = @_;
	my($temp_bin);

	substr($temp_bin, 0x0, 0x8000, reverse(substr($str, length($str) - 0x8000)));
	substr($temp_bin, length($str) - 0x8000, 0x8000, reverse(substr($str, 0x0, 0x8000)));

	return ( notstr(substr($temp_bin, 0, $skip_pre)), substr($temp_bin, $skip_pre) );
}

sub com_xf_scram2 # ( str, key, fwrev )
{
	my($str, $key, $fwrev) = @_;

	my($fwkey) = sum( map { ord } split(//, $fwrev) ) & 0xFF;

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

sub com_xf_scram3 # ( str, key, fwrev, andkey[, exkey ] )
{
	my($str, $key, $fwrev, $andkey, $exkey) = @_;

	my($fwkey) = sum( map { ord } split(//, $fwrev) ) & 0xFF;

	my($count);
	my($curkey);
	my($changepos);
	my($changebyte);

	my($hdbgtemp) = "N/A";

	unless (defined($exkey))
	{
		my(@excount) = (0) x 0x100;

		foreach $count (0 .. length($key) - 1)
		{
			$curkey = ord(substr($key, $count, 1));

			$changepos = $curkey & $andkey;
			$changepos += $count * (length($str) / length($key));
			$changebyte = ord(substr($str, $changepos, 1));

			if (($count + 1) % 7 == 1 || ($count + 1) % 7 == 3)
			{
				$excount[$changebyte ^ $fwkey]++;

				if ( $changepos > 0 && $changepos < length($str) - 1 &&
				     substr($str, $changepos - 1, 1) eq "\x00" && substr($str, $changepos - 1, 1) eq "\x00" )
				{
					$excount[$changebyte ^ $fwkey] += 2;
				}
			}
		}

		($exkey, $hdbgtemp, undef) = sort { $excount[$b] <=> $excount[$a] } (0x00 .. 0xFF);

		$hdbgtemp = sprintf("%02X:%02d%% / %02X:%02d%%", $exkey, 100 * $excount[$exkey] / sum(@excount), $hdbgtemp, 100 * $excount[$hdbgtemp] / sum(@excount));
	}

	$COM_XF_OUT_DEBUG->(sprintf("... > Keys: A(%02X), E(%02X), E_S/N(%s), F(%02X)", $andkey, $exkey, $hdbgtemp, $fwkey));

	foreach $count (0 .. length($key) - 1)
	{
		$curkey = ord(substr($key, $count, 1));

		$changepos = $curkey & $andkey;
		$changepos += $count * (length($str) / length($key));
		$changebyte = ord(substr($str, $changepos, 1));

		if (($count + 1) % 7 == 1 || ($count + 1) % 7 == 3)
		{
			substr($str, $changepos, 1, chr($changebyte ^ $fwkey ^ $exkey));
		}
		else
		{
			substr($str, $changepos, 1, chr($changebyte ^ $curkey));
		}
	}

	return ($str, $exkey);
}

##
# The stuff that's actually useful...
#
sub com_xf_extract # ( f_in[, ret_extended ] )
{
	my($f_in, $ret_extended) = @_;
	my(@ret, $i);

	my($data, $mode, $loaded, $f_upx);
	my($xfversion, $xfvernum, $xfb);

	my($ext_method) = -1;

	###
	# Optional: Override the unscrambling setup if UPX is found...
	# Comment this line out to disable this behavior.
	#
	#$COM_XF_EXTR_UNSCRAMBLE = 1 if (-f $COM_XF_UPX);

	###
	# Determine Mode
	#
	$COM_XF_OUT_DEBUG->("Performing initial analysis");

	$loaded = 0;

	if ($COM_XF_EXTR_SCRAMSIZE == -1)
	{
		loadbinary($f_in, \$data);
		$loaded = 1;

		$mode = ($data =~ /$COM_XF_PATTERN/s) ? 1 : 2;
	}
	else
	{
		$mode = ((-s $f_in) > $COM_XF_EXTR_SCRAMSIZE) ? 1 : 2;
	}

	if ($mode == 2 && $COM_XF_EXTR_UNSCRAMBLE == 0)
	{
		$COM_XF_OUT_DEBUG->("... This flasher is scrambled and/or compressed!");
		return [ [ ], [ ] ];
	}

	$COM_XF_OUT_DEBUG->("... Entering mode $mode");

	###
	# UPX
	#
	if ($mode == 2)
	{
		$COM_XF_OUT_DEBUG->("Preparing to attempt decompression");

		unless (-f $COM_XF_UPX)
		{
			&$COM_XF_UPX_ERR();
			return [ [ ], [ ] ];
		}

		$f_upx = $f_in;
		$f_upx =~ s/\.exe$/$COM_XF_EXTR_UPX_TEMP_SUFFIX.exe/i;

		$COM_XF_OUT_DEBUG->("... Creating temp file");

		loadbinary($f_in, \$data) unless ($loaded);
		$loaded = 0;

		substr($data, 0x2F8, 4, "UPX0");
		substr($data, 0x320, 4, "UPX1");
		substr($data, 0x3DB, 8, "1.24\00UPX");

		writebinary($f_upx, \$data);

		$COM_XF_OUT_DEBUG->("... Decompressing");

		my($upx_cmd) = qq($COM_XF_UPX -d -q "$f_upx");
		($COM_XF_UPX_SYSTEM) ? system($upx_cmd) : qx($upx_cmd);

		$f_in = $f_upx;
	}

	###
	# Read input
	#
	$COM_XF_OUT_DEBUG->("Reading input file");

	loadbinary($f_in, \$data) unless ($loaded);
	unlink($f_upx) if ($mode == 2 && !$COM_XF_EXTR_UPX_KEEP_TEMP);

	###
	# Finding out more about the flasher
	#
	$COM_XF_OUT_DEBUG->("Determining XFlash version");

	if ($data =~ /(?:rr.\x00v|Ver )(XFB-)?(\d\.\d{1,2}\.\d{1,2})\x00{2}/sg)
	{
		$xfb = (length($1) > 0);
		$xfversion = $2;
		$xfvernum = sprintf("%d%02d%02d", split(/\./, $xfversion));

		$COM_XF_OUT_DEBUG->("... Version detected: XFlash v$xfversion");

		if ($xfb)
		{
			if ($data =~ /\[(01)([US])-CG-XFB-(\d\.\d{1,2}\.\d{1,2})\]/sg)
			{
				$COM_XF_OUT_DEBUG->("... XFB flasher type detected: type $1/$2, made with version $3");
				$mode = ($2 eq 'U') ? 1 : 2;
			}
			else
			{
				$COM_XF_OUT_DEBUG->("... Unable to recognize XFB flasher type");
				return [ [ ], [ ] ];
			}
		}
		elsif ($mode != 2 && $xfvernum >= 20005)
		{
			$mode = 2;
			$COM_XF_OUT_DEBUG->("... Mode correction initiated, entering mode $mode");

			if ($mode == 2 && $COM_XF_EXTR_UNSCRAMBLE == 0)
			{
				$COM_XF_OUT_DEBUG->("... This flasher is scrambled and/or compressed!");
				return [ [ ], [ ] ];
			}
		}
		elsif ($mode == 2 && $xfvernum < 20005)
		{
			$mode = 1;
			$COM_XF_OUT_DEBUG->("... Mode correction initiated, entering mode $mode");
		}
	}
	else
	{
		$COM_XF_OUT_DEBUG->("... Unknown XFlash version");
	}

	###
	# Processing the firmwares
	#
	$COM_XF_OUT_DEBUG->("Searching for the firmware descriptor table");

	if ($data =~ /$COM_XF_PATTERN/sg)
	{
		my($skip_pre, $skip_len);
		my($rndkey, $andkey, $exkey);
		my($ext_info);

		my($offset, $nbins, @bins);
		my($start, $flag_fail, $bin_fw);

		my($bank, $verify_good, $md5sum);

		$COM_XF_OUT_DEBUG->("... Parsing descriptor table");

		$offset = pos($data);

		# Store the results of the table read before using any more regexp
		# calls that might screw up this capture.
		#
		$nbins = $1;

		push @bins, [$10, $2, $6];
		push @bins, [$11, $3, $7];
		push @bins, [$12, $4, $8];
		push @bins, [$13, $5, $9];

		# Now that it's stored, it's safe to use regexp calls to do some
		# cleanup and some output, and if it's the newer XFlash with
		# PARA_OPT, peg $nbins at 4...
		#
		$nbins = ($xfvernum < 20200) ? nulltrim($nbins) + 0 : 4;

		foreach $i (0 .. 3)
		{
			$bins[$i][0] = nulltrim(substr($bins[$i][0], 0, 4));
			$bins[$i][1] += 0;
			$bins[$i][2] += 0;

			$COM_XF_OUT_DEBUG->(sprintf("... %d - Name: %s, Offset: 0x%X, Size: 0x%06X", $i + 1, @{$bins[$i]}));
		}

		$COM_XF_OUT_DEBUG->(sprintf("... Initial offset: 0x%X", $offset));
		$COM_XF_OUT_DEBUG->("... Reported number of firmwares: $nbins");

		# Now we should determine what form of extraction should be used...
		# For some reason, this code used to be placed within the next loop,
		# which was inefficient...
		#
		$COM_XF_OUT_DEBUG->("Attempting to determine the appropriate extraction method");

		if ($mode == 1)
		{
			$ext_method = 0;
		}
		elsif ($xfvernum == 20005)
		{
			$ext_method = 1;
			$skip_pre = 0x000000;
			$skip_len = 0x000000;
		}
		elsif ($xfvernum >= 20100)
		{
			if ($data =~ /\x30\x02\xEB\x2B.{12}\x80\x34\x02\xFF.{25}\x30\x10/s)
			{
				$ext_method = 2;
			}
			elsif ($data =~ /(?:\x0F\xB6\x04\x08|(?:\x33\xC0)\x8A\x04\x0A)\x25(.)\x00\x00\x80(?:\x79\x05)\x48(?:\x83\xC8.)\x40/s)
			{
				$ext_method = 3;
				$andkey = ord($1);
			}
			elsif ($data =~ /\xFF{256}/s)
			{
				$ext_method = 1;
				$skip_pre = 0x000400;
				$skip_len = 0x001000;
			}
		}

		if ($ext_method == -1)
		{
			$COM_XF_OUT_DEBUG->("... Unable to determine extraction method!");
		}
		else
		{
			$COM_XF_OUT_DEBUG->("Extracting from XFlash v$xfversion, using extraction method $ext_method");

			foreach $i (0 .. $nbins - 1)
			{
				next if ($bins[$i][2] == 0);

				$COM_XF_OUT_DEBUG->(sprintf("... Extracting '%s': 0x%06X bytes with offset 0x%X", $bins[$i][0], $bins[$i][2], $bins[$i][1]));

				$flag_fail = 0;
				$start = $bins[$i][1] + $offset;

				if ($ext_method == 0)
				{
					# Unscrambled
					#
					$start += 0x1000 if ($xfb);
					$bin_fw = substr($data, $start, $bins[$i][2]);
					$ext_info = [ ];
				}
				elsif ($ext_method == 1)
				{
					# The flip-n-swap method
					#
					$bin_fw = com_xf_scram1_dec(substr($data, $start, $bins[$i][2] + $skip_len), $skip_pre, $skip_len);
					$ext_info = [ $skip_pre, $skip_len ];
				}
				elsif ($ext_method == 2)
				{
					# The Fibonacci scrambling method
					#
					$start += 0x1000;
					$rndkey = substr($data, $offset + 0x400 * $i, 0x400);

					$bin_fw = com_xf_scram2(substr($data, $start, $bins[$i][2]), $rndkey, $bins[$i][0]);
					$ext_info = [ $rndkey ];
				}
				elsif ($ext_method == 3)
				{
					# The "standard" scrambling method and variations thereof
					#
					$start += 0x1000;
					$rndkey = substr($data, $offset + 0x400 * $i, 0x400);

					($bin_fw, $exkey) = com_xf_scram3(substr($data, $start, $bins[$i][2]), $rndkey, $bins[$i][0], $andkey);
					$ext_info = [ $rndkey, $andkey, $exkey ];
				}
				else
				{
					$flag_fail = 1;
				}

				# Did we even get the right file size?
				#
				if ($flag_fail == 0 && length($bin_fw) != $bins[$i][2])
				{
					$COM_XF_OUT_DEBUG->("... > Size mismatch!");
					$flag_fail = 1;
				}

				# Verify the integrity of the extracted firmware
				#
				if ($COM_XF_EXTR_VERIFYFW && $flag_fail == 0)
				{
					$verify_good = 1;

					for ($bank = 0; $bank < length($bin_fw); $bank += 0x10000)
					{
						$verify_good = 0 if (substr($bin_fw, $bank, 1) ne "\x02");
					}

					# If the verification failed, give it a second chance
					# and see if it's a rebanked firmware...
					#
					unless ($verify_good)
					{
						$verify_good = 1;

						$verify_good = 0 if (substr($bin_fw, 0x0000, 1) ne "\x02");
						$verify_good = 0 if (substr($bin_fw, 0x4000, 1) ne "\x02");
						$verify_good = 0 if (substr($bin_fw, 0xFFF8, 8) ne "LITEONIT");

						$flag_fail = 1 unless ($verify_good);
					}
				}

				# Store the results in the return array
				#
				if ($flag_fail)
				{
					push @ret, [ $bins[$i][0], '', 0, [ ] ];
					$COM_XF_OUT_DEBUG->("... > Failed!");
				}
				else
				{
					$md5sum = ($COM_XF_EXTR_FINGERPRINT) ? sprintf(" (MD5: %s)", md5_hex($bin_fw)) : "";

					push @ret, [ $bins[$i][0], $bin_fw, $start, $ext_info ];
					$COM_XF_OUT_DEBUG->("... > Success!$md5sum");
				}

			} # foreach firmware

		} # if ext_method was found

	} # if descriptor table was found
	else
	{
		$COM_XF_OUT_DEBUG->("... Firmware descriptor table not found");
	}

	###
	# Return
	#
	return
	(
		($ret_extended) ?
		[ [ @ret ], [ $data, $ext_method ] ] :
		[ [ @ret ], [ ] ]
	);
}

sub com_xf_recrypt # ( &data, method, fmrev, extinfo )
{
	my($data, $method, $fmrev, $extinfo) = @_;

	if ($method == 1)
	{
		return com_xf_scram1_enc(${$data}, $extinfo->[0], $extinfo->[1]);
	}
	elsif ($method == 2)
	{
		return com_xf_scram2(${$data}, $extinfo->[0], $fmrev);
	}
	elsif ($method == 3)
	{
		return [ com_xf_scram3(${$data}, $extinfo->[0], $fmrev, $extinfo->[1], $extinfo->[2]) ]->[0];
	}
	else
	{
		return ${$data};
	}
}

1;
