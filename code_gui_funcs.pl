$OP_REPORT_MODE = 0;

sub load_file # ( )
{
	my($i, $label);

	my($header) = substr($file_data{'work'}, 0xF0000, 0x200);

	if ($header =~ /SOHW-8\d2S|DW-.18A|LDW-\d51S/)
	{
		$file_data{'gen'} = 2;
	}
	elsif ($header =~ /LDW-.[01]1/)
	{
		$file_data{'gen'} = 1;
	}
	elsif ($header =~ /DW-.(\d{2})A/)
	{
		$file_data{'gen'} = (($1 >= 20) ? 3 : 2);
	}
	else
	{
		$file_data{'gen'} = 0;
		error("Unable to classify firmware.");
	}

	if ($file_data{'gen'} == 0)
	{
		$file_data{'pbankpos'} = 0x00000;
		$file_data{'dbankpos'} = 0x00000;
	}
	elsif ($file_data{'gen'} < 3)
	{
		$file_data{'pbankpos'} = 0xC0000;
		$file_data{'dbankpos'} = 0xD0000;
	}
	else
	{
		$file_data{'pbankpos'} = 0xC0000;
		$file_data{'dbankpos'} = 0x90000;
	}

	getmctype();

	$file_data{'codes'} = [ getcodes() ];
	$file_data{'ncodes'} = scalar(@{$file_data{'codes'}});

	if ($file_data{'gen'} >= 3 && $file_data{'ncodes'} < 120)
	{
		$file_data{'codes'} = [ ];
		$file_data{'ncodes'} = 0;
		error("Unable to read the media code table!\n\nYou may need to upgrade to a newer\nversion of OmniPatcher.");
	}

	$file_data{'speeds'} = [ map { $_->[1][-1] } @{$file_data{'codes'}} ];
	$file_data{'strats'} = [ map { $_->[3] } @{$file_data{'codes'}} ];

	if ($file_data{'gen'} < 3)
	{
		$file_data{'r_limit'} = 8;
		$file_data{'r9_limit'} = 4;
		$file_data{'rw_limit'} = 4;
	}
	else
	{
		$file_data{'r_limit'} = 16;
		$file_data{'r9_limit'} = 4;
		$file_data{'rw_limit'} = 4;
	}

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

	$file_data{'patch_status'} = [ -1, -1, -1, -1, -1, -1 ];

	if ($file_data{'gen'} > 0 && $file_data{'gen'} < 3)
	{
		$file_data{'patch_status'}->[0] = patch_rs(1);
		$file_data{'patch_status'}->[1] = patch_abs(1, -1);
		$file_data{'patch_status'}->[2] = patch_fb(1, -1);
		$file_data{'patch_status'}->[3] = patch_sf(1, -1);
		$file_data{'patch_status'}->[4] = patch_ff(1, -1);
		$file_data{'patch_status'}->[5] = patch_eeprom(1, -1);
	}
	elsif ($file_data{'gen'} == 3)
	{
		$file_data{'patch_status'}->[1] = patch_abs(1, -1);
		$file_data{'patch_status'}->[5] = patch_eeprom(1, -1);
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

	SetEnable($ObjSpdRep);
	SetEnable($ObjCmds[1]);

	$ObjCmdGroup->Text($file_data{'shortname'});
}

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

	patch_rs(0)												if ($dopatch[0]);
	patch_abs(0, $ObjPatches[1]->GetCheck())		if ($dopatch[1]);
	patch_fb(0, $ObjPatches[2]->GetCheck())		if ($dopatch[2]);
	patch_sf(0, $ObjPatches[3]->GetCheck())		if ($dopatch[3] || $ObjPatches[3]->IsEnabled());	# Override; always patch if enabled
	patch_ff(0, $ObjPatches[4]->GetCheck())		if ($dopatch[4] || $ObjPatches[4]->IsEnabled());	# Override; always patch if enabled
	patch_eeprom(0, $ObjPatches[5]->GetCheck())	if ($dopatch[5]);

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
					substr($outdata, $file_data{'offset'} + 0x1000, length($s_bin), (xfx_crypt_mode4($s_bin, substr($outdata, $file_data{'key_offset'}, 0x400), $file_data{'name'}, $file_data{'exkey'}))[0]);
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

sub save_report # ( file_name )
{
	my($file_name) = @_;
	my($report);
	my($type, $entry, $i, $j);
	my($index, $strat, @speeds, $curspd, $spdrep);

	my(@types) = ( '+R/W', '+R', '+R9', '+RW', '-R', '-RW' );
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
			$strat = " -> $file_data{'codes'}[translate_index([ $file_data{'codes'}->[$i][0], $file_data{'strats'}->[$i] ])][2]";
		}
		else
		{
			$strat = "";
		}

		@speeds = ( );

		foreach $j (0 .. $#MEDIA_SPEEDS)
		{
			next if ($MEDIA_SPEEDS[$j] == 1 && substr($file_data{'codes'}->[$i][0], 0, 2) eq "+R");
			next if ($MEDIA_SPEEDS[$j] > $file_data{'r_limit'});

			$curspd = ($MEDIA_SPEEDS[$j] == 2 && substr($file_data{'codes'}->[$i][0], 0, 2) eq "+R") ? "2.4x" : "$MEDIA_SPEEDS[$j]x";
			$curspd .= ',' unless ($MEDIA_SPEEDS[$j] == $file_data{'r_limit'});
			$curspd =~ s/./ /g unless ($file_data{'speeds'}->[$i] & (2 ** $j));

			push @speeds, $curspd;
		}

		$spdrep = "[ " . join(" ", @speeds) . " ]";
		$spdrep =~ s/,(\s+\])$/ $1/;

		push(@{$typelists{$file_data{'codes'}->[$i][0]}}, "$index$file_data{'codes'}->[$i][2]  $spdrep$strat");
	}

	$report  = "OmniPatcher Media Code Report\n";
	$report .= "=============================\n\n";
	$report .= "File name: $file_data{'shortname'}\n";
	$report .= "Last modified: " . localtime((stat($file_data{'longname'}))[9]) . "\n\n\n";

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

		$file_data{'speeds'}->[$idx] = 0;

		foreach $i (0 .. $#ObjSpeeds)
		{
			$file_data{'speeds'}->[$idx] |= ((2 ** $i) * $ObjSpeeds[$i]->GetCheck());
		}
	}

	return 1;
}

1;
