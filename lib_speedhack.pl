##
# Speedhacker Common Library
# 1.3.0 (24 July 2004)
#

$PLUS_PATTERN = '(?:\x00{12}|\xFF{12}|(?:\w{2}.{6}[\w\x00]{3}.)|(?:[A-Z]\w{2}.{9})|(?:\x00{8}\w.{3}))[\x00-\x7F]';
$DASHR_PATTERN = '\x00{13}|(?:\w[\w \-=\.,\xAD\x00]{11}.)';
$DASHRW_PATTERN = '\x00{13}|(?:\w[\w \-=\.,\xAD\x00\!\/\[\]]{11}.)';

$PLUS_LEN = 26;
$DASH_LEN = 13;

$PLUS_SAMPLE = quotemeta(&nullbuf("RICOHJPNR00"));
$PLUSD_SAMPLE = quotemeta(&nullbuf("RICOHJPND00"));
$DASHR_SAMPLE = quotemeta("RITEKG03\x00");
$DASHRW_SAMPLE = quotemeta("RITEK000V11A");

sub nullpad # ( str, len )
{
	my($str, $len) = @_;
	return $str . "\x00" x ($len - length($str));
}

sub nulltrim # ( str )
{
	my($str) = @_;
	$str =~ s/\x00+$//g;
	return $str;
}

sub nullbuf # ( str )
{
	my($str) = @_;
	return "\x00" . join("\x00", split(//, $str));
}

sub nullunbuf # ( str )
{
	my($str) = @_;
	my(@str_arr, $i, $ret);

	@str_arr = split(//, $str);

	for ($i = 1; $i <= $#str_arr; $i += 2)
	{
		$ret .= $str_arr[$i];
	}

	return $ret;
}

sub getmctype # ( )
{
	my($pdata, $ddata);

	$pdata = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);
	$ddata = substr($file_data{'work'}, $file_data{'dbankpos'}, 0x10000);

	if ( $pdata =~ /\xE5\x24\x90..\xB4\x94\x05\x74(.)\xF0\x80\x03\x74(.)\xF0/s ||
	     $pdata =~ /\xE5\x24\x64\x94\x60\x05\xE5\x24\xB4\x97\x08\x90..\x74(.)\xF0\x80\x06\x90..\x74(.)\xF0/s )
	{
		$file_data{'mctype'} = 1;
		$file_data{'mcpdata'} = [ ord($1), ord($2), ord($1) + ord($2) ];
		$file_data{'mcddata'} = [ ];
	}
	else
	{
		$file_data{'mctype'} = 2;
		$file_data{'mcpdata'} = [ ];
		$file_data{'mcddata'} = [ ];

		while ($pdata =~ /\x75\xF0\x1A\xA4\x24(.)\xF5\x82(?:\xE5\xF0|\xE4)\x34(.)\xF5\x83.{35,43}?(?:\x64\x0B\x70|\xB4\x0B)\x03\x02(.)(.).{7,15}?\x90..\xE0\x04\xF0\xE0(?:\xC3\x94|\x64)(.)/sg)
		{
			push(@{$file_data{'mcpdata'}}, [ ord($2) * 0x100 + ord($1), ord($5), ord($3) * 0x100 + ord($4) ]);
		}

		while ($ddata =~ /\x75\xF0\x0D\xA4\x24(.)\xF5\x82(?:\xE5\xF0|\xE4)\x34(.)\xF5\x83.{256,272}?(?:\x64\x0E\x70|\xB4\x0E)\x03\x02(.)(.)\x90..\xE0\x04\xF0\xE0(?:\xC3\x94|\x64)\x0F.{2,8}?\x90..\xE0\x04\xF0\xE0(?:\xC3\x94|\x64)(.)/sg)
		{
			push(@{$file_data{'mcddata'}}, [ ord($2) * 0x100 + ord($1), ord($5), ord($3) * 0x100 + ord($4) ]);
		}

		if (scalar(@{$file_data{'mcpdata'}}) == 0 && scalar(@{$file_data{'mcddata'}}) == 0)
		{
			$file_data{'mctype'} = 0;
			$file_data{'mcpdata'} = [ 0, 0, 0 ];
		}
	}
}

sub getcodes # ( )
{
	return getcodes2() if ($file_data{'mctype'} == 2);

	my($data);
	my($x, $y, $p, $i);
	my(@codes, @speeds, @ret);
	my($plus_r_cnt, $plus_rw_cnt, $plus_cnt) = @{$file_data{'mcpdata'}};
	my($id, $mid, $tid, $rid, %used);
	my($dash_type, $dash_pattern, $dash_sample);

	$data = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);

	if ($data =~ /($PLUS_SAMPLE)/sg)
	{
		$x = pos($data);
		$y = length($1);

		for ($p = $x - $y; nullunbuf(substr($data, $p - $PLUS_LEN, $PLUS_LEN)) =~ /$PLUS_PATTERN/s; $p -= $PLUS_LEN) { }

		@codes = ();

		for ($i = $p; ; $i += $PLUS_LEN)
		{
			$id = nullunbuf(substr($data, $i, $PLUS_LEN));

			if ($id =~ /$PLUS_PATTERN/s)
			{
				$mid = nulltrim(substr($id, 0, 8));
				$tid = nulltrim(substr($id, 8, 3));
				$rid = ord(substr($id, 11, 1));
				$spd = ord(substr($id, 12, 1));

				push @codes, [ "+R/W", [ $mid, $tid, $rid, $spd ], sprintf("%-8s/%-3s/%02X", $mid, $tid, $rid) ];
			}
			else
			{
				last;
			}
		}

		%used = ();

		foreach $i (0 .. $#codes)
		{
			$codes[$i][0] = ($i < $plus_r_cnt) ? "+R" : "+RW" if ($#codes == $plus_cnt - 1);
			$codes[$i][3] = ($codes[$i][0] eq "+RW" ) ? $i - $plus_r_cnt : $i;

			if ($codes[$i][1][0] eq "MKM" && $codes[$i][1][1] eq "001")
			{
				$codes[$i][0] = "+R9";
			}
			elsif ($codes[$i][1][0] eq "RICOHJPN" && $codes[$i][1][1] eq "D00")
			{
				$codes[$i][0] = "+R9";
			}
			elsif ($codes[$i    ][1][0] eq "RICOHJPN" && $codes[$i    ][1][1] eq "R00" && $codes[$i    ][1][2] == 0x01 &&
			       $codes[$i + 1][1][0] eq "RICOHJPN" && $codes[$i + 1][1][1] eq "R00" && $codes[$i + 1][1][2] == 0x01)
			{
				$codes[$i][1][0] = $codes[$i + 1][1][0] = "";
				$codes[$i][1][1] = $codes[$i + 1][1][1] = "";
			}
			elsif ($codes[$i][1][0] eq "XxXxXxXx" && $codes[$i][1][1] eq "XxX")
			{
				$codes[$i][1][0] = "";
				$codes[$i][1][1] = "";
			}

			unless ($used{"$codes[$i][0]$codes[$i][2]$codes[$i][1][3]"} == 1 || ($codes[$i][1][0] eq "" && $codes[$i][1][1] eq "") || substr($codes[$i][1][0], 0, 1) eq "\xFF")
			{
				push @ret, $codes[$i];
				$used{"$codes[$i][0]$codes[$i][2]$codes[$i][1][3]"} = 1;
			}
		}

	} # End: +R/W

	if ($data =~ /($PLUSD_SAMPLE)/sg)
	{
		$x = pos($data);
		$y = length($1);

		for ($p = $x - $y; nullunbuf(substr($data, $p - $PLUS_LEN, $PLUS_LEN)) =~ /$PLUS_PATTERN/s; $p -= $PLUS_LEN) { }

		@codes = ();

		for ($i = $p; ; $i += $PLUS_LEN)
		{
			$id = nullunbuf(substr($data, $i, $PLUS_LEN));

			if ($id =~ /$PLUS_PATTERN/s)
			{
				$mid = nulltrim(substr($id, 0, 8));
				$tid = nulltrim(substr($id, 8, 3));
				$rid = ord(substr($id, 11, 1));
				$spd = ord(substr($id, 12, 1));

				push @codes, [ "+R9", [ $mid, $tid, $rid, $spd ], sprintf("%-8s/%-3s/%02X", $mid, $tid, $rid) ];
			}
			else
			{
				last;
			}
		}

		%used = ();

		foreach $i (0 .. $#codes)
		{
			$codes[$i][3] = $i;

			unless ($used{"$codes[$i][0]$codes[$i][2]$codes[$i][1][3]"} == 1 || ($codes[$i][1][0] eq "" && $codes[$i][1][1] eq "") || substr($codes[$i][1][0], 0, 1) eq "\xFF")
			{
				push @ret, $codes[$i];
				$used{"$codes[$i][0]$codes[$i][2]$codes[$i][1][3]"} = 1;
			}
		}

	} # End: +R9

	$data = substr($file_data{'work'}, $file_data{'dbankpos'}, 0x10000);

	foreach $dash_type ("R", "RW")
	{
		if ($dash_type eq "R")
		{
			$dash_sample = $DASHR_SAMPLE;
			$dash_pattern = $DASHR_PATTERN;
		}
		else
		{
			$dash_sample = $DASHRW_SAMPLE;
			$dash_pattern = $DASHRW_PATTERN;
		}

		if ($data =~ /($dash_sample)/sg)
		{
			$x = pos($data);
			$y = length($1);

			for ($p = $x - $y; substr($data, $p - $DASH_LEN, $DASH_LEN) =~ /$dash_pattern/s; $p -= $DASH_LEN) { }

			@codes = @speeds = ();

			for ($i = $p; ; $i += $DASH_LEN)
			{
				$mid = substr($data, $i, $DASH_LEN);

				if ($mid =~ /$dash_pattern/s)
				{
					push @codes, $mid;
				}
				else
				{
					last;
				}
			}

			for ( ; substr($data, $i, 1) ne "\x00"; ++$i)
			{
				push @speeds, substr($data, $i, 1);
			}

			if ($#codes == $#speeds)
			{
				foreach $i (0 .. $#codes)
				{
					if (substr($codes[$i], 0, 1) ne "\x00")
					{
						push @ret, [ "-$dash_type", [ $x = nulltrim(substr($codes[$i], 0, 12)), $y = ord(substr($codes[$i], 12, 1)), ord($speeds[$i]) ], sprintf("%-12s/%02X", $x, $y), $i ];
					}
				}

			} # End: if code count matches

		} # End: if sample found

	} # End: -R/W

	return sort { ($a->[0] cmp $b->[0]) ? $a->[0] cmp $b->[0] : uc($a->[2]) cmp uc($b->[2]) } @ret;
}

sub setcodes # ( )
{
	return setcodes2() if ($file_data{'mctype'} == 2);

	my($data);
	my($x, $y, $p, $i);
	my($patch, $mid, $tid);
	my(@codes, @speeds, $new_data);
	my($dash_type, $dash_pattern, $dash_sample, @dash_patches);
	my($code_id, $code_old, $code_new);
	my($code_id_m, $code_old_m, $code_new_m);

	$data = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);

	# Resolve the Ricoh R00 bug

	$code_old_m  = quotemeta(nullbuf("RICOHJPNR00\x01")) . '\x00.';
	$code_old_m x= 2;

	$code_new  = nullbuf("XxXxXxXxXxX\x01") . "\x00\x02";
	$code_new x= 2;

	$data =~ s/$code_old_m/$code_new/s;

	foreach $patch (@{$file_data{'plus_patches'}})
	{
		$mid = nullpad($patch->[0], 8);
		$tid = nullpad($patch->[1], 3);

		$code_id = nullbuf($mid . $tid . chr($patch->[2]));
		$code_old = $code_id . nullbuf(chr($patch->[3]));
		$code_new = $code_id . nullbuf(chr($patch->[4]));
		($code_id_m, $code_old_m, $code_new_m) = map { quotemeta } ($code_id, $code_old, $code_new);

		$data =~ s/$code_old_m/$code_new/sg;
	}

	substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000, $data);
	$data = substr($file_data{'work'}, $file_data{'dbankpos'}, 0x10000);

	foreach $dash_type ("R", "RW")
	{
		if ($dash_type eq "R")
		{
			$dash_sample = $DASHR_SAMPLE;
			$dash_pattern = $DASHR_PATTERN;
			@dash_patches = @{$file_data{'dashr_patches'}};
		}
		else
		{
			$dash_sample = $DASHRW_SAMPLE;
			$dash_pattern = $DASHRW_PATTERN;
			@dash_patches = @{$file_data{'dashrw_patches'}};
		}

		if ($data =~ /($dash_sample)/sg)
		{
			$x = pos($data);
			$y = length($1);

			for ($p = $x - $y; substr($data, $p - $DASH_LEN, $DASH_LEN) =~ /$dash_pattern/s; $p -= $DASH_LEN) { }

			@codes = @speeds = ();

			for ($i = $p; ; $i += $DASH_LEN)
			{
				$mid = substr($data, $i, $DASH_LEN);

				if ($mid =~ /$dash_pattern/s)
				{
					push @codes, $mid;
				}
				else
				{
					last;
				}
			}

			for ( ; substr($data, $i, 1) ne "\x00"; ++$i)
			{
				push @speeds, substr($data, $i, 1);
			}

			foreach $patch (@dash_patches)
			{
				$speeds[$patch->[0]] = chr($patch->[1]);
			}

			$new_data = join("", @codes) . join("", @speeds);
			substr($data, $p, length($new_data), $new_data);
		}
	}

	substr($file_data{'work'}, $file_data{'dbankpos'}, 0x10000, $data);
}

1;
