##
# OmniPatcher for LiteOn DVD-Writers
# Firmware : Main module
#
# Modified: 2005/06/13, C64K
#

sub fw_rebank # ( &data, &bootcode, mode )
{
	my($data, $bootcode, $mode) = @_;
	my($ret, $i);

	if ($mode == 1 && length(${$data}) == 0x100000)
	{
		for ($i = 0; $i < 0x15; ++$i)
		{
			$ret .= substr(${$data}, 0x4000, 0x4000);
			$ret .= substr(${$data}, 0xC000 * $i + 0x8000, ($i < 0x14) ? 0xC000 : 0x8000);
		}

		# Note that the mode #1 return does so in two different ways.
		# There is the standard function return for the rebanked firmware
		# as well as a by-reference return for the bootcode!
		#
		${$bootcode} = substr(${$data}, 0x0, 0x4000);
	}
	elsif ($mode == 0 && length(${$data}) == 0x14C000)
	{
		$ret = ${$bootcode} . substr(${$data}, 0x000000, 0x4000);

		for ($i = 0; $i < 0x15; ++$i)
		{
			$ret .= substr(${$data}, 0x10000 * $i + 0x4000, ($i < 0x14) ? 0xC000 : 0x8000);
		}
	}
	else
	{
		$ret = ${$data};
	}

	return $ret;
}

sub fw_isokay # ( )
{
	foreach my $i (0 .. $Current{'fw_nbanks'} - 1)
	{
		return 0 if (substr($Current{'fw'}, $i << 16, 1) ne chr(0x02));
	}

	return 1;
}

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
			loadbinary($new_file{'longname'}, \$new_file{'fw'});

			return ui_error("Invalid firmware size!\nAborting...") if (length($new_file{'fw'}) != 0x100000);
			return ui_error("This firmware appears to be corrupted!\nAborting...") if (substr($new_file{'fw'}, 0, 1) ne chr(0x02));
		}
		else
		{
			my($xf) = com_xf_extract($new_file{'longname'}, 1);

			$new_file{'xf_fwrev'} = $xf->[0][0][0];
			$new_file{'xf_start'} = $xf->[0][0][2];
			$new_file{'xf_ext_info'} = $xf->[0][0][3];
			$new_file{'xf_exedata'} = $xf->[1][0];
			$new_file{'xf_method'} = $xf->[1][1];

			$new_file{'fw'} = $xf->[0][0][1];

			return ui_error("Unable to process this .EXE file!\nPlease make sure that the file is valid and unscrambled.\n\nIf this firmware flasher is scrambled/compressed, you\nshould consider downloading an unscrambled version\nof the flasher from one of these two websites:\n-  http://dhc014.rpc1.org/indexOEM.htm\n-  http://codeguys.rpc1.org/firmwares.html") if (length($new_file{'fw'}) == 0);
			return ui_error("Invalid firmware size!\nAborting...") if (length($new_file{'fw'}) != 0x100000);
		}
	}
	else
	{
		return ui_error("Unrecognized file type!\nAborting...")
	}

	op_dbgout("fw_load", "Loaded $new_file{'longname'}");

	%Current = %new_file;
	fw_parse();
}

sub fw_parse # ( )
{
	##
	# Gather basic firmware info
	#
	{
		@Current{'fw_vid', 'fw_pid', 'fw_stdfwrev', 'fw_timestamp', 'fw_intfwrev'} = map { rtrim($_) } getfwid(\$Current{'fw'}, 1);
		@Current{'fw_vid', 'fw_pid', 'fw_timestamp'} = map { ($_ ne '') ? $_ : 'Unknown' } @Current{'fw_vid', 'fw_pid', 'fw_timestamp'};

		$Current{'fw_date_array'} = normalize_timestamp($Current{'fw_timestamp'});
		$Current{'fw_date_num'} = sprintf("%04d%02d%02d", @{$Current{'fw_date_array'}}) + 0;

		if ($Current{'fw_intfwrev'} eq '' && $Current{'fw_stdfwrev'} eq '')
		{
			$Current{'fw_fwrev'} = ' ';
		}
		elsif ($Current{'fw_intfwrev'} eq '' && $Current{'fw_stdfwrev'} ne '')
		{
			op_dbgout("fw_parse", "fw_intfwrev is undefined; switching to fw_stdfwrev");
			$Current{'fw_fwrev'} = $Current{'fw_stdfwrev'};
		}
		else
		{
			$Current{'fw_fwrev'} = $Current{'fw_intfwrev'};
		}

		op_dbgout("fw_parse", "Drive ID: $Current{'fw_vid'} $Current{'fw_pid'}, $Current{'fw_fwrev'}");
		op_dbgout("fw_parse", "Normalized drive timestamp: $Current{'fw_date_num'}");
	}

	##
	# Check for a bank 0 call and rebank if necessary
	#
	{
		my($bank0) = substr($Current{'fw'}, 0x4000, 0xC000);

		if ($bank0 =~ /(\xE5\x90\x54([\x0F\x1F])\xB4\x00)/sg)
		{
			$Current{'fw_bank0call'} = [ ((pos($bank0)) - length($1)) + ((ord($2) == 0x0F) ? 0x4000 : 0), ord($2) ];
			op_dbgout("fw_parse", sprintf("Bank 0 call found: %04X / %02X", @{$Current{'fw_bank0call'}}));
		}
		else
		{
			ui_warning("This firmware does not appear to be valid!");
		}

		if ($Current{'fw_bank0call'}->[1] == 0x1F)
		{
			op_dbgout("fw_parse", "Firmware rebanking is required");
			$Current{'fw_rebanked'} = 1;
			$Current{'fw_nbanks'} = 0x15;
			$Current{'fw'} = fw_rebank(\$Current{'fw'}, \$Current{'fw_bootcode'}, 1);
		}
		else
		{
			op_dbgout("fw_parse", "Firmware rebanking is NOT required");
			$Current{'fw_rebanked'} = 0;
			$Current{'fw_nbanks'} = 0x10;
		}
	}

	##
	# Gather general firmware info
	#
	{
		my($fw_letter) = substr($Current{'fw_fwrev'}, 0, 1);
		my($check);

		# Read from the table
		#
		if (exists($FW_PARAMS{$fw_letter}))
		{
			if ($fw_letter eq 'G' && $Current{'fw'} =~ /LDW\-451S/s)
			{
				$fw_letter = 'g';
			}
			elsif ($fw_letter eq 'B' && $Current{'fw_fwrev'} =~ /^B(?:S4|YX)/s)
			{
				$fw_letter = 'C';
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

		@Current{'fw_gen', 'fw_family', 'fw_ebank', 'media_pbank', 'media_dbank', 'media_limits', 'media_count_expected', 'fw_idlist'} = @{$FW_PARAMS{$fw_letter}};
		$Current{'fw_fwrev'} = 'Unknown' if ($Current{'fw_fwrev'} eq ' ');

		# Correct for deviations in the plus/dash bank addresses
		#
		foreach $check ( [ 'media_pbank', $MEDIA_SAMPLES_SHORT[$MEDIA_TYPE_DVD_PR] ], [ 'media_dbank', $MEDIA_SAMPLES_SHORT[$MEDIA_TYPE_DVD_DR] ] )
		{
			if (getaddr_bank($Current{$check->[0]}) > 0 && substr($Current{'fw'}, getaddr_full($Current{$check->[0]}), 0x10000) !~ /$check->[1]/s)
			{
				op_dbgout("fw_parse", "No media codes found in $check->[0]; searching for new bank");

				if ($Current{'fw'} =~ /$check->[1]/sg)
				{
					op_dbgout("fw_parse", sprintf("Changing %s from 0x%02X to 0x%02X", $check->[0], getaddr_bank($Current{$check->[0]}), getaddr_bank(pos($Current{'fw'}))));
					$Current{$check->[0]} = [ getaddr_bank(pos($Current{'fw'})) ];
				}

				pos($Current{'fw'}) = 0;
			}
		}
	}

	media_parse();
	media_strat_init();
	fw_rs_parse();

	##
	# Pass the torch
	#
	fw_init();
}

sub fw_init # ( )
{
	##
	# Drive tab
	#
	{
		map { ui_setenable($_) } ($DriveTab->{'Selector'}, @{$DriveTab->{'FieldLabels'}}, @{$DriveTab->{'Fields'}});

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

		push( @{$Current{'fw_driveids'}},
			[ "Keep the current drive ID; make no changes", [ $Current{'fw_vid'}, $Current{'fw_pid'} ] ],
			map { [ sprintf("Change to \"%-8s %-16s %-4s\"", @{$_}, $Current{'fw_stdfwrev'}), $_ ] }
			grep { $_->[0] ne $Current{'fw_vid'} || $_->[1] ne $Current{'fw_pid'} } @{$Current{'fw_idlist'}}
		);

		push(@{$Current{'fw_driveids'}}, [ $FW_CUSTOMID_CAPTION, [ '', '' ] ]) if ($FW_ALLOW_CUSTOM_DRIVEIDS);

		ui_clear($DriveTab->{'Selector'});
		ui_add($DriveTab->{'Selector'}, map { $_->[0] } @{$Current{'fw_driveids'}} );
		ui_select($DriveTab->{'Selector'}, 0);
		fw_proc_drivesel(0);
		ui_doevents();
	}

	##
	# Media tab
	#
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
		ui_setenable($MediaTab->{'Report'});
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
			my(@maxspeeds) = ($Current{'fw_gen'} < 0x030) ? (12, 8, 8, 8, 8) : (16, 16, 16, 16, 12);

			foreach my $i (@FW_RS_IDX)
			{
				my($speed) = $Current{'fw_rs'}->[$i][0];
				$speed = 4 if ($speed < 4);
				$speed = $maxspeeds[$i] if ($speed > $maxspeeds[$i]);

				ui_doevents();
				ui_clear($PatchesTab->{'Drops'}[$i]);
				ui_add($PatchesTab->{'Drops'}[$i], map { "$FW_RS_IDX2SPD[$i][$_]x" } (0 .. $FW_RS_SPD2IDX[$i][$maxspeeds[$i]]));
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
	}

	ui_settext($ObjMainCmdGrp, ($Current{'fw_fwrev'} eq 'Unknown') ? $Current{'shortname'} : "$Current{'fw_fwrev'} ($Current{'shortname'})");
	ui_setenable($ObjMainCmd->{'Save'});
}

sub fw_save # ( filename )
{
	my($filename) = @_;
	my($original) = $Current{'fw'};

	##
	# Media
	#
	op_dbgout("fw_save", "Saving media changes/switches");
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
				op_dbgout("fw_save", "Calling patch function for '$key'...");
				$FW_PATCHES{$key}->[1](0, ui_getcheck($PatchesTab->{$key}));
			}
		}

		fw_rs_save();
	}

	##
	# Drive ID
	#
	if ( $Current{'fw_vid'} ne ui_gettext($DriveTab->{'Fields'}[0]) ||
	     $Current{'fw_pid'} ne ui_gettext($DriveTab->{'Fields'}[1]) ||
	     $Current{'fw_stdfwrev'} ne ui_gettext($DriveTab->{'Fields'}[2]) )
	{
		op_dbgout("fw_save", "Patching drive ID");

		my($work) = substr($Current{'fw'}, 0x4000);

		my(@pat) =
		(
			quotemeta(sprintf("%-8s%-16s%-4s", $Current{'fw_vid'}, $Current{'fw_pid'}, $Current{'fw_stdfwrev'})),
			quotemeta(flipsig(sprintf("%-8s%-8s%-16s", $Current{'fw_stdfwrev'}, $Current{'fw_vid'}, $Current{'fw_pid'}))),
			quotemeta(flipsig(sprintf("%-8s%-8s %-16s ", $Current{'fw_stdfwrev'}, $Current{'fw_vid'}, $Current{'fw_pid'}))),
		);

		my(@replace) =
		(
			sprintf("%-8s%-16s%-4s", ui_gettext($DriveTab->{'Fields'}[0]), ui_gettext($DriveTab->{'Fields'}[1]), ui_gettext($DriveTab->{'Fields'}[2])),
			flipsig(sprintf("%-8s%-8s%-16s", ui_gettext($DriveTab->{'Fields'}[2]), ui_gettext($DriveTab->{'Fields'}[0]), ui_gettext($DriveTab->{'Fields'}[1]))),
			flipsig(sprintf("%-8s%-8s %-16s ", ui_gettext($DriveTab->{'Fields'}[2]), ui_gettext($DriveTab->{'Fields'}[0]), ui_gettext($DriveTab->{'Fields'}[1]))),
		);

		if ($work =~ s/$pat[0]/$replace[0]/s && ($work =~ s/$pat[1]/$replace[1]/s || $work =~ s/$pat[2]/$replace[2]/s))
		{
			substr($Current{'fw'}, 0x4000, length($work), $work);
			op_dbgout("fw_save", "... Drive ID patched successfully");
		}
		else
		{
			op_dbgout("fw_save", "... Oops, unexpected drive ID patching error!");
		}
	}

	##
	# Check to make sure that the firmware hasn't been messed up
	#
	if (!fw_isokay())
	{
		ui_error("Unexpected error encountered during patching.\nFile not saved.");
		$Current{'fw'} = $original;
		return;
	}

	##
	# Rebanking
	#
	$Current{'fw'} = fw_rebank(\$Current{'fw'}, \$Current{'fw_bootcode'}, 0) if ($Current{'fw_rebanked'});

	##
	# If, after all that, the firmware size is still all right, then
	# we're good to go!
	#
	if (length($Current{'fw'}) == 0x100000)
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

	$Current{'fw'} = $original;
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
