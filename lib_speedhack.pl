##
# Speedhacker Common Library
# 1.2.0 (7 July 2004)
#

$PLUS_PATTERN = '(?:\x00{12}|\xFF{12}|(?:\w{2}.{6}[\w\x00]{3}.)|(?:\w{3}.{9})|(?:\x00{8}\w.{3}))[\x00-\x7F]';
$DASHR_PATTERN = '\x00{13}|(?:\w[\w \-=\.,\xAD\x00]{11}.)';
$DASHRW_PATTERN = '\x00{13}|(?:\w[\w \-=\.,\xAD\x00\!\/\[\]]{11}.)';

$PLUS_LEN = 26;
$DASHR_LEN = 13;
$DASHRW_LEN = 13;

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
	return join("\x00", split(//, $str)) . "\x00";
}

sub nullunbuf # ( str )
{
	my($str) = @_;
	my(@str_arr, $i, $ret);

	@str_arr = split(//, $str);

	for ($i = 0; $i <= $#str_arr; $i += 2)
	{
		$ret .= $str_arr[$i];
	}

	return $ret;
}

sub getcodes # ( )
{
	my($start, $len) = ($file_data{'gen'} < 3) ? (0xC0000, 0x20000) : (0x90000, 0x40000);
	my($data) = substr($file_data{'work'}, $start, $len);

	my($x, $y, $p, $i);
	my(@codes, @speeds, @ret);
	my($id, $mid, $tid, $rid, %used);
	my($dash_type, $dash_pattern, $dash_len, $dash_sample);

	my($plus_bank) = substr($file_data{'work'}, 0xC0000, 0x10000);
	my($plus_r_cnt, $plus_rw_cnt, $plus_cnt);

	if ( $plus_bank =~ /\xE5\x24\x90..\xB4\x94\x05\x74(.)\xF0\x80\x03\x74(.)\xF0/ ||
	     $plus_bank =~ /\xE5\x24\x64\x94\x60\x05\xE5\x24\xB4\x97\x08\x90..\x74(.)\xF0\x80\x06\x90..\x74(.)\xF0/ )
	{
		$plus_r_cnt = ord($1);
		$plus_rw_cnt = ord($2);
		$plus_cnt = $plus_r_cnt + $plus_rw_cnt;
	}
	else
	{
		$plus_cnt = $plus_r_cnt = $plus_rw_cnt = 0;
	}

	if ($data =~ /($PLUS_SAMPLE)/g)
	{
		$x = pos($data);
		$y = length($1);

		for ($p = $x - $y; nullunbuf(substr($data, $p - $PLUS_LEN, $PLUS_LEN)) =~ /$PLUS_PATTERN/; $p -= $PLUS_LEN) { }

		@codes = ();

		for ($i = $p; ; $i += $PLUS_LEN)
		{
			$id = nullunbuf(substr($data, $i, $PLUS_LEN));

			if ($id =~ /$PLUS_PATTERN/)
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

	if ($data =~ /($PLUSD_SAMPLE)/g)
	{
		$x = pos($data);
		$y = length($1);

		for ($p = $x - $y; nullunbuf(substr($data, $p - $PLUS_LEN, $PLUS_LEN)) =~ /$PLUS_PATTERN/; $p -= $PLUS_LEN) { }

		@codes = ();

		for ($i = $p; ; $i += $PLUS_LEN)
		{
			$id = nullunbuf(substr($data, $i, $PLUS_LEN));

			if ($id =~ /$PLUS_PATTERN/)
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

	foreach $dash_type ("R", "RW")
	{
		if ($dash_type eq "R")
		{
			$dash_sample = $DASHR_SAMPLE;
			$dash_pattern = $DASHR_PATTERN;
			$dash_len = $DASHR_LEN;
		}
		else
		{
			$dash_sample = $DASHRW_SAMPLE;
			$dash_pattern = $DASHRW_PATTERN;
			$dash_len = $DASHRW_LEN;
		}

		if ($data =~ /($dash_sample)/g)
		{
			$x = pos($data);
			$y = length($1);

			for ($p = $x - $y; substr($data, $p - $dash_len, $dash_len) =~ /$dash_pattern/; $p -= $dash_len) { }

			@codes = @speeds = ();

			for ($i = $p; ; $i += $dash_len)
			{
				$mid = substr($data, $i, $dash_len);

				if ($mid =~ /$dash_pattern/)
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
	my($start, $len) = ($file_data{'gen'} < 3) ? (0xC0000, 0x20000) : (0x90000, 0x40000);
	my($data) = substr($file_data{'work'}, $start, $len);

	my($x, $y, $p, $i);
	my($patch, $mid, $tid);
	my(@codes, @speeds, $new_data);
	my($dash_type, $dash_pattern, $dash_sample, @dash_patches);
	my($code_id, $code_old, $code_new);
	my($code_id_m, $code_old_m, $code_new_m);

	# Resolve the Ricoh R00 bug

	$code_old_m  = quotemeta(nullbuf("RICOHJPNR00\x01")) . '.\x00';
	$code_old_m x= 2;

	$code_new  = nullbuf("XxXxXxXxXxX\x01") . "\x02\x00";
	$code_new x= 2;

	$data =~ s/$code_old_m/$code_new/;

	foreach $patch (@{$file_data{'plus_patches'}})
	{
		$mid = nullpad($patch->[0], 8);
		$tid = nullpad($patch->[1], 3);

		$code_id = nullbuf($mid . $tid . chr($patch->[2]));
		$code_old = $code_id . chr($patch->[3]);
		$code_new = $code_id . chr($patch->[4]);
		($code_id_m, $code_old_m, $code_new_m) = map { quotemeta } ($code_id, $code_old, $code_new);

		$data =~ s/$code_old_m/$code_new/g;
	}

	foreach $dash_type ("R", "RW")
	{
		if ($dash_type eq "R")
		{
			$dash_sample = $DASHR_SAMPLE;
			$dash_pattern = $DASHR_PATTERN;
			$dash_len = $DASHR_LEN;
			@dash_patches = @{$file_data{'dashr_patches'}};
		}
		else
		{
			$dash_sample = $DASHRW_SAMPLE;
			$dash_pattern = $DASHRW_PATTERN;
			$dash_len = $DASHRW_LEN;
			@dash_patches = @{$file_data{'dashrw_patches'}};
		}

		if ($data =~ /($dash_sample)/g)
		{
			$x = pos($data);
			$y = length($1);

			for ($p = $x - $y; substr($data, $p - $dash_len, $dash_len) =~ /$dash_pattern/; $p -= $dash_len) { }

			@codes = @speeds = ();

			for ($i = $p; ; $i += $dash_len)
			{
				$mid = substr($data, $i, $dash_len);

				if ($mid =~ /$dash_pattern/)
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

	substr($file_data{'work'}, $start, $len, $data);
}

1;
