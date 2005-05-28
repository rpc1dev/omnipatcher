$OP_REPORT_MODE = 0;

##
# Debugging stuff
#

$OP_PRINT_DEBUG = 1;
#dbgout(sprintf("DEBUG REPORT: %d, %d\n", ?, ?));

sub str2hex # ( str )
{
	return join(' ', map { sprintf('%02X', ord($_)) } split (//, $_[0]));
}

sub dbgout # ( debugging_output )
{
	print @_ if ($OP_PRINT_DEBUG);
}

##
# General functions
#

#..............................................................................
sub load_file # ( )
{
	my($i, $label);

	$file_data{'core'} = substr($file_data{'work'}, 0x4000);

	# Find the CDB version number
	my($fwr_len) = 16;
	my($fwr_pat) = '\x7D(.)\x90.{19,23}' x $fwr_len;

	$file_data{'fwrev'} = '';

	if ($file_data{'core'} =~ /$fwr_pat/s)
	{
		for ($i = 1; $i <= $fwr_len; ++$i)
		{
			$file_data{'fwrev'} .= substr($file_data{'core'}, $-[$i], $+[$i] - $-[$i]);
		}

		$file_data{'fwrev'} =~ s/\s+$//;
		dbgout("Firmware: $file_data{'fwrev'} (method 1)\n");
	}

	$file_data{'driveid'} = 'Unknown';
	$file_data{'drivevid'} = 'Unknown';
	$file_data{'drivepid'} = 'Unknown';
	$file_data{'timestamp'} = 'Unknown';

	# Find the version strings
	if ($file_data{'core'} =~ /\x07\x01\x03\x00\x78\x00\x78\x00\xE3\x00\x78\x00.{50}(.{8})(.{16})(.{4})(.{16})/s)
	{
		dbgout("Drive ID: $1,$2,$3,$4\n");
		$file_data{'drivevid'} = $1;
		$file_data{'drivepid'} = $2;
		$file_data{'timestamp'} = $4;

		if ($file_data{'fwrev'} eq '')
		{
			$file_data{'fwrev'} = $3;
			dbgout("Firmware: $file_data{'fwrev'} (method 2)\n");
		}

		$file_data{'drivevid'} =~ s/\s+$//;
		$file_data{'drivepid'} =~ s/\s+$//;
		$file_data{'timestamp'} =~ s/\s+$//;

		$file_data{'timestamp'} =~ s/^\s+//;
		$file_data{'timestamp'} = 'Unknown' if ($file_data{'timestamp'} eq '');

		$file_data{'driveid'} = "$file_data{'drivevid'} $file_data{'drivepid'}";
	}

	$file_data{'fwrev'} = ' ' if ($file_data{'fwrev'} eq '');

	if (mtk_rebank_check(\$file_data{'work'}))
	{
		$file_data{'rebank'} = 1;
		$file_data{'work'} = mtk_rebank(\$file_data{'work'}, 1, 1);
		dbgout("Rebanking required.\n");
	}
	else
	{
		$file_data{'rebank'} = 0;
		dbgout("No rebanking required.\n");
	}

	my(%fwparams) =
	(
		# fw_letter => [ gen, genex, fwfamily, ebankpos, pbankpos, dbankpos, [ pr, prw, pr9, dr, drw, dr9 ] ]

		'E' => [ 1, 0x011, 'LDW-401S',       0x00000, 0xC0000, 0xD0000, [  4, 4, 0,  0, 0, 0 ] ],
		'F' => [ 1, 0x011, 'LDW-411S',       0x90000, 0xC0000, 0xD0000, [  4, 4, 0,  4, 4, 0 ] ],
		'H' => [ 1, 0x011, 'LDW-811S',       0x90000, 0xC0000, 0xD0000, [  8, 4, 0,  4, 4, 0 ] ],
		'G' => [ 2, 0x012, 'LDW-451S/851S',  0x90000, 0xC0000, 0xD0000, [  8, 4, 0,  4, 4, 0 ] ],
		'U' => [ 2, 0x021, 'SOHW-802S/812S', 0x90000, 0xC0000, 0xD0000, [  8, 4, 0,  8, 4, 0 ] ],
		'V' => [ 2, 0x021, 'SOHW-822S/832S', 0x90000, 0xC0000, 0xD0000, [  8, 4, 2,  8, 4, 0 ] ],
		'T' => [ 3, 0x031, 'SOHW-1213S',     0x90000, 0xE0000, 0x90000, [ 12, 4, 4,  8, 4, 0 ] ],
		'I' => [ 3, 0x032, 'SOHW-833S',      0x90000, 0xE0000, 0x90000, [  8, 4, 4,  8, 4, 0 ] ],
		'A' => [ 3, 0x032, 'SOHW-1613S',     0x90000, 0xE0000, 0x90000, [ 16, 4, 4,  8, 4, 0 ] ],
		'B' => [ 3, 0x032, 'SOHW-1633S',     0x90000, 0xE0000, 0x90000, [ 16, 4, 4, 12, 4, 0 ] ],
		'C' => [ 3, 0x033, 'SOHW-1653S',     0x90000, 0xE0000, 0x90000, [ 16, 4, 4, 12, 4, 0 ] ],
		'J' => [ 4, 0x034, 'SOHW-1673S',     0xA0000, 0xA0000,0x100000, [ 16, 8, 4, 16, 6, 0 ] ],
		'K' => [ 4, 0x035, 'SOHW-1693S',     0xA0000, 0xB0000,0x100000, [ 16, 8, 4, 16, 6, 4 ] ],

		'L' => [ 0, 0x111, 'SDW-421S',       0x00000, 0xA0000, 0xD0000, [  4, 4, 0,  0, 0, 0 ] ],
		'M' => [ 0, 0x111, 'SDW-431S',       0xC0000, 0xA0000, 0xD0000, [  4, 4, 0,  4, 2, 0 ] ],
		'R' => [ 0, 0x121, 'SOSW-832S',      0xC0000, 0xA0000, 0xD0000, [  8, 4, 0,  8, 4, 0 ] ],
		'N' => [ 0, 0x121, 'SOSW-842S',      0xC0000, 0xA0000, 0xD0000, [  8, 4, 0,  0, 0, 0 ] ],
		'P' => [ 0, 0x121, 'SOSW-852S',      0xC0000, 0xA0000, 0xD0000, [  8, 4, 2,  8, 4, 0 ] ],
		'6' => [ 0, 0x121, 'SOSW-852S',      0xC0000, 0xA0000, 0xD0000, [  8, 4, 2,  8, 4, 0 ] ],
		'Q' => [ 0, 0x121, 'SOSW-862S',      0xC0000, 0xA0000, 0xD0000, [  8, 4, 2,  0, 0, 0 ] ],
	);

	my($fwparam);

	# Find first letter of version in table
	if (exists $fwparams{substr($file_data{'fwrev'}, 0, 1)})
	{
		$fwparam = $fwparams{substr($file_data{'fwrev'}, 0, 1)};
	}
	else
	{
		$fwparam = [ 0, 0x000, 'Unknown', 0x00000, 0x00000, 0x00000, [ 0, 0, 0, 0, 0, 0 ] ];
		error('Unable to classify firmware.');
	}

	##
	# Initialize %file_data parameters
	{
		$file_data{'gen'}      = $fwparam->[0];
		$file_data{'genex'}    = $fwparam->[1];
		$file_data{'fwfamily'} = $fwparam->[2];
		$file_data{'ebankpos'} = $fwparam->[3];
		$file_data{'pbankpos'} = $fwparam->[4];
		$file_data{'dbankpos'} = $fwparam->[5];

		$file_data{'pr_limit'}  = $fwparam->[-1][0];
		$file_data{'prw_limit'} = $fwparam->[-1][1];
		$file_data{'pr9_limit'} = $fwparam->[-1][2];
		$file_data{'dr_limit'}  = $fwparam->[-1][3];
		$file_data{'drw_limit'} = $fwparam->[-1][4];
		$file_data{'dr9_limit'} = $fwparam->[-1][5];

		$file_data{'fwrev'} = 'Unknown' if ($file_data{'fwrev'} eq ' ');

	} # End: Initialize %file_data parameters

	if ($file_data{'genex'} >= 0x030 && $file_data{'genex'} < 0x034)
	{
		$file_data{'pbankpos'} = 0xC0000 if (substr($file_data{'work'}, 0xC0000, 0x10000) =~ /$PLUS_SAMPLE/);
	}
	elsif ($file_data{'genex'} >= 0x034 && $file_data{'genex'} < 0x100)
	{
		# +R table moved in JS07
		$file_data{'pbankpos'} = 0xB0000 if ($file_data{'genex'} == 0x034 && (substr($file_data{'work'}, 0xB4000, 0xC000) =~ /$PLUSR1A_SAMPLE/)); 
#		Win32::GUI::MessageBox($hWndMain, "Support for this drive type in this version of OmniPatcher is experimental.", "Notice", MB_OK | MB_ICONINFORMATION);
	}

	# sets mcpdata (tables) -> module = speedhack
	getmctype();

	$file_data{'codes'} = [ getcodes() ];
	$file_data{'ncodes'} = scalar(@{$file_data{'codes'}});

	dbgout("MC Type: $file_data{'mctype'}\n");
	if ($file_data{'mctype'} == 4)
	{
#		Win32::GUI::MessageBox($hWndMain, "This version of OmniPatcher is experimental for 3S firmware strategy switching.", "Notice", MB_OK | MB_ICONINFORMATION);
	}

	if ($file_data{'mctype'} >= 2 && $file_data{'fwfamily'} =~ /^SOHW-1[26]([1357])3S$/)
	{
		my($codetbl_actual) = scalar(@{$file_data{'mcpdata'}}) + scalar(@{$file_data{'mcddata'}});
		my($codetbl_expected) = ($1 eq '1') ? 8 : 9;
		$codetbl_expected += 1 if ($file_data{'mctype'} == 4 && ($file_data{'genex'} >= 0x033 && $file_data{'genex'} < 0x100));
		$codetbl_expected += 2 if ($file_data{'genex'} >= 0x034 && $file_data{'genex'} < 0x100);

		if ($codetbl_actual < $codetbl_expected)
		{
			error(sprintf("OmniPatcher expected to find %d media tables in this firmware,\nhowever, only %d tables were recognized.\n\nThere will likely be some media codes in this firmware that\nare present but are not being reported by OmniPatcher.", $codetbl_expected, $codetbl_actual));
		}

		dbgout(sprintf("%d/%d tables found\n", $codetbl_actual, $codetbl_expected));
	}
	elsif ($file_data{'ncodes'} < 50 && ($file_data{'genex'} > 0x000))
	{
		$file_data{'codes'} = [ ];
		$file_data{'ncodes'} = 0;
		error("Unable to read the media code table!\n\nYou may need to upgrade to a newer\nversion of OmniPatcher.");
	}

	$file_data{'speed_type'} = 0;

	for ($i = 0; $i < $file_data{'ncodes'}; ++$i)
	{
		if ($file_data{'codes'}->[$i][1][-1] > 0xFF)
		{
			$file_data{'speed_type'} = 2;
			last;
		}
		elsif ($file_data{'codes'}->[$i][1][-1] > 0x7F)
		{
			$file_data{'speed_type'} = 1;
		}
	}

	dbgout(sprintf("%d bits used for speed encoding.\n", 7 + $file_data{'speed_type'}));
	dbgout("Warning! Possible 9th speed bit conflict!\n") if ($file_data{'speed_type'} == 2 && $file_data{'mctype'} == 4);

	if ($file_data{'speed_type'} == 2)
	{
		@MEDIA_SPEEDS = @MEDIA_SPEEDS_2;
		SetTop($ObjSpeeds[6], $ObjSpeeds[5]->Top());
	}
	elsif ($file_data{'speed_type'} == 1)
	{
		@MEDIA_SPEEDS = @MEDIA_SPEEDS_1;
	}
	else
	{
		@MEDIA_SPEEDS = @MEDIA_SPEEDS_0;
		SetTop($ObjSpeeds[6], $ObjSpeeds[7]->Top());
	}

	$file_data{'speeds'} = [ map { $_->[1][-1] } @{$file_data{'codes'}} ];
	$file_data{'strats'} = [ map { $_->[3] } @{$file_data{'codes'}} ];

	$file_data{'strat_status'} = patch_strat(1, -1);
	($file_data{'strat_status'} < 0) ? SetDisable($ObjDefStrat) : SetEnable($ObjDefStrat);
	($file_data{'strat_status'} < 0) ? SetDisable($ObjMediaLabel) : SetEnable($ObjMediaLabel);
	load_strats() if ($file_data{'strat_status'} == 1);

	$ObjList->Clear();
	List_Click();

	for ($i = 0; $i < $file_data{'ncodes'}; ++$i)
	{
		$label = "$file_data{'codes'}->[$i][2] $file_data{'codes'}->[$i][0]";

		if ($file_data{'codes'}->[$i][3] == $file_data{'strats'}->[$i])
		{
			$ObjList->AddString(" $label");
		}
		else
		{
			$ObjList->AddString("!$label");
		}
	}

	SetEnable($ObjList);
	$ObjMediaGroup->Text("$MGROUP_NAME ($file_data{'ncodes'} codes)");

	$file_data{'patch_status'} = [ -1, -1, -1, -1, -1, -1, -1 ];

	if ($file_data{'gen'} > 0 && $file_data{'gen'} < 3)
	{
		$file_data{'patch_status'}->[$PIDX_RS12] = patch_rs(1);
#		$file_data{'patch_status'}->[$PIDX_RS16] = -1;
		$file_data{'patch_status'}->[$PIDX_AB] = patch_abs(1, -1);
		$file_data{'patch_status'}->[$PIDX_ES] = patch_fb(1, -1);
		$file_data{'patch_status'}->[$PIDX_FS] = patch_sf(1, -1);
		$file_data{'patch_status'}->[$PIDX_FF] = patch_ff(1, -1);
		$file_data{'patch_status'}->[$PIDX_CF] = patch_eeprom(1, -1);

		SetText($ObjPatches[$PIDX_RS12], $PATCH_0_BASE . " to 8x")
	}
	elsif ($file_data{'gen'} == 3 || $file_data{'gen'} == 4)
	{
		dbgout(sprintf("DEBUG REPORT: %d, %d\n", $PIDX_RS12, $PIDX_RS16));
		SetCheck($ObjPatches[$PIDX_RS16], 0);
		if (($file_data{'patch_status'}->[$PIDX_RS12] = patch_rs(1)) < 0) 
		{
			SetCheck($ObjPatches[$PIDX_RS16], 1);
			$file_data{'patch_status'}->[$PIDX_RS16] = patch_rs(1);
		} else {
			$file_data{'patch_status'}->[$PIDX_RS16] = 0;
		}
		$file_data{'patch_status'}->[$PIDX_AB] = patch_abs(1, -1);
		$file_data{'patch_status'}->[$PIDX_CF] = patch_eeprom(1, -1);

		SetText($ObjPatches[$PIDX_RS12], $PATCH_0_BASE . " to 12x")
	}
	else
	{
		$file_data{'patch_status'}->[$PIDX_CF] = patch_eeprom(1, -1);

		SetText($ObjPatches[$PIDX_RS12], $PATCH_0_BASE)
	}

	foreach $i (0 .. $#ObjPatches)
	{
		if ($file_data{'patch_status'}->[$i] < 0)
		{
			SetCheck($ObjPatches[$i], 0);
			SetDisable($ObjPatches[$i]);
		}
		else
		{
			SetCheck($ObjPatches[$i], $file_data{'patch_status'}->[$i]);
			SetEnable($ObjPatches[$i]);
		}
	}

	if ($ObjPatches[$PIDX_RS12]->GetCheck() || $ObjPatches[$PIDX_RS16]->GetCheck())
	{
		SetDisable($ObjPatches[$PIDX_RS12]);
		SetDisable($ObjPatches[$PIDX_RS16]);
	}

	if ($file_data{'patch_status'}->[$PIDX_CF] == -2)
	{
		$file_data{'patch_status'}->[$PIDX_FF] = -1;
		SetCheck($ObjPatches[$PIDX_CF], 1);
	}

	SetEnable($ObjSpdRep);
	SetEnable($ObjCmds[1]);
	SetEnable($ObjCmds[2]);

	$ObjCmdGroup->Text(($file_data{'fwrev'} eq 'Unknown') ? $file_data{'shortname'} : "$file_data{'fwrev'} ($file_data{'shortname'})");
}

#..............................................................................
sub save_file # ( file_name )
{
	my($file_name) = @_;
	my($i, @dopatch);

	$file_data{'plus_patches'} = [ ];
	$file_data{'dashr_patches'} = [ ];
	$file_data{'dashrw_patches'} = [ ];

	foreach $i (0 .. $file_data{'ncodes'} - 1)
	{
		if ($file_data{'speeds'}->[$i] > 0 && $file_data{'speeds'}->[$i] != $file_data{'codes'}->[$i][1][-1])
		{
			if ($file_data{'codes'}->[$i][0] eq "-R")
			{
				push(@{$file_data{'dashr_patches'}}, [ $file_data{'codes'}->[$i][3], $file_data{'speeds'}->[$i] ]);
			}
			elsif ($file_data{'codes'}->[$i][0] eq "-RW")
			{
				push(@{$file_data{'dashrw_patches'}}, [ $file_data{'codes'}->[$i][3], $file_data{'speeds'}->[$i] ]);
			}
			elsif ($file_data{'codes'}->[$i][0] eq "-R/W")
			{
			}
			else
			{
				push(@{$file_data{'plus_patches'}}, [ @{$file_data{'codes'}->[$i][1]}, $file_data{'speeds'}->[$i] ]);
			}
		}
	}

	foreach $i (0 .. $#ObjPatches)
	{
		if ($ObjPatches[$i]->IsEnabled() && $ObjPatches[$i]->GetCheck() != $file_data{'patch_status'}->[$i])
		{
			$dopatch[$i] = 1;
		}
		else
		{
			$dopatch[$i] = 0;
		}
	}

	my($temp) = $file_data{'work'};

	setcodes();
	save_strats();

	patch_rs(0)												if ($dopatch[$PIDX_RS12] || $dopatch[$PIDX_RS16]);
	patch_abs(0, $ObjPatches[$PIDX_AB]->GetCheck())		if ($dopatch[$PIDX_AB]);
	patch_fb(0, $ObjPatches[$PIDX_ES]->GetCheck())		if ($dopatch[$PIDX_ES]);
	patch_sf(0, $ObjPatches[$PIDX_FS]->GetCheck())		if ($dopatch[$PIDX_FS] || $ObjPatches[$PIDX_FS]->IsEnabled());	# Override; always patch if enabled
	patch_ff(0, $ObjPatches[$PIDX_FF]->GetCheck())		if ($dopatch[$PIDX_FF] || $ObjPatches[$PIDX_FF]->IsEnabled());			# Override; always patch if enabled
	patch_eeprom(0, $ObjPatches[$PIDX_CF]->GetCheck())	if ($dopatch[$PIDX_CF] || $ObjPatches[$PIDX_CF]->GetCheck());				# Override; always patch if checked

	$file_data{'work'} = mtk_rebank(\$file_data{'work'}, 0) if ($file_data{'rebank'});

	if (length($file_data{'work'}) == 0x100000)
	{
		my($outdata);
		my($recompress) = 0;

		if ($file_data{'ext'} eq "bin" || $file_name =~ /\.bin$/i)
		{
			$outdata = $file_data{'work'};
		}
		else
		{
			$outdata = $file_data{'exedata'}->[0];

			my($ffpatch) = chr(0x90) x 6;
			my($ffarea) = substr($outdata, 0, 0x10000);
			$ffarea =~ s/\x0F\x85\xDA\x01\x00\x00|\x0F\x85\xF5\x00\x00\x00/$ffpatch/;
			substr($outdata, 0, 0x10000, $ffarea);

			if ($file_data{'exedata'}->[1] == 2)
			{
				my($s_bin) = $file_data{'work'};

				if ($file_data{'exedata'}->[2] == 3)
				{
					substr($outdata, $file_data{'offset'} + 0x1000, length($s_bin), xfx_crypt_mode3($s_bin, substr($outdata, $file_data{'key_offset'}, 0x400), $file_data{'name'}));
				}
				elsif ($file_data{'exedata'}->[2] == 4)
				{
					substr($outdata, $file_data{'offset'} + 0x1000, length($s_bin), (xfx_crypt_mode4($s_bin, substr($outdata, $file_data{'key_offset'}, 0x400), $file_data{'name'}, $file_data{'andkey'}, $file_data{'exkey'}))[0]);
				}
				else
				{
					substr($s_bin, 0x0, 0x8000, reverse(substr($file_data{'work'}, length($file_data{'work'}) - 0x8000, 0x8000)));
					substr($s_bin, length($file_data{'work'}) - 0x8000, 0x8000, reverse(substr($file_data{'work'}, 0x0, 0x8000)));

					substr($outdata, $file_data{'offset'}, $file_data{'exedata'}->[3], xfx_notstr(substr($s_bin, 0, $file_data{'exedata'}->[3])));
					substr($outdata, $file_data{'offset'} + $file_data{'exedata'}->[3] + $file_data{'exedata'}->[4], length($s_bin) - $file_data{'exedata'}->[3], substr($s_bin, $file_data{'exedata'}->[3], length($s_bin) - $file_data{'exedata'}->[3]));
				}

				$recompress = 1;
			}
			else
			{
				substr($outdata, $file_data{'offset'}, length($file_data{'work'}), $file_data{'work'});
			}
		}

		if (open file, ">$file_name")
		{
			binmode file;
			print file $outdata;
			close file;

			if ($recompress && xfx_check_helper())
			{
				my($null4) = chr(0x00) x 4;
				my($strip);

				system(qq($XFX_HELPER -9 -q "$file_name"));

				open file, $file_name;
				binmode file;
				read(file, $strip, -s file);
				close file;

				$strip =~ s/UPX0/$null4/;
				$strip =~ s/UPX1/$null4/;
				$strip =~ s/1\.\d{2}\x00UPX/$null4$null4/;

				open file, ">$file_name";
				binmode file;
				print file $strip;
				close file;
			}

			Win32::GUI::MessageBox($hWndMain, "The patched file was successfully created.", "Done!", MB_OK | MB_ICONINFORMATION);
		}
		else
		{
			error("File access error.", 0);
		}
	}
	else
	{
		error("Unexpected error encountered during patching.\nFile not saved.", 0);
	}

	$file_data{'work'} = $temp;
}

#..............................................................................
sub save_report # ( file_name )
{
	my($file_name) = @_;
	my($report);
	my($type, $entry, $i, $j);
	my($index, $strat, @speeds, $curspd, $spdrep);

	my(@types) = ( '+R/W', '+R', '+R9', '+RW', '-R', '-R9', '-RW' );

	my(%typelimits) =
	(
		'+R/W' => $file_data{'pr_limit'},
		'+R'   => $file_data{'pr_limit'},
		'+R9'  => $file_data{'pr9_limit'},
		'+RW'  => $file_data{'prw_limit'},
		'-R/W' => $file_data{'dr_limit'},
		'-R',  => $file_data{'dr_limit'},
		'-R9'  => $file_data{'dr9_limit'},
		'-RW'  => $file_data{'drw_limit'},
	);

	my(%typelists);

	foreach $type (@types)
	{
		$typelists{$type} = [ ];
	}

	foreach $i (0 .. $file_data{'ncodes'} - 1)
	{
		$index = ($OP_REPORT_MODE > 0) ? sprintf("0x%02X: ", $file_data{'codes'}->[$i][3]) : "";

		if ($file_data{'codes'}->[$i][3] != $file_data{'strats'}->[$i])
		{
			$strat = " -> $file_data{'codes'}->[translate_index([ $file_data{'codes'}->[$i][0], $file_data{'strats'}->[$i] ])][2]";
		}
		else
		{
			$strat = "";
		}

		@speeds = ( );

		foreach $j (0 .. $#MEDIA_SPEEDS)
		{
			next if ($MEDIA_SPEEDS[$j] == 1 && substr($file_data{'codes'}->[$i][0], 0, 2) eq "+R");
			next if ($MEDIA_SPEEDS[$j] > $typelimits{$file_data{'codes'}->[$i][0]});

			$curspd = ($MEDIA_SPEEDS[$j] == 2 && substr($file_data{'codes'}->[$i][0], 0, 2) eq "+R") ? "2.4x" : "$MEDIA_SPEEDS[$j]x";
			$curspd .= ',' unless ($MEDIA_SPEEDS[$j] == $typelimits{$file_data{'codes'}->[$i][0]});
			$curspd =~ s/./ /g unless ($file_data{'speeds'}->[$i] & (2 ** $j));

			push @speeds, $curspd;
		}

		$spdrep = "[ " . join(" ", @speeds) . " ]";
		$spdrep =~ s/,(\s+\])$/ $1/;

		push(@{$typelists{$file_data{'codes'}->[$i][0]}}, "$index$file_data{'codes'}->[$i][2]  $spdrep$strat");
	}

	$report  = "OmniPatcher Media Code Report\n";
	$report .= "=============================\n\n";

	$report .= "OmniPatcher version: $PROGRAM_VERSION\n";
	$report .= "Firmware file name : $file_data{'shortname'}\n\n\n";

	$report .= "-" x 80 . "\n";
	$report .= "General Information\n";
	$report .= "-" x 80 . "\n";
	$report .= "Drive type         : $file_data{'fwfamily'}\n";
	$report .= "Vendor string      : $file_data{'drivevid'}\n";
	$report .= "Product string     : $file_data{'drivepid'}\n";
	$report .= "Firmware revision  : $file_data{'fwrev'}\n";
	$report .= "Firmware timestamp : $file_data{'timestamp'}\n\n";
	$report .= "Total media codes  : $file_data{'ncodes'}\n\n";

	foreach $type (@types)
	{
		if (scalar(@{$typelists{$type}}))
		{
			$report .= "-" x 80 . "\n";
			$report .= "$type Media Codes (" . scalar(@{$typelists{$type}}) . ")\n";
			$report .= "-" x 80 . "\n";

			@{$typelists{$type}} = sort(@{$typelists{$type}}) if ($OP_REPORT_MODE > 1);

			foreach $entry (@{$typelists{$type}})
			{
				$report .= "$entry\n";
			}

			$report .= "\n";
		}
	}

	if (open file, ">$file_name")
	{
		print file $report;
		close file;

		Win32::GUI::MessageBox($hWndMain, "The media code report has been created.", "Done!", MB_OK | MB_ICONINFORMATION);
	}
	else
	{
		error("File access error.", 0);
	}
}

#..............................................................................
sub proc_speed
{
	my($idx) = $ObjList->SelectedItem();
	my($i);

	if ($idx >= 0)
	{
		unless ($StratSpeedWarned || $file_data{'codes'}->[$idx][3] == $file_data{'strats'}->[$idx])
		{
			my($used) = 0;

			foreach $i (0 .. $file_data{'ncodes'} - 1)
			{
				$used = 1 if ($file_data{'codes'}->[$idx][0] eq $file_data{'codes'}->[$i][0] && $file_data{'codes'}->[$idx][3] == $file_data{'strats'}->[$i]);
			}

			unless ($used)
			{
				$StratSpeedWarned = 1;
				Win32::GUI::MessageBox($hWndMain, "Please note that media codes with a '!' in front of them are media\ncodes that are currently using another media code's write strategy\nand speed code.  Because they are no longer using their own speed\ncode, changing their burning speed will have no effect.  If you\nwould like to change the burning speed of this media code, you will\nhave to adjust the burning speed of its host media code.\n\nPlease refer to the documentation for more information.\n\nYou will not see this message again until the next time this program\nis run.", "Notice", MB_OK | MB_ICONINFORMATION);
			}
		}

		unless ($PlusRWWarned || $file_data{'codes'}->[$idx][0] ne "+RW")
		{
			$PlusRWWarned = 1;
			Win32::GUI::MessageBox($hWndMain, "Adjusting +RW speeds is not recommended!\n\nPlease refer to the documentation for more information.\n\nYou will not see this warning message again until the next time this\nprogram is run.", "Warning!", MB_OK | MB_ICONWARNING);
		}

		unless ($PlusR9Warned || $file_data{'codes'}->[$idx][0] ne "+R9")
		{
			$PlusR9Warned = 1;
			Win32::GUI::MessageBox($hWndMain, "Adjusting +R9 speeds is not recommended!\n\nYou will not see this warning message again until the next time this\nprogram is run.", "Warning!", MB_OK | MB_ICONWARNING);
		}

		unless ($DashR9Warned || $file_data{'codes'}->[$idx][0] ne "-R9")
		{
			$DashR9Warned = 1;
			Win32::GUI::MessageBox($hWndMain, "Adjusting -R9 speeds is not recommended!\n\nYou will not see this warning message again until the next time this\nprogram is run.", "Warning!", MB_OK | MB_ICONWARNING);
		}

		if ($file_data{'speed_type'} == 1)
		{
			SetCheck($ObjSpeeds[6], $ObjSpeeds[7]->GetCheck()) if (substr($file_data{'codes'}->[$idx][0], 0, 1) eq '+');
		}
		elsif ($file_data{'speed_type'} == 2)
		{
			SetCheck($ObjSpeeds[8], $ObjSpeeds[7]->GetCheck());
		}

		$file_data{'speeds'}->[$idx] = 0;

		foreach $i (0 .. $#ObjSpeeds)
		{
			$file_data{'speeds'}->[$idx] |= ((2 ** $i) * $ObjSpeeds[$i]->GetCheck());
		}
	}

	return 1;
}

1;
