##
# OmniPatcher for LiteOn DVD-Writers
# Media : Main module
#
# Modified: 2005/06/25, C64K
#

sub media_refresh_listitem # ( idx )
{
	my($idx) = @_;

	if ($idx >= 0)
	{
		my($code) = $Current{'media_table'}->[$idx];

		$code->[5] = (media_istype($code->[0], $MEDIA_TYPE_DVD_P)) ?
			media_cleandisp(sprintf("%-8s-%-3s-%02X", $code->[4]{'MID'}, $code->[4]{'TID'}, $code->[4]{'RID'})) :
			media_cleandisp(sprintf("%-12s-%02X", $code->[4]{'MID'}, $code->[4]{'RID'}));

		ui_changeitem_safe($MediaTab->{'List'}, $idx, ($code->[1] == $code->[3]) ? " $code->[5] : $MEDIA_TYPE_NAME[$code->[0]]" : "!$code->[5] : $MEDIA_TYPE_NAME[$code->[0]]");
	}
}

sub media_proc_listclick # ( idx )
{
	my($idx) = @_;
	my($i);

	$FlagIgnoreMediaChange = 1;

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
			elsif ($MEDIA_SPEEDS_STD[$i] == 16 && $Current{'media_spd_type'} == 5 && $code->[2]{'SPD'}[1][1] == 0)
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

	$FlagIgnoreMediaChange = 0;
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

		media_refresh_listitem($idx) if ($changed);
	}
}

sub media_proc_tweaks # ( idx )
{
	my($idx) = @_;
	my($entry, $src, $dst, $st_count, $sp_count);

	foreach $entry (@MEDIA_TWEAKS)
	{
		next unless ($entry->[3]($Current{'fw_gen'}));

		$src = media_name2idx($entry->[0]);
		$dst = media_name2idx($entry->[1]);

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
	ui_infobox(sprintf("%d write strategy reassignment(s) applied.\n%d write speed adjustment(s) applied.\n\n%s", $st_count, $sp_count, $MEDIA_TWEAKS_REV), "Status");
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

sub media_load_report # ( filename )
{
	my($filename) = @_;

	my(%name2type) =
	(
		'+R'  => $MEDIA_TYPE_DVD_PR,
		'+RW' => $MEDIA_TYPE_DVD_PRW,
		'+R9' => $MEDIA_TYPE_DVD_PR9,
		'-R'  => $MEDIA_TYPE_DVD_DR,
		'-RW' => $MEDIA_TYPE_DVD_DRW,
		'-R9' => $MEDIA_TYPE_DVD_DR9,
	);

	open file, $filename;
	my(@lines) = <file>;
	close file;

	my($st_count, $sp_count);
	my($idx) = ui_getselected($MediaTab->{'List'});
	my($type) = -1;

	foreach my $line (@lines)
	{
		if ($line =~ /^([+-]R[W9]?) Media Codes/s && exists($name2type{$1}))
		{
			$type = $name2type{$1};
			next;
		}

		if ($type >= 0 && $line =~ /^(?:0x[0-9A-F]{2}: )?(?#1-code)(.{12}[\/-][0-9A-F]{2})  \[(?#2-speed)( .* )\](?: -> (?#3-strat)(.{12}[\/-][0-9A-F]{2}))?/s)
		{
			my($src) = media_disp2idx($type, $1);
			my($dst) = media_disp2idx($type, $3);
			my($spdtxt) = $2;

			next if ($src < 0);

			my($spdmask) = (2 << $MEDIA_STDSPD2IDX[$Current{'media_limits'}->[$type]]) - 1;
			my($newspd) = 0;

			$newspd |= (1 << 0) if ($spdtxt =~ / 1x/s);
			$newspd |= (1 << 1) if ($spdtxt =~ / 2(?:.4)?x/s);
			$newspd |= (1 << 2) if ($spdtxt =~ / 4x/s);
			$newspd |= (1 << 3) if ($spdtxt =~ / 6x/s);
			$newspd |= (1 << 4) if ($spdtxt =~ / 8x/s);
			$newspd |= (1 << 5) if ($spdtxt =~ / 12x/s);
			$newspd |= (1 << 6) if ($spdtxt =~ / 16x/s);
			$newspd &= $spdmask;

			my($code) = $Current{'media_table'}->[$src];

			if ($newspd != ($code->[4]{'SPD'} & $spdmask))
			{
				++$sp_count;
				$code->[4]{'SPD'} = ($code->[4]{'SPD'} & ($spdmask ^ 0xFF)) | $newspd;
			}

			if ( $dst >= 0 && $Current{'media_strat_status'} >= 0 &&
			     $Current{'media_strat'}->[$type]{'status'} >= 0 &&
			     $code->[3] != $Current{'media_table'}->[$dst][1] )
			{
				++$st_count;
				$code->[3] = $Current{'media_table'}->[$dst][1];
				media_refresh_listitem($src);
			}
		}
	}

	media_proc_listclick($idx);
	ui_infobox(sprintf("%d write strategy reassignment(s) applied.\n%d write speed adjustment(s) applied.", $st_count, $sp_count), "Status");
}

sub media_undo_nschanges # ( idx )
{
	my($idx) = @_;

	if ($idx >= 0)
	{
		my($code) = $Current{'media_table'}->[$idx];

		$code->[4]{'MID'} = $code->[2]{'MID'}[0];
		$code->[4]{'TID'} = $code->[2]{'TID'}[0] if (exists($code->[2]{'TID'}));
		$code->[4]{'RID'} = $code->[2]{'RID'}[0];
		$code->[4]{'SPD'} = $code->[2]{'SPD'}[0];

		media_refresh_listitem($idx);
		media_proc_listclick($idx);
	}
}

sub media_import_code # ( idx, text )
{
	my($idx, $text) = @_;
	return 1 if ($idx < 0);

	# Convert the hex dump into a raw string
	#
	my(@lines) = split(/\r?\n/, $text);
	my($str, $isdip);

	foreach my $line (@lines)
	{
		if ($line =~ /^(?:(0{6}\d0)?\s+|.*?\s+|\s*)((?:[0-9A-Fa-f]{2}\s{1,4}){16})\s*/s)
		{
			$isdip = ($isdip || length($1) > 0);
			my(@bytes) = split(/\s+/, $2);
			$str .= join('', map { chr(hex($_)) } @bytes);
		}
	}

	return ui_error_mib("The media code block appears to be either too short\nor incorrectly formatted!", 0) if (length($str) < 0x30);

	# Now let's see if we can make heads or tails of it
	#
	my($code) = $Current{'media_table'}->[$idx];
	my(@offset_try_order) = ($isdip) ? (4, 0) : (0, 4);
	my($pmid, $ptid, $prid, $pokay);
	my($dmid, $drid, $dokay);

	# A private helper sub that shares this function's scope will check
	# out which offsets (i.e., discard first 4 bytes?) is right for this input.
	#
	my($try_offset) = sub # ( offset )
	{
		my($offset) = @_;

		$pmid = nulltrim(substr($str, 0x13 + $offset, 8));
		$ptid = nulltrim(substr($str, 0x1B + $offset, 3));
		$prid = ord(substr($str, 0x1E + $offset, 1));
		$pokay = 0;

		if ( (length($pmid) == 0 || $pmid =~ /^[0-9A-Z]/) &&
		     (length($ptid) == 0 || $ptid =~ /^[0-9A-Za-z]/) &&
		     $pmid =~ /^[\x20-\x7F]*$/ && $ptid =~ /^[\x20-\x7F]*$/ && $prid < 0x10 )
		{
			$pokay = 1;
		}

		$dmid = nulltrim(substr($str, 0x11 + $offset, 6) . substr($str, 0x19 + $offset, 6));
		$drid = ord(substr($str, 0x06 + $offset, 1));
		$dokay = 0;

		if ($dmid =~ /^[0-9A-Z][\x00\x20-\x7F]*$/)
		{
			$dokay = 1;
		}
	};

	foreach (@offset_try_order)
	{
		$try_offset->($_);
		last if ($pokay || $dokay);
	}

	# Now deal with this result in the context of the selected code.
	#
	if (media_istype($code->[0], $MEDIA_TYPE_DVD_P))
	{
		if ($pokay)
		{
			return ui_error_mib("This media code is already in this firmware!", 0) if (media_newname2idx([ $pmid, $ptid, $prid ], $code->[0]) >= 0);

			$code->[4]{'MID'} = $pmid;
			$code->[4]{'TID'} = $ptid;
			$code->[4]{'RID'} = $prid;
		}
		elsif ($dokay)
		{
			return ui_error_mib("You cannot load a dash code into the plus table!", 0);
		}
		else
		{
			return ui_error_mib("This media code block (or the media code itself)\ndoes not appear to be valid!", 0);
		}
	}
	else
	{
		if ($dokay)
		{
			return ui_error_mib("This media code is already in this firmware!", 0) if (media_newname2idx([ $dmid, $drid ], $code->[0]) >= 0);

			$code->[4]{'MID'} = $dmid;
			$code->[4]{'RID'} = $drid;
		}
		elsif ($pokay)
		{
			return ui_error_mib("You cannot load a plus code into the dash table!", 0);
		}
		else
		{
			return ui_error_mib("This media code block (or the media code itself)\ndoes not appear to be valid!", 0);
		}
	}

	media_refresh_listitem($idx);
	media_proc_listclick($idx);

	return 1;
}

sub media_cleandisp # ( str )
{
	my($str) = @_;
	op_dbgout("media_cleandisp", "Bytes in the 00-1F range found in [$str]") if ($str =~ s/[\x00-\x1F]/ /sg);
	return $str;
}

sub media_name2idx # ( name[, type ] )
{
	my($name, $type) = @_;
	my($code, $i);

	if ($#{$name} == 1 || $#{$name} == 2)
	{
		foreach $code (@{$Current{'media_table'}})
		{
			if (!defined($type) || $type == $code->[0])
			{
				if ( ($#{$name} == 2 && $name->[0] eq $code->[2]{'MID'}[0] && $name->[1] eq $code->[2]{'TID'}[0] && $name->[2] == $code->[2]{'RID'}[0]) ||
				     ($#{$name} == 1 && $name->[0] eq $code->[2]{'MID'}[0] && $name->[1] == $code->[2]{'RID'}[0]) )
				{
					return $i;
				}
			}

			++$i;
		}
	}

	return -1;
}

sub media_newname2idx # ( name[, type ] )
{
	##
	# Just like media_name2idx, except that instead of checking for a match
	# against the original name, it checks against the new name, which may
	# differ from the original if the user has made changes
	#
	my($name, $type) = @_;
	my($code, $i);

	if ($#{$name} == 1 || $#{$name} == 2)
	{
		foreach $code (@{$Current{'media_table'}})
		{
			if (!defined($type) || $type == $code->[0])
			{
				if ( ($#{$name} == 2 && $name->[0] eq $code->[4]{'MID'} && $name->[1] eq $code->[4]{'TID'} && $name->[2] == $code->[4]{'RID'}) ||
				     ($#{$name} == 1 && $name->[0] eq $code->[4]{'MID'} && $name->[1] == $code->[4]{'RID'}) )
				{
					return $i;
				}
			}

			++$i;
		}
	}

	return -1;
}

sub media_disp2idx # ( type, display_name )
{
	##
	# Since the display name always reflects the current/new names and
	# not the original names, this, by its nature, is more akin to newname2idx
	# than to name2idx
	#
	my($type, $display_name) = @_;
	my($found) = -1;
	my($i);

	if (length($display_name) == 15)
	{
		substr($display_name, 8, 1, '-') if (substr($display_name, 8, 1) eq '/');
		substr($display_name, 12, 1, '-');

		foreach my $code (@{$Current{'media_table'}})
		{
			if ($type == $code->[0] && $display_name eq $code->[5])
			{
				($found < 0) ? $found = $i : return -1;
			}

			++$i;
		}
	}

	return $found;
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
