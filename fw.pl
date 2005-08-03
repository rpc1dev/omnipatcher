##
# OmniPatcher for Optical Drives
# Firmware : Main module
#
# Modified: 2005/08/03, C64K
#

sub fw_load # ( filename )
{
	my($filename) = @_;
	my(%new_file);

	return ui_error("Cannot find the file,\n$filename") unless (-f $filename);

	$new_file{'longname'} = $filename;
	$new_file{'shortname'} = substr($filename, rindex($filename, '\\') + 1);

	if ($new_file{'shortname'} =~ /\.(bin|exe)$/i)
	{
		$new_file{'ext'} = lc($1);

		if ($new_file{'ext'} eq 'bin')
		{
			# Binary
			loadbinary($new_file{'longname'}, \$new_file{'fw'});
		}
		elsif ($new_file{'ext'} eq 'hex')
		{
			# Intel HEX Format
			# TBD
		}
		else
		{
			# Flasher
			# Add support for other flashers here as necessary
			#
			my($xf) = com_xf_extract($new_file{'longname'}, 1);

			$new_file{'xf_fwrev'} = $xf->[0][0][0];
			$new_file{'xf_start'} = $xf->[0][0][2];
			$new_file{'xf_ext_info'} = $xf->[0][0][3];
			$new_file{'xf_exedata'} = $xf->[1][0];
			$new_file{'xf_method'} = $xf->[1][1];

			$new_file{'fw'} = $xf->[0][0][1];

			return ui_error("Unable to process this .EXE file!\nPlease make sure that the file is valid and unscrambled.\n\nIf this firmware flasher is scrambled/compressed, you\nshould consider downloading an unscrambled version\nof the flasher from one of these two websites:\n-  http://dhc014.rpc1.org/indexOEM.htm\n-  http://codeguys.rpc1.org/firmwares.html") if (length($new_file{'fw'}) == 0);
		}

		if (substr($new_file{'fw'}, 0, 1) eq chr(0x02) && (length($new_file{'fw'}) == 0x020000 || length($new_file{'fw'}) == 0x040000 || length($new_file{'fw'}) == 0x080000 || length($new_file{'fw'}) == 0x100000))
		{
			# Could be other Mtk drives, too, but we'll stick with LO until other Mtk
			# drives are added.
			#
			$new_file{'fw_manuf'} = 'lo';
		}
		else
		{
			return ui_error("Unable to recognize firmware type!\nAborting...");
		}
	}
	else
	{
		return ui_error("Unrecognized file type!\nAborting...")
	}

	op_dbgout("fw_load", "Loaded $new_file{'longname'}");
	op_dbgout("fw_load", "Drive manufacturer: $new_file{'fw_manuf'}");

	ui_settext($ObjMainCmdGrp, "Processing, please wait...");
	ui_setdisable($ObjMainCmd->{'Load'});
	ui_setdisable($ObjMainCmd->{'Save'});
	ui_doevents();

	%Current = %new_file;
	fw_parse();
}

sub fw_parse # ( )
{
	fw_parse_lo() if ($Current{'fw_manuf'} eq 'lo');
	fw_init();
}

sub fw_parse_lo # ( )
{
	##
	# Set drive type
	#
	{
		if (length($Current{'fw'}) == 0x100000)
		{
			$Current{'fw_type'} = 'dvdrw';
			$FlagTabEnabledStatus[$UI_TABID_MEDIA] = 1;
			$FlagTabEnabledStatus[$UI_TABID_PATCHES] = 1;
		}
		elsif ($Current{'fw'} =~ /VIDEO_TS|NOSMARTX/s)
		{
			$Current{'fw_type'} = (length($Current{'fw'}) == 0x80000) ? 'combo' : 'dvdrom';
			$FlagTabEnabledStatus[$UI_TABID_MEDIA] = 0;
			$FlagTabEnabledStatus[$UI_TABID_PATCHES] = 1;
		}
		else
		{
			$Current{'fw_type'} = 'other';
			$FlagTabEnabledStatus[$UI_TABID_MEDIA] = 0;
			$FlagTabEnabledStatus[$UI_TABID_PATCHES] = 0;
		}

		op_dbgout("fw_parse_lo", "Drive type: $Current{'fw_type'}");
	}

	##
	# Gather basic firmware info
	#
	{
		@Current{'fw_info_rulelvl', 'fw_vid', 'fw_pid', 'fw_stdfwrev', 'fw_timestamp', 'fw_intfwrev'} =
			map { rtrim($_) } ($Current{'fw_type'} eq 'dvdrw') ?
			getfwid_mtk(\$Current{'fw'}, [ 1, 2 ], 10) :
			getfwid_mtk(\$Current{'fw'}, [ 1, 2, 3, 4 ], 8);

		$Current{'fw_dispfwrev'} = format_fwrev($Current{'fw_stdfwrev'}, $Current{'fw_intfwrev'});
		$Current{'fw_date_array'} = normalize_timestamp($Current{'fw_timestamp'});
		$Current{'fw_date_num'} = sprintf("%04d%02d%02d", @{$Current{'fw_date_array'}}) + 0;
		$Current{'fw_enable_driveid'} = ($Current{'fw_info_rulelvl'} > 0);

		if ($Current{'fw_intfwrev'} eq '' && $Current{'fw_stdfwrev'} eq '')
		{
			$Current{'fw_fwrev'} = ' ';
		}
		elsif ($Current{'fw_intfwrev'} eq '' && $Current{'fw_stdfwrev'} ne '')
		{
			op_dbgout("fw_parse_lo", "fw_intfwrev is undefined; switching to fw_stdfwrev");
			$Current{'fw_fwrev'} = $Current{'fw_stdfwrev'};
		}
		else
		{
			$Current{'fw_fwrev'} = $Current{'fw_intfwrev'};
		}

		map { $_ = ($_ ne '') ? $_ : 'Unknown' } @Current{'fw_vid', 'fw_pid', 'fw_stdfwrev', 'fw_timestamp', 'fw_intfwrev', 'fw_dispfwrev'};

		op_dbgout("fw_parse_lo", "Drive ID ($Current{'fw_info_rulelvl'}): $Current{'fw_vid'} $Current{'fw_pid'}, $Current{'fw_fwrev'}");
		op_dbgout("fw_parse_lo", "Normalized drive timestamp: $Current{'fw_date_num'}");
	}

	##
	# Check for a bank 0 call and rebank if necessary
	#
	{
		if (length($Current{'fw'}) >= 0x80000)
		{
			my($bank0) = substr($Current{'fw'}, 0x4000, 0xC000);
			my($pgpat) = (length($Current{'fw'}) == 0x100000) ? '[\x0F\x1F]' : '\x07';

			if ($bank0 =~ /(\xE5\x90\x54($pgpat)\xB4\x00)/sg)
			{
				$Current{'fw_bank0call'} = [ ((pos($bank0)) - length($1)) + ((ord($2) == 0x1F) ? 0 : 0x4000), ord($2) ];
				op_dbgout("fw_parse_lo", sprintf("Bank 0 call found: %04X / %02X", @{$Current{'fw_bank0call'}}));
			}
			else
			{
				ui_warning("This firmware does not appear to be valid!");
			}

			if ($Current{'fw_bank0call'}->[1] == 0x1F)
			{
				op_dbgout("fw_parse_lo", "Firmware rebanking is required");
				$Current{'fw_rebanked'} = 1;
				$Current{'fw_common_len'} = ($Current{'fw_fwrev'} =~ /^[UV]/ && substr($Current{'fw'}, -16) =~ /^[A-Z ]+$/s) ? 0x3000 : 0x4000;
				$Current{'fw'} = fw_mtk_rebank(\$Current{'fw'}, \$Current{'fw_bootcode'}, 1, $Current{'fw_common_len'});
			}
			else
			{
				op_dbgout("fw_parse_lo", "Firmware rebanking is NOT required");
				$Current{'fw_rebanked'} = 0;
			}
		}

		$Current{'fw_nbanks'} = length($Current{'fw'}) >> 16;
		$Current{'fw_nbanks'}++ if (length($Current{'fw'}) & 0xFFFF);
		op_dbgout("fw_parse_lo", sprintf("Number of banks: 0x%02X (%d)", $Current{'fw_nbanks'}, $Current{'fw_nbanks'}));
	}

	##
	# Gather general firmware info
	#
	{
		$Current{'fw_saveable'} = 1;
		my($fw_letter) = substr($Current{'fw_fwrev'}, 0, 1);

		if ($Current{'fw_type'} eq 'dvdrw')
		{
			# Read from the table
			#
			if (exists($FW_PARAMS_LO_DVDRW{$fw_letter}))
			{
				if ($fw_letter eq 'G' && $Current{'fw'} =~ /LDW\-451S/s)
				{
					$fw_letter = lc($fw_letter);
				}
				elsif ($fw_letter eq 'B' && $Current{'fw_fwrev'} =~ /^B(?:S4|YX|8S[3-Z])/s)
				{
					$fw_letter = lc($fw_letter);
				}
				elsif ($fw_letter =~ /[UV]/ && $Current{'fw_rebanked'})
				{
					$fw_letter = lc($fw_letter);

					if (substr($Current{'fw'}, -16) !~ /^[A-Z ]+$/s)
					{
						$Current{'fw_saveable'} = 0;
						$Current{'fw_enable_driveid'} = 0;

						$Current{'fw_vid'} = $Current{'fw_pid'} = $Current{'fw_stdfwrev'} = "Unknown";
						$Current{'fw_dispfwrev'} = $Current{'fw_intfwrev'};

						ui_error("LtnFW/LtnFlash cannot be used to dump the firmware for this drive type!\nThis firmware is damaged! DO NOT attempt to flash this firmware!");
					}
				}
			}
			elsif ($fw_letter eq '6')
			{
				$fw_letter = 'P';
			}
			else
			{
				$fw_letter = '~';
				ui_error('Unable to classify firmware.');
			}

			@Current{'fw_gen', 'fw_family', 'fw_ebank', 'fw_rbank', 'media_pbank', 'media_dbank', 'media_limits', 'media_count_expected', 'fw_rs_limits', 'fw_rs_defaults', 'fw_idlist'} = @{$FW_PARAMS_LO_DVDRW{$fw_letter}};

			# Correct for deviations in the read bank address
			#
			if ($Current{'fw_gen'} > 0 && substr($Current{'fw'}, $Current{'fw_rbank'}, 0x10000) !~ /\x02\xFF.\x00|\xE5\x24\x24\x7E|\xE5\x24\x12/s)
			{
				op_dbgout("fw_parse_lo", sprintf("Read routine not found in bank 0x%02X; searching for new bank", $Current{'fw_rbank'} >> 16));

				if ($Current{'fw'} =~ /(?:\x02\xFF.\x00|\xE5\x24\x24\x7E)\x60|\xE5\x24\x12..(?:...){5,15}?\x00{2}/sg)
				{
					$Current{'fw_rbank'} = (pos($Current{'fw'})) & 0xFF0000;
					op_dbgout("fw_parse_lo", sprintf("... Changing read bank to 0x%02X", $Current{'fw_rbank'} >> 16));
				}

				pos($Current{'fw'}) = 0;
			}

			# Correct for deviations in the plus/dash bank addresses
			#
			foreach my $check ( [ 'media_pbank', $MEDIA_SAMPLES_SHORT[$MEDIA_TYPE_DVD_PR] ], [ 'media_dbank', $MEDIA_SAMPLES_SHORT[$MEDIA_TYPE_DVD_DR] ] )
			{
				if ($Current{$check->[0]} > 0 && substr($Current{'fw'}, $Current{$check->[0]}, 0x10000) !~ /$check->[1]/s)
				{
					op_dbgout("fw_parse_lo", "No media codes found in $check->[0]; searching for new bank");

					if ($Current{'fw'} =~ /$check->[1]/sg)
					{
						op_dbgout("fw_parse_lo", sprintf("Changing %s from 0x%02X to 0x%02X", $check->[0], $Current{$check->[0]} >> 16, (pos($Current{'fw'})) >> 16));
						$Current{$check->[0]} = (pos($Current{'fw'})) & 0xFF0000;
					}

					pos($Current{'fw'}) = 0;
				}
			}
		}
		elsif ($Current{'fw_type'} eq 'combo')
		{
			# Read from the table
			#
			if (exists($FW_PARAMS_LO_COMBO{$fw_letter}))
			{
				if ($fw_letter eq 'R' && $Current{'fw_fwrev'} !~ /^.[0-9A-Z]{3}/s)
				{
					$fw_letter = lc($fw_letter);
				}
			}
			else
			{
				$fw_letter = '~';
				ui_error('Unable to classify firmware.');
			}

			@Current{'fw_family', 'fw_rs_limits', 'fw_rs_defaults', 'fw_idlist'} = @{$FW_PARAMS_LO_COMBO{$fw_letter}};
		}
		elsif ($Current{'fw_type'} eq 'dvdrom')
		{
			# Read from the table
			#
			if (exists($FW_PARAMS_LO_DVDROM{$fw_letter}))
			{
			}
			else
			{
				$fw_letter = '~';
				ui_error('Unable to classify firmware.');
			}

			@Current{'fw_family', 'fw_rs_limits', 'fw_rs_defaults', 'fw_idlist'} = @{$FW_PARAMS_LO_DVDROM{$fw_letter}};
		}
		else
		{
			$Current{'fw_saveable'} = 0;
			$Current{'fw_enable_driveid'} = 0;
			$Current{'fw_family'} = "N/A";
		}
	}

	##
	# Call various parsing functions
	#
	{
		media_parse();
		media_strat_init();
		fw_led_parse();
		fw_rs_parse();
	}
}

sub fw_init # ( )
{
	##
	# Drive tab
	#
	{
		my($make_infopair) = sub { sprintf("%-22s : %s", @_) };
		my(@drive_info);

		push(@drive_info, $make_infopair->("Drive type", $Current{'fw_family'}));
		push(@drive_info, $make_infopair->("Vendor ID string", $Current{'fw_vid'}));
		push(@drive_info, $make_infopair->("Product ID string", $Current{'fw_pid'}));
		push(@drive_info, $make_infopair->("Standard firmware rev.", $Current{'fw_stdfwrev'}));
		push(@drive_info, $make_infopair->("Internal firmware rev.", $Current{'fw_intfwrev'}));
		push(@drive_info, $make_infopair->("Firmware timestamp", ltrim($Current{'fw_timestamp'})));

		ui_settext($DriveTab->{'InfoBox'}, join("\r\n", @drive_info));
		#ui_settext($DriveTab->{'InfoBox'}, sprintf("\t[ %-10s, %-18s ],\n", "'$Current{'fw_vid'}'", "'$Current{'fw_pid'}'"));

		if ($Current{'fw_enable_driveid'})
		{
			push( @{$Current{'fw_driveids'}},
				[ "Keep the current drive ID; make no changes", [ $Current{'fw_vid'}, $Current{'fw_pid'} ] ],
				map { [ sprintf("Change to \"%-8s %-16s %-4s\"", @{$_}, $Current{'fw_stdfwrev'}), $_ ] }
				grep { $_->[0] ne $Current{'fw_vid'} || $_->[1] ne $Current{'fw_pid'} } @{$Current{'fw_idlist'}}
			);

			push(@{$Current{'fw_driveids'}}, [ $FW_CUSTOMID_CAPTION, [ '', '' ] ]) if ($FW_ALLOW_CUSTOM_DRIVEIDS);

			map { ui_setenable($_) } ($DriveTab->{'Selector'}, @{$DriveTab->{'FieldLabels'}}, @{$DriveTab->{'Fields'}});
			ui_clear($DriveTab->{'Selector'});
			ui_add($DriveTab->{'Selector'}, map { $_->[0] } @{$Current{'fw_driveids'}} );
			ui_select($DriveTab->{'Selector'}, 0);
			fw_proc_drivesel(0);
		}
		else
		{
			map { ui_setdisable($_) } ($DriveTab->{'Selector'}, @{$DriveTab->{'FieldLabels'}}, @{$DriveTab->{'Fields'}});
			map { ui_settext($_, "") } (@{$DriveTab->{'Fields'}});
			ui_clear($DriveTab->{'Selector'});
		}

		ui_doevents();
	}

	##
	# Media tab
	#
	if ($Current{'fw_type'} eq 'dvdrw')
	{
		if ($Current{'media_count'} == 0)
		{
			ui_error("OmniPatcher was unable to locate and/or\nparse the media code tables.\n\nYou may need to upgrade to a newer\nversion of OmniPatcher.");
		}
		elsif ($Current{'media_count'} < $Current{'media_count_expected'})
		{
			ui_error("OmniPatcher found fewer media codes than it\nhad expected to find.\n\nThe media code table may be incomplete.");
		}

		ui_clear($MediaTab->{'List'});
		ui_add($MediaTab->{'List'}, map { ($_->[1] == $_->[3]) ? " $_->[5] : $MEDIA_TYPE_NAME[$_->[0]]" : "!$_->[5] : $MEDIA_TYPE_NAME[$_->[0]]" } @{$Current{'media_table'}} );
		media_proc_listclick(-1);
		ui_doevents();

		my(@media_info);

		push(@media_info, "Media Codes");
		push(@media_info, "===========");
		push(@media_info, sprintf("%-5s : %3d", 'Total', $Current{'media_count'}));
		push(@media_info, map { sprintf("%-5s : %3d", $MEDIA_TYPE_NAME[$_], $Current{'media_type_count'}->[$_]) } grep { $Current{'media_type_count'}->[$_] > 0 } (@{$MEDIA_TYPES[$MEDIA_TYPE_DVD_P]}, @{$MEDIA_TYPES[$MEDIA_TYPE_DVD_D]}));
		push(@media_info, "", "Max. Write Speeds");
		push(@media_info, "=================");
		push(@media_info, map { sprintf("%-5s : %3sx", $MEDIA_TYPE_NAME[$_], ($Current{'media_limits'}->[$_] != 2) ? $Current{'media_limits'}->[$_] : 2.4) } grep { $Current{'media_limits'}->[$_] > 0 } (@{$MEDIA_TYPES[$MEDIA_TYPE_DVD_P]}));
		push(@media_info, map { sprintf("%-5s : %3dx", $MEDIA_TYPE_NAME[$_], $Current{'media_limits'}->[$_]) } grep { $Current{'media_limits'}->[$_] > 0 } (@{$MEDIA_TYPES[$MEDIA_TYPE_DVD_D]}));

		ui_settext($MediaTab->{'InfoBox'}, join("\r\n", @media_info));

		if ($Current{'media_strat_status'} < 0)
		{
			ui_settext($MediaTab->{'StratLabel'}, $UI_STRATLABEL[0]);
			ui_setdisable($MediaTab->{'StratLabel'});
		}
		else
		{
			if ($Current{'media_strat'}->[$MEDIA_TYPE_DVD_PR]{'status'} < 0)
			{
				ui_settext($MediaTab->{'StratLabel'}, $UI_STRATLABEL[2]);
			}
			elsif ($Current{'media_strat'}->[$MEDIA_TYPE_DVD_DR]{'status'} < 0)
			{
				ui_settext($MediaTab->{'StratLabel'}, $UI_STRATLABEL[1]);
			}
			else
			{
				ui_settext($MediaTab->{'StratLabel'}, $UI_STRATLABEL[0]);
			}

			ui_setenable($MediaTab->{'StratLabel'});
		}

		ui_setenable($MediaTab->{'List'});
		ui_setenable($MediaTab->{'Tweak'});
		ui_setenable($MediaTab->{'ExtCmds'});
		ui_doevents();
	}

	##
	# Patches tab
	#
	{
		# Flip through the patches and set them up
		#
		foreach my $key (@FW_PATCH_KEYS)
		{
			ui_doevents();

			if ($FW_PATCHES{$key}->[3]())
			{
				$Current{'fw_patch_status'}->{$key} = $FW_PATCHES{$key}->[1](1, 1);
				op_dbgout("fw_init", "Patch function for '$key' returned from test mode with $Current{'fw_patch_status'}->{$key}");

				($Current{'fw_patch_status'}->{$key} < 0) ?
				ui_setdisable($PatchesTab->{$key}) :
				ui_setenable($PatchesTab->{$key});

				($Current{'fw_patch_status'}->{$key} == 1 || $Current{'fw_patch_status'}->{$key} == -2) ?
				ui_setcheck($PatchesTab->{$key}, 1) :
				ui_setcheck($PatchesTab->{$key}, 0);
			}
			else
			{
				$Current{'fw_patch_status'}->{$key} = -1;
			}
		}

		# Flip through the patches decide which ones will be shown
		# This is done in a separate loop to compensate for the reflow lag
		#
		foreach my $key (@FW_PATCH_KEYS)
		{
			($FW_PATCHES{$key}->[3]() && $Current{'fw_patch_status'}->{$key} != -3) ?
			ui_setvisible($PatchesTab->{$key}) :
			ui_setinvisible($PatchesTab->{$key});
		}

		ui_reflow_patches();

		# Set up read-speed
		#
		if ($Current{'fw_rs_status'} >= 0)
		{
			foreach my $i (@FW_RS_IDX)
			{
				my($speed) = $Current{'fw_rs'}->[$i][0];
				$speed = 4 if ($speed < 4);
				$speed = $Current{'fw_rs_limits'}->[$i] if ($speed > $Current{'fw_rs_limits'}->[$i]);

				ui_doevents();
				ui_clear($PatchesTab->{'Drops'}[$i]);
				ui_add($PatchesTab->{'Drops'}[$i], map { "$FW_RS_IDX2SPD[$i][$_]x" } (0 .. $FW_RS_SPD2IDX[$i][$Current{'fw_rs_limits'}->[$i]]));
				ui_select($PatchesTab->{'Drops'}[$i], $FW_RS_SPD2IDX[$i][$speed]);

				ui_setenable($PatchesTab->{'DropLabels'}[$i]);
				ui_setenable($PatchesTab->{'Drops'}[$i]);
			}
		}
		else
		{
			foreach my $i (@FW_RS_IDX)
			{
				ui_doevents();
				ui_clear($PatchesTab->{'Drops'}[$i]);
				ui_setdisable($PatchesTab->{'DropLabels'}[$i]);
				ui_setdisable($PatchesTab->{'Drops'}[$i]);
			}
		}

		# Set up LED blink controls
		#
		if ($Current{'fw_led_status'} >= 0)
		{
			ui_select($PatchesTab->{'LEDDrops'}[0], $Current{'fw_led_type'});
			ui_select($PatchesTab->{'LEDDrops'}[1], $Current{'fw_led_rate'} - $FW_LED_MINRATE);
			fw_led_ctrltoggle(1)
		}
		else
		{
			fw_led_ctrltoggle(0)
		}
	}

	MainTabstrip_Change();
	ui_settext($ObjMainCmdGrp, ($Current{'fw_dispfwrev'} eq 'Unknown') ? $Current{'shortname'} : "$Current{'fw_dispfwrev'} ($Current{'shortname'})");
	ui_setenable($ObjMainCmd->{'Load'});
	ui_setenable($ObjMainCmd->{'Save'}) if ($Current{'fw_saveable'});
}

sub fw_save # ( filename )
{
	ui_setdisable($ObjMainCmd->{'Load'});
	ui_setdisable($ObjMainCmd->{'Save'});
	my(%original) = %Current;

	fw_save_lo(@_) if ($Current{'fw_manuf'} eq 'lo');

	%Current = %original;
	ui_setenable($ObjMainCmd->{'Load'});
	ui_setenable($ObjMainCmd->{'Save'});
}

sub fw_save_lo # ( filename )
{
	my($filename) = @_;

	##
	# Media
	#
	op_dbgout("fw_save_lo", "Saving media changes/switches");
	media_save_changes();
	media_strat_save() if ($Current{'media_strat_status'} >= 0);

	##
	# General Patches
	#
	{
		foreach my $key (@FW_PATCH_KEYS)
		{
			if ( $FW_PATCHES{$key}->[3]() && $Current{'fw_patch_status'}->{$key} >= 0 &&
			     ($FW_PATCHES{$key}->[2] || $Current{'fw_patch_status'}->{$key} != ui_getcheck($PatchesTab->{$key})) )
			{
				op_dbgout("fw_save_lo", "Calling patch function for '$key'...");
				$FW_PATCHES{$key}->[1](0, ui_getcheck($PatchesTab->{$key}));
			}
		}

		fw_led_save();
		fw_rs_save();
	}

	##
	# Drive ID
	#
	if ( $Current{'fw_enable_driveid'} &&
	     ($Current{'fw_vid'} ne ui_gettext($DriveTab->{'Fields'}[0]) ||
	     $Current{'fw_pid'} ne ui_gettext($DriveTab->{'Fields'}[1]) ||
	     $Current{'fw_stdfwrev'} ne ui_gettext($DriveTab->{'Fields'}[2])) )
	{
		op_dbgout("fw_save_lo", "Patching drive ID");

		my($omit) = ($Current{'fw_info_rulelvl'} >= 2 && $Current{'fw_type'} ne 'dvdrw' && $Current{'fw_type'} ne 'combo') ? 0 : 0x4000;
		my($work) = substr($Current{'fw'}, $omit);

		my(@pat) =
		(
			quotemeta(sprintf("%-8s%-16s%-4s", $Current{'fw_vid'}, $Current{'fw_pid'}, $Current{'fw_stdfwrev'})),
			quotemeta(rev_end(sprintf("%-8s%-8s%-16s", $Current{'fw_stdfwrev'}, $Current{'fw_vid'}, $Current{'fw_pid'}))),
			quotemeta(rev_end(sprintf("%-8s%-8s %-16s ", $Current{'fw_stdfwrev'}, $Current{'fw_vid'}, $Current{'fw_pid'}))),
		);

		my(@replace) =
		(
			sprintf("%-8s%-16s%-4s", ui_gettext($DriveTab->{'Fields'}[0]), ui_gettext($DriveTab->{'Fields'}[1]), ui_gettext($DriveTab->{'Fields'}[2])),
			rev_end(sprintf("%-8s%-8s%-16s", ui_gettext($DriveTab->{'Fields'}[2]), ui_gettext($DriveTab->{'Fields'}[0]), ui_gettext($DriveTab->{'Fields'}[1]))),
			rev_end(sprintf("%-8s%-8s %-16s ", ui_gettext($DriveTab->{'Fields'}[2]), ui_gettext($DriveTab->{'Fields'}[0]), ui_gettext($DriveTab->{'Fields'}[1]))),
		);

		if ($work =~ s/$pat[0]/$replace[0]/sg && ($work =~ s/$pat[1]/$replace[1]/sg || $work =~ s/$pat[2]/$replace[2]/sg || 1))
		{
			substr($Current{'fw'}, $omit, length($work), $work);
			op_dbgout("fw_save_lo", "... Drive ID patched successfully");
		}
		else
		{
			op_dbgout("fw_save_lo", "... Oops, unexpected drive ID patching error!");
		}
	}

	##
	# Check to make sure that the firmware hasn't been messed up
	#
	return ui_error("Unexpected error encountered during patching.\nFile not saved.") if (!fw_mtk_isokay());

	##
	# Rebanking
	#
	if ($Current{'fw_rebanked'})
	{
		op_dbgdumpfw() if (0);	# Change to 1 to dump the firmware before rebanking; useful for debugging
		$Current{'fw'} = fw_mtk_rebank(\$Current{'fw'}, \$Current{'fw_bootcode'}, 0, $Current{'fw_common_len'});
	}

	##
	# If, after all that, the firmware size is still all right, then
	# we're good to go!
	#
	if (length($Current{'fw'}) > 0 && (length($Current{'fw'}) & 0xFFFF) == 0)
	{
		my($outdata, $scrambled);

		if ($Current{'ext'} eq "bin" || $filename =~ /\.bin$/i)
		{
			$outdata = $Current{'fw'};
		}
		else
		{
			$scrambled = com_xf_recrypt(\$Current{'fw'}, $Current{'xf_method'}, $Current{'xf_fwrev'}, $Current{'xf_ext_info'});
			$outdata = $Current{'xf_exedata'};
			substr($outdata, $Current{'xf_start'}, length($scrambled), $scrambled);
		}

		if (open file, ">$filename")
		{
			binmode file;
			print file $outdata;
			close file;

			ui_infobox("The patched file was successfully created.", "Done!");
		}
		else
		{
			ui_error("File access error!");
		}
	}
	else
	{
		ui_error("Unexpected error encountered during patching.\nFile not saved.");
	}
}

sub fw_proc_drivesel # ( idx )
{
	my($idx) = @_;

	if ($idx >= 0)
	{
		if ($Current{'fw_driveids'}->[$idx][0] eq $FW_CUSTOMID_CAPTION)
		{
			map { ui_setreadonly($_, 0) } @{$DriveTab->{'Fields'}};
		}
		else
		{
			map { ui_setreadonly($_, 1) } @{$DriveTab->{'Fields'}};
			ui_settext($DriveTab->{'Fields'}[0], $Current{'fw_driveids'}->[$idx][1][0]);
			ui_settext($DriveTab->{'Fields'}[1], $Current{'fw_driveids'}->[$idx][1][1]);
			ui_settext($DriveTab->{'Fields'}[2], $Current{'fw_stdfwrev'});
		}
	}
}

1;
