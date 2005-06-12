##
# OmniPatcher for LiteOn DVD-Writers
# Media : Main module
#
# Modified: 2005/06/12, C64K
#

sub media_refresh_listitem # ( idx )
{
	my($idx) = @_;

	if ($idx >= 0)
	{
		my($code) = $Current{'media_table'}->[$idx];
		ui_changeitem_safe($MediaTab->{'List'}, $idx, ($code->[1] == $code->[3]) ? " $code->[5] : $MEDIA_TYPE_NAME[$code->[0]]" : "!$code->[5] : $MEDIA_TYPE_NAME[$code->[0]]");
	}
}

sub media_proc_listclick # ( idx )
{
	my($idx) = @_;
	my($i);

	if ($idx < 0)
	{
		# If no entry is selected, then gray out all of the speed/field
		# controls and reset them to a blank/default state.
		#
		foreach $i (0 .. $#{$MediaTab->{'Speeds'}})
		{
			ui_setdisable($MediaTab->{'Speeds'}[$i]);
			ui_setcheck($MediaTab->{'Speeds'}[$i], 0);
			ui_settext($MediaTab->{'Speeds'}[$i], "$MEDIA_SPEEDS_STD[$i]x");
			($MEDIA_SPEEDS_STD[$i] > $Current{'media_limits'}[$MEDIA_TYPE_DVD_PR]) ? ui_setinvisible($MediaTab->{'Speeds'}[$i]) : ui_setvisible($MediaTab->{'Speeds'}[$i])
		}

		foreach $i (0 .. $#{$MediaTab->{'Fields'}})
		{
			ui_setdisable($MediaTab->{'FieldLabels'}[$i]);
			ui_setdisable($MediaTab->{'Fields'}[$i]);
			ui_settext($MediaTab->{'Fields'}[$i], '');
		}
	}
	else
	{
		my($code) = $Current{'media_table'}->[$idx];

		# Flip off the speeds that should be flipped off, change the
		# text for 2.4x vs. 2x, and set the controls to the speed.
		#
		foreach $i (0 .. $#{$MediaTab->{'Speeds'}})
		{
			if ( $MEDIA_SPEEDS_STD[$i] > $Current{'media_limits'}[$code->[0]] ||
			     $MEDIA_SPEEDS->($code->[0])->[$i] == 0 )
			{
				ui_setdisable($MediaTab->{'Speeds'}[$i]);
				ui_setinvisible($MediaTab->{'Speeds'}[$i]);
			}
			elsif ($MEDIA_SPEEDS_STD[$i] == 16 && $Current{'media_spd_type'} == 6)
			{
				ui_setdisable($MediaTab->{'Speeds'}[$i]);
				ui_setvisible($MediaTab->{'Speeds'}[$i]);
			}
			else
			{
				ui_setenable($MediaTab->{'Speeds'}[$i]);
				ui_setvisible($MediaTab->{'Speeds'}[$i]);
			}

			ui_settext($MediaTab->{'Speeds'}[$i], $MEDIA_SPEEDS->($code->[0])->[$i] . "x");
			ui_setcheck($MediaTab->{'Speeds'}[$i], ($code->[4]{'SPD'} & (1 << $i)) ? 1 : 0);
		}

		# Do the same for the fields...
		#
		foreach $i (0 .. $#{$MediaTab->{'Fields'}})
		{
			$MediaTab->{'Fields'}[$i]->MaxLength((media_istype($code->[0], $MEDIA_TYPE_DVD_P)) ? 8 : 12) if ($i == $UI_MEDIA_TXTID_MID);

			if ($i == $UI_MEDIA_TXTID_TID && media_istype($code->[0], $MEDIA_TYPE_DVD_D))
			{
				ui_setdisable($MediaTab->{'FieldLabels'}[$i]);
				ui_setdisable($MediaTab->{'Fields'}[$i]);
				ui_settext($MediaTab->{'Fields'}[$i], '');
			}
			else
			{
				($i != $UI_MEDIA_TXTID_RID) ?
					ui_settext($MediaTab->{'Fields'}[$i], $code->[4]{$UI_FIELD_KEY[$i]}) :
					ui_settext($MediaTab->{'Fields'}[$i], sprintf("%02X", $code->[4]{$UI_FIELD_KEY[$i]}));

				ui_setenable($MediaTab->{'FieldLabels'}[$i]);
				ui_setenable($MediaTab->{'Fields'}[$i]);
			}
		}
	}
}

sub media_proc_spdchange # ( )
{
	my($idx) = ui_getselected($MediaTab->{'List'});

	if ($idx >= 0)
	{
		my($code) = $Current{'media_table'}->[$idx];
		my($strat_used, $i);

		if (!$FlagWarnedStratSpeed && $code->[1] != $code->[3])
		{
			foreach $i (0 .. $#{$Current{'media_table'}})
			{
				$strat_used = 1 if ($code->[0] == $Current{'media_table'}->[$i][0] && $code->[1] == $Current{'media_table'}->[$i][3]);
			}

			unless ($strat_used)
			{
				$FlagWarnedStratSpeed = 1;
				ui_infobox("Please note that media codes with a '!' in front of them are media\ncodes that are currently using another media code's write strategy\nand speed code.  Because they are no longer using their own speed\ncode, changing their burning speed will have no effect.  If you\nwould like to change the burning speed of this media code, you will\nhave to adjust the burning speed of its host media code.\n\nPlease refer to the documentation for more information.\n\nYou will not see this message again until the next time this program\nis run.", "Notice");
			}
		}

		if (!$FlagWarnedNonRSpeed && $code->[0] != $MEDIA_TYPE_DVD_PR && $code->[0] != $MEDIA_TYPE_DVD_DR)
		{
			$FlagWarnedNonRSpeed = 1;
			ui_warning("Adjusting ±RW or ±R9 speeds is not recommended!\n\nPlease refer to the documentation for more information.\n\nYou will not see this message again until the next time this program\nis run.");
		}

		$code->[4]{'SPD'} = 0;

		foreach $i (0 .. $#MEDIA_SPEEDS_STD)
		{
			$code->[4]{'SPD'} |= ((1 << $i) * ui_getcheck($MediaTab->{'Speeds'}[$i]));
		}
	}

	return 1;
}

sub media_proc_fieldchange # ( )
{
	my($idx) = ui_getselected($MediaTab->{'List'});

	if ($idx >= 0)
	{
		my($code) = $Current{'media_table'}->[$idx];
		my($changed);

		if ($code->[4]{'MID'} ne ui_gettext($MediaTab->{'Fields'}[$UI_MEDIA_TXTID_MID]))
		{
			$changed = 1;
			$code->[4]{'MID'} = ui_gettext($MediaTab->{'Fields'}[$UI_MEDIA_TXTID_MID]);
		}

		if ($code->[4]{'TID'} ne ui_gettext($MediaTab->{'Fields'}[$UI_MEDIA_TXTID_TID]) && media_istype($code->[0], $MEDIA_TYPE_DVD_P))
		{
			$changed = 1;
			$code->[4]{'TID'} = ui_gettext($MediaTab->{'Fields'}[$UI_MEDIA_TXTID_TID]);
		}

		if ($code->[4]{'RID'} != hex(ui_gettext($MediaTab->{'Fields'}[$UI_MEDIA_TXTID_RID])))
		{
			$changed = 1;
			$code->[4]{'RID'} = hex(ui_gettext($MediaTab->{'Fields'}[$UI_MEDIA_TXTID_RID]));
		}

		if ($changed)
		{
			$code->[5] = (media_istype($code->[0], $MEDIA_TYPE_DVD_P)) ?
				media_cleandisp(sprintf("%-8s-%-3s-%02X", $code->[4]{'MID'}, $code->[4]{'TID'}, $code->[4]{'RID'})) :
				media_cleandisp(sprintf("%-12s-%02X", $code->[4]{'MID'}, $code->[4]{'RID'}));

			media_refresh_listitem($idx);
		}
	}
}

sub media_proc_tweaks # ( idx )
{
	my($idx) = @_;
	my($entry, $src, $dst, $st_count, $sp_count);

	foreach $entry (@MEDIA_TWEAKS)
	{
		next unless ($entry->[3]($Current{'fw_gen'}));

		$src = media_name2rawidx($entry->[0]);
		$dst = media_name2rawidx($entry->[1]);

		if ($src >= 0)
		{
			if ( $dst >= 0 && $Current{'media_strat_status'} >= 0 &&
			     $Current{'media_strat'}->[$Current{'media_table'}->[$src][0]]{'status'} >= 0 &&
			     $Current{'media_table'}->[$src][3] != $Current{'media_table'}->[$dst][1] )
			{
				++$st_count;
				$Current{'media_table'}->[$src][3] = $Current{'media_table'}->[$dst][1];
				media_refresh_listitem($src);
			}

			if ( $#{$entry->[2]} == 0 && $entry->[2][0] > 0 &&
			     $Current{'media_table'}->[$src][4]{'SPD'} != $entry->[2][0] )
			{
				++$sp_count;
				$Current{'media_table'}->[$src][4]{'SPD'} = $entry->[2][0];
			}

		} # End: if the source code is valid for this firmware

	} # End: for each entry in the tweaks table

	media_proc_listclick($idx);
	ui_infobox(sprintf("%d write strategy replacement(s) applied.\n%d writing speed adjustment(s) applied.\n\n%s", $st_count, $sp_count, $MEDIA_TWEAKS_REV ), "Status");
}

sub media_save_report # ( filename )
{
	my($filename) = @_;

	my($report);
	my(@typelists, $code, $temp, $i);
	my($field_idx, $field_strat, $field_speeds);

	my($make_header) = sub { "-" x 80 . "\n$_[0]\n" . "-" x 80 . "\n" };
	my($make_infopair) = sub { sprintf("%-22s : %s\n", @_) };

	foreach $code (@{$Current{'media_table'}})
	{
		$field_idx = ($MEDIA_REPORT_MODE > 0) ? sprintf("0x%02X: ", $code->[1]) : '';

		$field_strat = ($code->[1] != $code->[3]) ? " -> $Current{'media_table'}->[media_rawidx2idx($code->[0], $code->[3])][5]" : '';

		$field_speeds = "";

		foreach $i (0 .. $#MEDIA_SPEEDS_STD)
		{
			unless ( $MEDIA_SPEEDS_STD[$i] > $Current{'media_limits'}[$code->[0]] ||
			         $MEDIA_SPEEDS->($code->[0])->[$i] == 0 )
			{
				my($temp) = $MEDIA_SPEEDS->($code->[0])->[$i] . "x, ";
				$field_speeds .= (($code->[4]{'SPD'} & (1 << $i)) ? $temp : ' ' x length($temp));
			}
		}

		$field_speeds =~ s/, (\s*)$/$1/;

		push(@{$typelists[$code->[0]]}, "$field_idx$code->[5]  [ $field_speeds ]$field_strat\n");
	}

	$report  = "OmniPatcher DVD Media Code Report\n";
	$report .= "=================================\n\n";

	$report .= "OmniPatcher version: $PROGRAM_VERSION\n";
	$report .= "Firmware file name: $Current{'shortname'}\n\n\n";

	$report .= $make_header->("General Information");
	$report .= $make_infopair->("Drive type", $Current{'fw_family'});
	$report .= $make_infopair->("Vendor ID string", ui_gettext($DriveTab->{'Fields'}[0]));
	$report .= $make_infopair->("Product ID string", ui_gettext($DriveTab->{'Fields'}[1]));
	$report .= $make_infopair->("Standard firmware rev.", ui_gettext($DriveTab->{'Fields'}[2]));
	$report .= $make_infopair->("Internal firmware rev.", $Current{'fw_intfwrev'});
	$report .= $make_infopair->("Firmware timestamp", ltrim($Current{'fw_timestamp'})) . "\n";

	$report .= $make_header->("DVD Media Support Summary");
	$report .= $make_infopair->("Total media codes", $Current{'media_count'});
	map { $report .= $make_infopair->("$MEDIA_TYPE_NAME[$_] media codes", sprintf("%3d", $Current{'media_type_count'}->[$_])) } grep { $Current{'media_type_count'}->[$_] > 0 } (@{$MEDIA_TYPES[$MEDIA_TYPE_DVD_P]}, @{$MEDIA_TYPES[$MEDIA_TYPE_DVD_D]});
	$report .= "\n";

	foreach $i (0 .. $#typelists)
	{
		if (scalar(@{$typelists[$i]}))
		{
			@{$typelists[$i]} = sort(@{$typelists[$i]}) if ($MEDIA_REPORT_MODE > 1);

			$report .= $make_header->("$MEDIA_TYPE_NAME[$i] Media Codes ($Current{'media_type_count'}->[$i])");
			$report .= join('', @{$typelists[$i]}) . "\n";
		}
	}

	if (open file, ">$filename")
	{
		print file $report;
		close file;

		ui_infobox("The media code report has been created.", "Done!");
	}
	else
	{
		ui_error("File access error!");
	}
}

sub media_cleandisp # ( str )
{
	my($str) = @_;
	$str =~ s/[\x00-\x1F]/ /sg;
	return $str;
}

sub media_name2rawidx # ( name )
{
	my($name) = @_;
	my($code, $i);

	if ($#{$name} == 1 || $#{$name} == 2)
	{
		foreach $code (@{$Current{'media_table'}})
		{
			if ( ($#{$name} == 2 && $name->[0] eq $code->[2]{'MID'}[0] && $name->[1] eq $code->[2]{'TID'}[0] && $name->[2] == $code->[2]{'RID'}[0]) ||
			     ($#{$name} == 1 && $name->[0] eq $code->[2]{'MID'}[0] && $name->[1] == $code->[2]{'RID'}[0]) )
			{
				return $i;
			}

			++$i;
		}
	}

	return -1;
}

sub media_rawidx2idx # ( type, rawidx )
{
	my($type, $rawidx) = @_;
	my($i);

	foreach $i (0 .. $#{$Current{'media_table'}})
	{
		return $i if ($Current{'media_table'}->[$i][0] == $type && $Current{'media_table'}->[$i][1] == $rawidx);
	}

	return -1;
}

1;
