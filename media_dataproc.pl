##
# OmniPatcher for Optical Drives
# Media : Data processing
#
# Modified: 2005/07/22, C64K
#

sub media_istype # ( type, general_type )
{
	my($type, $general_type) = @_;
	return grep { $type == $_ } @{$MEDIA_TYPES[$general_type]};
}

sub media_spd2stdspd # ( spd )
{
	my($spd) = @_;

	if ($Current{'media_spd_type'} == 2)
	{
		# Slimtype
		#
		return 0b00000001 if ($spd == 0x01);
		return 0b00000010 if ($spd == 0x02);
		return 0b00000110 if ($spd == 0x04);
		return 0b00001110 if ($spd == 0x06);
		return 0b00011110 if ($spd == 0x08);
		return 0b00111100 if ($spd == 0x0C);
		return 0b01111100 if ($spd == 0x10);
		return 0b00000000;
	}
	elsif ($Current{'media_spd_type'} == 3 || $Current{'media_spd_type'} == 4)
	{
		# 8-bit
		#
		return (($spd & 0b00111111) | (($spd & 0b10000000) >> 1))
	}
	elsif ($Current{'media_spd_type'} == 5)
	{
		# 9-bit
		#
		return (($spd & 0b00011111) | (($spd & 0b01000000) >> 1) | (($spd & 0b100000000) >> 2))
	}
	else
	{
		# Standard/Unknown/Undefined
		#
		return $spd;
	}
}

sub media_stdspd2spd # ( spd )
{
	my($spd) = @_;

	if ($Current{'media_spd_type'} == 2)
	{
		# Slimtype
		#
		return 0x10 if ($_[0] & 0b01000000);
		return 0x0C if ($_[0] & 0b00100000);
		return 0x08 if ($_[0] & 0b00010000);
		return 0x06 if ($_[0] & 0b00001000);
		return 0x04 if ($_[0] & 0b00000100);
		return 0x02 if ($_[0] & 0b00000010);
		return 0x01 if ($_[0] & 0b00000001);
		return 0x00;
	}
	elsif ($Current{'media_spd_type'} == 3)
	{
		# 8-bit, b6set
		#
		return (($spd & 0b00111111) | (($spd & 0b01000000) << 1) | ($spd & 0b01000000))
	}
	elsif ($Current{'media_spd_type'} == 4)
	{
		# 8-bit, b6unset
		#
		return (($spd & 0b00111111) | (($spd & 0b01000000) << 1))
	}
	elsif ($Current{'media_spd_type'} == 5)
	{
		# 9-bit
		#
		return (($spd & 0b00011111) | (($spd & 0b01100000) << 1) | (($spd & 0b01000000) << 2))
	}
	else
	{
		# Standard/Unknown/Undefined
		#
		return $spd;
	}
}

sub media_makefield # ( datatype, len, addr, addr2offset )
{
	my($datatype, $len, $addr, $addr2offset) = @_;

	my($value) = substr($Current{'fw'}, $addr, $len << $datatype->[1]);

	$value = ($datatype->[0] == $MEDIA_DATA_STR) ?
		(($datatype->[1]) ? nulltrim(be16b2str($value)) : nulltrim($value)) :
		(($datatype->[1]) ? be16b2int($value) : ord($value));

	return [ $value, $datatype, $len, ($addr2offset) ? [ $addr, $addr + $addr2offset ] : [ $addr ] ];
}

sub media_makechange # ( entry, new_value )
{
	my($entry, $new_value) = @_;

	if (($entry->[1][0] == $MEDIA_DATA_STR) ? ($entry->[0] ne $new_value) : ($entry->[0] != $new_value))
	{
		# Adjust the length of the entry as necessary if 16 bits
		my($new_len) = $entry->[2] << $entry->[1][1];

		if ($entry->[1][0] == $MEDIA_DATA_STR)
		{
			$new_value = nullpad($new_value, $entry->[2]);
			$new_value = str2be16b($new_value) if ($entry->[1][1]);
		}
		else
		{
			$new_value = ($entry->[1][1]) ? int2be16b($new_value) : chr($new_value);
		}

		(length($new_value) == $new_len) ?
			map { substr($Current{'fw'}, $_, $new_len, $new_value) } @{$entry->[3]} :
			op_dbgout("media_makechange", "Fatal error: length mismatch");
	}
}

sub media_parse # ( )
{
	return if ($Current{'fw_type'} ne 'dvdrw');

	my(@table);

	op_dbgout("media_parse", sprintf("Media banks: +/%02X, -/%02X", $Current{'media_pbank'} >> 16, $Current{'media_dbank'} >> 16));

	##
	# Call the appropriate child function to get the raw data
	#
	if ($Current{'fw_manuf'} eq 'lo' && substr($Current{'fw'}, $Current{'media_dbank'}, 0x10000) =~ /\xC2\xAF..\x0B..\x08\x90..\x74.\xF0\x80\x06\x90..\x74.\xF0/s)
	{
		# 1S/2S/1213S
		#
		media_parse_1s(\@table);
		$Current{'media_spd_type'} = 1;
	}
	elsif ($Current{'fw_manuf'} eq 'lo' && $Current{'fw_gen'} >= 0x030 && $Current{'fw_gen'} < 0x040)
	{
		# 3S
		#
		media_parse_3s(\@table);
		$Current{'media_spd_type'} = 0;
	}
	elsif ($Current{'fw_manuf'} eq 'lo' && $Current{'fw_gen'} >= 0x110 && $Current{'fw_gen'} < 0x130)
	{
		# Slimtype 1S/2S
		#
		media_parse_s1s(\@table);
		$Current{'media_spd_type'} = 2;
	}
	elsif ($Current{'fw_manuf'} eq 'lo' && $Current{'fw_gen'} >= 0x130 && $Current{'fw_gen'} < 0x140)
	{
		# Slimtype 3S
		#
		media_parse_s3s(\@table);
		$Current{'media_spd_type'} = 2;
	}
	else
	{
		return;
	}

	##
	# Process the raw data to filter out bad codes, etc...
	#
	op_dbgout("media_parse", sprintf("Beginning media code post-processing: %d media codes", scalar(@table)));

	my($i, $b6set);

	for ($i = 0; $i <= $#table; ++$i)
	{
		if (media_istype($table[$i][0], $MEDIA_TYPE_DVD_P))
		{
			# Plus
			#
			unless( ($table[$i][2]{'MID'}[0] eq '' && $table[$i][2]{'TID'}[0] eq '') ||
			        ($table[$i][2]{'MID'}[0] eq 'MKM' && $table[$i][2]{'TID'}[0] eq '001' && $table[$i][0] == $MEDIA_TYPE_DVD_PR) ||
			        substr($table[$i][2]{'MID'}[0], 1, 1) eq chr(0xFF) ||
			        $table[$i][2]{'MID'}[0] eq 'XxXxXxXx' )
			{
				push( @{$Current{'media_table'}},
				[
					$table[$i][0], $table[$i][1], $table[$i][2],
					$table[$i][1],
					{
						MID => $table[$i][2]{'MID'}[0],
						TID => $table[$i][2]{'TID'}[0],
						RID => $table[$i][2]{'RID'}[0],
						SPD => $table[$i][2]{'SPD'}[0],
					},
					media_cleandisp(sprintf("%-8s-%-3s-%02X", $table[$i][2]{'MID'}[0], $table[$i][2]{'TID'}[0], $table[$i][2]{'RID'}[0])),
				] );

				++$Current{'media_type_count'}->[$table[$i][0]];
			}
		}
		else
		{
			# Dash
			#
			unless($table[$i][2]{'MID'}[0] eq '' || substr($table[$i][2]{'MID'}[0], 1, 1) eq chr(0xFF))
			{
				push( @{$Current{'media_table'}},
				[
					$table[$i][0], $table[$i][1], $table[$i][2],
					$table[$i][1],
					{
						MID => $table[$i][2]{'MID'}[0],
						RID => $table[$i][2]{'RID'}[0],
						SPD => $table[$i][2]{'SPD'}[0],
					},
					media_cleandisp(sprintf("%-12s-%02X", $table[$i][2]{'MID'}[0], $table[$i][2]{'RID'}[0])),
				] );

				++$Current{'media_type_count'}->[$table[$i][0]];
			}
		}
	}

	@{$Current{'media_table'}} = sort { ($a->[0] <=> $b->[0]) ? $a->[0] <=> $b->[0] : uc($a->[5]) cmp uc($b->[5]) } @{$Current{'media_table'}};
	$Current{'media_count'} = scalar(@{$Current{'media_table'}});

	op_dbgout("media_parse", sprintf("Completed media code post-processing: %d media codes", $Current{'media_count'}));

	##
	# Determine the speed encoding...
	#
	# This MUST be done after post-processing because invalid entries can trip
	# up the detection process!
	#
	if ($Current{'media_spd_type'} == 0)
	{
		$Current{'media_spd_type'} = 1;

		foreach $i (@{$Current{'media_table'}})
		{
			$b6set = 1 if ($i->[2]{'SPD'}[0] & 0x040);
			$Current{'media_spd_type'} = 5 if ($Current{'media_spd_type'} < 5 && ($i->[2]{'SPD'}[0] & 0x100));
			$Current{'media_spd_type'} = 4 if ($Current{'media_spd_type'} < 4 && ($i->[2]{'SPD'}[0] & 0x080));
		}

		$Current{'media_spd_type'} = 3 if ($Current{'media_spd_type'} == 4 && $b6set);
	}

	op_dbgout("media_parse", "Speed encoding: $MEDIA_SPEED_TYPE[$Current{'media_spd_type'}]");

	##
	# Fix the speed encoding...
	#
	if ($Current{'media_spd_type'} > 1)
	{
		op_dbgout("media_parse", "Converting non-standard speed encoding");

		foreach $i (@{$Current{'media_table'}})
		{
			$i->[4]{'SPD'} = $i->[2]{'SPD'}[0] = media_spd2stdspd($i->[2]{'SPD'}[0]);
		}
	}

	##
	# Rejoice if the there is actually something sensible being printed here!
	#
	if (0)
	{
		foreach $i (@{$Current{'media_table'}})
		{
			op_dbgout("media_parse", sprintf("Processed media code: %-3s / [%s] / %07b", $MEDIA_TYPE_NAME[$i->[0]], $i->[5], $i->[2]{'SPD'}[0]));
		}
	}
}

sub media_parse_1s # ( &table )
{
	my($table) = @_;

	my($pdata) = substr($Current{'fw'}, $Current{'media_pbank'}, 0x10000);
	my($ddata) = substr($Current{'fw'}, $Current{'media_dbank'}, 0x10000);

	my($ppat) = '\x75\xF0\x1A\xA4\x24(.)\xF5\x82(?:\xE5\xF0|\xE4)\x34(.)\xF5\x83';
	my($dpat) = '\x75\xF0\x0D\xA4\x24(.)\xF5\x82(?:\xE5\xF0|\xE4)\x34(.)\xF5\x83';

	my($plus_len, $dash_len) = (0x1A, 0x0D);

	my(@table_loc, @table_cnt, $media_type, $i);

	##
	# First, we need to apply a hack to fix the RICOHJPNR00 problem...
	#
	my($ricoh_hack_pat) = quotemeta(str2be16b("RICOHJPNR00\x01\x02")) x 2;
	my($ricoh_hack_ins) = str2be16b("XxXxXxXxXxX\x01\x02") x 2;

	if ($pdata =~ s/$ricoh_hack_pat/$ricoh_hack_ins/s)
	{
		op_dbgout("media_parse_1s", "Removing faulty RICOHJPNR00 +R DL entry");
		substr($Current{'fw'}, $Current{'media_pbank'}, 0x10000, $pdata);
	}

	##
	# Find the plus table locations and addresses.
	#
	# Observed lengths of wildcard segments...
	# Segment 1: 49-64 ~ Between +RW and +R
	# Segment 2: 49-49 ~ Between +R and +R9
	# Segment 3: 37-40 ~ Before the XOR
	#
	if ($pdata =~ /$ppat.{47,66}?$ppat(?:.{47,51}?$ppat)?.{35,42}?\x90..\xE0\x64\x0B/s)
	{
		$table_loc[$MEDIA_TYPE_DVD_PR]  = $Current{'media_pbank'} + be16b2int("$4$3");
		$table_loc[$MEDIA_TYPE_DVD_PRW] = $Current{'media_pbank'} + be16b2int("$2$1");
		$table_loc[$MEDIA_TYPE_DVD_PR9] = $Current{'media_pbank'} + be16b2int("$6$5") if (length($5) == 1);
	}

	if ( $pdata =~ /\xE5\x24\x90..\xB4\x94\x05\x74(.)\xF0\x80\x03\x74(.)\xF0/s ||
	     $pdata =~ /\xE5\x24\x64\x94\x60\x05\xE5\x24\xB4\x97\x08\x90..\x74(.)\xF0\x80\x06\x90..\x74(.)\xF0/s )
	{
		@table_cnt[$MEDIA_TYPE_DVD_PR, $MEDIA_TYPE_DVD_PRW] = (ord($1), ord($2));
	}

	##
	# Find the dash table locations and addresses.
	#
	# Observed lengths of wildcard segments...
	# Segment 1: 45-45 ~ Between -RW and -R
	# Segment 2: 377-382 ~ Before the XOR
	#
	if ($ddata =~ /$dpat.{43,47}?$dpat.{375,384}?\x90..\xE0\x64\x0E/s)
	{
		$table_loc[$MEDIA_TYPE_DVD_DR]  = $Current{'media_dbank'} + be16b2int("$4$3");
		$table_loc[$MEDIA_TYPE_DVD_DRW] = $Current{'media_dbank'} + be16b2int("$2$1");
	}

	if ($ddata =~ /\xC2\xAF..\x0B..\x08\x90..\x74(.)\xF0\x80\x06\x90..\x74(.)\xF0/s)
	{
		@table_cnt[$MEDIA_TYPE_DVD_DR, $MEDIA_TYPE_DVD_DRW] = (ord($2), ord($1));
	}

	##
	# For those who get the joys of reading the debug output...
	#
	foreach $media_type (@{$MEDIA_TYPES[$MEDIA_TYPE_DVD_P]}, @{$MEDIA_TYPES[$MEDIA_TYPE_DVD_D]})
	{
		op_dbgout("media_parse_1s", sprintf("%-3s, loc=%05X, n=%2s", $MEDIA_TYPE_NAME[$media_type], $table_loc[$media_type], ($table_cnt[$media_type] > 0) ? $table_cnt[$media_type] : '??')) if ($table_loc[$media_type]);
	}

	##
	# Process plus entries...
	#
	foreach $media_type (@{$MEDIA_TYPES[$MEDIA_TYPE_DVD_P]})
	{
		next unless ($table_loc[$media_type]);

		my($isR9) = ($media_type == $MEDIA_TYPE_DVD_PR9);

		# Hideous loop because we can't read the +R9 table length so we have to brute-force.
		for ($i = 0; ($table_cnt[$media_type]) ? $i < $table_cnt[$media_type] : be16b2str(substr($pdata, ($table_loc[$media_type] & 0xFFFF) + $plus_len * $i, $plus_len)) =~ /$MEDIA_PLUS_PATTERN/s; ++$i)
		{
			push( @{$table},
			[
				$media_type,
				$i,
				{
					MID => media_makefield([ $MEDIA_DATA_STR, 1 ], 8, $table_loc[$media_type] + $plus_len * $i + 0x00, ($isR9) ? $plus_len : 0),
					TID => media_makefield([ $MEDIA_DATA_STR, 1 ], 3, $table_loc[$media_type] + $plus_len * $i + 0x10, ($isR9) ? $plus_len : 0),
					RID => media_makefield([ $MEDIA_DATA_INT, 1 ], 1, $table_loc[$media_type] + $plus_len * $i + 0x16, ($isR9) ? $plus_len : 0),
					SPD => media_makefield([ $MEDIA_DATA_INT, 1 ], 1, $table_loc[$media_type] + $plus_len * $i + 0x18, ($isR9) ? $plus_len : 0),
				}
			] );

			++$i if ($isR9);
		}
	}

	##
	# Process dash entries...
	#
	foreach $media_type (@{$MEDIA_TYPES[$MEDIA_TYPE_DVD_D]})
	{
		next unless ($table_loc[$media_type]);

		for ($i = 0; $i < $table_cnt[$media_type]; ++$i)
		{
			push( @{$table},
			[
				$media_type,
				$i,
				{
					MID => media_makefield([ $MEDIA_DATA_STR, 0 ], 12, $table_loc[$media_type] + $dash_len * $i + 0x00, 0),
					RID => media_makefield([ $MEDIA_DATA_INT, 0 ], 1, $table_loc[$media_type] + $dash_len * $i + 0x0C, 0),
					SPD => media_makefield([ $MEDIA_DATA_INT, 0 ], 1, $table_loc[$media_type] + $dash_len * $table_cnt[$media_type] + $i, 0),
				}
			] );
		}
	}
}

sub media_parse_3s # ( &table )
{
	my($table) = @_;

	##
	# The world's most convoluted pattern matching scheme...
	#
	my($stratpat) = '(?:(?:\x90..|\xA3)\xE0[\xF8-\xFF]?(?:\x90..|\x02\xFF.)|(?:\x90..[\xE8-\xEF]|[\xE8-\xEF]\x02\xFF.))\xF0';

	my($ppat) = '(?:\x75\xF0|\xC4\x54)(?#1)(.)(?:\xA4\x24|\x24)(?#2)(.)\xF5\x82(?:\xE5\xF0|\xE4)\x34(?#3)(.)\xF5\x83.{12,43}?(?:\x64\x0B\x70|\xB4\x0B)' .
	            '(?:\x03\x02(?#4)(..).{0,8}?|' .
	            '.(?#5)(' . $stratpat . '.{36,110}?(?:(?:\xEF|\x90..\xE0)\x64.\x60.)*.{0,17}?))' .
	            '(?#6)(\x90..\xE0\x04\xF0\xE0(?:\xC3\x94|\x64)\x0C.{2,8}?\x90..\xE0\x04\xF0\xE0(?:\xC3\x94|\x64))(?#7)(.)';

	my($dpat) = '\x75\xF0(?#1)([\x0D-\x11])\xA4\x24(?#2)(.)\xF5\x82(?:\xE5\xF0|\xE4)\x34(?#3)(.)\xF5\x83(?:.{256,272}?|.{154,170}?)(?:\x64\x0E\x70|\x64\x0E\x60.\x02.|\xB4\x0E)' .
	            '(?:\x03\x02(?#4)(..)|' .
	            '.(?#5)(' . $stratpat . '.{10,207}?(?:(?:\xEF|\x90..\xE0)(?:\x64.\x60.|\x90..\x02..))*.{0,6}))' .
	            '(?#6)(\x90..\xE0\x04\xF0\xE0(?:\xC3\x94|\x64)\x0F.{2,8}?\x90..\xE0\x04\xF0\xE0(?:\xC3\x94|\x64))(?#7)(.)';

	##
	# Format of @tables3s:
	#
	# type(0), table_start(1), table_entries(2), table_entry_len(3), [ strat_patch_addr, strat_patch_ext ](4)
	#
	my(@tables3s);

	##
	# Loop through each format and search for tables...
	#                     0                  1/2                                                             3      4
	foreach my $param ( [ $MEDIA_TYPE_DVD_P, (substr($Current{'fw'}, $Current{'media_pbank'}, 0x10000)) x 2, $ppat, $Current{'media_pbank'} ],
	                    [ $MEDIA_TYPE_DVD_D, (substr($Current{'fw'}, $Current{'media_dbank'}, 0x10000)) x 2, $dpat, $Current{'media_dbank'} ] )
	{
		# Some temporary variables for this segment of code
		#
		my($new_entry, $x, $y, $z);

		while ($param->[1] =~ /$param->[3]/sg)
		{
			if (grep { $_->[1] == $param->[4] + be16b2int("$3$2") } @tables3s)
			{
				op_dbgout("media_parse_3s", "Warning, duplicate table captured and removed!");
			}
			else
			{
				$new_entry = [ $param->[0], $param->[4] + be16b2int("$3$2"), ord($7), (ord($1) == 0xF0) ? 0x10 : ord($1), (length($5)) ? [ (pos($param->[1])) - length($5) - length($6) - length($7), 1 ] : [ be16b2int($4), 0, ord($7) ] ];

				# If it turns out that there is a second strat patch point, we'll
				# need to find it...
				#
				if ($new_entry->[4][1])
				{
					($x, $y, $z) = map { quotemeta } ($1, $2, $3);

					if ( ($param->[0] == $MEDIA_TYPE_DVD_P) ?
					     ($param->[2] =~ /(?:\x75\xF0|\xC4\x54)$x(?:\xA4\x24|\x24)$y\xF5\x82(?:\xE5\xF0|\xE4)\x34$z\xF5\x83.{12,43}?(?:\x64\x0A\x70|\xB4\x0A)./sg) :
					     ($param->[2] =~ /\x75\xF0$x\xA4\x24$y\xF5\x82(?:\xE5\xF0|\xE4)\x34$z\xF5\x83.{71,90}?(?:\x64\x0D(?:\x70|\x60\x03..)|\xB4\x0D)./sg) )
					{
						$new_entry->[4][1] = $new_entry->[4][0];
						$new_entry->[4][0] = pos($param->[2]);
					}
					else
					{
						# A second strat patch point, though expected, was not found... oops!
						#
						$new_entry->[4][1] = 0xFFFF;
					}
				}

				# Now let's be more specific than just '+' or '-'
				#
				$x = substr($param->[1], $new_entry->[1] & 0xFFFF, $new_entry->[2] * $new_entry->[3]);

				foreach $y (@{$MEDIA_TYPES[$param->[0]]})
				{
					if ($x =~ $MEDIA_SAMPLES[$y])
					{
						$new_entry->[0] = $y;
						last;
					}
				}

				# Whew, finally, done with this new entry!
				#
				push(@tables3s, $new_entry);

				op_dbgout("media_parse_3s", sprintf("%-3s, fw=%06X, loc=%06X, n=%2d, len=%02d, strat=%02X%04X/%04X", $MEDIA_TYPE_NAME[$tables3s[-1][0]], $param->[4] + pos($param->[1]), $tables3s[-1][1], @{$tables3s[-1]}[2 .. 3], $param->[4] >> 16, @{$tables3s[-1][4]}));

			} # End: if duplicate table

		} # End: while there are more tables to be found

	} # End: for each media format

	op_dbgout("media_parse_3s", sprintf("Total number of media tables: %d", scalar(@tables3s)));

	##
	# Put the tables through the strainer and make them usable!
	#
	my($entry, @type_count, $id_offset, $i);

	foreach $entry (@tables3s)
	{
		$id_offset = $type_count[$entry->[0]]++ << 6;

		if (media_istype($entry->[0], $MEDIA_TYPE_DVD_P))
		{
			push(@{$Current{'media_pstrat_pts'}}, $entry->[4]) if ($entry->[0] == $MEDIA_TYPE_DVD_PR);

			my($isR9) = ($entry->[0] == $MEDIA_TYPE_DVD_PR9);
			my($encoding) = ($entry->[3] > 0x14) ? 1 : 0;

			for ($i = 0; $i < $entry->[2]; ++$i )
			{
				push( @{$table},
				[
					$entry->[0],
					$i + $id_offset,
					{
						MID => media_makefield([ $MEDIA_DATA_STR, $encoding ], 8, $entry->[1] + $entry->[3] * $i + (0x00 << $encoding), ($isR9) ? $entry->[3] : 0),
						TID => media_makefield([ $MEDIA_DATA_STR, $encoding ], 3, $entry->[1] + $entry->[3] * $i + (0x08 << $encoding), ($isR9) ? $entry->[3] : 0),
						RID => media_makefield([ $MEDIA_DATA_INT, $encoding ], 1, $entry->[1] + $entry->[3] * $i + (0x0B << $encoding), ($isR9) ? $entry->[3] : 0),
						SPD => media_makefield([ $MEDIA_DATA_INT, $encoding ], 1, $entry->[1] + $entry->[3] * $i + (0x0C << $encoding), ($isR9) ? $entry->[3] : 0),
					}
				] );

				++$i if ($isR9);
			}
		}
		else
		{
			push(@{$Current{'media_dstrat_pts'}}, $entry->[4]) if ($entry->[0] == $MEDIA_TYPE_DVD_DR);

			my($isR9) = ($entry->[0] == $MEDIA_TYPE_DVD_DR9);

			for ($i = 0; $i < $entry->[2]; ++$i )
			{
				push( @{$table},
				[
					$entry->[0],
					$i + $id_offset,
					{
						MID => media_makefield([ $MEDIA_DATA_STR, 0 ], 12, $entry->[1] + $entry->[3] * $i + 0x00, ($isR9) ? $entry->[3] : 0),
						RID => media_makefield([ $MEDIA_DATA_INT, 0 ], 1, $entry->[1] + $entry->[3] * $i + 0x0C, ($isR9) ? $entry->[3] : 0),
						SPD => media_makefield([ $MEDIA_DATA_INT, 0 ], 1, $entry->[1] + $entry->[3] * $entry->[2] + $i, ($isR9) ? 1 : 0),
					}
				] );

				++$i if ($isR9);
			}

		} # End: if plus or dash

	} # End: for each entry in @tables3s
}

sub media_parse_s1s # ( &table )
{
	my($table) = @_;

	my($pdata) = substr($Current{'fw'}, $Current{'media_pbank'}, 0x10000);
	my($ddata) = substr($Current{'fw'}, $Current{'media_dbank'}, 0x10000);

	my($ppat) = '\x75\xF0\x1A\xA4\x24(.)\xF5\x82(?:\xE5\xF0|\xE4)\x34(.)\xF5\x83';
	my($dpat) = '\x75\xF0\x0E\xA4\x24(.)\xF5\x82(?:\xE5\xF0|\xE4)\x34(.)\xF5\x83';

	my($plus_len, $dash_len) = (0x1A, 0x0E);

	my(@table_loc, @table_cnt, $media_type, $i);

	##
	# Find the plus table locations and addresses.
	#
	# Observed lengths of wildcard segments...
	# Segment 1: 50-58 ~ Between +RW and +R
	# Segment 2: 45-45 ~ Between +R and +R9
	# Segment 3: 36-36, 131-152 ~ Before the XOR
	#
	if ($pdata =~ /$ppat.{46,62}?$ppat(?:.{41,49}?$ppat)?.{32,160}?\x90..\xE0\x64\x0B/s)
	{
		$table_loc[$MEDIA_TYPE_DVD_PR]  = $Current{'media_pbank'} + be16b2int("$4$3");
		$table_loc[$MEDIA_TYPE_DVD_PRW] = $Current{'media_pbank'} + be16b2int("$2$1");
		$table_loc[$MEDIA_TYPE_DVD_PR9] = $Current{'media_pbank'} + be16b2int("$6$5") if (length($5) == 1);
	}

	if ($pdata =~ /\xE5\x24(?:\x90..)?\xB4\x94.(?:\x90..)?\x74(.)\xF0\x80.(?:\xE5\x24(?:\x90..)?\xB4\x97.(?:\x90..)?\x74(.)\xF0\x80.)?\x74(.)\xF0/s)
	{
		@table_cnt[$MEDIA_TYPE_DVD_PR, $MEDIA_TYPE_DVD_PR9, $MEDIA_TYPE_DVD_PRW] = (ord($1), ord($2), ord($3));
	}

	##
	# Find the dash table locations and addresses.
	#
	# Observed lengths of wildcard segments...
	# Segment 1: 33-45 ~ Between -RW and -R
	# Segment 2: 26-26 ~ Before the XOR
	#
	if ($ddata =~ /$dpat.{29,49}?$dpat.{22,30}?\x90..\xE0\xFF\xC3\x94\x08[\x40\x50]/s)
	{
		$table_loc[$MEDIA_TYPE_DVD_DR]  = $Current{'media_dbank'} + be16b2int("$4$3");
		$table_loc[$MEDIA_TYPE_DVD_DRW] = $Current{'media_dbank'} + be16b2int("$2$1");
	}

	if ($ddata =~ /\x30..\x30..\x90..\x74(.)\xF0.{0,8}?\x80.\x90..\x74(.)\xF0/s)
	{
		@table_cnt[$MEDIA_TYPE_DVD_DR, $MEDIA_TYPE_DVD_DRW] = (ord($2), ord($1));
	}

	##
	# For those who get the joys of reading the debug output...
	#
	foreach $media_type (@{$MEDIA_TYPES[$MEDIA_TYPE_DVD_P]}, @{$MEDIA_TYPES[$MEDIA_TYPE_DVD_D]})
	{
		op_dbgout("media_parse_s1s", sprintf("%-3s, loc=%05X, n=%2d", $MEDIA_TYPE_NAME[$media_type], $table_loc[$media_type], $table_cnt[$media_type])) if ($table_loc[$media_type]);
	}

	##
	# Process plus entries...
	#
	foreach $media_type (@{$MEDIA_TYPES[$MEDIA_TYPE_DVD_P]})
	{
		next unless ($table_loc[$media_type]);

		my($isR9) = ($media_type == $MEDIA_TYPE_DVD_PR9);

		for ($i = 0; $i < $table_cnt[$media_type]; ++$i)
		{
			push( @{$table},
			[
				$media_type,
				$i,
				{
					MID => media_makefield([ $MEDIA_DATA_STR, 1 ], 8, $table_loc[$media_type] + $plus_len * $i + 0x00, ($isR9) ? $plus_len : 0),
					TID => media_makefield([ $MEDIA_DATA_STR, 1 ], 3, $table_loc[$media_type] + $plus_len * $i + 0x10, ($isR9) ? $plus_len : 0),
					RID => media_makefield([ $MEDIA_DATA_INT, 1 ], 1, $table_loc[$media_type] + $plus_len * $i + 0x16, ($isR9) ? $plus_len : 0),
					SPD => media_makefield([ $MEDIA_DATA_INT, 1 ], 1, $table_loc[$media_type] + $plus_len * $i + 0x18, ($isR9) ? $plus_len : 0),
				}
			] );

			++$i if ($isR9);
		}
	}

	##
	# Process dash entries...
	#
	foreach $media_type (@{$MEDIA_TYPES[$MEDIA_TYPE_DVD_D]})
	{
		next unless ($table_loc[$media_type]);

		for ($i = 0; $i < $table_cnt[$media_type]; ++$i)
		{
			push( @{$table},
			[
				$media_type,
				$i,
				{
					MID => media_makefield([ $MEDIA_DATA_STR, 0 ], 12, $table_loc[$media_type] + $dash_len * $i + 0x00, 0),
					RID => media_makefield([ $MEDIA_DATA_INT, 0 ], 1, $table_loc[$media_type] + $dash_len * $i + 0x0C, 0),
					SPD => media_makefield([ $MEDIA_DATA_INT, 0 ], 1, $table_loc[$media_type] + $dash_len * $i + 0x0D, 0),
				}
			] );
		}
	}
}

sub media_parse_s3s # ( &table )
{
	my($table) = @_;

	my($prdata, $prwdata, @prloops, @prwloops);
	my($drdata, $drwdata, @drloops, @drwloops);
	my(@total_codes, @subtables, @banks);
	my($mulpat) = '(?:\xC3\x94(.)\x50..{0,16}?)?[\xEC-\xEF]?\x75\xF0([\x1A\x0E\x1C])[\xEC-\xEF]?\xA4\x24(.)\xF5\x82(?:\xE5\xF0|\xE4)\x34(.)\xF5\x83';

	# Format of @tables3s:
	# type(0), table_start(1), table_entries(2), table_entry_len(3), id_offset(4)
	my(@tables3s);

	# Initialize banks
	{
		$banks[$MEDIA_TYPE_DVD_PR] = $banks[$MEDIA_TYPE_DVD_PR9] = $Current{'media_pbank'};
		$banks[$MEDIA_TYPE_DVD_DR] = $banks[$MEDIA_TYPE_DVD_DR9] = $Current{'media_dbank'};

		$banks[$MEDIA_TYPE_DVD_PRW] = $banks[$MEDIA_TYPE_DVD_PR] + 0x10000;
		$banks[$MEDIA_TYPE_DVD_DRW] = $banks[$MEDIA_TYPE_DVD_DR] + 0x10000;

		$prdata = substr($Current{'fw'}, $banks[$MEDIA_TYPE_DVD_PR], 0x10000);
		$drdata = substr($Current{'fw'}, $banks[$MEDIA_TYPE_DVD_DR], 0x10000);

		$prwdata = substr($Current{'fw'}, $banks[$MEDIA_TYPE_DVD_PRW], 0x10000);
		$drwdata = substr($Current{'fw'}, $banks[$MEDIA_TYPE_DVD_DRW], 0x10000);
	}

	# Phase 1: Find the number of total media codes
	{
		op_dbgout("media_parse_s3s", "Searching for type count indicators");

		my($pat_size);
		my(@pat_size_template) =
		(
			'(?:\xE5\x24\xB4\x%02X.(?:\x90..%s)\x74(.)\xF0\x80\x0B)%s\xE5\x24\xB4\x%02X\x06\x90..\x74(.)\xF0',
			'\x90..\x74(.)\xF0\x90..\x74[\x00-0x02\xFF]\xF0\x90..\xE0\x54\x7F\xF0',
		);

		# +R/9
		if ($pat_size = sprintf($pat_size_template[0], 0x94, '|\x90..\xE0\x90..\x60.\x74.\xF0\x80.', '', 0x97), $prdata =~ /$pat_size/s)
		{
			$total_codes[$MEDIA_TYPE_DVD_PR] = ord($1);
			$total_codes[$MEDIA_TYPE_DVD_PR9] = ord($2);
			op_dbgout("media_parse_s3s", sprintf("... Total for +R/9: 0x%02X / 0x%02X", $total_codes[$MEDIA_TYPE_DVD_PR], $total_codes[$MEDIA_TYPE_DVD_PR9]));
		}
		else { return; }

		# +RW
		if ($pat_size = sprintf($pat_size_template[0], 0x00, '', '?', 0x8C), $prwdata =~ /$pat_size/s)
		{
			$total_codes[$MEDIA_TYPE_DVD_PRW] = ord($2);
			op_dbgout("media_parse_s3s", sprintf("... Total for +RW:  0x%02X", $total_codes[$MEDIA_TYPE_DVD_PRW]));
		}
		else { return; }

		# -R/9
		if ($pat_size = sprintf($pat_size_template[0], 0x90, '', '', 0x93), $drdata =~ /$pat_size/s)
		{
			$total_codes[$MEDIA_TYPE_DVD_DR] = ord($1);
			$total_codes[$MEDIA_TYPE_DVD_DR9] = ord($2);
			op_dbgout("media_parse_s3s", sprintf("... Total for -R/9: 0x%02X / 0x%02X", $total_codes[$MEDIA_TYPE_DVD_DR], $total_codes[$MEDIA_TYPE_DVD_DR9]));
		}
		elsif ($pat_size = sprintf($pat_size_template[0], 0x00, '', '?', 0x90), $drdata =~ /$pat_size/s)
		{
			$total_codes[$MEDIA_TYPE_DVD_DR] = ord($2);
			op_dbgout("media_parse_s3s", sprintf("... Total for -R/9: 0x%02X / 0x%02X", $total_codes[$MEDIA_TYPE_DVD_DR], $total_codes[$MEDIA_TYPE_DVD_DR9]));
		}
		else { return; }

		# -RW
		if ($pat_size = sprintf($pat_size_template[0], 0x00, '', '?', 0x88), $drwdata =~ /$pat_size/s)
		{
			$total_codes[$MEDIA_TYPE_DVD_DRW] = ord($2);
			op_dbgout("media_parse_s3s", sprintf("... Total for -RW:  0x%02X", $total_codes[$MEDIA_TYPE_DVD_DRW]));
		}
		elsif ($drwdata =~ /$pat_size_template[1]/s)
		{
			$total_codes[$MEDIA_TYPE_DVD_DRW] = ord($1);
			op_dbgout("media_parse_s3s", sprintf("... Total for -RW:  0x%02X", $total_codes[$MEDIA_TYPE_DVD_DRW]));
		}
		else { return; }
	}

	# Phase 2: Gather loops
	foreach my $param ( [ \$prdata, \@prloops ], [ \$prwdata, \@prwloops ],
	                    [ \$drdata, \@drloops ], [ \$drwdata, \@drwloops ] )
	{
		while (${$param->[0]} =~ /$mulpat/sg)
		{
			# Entry format: [ found_pos(0), running_total(1), entry_len(2), start_offset(3) ]
			push(@{$param->[1]}, [ pos(${$param->[0]}), ord($1), ord($2), be16b2int("$4$3") ]);
		}
	}

	# Phase 3: Trim and check the loops
	{
		# Note that this ASSUMES that the R and RW tables are broken into 3 subtables
		# and that the R9 tables are broken into 1 subtable!
		#
		# If this assumption proves false at some point in time, one possible remedy
		# would be to use the running total offset as a hash key with an associated
		# hash value equal to the start dptr; if a repeated hash key is found to have
		# a hash value within a certain constant (entry length) of the existing hash
		# value, then we know that we've reached the end of a set of subtables.
		#

		shift(@prloops) if ($prloops[0][1] == 0);

		($prloops[0][1] && $prloops[1][1] && ($prloops[2][1] == 0 || $prloops[2][1] == $total_codes[$MEDIA_TYPE_DVD_PR])) ?
			$subtables[$MEDIA_TYPE_DVD_PR] = [ @prloops[0 .. 2] ] :
			return;

		($prwloops[0][1] && $prwloops[1][1] && ($prwloops[2][1] == 0 || $prwloops[2][1] == $total_codes[$MEDIA_TYPE_DVD_PRW])) ?
			$subtables[$MEDIA_TYPE_DVD_PRW] = [ @prwloops[0 .. 2] ] :
			return;

		($drloops[0][1] && $drloops[1][1] && ($drloops[2][1] == 0 || $drloops[2][1] == $total_codes[$MEDIA_TYPE_DVD_DR])) ?
			$subtables[$MEDIA_TYPE_DVD_DR] = [ @drloops[0 .. 2] ] :
			return;

		($drwloops[0][1] && $drwloops[1][1] && ($drwloops[2][1] == 0 || $drwloops[2][1] == $total_codes[$MEDIA_TYPE_DVD_DRW])) ?
			$subtables[$MEDIA_TYPE_DVD_DRW] = [ @drwloops[0 .. 2] ] :
			return;

		($prloops[3][1] == 0 || $prloops[3][1] == $total_codes[$MEDIA_TYPE_DVD_PR9]) ?
			$subtables[$MEDIA_TYPE_DVD_PR9] = [ $prloops[3] ] :
			return;

		($drloops[3][1] == 0 || $drloops[3][1] == $total_codes[$MEDIA_TYPE_DVD_DR9]) ?
			$subtables[$MEDIA_TYPE_DVD_DR9] = [ $drloops[3] ] :
			return if ($total_codes[$MEDIA_TYPE_DVD_DR9]);
	}

	# Phase 4: Make the subtables useful
	op_dbgout("media_parse_s3s", "Listing of the (sub-)tables");

	foreach my $type (@{$MEDIA_TYPES[$MEDIA_TYPE_DVD_P]}, @{$MEDIA_TYPES[$MEDIA_TYPE_DVD_D]})
	{
		my($prev_rtotal) = 0;
		my($bank);

		foreach $subtable (@{$subtables[$type]})
		{
			$subtable->[1] = $total_codes[$type] unless($subtable->[1]);

			push(@tables3s, [ $type, $banks[$type] + $subtable->[3] + $subtable->[2] * $prev_rtotal, $subtable->[1] - $prev_rtotal, $subtable->[2], $prev_rtotal ]);
			$prev_rtotal = $subtable->[1];

			op_dbgout("media_parse_s3s", sprintf("... %-3s, fw=%06X, loc=%06X, n=%2d, len=%02d", $MEDIA_TYPE_NAME[$type], $banks[$type] + $subtable->[0], @{$tables3s[-1]}[1 .. 3]));
		}
	}

	# Phase 5: Convert this into the standard format
	foreach my $entry (@tables3s)
	{
		my($id_offset) = $entry->[4];
		my($encoding) = ($entry->[3] > 0x14) ? 1 : 0;

		if (media_istype($entry->[0], $MEDIA_TYPE_DVD_P))
		{
			for ($i = 0; $i < $entry->[2]; ++$i )
			{
				push( @{$table},
				[
					$entry->[0],
					$i + $id_offset,
					{
						MID => media_makefield([ $MEDIA_DATA_STR, $encoding ], 8, $entry->[1] + $entry->[3] * $i + (0x00 << $encoding), 0),
						TID => media_makefield([ $MEDIA_DATA_STR, $encoding ], 3, $entry->[1] + $entry->[3] * $i + (0x08 << $encoding), 0),
						RID => media_makefield([ $MEDIA_DATA_INT, $encoding ], 1, $entry->[1] + $entry->[3] * $i + (0x0B << $encoding), 0),
						SPD => media_makefield([ $MEDIA_DATA_INT, $encoding ], 1, $entry->[1] + $entry->[3] * $i + (0x0C << $encoding), 0),
					}
				] );
			}
		}
		else
		{
			for ($i = 0; $i < $entry->[2]; ++$i )
			{
				push( @{$table},
				[
					$entry->[0],
					$i + $id_offset,
					{
						MID => media_makefield([ $MEDIA_DATA_STR, $encoding ], 12, $entry->[1] + $entry->[3] * $i + (0x00 << $encoding), 0),
						RID => media_makefield([ $MEDIA_DATA_INT, $encoding ],  1, $entry->[1] + $entry->[3] * $i + (0x0C << $encoding), 0),
						SPD => media_makefield([ $MEDIA_DATA_INT, $encoding ],  1, $entry->[1] + $entry->[3] * $i + (0x0D << $encoding), 0),
					}
				] );
			}

		} # End: if plus or dash

	} # End: for each entry in @tables3s
}

sub media_save_changes # ( )
{
	return if ($Current{'fw_type'} ne 'dvdrw');

	my($code, $temp);

	foreach $code (@{$Current{'media_table'}})
	{
		media_makechange($code->[2]{'MID'}, $code->[4]{'MID'});
		media_makechange($code->[2]{'TID'}, $code->[4]{'TID'}) if (exists($code->[2]{'TID'}));
		media_makechange($code->[2]{'RID'}, $code->[4]{'RID'});
		media_makechange([ media_stdspd2spd($code->[2]{'SPD'}[0]), @{$code->[2]{'SPD'}}[1 .. 3] ], media_stdspd2spd($code->[4]{'SPD'}));
	}
}

1;
