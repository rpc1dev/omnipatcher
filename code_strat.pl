$DEFSTRATCONF = 'rec_tweak.conf';

if (-f $DEFSTRATCONF)
{
	open file, $DEFSTRATCONF;
	read(file, $dsr_eval, -s file);
	close file;

	$DEF_STRAT_REV = ($dsr_eval =~ /# Revision (.-.. \(\d{4}\/\d{2}\/\d{2}\))/) ? $1 : "";

	eval("\@DEF_STRATS = ($dsr_eval);");
}
else
{
	@DEF_STRATS = ( );
}

$STRAT_BUF_LEN = 0x02;
$STRAT_REV_LOC = 0x0FFEF;

sub patch_strat # ( testmode, mode )
{
	return patch_strat2(@_) if ($file_data{'mctype'} == 2);

	my($testmode, $mode) = @_;
	my($curmode) = 0;

	$file_data{'stbloffset'} = 0xFF30;

	my($insert) = join '', map { chr }
	(
		0xC0, 0x82, 0xC0, 0x83, 0xFF, 0xE5, 0x24, 0xB4, 0x00, 0x12, 0x90, 0xFF, 0x30, 0xE4, 0x93, 0x60,
		0x0B, 0x6F, 0x60, 0x04, 0xA3, 0xA3, 0x80, 0xF5, 0x74, 0x01, 0x93, 0xFF, 0xEF, 0xD0, 0x83, 0xD0,
		0x82, 0xF0, 0x90, 0x00, 0x00, 0x22
	);

	my($pat_pattern) = '\x90..\xE0\x64[\x0A\x0B\x0D\x0E](?:\x60\x03\x02..|\x70.)(?:\x90..|\xA3)\xE0(?:\x90..|\x12\xFF\x00)\xF0';

	my(@pat_points, $pat_point, $pat_dptr);

	my($pbank) = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);
	my($dbank) = substr($file_data{'work'}, $file_data{'dbankpos'}, 0x10000);

	# First, let's make sure that we even have the space...

	if ( (substr($pbank, 0xFF00 - $STRAT_BUF_LEN, $STRAT_BUF_LEN) ne chr(0x00) x $STRAT_BUF_LEN) ||
	     (substr($dbank, 0xFF00 - $STRAT_BUF_LEN, $STRAT_BUF_LEN) ne chr(0x00) x $STRAT_BUF_LEN) )
	{
		return -1;
	}

	while ($pbank =~ /$pat_pattern/sg)
	{
		$pat_point = pos($pbank);
		$pat_point += $file_data{'pbankpos'} - 4;
		$pat_dptr = substr($file_data{'work'}, $pat_point + 1, 2);
		push @pat_points, [ $pat_point, $pat_dptr ];
	}

	while ($dbank =~ /$pat_pattern/sg)
	{
		$pat_point = pos($dbank);
		$pat_point += $file_data{'dbankpos'} - 4;
		$pat_dptr = substr($file_data{'work'}, $pat_point + 1, 2);
		push @pat_points, [ $pat_point, $pat_dptr ];
	}

	if ($pat_dptr eq "\xFF\x00")
	{
		$curmode = 1;
		$pat_dptr = substr($pbank, 0xFF23, 2);
	}

	# Early exits...

	return -1 unless ($#pat_points == 3 && $pat_points[0][1] eq $pat_points[1][1] && $pat_points[0][1] eq $pat_points[2][1] && $pat_points[0][1] eq $pat_points[3][1]);
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
			substr($file_data{'work'}, $pat_point->[0], 3, "\x12\xFF\x00");
		}

		substr($insert, 0x23, 2, $pat_dptr);

		substr($insert, 0x08, 1, chr(0x94));
		substr($file_data{'work'}, $file_data{'pbankpos'} + 0xFF00, length($insert), $insert);

		substr($insert, 0x08, 1, chr(0x90));
		substr($file_data{'work'}, $file_data{'dbankpos'} + 0xFF00, length($insert), $insert);

		substr($file_data{'work'}, $STRAT_REV_LOC, 1, chr(0x01));
	}

	return $curmode;
}

sub load_strats # ( )
{
	my($type, $pos, $curpos, $idx);

	foreach $type ("+R", "-R")
	{
		$pos = $file_data{'pbankpos'} if ($type eq "+R");
		$pos = $file_data{'dbankpos'} if ($type eq "-R");

		for ($curpos = $pos + $file_data{'stbloffset'}; ord(substr($file_data{'work'}, $curpos, 1)) != 0; $curpos += 2)
		{
			$idx = translate_index([$type, ord(substr($file_data{'work'}, $curpos, 1))]);
			$file_data{'strats'}[$idx] = ord(substr($file_data{'work'}, $curpos + 1, 1)) if ($idx >= 0);
		}
	}
}

sub save_strats # ( )
{
	my($i, $pcodes, $dcodes, $entry);

	for ($i = 0; $i < $file_data{'ncodes'}; ++$i)
	{
		if ($file_data{'codes'}->[$i][3] != $file_data{'strats'}->[$i])
		{
			$entry = chr($file_data{'codes'}->[$i][3]) . chr($file_data{'strats'}->[$i]);
			if ($file_data{'codes'}->[$i][0] eq "+R")
			{
				$pcodes .= $entry;
			}
			elsif ($file_data{'codes'}->[$i][0] eq "-R")
			{
				$dcodes .= $entry;
			}
		}
	}

	if ($pcodes eq "" && $dcodes eq "")
	{
		patch_strat(0, 0);
	}
	else
	{
		patch_strat(0, 1);
		substr($file_data{'work'}, $file_data{'pbankpos'} + $file_data{'stbloffset'}, length($pcodes), $pcodes);
		substr($file_data{'work'}, $file_data{'dbankpos'} + $file_data{'stbloffset'}, length($dcodes), $dcodes);
	}
}

sub find_index # ( params )
{
	my($params) = @_;
	my($code);
	my($i) = 0;

	if ($#{$params} == 1 || $#{$params} == 2)
	{
		foreach $code (@{$file_data{'codes'}})
		{
			if ( ($#{$params} == 2 && $params->[0] eq $code->[1][0] && $params->[1] eq $code->[1][1] && $params->[2] == $code->[1][2]) ||
			     ($#{$params} == 1 && $params->[0] eq $code->[1][0] && $params->[1] == $code->[1][1]) )
			{
				return $i;
			}

			++$i;
		}
	}

	return -1;
}

sub translate_index # ( params )
{
	my($params) = @_;
	my($code);
	my($i) = 0;

	foreach $code (@{$file_data{'codes'}})
	{
		return $i if ($params->[0] eq $code->[0] && $params->[1] == $code->[3]);
		++$i;
	}

	return -1;
}

sub refresh_st_display # ( idx )
{
	my($idx) = @_;
	my($label) = "$file_data{'codes'}->[$idx][2] $file_data{'codes'}->[$idx][0]";

	if ($file_data{'codes'}->[$idx][3] == $file_data{'strats'}->[$idx])
	{
		ChangeItem($ObjList, $idx, " $label");
	}
	else
	{
		ChangeItem($ObjList, $idx, "!$label");
	}
}

1;
