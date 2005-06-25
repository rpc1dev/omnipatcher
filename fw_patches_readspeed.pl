##
# OmniPatcher for LiteOn DVD-Writers
# Firmware : DVD read speeds
#
# Modified: 2005/06/25, C64K
#

sub fw_rs_parse # ( )
{
	if (($Current{'fw_rs_status'} = fw_rs_patch(1, 1)) >= 0)
	{
		##
		# Tell the debug stream what info it has gathered
		#
		map { op_dbgout("fw_rs_parse", sprintf("%-7s points: ", $FW_RS_NAME[$_]) . join(", ", map { sprintf("%04X", $_) } @{$Current{'fw_rs'}->[$_][2]})) } (@FW_RS_IDX);

		if ($Current{'fw_rs_status'} == 0x01)
		{
			# Special case: read from the special global variable
			#
			foreach my $i (@FW_RS_IDX)
			{
				$Current{'fw_rs'}->[$i][0] = $Current{'fw_rs'}->[$i][1] = $Current{'fw_rs_type1parse'}->[$i];
			}
		}
		else
		{
			foreach my $i (@FW_RS_IDX)
			{
				$Current{'fw_rs'}->[$i][0] = $Current{'fw_rs'}->[$i][1] = ord(substr($Current{'fw'}, $Current{'fw_rs'}->[$i][2][0], 1));
			}
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

	fw_rs_patch(0, 1) if ($Current{'fw_rs_status'} == 0x01);

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
	# Because this is not a standard patch function, the return
	# codes are a bit different...
	#   -1 = unpatchable (as before)
	# 0x01 = Type 1, unpatched
	# 0x11 = Type 1, patched
	# 0x02 = Type 2
	#

	my($bank) = substr(${$fw}, $Current{'fw_rbank'}, 0x10000);

	if ($bank =~ /(?#1)((?:\x02(?#2:insert_addr)(\xFF.)\x00|\xE5\x24\x24\x7E)(?#type_detection)(?#type82)(?:\x60.)\x14(?#type83)(?:\x60.).+?\x24.\x70.(?:(?#3:speed_assignment)((?:\x7F.\x80.)+)\x7F[\x01\x02](?!\x80)|.{146,162}?\x75\x3E.\xAF\x3E)(?#4:return_point)(.*?\x22))/sg)
	{
		# Type 1 function (401S thru 1673S)
		#
		my($patch_pt) = (pos($bank)) - length($1);
		my($insert_pt) = unicode2int($2);
		my($return_pt) = (pos($bank)) - length($4);
		my($speed_sel) = $3;

		op_dbgout("fw_rs_patch", sprintf("Type 1 routine: loc=%05X, ins_pt=%04X, ret_pt=%04X, len=%d", $patch_pt + $Current{'fw_rbank'}, $insert_pt, $return_pt, length($1)));

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
			op_dbgout("fw_rs_patch", sprintf("... Patch insertion point set to %X", $insert_pt));

			# The standard parser function (see above) can't read the original
			# speeds because they are not stored in the patch insert location
			# so we have to save them to a special global variable that is used
			# only for parsing a 0x01 return from this patch function.
			#
			if ($testmode)
			{
				op_dbgout("fw_rs_patch", sprintf("... Length of current speed area: %d", length($speed_sel)));

				if ($Current{'fw_gen'} >= 0x011 && $Current{'fw_gen'} < 0x040 && $speed_sel =~ /^\x7F(?#1)(.)\x80.\x7F(?#2)(.)\x80.(?:\x7F.\x80.)?\x7F(?#3)(.)\x80.\x7F(?#4)(.)\x80.\x7F(?#5)(.)\x80.\x7F(?#6)(.)\x80.$/s)
				{
					$Current{'fw_rs_type1parse'} = [ ord($1), ord($2), ord($6), ord($4), min(ord($2), ord($3)) ];
					op_dbgout("fw_rs_patch", "... Parsing of current speed area successful: standard");
				}
				elsif ($Current{'fw_gen'} >= 0x121 && $Current{'fw_gen'} < 0x130 && $speed_sel =~ /^\x7F(?#1)(.)\x80.\x7F(?#2)(.)\x80.\x7F(?#3)(.)\x80.\x7F(?#4)(.)\x80.\x7F(?#5)(.)\x80.$/s)
				{
					$Current{'fw_rs_type1parse'} = [ ord($1), ord($2), ord($1), ord($4), ord($3) ];
					op_dbgout("fw_rs_patch", "... Parsing of current speed area successful: 2S slimtype");
				}
				elsif ($Current{'fw_gen'} >= 0x111 && $Current{'fw_gen'} < 0x120 && $speed_sel =~ /^\x7F(?#1)(.)\x80.\x7F(?#2)(.)\x80.$/s)
				{
					$Current{'fw_rs_type1parse'} = [ ord($1), ord($2), ord($2), ord($2), $Current{'fw_rs_defaults'}->[$FW_RS_DVDR9] ];
					op_dbgout("fw_rs_patch", "... Parsing of current speed area successful: 1S slimtype");
				}
				else
				{
					$Current{'fw_rs_type1parse'} = [ @{$Current{'fw_rs_defaults'}} ];
					op_dbgout("fw_rs_patch", "... Parsing of current speed area failed; using defaults");
				}

				map { $Current{'fw_rs'}->[$_][2] = [ $Current{'fw_rbank'} + $insert_pt + $speed_pts[$_] ] } (@FW_RS_IDX);
			}

			# And now, patch
			#
			substr($insert, $insert_ret_pt, 2, int2unicode($return_pt));
			substr($bank, $insert_pt, $insert_len, $insert);
			substr($bank, $patch_pt, 4, chr(0x02) . int2unicode($insert_pt) . chr(0x00));
			substr(${$fw}, $Current{'fw_rbank'}, 0x10000, $bank);

			return 0x01;
		}
		else
		{
			# If not patched, and not patchable
			#
			op_dbgout("fw_rs_patch", "... Cannot allocate space!");
			return -1;
		}
	}
	elsif ($bank =~ /(?#1)(\xE5\x24\x12..(?#2:ROM)(..)\x80(?#3,4:DL)(..)\x82(..)\x83(?#5,6,7:RW)(..)\x88(..)\x8C(..)\x8D(?#8:R)(..)\x90(?#9:R9)(..)\x93(?#10:R)(..)\x94(?#11:R9)(..)\x97)/sg)
	{
		# Type 2 function (starting with -R9)
		#
		op_dbgout("fw_rs_patch", sprintf("Type 2 routine: loc=%05X", (pos($bank)) - length($1) + $Current{'fw_rbank'}));

		if ($testmode)
		{
			$Current{'fw_rs'}->[$FW_RS_DVDROM][2] = [ makeset(map { $Current{'fw_rbank'} + unicode2int($_) + 1 } ($2)) ];
			$Current{'fw_rs'}->[$FW_RS_DVD9  ][2] = [ makeset(map { $Current{'fw_rbank'} + unicode2int($_) + 1 } ($3, $4)) ];
			$Current{'fw_rs'}->[$FW_RS_DVDR  ][2] = [ makeset(map { $Current{'fw_rbank'} + unicode2int($_) + 1 } ($8, $10)) ];
			$Current{'fw_rs'}->[$FW_RS_DVDRW ][2] = [ makeset(map { $Current{'fw_rbank'} + unicode2int($_) + 1 } ($5, $6, $7)) ];
			$Current{'fw_rs'}->[$FW_RS_DVDR9 ][2] = [ makeset(map { $Current{'fw_rbank'} + unicode2int($_) + 1 } ($9, $11)) ];
		}

		return 0x02;
	}

	op_dbgout("fw_rs_patch", "Sorry, can't find the function!");

	return -1;
}

sub fw_rs_proc # ( dropid, itemid )
{
	my($dropid, $itemid) = @_;
	$Current{'fw_rs'}->[$dropid][1] = $FW_RS_IDX2SPD[$dropid][$itemid];
}

1;
