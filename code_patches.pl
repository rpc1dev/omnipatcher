sub patch_rs # ( testmode )
{
	my($testmode) = @_;
	my($i, $j, $counter, $jmppos);

	my($MIN_SEQ) = 4;
	my($changes) = 0;

	my($work) = substr($file_data{'work'}, 0x20000, 0x10000);

	for ($i = 0; $i < length($work) - 4; ++$i)
	{
		if (substr($work, $i, 3) =~ /^\x7F[\x06\x08\x0A\x0C]\x80$/)
		{
			$counter = 1;
			$jmppos = $i + ord(substr($work, $i + 3, 1));

			for ($j = $i + 4; $j < length($work) - 4 && substr($work, $j, 3) =~ /^\x7F[\x06\x08\x0A\x0C]\x80$/; $j += 4)
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
				for ($j = 0; $j < $counter * 4; $j += 4)
				{
					if (ord(substr($work, $i + $j + 1, 1)) < 0x08)
					{
						substr($work, $i + $j + 1, 1, chr(0x08));
						++$changes;
					}
				}

				last;
			}
		}
	}

	if (!$testmode)
	{
		substr($file_data{'work'}, 0x20000, 0x10000, $work);
	}

	return ($changes) ? 0 : -1;
}

sub patch_abs # ( testmode, mode )
{
	my($testmode, $mode) = @_;

	my($off) = join('', map { chr } ( 0x54, 0xEF, 0xF0, 0xE0, 0x54, 0xF7, 0xF0, 0xE4 ));
	my($on)  = join('', map { chr } ( 0x54, 0xE7, 0xF0, 0x00, 0x00, 0x00, 0x74, 0x01 ));
	my($offpat, $onpat) = (quotemeta($off), quotemeta($on));

	if ($file_data{'work'} =~ /($offpat|$onpat)/g)
	{
		my($addr) = pos($file_data{'work'});
		my($orig) = $1;
		my($len) = length($orig);

		if (!$testmode)
		{
			substr($file_data{'work'}, $addr - $len, $len, ($mode) ? $on : $off);
		}

		return ($orig eq $on) ? 1 : 0;
	}

	return -1;
}

sub patch_fb # ( testmode, mode )
{
	my($testmode, $mode) = @_;

	my($work) = substr($file_data{'work'}, 0x70000, 0x60000);

	if ($work =~ /\x74\x04\xF0\x90..\x74([\x0D\x0B])\xF0/g)
	{
		my($addr) = pos($work);

		if (!$testmode)
		{
			substr($work, $addr - 2, 1, ($mode) ? chr(0x0B) : chr(0x0D));
			substr($file_data{'work'}, 0x70000, 0x60000, $work);
		}

		return ($1 eq chr(0x0B)) ? 1 : 0;
	}
	elsif ($work =~ /\x74[\x06\x05]\xF0\x90..\x74([\x0F\x0C])\xF0/g)
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

	my($offkey) = "\x59\x00\xD0\x00 \x06 \x03 \x17\x17";
	my($onkey)  = "\xB2\x00\xA0\x01 \x02 \x02 \xFF\xFF";
	my($curkey) = "";
	my($addr);

	my($bank6) = substr($file_data{'work'}, 0x60000, 0x10000);
	my($bank7) = substr($file_data{'work'}, 0x70000, 0x10000);
	my($bankC) = substr($file_data{'work'}, 0xC0000, 0x10000);
	my($bankD) = substr($file_data{'work'}, 0xD0000, 0x10000);

	if ($bank6 =~ /\xC3\x90..\xE0\x94([\x59\xB2])\x90..\xE0\x94(\x00)\x50.\xC3\x90..\xE0\x94([\xD0\xA0])\x90..\xE0\x94([\x00\x01])\x50./g)
	{
		$addr = pos($bank6);
		$curkey .= "$1$2$3$4 ";

		substr($bank6, $addr - 24, 1, ($mode) ? chr(0xB2) : chr(0x59));
		substr($bank6, $addr - 18, 1, ($mode) ? chr(0x00) : chr(0x00));
		substr($bank6, $addr - 9, 1, ($mode) ? chr(0xA0) : chr(0xD0));
		substr($bank6, $addr - 3, 1, ($mode) ? chr(0x01) : chr(0x00));
	}

	if ($bank7 =~ /\x90..\xE0\xC3\x94([\x06\x02])\x40\x0E\xEF\x64\x08/g)
	{
		$addr = pos($bank7);
		$curkey .= "$1 ";

		substr($bank7, $addr - 6, 1, ($mode) ? chr(0x02) : chr(0x06));
	}

	if ($bankD =~ /\x90..\xE0\xB4\x01.\xE4\xFF\xFE\x7D([\x03\x02])\xFC/g)
	{
		$addr = pos($bankD);
		$curkey .= "$1 ";

		substr($bankD, $addr - 2, 1, ($mode) ? chr(0x02) : chr(0x03));
	}

	my($temp) = $bankC;

	while ($temp =~ /\x90..\xE0\xFF\x64([\x17\xFF])[\x60\x70]/g)
	{
		$addr = pos($temp);
		$curkey .= $1;

		substr($bankC, $addr - 2, 1, ($mode) ? chr(0xFF) : chr(0x17));
	}

	if ($curkey eq $onkey || $curkey eq $offkey)
	{
		if (!$testmode)
		{
			substr($file_data{'work'}, 0x60000, 0x10000, $bank6);
			substr($file_data{'work'}, 0x70000, 0x10000, $bank7);
			substr($file_data{'work'}, 0xC0000, 0x10000, $bankC);
			substr($file_data{'work'}, 0xD0000, 0x10000, $bankD);
		}

		return ($curkey eq $onkey) ? 1 : 0;
	}

	return -1;
}

sub patch_eeprom # ( testmode, mode )
{
	my($testmode, $mode) = @_;

	my($off) = join('', map { chr } ( 0xFF, 0xEE, 0x6F, 0x60, 0x02, 0xC3, 0x22 ));
	my($on1) = join('', map { chr } ( 0xFF, 0xEE, 0x6F, 0x00, 0x00, 0xD3, 0x22 ));
	my($on2) = join('', map { chr } ( 0xFF, 0xEE, 0x6F, 0xD3, 0xD3, 0xD3, 0x22 ));
	my($offpat, $on1pat, $on2pat) = (quotemeta($off), quotemeta($on1), quotemeta($on2));

	my($work) = substr($file_data{'work'}, 0x90000, 0x10000);

	if ($work =~ /($offpat|$on1pat|$on2pat)/g)
	{
		my($addr) = pos($work);
		my($orig) = $1;
		my($len) = length($orig);

		if (!$testmode)
		{
			substr($work, $addr - $len, $len, ($mode) ? $on1 : $off);
			substr($file_data{'work'}, 0x90000, 0x10000, $work);

			my($check_addr) = rindex($work, chr(0x12), $addr);

			if ($addr - $check_addr < 0x18)
			{
				$check_addr = substr($work, $check_addr + 1, 2);

				my($check_addr_m) = quotemeta("\x90$check_addr\x02");
				my($check_fail) = 0;
				my($check_count) = 0;
				my($check_jump) = 0;
				my($check_temp) = 0;

				while ($file_data{'work'} =~ /$check_addr_m|\x90\xFF\xF0\x02/g)
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

				$check_fail = 1 if ($check_count != 16);

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

					foreach $check_temp (0x00 .. 0x0F)
					{
						substr($file_data{'work'}, $check_jump + $check_temp * 0x10000, 4, $check_1);
					}

					substr($file_data{'work'}, 0x9FFF0, 8, $check_2);
				}
			}
		}

		return ($orig eq $on1 || $orig eq $on2) ? 1 : 0;
	}

	return -1;
}

1;
