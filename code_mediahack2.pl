$PLUSR1_SAMPLE = quotemeta(&nullbuf("RICOHJPNR0"));
$PLUSR2_SAMPLE = quotemeta(&nullbuf("YUDEN000T0"));
$PLUSR3_SAMPLE = quotemeta(&nullbuf("OPTODISCOR"));
$PLUSR4_SAMPLE = quotemeta(&nullbuf("PRODISC\x00R0"));
$PLUSR9_SAMPLE = quotemeta(&nullbuf("RICOHJPND00"));
$PLUSRW_SAMPLE = quotemeta(&nullbuf("MKM\x00\x00\x00\x00\x00A0"));
$PLUSRW2_SAMPLE = quotemeta(&nullbuf("RICOHJPNW"));

$PLUSR1A_SAMPLE = quotemeta("RICOHJPNR0");
$PLUSR2A_SAMPLE = quotemeta("YUDEN000T0");
$PLUSR3A_SAMPLE = quotemeta("OPTODISCOR");
$PLUSR4A_SAMPLE = quotemeta("PRODISC\x00R0");
$PLUSR9A_SAMPLE = quotemeta("RICOHJPND00");
$PLUSRWA_SAMPLE = quotemeta("MKM\x00\x00\x00\x00\x00A0");
$PLUSRW2A_SAMPLE = quotemeta("RICOHJPNW");

$DASHR1_SAMPLE = quotemeta("RITEKG0");
$DASHR2_SAMPLE = quotemeta("FUJIFILM0");
$DASHR3_SAMPLE = quotemeta("TYG0");

$DASHRW2_SAMPLE = 'TDK\d{3}saku';

sub addr2bankstr # ( address )
{
	use integer;
	my($address) = @_;
	$address %= 0x10000;
	return chr($address / 0x100) . chr($address % 0x100);
}

sub int2uni # ( val )
{
	use integer;
	return chr($_[0] / 0x100) . chr($_[0] % 0x100);
}

sub pcode2str # ( [ mid, tid, rid, spd ], unicode )
{
	my($data, $unicode) = @_;

	my($ret) = nullpad($data->[0], 8) . nullpad($data->[1], 3) . chr($data->[2]);
	return ($unicode) ? nullbuf($ret) . int2uni($data->[3]) : $ret . chr($data->[3]);
}

sub str2pcode # ( str, unicode )
{
	my($str, $unicode) = @_;

	my($id) = ($unicode) ? nullunbuf($str) : $str;

	my($mid) = nulltrim(substr($id, 0, 8));
	my($tid) = nulltrim(substr($id, 8, 3));
	my($rid) = ord(substr($id, 11, 1));
	my($spd) = ord(substr($id, 12, 1));

	$spd += ord(substr($str, 24, 1)) * 0x100 if ($unicode);

	return($mid, $tid, $rid, $spd);
}

sub getcodes2 # ( )
{
	my($data);
	my($i, $j);
	my(@codes, @ret);
	my($id_offset, $type);
	my($id, $mid, $tid, $rid, $spd, %used);
	my($eff_len);

	$file_data{'stratptables'} = [ ];
	$file_data{'stratdtables'} = [ ];
	$file_data{'prwtables'} = [ ];
	$file_data{'drwtables'} = [ ];

	$data = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);

	for ($i = 0; $i < scalar(@{$file_data{'mcpdata'}}); ++$i)
	{
		$data = substr($file_data{'work'}, $file_data{'pbankpos'} + $file_data{'mcpdata'}->[$i][0], $file_data{'mcpdata'}->[$i][1] * $file_data{'mcpdata'}->[$i][3]);

		$id_offset = 0;

		if ($data =~ /$PLUSR1_SAMPLE|$PLUSR2_SAMPLE|$PLUSR3_SAMPLE|$PLUSR4_SAMPLE|$PLUSR1A_SAMPLE|$PLUSR2A_SAMPLE|$PLUSR3A_SAMPLE|$PLUSR4A_SAMPLE/)
		{
			$type = '+R';
			$id_offset = scalar(@{$file_data{'stratptables'}});
			push @{$file_data{'stratptables'}}, $file_data{'mcpdata'}->[$i];
			$file_data{'mctype'} = 3 if ($file_data{'mctype'} < 3 && $file_data{'mcpdata'}->[$i][4] != 0);
		}
		elsif ($data =~ /$PLUSR9_SAMPLE|$PLUSR9A_SAMPLE/)
		{
			$type = '+R9';
		}
		elsif ($data =~ /$PLUSRW_SAMPLE|$PLUSRWA_SAMPLE|$PLUSRW2_SAMPLE|$PLUSRW2A_SAMPLE/)
		{
			$type = '+RW';
			$id_offset = scalar(@{$file_data{'prwtables'}});
			push @{$file_data{'prwtables'}}, $file_data{'mcpdata'}->[$i];
		}
		else
		{
			$type = '+R/W';
		}

		for ($j = 0; $j < $file_data{'mcpdata'}->[$i][1]; ++$j)
		{
			$eff_len = ($file_data{'mcpdata'}->[$i][3] > 0x10) ? 0x1A : 0x0D;
			($mid, $tid, $rid, $spd) = str2pcode(substr($data, $j * $file_data{'mcpdata'}->[$i][3], $eff_len), $eff_len == $PLUS_LEN);

			$mid =~ s/[\x00-\x1F]/ /g;
			$tid =~ s/[\x00-\x1F]/ /g;

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
		$data = substr($file_data{'work'}, $file_data{'dbankpos'} + $file_data{'mcddata'}->[$i][0], $file_data{'mcddata'}->[$i][1] * ($file_data{'mcddata'}->[$i][3] + 1));

		$id_offset = 0;

		if ($data =~ /$DASHR1_SAMPLE|$DASHR2_SAMPLE|$DASHR3_SAMPLE/)
		{
			$type = '-R';
			$id_offset = scalar(@{$file_data{'stratdtables'}});
			push @{$file_data{'stratdtables'}}, $file_data{'mcddata'}->[$i];
			$file_data{'mctype'} = 3 if ($file_data{'mctype'} < 3 && $file_data{'mcddata'}->[$i][4] != 0);
		}
		elsif ($data =~ /$DASHRW_SAMPLE|$DASHRW2_SAMPLE/)
		{
			$type = '-RW';
			$id_offset = scalar(@{$file_data{'drwtables'}});
			push @{$file_data{'drwtables'}}, $file_data{'mcddata'}->[$i];
		}
		else
		{
			$type = '-R/W';
		}

		for ($j = 0; $j < $file_data{'mcddata'}->[$i][1]; ++$j)
		{
			$id = substr($data, $j * $file_data{'mcddata'}->[$i][3], $file_data{'mcddata'}->[$i][3]);

			$mid = nulltrim(substr($id, 0, 12));
			$rid = ord(substr($id, 12, 1));
			$spd = ord(substr($data, $file_data{'mcddata'}->[$i][1] * $file_data{'mcddata'}->[$i][3] + $j, 1));

			$mid =~ s/[\x00-\x1F]/ /g;

			if (substr($id, 0, 1) ne "\x00" && substr($id, 0, 1) ne "\xFF")
			{
				push @ret, [ $type, [ $mid, $rid, $spd ], sprintf("%-12s/%02X", $mid, $rid), $id_offset * 0x40 + $j ];
			}
		}
	}

	return sort { ($a->[0] cmp $b->[0]) ? $a->[0] cmp $b->[0] : uc($a->[2]) cmp uc($b->[2]) } @ret;
}

sub setcodes2 # ( )
{
	my($data, $patch);
	my($code_old, $code_new);
	my(@dash_data, $dash_type);

	$data = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);

	foreach $patch (@{$file_data{'plus_patches'}})
	{
		$code_old = quotemeta(pcode2str([$patch->[0], $patch->[1], $patch->[2], $patch->[3]], 0));
		$code_new = pcode2str([$patch->[0], $patch->[1], $patch->[2], $patch->[4]], 0);

		$data =~ s/$code_old/$code_new/g;

		$code_old = quotemeta(pcode2str([$patch->[0], $patch->[1], $patch->[2], $patch->[3]], 1));
		$code_new = pcode2str([$patch->[0], $patch->[1], $patch->[2], $patch->[4]], 1);

		$data =~ s/$code_old/$code_new/g;
	}

	substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000, $data);

	foreach $dash_type ( [ 'R', $file_data{'stratdtables'}, $file_data{'dashr_patches'} ],
	                     [ 'RW', $file_data{'drwtables'}, $file_data{'dashrw_patches'} ] )
	{
		use integer;

		@dash_data = ();

		foreach $dash_table (@{$dash_type->[1]})
		{
			push @dash_data, substr($file_data{'work'}, $file_data{'dbankpos'} + $dash_table->[0] + $dash_table->[1] * $dash_table->[3], $dash_table->[1]);
		}

		foreach $patch (@{$dash_type->[2]})
		{
			substr($dash_data[$patch->[0] / 0x40], $patch->[0] % 0x40, 1, chr($patch->[1]));
		}

		foreach $dash_table (@{$dash_type->[1]})
		{
			substr($file_data{'work'}, $file_data{'dbankpos'} + $dash_table->[0] + $dash_table->[1] * $dash_table->[3], $dash_table->[1], shift(@dash_data));
		}
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

sub patch_strat3 # ( testmode, mode )
{
	return -1 if (scalar @{$file_data{'stratptables'}} < 3 || scalar @{$file_data{'stratdtables'}} < 3);
	return -1 if (scalar @{$file_data{'stratptables'}} > 4 || scalar @{$file_data{'stratdtables'}} > 4);

	my($testmode, $mode) = @_;
	my($curmode) = 0;
	my(@pat_points, @pat_jumps, $pat_point, $pat_dptr, $pat_area, $pat_entry, $pat_type);

	$file_data{'stbloffset'} = 0xFF40;

	my($insert) = join '', map { chr }
	(
		0x24, 0x40, 0x24, 0x40, 0x24, 0x40, 0xFF, 0x90, 0xFF, 0x40, 0xE4, 0x93, 0x60, 0x0B, 0x6F, 0x60,
		0x04, 0xA3, 0xA3, 0x80, 0xF5, 0x74, 0x01, 0x93, 0xFF, 0xEF, 0x75, 0xF0, 0x40, 0x84, 0xFE, 0xE5,
		0xF0, 0x90, 0x00, 0x00, 0xBE, 0x00, 0x03, 0x02, 0x00, 0x00, 0xBE, 0x01, 0x03, 0x02, 0x00, 0x00,
		0xBE, 0x02, 0x03, 0x02, 0x00, 0x00, 0x02, 0x00, 0x00
	);

	my($loc_dptr) = 0x22;
	my(@loc_jmps) = (0x28, 0x2E, 0x34, 0x37);

	my($pat_pattern) = $STRAT3_PATTERN;

	my($pbank) = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);
	my($dbank) = substr($file_data{'work'}, $file_data{'dbankpos'}, 0x10000);

	# First, let's make sure that we even have the space...

	if ( (substr($pbank, 0xFF00 - $STRAT_BUF_LEN, $STRAT_BUF_LEN) ne chr(0x00) x $STRAT_BUF_LEN) ||
	     (substr($dbank, 0xFF00 - $STRAT_BUF_LEN, $STRAT_BUF_LEN) ne chr(0x00) x $STRAT_BUF_LEN) )
	{
		return -1;
	}

	if (substr($file_data{'work'}, $STRAT_REV_LOC, 1) eq chr(0x04))
	{
		$curmode = 1;
		$pat_dptr = substr($pbank, 0xFF00 + $loc_dptr, 2);
	}
	else
	{
		$pat_dptr = "";
	}

	##
	# Gather all the patch points...
	#

	my($type, $i);

	foreach $type ( [ $file_data{'stratptables'}, $pbank, $file_data{'pbankpos'}, 0 ],
	                [ $file_data{'stratdtables'}, $dbank, $file_data{'dbankpos'}, 1 ] )
	{
		for ($i = 0; $i <= $#{$type->[0]}; ++$i)
		{
			$pat_area = substr($type->[1], $type->[0][$i][2], 9);

			if (($testmode || $mode) && $pat_area =~ s/^((?:\x90..|\xA3)\xE0)([\xF8-\xFF])(\x90..\xF0)(.*)$/$1$3$2$4/s)
			{
				substr($type->[1], $type->[0][$i][2], length($pat_area), $pat_area);
				substr($file_data{'work'}, $type->[0][$i][2] + $type->[2], length($pat_area), $pat_area) unless ($testmode);
			}

			$pat_area = substr($type->[1], $type->[0][$i][2], 8);

			if ($pat_area =~ /^($pat_pattern)/sg)
			{
				if (length($1) > 5)
				{
					$pat_point = scalar(pos($pat_area)) - 4;
					$pat_type = 0;
					$pat_ex = '';
				}
				elsif (length($1) == 5)
				{
					$pat_point = scalar(pos($pat_area)) - 5;
					$pat_type = 1;
					$pat_ex = substr($pat_area, (substr($pat_area, 0, 1) eq chr(0x90)) ? 3 : 0, 1);
				}
				else
				{
					return -1;
				}

				$pat_point += ($type->[2] + $type->[0][$i][2]);

				if ($curmode == 0 && $pat_dptr eq "")
				{
					$pat_dptr = substr($type->[1], $pat_point + 1 - $type->[2], 2);
				}
				elsif ($curmode == 0 && $pat_dptr ne substr($type->[1], $pat_point + 1 - $type->[2], 2))
				{
					return -1;
				}

				$pat_entry = "\xFF\x06" if ($i == 0);
				$pat_entry = "\xFF\x04" if ($i == 1);
				$pat_entry = "\xFF\x02" if ($i == 2);
				$pat_entry = "\xFF\x00" if ($i == 3);

				push @pat_points, [ $pat_point, $pat_entry, $pat_type, $pat_ex ];
				push @{$pat_jumps[$type->[3]]}, [ $loc_jmps[$i], $pat_point + (($pat_type) ? 4 : 3) ];

				if ($type->[0][$i][4])
				{
					$pat_area = substr($type->[1], $type->[0][$i][4], 9);

					if (($testmode || $mode) && $pat_area =~ s/^((?:\x90..|\xA3)\xE0)([\xF8-\xFF])(\x90..\xF0)(.*)$/$1$3$2$4/s)
					{
						substr($type->[1], $type->[0][$i][4], length($pat_area), $pat_area);
						substr($file_data{'work'}, $type->[0][$i][4] + $type->[2], length($pat_area), $pat_area) unless ($testmode);
					}

					$pat_area = substr($type->[1], $type->[0][$i][4], 8);

					if ($pat_area =~ /^($pat_pattern)/sg)
					{
						if (length($1) > 5)
						{
							$pat_point = scalar(pos($pat_area)) - 4;
							$pat_type = 0;
							$pat_ex = '';
						}
						elsif (length($1) == 5)
						{
							$pat_point = scalar(pos($pat_area)) - 5;
							$pat_type = 1;
							$pat_ex = substr($pat_area, (substr($pat_area, 0, 1) eq chr(0x90)) ? 3 : 0, 1);
						}
						else
						{
							return -1;
						}

						$pat_point += ($type->[2] + $type->[0][$i][4]);

						if ($curmode == 0 && $pat_dptr ne substr($type->[1], $pat_point + 1 - $type->[2], 2))
						{
							return -1;
						}
					}

					push @pat_points, [ $pat_point, $pat_entry, $pat_type, $pat_ex ];

				} # end if there is a second patch point
			}
			else
			{
				return -1;
			}

		} # end strat table loop

	} # end foreach media type

	dbgout("patch_strat3(): Listing of patch point data...\n");

	foreach $pat_point (@pat_points)
	{
		dbgout(sprintf("%05X, %02X, %d, %02X\n", $pat_point->[0], ord(substr($pat_point->[1], 1, 1)), $pat_point->[2], ord($pat_point->[3])));
	}

	return $curmode if ($testmode);

	substr($file_data{'work'}, $file_data{'pbankpos'} + 0xFF00, 0xF0, chr(0x00) x 0xF0);
	substr($file_data{'work'}, $file_data{'dbankpos'} + 0xFF00, 0xF0, chr(0x00) x 0xF0);

	if ($mode == 0)
	{
		foreach $pat_point (@pat_points)
		{
			if ($pat_point->[2] == 0)
			{
				substr($file_data{'work'}, $pat_point->[0], 3, "\x90$pat_dptr");
			}
			elsif ($pat_point->[2] == 1)
			{
				substr($file_data{'work'}, $pat_point->[0], 4, "\x90$pat_dptr$pat_point->[3]");
			}
		}

		substr($file_data{'work'}, $STRAT_REV_LOC, 1, chr(0x00));
	}
	else
	{
		foreach $pat_point (@pat_points)
		{
			if ($pat_point->[2] == 0)
			{
				substr($file_data{'work'}, $pat_point->[0], 3, "\x02$pat_point->[1]");
			}
			elsif ($pat_point->[2] == 1)
			{
				substr($file_data{'work'}, $pat_point->[0], 4, "$pat_point->[3]\x02$pat_point->[1]");
			}
		}

		substr($insert, $loc_dptr, 2, $pat_dptr);

		foreach $pat_point (@{$pat_jumps[0]})
		{
			dbgout(sprintf("+ insert change: %02X, %05X\n", $pat_point->[0], $pat_point->[1]));
			substr($insert, $pat_point->[0], 2, addr2bankstr($pat_point->[1]));
		}
		substr($file_data{'work'}, $file_data{'pbankpos'} + 0xFF00, length($insert), $insert);

		foreach $pat_point (@{$pat_jumps[1]})
		{
			dbgout(sprintf("- insert change: %02X, %05X\n", $pat_point->[0], $pat_point->[1]));
			substr($insert, $pat_point->[0], 2, addr2bankstr($pat_point->[1]));
		}
		substr($file_data{'work'}, $file_data{'dbankpos'} + 0xFF00, length($insert), $insert);

		substr($file_data{'work'}, $STRAT_REV_LOC, 1, chr(0x04));
	}

	return $curmode;
}

1;
