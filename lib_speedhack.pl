$PLUS_PATTERN = '(?:\x00{12}|\xFF{12}|(?:\w{2}.{6}[\w\x00]{3}.)|(?:\w{3}.{9})|(?:\x00{8}\w.{3}))[\x00-\x7F]';
$DASHR_PATTERN = '\x00{13}|(?:\w[\w \-\.,\xAD\x00]{11}.)';
$DASHRW_PATTERN = '\x00{13}|(?:\w[\w \-\.,\xAD\x00\!\/\[\]]{11}.)';

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
	my($found_break, $found_break_ff, $break_pos);
	my($id, $mid, $tid, $rid, %used);
	my($dash_type, $dash_pattern, $dash_sample);

	if ($data =~ /($PLUS_SAMPLE)/g)
	{
		$x = pos($data);
		$y = length($1);

		for ($p = $x - $y; nullunbuf(substr($data, $p - 26, 26)) =~ /$PLUS_PATTERN/; $p -= 26) { }

		@codes = ();

		$found_break = 0;
		$found_break_ff = 0;
		$break_pos = 0;

		for ($i = $p; ; $i += 26)
		{
			$id = nullunbuf(substr($data, $i, 26));

			if ($id =~ /$PLUS_PATTERN/)
			{
				$mid = nulltrim(substr($id, 0, 8));
				$tid = nulltrim(substr($id, 8, 3));
				$rid = ord(substr($id, 11, 1));
				$spd = ord(substr($id, 12, 1));

				push @codes, [ "+R/W", [ $mid, $tid, $rid, $spd ], sprintf("%-8s/%-3s/%02X", $mid, $tid, $rid) ];

				$found_break = $break_pos if ($mid eq "" || $mid =~ /^[\xFF]/);
				$found_break_ff = $break_pos if ($mid =~ /^[\xFF]/);
				++$break_pos;
			}
			else
			{
				last;
			}

			$found_break = $found_break_ff if ($found_break_ff < $found_break && $found_break_ff > 0);
		}

		foreach $i (0 .. $#codes)
		{
			$codes[$i][0] = ($i < $found_break) ? "+R" : "+RW" if ($found_break > $#codes / 2);

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

		for ($p = $x - $y; nullunbuf(substr($data, $p - 26, 26)) =~ /$PLUS_PATTERN/; $p -= 26) { }

		@codes = ();

		for ($i = $p; ; $i += 26)
		{
			$id = nullunbuf(substr($data, $i, 26));

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
		}
		else
		{
			$dash_sample = $DASHRW_SAMPLE;
			$dash_pattern = $DASHRW_PATTERN;
		}

		if ($data =~ /($dash_sample)/g)
		{
			$x = pos($data);
			$y = length($1);

			for ($p = $x - $y; substr($data, $p - 13, 13) =~ /$dash_pattern/; $p -= 13) { }

			@codes = @speeds = ();

			for ($i = $p; ; $i += 13)
			{
				$mid = substr($data, $i, 13);

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
					unless ($used{$codes[$i]} == 1 || substr($codes[$i], 0, 1) eq "\x00")
					{
						push @ret, [ "-$dash_type", [ $x = nulltrim(substr($codes[$i], 0, 12)), $y = ord(substr($codes[$i], 12, 1)), ord($speeds[$i]) ], sprintf("%-12s/%02X", $x, $y) ];
						$used{$codes[$i]} = 1;
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

	my($ricoh_do, $ricoh_count, $ricoh_max) = (0, 0, 0, 0);

	foreach $patch (@{$file_data{'plus_patches'}})
	{
		$mid = nullpad($patch->[0], 8);
		$tid = nullpad($patch->[1], 3);

		$code_id = nullbuf($mid . $tid . chr($patch->[2]));
		$code_old = $code_id . chr($patch->[3]);
		$code_new = $code_id . chr($patch->[4]);
		($code_id_m, $code_old_m, $code_new_m) = map { quotemeta } ($code_id, $code_old, $code_new);

		$data =~ s/$code_old_m/$code_new/g;

		$ricoh_do = 1 if ($mid . $tid eq "RICOHJPNR00");
	}

	if ($ricoh_do)
	{
		foreach $i (0 .. $file_data{'ncodes'} - 1)
		{
			if ("$file_data{'codes'}->[$i][1][0]$file_data{'codes'}->[$i][1][1]" eq "RICOHJPNR00")
			{
				++$ricoh_count;
				$ricoh_max = $file_data{'speeds'}->[$i] if ($ricoh_max < $file_data{'speeds'}->[$i]);
			}
		}

		if ($ricoh_count > 1)
		{
			$code_old_m = quotemeta(nullbuf("RICOHJPNR00")) . '[\x00\x01]\x00';
			$code_new = nullbuf("RICOHJPNR00\x01") . chr($ricoh_max);

			$data =~ s/$code_old_m[\x00-\xFF]/$code_new/g;
		}
	}

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

		if ($data =~ /($dash_sample)/g)
		{
			$x = pos($data);
			$y = length($1);

			for ($p = $x - $y; substr($data, $p - 13, 13) =~ /$dash_pattern/; $p -= 13) { }

			@codes = @speeds = ();

			for ($i = $p; ; $i += 13)
			{
				$mid = substr($data, $i, 13);

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
				$code_id = nullpad($patch->[0], 12);

				for ($i = 0; $i <= $#codes; ++$i)
				{
					if ( (substr($codes[$i], 0, 12) eq $code_id) &&
					     ($patch->[1] == 0 || ord(substr($codes[$i], 12, 1)) == 0 || ord(substr($codes[$i], 12, 1)) == $patch->[1]) &&
					     ($speeds[$i] eq chr($patch->[2])) )
					{
						$speeds[$i] = chr($patch->[3]);
					}
				}
			}

			$new_data = join("", @codes) . join("", @speeds);
			substr($data, $p, length($new_data), $new_data);
		}
	}

	substr($file_data{'work'}, $start, $len, $data);
}

1;
