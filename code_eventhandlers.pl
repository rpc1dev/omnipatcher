sub Main_Terminate
{
	return -1;
}

sub List_Click
{
	my($idx) = $ObjList->SelectedItem();
	my($i, $type);

	if ($idx < 0)
	{
		foreach $i (0 .. $#ObjSpeeds)
		{
			SetDisable($ObjSpeeds[$i]);
			SetCheck($ObjSpeeds[$i], 0);
			SetText($ObjSpeeds[$i], "$MEDIA_SPEEDS[$i]x");
		}
	}
	else
	{
		$type = $file_data{'codes'}->[$idx][0];

		foreach $i (0 .. $#ObjSpeeds)
		{
			if ( ($MEDIA_SPEEDS[$i] > $file_data{'r_limit'}) ||
			     ($MEDIA_SPEEDS[$i] > $file_data{'r9_limit'} && $type =~ /^.R9/) ||
			     ($MEDIA_SPEEDS[$i] > $file_data{'rw_limit'} && $type =~ /^.RW/) ||
			     ($MEDIA_SPEEDS[$i] == 1 && $type =~ /^\+/) )
			{
				SetDisable($ObjSpeeds[$i]);
			}
			else
			{
				SetEnable($ObjSpeeds[$i]);
			}

			if ($MEDIA_SPEEDS[$i] == 2 && $type =~ /^\+/)
			{
				SetText($ObjSpeeds[$i], "2.4x");
			}
			else
			{
				SetText($ObjSpeeds[$i], "$MEDIA_SPEEDS[$i]x");
			}

			SetCheck($ObjSpeeds[$i], ($file_data{'speeds'}->[$idx] & (2 ** $i)) ? 1 : 0);
		}
	}

	return 1;
}

sub Speeds0_Click { return proc_speed(); }
sub Speeds1_Click { return proc_speed(); }
sub Speeds2_Click { return proc_speed(); }
sub Speeds3_Click { return proc_speed(); }
sub Speeds4_Click { return proc_speed(); }
sub Speeds5_Click { return proc_speed(); }
sub Speeds6_Click { return proc_speed(); }

sub SpdRep_Click
{
	my(%ofn) =
	(
		-owner				=> $hWndMain,
		-title				=> "Select File Name for the Media Codes Report",
		-directory			=> "",
		-file					=> "",
		-filter				=> [ "Text Documents (*.txt)", "*.txt" ],
		-defaultextention	=> "txt",
		-pathmustexist		=> 1,
	);

	return 1 unless ($ofn{'-ret'} = Win32::GUI::GetSaveFileName(%ofn));

	save_report($ofn{'-ret'});

	return 1;
}

sub Patches2_Click
{
	if ($ObjPatches[2]->GetCheck() && $ObjPatches[3]->IsEnabled())
	{
		my($temp) = $PATCH_NAMES[3];
		$temp =~ s/"/'/g;
		Win32::GUI::MessageBox($hWndMain, "If you choose to apply the \"$PATCH_NAMES[2]\"\npatch, it is highly recommended that you also apply the\n\"$temp\" patch.", "Notice", MB_OK | MB_ICONINFORMATION);

		SetCheck($ObjPatches[3], 1);
	}

	return 1;
}

sub Cmds0_Click
{
	my(%ofn) =
	(
		-owner				=> $hWndMain,
		-title				=> "Select File to Patch",
		-directory			=> "",
		-file					=> "",
		-filter				=> [ "Firmwares (*.bin;*.exe)", "*.bin;*.exe" ],
		-defaultextention	=> "bin",
		-filemustexist		=> 1,
		-hidereadonly		=> 1,
		-pathmustexist		=> 1,
	);

	return 1 unless ($ofn{'-ret'} = Win32::GUI::GetOpenFileName(%ofn));

	my(%new_file) =
	(
		longname => $ofn{'-ret'},
		shortname => substr($ofn{'-ret'}, rindex($ofn{'-ret'}, '\\') + 1),
	);

	if ($new_file{'shortname'} =~ /\.(bin|exe)$/i)
	{
		$new_file{'ext'} = lc($1);
	}
	else
	{
		return error("Invalid file type.", 1)
	}

	if ($new_file{'ext'} eq "bin")
	{
		open file, $new_file{'longname'};
		binmode file;
		read(file, $new_file{'work'}, -s $new_file{'longname'});
		close file;

		return error("Invalid .BIN file size!\nAborting load process.", 1) if (length($new_file{'work'}) != 0x100000);
		return error("This firmware appears to be corrupted.\nAborting load process.", 1) if (substr($new_file{'work'}, 0, 1) ne "\x02");
	}
	else
	{
		my($xfx) = xflashx($new_file{'longname'});

		$new_file{'name'} = $xfx->[0][0][0];
		$new_file{'work'} = $xfx->[0][0][1];
		$new_file{'offset'} = $xfx->[0][0][2];
		$new_file{'key_offset'} = $xfx->[0][0][3];
		$new_file{'exkey'} = $xfx->[0][0][4];
		$new_file{'exedata'} = $xfx->[1];

		return error("Unable to process this .EXE file!\nPlease make sure that the file is valid.\n\nIf this firmware flasher is scrambled/compressed, you\nshould consider downloading an unscrambled version\nof the flasher from one of these two websites:\n-  http://codeguys.rpc1.org/firmwares.html\n-  http://dhc014.rpc1.org/indexOEM.htm", 1) if (length($new_file{'work'}) != 0x100000);
	}

	%file_data = %new_file;
	load_file();

	return 1;
}

sub Cmds1_Click
{
	my(%ofn) =
	(
		-owner				=> $hWndMain,
		-title				=> "Select Output File",
		-directory			=> "",
		-file					=> "",
		-pathmustexist		=> 1,
	);

	if ($file_data{'ext'} eq "bin")
	{
		$ofn{'-filter'} = [ "Raw Firmwares (*.bin)", "*.bin" ];
		$ofn{'-defaultextention'} = "bin";
	}
	else
	{
		$ofn{'-filter'} = [ "Executable Firmwares (*.exe)", "*.exe", "Raw Firmwares (*.bin)", "*.bin" ];
		$ofn{'-defaultextention'} = "exe";
	}

	return 1 unless ($ofn{'-ret'} = Win32::GUI::GetSaveFileName(%ofn));

	save_file($ofn{'-ret'});

	return 1;
}

sub Cmds2_Click
{
	Win32::GUI::MessageBox($hWndMain, "$PROGRAM_TITLE\nVersion $PROGRAM_VERSION, built on $BUILD_STAMP\n\nWeb: http://codeguys.rpc1.org/", "About", MB_OK | MB_ICONINFORMATION);
	return 1;
}

1;
