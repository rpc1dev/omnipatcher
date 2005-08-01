##
# OmniPatcher for Optical Drives
# Firmware : DVD read speeds
#
# Modified: 2005/07/22, C64K
#

sub fw_rs_parse # ( )
{
	if (($Current{'fw_rs_status'} = fw_rs_patch(1, 1)) >= 0)
	{
		##
		# Tell the debug stream what info it has gathered
		#
		map { op_dbgout("fw_rs_parse", sprintf("%-9s points: %s", $FW_RS_NAME[$_], join(", ", map { sprintf("%05X", $_) } @{$Current{'fw_rs'}->[$_][2]}))) } (@FW_RS_IDX);

		if ($Current{'fw_rs_status'} == 0x01 || $Current{'fw_rs_status'} == 0x03)
		{
			# Special case: read from the special global variable
			#
			foreach my $i (@FW_RS_IDX)
			{
				$Current{'fw_rs'}->[$i][0] = $Current{'fw_rs'}->[$i][1] = $Current{'fw_rs_initialspds'}->[$i];
			}
		}
		else
		{
			foreach my $i (@FW_RS_IDX)
			{
				$Current{'fw_rs'}->[$i][0] = $Current{'fw_rs'}->[$i][1] = ord(substr($Current{'fw'}, $Current{'fw_rs'}->[$i][2][0], 1));
			}
		}

		map { $FW_RS_SPD2IDX[$_] = $FW_RS_SPD2IDX_ } @FW_RS_IDX;
		map { $FW_RS_IDX2SPD[$_] = $FW_RS_IDX2SPD_ } @FW_RS_IDX;

		if ($Current{'fw_manuf'} eq 'lo' && $Current{'fw_type'} eq 'dvdrw' && $Current{'fw_gen'} >= 0x033 && $Current{'fw_gen'} < 0x040)
		{
			# 3S-v2
			#
			$FW_RS_SPD2IDX[$FW_RS_DVDROM] = $FW_RS_SPD2IDX[$FW_RS_DVD9] = $FW_RS_SPD2IDX_1014;
			$FW_RS_IDX2SPD[$FW_RS_DVDROM] = $FW_RS_IDX2SPD[$FW_RS_DVD9] = $FW_RS_IDX2SPD_1014;

			if (($Current{'fw_rs_status'} & 0x0F) == 0x02)
			{
				# Type 2 routine
				#
				$FW_RS_SPD2IDX[$FW_RS_DVDR] = $FW_RS_SPD2IDX[$FW_RS_DVDRW] = $FW_RS_SPD2IDX[$FW_RS_DVDR9] = $FW_RS_SPD2IDX_10;
				$FW_RS_IDX2SPD[$FW_RS_DVDR] = $FW_RS_IDX2SPD[$FW_RS_DVDRW] = $FW_RS_IDX2SPD[$FW_RS_DVDR9] = $FW_RS_IDX2SPD_10;
			}
		}
		elsif ($Current{'fw_manuf'} eq 'lo' && $Current{'fw_type'} ne 'dvdrw')
		{
			# DVD-ROM/Combo
			#
			map { $FW_RS_SPD2IDX[$_] = $FW_RS_SPD2IDX_1014 } @FW_RS_IDX;
			map { $FW_RS_IDX2SPD[$_] = $FW_RS_IDX2SPD_1014 } @FW_RS_IDX;
		}
	}
	else
	{
		$Current{'fw_rs_status'} = -1;
	}
}

sub fw_rs_save # ( )
{
	return if ($Current{'fw_rs_status'} < 0);

	my($changed) = 0;

	foreach my $rs (@{$Current{'fw_rs'}})
	{
		$changed = 1 if ($rs->[0] != $rs->[1]);
	}

	return unless ($changed);

	fw_rs_patch(0, 1) if ($Current{'fw_rs_status'} == 0x01 || $Current{'fw_rs_status'} == 0x03);

	foreach my $rs (@{$Current{'fw_rs'}})
	{
		foreach my $loc (@{$rs->[2]})
		{
			substr($Current{'fw'}, $loc, 1, chr($rs->[1]));
		}
	}
}

sub fw_rs_patch # ( testmode, patchmode )
{
	##
	# Because this is not a standard patch function, the return
	# codes are a bit different...
	#   -1 = unpatchable (as before)
	# 0x01 = Type 1 (DVDRW-v1), unpatched
	# 0x11 = Type 1 (DVDRW-v1), patched
	# 0x02 = Type 2 (DVDRW-v2)
	# 0x03 = Type 3 (DVDROM/C), unpatched
	# 0x13 = Type 3 (DVDROM/C), patched
	#
	return fw_rs_patch_lo_w(@_) if ($Current{'fw_manuf'} eq 'lo' && ($Current{'fw_type'} eq 'dvdrw'));
	return fw_rs_patch_lo_d(@_) if ($Current{'fw_manuf'} eq 'lo' && ($Current{'fw_type'} eq 'dvdrom' || $Current{'fw_type'} eq 'combo'));
	return -1;
}

sub fw_rs_patch_lo_w # ( testmode, patchmode )
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

	my($bank) = substr(${$fw}, $Current{'fw_rbank'}, 0x10000);

	if ($bank =~ /(?#1)((?:\x02(?#2:insert_addr)(\xFF.)\x00|\xE5\x24\x24\x7E)(?#type_detection)(?#type82)(?:\x60.)\x14(?#type83)(?:\x60.).+?\x24.\x70.(?:(?#3:speed_assignment)((?:\x7F.\x80.)+)\x7F[\x01\x02](?!\x80)|.{146,162}?\x75\x3E.\xAF\x3E)(?#4:return_point)(.*?\x22))/sg)
	{
		# Type 1 function (401S thru 1673S)
		#
		my($patch_pt) = (pos($bank)) - length($1);
		my($insert_pt) = be16b2int($2);
		my($return_pt) = (pos($bank)) - length($4);
		my($speed_sel) = $3;

		op_dbgout("fw_rs_patch_lo_w", sprintf("Type 1 routine: loc=%05X, ins_pt=%04X, ret_pt=%04X, len=%d", $patch_pt + $Current{'fw_rbank'}, $insert_pt, $return_pt, length($1)));

		# Establish patch parameters
		#
		my($insert) = join '', map { chr }
		(
			#  0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
			0xE5, 0x24, 0x7F,    0, 0xB4, 0x80, 0x02, 0x80, 0x37, 0x7F,    0, 0xB4, 0x82, 0x02, 0x80, 0x30,
			0xB4, 0x83, 0x02, 0x80, 0x2B, 0x7F,    0, 0xB4, 0x90, 0x02, 0x80, 0x24, 0xB4, 0x94, 0x02, 0x80,
			0x1F, 0x7F,    0, 0xB4, 0x88, 0x02, 0x80, 0x18, 0xB4, 0x8C, 0x02, 0x80, 0x13, 0xB4, 0x8D, 0x02,
			0x80, 0x0E, 0x7F,    0, 0xB4, 0x93, 0x02, 0x80, 0x07, 0xB4, 0x97, 0x02, 0x80, 0x02, 0x7F, 0x01,
			0x02,    0,    0
		);

		my($insert_len) = length($insert);
		my($insert_ret_pt) = 0x41;
		my(@speed_pts);
		$speed_pts[$FW_RS_DVDROM] = 0x03;
		$speed_pts[$FW_RS_DVD9  ] = 0x0A;
		$speed_pts[$FW_RS_DVDR  ] = 0x16;
		$speed_pts[$FW_RS_DVDRW ] = 0x22;
		$speed_pts[$FW_RS_DVDR9 ] = 0x33;

		if ($insert_pt)
		{
			# If already patched
			#
			map { $Current{'fw_rs'}->[$_][2] = [ $Current{'fw_rbank'} + $insert_pt + $speed_pts[$_] ] } (@FW_RS_IDX) if ($testmode);
			return 0x11;
		}
		elsif ($bank =~ /\x00{2}(\x00{$insert_len}\x00{16})$/sg)
		{
			# If not patched, but patchable
			#
			$insert_pt = (pos($bank)) - length($1);
			op_dbgout("fw_rs_patch_lo_w", sprintf("... Patch insertion point set to %X", $insert_pt));

			# The standard parser function (see above) can't read the original
			# speeds because they are not stored in the patch insert location
			# so we have to save them to a special global variable that is used
			# only for parsing a 0x01 return from this patch function.
			#
			if ($testmode)
			{
				op_dbgout("fw_rs_patch_lo_w", sprintf("... Length of current speed area: %d", length($speed_sel)));

				if ($Current{'fw_gen'} >= 0x011 && $Current{'fw_gen'} < 0x040 && $speed_sel =~ /^\x7F(?#1)(.)\x80.\x7F(?#2)(.)\x80.(?:\x7F.\x80.)?\x7F(?#3)(.)\x80.\x7F(?#4)(.)\x80.\x7F(?#5)(.)\x80.\x7F(?#6)(.)\x80.$/s)
				{
					$Current{'fw_rs_initialspds'} = [ ord($1), ord($2), ord($6), ord($4), min(ord($2), ord($3)) ];
					op_dbgout("fw_rs_patch_lo_w", "... Parsing of current speed area successful: standard");
				}
				elsif ($Current{'fw_gen'} >= 0x121 && $Current{'fw_gen'} < 0x130 && $speed_sel =~ /^\x7F(?#1)(.)\x80.\x7F(?#2)(.)\x80.\x7F(?#3)(.)\x80.\x7F(?#4)(.)\x80.\x7F(?#5)(.)\x80.$/s)
				{
					$Current{'fw_rs_initialspds'} = [ ord($1), ord($2), ord($1), ord($4), ord($3) ];
					op_dbgout("fw_rs_patch_lo_w", "... Parsing of current speed area successful: 2S slimtype");
				}
				elsif ($Current{'fw_gen'} >= 0x111 && $Current{'fw_gen'} < 0x120 && $speed_sel =~ /^\x7F(?#1)(.)\x80.\x7F(?#2)(.)\x80.$/s)
				{
					$Current{'fw_rs_initialspds'} = [ ord($1), ord($2), ord($2), ord($2), $Current{'fw_rs_defaults'}->[$FW_RS_DVDR9] ];
					op_dbgout("fw_rs_patch_lo_w", "... Parsing of current speed area successful: 1S slimtype");
				}
				else
				{
					$Current{'fw_rs_initialspds'} = [ @{$Current{'fw_rs_defaults'}} ];
					op_dbgout("fw_rs_patch_lo_w", "... Parsing of current speed area failed; using defaults");
				}

				map { $Current{'fw_rs'}->[$_][2] = [ $Current{'fw_rbank'} + $insert_pt + $speed_pts[$_] ] } (@FW_RS_IDX);
			}

			# And now, patch
			#
			substr($insert, $insert_ret_pt, 2, int2be16b($return_pt));
			substr($bank, $insert_pt, $insert_len, $insert);
			substr($bank, $patch_pt, 4, chr(0x02) . int2be16b($insert_pt) . chr(0x00));
			substr(${$fw}, $Current{'fw_rbank'}, 0x10000, $bank);

			return 0x01;
		}
		else
		{
			# If not patched, and not patchable
			#
			op_dbgout("fw_rs_patch_lo_w", "... Cannot allocate space!");
			return -1;
		}
	}
	elsif ($bank =~ /(?#1)(\xE5\x24\x12..(?#2:table)((?:...){5,15}?)\x00{2}(?#3:table_default)(..))/sg)
	{
		# Type 2 function (starting with -R9)
		#
		my($rs_table) = $2;

		op_dbgout("fw_rs_patch_lo_w", sprintf("Type 2 routine: loc=%05X, tbl_len=%2d", $Current{'fw_rbank'} + (pos($bank)) - length($1), length($rs_table) / 3));

		if ($testmode)
		{
			for (my $i = 0; $i < length($rs_table); $i += 3)
			{
				my($id) = str2hex(substr($rs_table, $i + 2, 1));
				push(@{$Current{'fw_rs'}->[$FW_RS_LODVDRWID2TYPE{$id}][2]}, $Current{'fw_rbank'} + be16b2int(substr($rs_table, $i, 2)) + 1) if (exists($FW_RS_LODVDRWID2TYPE{$id}));
			}

			map { @{$Current{'fw_rs'}->[$_][2]} = makeset(@{$Current{'fw_rs'}->[$_][2]}) } @FW_RS_IDX;
		}

		return 0x02;
	}

	op_dbgout("fw_rs_patch_lo_w", "Sorry, can't find the function!");

	return -1;
}

sub fw_rs_patch_lo_d # ( testmode, patchmode )
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

	my($found, $bank, $pt_patch, $pt_return, $pt_insert, $dptr_bt, $dptr_rs, $dlbyte);

	my($default_ins_pt) = 0xFF80;
	my($combo_header) = '\x90..\xE0\xFF\xC4\x13\x13\x54\x03\x30\xE0\x0C\x90..\xE0\xD3\x94\x20\x40\x03\x74\x20\xF0(?:\x30..|\x20..\x02..)';

	if (${$fw} =~ /$combo_header\x90(?#1:dptr_bt)(..)\xE0(?#2:region-func_params)((?:\xFF\x70.|\x02(?#3:insert_pt)(\xFF.))\x30(?#4:dlbyte)(.).\x90(?#5:dptr_rs)(..))(?#6:region-func_body)(.{227,318}?)(?#7:region-func_end)(\x90(?#8:dptr_rs)(..)\xE0\x90..\xF0\xE4\x90..\xF0\x22)/sg)
	{
		# Combo pattern matched
		# Note: observed wildcard lengths: 243 (KH0K) thru 302 (R$07); value in pattern is this +/- 16

		return -1 if ($5 ne $8);	# Quit if the two dptr_rs values are not identical

		$found = 1;
		$bank = (pos(${$fw})) & 0xFF0000;
		$pt_return = ((pos(${$fw})) & 0xFFFF) - length($7);
		$pt_patch = $pt_return - length($2) - length($6);
		$pt_insert = be16b2int($3);
		$dptr_bt = be16b2int($1);
		$dptr_rs = be16b2int($5);
		$dlbyte = $4;

		op_dbgout("fw_rs_patch_lo_d", sprintf("Function found: type=%s, dptr_bt=%04X, wc_len=%d", "combo", $dptr_bt, length($6)));
	}
	elsif (${$fw} =~ /\x30(?#1:cdbyte)([\x04\x0C\x14\x1C\x24\x2C]).(?#2:region-wildcard)(.{17,37}?)(?#3:region-booktype)(\x78.\xE6|\x90(?#4:dptr_bt)(..)\xE0)(?#5:region-main)((?:\xFF\x64\x02|\x02(?#6:insert_pt)(\xFF.))\x60[\x04\x09].{4,9}?\x90(?#7:dptr_rs)(..)\xE0\xD3\x94\x08\x40\x03\x74\x08\xF0)/sg)
	{
		# ROM-v1 pattern matched
		# Note: observed wildcard lengths: 25 thru 29; value in pattern is this +/- 8

		$found = 1;
		$bank = (pos(${$fw})) & 0xFF0000;
		$pt_return = ((pos(${$fw})) & 0xFFFF);
		$pt_patch = $pt_return - length($5);
		$pt_insert = be16b2int($6);
		$dptr_bt = be16b2int($4);
		$dptr_rs = be16b2int($7);
		$dlbyte = chr((ord($1) & 0xF8) | 00);

		op_dbgout("fw_rs_patch_lo_d", sprintf("Function found: type=%s, dptr_bt=%04X, wc_len=%d", "dvdrom1", $dptr_bt, length($2)));
	}
	elsif (${$fw} =~ /\x30(?#1:dvdbyte)(.).\x90(?#2:dptr_bt)(..)\xE0(?#3:region-func_params)(\x60.\x24\xFD|\x02(?#4:insert_pt)(\xFF.)\xFD)(?#5:region-func_body)(.{38,70}?\x74\x10\xF0)(?#6:region-func_end)(\x90(?#7:dptr_rs)(..)\xE0\x90..\xF0)/sg)
	{
		# ROM-v2 pattern matched
		# Note: observed wildcard lengths: 54 thru 54; value in pattern is this +/- 16

		$found = 1;
		$bank = (pos(${$fw})) & 0xFF0000;
		$pt_return = ((pos(${$fw})) & 0xFFFF) - length($6);
		$pt_patch = $pt_return - length($3) - length($5);
		$pt_insert = be16b2int($4);
		$dptr_bt = be16b2int($2);
		$dptr_rs = be16b2int($7);
		$dlbyte = chr((ord($1) & 0xF8) | 01);

		op_dbgout("fw_rs_patch_lo_d", sprintf("Function found: type=%s, dptr_bt=%04X, wc_len=%d", "dvdrom2", $dptr_bt, length($5) - 3));
	}

	if ($found)
	{
		op_dbgout("fw_rs_patch_lo_d", sprintf("bank=%X, pPat=%04X, pRet=%04X, pIns=%04X, dRS=%04X, bDL=%02X", $bank >> 16, $pt_patch, $pt_return, $pt_insert, $dptr_rs, ord($dlbyte)));

		# Establish patch parameters
		#
		my($insert) = join '', map { chr }
		(
			#  0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
			0x90,    0,    0, 0xB4, 0x00, 0x0B, 0x20,    0, 0x04, 0x74,   0 , 0x80, 0x39, 0x74,   0 , 0x80,
			0x35, 0xB4, 0x01, 0x04, 0x74,   8 , 0x80, 0x2E, 0xB4, 0x02, 0x05, 0x20,    0, 0x1B, 0x80, 0x03,
			0xB4, 0x0A, 0x04, 0x74,   0 , 0x80, 0x1F, 0xB4, 0x03, 0x05, 0x20,    0, 0x13, 0x80, 0x03, 0xB4,
			0x09, 0x04, 0x74,   0 , 0x80, 0x10, 0xB4, 0x0E, 0x04, 0x74,   0 , 0x80, 0x09, 0xB4, 0x0D, 0x04,
			0x74,   8 , 0x80, 0x02, 0x74,   8 , 0xF0, 0x02,    0,    0
		);

		my(@speed_pts);
		$speed_pts[$FW_RS_DVDROM] = 0x0A;	# BT=0
		$speed_pts[$FW_RS_DVD9  ] = 0x0E;	# BT=0+DL=1
	#	$speed_pts[$FW_RS_DVDRAM] = 0x15;	# BT=1
		$speed_pts[$FW_RS_DVDR  ] = 0x24;	# BT=2, BT=A
		$speed_pts[$FW_RS_DVDRW ] = 0x33;	# BT=3, BT=9
		$speed_pts[$FW_RS_DVDR9 ] = 0x3A;	# BT=E, BT=2+DL=1
	#	$speed_pts[$FW_RS_DVDRW9] = 0x41;	# BT=D, BT=3+DL=1
	#	$speed_pts[$FW_RS_OTHER ] = 0x45;

		substr($insert, 0x01, 2, int2be16b($dptr_rs));
		substr($insert, 0x48, 2, int2be16b($pt_return));
		substr($insert, 0x07, 1, $dlbyte);
		substr($insert, 0x1C, 1, $dlbyte);
		substr($insert, 0x2B, 1, $dlbyte);

		if ($pt_insert)
		{
			# Already patched
			map { $Current{'fw_rs'}->[$_][2] = [ $bank + $pt_insert + $speed_pts[$_] ] } (@FW_RS_IDX) if ($testmode);
			return 0x13;
		}
		elsif (substr(${$fw}, $bank + $default_ins_pt - 2, length($insert) + 4) =~ /^(?:\x00*|0xFF*)$/s)
		{
			# Not patched
			$pt_insert = $default_ins_pt;
			$Current{'fw_rs_initialspds'} = [ @{$Current{'fw_rs_defaults'}} ];

			substr(${$fw}, $bank + $pt_patch, 3, chr(0x02) . int2be16b($pt_insert));
			substr(${$fw}, $bank + $pt_insert, length($insert), $insert);

			map { $Current{'fw_rs'}->[$_][2] = [ $bank + $pt_insert + $speed_pts[$_] ] } (@FW_RS_IDX) if ($testmode);
			return 0x03;
		}
		else
		{
			# Not patched and no space
			op_dbgout("fw_rs_patch_lo_d", "... Cannot allocate space!");
			return -1;
		}
	}

	op_dbgout("fw_rs_patch_lo_d", "Sorry, can't find the function!");

	return -1;
}

sub fw_rs_proc # ( dropid, itemid )
{
	my($dropid, $itemid) = @_;
	$Current{'fw_rs'}->[$dropid][1] = $FW_RS_IDX2SPD[$dropid][$itemid];
}

1;
