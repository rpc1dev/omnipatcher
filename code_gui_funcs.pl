sub load_file # ( )
{
	my($code, $i);

	$file_data{'codes'} = [ getcodes() ];
	$file_data{'speeds'} = [ map { $_->[1][-1] } @{$file_data{'codes'}} ];
	$file_data{'ncodes'} = scalar(@{$file_data{'codes'}});

	$ObjList->Clear();
	List_Click();

	foreach $code (@{$file_data{'codes'}})
	{
		$ObjList->AddString("$code->[2] $code->[0]");
	}

	SetEnable($ObjList);
	$ObjMediaGroup->Text("$MGROUP_NAME ($file_data{'ncodes'} codes)");

	$file_data{'patch_status'} = [ ];

	$file_data{'patch_status'}->[0] = patch_rs(1);
	$file_data{'patch_status'}->[1] = patch_abs(1, -1);
	$file_data{'patch_status'}->[2] = patch_fb(1, -1);
	$file_data{'patch_status'}->[3] = patch_sf(1, -1);
	$file_data{'patch_status'}->[4] = patch_eeprom(1, -1);

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

	SetEnable($ObjCmds[1]);
	$ObjCmdGroup->Text("$file_data{'shortname'} loaded");
}

sub save_file # ( file_name )
{
	my($file_name) = @_;
	my($i, $type, @dopatch, @temp);

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

	@temp = @{$file_data{'work'}};

	setcodes();

	patch_rs(0)												if ($dopatch[0]);
	patch_abs(0, $ObjPatches[1]->GetCheck())		if ($dopatch[1]);
	patch_fb(0, $ObjPatches[2]->GetCheck())		if ($dopatch[2]);
	patch_sf(0, $ObjPatches[3]->GetCheck())		if ($dopatch[3]);
	patch_eeprom(0, $ObjPatches[4]->GetCheck())	if ($dopatch[4]);

	if (length($file_data{'work'}->[0]) == 0x100000)
	{
		substr($file_data{'raw'}, $file_data{'work'}->[1], length($file_data{'work'}->[0]), $file_data{'work'}->[0]);

		if (open file, ">$file_name")
		{
			binmode file;
			print file $file_data{'raw'};
			close file;

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

	$file_data{'work'} = [ @temp ];
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
