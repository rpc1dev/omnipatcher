$PLUSR1_SAMPLE = quotemeta(&nullbuf("RICOHJPNR00"));
$PLUSR2_SAMPLE = quotemeta(&nullbuf("RICOHJPNR01"));
$PLUSR3_SAMPLE = quotemeta(&nullbuf("RICOHJPNR02"));
$PLUSR4_SAMPLE = quotemeta(&nullbuf("YUDEN000T02"));
$PLUSR5_SAMPLE = quotemeta(&nullbuf("OPTODISCOR4"));
$PLUSR9_SAMPLE = quotemeta(&nullbuf("RICOHJPND00"));
$PLUSRW_SAMPLE = quotemeta(&nullbuf("RICOHJPNW01"));

$DASHR1_SAMPLE = quotemeta("RITEKG03\x00");
$DASHR2_SAMPLE = quotemeta("RITEKG04\x00");
$DASHR3_SAMPLE = quotemeta("RITEKG05\x00");

sub addr2bankstr # ( address )
{
	my($address) = @_;
	$address %= 0x10000;
	return chr($address / 0x100) . chr($address % 0x100);
}

sub getcodes2 # ( )
{
	my($data);
	my($i, $j);
	my(@codes, @ret);
	my($id_offset, $type);
	my($id, $mid, $tid, $rid, %used);

	$file_data{'stratptables'} = [ ];
	$file_data{'stratdtables'} = [ ];

	$data = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);

	for ($i = 0; $i < scalar(@{$file_data{'mcpdata'}}); ++$i)
	{
		$data = substr($file_data{'work'}, $file_data{'pbankpos'} + $file_data{'mcpdata'}->[$i][0], $file_data{'mcpdata'}->[$i][1] * $PLUS_LEN);

		$id_offset = 0;

		if ($data =~ /$PLUSR1_SAMPLE|$PLUSR2_SAMPLE|$PLUSR3_SAMPLE|$PLUSR4_SAMPLE|$PLUSR5_SAMPLE/)
		{
			$type = '+R';
			$id_offset = scalar(@{$file_data{'stratptables'}});
			push @{$file_data{'stratptables'}}, $file_data{'mcpdata'}->[$i];
		}
		elsif ($data =~ /$PLUSR9_SAMPLE/)
		{
			$type = '+R9';
		}
		elsif ($data =~ /$PLUSRW_SAMPLE/)
		{
			$type = '+RW';
		}
		else
		{
			$type = '+R/W';
		}

		for ($j = 0; $j < $file_data{'mcpdata'}->[$i][1]; ++$j)
		{
			$id = nullunbuf(substr($data, $j * $PLUS_LEN, $PLUS_LEN));

			$mid = nulltrim(substr($id, 0, 8));
			$tid = nulltrim(substr($id, 8, 3));
			$rid = ord(substr($id, 11, 1));
			$spd = ord(substr($id, 12, 1));

			push @codes, [ $type, [ $mid, $tid, $rid, $spd ], sprintf("%-8s/%-3s/%02X", $mid, $tid, $rid), $id_offset * 0x40 + $j ];
		}
	}

	%used = ();

	for ($i = 0; $i <= $#codes; ++$i)
	{
		unless ($used{"$codes[$i][0]$codes[$i][2]$codes[$i][1][3]"} == 1 || ($codes[$i][1][0] eq "" && $codes[$i][1][1] eq "") || substr($codes[$i][1][0], 0, 1) eq "\xFF")
		{
			push @ret, $codes[$i];
			$used{"$codes[$i][0]$codes[$i][2]$codes[$i][1][3]"} = 1;
		}
	}

	$data = substr($file_data{'work'}, $file_data{'dbankpos'}, 0x10000);

	for ($i = 0; $i < scalar(@{$file_data{'mcddata'}}); ++$i)
	{
		$data = substr($file_data{'work'}, $file_data{'dbankpos'} + $file_data{'mcddata'}->[$i][0], $file_data{'mcddata'}->[$i][1] * ($DASH_LEN + 1));

		$id_offset = 0;

		if ($data =~ /$DASHR1_SAMPLE|$DASHR2_SAMPLE|$DASHR3_SAMPLE/)
		{
			$type = '-R';
			$id_offset = scalar(@{$file_data{'stratdtables'}});
			push @{$file_data{'stratdtables'}}, $file_data{'mcddata'}->[$i];
		}
		elsif ($data =~ /$DASHRW_SAMPLE/)
		{
			$type = '-RW';
			$file_data{'drwtableidx'} = $i;
		}
		else
		{
			$type = '-R/W';
		}

		for ($j = 0; $j < $file_data{'mcddata'}->[$i][1]; ++$j)
		{
			$id = substr($data, $j * $DASH_LEN, $DASH_LEN);

			$mid = nulltrim(substr($id, 0, 12));
			$rid = ord(substr($id, 12, 1));
			$spd = ord(substr($data, $file_data{'mcddata'}->[$i][1] * $DASH_LEN + $j, 1));

			if (substr($id, 0, 1) ne "\x00")
			{
				push @ret, [ $type, [ $mid, $rid, $spd ], sprintf("%-12s/%02X", $mid, $rid), $id_offset * 0x40 + $j ];
			}
		}
	}

	return sort { ($a->[0] cmp $b->[0]) ? $a->[0] cmp $b->[0] : uc($a->[2]) cmp uc($b->[2]) } @ret;
}

sub setcodes2 # ( )
{
	my($data);
	my($patch, $mid, $tid);
	my($code_id, $code_old, $code_new);
	my($code_id_m, $code_old_m, $code_new_m);
	my(@dash_data, $dash_type, @dash_patches, $table_idx);

	$data = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);

	foreach $patch (@{$file_data{'plus_patches'}})
	{
		$mid = nullpad($patch->[0], 8);
		$tid = nullpad($patch->[1], 3);

		$code_id = nullbuf($mid . $tid . chr($patch->[2]));
		$code_old = $code_id . nullbuf(chr($patch->[3]));
		$code_new = $code_id . nullbuf(chr($patch->[4]));
		($code_id_m, $code_old_m, $code_new_m) = map { quotemeta } ($code_id, $code_old, $code_new);

		$data =~ s/$code_old_m/$code_new/g;
	}

	substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000, $data);

	foreach $dash_table (@{$file_data{'stratdtables'}}, $file_data{'mcddata'}->[$file_data{'drwtableidx'}])
	{
		push @dash_data, substr($file_data{'work'}, $file_data{'dbankpos'} + $dash_table->[0] + $dash_table->[1] * $DASH_LEN, $dash_table->[1]);
	}

	foreach $dash_type ("R", "RW")
	{
		if ($dash_type eq "R")
		{
			@dash_patches = @{$file_data{'dashr_patches'}};
		}
		else
		{
			@dash_patches = @{$file_data{'dashrw_patches'}};
		}

		foreach $patch (@dash_patches)
		{
			$table_idx = ($dash_type eq "R") ? int($patch->[0] / 0x40) : -1;
			substr($dash_data[$table_idx], $patch->[0] % 0x40, 1, chr($patch->[1]));
		}
	}

	foreach $dash_table (@{$file_data{'mcddata'}})
	{
		substr($file_data{'work'}, $file_data{'dbankpos'} + $dash_table->[0] + $dash_table->[1] * $DASH_LEN, $dash_table->[1], shift(@dash_data));
	}
}

sub patch_strat2 # ( testmode, mode )
{
	return -1 if (scalar @{$file_data{'stratptables'}} != 3 || scalar @{$file_data{'stratdtables'}} != 3);

	my($testmode, $mode) = @_;
	my($curmode) = 0;
	my(@pat_points, $pat_point, $pat_dptr, $pat_area, $pat_entry);

	$file_data{'stbloffset'} = 0xFF40;

	my($insert) = join '', map { chr }
	(
		0x24, 0x40, 0x24, 0x40, 0xC0, 0x82, 0xC0, 0x83, 0xFF, 0x90, 0xFF, 0x40, 0xE4, 0x93, 0x60, 0x0B,
		0x6F, 0x60, 0x04, 0xA3, 0xA3, 0x80, 0xF5, 0x74, 0x01, 0x93, 0xFF, 0xEF, 0x75, 0xF0, 0x40, 0x84,
		0xFF, 0xE5, 0xF0, 0xD0, 0x83, 0xD0, 0x82, 0xF0, 0x90, 0x00, 0x00, 0xEF, 0xAF, 0xF0, 0x60, 0x0B,
		0x14, 0x60, 0x04, 0xEF, 0x02, 0x00, 0x00, 0xEF, 0x02, 0x00, 0x00, 0xEF, 0x02, 0x00, 0x00
	);

	my($pat_pattern) = '(?:\x90..|\xA3)\xE0(?:\x90..|\x02\xFF[\x00\x02\x04])\xF0';

	my($pbank) = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);
	my($dbank) = substr($file_data{'work'}, $file_data{'dbankpos'}, 0x10000);

	# First, let's make sure that we even have the space...

	if ( (substr($pbank, 0xFF00 - $STRAT_BUF_LEN, $STRAT_BUF_LEN) ne chr(0x00) x $STRAT_BUF_LEN) ||
	     (substr($dbank, 0xFF00 - $STRAT_BUF_LEN, $STRAT_BUF_LEN) ne chr(0x00) x $STRAT_BUF_LEN) )
	{
		return -1;
	}

	if (substr($file_data{'work'}, $STRAT_REV_LOC, 1) eq chr(0x02))
	{
		$curmode = 1;
		$pat_dptr = substr($pbank, 0xFF29, 2);
	}
	else
	{
		$pat_dptr = "";
	}

	#
	# Gather all the patch points for the plus tables...
	#

	for ($i = 0; $i <= $#{$file_data{'stratptables'}}; ++$i)
	{
		$pat_area = substr($pbank, $file_data{'stratptables'}->[$i][2], 8);

		if ($pat_area =~ /$pat_pattern/sg)
		{
			$pat_point = pos($pat_area);
			$pat_point += ($file_data{'pbankpos'} + $file_data{'stratptables'}->[$i][2] - 4);

			if ($curmode == 0 && $pat_dptr eq "")
			{
				$pat_dptr = substr($file_data{'work'}, $pat_point + 1, 2);
			}
			elsif ($curmode == 0 && $pat_dptr ne substr($file_data{'work'}, $pat_point + 1, 2))
			{
				return -1;
			}

			$pat_entry = "\xFF\x04" if ($i == 0);
			$pat_entry = "\xFF\x02" if ($i == 1);
			$pat_entry = "\xFF\x00" if ($i == 2);

			push @pat_points, [ $pat_point, $pat_entry ];
		}
		else
		{
			return -1;
		}
	}

	#
	# Gather all the patch points for the dash tables...
	#

	for ($i = 0; $i <= $#{$file_data{'stratdtables'}}; ++$i)
	{
		$pat_area = substr($dbank, $file_data{'stratdtables'}->[$i][2], 8);

		if ($pat_area =~ /$pat_pattern/sg)
		{
			$pat_point = pos($pat_area);
			$pat_point += ($file_data{'dbankpos'} + $file_data{'stratdtables'}->[$i][2] - 4);

			if ($curmode == 0 && $pat_dptr eq "")
			{
				$pat_dptr = substr($file_data{'work'}, $pat_point + 1, 2);
			}
			elsif ($curmode == 0 && $pat_dptr ne substr($file_data{'work'}, $pat_point + 1, 2))
			{
				return -1;
			}

			$pat_entry = "\xFF\x04" if ($i == 0);
			$pat_entry = "\xFF\x02" if ($i == 1);
			$pat_entry = "\xFF\x00" if ($i == 2);

			push @pat_points, [ $pat_point, $pat_entry ];
		}
		else
		{
			return -1;
		}
	}

	return $curmode if ($testmode);

	substr($file_data{'work'}, $file_data{'pbankpos'} + 0xFF00, 0xF0, chr(0x00) x 0xF0);
	substr($file_data{'work'}, $file_data{'dbankpos'} + 0xFF00, 0xF0, chr(0x00) x 0xF0);

	if ($mode == 0)
	{
		foreach $pat_point (@pat_points)
		{
			substr($file_data{'work'}, $pat_point->[0], 3, "\x90$pat_dptr");
		}

		substr($file_data{'work'}, $STRAT_REV_LOC, 1, chr(0x00));
	}
	else
	{
		foreach $pat_point (@pat_points)
		{
			substr($file_data{'work'}, $pat_point->[0], 3, "\x02$pat_point->[1]");
		}

		substr($insert, 0x29, 2, $pat_dptr);

		substr($insert, 0x35, 2, addr2bankstr($pat_points[2][0] + 3));
		substr($insert, 0x39, 2, addr2bankstr($pat_points[1][0] + 3));
		substr($insert, 0x3D, 2, addr2bankstr($pat_points[0][0] + 3));
		substr($file_data{'work'}, $file_data{'pbankpos'} + 0xFF00, length($insert), $insert);

		substr($insert, 0x35, 2, addr2bankstr($pat_points[5][0] + 3));
		substr($insert, 0x39, 2, addr2bankstr($pat_points[4][0] + 3));
		substr($insert, 0x3D, 2, addr2bankstr($pat_points[3][0] + 3));
		substr($file_data{'work'}, $file_data{'dbankpos'} + 0xFF00, length($insert), $insert);

		substr($file_data{'work'}, $STRAT_REV_LOC, 1, chr(0x02));
	}

	return $curmode;
}

1;