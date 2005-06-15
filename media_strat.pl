##
# OmniPatcher for LiteOn DVD-Writers
# Media : Write strategy reassignment
#
# Modified: 2005/06/14, C64K
#

sub media_strat_init # ( )
{
	##
	# Check the status flag area
	#
	if ( substr($Current{'fw'}, $MEDIA_STRAT_REVLOC - 8, 8) eq chr(0x00) x 8 &&
	     substr($Current{'fw'}, $MEDIA_STRAT_REVLOC + 1, 1) eq chr(0x00) )
	{
		$Current{'media_strat_status'} = ord(substr($Current{'fw'}, $MEDIA_STRAT_REVLOC, 1));
		op_dbgout("media_strat_init", sprintf("Status flag area is valid; flag value is: %d", $Current{'media_strat_status'}));

		if ($Current{'media_strat_status'} > 6)
		{
			$Current{'media_strat_status'} = -1;
			op_dbgout("media_strat_init", "FAILURE: Cannot interpret status flag!");
			return;
		}
	}
	else
	{
		$Current{'media_strat_status'} = -1;
		op_dbgout("media_strat_init", "FAILURE: Status flag area is invalid!");
		return;
	}

	op_dbgout("media_strat_init", "Status flag is good; now starting media_strat_p in test mode");

	##
	# Do the real work here...
	#
	$Current{'media_strat_status'} = media_strat_p(1, 1);

	op_dbgout("media_strat_init", sprintf("Final status/type flags: (%d, %d)", $Current{'media_strat_status'}, $Current{'media_strat_type'}));

	##
	# Read the strat indices from the firmware
	#
	my($type, $i, $idx);

	foreach $type ($MEDIA_TYPE_DVD_PR, $MEDIA_TYPE_DVD_DR)
	{
		if ($Current{'media_strat'}->[$type]{'status'} > 0)
		{
			op_dbgout("media_strat_init", "Loading strats for $MEDIA_TYPE_NAME[$type]");

			for ($i = $Current{'media_strat'}->[$type]{'table'}; ord(substr($Current{'fw'}, $i, 1)) != 0; $i += 2)
			{
				$idx = media_rawidx2idx($type, ord(substr($Current{'fw'}, $i, 1)));
				$Current{'media_table'}->[$idx][3] = ord(substr($Current{'fw'}, $i + 1, 1)) if ($idx >= 0);

			} # End: loop through the strat index table in the firmware

		} # End: is strat patching enabled for this type/bank?

	} # End: loop through the different types/banks
}

sub media_strat_save # ( )
{
	my(@strat_indices, $code, $type);

	foreach $code (@{$Current{'media_table'}})
	{
		$strat_indices[$code->[0]] .= chr($code->[1]) . chr($code->[3]) if ($code->[1] != $code->[3]);
	}

	if (length($strat_indices[$MEDIA_TYPE_DVD_PR]) || length($strat_indices[$MEDIA_TYPE_DVD_DR]))
	{
		media_strat_p(0, 1);

		foreach $type ($MEDIA_TYPE_DVD_PR, $MEDIA_TYPE_DVD_DR)
		{
			op_dbgout("media_strat_save", sprintf("Length of table for %s: %d", $MEDIA_TYPE_NAME[$type], length($strat_indices[$type])));

			if ($Current{'media_strat'}->[$type]{'status'} >= 0)
			{
				if (length($strat_indices[$type]) > $Current{'media_strat'}->[$type]{'table_maxlen'})
				{
					op_dbgout("media_strat_save", "... Table length is too long; snipping...");
					$strat_indices[$type] = substr($strat_indices[$type], 0, $Current{'media_strat'}->[$type]{'table_maxlen'});
				}

				op_dbgout("media_strat_save", "... Patch status is $Current{'media_strat'}->[$type]{'status'} and is valid; patching...");

				substr($Current{'fw'}, $Current{'media_strat'}->[$type]{'table'}, length($strat_indices[$type]), $strat_indices[$type]);
			}
		}
	}
	else
	{
		media_strat_p(0, 0);
	}
}

sub media_strat_p # ( testmode, patchmode )
{
	my($testmode, $patchmode) = @_;

	if ($Current{'media_strat_type'} == 5 || (substr($Current{'fw'}, $Current{'media_dbank'}, 0x10000) =~ /\xC2\xAF..\x0B..\x08\x90..\x74.\xF0\x80\x06\x90..\x74.\xF0/s))
	{
		# 1S/2S/3S-v1
		#
		$Current{'media_strat_type'} = 5;
		return media_strat_p1s(@_);
	}
	elsif ($Current{'media_strat_type'} == 6 || ($Current{'fw_gen'} >= 0x030 && $Current{'fw_gen'} < 0x040))
	{
		# 3S-v2
		#
		$Current{'media_strat_type'} = 6;
		return media_strat_p3s(@_);
	}
	else
	{
		return -1;
	}
}

sub media_strat_p1s # ( testmode, patchmode )
{
	my($testmode, $patchmode) = @_;

	##
	# Establish the framework for testmode
	#
	my($fw, $fw_testmode);

	if ($testmode)
	{
		$fw_testmode = $Current{'fw'};
		$fw = \$fw_testmode;
	}
	else
	{
		$fw = \$Current{'fw'};
	}

	##
	# Establish the patch information
	#
	my($base) = 0xFF00;

	my($template) = join '', map { chr }
	(
		#  0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
		0xC0, 0x82, 0xC0, 0x83, 0xFF, 0xE5, 0x24, 0xB4,    0, 0x12, 0x90, 0xFF,    0, 0xE4, 0x93, 0x60,
		0x0B, 0x6F, 0x60, 0x04, 0xA3, 0xA3, 0x80, 0xF5, 0x74, 0x01, 0x93, 0xFF, 0xEF, 0xD0, 0x83, 0xD0,
		0x82, 0xF0, 0x90,    0,    0, 0x22
	);

	my($template_offset_type) = 0x08;
	my($template_offset_table) = 0x0B;
	my($template_offset_dptr) = 0x23;

	my($insert_pattern) = '\xC0\x82\xC0\x83\xFF\xE5\x24\xB4[\x90\x94]\x12\x90(\xFF.)\xE4\x93\x60\x0B\x6F\x60\x04\xA3\xA3\x80\xF5\x74\x01\x93\xFF\xEF\xD0\x83\xD0\x82\xF0\x90(..)\x22';
	my($switch_pattern) = '\x90..\xE0\x64[\x0A\x0B\x0D\x0E](?:\x60\x03\x02..|\x70.)(?:\x90..|\xA3)\xE0([\x90\x12])(..)(\xF0)';

	##
	# Process each bank
	#
	foreach my $type ( [ $MEDIA_TYPE_DVD_PR, substr(${$fw}, $Current{'media_pbank'}, 0x10000), $Current{'media_pbank'}, chr(0x94) ],
	                   [ $MEDIA_TYPE_DVD_DR, substr(${$fw}, $Current{'media_dbank'}, 0x10000), $Current{'media_dbank'}, chr(0x90) ] )
	{
		op_dbgout("media_strat_p1s", "Processing the $MEDIA_TYPE_NAME[$type->[0]] bank");

		my($fail) = sub { $Current{'media_strat'}->[$type->[0]]{'status'} = -1; op_dbgout("media_strat_p1s", "... Error: $_[0]"); };

		my(@switch_points, $is_patched, $temp_addr);
		my($insert_pt, $table_pt, $dptr_val, $size_of_area);
		my($switch_pt, $insert, $potential_insert_area);

		# First, look for the "switch" pattern in the media lookup loops; there should be 2
		#
		while ($type->[1] =~ /$switch_pattern/sg)
		{
			push(@switch_points, (pos($type->[1])) - (length($1) + length($2) + length($3)));
			$is_patched = (!defined($is_patched)) ? $1 eq chr(0x12) : (($is_patched == ($1 eq chr(0x12))) ? $is_patched : -1);
			$temp_addr = (!defined($temp_addr)) ? unicode2int($2) : (($temp_addr == unicode2int($2)) ? $temp_addr : -1);
		}

		if ($#switch_points != 1 || $is_patched == -1 || $temp_addr == -1)
		{
			$fail->("The switch points do not look right!");
			next;
		}

		# And now, to take care of the patch insert point...
		#
		if ($is_patched)
		{
			op_dbgout("media_strat_p1s", "... This bank is already patched; looking for patch");
			$potential_insert_area = substr($type->[1], $base, 0x10000 - ($base + 0x10));

			# Read the patch to extract information
			#
			if ($potential_insert_area =~ /$insert_pattern/sg)
			{
				if (((pos($potential_insert_area)) - length($template) + $base) != $temp_addr)
				{
					$fail->("The patch is not in the right location; how odd!");
					next;
				}

				$insert_pt = $temp_addr;
				$table_pt = unicode2int($1);
				$dptr_val = unicode2int($2);
				$size_of_area = $base + length($potential_insert_area) - $insert_pt;
			}
			else
			{
				$fail->("Um, the patch can't be found!");
				next;
			}
		}
		else
		{
			op_dbgout("media_strat_p1s", "... This bank has not been patched");
			$potential_insert_area = substr($type->[1], $base - 2, 0x10000 - ($base + 0x10) + 2);

			# Search for a suitable patch spot
			#
			if ($potential_insert_area !~ /$insert_pattern/s && $potential_insert_area =~ /\x00{2}(\x00{60,})$/sg)
			{
				$size_of_area = length($1);
				$insert_pt = (pos($potential_insert_area)) - $size_of_area + ($base - 2);
				$table_pt = $insert_pt + length($template);
				$dptr_val = $temp_addr;
			}
			else
			{
				$fail->("Unable to allocate space!");
				next;
			}
		}

		# If we've made it this far, then we're good to go!
		#
		$Current{'media_strat'}->[$type->[0]]{'status'} = ($is_patched) ? $Current{'media_strat_type'} : 0;
		$Current{'media_strat'}->[$type->[0]]{'table'} = $table_pt + $type->[2];
		$Current{'media_strat'}->[$type->[0]]{'table_maxlen'} = ((($size_of_area - ($table_pt - $insert_pt)) >> 1) << 1);

		op_dbgout("media_strat_p1s", sprintf("... Insertion and table points: %04X / %04X", $insert_pt, $table_pt));
		op_dbgout("media_strat_p1s", sprintf("... Max table length: %3d bytes", $Current{'media_strat'}->[$type->[0]]{'table_maxlen'}));
		op_dbgout("media_strat_p1s", sprintf("... dptr value: %04X", $dptr_val));

		# Start by clearing away the region
		#
		substr($type->[1], $insert_pt, $size_of_area, chr(0x00) x $size_of_area);

		if ($patchmode == 0)
		{
			# Remove the patch
			#
			foreach $switch_pt (@switch_points)
			{
				substr($type->[1], $switch_pt, 3, chr(0x90) . int2unicode($dptr_val));
			}
		}
		else
		{
			# Apply the patch
			#
			foreach $switch_pt (@switch_points)
			{
				substr($type->[1], $switch_pt, 3, chr(0x12) . int2unicode($insert_pt));
			}

			$insert = $template;
			substr($insert, $template_offset_type, 1, $type->[3]);
			substr($insert, $template_offset_table, 2, int2unicode($table_pt));
			substr($insert, $template_offset_dptr, 2, int2unicode($dptr_val));
			substr($type->[1], $insert_pt, length($insert), $insert);
		}

		# Apply the changes to the firmware
		#
		substr(${$fw}, $type->[2], 0x10000, $type->[1]);

		op_dbgout("media_strat_p1s", "... Done!");

	} # End: for each media format

	my($status_code) = ($patchmode) ? $Current{'media_strat_type'} : 0;
	my($return_code) = max($Current{'media_strat'}->[$MEDIA_TYPE_DVD_PR]{'status'}, $Current{'media_strat'}->[$MEDIA_TYPE_DVD_DR]{'status'});

	substr(${$fw}, $MEDIA_STRAT_REVLOC, 1, chr($status_code)) if ($return_code >= 0);

	return $return_code;
}

sub media_strat_p3s # ( testmode, patchmode )
{
	my($testmode, $patchmode) = @_;

	##
	# Establish the framework for testmode
	#
	my($fw, $fw_testmode);

	if ($testmode)
	{
		$fw_testmode = $Current{'fw'};
		$fw = \$fw_testmode;
	}
	else
	{
		$fw = \$Current{'fw'};
	}

	##
	# Establish the patch information
	#
	my($template) = join '', map { chr }
	(
		#  0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
		0x24, 0x40, 0x24, 0x40, 0x24, 0x40, 0xFF, 0x90, 0xFF,    0, 0xE4, 0x93, 0x60, 0x0B, 0x6F, 0x60,
		0x04, 0xA3, 0xA3, 0x80, 0xF5, 0x74, 0x01, 0x93, 0xFF, 0xEF, 0x75, 0xF0, 0x40, 0x84, 0xFE, 0xE5,
		0xF0, 0x90,    0,    0, 0xBE, 0x00, 0x03, 0x02,    0,    0, 0xBE, 0x01, 0x03, 0x02,    0,    0,
		0xBE, 0x02, 0x03, 0x02,    0,    0, 0x02,    0,    0
	);

	my($template_offset_table) = 0x08;
	my($template_offset_dptr) = 0x22;
	my(@template_offset_ret) = (0x28, 0x2E, 0x34, 0x37);

	my($switch_pattern) = '(?:(?:\x90..|\xA3)\xE0(?:\x90..|\x02\xFF.)|(?:\x90..[\xE8-\xEF]|[\xE8-\xEF]\x02\xFF.))\xF0';

	##
	# Process each bank
	#
	TYPELOOP: foreach my $type ( [ $MEDIA_TYPE_DVD_PR, substr(${$fw}, $Current{'media_pbank'}, 0x10000), $Current{'media_pbank'}, $Current{'media_pstrat_pts'} ],
	                             [ $MEDIA_TYPE_DVD_DR, substr(${$fw}, $Current{'media_dbank'}, 0x10000), $Current{'media_dbank'}, $Current{'media_dstrat_pts'} ] )
	{
		op_dbgout("media_strat_p3s", "Processing the $MEDIA_TYPE_NAME[$type->[0]] bank");

		my($fail) = sub { $Current{'media_strat'}->[$type->[0]]{'status'} = -1; op_dbgout("media_strat_p3s", "... Error: $_[0]"); };

		my($insert_pt, $table_pt, $size_of_area);

		my(@patch_points_raw, @patch_points, @return_points, @patch_entry_points);
		my($pat_area, $pat_point, $pat_type);
		my($is_patched, $dptr_val, $insert);

		# Reasons why we should stop right now...
		#
		if ($#{$type->[3]} >= 4)
		{
			$fail->("But Captain, she can't handle more than four tables!");
			next TYPELOOP;
		}

		# Now, we should find out if this bank has already been patched, and
		# if not, we need to allocate space for the patch.
		#
		my($rev_flag) = ord(substr(${$fw}, $MEDIA_STRAT_REVLOC, 1));

		if ($rev_flag == 2 || $rev_flag == 4)
		{
			op_dbgout("media_strat_p3s", "... This bank is patched with a legacy function");
			$is_patched = 1;

			$size_of_area = 0xF0;
			$insert_pt = 0xFF00;
			$table_pt = 0xFF40;
			$dptr_val = unicode2int(substr($type->[1], ($rev_flag == 2) ? 0xFF29 : 0xFF22, 2));
		}
		elsif ($rev_flag == 6 && $type->[1] =~ /(\x24\x40\x24\x40\x24\x40\xFF\x90)(\xFF.)/sg)
		{
			op_dbgout("media_strat_p3s", "... This bank is patched; determining parameters");
			$is_patched = 1;

			$size_of_area = 0xF0;
			$insert_pt = (pos($type->[1])) - (length($1) + length($2));
			$table_pt = unicode2int($2);
			$dptr_val = unicode2int(substr($type->[1], $insert_pt + $template_offset_dptr, 2));
		}
		else
		{
			if ($patchmode == 0)
			{
				op_dbgout("media_strat_p3s", "... No need to unpatch an unpatched bank");
				next TYPELOOP;
			}

			op_dbgout("media_strat_p3s", "... This bank is unpatched; finding space");
			$is_patched = 0;

			my($potential_insert_area) = substr($type->[1], 0xFF00 - 2, 0xF0 + 2);

			# Search for a suitable patch spot
			#
			if ($potential_insert_area =~ /\x00{2}(\x00{64,})$/sg)
			{
				$size_of_area = length($1);
				$insert_pt = (pos($potential_insert_area)) - $size_of_area + (0xFF00 - 2);
				$table_pt = $insert_pt + length($template);
			}
			else
			{
				$fail->("Unable to allocate space!");
				next TYPELOOP;
			}
		}

		# Let's gather together a list of all the patch points... remember that $type->[0]
		# contains *pairs* of patch points because some tables have two patch points!
		#
		# Format: [ point address, which table it is for, is it the first in a pair ]
		#
		foreach my $i (0 .. $#{$type->[3]})
		{
			# If there is supposed to be a second patch point, but the parser didn't find it,
			# then that patch point will show up as 0xFFFF
			#
			if ($type->[3][$i][1] == 0xFFFF)
			{
				$fail->("Oops, we got an invalid second patch point!");
				next TYPELOOP;
			}

			push(@patch_points_raw, [ $type->[3][$i][0], $i, 1 ]);
			push(@patch_points_raw, [ $type->[3][$i][1], $i, 0 ]) if ($type->[3][$i][1] > 0);
		}

		@patch_entry_points = map { $insert_pt + $_ } (0x06, 0x04, 0x02, 0x00);

		# NOW, we can finally go through and process each patch point
		#
		foreach my $raw_point (@patch_points_raw)
		{
			# Now, for each patch point, pat_area is the region of bytes that are of
			# interest and that we want to work with... but before we do that, we need
			# to re-arrange this area of the firmware, if needed, to make it usable
			#
			$pat_area = substr($type->[1], $raw_point->[0], 9);

			if ($patchmode && $pat_area =~ s/^((?:\x90..|\xA3)\xE0)([\xF8-\xFF])(\x90..\xF0)(.*)$/$1$3$2$4/s)
			{
				# Re-arrangement of pat_area is needed, so make it so!
				#
				substr($type->[1], $raw_point->[0], length($pat_area), $pat_area);
			}

			# Get the area of interest
			#
			$pat_area = substr($type->[1], $raw_point->[0], 8);

			if ($pat_area =~ /^($switch_pattern)/sg)
			{
				# Interpret the results
				#
				if (length($1) > 5)
				{
					$pat_point = $raw_point->[0] + (pos($pat_area)) - 4;
					$pat_type = 0;
					$pat_ex = '';
				}
				elsif (length($1) == 5)
				{
					$pat_point = $raw_point->[0] + (pos($pat_area)) - 5;
					$pat_type = 1;
					$pat_ex = substr($pat_area, (substr($pat_area, 0, 1) eq chr(0x90)) ? 3 : 0, 1);
				}
				else
				{
					$fail->(sprintf("Unexpected error with patch point %04X", $raw_point->[0]));
					next TYPELOOP;
				}

				# Deal with the dptr value as necessary
				#
				if (!$is_patched && $dptr_val == 0)
				{
					$dptr_val = unicode2int(substr($type->[1], $pat_point + 1, 2));
				}
				elsif (!$is_patched && $dptr_val != unicode2int(substr($type->[1], $pat_point + 1, 2)))
				{
					$fail->(sprintf("Unexpected dptr mismatch with patch point %04X", $raw_point->[0]));
					next TYPELOOP;
				}

				# We have now converted this raw patch point into a processed patch point!
				#
				push( @patch_points, [
					$pat_point,										# Location to patch
					$patch_entry_points[$raw_point->[1]],	# Which entry point into the patch insert to use?
					$pat_type,										# What kind of layout does the bytes in this patch area have?
					$pat_ex											# Extended info
				] );

				# And now, we should add this patch point to the list of addresses the
				# patch insert will return to at its end.
				#
				push( @return_points, [
					$template_offset_ret[$raw_point->[1]],	# Which return point will this patch point be assigned?
					$pat_point + (($pat_type) ? 4 : 3)		# Where exactly should the return jump to go?
				] ) if ($raw_point->[2]);
			}
			else
			{
				$fail->(sprintf("Unrecognized pattern with patch point %04X", $raw_point->[0]));
				next TYPELOOP;
			}

		} # End: loop through the potential patch points

		# If we've made it this far, then we're good to go!
		#
		$Current{'media_strat'}->[$type->[0]]{'status'} = ($is_patched) ? $Current{'media_strat_type'} : 0;
		$Current{'media_strat'}->[$type->[0]]{'table'} = $table_pt + $type->[2];
		$Current{'media_strat'}->[$type->[0]]{'table_maxlen'} = ((($size_of_area - ($table_pt - $insert_pt)) >> 1) << 1);

		op_dbgout("media_strat_p3s", sprintf("... Insertion and table points: %04X / %04X", $insert_pt, $table_pt));
		op_dbgout("media_strat_p3s", sprintf("... Max table length: %3d bytes", $Current{'media_strat'}->[$type->[0]]{'table_maxlen'}));
		op_dbgout("media_strat_p3s", sprintf("... dptr value: %04X", $dptr_val));

		# Start by clearing away the region
		#
		substr($type->[1], $insert_pt, $size_of_area, chr(0x00) x $size_of_area);

		op_dbgout("media_strat_p3s", "... Say hello to our patch point finalists!");

		foreach $pat_point (@patch_points)
		{
			op_dbgout("media_strat_p3s", sprintf("... > pt=%04X, entry=%04X, type=%d, ex=%02X", $pat_point->[0], $pat_point->[1], $pat_point->[2], ord($pat_point->[3])));

			if ($patchmode == 0)
			{
				($pat_point->[2] == 0) ?
				substr($type->[1], $pat_point->[0], 3, chr(0x90) . int2unicode($dptr_val)) :
				substr($type->[1], $pat_point->[0], 4, chr(0x90) . int2unicode($dptr_val) . $pat_point->[3]);
			}
			else
			{
				($pat_point->[2] == 0) ?
				substr($type->[1], $pat_point->[0], 3, "\x02" . int2unicode($pat_point->[1])) :
				substr($type->[1], $pat_point->[0], 4, "$pat_point->[3]\x02" . int2unicode($pat_point->[1]));
			}
		}

		if ($patchmode)
		{
			$insert = $template;

			foreach my $ret_pt (@return_points)
			{
				op_dbgout("media_strat_p3s", sprintf("... > Return point: %02X->%04X", @{$ret_pt}));
				substr($insert, $ret_pt->[0], 2, int2unicode($ret_pt->[1]));
			}

			substr($insert, $template_offset_table, 2, int2unicode($table_pt));
			substr($insert, $template_offset_dptr, 2, int2unicode($dptr_val));
			substr($type->[1], $insert_pt, length($insert), $insert);
		}

		# Apply the changes to the firmware
		#
		substr(${$fw}, $type->[2], 0x10000, $type->[1]);

		op_dbgout("media_strat_p3s", "... Done!");

	} # End: for each media format

	my($status_code) = ($patchmode) ? $Current{'media_strat_type'} : 0;
	my($return_code) = max($Current{'media_strat'}->[$MEDIA_TYPE_DVD_PR]{'status'}, $Current{'media_strat'}->[$MEDIA_TYPE_DVD_DR]{'status'});

	substr(${$fw}, $MEDIA_STRAT_REVLOC, 1, chr($status_code)) if ($return_code >= 0);

	return $return_code;
}

1;
