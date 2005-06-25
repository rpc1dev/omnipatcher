##
# OmniPatcher for LiteOn DVD-Writers
# Firmware : LED blink control
#
# Modified: 2005/06/25, C64K
#

sub fw_led_parse # ( )
{
	if ($Current{'fw_gen'} >= 0x033 && $Current{'fw_gen'} < 0x040 && ($Current{'fw_led_status'} = fw_led_patch(1, 1)) >= 0)
	{
		if ($Current{'fw_led_status'})
		{
			my($writeblink) = (unicode2int(substr($Current{'fw'}, $Current{'fw_led_pts'}->{'write_patch'} + 1, 2)) == $Current{'fw_led_pts'}->{'blink_entry'});
			my($readblink) = (unicode2int(substr($Current{'fw'}, $Current{'fw_led_pts'}->{'read_patch'} + 1, 2)) == $Current{'fw_led_pts'}->{'blink_entry'});

			$Current{'fw_led_type'} = 0 if ($writeblink && !$readblink);
			$Current{'fw_led_type'} = 1 if (!$writeblink && $readblink);
			$Current{'fw_led_type'} = 2 if ($writeblink && $readblink);
			$Current{'fw_led_type'} = 3 if (!$writeblink && !$readblink);
			$Current{'fw_led_rate'} = ord(substr($Current{'fw'}, $Current{'fw_led_pts'}->{'blink_rate'}, 1));
		}
		else
		{
			$Current{'fw_led_type'} = 0;
			$Current{'fw_led_rate'} = $Current{'fw_led_origrate'};
		}

		$Current{'fw_led_rate'} = $FW_LED_MINRATE if ($Current{'fw_led_rate'} < $FW_LED_MINRATE);
		$Current{'fw_led_rate'} = $FW_LED_MAXRATE if ($Current{'fw_led_rate'} > $FW_LED_MAXRATE);
	}
	else
	{
		$Current{'fw_led_status'} = -1;
	}
}

sub fw_led_save # ( )
{
	return if ($Current{'fw_led_status'} < 0);

	if ( (ui_getselected($PatchesTab->{'LEDDrops'}[0]) >= 0 && ui_getselected($PatchesTab->{'LEDDrops'}[0]) != $Current{'fw_led_type'}) ||
	     (ui_getselected($PatchesTab->{'LEDDrops'}[1]) >= 0 && ui_getselected($PatchesTab->{'LEDDrops'}[1]) != $Current{'fw_led_rate'} - $FW_LED_MINRATE) )
	{
		fw_led_patch(0, 1) if ($Current{'fw_led_status'} == 0);

		my($writeblink) = (ui_getselected($PatchesTab->{'LEDDrops'}[0]) == 0 || ui_getselected($PatchesTab->{'LEDDrops'}[0]) == 2);
		my($readblink) = (ui_getselected($PatchesTab->{'LEDDrops'}[0]) == 1 || ui_getselected($PatchesTab->{'LEDDrops'}[0]) == 2);

		substr($Current{'fw'}, $Current{'fw_led_pts'}->{'write_patch'}, 3, chr(0x02) . int2unicode(($writeblink) ? $Current{'fw_led_pts'}->{'blink_entry'} : $Current{'fw_led_pts'}->{'solid_entry'}));
		substr($Current{'fw'}, $Current{'fw_led_pts'}->{'read_patch'}, 3, chr(0x02) . int2unicode(($readblink) ? $Current{'fw_led_pts'}->{'blink_entry'} : $Current{'fw_led_pts'}->{'solid_entry'}));
		substr($Current{'fw'}, $Current{'fw_led_pts'}->{'blink_rate'}, 1, chr(ui_getselected($PatchesTab->{'LEDDrops'}[1]) + $FW_LED_MINRATE));
	}
}

sub fw_led_patch # ( testmode, patchmode )
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
	# Construct the LED function pattern
	#
	my($pattern) = '';
	$pattern .= '\x90..\xE0\x64\x04\x70.\x30\x26.\x90..\xE0\x64\x03\x60.';
	$pattern .= '(?#1-ppoint1)(\x30\x27.|\x00\x80.)(?#2-ppoint1jumpover)(.{50,58})';
	$pattern .= '(?#3-blink)((?:\x90..|\x02\x3F.)\xE0(?#4-blinkcode)(\xFE\xA3\xE0\xFF\x7C\x00\x7D.\x12..\xEF)\x30\xE0.)';
	$pattern .= '(?#5-on)((?#6-oncall)(\x12..|\x02\x3F.)(?:\x78\x02\x74[\x04\x08]\xF2)?\x80.)(?#7-turnoff)((?:\x12..(?:\x78\x02\x74[\x04\x08]\xF2\x12..)?(?:\x80.)?)?\x12..(?:\x78\x02\x74[\x04\x08]\xF2)?)';
	$pattern .= '(?#8-return)(\xD0\xD0\xD0\x82\xD0\x83)';

	my($work) = substr(${$fw}, 0, 0x4000);

	if ($work =~ /$pattern/sg)
	{
		op_dbgout("fw_led_patch", sprintf("Capt'n, that's a nasty pattern, but we found 'er at %04X!", pos($work)));

		my($ppt_sjmp) = (pos($work)) - length("$1$2$3$5$7$8");
		my($ppt_write) = (pos($work)) - length("$3$5$7$8");
		my($ppt_read) = (pos($work)) - length("$5$7$8");
		my($pt_off) = (pos($work)) - length("$7$8");
		my($pt_ret) = (pos($work)) - length("$8");
		my($sjmp_ofs) = length($2);

		# Construct the code to insert
		my($ppt_insert) = 0x3FE0;
		my(@patch) = ($3, $5);
		substr($patch[0], -3, 3, "\x20\xE0\x03\x02" . int2unicode($pt_off));
		substr($patch[1], -2, 2, "\x02" . int2unicode($pt_ret));

		$Current{'fw_led_pts'} =
		{
			write_patch => $ppt_write,
			read_patch => $ppt_read,
			blink_entry => $ppt_insert,
			solid_entry => $ppt_insert + length($patch[0]),
			blink_rate => $ppt_insert + 4 + length($4) - 5,
		};

		$Current{'fw_led_origrate'} = (substr($4, 0, 1) eq chr(0xFE)) ? ord(substr($4, -5, 1)) : 0x10;

		if (substr($1, 0, 1) eq chr(0x00) && substr($3, 0, 1) eq chr(0x02) && substr($5, 0, 1) eq chr(0x02))
		{
			# Already patched
			return 1;
		}
		elsif (substr($1, 0, 1) eq chr(0x30) && substr($3, 0, 1) eq chr(0x90) && substr($5, 0, 1) eq chr(0x12))
		{
			# Not patched, no free space
			return -1 if (substr($work, $ppt_insert - 2, length($work) - ($ppt_insert - 2)) !~ /^\x00+$/s);

			# Not patched
			$patch[1] =~ s/\x78\x02\x74[\x04\x08]\xF2//s;
			substr($work, $ppt_sjmp, 3, "\x00\x80" . chr($sjmp_ofs));
			substr($work, $ppt_insert, length("$patch[0]$patch[1]"), "$patch[0]$patch[1]");
			substr(${$fw}, 0, length($work), $work);
			return 0;
		}
	}

	return -1;
}

sub fw_led_ctrltoggle # ( state )
{
	my($state) = @_;

	if ($state)
	{
		ui_setvisible($PatchesTab->{'LEDFrame'});

		foreach my $i (0 .. 1)
		{
			ui_setvisible($PatchesTab->{'LEDDropLabels'}[$i]);
			ui_setvisible($PatchesTab->{'LEDDrops'}[$i]);
		}
	}
	else
	{
		ui_setinvisible($PatchesTab->{'LEDFrame'});

		foreach my $i (0 .. 1)
		{
			ui_setinvisible($PatchesTab->{'LEDDropLabels'}[$i]);
			ui_setinvisible($PatchesTab->{'LEDDrops'}[$i]);
		}
	}
}

1;
