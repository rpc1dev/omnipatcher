$OP_ALLOW_ADVANCED_AUTOBS = 1;

sub patch_rs # ( testmode )
{
	my($testmode) = @_;
	my($i, $j, $counter, $jmppos);
	my($spd_pattern, $spd_to);

	my($MIN_SEQ) = 4;
	my($changes) = 0;
	my($found) = 0;
	my($p_spd) = 0;
	my($p_spd) = 0;
	
	my($work) = substr($file_data{'work'}, 0x20000, 0x10000);

	if ($file_data{'gen'} >= 3)
	{
		if ($ObjPatches[1]->GetCheck())
		{
			$spd_pattern = '^\x7F[\x06\x08\x0A\x0C\x0E\x10]\x80$';
			$spd_to = 0x10;
		}
		else
		{
			$spd_pattern = '^\x7F[\x06\x08\x0A\x0C\x0E]\x80$';
			$spd_to = 0x0C;
		}
	}
	else
	{
		$spd_pattern = '^\x7F[\x06\x08\x0A\x0C]\x80$';
		$spd_to = 0x08;
	}

	for ($i = 0; $i < length($work) - 4; ++$i)
	{
		if (substr($work, $i, 3) =~ /$spd_pattern/s)
		{
			$counter = 1;
			$jmppos = $i + ord(substr($work, $i + 3, 1));

			for ($j = $i + 4; $j < length($work) - 4 && substr($work, $j, 3) =~ /$spd_pattern/s; $j += 4)
#			for ($j = $i + 4; $j < length($work) - 4 && substr($work, $j, 3) =~ /^\x7F[\x06\x08\x0A\x0C]\x80$/s; $j += 4)
			{
				if ($j + ord(substr($work, $j + 3, 1)) == $jmppos)
				{
					++$counter;
				}
				else
				{
					last;
				}
			}

			if ($counter >= $MIN_SEQ)
			{
				dbgout(sprintf("patch_rs(): Main patch point found at 0x%X\n", $i + 0x20000));
				for ($j = 0; $j < $counter * 4; $j += 4)
				{
					if (ord(substr($work, $i + $j + 1, 1)) < $spd_to)
					{
						substr($work, $i + $j + 1, 1, chr($spd_to));
						++$changes;
					}
				}

				$found = 1;
				last;
			}
		}
	}

	if (!$testmode)
	{
		substr($file_data{'work'}, 0x20000, 0x10000, $work);
	}

	return ($found) ? $changes == 0 : -1;
}

sub patch_abs # ( testmode, mode )
{
	my($testmode, $mode) = @_;
	my(@off, @on, @offpat, @onpat);

	$off[0] = join('', map { chr } ( 0xEF, 0xF0, 0xE0, 0x54, 0xF7, 0xF0 ));
	$off[1] = join('', map { chr } ( 0xE4 ));
	$off[2] = join('', map { chr } ( 0x7F, 0x4A, 0x7E, 0x01 ));
	$on[0]  = join('', map { chr } ( 0xE7, 0xF0, 0x00, 0x00, 0x00 ));
	$on[1]  = join('', map { chr } ( 0x74, 0x01 ));
	$on[2]  = join('', map { chr } ( 0x7F, 0x10, 0x80, 0x03 ));
	($offpat[0], $offpat[1], $offpat[2], $onpat[0], $onpat[1], $onpat[2]) = map { quotemeta } ( @off, @on );

	if ($file_data{'work'} =~ /\x90..\xE0\x54($offpat[0]|$onpat[0])(.{0,24}?)($offpat[1]|$onpat[1])\x90..\xF0\x22/sg)
	{
		my($addr) = pos($file_data{'work'});
		pos $file_data{'work'} = 0;

		return -1 if (length($1) + length($3) != 7);

		my($patch) = ($mode) ? "$on[0]$2$on[1]" : "$off[0]$2$off[1]";
		dbgout(sprintf("patch_abs(): Main patch point found at 0x%X\n", $addr - 5 - length($patch)));
		if (!$testmode)
		{
			substr($file_data{'work'}, $addr - 5 - length($patch), length($patch), $patch);
		}

		return ($1 eq $on[0]) ? 1 : 0;
	}
	elsif ($OP_ALLOW_ADVANCED_AUTOBS && $file_data{'work'} =~ /\x90..\xE0\x54$offpat[0].{0,24}?($offpat[2]|$onpat[2])(\x12..\x90..\xEF\xF0\x22)/sg)
	{
		my($addr) = pos($file_data{'work'});
		pos $file_data{'work'} = 0;

		my($patch) = ($mode) ? "$on[2]$2" : "$off[2]$2";
		dbgout(sprintf("patch_abs_adv(): Main patch point found at 0x%X\n", $addr - length($patch)));
		if (!$testmode)
		{
			substr($file_data{'work'}, $addr - length($patch), length($patch), $patch);
		}

		return ($1 eq $on[2]) ? 1 : 0;
	}

	return -1;
}

sub patch_fb # ( testmode, mode )
{
	my($testmode, $mode) = @_;

	my($work) = substr($file_data{'work'}, 0x70000, 0x60000);

	if ($work =~ /\x74\x04\xF0\x90..\x74([\x0D\x0B])\xF0/sg)
	{
		my($addr) = pos($work);

		if (!$testmode)
		{
			substr($work, $addr - 2, 1, ($mode) ? chr(0x0B) : chr(0x0D));
			substr($file_data{'work'}, 0x70000, 0x60000, $work);
		}

		return ($1 eq chr(0x0B)) ? 1 : 0;
	}
	elsif ($work =~ /\x74[\x06\x05]\xF0\x90..\x74([\x0F\x0C])\xF0/sg)
	{
		my($addr) = pos($work);

		if (!$testmode)
		{
			substr($work, $addr - 2, 1, ($mode) ? chr(0x0C) : chr(0x0F));
			substr($work, $addr - 8, 1, ($mode) ? chr(0x05) : chr(0x06));
			substr($file_data{'work'}, 0x70000, 0x60000, $work);
		}

		return ($1 eq chr(0x0C)) ? 1 : 0;
	}

	return -1;
}

sub patch_sf # ( testmode, mode )
{
	my($testmode, $mode) = @_;

	my($offkey) = "\x59\x00\xD0\x00 \x06 \x03";
	my($onkey)  = "\xB2\x00\xA0\x01 \x02 \x02";
	my($curkey) = "";
	my($addr);

	my($bank6) = substr($file_data{'work'}, 0x60000, 0x10000);
	my($bank7) = substr($file_data{'work'}, 0x70000, 0x10000);
	my($bankD) = substr($file_data{'work'}, 0xD0000, 0x10000);

	if ($bank6 =~ /\xC3\x90..\xE0\x94([\x59\xB2])\x90..\xE0\x94(\x00)\x50.\xC3\x90..\xE0\x94([\xD0\xA0])\x90..\xE0\x94([\x00\x01])\x50./sg)
	{
		$addr = pos($bank6);
		$curkey .= "$1$2$3$4 ";

		substr($bank6, $addr - 24, 1, ($mode) ? chr(0xB2) : chr(0x59));
		substr($bank6, $addr - 18, 1, ($mode) ? chr(0x00) : chr(0x00));
		substr($bank6, $addr - 9, 1, ($mode) ? chr(0xA0) : chr(0xD0));
		substr($bank6, $addr - 3, 1, ($mode) ? chr(0x01) : chr(0x00));
	}

	if ($bank7 =~ /\x90..\xE0\xC3\x94([\x06\x02])\x40\x0E\xEF\x64\x08/sg)
	{
		$addr = pos($bank7);
		$curkey .= "$1 ";

		substr($bank7, $addr - 6, 1, ($mode) ? chr(0x02) : chr(0x06));
	}

	if ($bankD =~ /\x90..\xE0\xB4\x01.\xE4\xFF\xFE\x7D([\x03\x02])\xFC/sg)
	{
		$addr = pos($bankD);
		$curkey .= "$1";

		substr($bankD, $addr - 2, 1, ($mode) ? chr(0x02) : chr(0x03));
	}

	if ($curkey eq $onkey || $curkey eq $offkey)
	{
		if (!$testmode)
		{
			substr($file_data{'work'}, 0x60000, 0x10000, $bank6);
			substr($file_data{'work'}, 0x70000, 0x10000, $bank7);
			substr($file_data{'work'}, 0xD0000, 0x10000, $bankD);
			helper_patch_ricoh(0, $mode);
		}

		return ($curkey eq $onkey) ? 1 : 0;
	}

	return -1;
}

sub patch_ff # ( testmode, mode )
{
	my($testmode, $mode) = @_;

	my($ricohidx) = find_index(["RICOHJPN", "R01", 0x02]);
	my($ricohbyte) = chr($file_data{'codes'}->[$ricohidx][3]) unless ($ricohidx < 0);

	my($offkey) = "\x64\x64";
	my($onkey)  = "\xE4\xE4";
	my($curkey) = "";
	my($addr, $idbyte, $offbyte);

	my($plusbank) = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);

	my($temp) = $plusbank;

	while ($temp =~ /\x90..\xE0\xFF(\x64[$ricohbyte\xFF]|\xE4\x00)[\x60\x70]/sg)
	{
		$addr = pos($temp);
		$curkey .= substr($1, 0, 1);

		$idbyte = substr($1, 1, 1);
		$offbyte = ($idbyte eq $ricohbyte || $idbyte eq "\xFF") ? $idbyte : $ricohbyte;

		substr($plusbank, $addr - 3, 2, ($mode) ? "\xE4\x00" : "\x64$offbyte");
	}

	if ($curkey eq $onkey || $curkey eq $offkey)
	{
		if (!$testmode)
		{
			substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000, $plusbank);
			helper_patch_recalibrate(0, 0);
		}

		return ($curkey eq $onkey) ? 1 : 0;
	}

	return -1;
}

sub patch_fr # ( testmode, mode )
{
	my($testmode, $mode) = @_;

	my($ricohidx) = find_index(["RICOHJPN", "R01", 0x02]);
	my($ricohbyte) = chr($file_data{'codes'}->[$ricohidx][3]) unless ($ricohidx < 0);

	my($offkey) = "\x64\x64";
	my($onkey)  = "\xE4\xE4";
	my($curkey) = "";
	my($addr, $idbyte, $offbyte);

	my($plusbank) = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);

	my($temp) = $plusbank;

	while ($temp =~ /\x90..\xE0\xFF(\x64[$ricohbyte\xFF]|\xE4\x00)[\x60\x70]/sg)
	{
		$addr = pos($temp);
		$curkey .= substr($1, 0, 1);

		$idbyte = substr($1, 1, 1);
		$offbyte = ($idbyte eq $ricohbyte || $idbyte eq "\xFF") ? $idbyte : $ricohbyte;

		substr($plusbank, $addr - 3, 2, ($mode) ? "\xE4\x00" : "\x64$offbyte");
	}

	if ($curkey eq $onkey || $curkey eq $offkey)
	{
		if (!$testmode)
		{
			substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000, $plusbank);
			helper_patch_recalibrate(0, $mode);
			return 2;
		}
		else
		{
			my($recalib) = helper_patch_recalibrate(1, -1);
			return -1 if ($recalib < 0);
			return ($curkey eq $onkey && $recalib == 1) ? 1 : 0;
		}
	}

	return -1;
}

sub patch_eeprom # ( testmode, mode )
{
	use integer;

	my($testmode, $mode) = @_;

	my($off) = join('', map { chr } ( 0xFF, 0xEE, 0x6F, 0x60, 0x02, 0xC3, 0x22 ));
	my($on1) = join('', map { chr } ( 0xFF, 0xEE, 0x6F, 0x00, 0x00, 0xD3, 0x22 ));
	my($on2) = join('', map { chr } ( 0xFF, 0xEE, 0x6F, 0xD3, 0xD3, 0xD3, 0x22 ));
	my($onc) = join('', map { chr } ( 0xFF, 0xEE, 0x6F, 0x60, 0x00, 0xD3, 0x22 ));
	my($offpat, $on1pat, $on2pat, $oncpat) = map { quotemeta } ($off, $on1, $on2, $onc);

	my($work) = substr($file_data{'work'}, $file_data{'ebankpos'}, 0x10000);

	if ($file_data{'fwfamily'} eq 'LDW-411S')
	{
		my($offold) = join('', map { chr } ( 0xEF, 0x64, 0xFE, 0x60, 0x02, 0xC3, 0x22, 0xD3, 0x22 ));
		my($onold)  = join('', map { chr } ( 0xEF, 0x64, 0xFE, 0x60, 0x02, 0xD3, 0x22, 0xD3, 0x22 ));
		my($offoldpat, $onoldpat) = map { quotemeta } ($offold, $onold);

		if ($work =~ /($offoldpat|$onoldpat)/s)
		{
			my ($orig) = $1;

			if (!$testmode)
			{
				if ($mode)
				{
					$work =~ s/$offoldpat|$onoldpat/$onold/s;
				}
				else
				{
					$work =~ s/$offoldpat|$onoldpat/$offold/s;
				}

				substr($file_data{'work'}, $file_data{'ebankpos'}, 0x10000, $work);
			}

			return ($orig eq $onold) ? 1 : 0;
		}

		return -1;
	}

	return -2 if ($work =~ /($oncpat)/s);

	if ($work =~ /($offpat|$on1pat|$on2pat)/sg)
	{
		my($addr) = pos($work);
		my($orig) = $1;
		my($len) = length($orig);

		dbgout(sprintf("patch_eeprom(): Main patch point found at 0x%X\n", $addr + $file_data{'ebankpos'}));

		if (!$testmode)
		{
			substr($work, $addr - $len, $len, ($mode) ? $on1 : $off);
			substr($file_data{'work'}, $file_data{'ebankpos'}, 0x10000, $work);

			##
			# Code for multibank patching for VS05+ protections schemes.
			#

			my($check_addr) = rindex($work, chr(0x12), $addr);

			if ($addr - $check_addr < 0x18)
			{
				$check_addr = substr($work, $check_addr + 1, 2);

				dbgout(sprintf("patch_eeprom(): Checksum function found at 0x%X%02X%02X\n", $file_data{'ebankpos'} / 0x10000, ord(substr($check_addr, 0, 1)), ord(substr($check_addr, 1, 1))));

				my($check_addr_m) = quotemeta("\x90$check_addr\x02");
				my($check_fail) = 0;
				my($check_count) = 0;
				my($check_jump) = 0;
				my($check_temp) = 0;
				my($num_of_banks) = length($file_data{'work'}) / 0x10000;

				while ($file_data{'work'} =~ /$check_addr_m|\x90\xFF\xF0\x02/sg)
				{
					++$check_count;

					$check_temp = pos($file_data{'work'});
					$check_temp -= 4;
					$check_temp %= 0x10000;

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

				$check_fail = 1 if ($check_count != $num_of_banks);
				pos($file_data{'work'}) = 0;

				if (!$check_fail)
				{
					my($check_1, $check_2);

					if ($mode)
					{
						$check_1 = "\x90\xFF\xF0\x02";
						$check_2 = join('', map { chr } ( 0xE5, 0x81, 0x24, 0xFC, 0xF8, 0xE6, 0xFF, 0x22 ));
					}
					else
					{
						$check_1 = "\x90$check_addr\x02";
						$check_2 = chr(0x00) x 8;
					}

					foreach $check_temp (0x00 .. $num_of_banks - 1)
					{
						substr($file_data{'work'}, $check_jump + $check_temp * 0x10000, 4, $check_1);
					}

					substr($file_data{'work'}, $file_data{'ebankpos'} + 0xFFF0, 8, $check_2);
				}
			}

			##
			# Code for 51S@832S crossflashing
			#

			if ( $file_data{'fwfamily'} eq 'SOHW-802S/812S' ||
			     $file_data{'fwfamily'} eq 'SOHW-822S/832S' )
			{
				my($jmp) = ($mode) ? chr(0x00) : chr(0x03);

				if ($file_data{'work'} =~ s/(\x30.\x09\x90)(..)(\xE0\x60)[\x00\x03](\xD3\x80\x01)/$1$2$3$jmp$4/s)
				{
					my($addr_hwset) = $2;

					$work = substr($file_data{'work'}, 0xF0000, 0x10000);

					if ($work =~ /\x90(..)\xA3\xE0\xFF\x30\xE0\x0C\x90..\x74\x01\xF0\x90(..)\xE0\x04\xF0.{32}(.{32})\x22/sg)
					{
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

						if ($mode && $patch_area ne $spd_patch_a)
						{
							substr($work, $addr_end - 0x21, 0x20, $spd_patch_a);
							substr($work, 0xFFB0, 0x23, $patch_area . chr(0x02) . addr2bankstr($addr_end - 0x01));
							substr($file_data{'work'}, 0xF0000, 0x10000, $work);
						}
						elsif (!$mode && $patch_area eq $spd_patch_a)
						{
							substr($work, $addr_end - 0x21, 0x20, substr($work, 0xFFB0, 0x20));
							substr($work, 0xFFB0, 0x23, chr(0x00) x 0x23);
							substr($file_data{'work'}, 0xF0000, 0x10000, $work);
						}

					} # End: If found speed patching

				} # End: If first patch point is found

			} # End: If valid drive type
		}

		return ($orig eq $on1 || $orig eq $on2) ? 1 : 0;
	}

	return -1;
}

sub helper_patch_ricoh # ( testmode, mode )
{
	my($testmode, $mode) = @_;

	my($ricohidx) = find_index(["RICOHJPN", "R01", 0x02]);
	my($ricohbyte) = chr($file_data{'codes'}->[$ricohidx][3]) unless ($ricohidx < 0);

	my($offkey0) = "$ricohbyte$ricohbyte";
	my($offkey1) = "\x00\x00";
	my($onkey)  = "\xFF\xFF";
	my($curkey) = "";

	my($plusbank) = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);

	my($temp) = $plusbank;

	while ($temp =~ /\x90..\xE0\xFF(\x64[$ricohbyte\xFF]|\xE4\x00)[\x60\x70]/sg)
	{
		my($addr) = pos($temp);
		$curkey .= substr($1, 1, 1);

		substr($plusbank, $addr - 3, 2, ($mode) ? "\x64\xFF" : "\x64$ricohbyte");
	}

	if ($curkey eq $onkey || $curkey eq $offkey0 || $curkey eq $offkey1)
	{
		if (!$testmode)
		{
			substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000, $plusbank);
		}

		return ($curkey eq $onkey) ? 1 : 0;
	}

	return -1;
}

sub helper_patch_recalibrate # ( testmode, mode )
{
	my($testmode, $mode) = @_;

	my($data) = substr($file_data{'work'}, 0x70000, 0x10000);

	if ($data =~ /\x90..\xE0\xC3\x94([\x22\x24])(\x50\x03\x02...{0,16}?\x13\x13\x54\x3F)/sg)
	{
		my($addr) = pos($data);
		$addr -= (length($1) + length($2));

		if (!$testmode)
		{
			substr($data, $addr, 1, ($mode) ? chr(0x24) : chr(0x22));
			substr($file_data{'work'}, 0x70000, 0x10000, $data);
		}

		return ($1 eq chr(0x24)) ? 1 : 0;
	}

	return -1;
}

1;
