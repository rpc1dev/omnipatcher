##
# OmniPatcher for LiteOn DVD-Writers
# Firmware : General patches
#
# Modified: 2005/06/13, C64K
#

##
# OmniPatcher Patching Guide
# - testmode  : 0 = regular operation,
#               1 = do not patch; just determine if it's patchable, and if applicable, what the current patch state is
# - patchmode : 0 = remove patch, (the entire patchmode flag may be ignored by functions that do not support unpatching)
#               1 = apply patch
# - return    :-3 = override relevancy and re-flag as irrelevant
#              -2 = patched but cannot be unpatched
#              -1 = not patchable
#               0 = patchable and currently unpatched
#               1 = patchable and currently patched
#
# Warning: Never directly modify $Current{'fw'}!
# Instead, modify the $fw reference, which, in testmode, points to a
# discardable copy of the firmware, and which, in standard mode, points
# to the real thing.
#
# There is a template function, fw_pat_null, that can be used as the
# basis of new patching functions.
#

sub fw_pat_null # ( testmode, patchmode )
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

	#op_dbgout("fw_pat_null", "Hello, world! :)");

	return -1;
}

sub fw_pat_fbs # ( testmode, patchmode )
{
	ui_settext($PatchesTab->{'FBS'}, $FW_PATCHES{'FBS'}->[0]) if ($_[0]);
	return fw_pat_fbs_812s(@_) if ($Current{'fw_family'} eq 'SOHW-812S/802S');
	return fw_pat_fbs_sony(@_) if ($Current{'fw_fwrev'} =~ /^BYX|[CJK]Y/);
	return -1;
}

sub fw_pat_fbs_812s # ( testmode, patchmode )
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

	my($patch) = join '', map { chr }
	(
		#  0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
		0xD3, 0x10, 0xAF, 0x01, 0xC3, 0xC0, 0xD0, 0x90, 0x89, 0xC0, 0xE0, 0xB4, 0x01, 0x1F, 0x90, 0x84,
		0xCA, 0xE0, 0x60, 0x0B, 0x75, 0x46, 0x00, 0x75, 0x45, 0x01, 0x75, 0x44, 0x1F, 0x80, 0x09, 0x75,
		0x46, 0x00, 0x75, 0x45, 0x01, 0x75, 0x44, 0x1F, 0x75, 0x43, 0x01, 0x80, 0x24, 0x90, 0x89, 0xC0,
		0xE0, 0xB4, 0x02, 0x2E, 0x90, 0x84, 0xCA, 0xE0, 0x60, 0x0B, 0x75, 0x46, 0x00, 0x75, 0x45, 0x04,
		0x75, 0x44, 0x1F, 0x80, 0x09, 0x75, 0x46, 0x00, 0x75, 0x45, 0x04, 0x75, 0x44, 0x1F, 0x75, 0x43,
		0x92, 0x90, 0x89, 0xC2, 0xE0, 0xFC, 0xA3, 0xE0, 0xFD, 0xA3, 0xE0, 0xFE, 0xA3, 0xE0, 0xFF, 0x12,
		0xAA, 0x5A, 0x02, 0x3E, 0x70
	);

	my($header) = "\x02\xFF\x00\x00";
	my($ins_pt) = 0x5FF00;
	my(@fwdep, $header_pt);

	op_dbgout("fw_pat_fbs_812s", "Starting...");

	return -2 if (substr(${$fw}, $ins_pt, 0x07) eq substr($patch, 0x00, 0x07));

	my($bank5) = substr(${$fw}, 0x50000, 0x10000);
	my($bank9) = substr(${$fw}, 0x90000, 0x10000);

	if ($bank9 =~ /\xE0\xB4\x01\x07...(..)/sg)
	{
		$fwdep[0] = $1;
		op_dbgout("fw_pat_fbs_812s", sprintf("... fwdep[0]: %04X at 9%04X", unicode2int($fwdep[0]), (pos($bank9)) - length($1)));
	} else { return -1 }

	if ($bank5 =~ /\x60\x08\x90(..)(\x74\x01\xF0\x80\x05)/sg)
	{
		$fwdep[1] = $1;
		op_dbgout("fw_pat_fbs_812s", sprintf("... fwdep[1]: %04X at 5%04X", unicode2int($fwdep[1]), (pos($bank5)) - (length($1) + length($2))));
		pos($bank5) = 0;
	} else { return -1 }

	if ($bank5 =~ /(\xD3\x10\xAF\x01\xC3\xC0\xD0)(\x30...)(..)/sg)
	{
		$fwdep[2] = $3;
		$fwdep[4] = int2unicode((pos($bank5)) - (length($2) + length($3)));
		$header_pt = (pos($bank5)) - (length($1) + length($2) + length($3)) + 0x50000;
		op_dbgout("fw_pat_fbs_812s", sprintf("... fwdep[2]: %04X at 5%04X", unicode2int($fwdep[2]), (pos($bank5)) - length($3)));
	} else { return -1 }

	if ($bank5 =~ /\xE4\xF5\x43\x12(..)/sg)
	{
		$fwdep[3] = $1;
		op_dbgout("fw_pat_fbs_812s", sprintf("... fwdep[3]: %04X at 5%04X", unicode2int($fwdep[3]), (pos($bank5)) - length($1)));
	} else { return -1 }

	op_dbgout("fw_pat_fbs_812s", sprintf("... fwdep[4]: %04X", unicode2int($fwdep[4])));
	op_dbgout("fw_pat_fbs_812s", sprintf("... header_pt: %05X", $header_pt));
	op_dbgout("fw_pat_fbs_812s", "... applying patch");

	substr($patch, 0x08, 2, $fwdep[0]);
	substr($patch, 0x0F, 2, $fwdep[1]);
	substr($patch, 0x2E, 2, $fwdep[0]);
	substr($patch, 0x35, 2, $fwdep[1]);
	substr($patch, 0x52, 2, $fwdep[2]);
	substr($patch, 0x60, 2, $fwdep[3]);
	substr($patch, 0x63, 2, $fwdep[4]);

	substr(${$fw}, $ins_pt, length($patch), $patch);
	substr(${$fw}, $header_pt, length($header), $header);

	return 0;
}

sub fw_pat_fbs_sony # ( testmode, patchmode )
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

	my($patch) = join '', map { chr }
	(
		#  0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
		0x7F, 0x4A, 0x7E, 0x01, 0x12, 0x00, 0x00, 0x90, 0x00, 0x00, 0xEF, 0xF0, 0x22
	);

	my(@ppoint, @fwdep, $temp);

	op_dbgout("fw_pat_fbs_sony", "Starting...");

	if (${$fw} =~ /(\x30..\x90..\x74\x01)([\xF0\x00])(\x80\x05\xE4\x90..)([\xF0\x00])(\x90..\xE0\xFF\xC4)/sg)
	{
		# BYX?
		#
		return -1 if ($2 ne $4);
		return -2 if ($2 eq $4 && $2 eq chr(0x00));

		$ppoint[0] = (pos(${$fw})) - (length("$1$2$3$4$5"));
		op_dbgout("fw_pat_fbs_sony", sprintf("... ppoint[0]: %05X (can save)", $ppoint[0]));

		substr(${$fw}, $ppoint[0] + 0x08, 1, chr(0x00));
		substr(${$fw}, $ppoint[0] + 0x0F, 1, chr(0x00));

		pos(${$fw}) = 0;

		# Find EEPROM read routine
		#
		if (${$fw} =~ /\x7F\x3D\x7E\x01\x12(..)/sg)
		{
			$fwdep[0] = $1;
			op_dbgout("fw_pat_fbs_sony", sprintf("... fwdep[0]: %04X at %04X", unicode2int($fwdep[0]), (pos(${$fw})) - length($1)));

			pos(${$fw}) = 0;
		} else { return -1 }
		
		# Find the booktype init routine
		#
		if (${$fw} =~ /\x90..\xE0\x54\xEF\xF0\xE0\x54\xF7\xF0\x90..\xE0\x54\xBF\xF0\x90..\xE0\x54\xFB\xF0(\xE4\x90)(..)(\xF0\x22)/sg)
		{
			$fwdep[1] = $2;
			op_dbgout("fw_pat_fbs_sony", sprintf("... fwdep[1]: %04X at %04X", unicode2int($fwdep[1]), (pos(${$fw})) - length("$2$3")));

			$ppoint[1] = (pos(${$fw})) - (length("$1$2$3"));
			op_dbgout("fw_pat_fbs_sony", sprintf("... ppoint[1]: %05X", $ppoint[1]));
		} else { return -1 }

		$temp = substr(${$fw}, $ppoint[1], 0x10000 - ($ppoint[1] & 0xFFFF));

		# Find some real estate for the patch
		#
		if ($temp =~ /\x00{2}(\x00{64})/sg)
		{
			$ppoint[2] = $ppoint[1] + (pos($temp)) - (length($1));
			op_dbgout("fw_pat_fbs_sony", sprintf("... ppoint[2]: %05X", $ppoint[2]));
		} else { return -1 }

		op_dbgout("fw_pat_fbs_sony", "... applying patch");

		substr($patch, 0x05, 2, $fwdep[0]);
		substr($patch, 0x08, 2, $fwdep[1]);
		
		# Insert main patch into real estate and add in a call to the
		# inserted patch point.
		#
		substr(${$fw}, $ppoint[2], length($patch), $patch);
		substr(${$fw}, $ppoint[1], 6, chr(0x02) . int2unicode($ppoint[2] & 0xFFFF) . "\x00\x00\x00");

		ui_settext($PatchesTab->{'FBS'}, "$FW_PATCHES{'FBS'}->[0] (Booktype saving: ON)") if ($testmode);
		return 0;
	}
	elsif (${$fw} =~ /(\x30..\x7F\x01\x80\x02\x7F\x00\x90..\xEF)([\xF0\x00])(\x90..\xE0\xFF)/sg)
	{
		# KY0? (JY0?)
		#
		return -2 if ($2 eq chr(0x00));

		$ppoint[0] = (pos(${$fw})) - length("$1$2$3");
		op_dbgout("fw_pat_fbs_sony", sprintf("... ppoint[0]: %05X (cannot save)", $ppoint[0]));

		substr(${$fw}, $ppoint[0] + 0x0D, 1, chr(0x00));

		ui_settext($PatchesTab->{'FBS'}, "$FW_PATCHES{'FBS'}->[0] (Booktype saving: OFF)") if ($testmode);
		return 0;
	}

	return -1;
}

sub fw_pat_abs # ( testmode, patchmode )
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

	my (@offpat) = map { quotemeta } my(@off) =
	(
		"\xEF\xF0\xE0\x54\xF7\xF0",
		"\xE4",
		"\x7F\x4A\x7E\x01",
	);

	my (@onpat) = map { quotemeta } my(@on) =
	(
		"\xE7\xF0\x00\x00\x00",
		"\x74\x01",
		"\x7F\x10\x80\x03",
	);

	if (${$fw} =~ /\x90..\xE0\x54($offpat[0]|$onpat[0])(.{0,24}?)($offpat[1]|$onpat[1])(\x90..\xF0\x22)/sg)
	{
		my($addr) = (pos(${$fw})) - length($4);
		my($patch) = ($patchmode) ? "$on[0]$2$on[1]" : "$off[0]$2$off[1]";

		pos ${$fw} = 0;

		return -1 if (length($1) + length($3) != 7);

		op_dbgout("fw_pat_abs", sprintf("Main patch point found at 0x%X", $addr - length($patch)));
		substr(${$fw}, $addr - length($patch), length($patch), $patch);

		return ($1 eq $on[0]) ? 1 : 0;
	}
	elsif (${$fw} =~ /\x90..\xE0\x54$offpat[0].{0,24}?($offpat[2]|$onpat[2])(\x12..\x90..\xEF\xF0\x22)/sg)
	{
		my($addr) = pos(${$fw});
		my($patch) = ($patchmode) ? "$on[2]$2" : "$off[2]$2";

		pos ${$fw} = 0;

		op_dbgout("fw_pat_abs", sprintf("Advanced patch point found at 0x%X", $addr - length($patch)));
		return -3 unless ($FW_ALLOW_ADVANCED_AUTOBS);
		substr(${$fw}, $addr - length($patch), length($patch), $patch);

		return ($1 eq $on[2]) ? 1 : 0;
	}

	return -1;
}

sub fw_pat_led # ( testmode, patchmode )
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

	my($insert) = join '', map { chr }
	(
		#  0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F
		0x78, 0xCB, 0xE2, 0x30, 0xE7, 0x06, 0xE2, 0x30, 0xE2, 0x02, 0x80, 0x10, 0x30, 0x27, 0x12, 0x90,
		0x88, 0xDB, 0xE0, 0xB4, 0x01, 0x0B, 0x20, 0x03, 0x08, 0x20, 0x46, 0x05, 0x12, 0xB7, 0xBB, 0x80,
		0x03, 0x12, 0xB7, 0xA9, 0x12, 0xCA, 0x3F, 0x22
	);

	##
	# First, let's determine if this firmware has already been patched, and if it has
	# not been, we should allocate some space for the insertion point.
	#
	my($insert_pt);
	{
		my($insert_pattern) = quotemeta(substr($insert, 0, 0x10));
		my($insert_search_start) = 0xFF00 - 2;
		my($insert_search_len) = 0xC0 + 2;
		my($insert_search_area) = substr(${$fw}, $insert_search_start, $insert_search_len);
		my($insert_search_patchlen) = length($insert);

		if ($insert_search_area =~ /$insert_pattern/s)
		{
			return -2;
		}
		elsif ($insert_search_area =~ /\x00{2}(\x00{$insert_search_patchlen}\x00{2})/sg)
		{
			$insert_pt = (pos($insert_search_area) - length($1)) + $insert_search_start;
			op_dbgout("fw_pat_led", sprintf("Patch insertion position is set to: %05X", $insert_pt));
		}
		else
		{
			op_dbgout("fw_pat_led", "Unable to allocate space!");
			return -1;
		}
	}

	my(@ppoint, @jmpofs, @callsearch);
	my($fdvar, @fdbyte, @fdcall);

	##
	# Find LED routine and patch points
	#
	my($bank0) = substr(${$fw}, 0, 0x10000);

	if ($bank0 =~ /(?#1)(...\xE0\x60.\xE0\x54\x7F\x60)(?#2)(.{0,200}?)(?#3)(\xE0\x64\x03\x60.)(?#4-ppoint0)(.{0,200}?)(?#5-ppoint1)(\x90..\xE0\xFE\xA3)(?#6)(.{0,200}?)(?#7)(\xD0\xD0\xD0\x82\xD0\x83|\x22)/sg)
	{
		$ppoint[0] = (pos($bank0)) - length("$4$5$6$7");
		$ppoint[1] = (pos($bank0)) - length("$5$6$7");

		$jmpofs[0] = $ppoint[1] - $ppoint[0] - 2;
		$jmpofs[1] = ((pos($bank0)) - length($7)) - $ppoint[1] - 8;

		$callsearch[0] = "$1$2";
		$callsearch[1] = "$4$5$6";

		op_dbgout("fw_pat_led", sprintf("LED function found; wildcard lengths: %d, %d, %d", length($2), length($4), length($6)));
		op_dbgout("fw_pat_led", sprintf("... ppoint: %04X / %04X", @ppoint));
		op_dbgout("fw_pat_led", sprintf("... jmpofs: %02X / %02X", @jmpofs));
	} else { return -1 }

	##
	# Firmware-dependent variable
	#
	if (${$fw} =~ /\xE0\x54\xDF\xF0\x90(..)\x74\x01\xF0/s)
	{
		$fdvar = $1;
		op_dbgout("fw_pat_led", sprintf("... fdvar: %04X", unicode2int($fdvar)));
	} else { return -1 }

	##
	# Firmware-dependent byte 0
	#
	if (${$fw} =~ /\x20(.)\x02\xD2.\x30.\x06/s)
	{
		$fdbyte[0] = $1;
	} else { return -1 }

	##
	# Firmware-dependent byte 1
	#
	if (${$fw} =~ /\x74\x06\xF0\x90..\x74\x66.{8}(.)/s)
	{
		$fdbyte[1] = $1;
		op_dbgout("fw_pat_led", sprintf("... fdbyte: %02X / %02X", map { ord } @fdbyte));
	} else { return -1 }

	##
	# Firmware-dependent call 0
	#
	if ($callsearch[0] =~ /\x12(..)/s)
	{
		$fdcall[0] = $1;
		op_dbgout("fw_pat_led", sprintf("... fdcall[0]: %04X", unicode2int($fdcall[0])));
	} else { return -1 }

	##
	# Firmware-dependent call 1
	#
	if ($callsearch[1] =~ /\x12..\xEF\x30\xE0..(..)/s)
	{
		$fdcall[1] = $1;
		op_dbgout("fw_pat_led", sprintf("... fdcall[1]: %04X", unicode2int($fdcall[1])));
	} else { return -1 }

	##
	# Firmware-dependent call 2
	#
	if (${$fw} =~ /\xE0\x30\xE1.\x12..\x12..\x7F\xC8\x7E\x00......\x12(..)/s)
	{
		$fdcall[2] = $1;
		op_dbgout("fw_pat_led", sprintf("... fdcall[2]: %04X", unicode2int($fdcall[2])));
	} else { return -1 }

	##
	# Patch: changing existing code
	#
	my(@pcount, @patch);

	$patch[0] = chr(0x80) . chr($jmpofs[0]) . chr(0x00);
	$patch[1] = chr(0x90) . int2unicode($insert_pt) . chr(0x12) . int2unicode($Current{'fw_bank0call'}->[0]) . chr(0x80) . chr($jmpofs[1]);

	foreach my $i (0 .. $Current{'fw_nbanks'} - 1)
	{
		if (substr(${$fw}, ($i << 16) + $ppoint[0], 2) eq "\x30\x27")
		{
			substr(${$fw}, ($i << 16) + $ppoint[0], length($patch[0]), $patch[0]);
			++$pcount[0];
		}

		if (substr(${$fw}, ($i << 16) + $ppoint[1], 6) =~ /^\x90..\xE0\xFE\xA3/s)
		{
			substr(${$fw}, ($i << 16) + $ppoint[1], length($patch[1]), $patch[1]);
			++$pcount[1];
		}
	}

	op_dbgout("fw_pat_led", sprintf("... pcount: %d / %d", @pcount));
	return -1 if ($pcount[0] != $pcount[1] || ($pcount[0] != 1 && $pcount[0] != $Current{'fw_nbanks'}));

	##
	# Patch: fix IDE problem
	#
	if ($Current{'fw_fwrev'} =~ /^.[FY]/s && ${$fw} =~ /\x12..\x78\x02\x74(\x04\xF2)/sg)
	{
		op_dbgout("fw_pat_led", sprintf("... IDE fix location: %05X", (pos(${$fw})) - length($1)));
		substr(${$fw}, (pos(${$fw})) - length($1), 1, chr(0x08));
	}

	##
	# Patch: insertion of new code
	#
	substr($insert, 0x10, 2, $fdvar);
	substr($insert, 0x17, 1, $fdbyte[1]);
	substr($insert, 0x1A, 1, $fdbyte[0]);
	substr($insert, 0x1D, 2, $fdcall[1]);
	substr($insert, 0x22, 2, $fdcall[0]);
	substr($insert, 0x25, 2, $fdcall[2]);
	substr($insert, 0x19, 2, "\x00\x80") if ($Current{'fw_gen'} >= 0x030);
	substr(${$fw}, $insert_pt, length($insert), $insert);

	return 0;
}

sub fw_pat_es # ( testmode, patchmode )
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

	my($work) = substr(${$fw}, 0x70000, 0x60000);

	if ($work =~ /\x74\x04\xF0\x90..\x74([\x0D\x0B])\xF0/sg)
	{
		my($addr) = pos($work);
		my($orig) = $1;

		substr($work, $addr - 2, 1, ($patchmode) ? chr(0x0B) : chr(0x0D));
		substr(${$fw}, 0x70000, length($work), $work);

		return ($orig eq chr(0x0B)) ? 1 : 0;
	}
	elsif ($work =~ /\x74[\x06\x05]\xF0\x90..\x74([\x0F\x0C])\xF0/sg)
	{
		my($addr) = pos($work);
		my($orig) = $1;

		substr($work, $addr - 2, 1, ($patchmode) ? chr(0x0C) : chr(0x0F));
		substr($work, $addr - 8, 1, ($patchmode) ? chr(0x05) : chr(0x06));
		substr(${$fw}, 0x70000, length($work), $work);

		return ($orig eq chr(0x0C)) ? 1 : 0;
	}

	return -1;
}

sub fw_pat_fs # ( testmode, patchmode )
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

	my($offkey) = "\x59\x00\xD0\x00 \x06 \x03";
	my($onkey)  = "\xB2\x00\xA0\x01 \x02 \x02";
	my($curkey) = "";
	my($addr);

	my($bank6) = substr(${$fw}, 0x60000, 0x10000);
	my($bank7) = substr(${$fw}, 0x70000, 0x10000);
	my($bankD) = substr(${$fw}, 0xD0000, 0x10000);

	if ($bank6 =~ /\xC3\x90..\xE0\x94([\x59\xB2])\x90..\xE0\x94(\x00)\x50.\xC3\x90..\xE0\x94([\xD0\xA0])\x90..\xE0\x94([\x00\x01])\x50./sg)
	{
		$addr = pos($bank6);
		$curkey .= "$1$2$3$4 ";

		substr($bank6, $addr - 24, 1, ($patchmode) ? chr(0xB2) : chr(0x59));
		substr($bank6, $addr - 18, 1, ($patchmode) ? chr(0x00) : chr(0x00));
		substr($bank6, $addr - 9, 1, ($patchmode) ? chr(0xA0) : chr(0xD0));
		substr($bank6, $addr - 3, 1, ($patchmode) ? chr(0x01) : chr(0x00));
	}

	if ($bank7 =~ /\x90..\xE0\xC3\x94([\x06\x02])\x40\x0E\xEF\x64\x08/sg)
	{
		$addr = pos($bank7);
		$curkey .= "$1 ";

		substr($bank7, $addr - 6, 1, ($patchmode) ? chr(0x02) : chr(0x06));
	}

	if ($bankD =~ /\x90..\xE0\xB4\x01.\xE4\xFF\xFE\x7D([\x03\x02])\xFC/sg)
	{
		$addr = pos($bankD);
		$curkey .= "$1";

		substr($bankD, $addr - 2, 1, ($patchmode) ? chr(0x02) : chr(0x03));
	}

	if ($curkey eq $onkey || $curkey eq $offkey)
	{
		substr(${$fw}, 0x60000, 0x10000, $bank6);
		substr(${$fw}, 0x70000, 0x10000, $bank7);
		substr(${$fw}, 0xD0000, 0x10000, $bankD);
		fw_pat_ff_ricoh($testmode, $patchmode);

		return ($curkey eq $onkey) ? 1 : 0;
	}

	return -1;
}

sub fw_pat_ff # ( testmode, patchmode )
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

	my($ricohidx) = media_name2idx(["RICOHJPN", "R01", 0x02]);
	my($ricohbyte) = chr($Current{'media_table'}->[$ricohidx][1]) unless ($ricohidx < 0);

	my($offkey) = "\x64\x64";
	my($onkey)  = "\xE4\xE4";
	my($curkey) = "";
	my($addr, $idbyte, $offbyte);

	my($plusbank) = substr(${$fw}, getaddr_full($Current{'media_pbank'}), 0x10000);

	my($temp) = $plusbank;

	while ($temp =~ /\x90..\xE0\xFF(\x64[$ricohbyte\xFF]|\xE4\x00)[\x60\x70]/sg)
	{
		$addr = pos($temp);
		$curkey .= substr($1, 0, 1);

		$idbyte = substr($1, 1, 1);
		$offbyte = ($idbyte eq $ricohbyte || $idbyte eq "\xFF") ? $idbyte : $ricohbyte;

		substr($plusbank, $addr - 3, 2, ($patchmode) ? "\xE4\x00" : "\x64$offbyte");
	}

	if ($curkey eq $onkey || $curkey eq $offkey)
	{
		substr(${$fw}, getaddr_full($Current{'media_pbank'}), 0x10000, $plusbank);

		return ($curkey eq $onkey) ? 1 : 0;
	}

	return -1;
}

sub fw_pat_ff_ricoh # ( testmode, patchmode )
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

	my($ricohidx) = media_name2idx(["RICOHJPN", "R01", 0x02]);
	my($ricohbyte) = chr($Current{'media_table'}->[$ricohidx][1]) unless ($ricohidx < 0);

	my($offkey0) = "$ricohbyte$ricohbyte";
	my($offkey1) = "\x00\x00";
	my($onkey)  = "\xFF\xFF";
	my($curkey) = "";

	my($plusbank) = substr(${$fw}, getaddr_full($Current{'media_pbank'}), 0x10000);

	my($temp) = $plusbank;

	while ($temp =~ /\x90..\xE0\xFF(\x64[$ricohbyte\xFF]|\xE4\x00)[\x60\x70]/sg)
	{
		my($addr) = pos($temp);
		$curkey .= substr($1, 1, 1);

		substr($plusbank, $addr - 3, 2, ($patchmode) ? "\x64\xFF" : "\x64$ricohbyte");
	}

	if ($curkey eq $onkey || $curkey eq $offkey0 || $curkey eq $offkey1)
	{
		substr(${$fw}, getaddr_full($Current{'media_pbank'}), 0x10000, $plusbank);

		return ($curkey eq $onkey) ? 1 : 0;
	}

	return -1;
}

sub fw_pat_dl # ( testmode, patchmode )
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

	my(@points);

	while (${$fw} =~ /\xEF\xF0([\x60\x80])(\x06\xE0\xC3\x94\x05)/sg)
	{
		push(@points, [ ord($1), (pos(${$fw})) - (length($1) + length($2)) ]);
		op_dbgout("fw_pat_dl", sprintf("%02X at %05X", @{$points[-1]}));
	}

	if ($#points == 3 && $points[0][0] == $points[1][0] && $points[0][0] == $points[2][0] && $points[0][0] == $points[3][0])
	{
		foreach my $point (@points)
		{
			substr(${$fw}, $point->[1], 1, ($patchmode) ? chr(0x80) : chr(0x60));
		}

		return(($points[0][0] == 0x60) ? 0 : 1);
	}

	return -1;
}

sub fw_pat_cf # ( testmode, patchmode )
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

	use integer;

	my($insert) = join('', map { chr } ( 0xE5, 0x81, 0x24, 0xFC, 0xF8, 0xE6, 0xFF, 0x22 ));
	my($off) = join('', map { chr } ( 0xFF, 0xEE, 0x6F, 0x60, 0x02, 0xC3, 0x22 ));
	my($on1) = join('', map { chr } ( 0xFF, 0xEE, 0x6F, 0x00, 0x00, 0xD3, 0x22 ));
	my($on2) = join('', map { chr } ( 0xFF, 0xEE, 0x6F, 0xD3, 0xD3, 0xD3, 0x22 ));
	my($onc) = join('', map { chr } ( 0xFF, 0xEE, 0x6F, 0x60, 0x00, 0xD3, 0x22 ));
	my($offpat, $on1pat, $on2pat, $oncpat) = map { quotemeta } ($off, $on1, $on2, $onc);

	my($work) = substr(${$fw}, getaddr_full($Current{'fw_ebank'}), 0x10000);

	##
	# LDW-411S mode
	#
	if ($Current{'fw_family'} eq 'LDW-411S')
	{
		op_dbgout("fw_pat_cf", "Entering 411S mode");

		my($offold) = join('', map { chr } ( 0xEF, 0x64, 0xFE, 0x60, 0x02, 0xC3, 0x22, 0xD3, 0x22 ));
		my($onold)  = join('', map { chr } ( 0xEF, 0x64, 0xFE, 0x60, 0x02, 0xD3, 0x22, 0xD3, 0x22 ));
		my($offoldpat, $onoldpat) = map { quotemeta } ($offold, $onold);

		if ($work =~ /($offoldpat|$onoldpat)/s)
		{
			my ($orig) = $1;

			($patchmode) ?
			$work =~ s/$offoldpat|$onoldpat/$onold/s :
			$work =~ s/$offoldpat|$onoldpat/$offold/s;

			substr(${$fw}, getaddr_full($Current{'fw_ebank'}), 0x10000, $work);

			return ($orig eq $onold) ? 1 : 0;
		}

		return -1;
	}

	##
	# Refuse to unpatch if the special Code Guys crossflash patch type is found.
	# The 8X2S_cfp mini-patcher will produce such patch types.
	#
	return -2 if ($work =~ /($oncpat)/s);

	##
	# Standard mode
	#
	if ($work =~ /($offpat|$on1pat|$on2pat)/sg)
	{
		my($addr) = (pos($work)) - length($1);
		my($orig) = $1;

		op_dbgout("fw_pat_cf", sprintf("Main patch point found at 0x%X", getaddr_full($Current{'fw_ebank'}) + $addr + 3));

		substr($work, $addr, length($orig), ($patchmode) ? $on1 : $off);
		substr(${$fw}, getaddr_full($Current{'fw_ebank'}), 0x10000, $work);

		# Code for multibank patching for VS05+ protections schemes.
		#
		my($check_addr) = rindex($work, chr(0x12), $addr);

		if ($addr - $check_addr < 0x11)
		{
			$check_addr = substr($work, $check_addr + 1, 2);

			op_dbgout("fw_pat_cf", sprintf("Checksum function found at 0x%X", getaddr_full($Current{'fw_ebank'}) + unicode2int($check_addr)));
			op_dbgout("fw_pat_cf", sprintf("Checksum XOR value: 0x%02X", ord($1))) if ($work =~ /\x90..\xE0\x64(.)\xFF\xF0\x22/s);

			my($check_addr_m) = quotemeta("\x90$check_addr\x02");
			my($check_fail) = 0;
			my($check_count) = 0;
			my($check_jump) = 0;
			my($check_temp) = 0;

			while (${$fw} =~ /$check_addr_m|\x90\xFF\xF0\x02/sg)
			{
				++$check_count;

				$check_temp = ((pos(${$fw})) - 4) & 0xFFFF;

				if ($check_count == 1)
				{
					$check_jump = $check_temp;
				}
				else
				{
					if ($check_jump != $check_temp)
					{
						$check_fail = 1;
						last;
					}
				}
			}

			$check_fail = 1 if ($check_count != $Current{'fw_nbanks'});
			pos(${$fw}) = 0;

			if (!$check_fail)
			{
				op_dbgout("fw_pat_cf", "Performing multi-bank patch");

				my($check_1, $check_2);

				if ($patchmode)
				{
					$check_1 = "\x90\xFF\xF0\x02";
					$check_2 = $insert;
				}
				else
				{
					$check_1 = "\x90$check_addr\x02";
					$check_2 = chr(0x00) x 8;
				}

				foreach $check_temp (0 .. $Current{'fw_nbanks'} - 1)
				{
					substr(${$fw}, $check_jump + ($check_temp << 16), 4, $check_1);
				}

				if ( substr(${$fw}, getaddr_full($Current{'fw_ebank'}) + 0xFFF0, 8) eq chr(0x00) x 8 ||
				     substr(${$fw}, getaddr_full($Current{'fw_ebank'}) + 0xFFF0, 8) eq $insert )
				{
					substr(${$fw}, getaddr_full($Current{'fw_ebank'}) + 0xFFF0, 8, $check_2);
				}
				else
				{
					op_dbgout("fw_pat_cf", "Multi-bank patch failed due lack of space");
					return -1;
				}
			}
		}

		# Code for 51S@832S crossflashing
		#
		if ($Current{'fw_gen'} == 0x021)
		{
			op_dbgout("fw_pat_cf", "Entering 51S\@2S mode");

			my($jmp) = ($patchmode) ? chr(0x00) : chr(0x03);

			if (${$fw} =~ s/(\x30.\x09\x90)(..)(\xE0\x60)[\x00\x03](\xD3\x80\x01)/$1$2$3$jmp$4/s)
			{
				op_dbgout("fw_pat_cf", "... Special patch point found; trying to set speed limits");

				my($addr_hwset) = $2;

				$work = substr(${$fw}, 0xF0000, 0x10000);

				if ($work =~ /\x90(..)\xA3\xE0\xFF\x30\xE0\x0C\x90..\x74\x01\xF0\x90(..)\xE0\x04\xF0.{32}(.{32})\x22/sg)
				{
					op_dbgout("fw_pat_cf", "... Speed limiter found!");

					my($addr_src) = $1;
					my($addr_dest) = $2;
					my($addr_end) = pos($work);
					my($patch_area) = $3;

					my($spd_patch_a) = join('', map { chr }
					(
						0x90, 0x00, 0x00, 0xE0, 0x60, 0x03, 0x02, 0xFF,
						0xB0, 0xEF, 0x54, 0xE7, 0xFF, 0x90, 0x00, 0x00,
						0xA3, 0xF0, 0x90, 0x00, 0x00
					));

					substr($spd_patch_a, 0x01, 2, $addr_hwset);
					substr($spd_patch_a, 0x0E, 2, $addr_src);
					substr($spd_patch_a, 0x13, 2, $addr_dest);

					$spd_patch_a .= chr(0x00) x (0x20 - length($spd_patch_a));

					if ($patchmode && $patch_area ne $spd_patch_a)
					{
						substr($work, $addr_end - 0x21, 0x20, $spd_patch_a);
						substr($work, 0xFFB0, 0x23, $patch_area . chr(0x02) . int2unicode($addr_end - 0x01));
						substr(${$fw}, 0xF0000, 0x10000, $work);
					}
					elsif (!$patchmode && $patch_area eq $spd_patch_a)
					{
						substr($work, $addr_end - 0x21, 0x20, substr($work, 0xFFB0, 0x20));
						substr($work, 0xFFB0, 0x23, chr(0x00) x 0x23);
						substr(${$fw}, 0xF0000, 0x10000, $work);
					}

				} # End: If found speed patching

			} # End: If first patch point is found

		} # End: If valid drive type

		return ($orig eq $on1 || $orig eq $on2) ? 1 : 0;
	}

	return -1;
}

1;
