sub load_file # ( )
{
	my($code, $i);

	my($header) = substr($file_data{'work'}, 0xF0000, 0x200);

	if ($header =~ /SOHW-8.2S|DW-.18A/)
	{
		$file_data{'gen'} = 2;
	}
	elsif ($header =~ /DW-.(\d{2})A/)
	{
		$file_data{'gen'} = (($1 >= 20) ? 3 : 2);
	}
	else
	{
		$file_data{'gen'} = 1;
	}

	$file_data{'codes'} = [ getcodes() ];
	$file_data{'speeds'} = [ map { $_->[1][-1] } @{$file_data{'codes'}} ];
	$file_data{'ncodes'} = scalar(@{$file_data{'codes'}});

	$ObjList->Clear();
	List_Click();

	if ($file_data{'gen'} < 3)
	{
		$file_data{'r_limit'} = 8;
		$file_data{'r9_limit'} = 2;
		$file_data{'rw_limit'} = 4;
	}
	else
	{
		$file_data{'r_limit'} = 16;
		$file_data{'r9_limit'} = 4;
		$file_data{'rw_limit'} = 8;
	}

	foreach $code (@{$file_data{'codes'}})
	{
		$ObjList->AddString("$code->[2] $code->[0]");
	}

	SetEnable($ObjList);
	$ObjMediaGroup->Text("$MGROUP_NAME ($file_data{'ncodes'} codes)");

	$file_data{'patch_status'} = [ ];

	if ($file_data{'gen'} < 3)
	{
		$file_data{'patch_status'}->[0] = patch_rs(1);
		$file_data{'patch_status'}->[1] = patch_abs(1, -1);
		$file_data{'patch_status'}->[2] = patch_fb(1, -1);
		$file_data{'patch_status'}->[3] = patch_sf(1, -1);
		$file_data{'patch_status'}->[4] = patch_eeprom(1, -1);
	}
	else
	{
		$file_data{'patch_status'} = [ -1, -1, -1, -1, -1 ];
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
	my($i, $type, @dopatch);

	$file_data{'plus_patches'} = $file_data{'dashr_patches'} = $file_data{'dashrw_patches'} = [ ];

	foreach $i (0 .. $file_data{'ncodes'} - 1)
	{
		if ($file_data{'speeds'}->[$i] > 0 && $file_data{'speeds'}->[$i] != $file_data{'codes'}->[$i][1][-1])
		{
			if ($file_data{'codes'}->[$i][0] eq "-R")
			{
				$type = 'dashr_patches';
			}
			elsif ($file_data{'codes'}->[$i][0] eq "-RW")
			{
				$type = 'dashr_patches';
			}
			else
			{
				$type = 'plus_patches';
			}

			push(@{$file_data{$type}}, [ @{$file_data{'codes'}->[$i][1]}, $file_data{'speeds'}->[$i] ]);
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

	patch_rs(0)												if ($dopatch[0]);
	patch_abs(0, $ObjPatches[1]->GetCheck())		if ($dopatch[1]);
	patch_fb(0, $ObjPatches[2]->GetCheck())		if ($dopatch[2]);
	patch_sf(0, $ObjPatches[3]->GetCheck())		if ($dopatch[3]);
	patch_eeprom(0, $ObjPatches[4]->GetCheck())	if ($dopatch[4]);

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

				unless ($file_data{'exedata'}->[2] == 3)
				{
					substr($s_bin, 0x0, 0x8000, reverse(substr($file_data{'work'}, length($file_data{'work'}) - 0x8000, 0x8000)));
					substr($s_bin, length($file_data{'work'}) - 0x8000, 0x8000, reverse(substr($file_data{'work'}, 0x0, 0x8000)));

					substr($outdata, $file_data{'offset'}, $file_data{'exedata'}->[3], xfx_notstr(substr($s_bin, 0, $file_data{'exedata'}->[3])));
					substr($outdata, $file_data{'offset'} + $file_data{'exedata'}->[3] + $file_data{'exedata'}->[4], length($s_bin) - $file_data{'exedata'}->[3], substr($s_bin, $file_data{'exedata'}->[3], length($s_bin) - $file_data{'exedata'}->[3]));
				}
				else
				{
					substr($outdata, $file_data{'offset'} + 0x1000, length($s_bin), xfx_crypt_mode3($s_bin, substr($outdata, $file_data{'key_offset'}, 0x400), $file_data{'name'}));
				}

				$recompress = 1;
			}
			else
			{
				print length($outdata), "\n";
				print "$file_data{'offset'}\n";
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
				qx($XFX_HELPER -9 -q "$file_name");

				open file, $file_name;
				binmode file;
				my($strip) = join("", <file>);
				close file;

				my($null4) = chr(0x00) x 4;

				$strip =~ s/UPX0/$null4/;
				$strip =~ s/UPX1/$null4/;
				$strip =~ s/1\.24\x00UPX/$null4$null4/;

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
	my(@speeds, $spdrep);

	my(@types) = ( '+R/W', '+R', '+R9', '+RW', '-R', '-RW' );
	my(%typelists);

	foreach $type (@types)
	{
		$typelists{$type} = [ ];
	}

	foreach $i (0 .. $#{$file_data{'codes'}})
	{
		@speeds = ( );

		foreach $j (0 .. $#MEDIA_SPEEDS)
		{
			if ($file_data{'speeds'}->[$i] & (2 ** $j))
			{
				push(@speeds, ($MEDIA_SPEEDS[$j] == 2 && substr($file_data{'codes'}->[$i][0], 0, 2) eq "+R") ? "2.4x" : "$MEDIA_SPEEDS[$j]x");
			}
		}

		$spdrep = "[" . join(", ", @speeds) . "]";

		push(@{$typelists{$file_data{'codes'}->[$i][0]}}, "$file_data{'codes'}->[$i][2]  $spdrep");
	}

	foreach $type (@types)
	{
		if (scalar(@{$typelists{$type}}))
		{
			$report .= "-" x 80 . "\n";
			$report .= "$type Media Codes (" . scalar(@{$typelists{$type}}) . ")\n";
			$report .= "-" x 80 . "\n";

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

		Win32::GUI::MessageBox($hWndMain, "The media codes report has been created.", "Done!", MB_OK | MB_ICONINFORMATION);
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
		$file_data{'speeds'}->[$idx] = 0;

		foreach $i (0 .. $#ObjSpeeds)
		{
			$file_data{'speeds'}->[$idx] |= ((2 ** $i) * $ObjSpeeds[$i]->GetCheck());
		}
	}

	return 1;
}

1;
