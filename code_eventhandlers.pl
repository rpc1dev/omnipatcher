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
			if ( ($MEDIA_SPEEDS[$i] > 4 && $type =~ /^.RW/) ||
			     ($MEDIA_SPEEDS[$i] > 2 && $type =~ /^.R9/) ||
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
	my(%ofn) = %ofn_def;

	$ofn{'filter'} = [ [ "Firmwares (*.bin;*.exe)", "*.bin;*.exe" ] ];
	$ofn{'title'} = "Select File to Patch";
	$ofn{'flags'} = $OFN_ENABLESIZING | $OFN_FILEMUSTEXIST | $OFN_HIDEREADONLY | $OFN_PATHMUSTEXIST;
	$ofn{'def_ext'} = "bin";

	return 1 unless (OFNDialog($GetOpenFileName, \%ofn));

	my(%new_file) =
	(
		longname => $ofn{'file'},
		shortname => $ofn{'file_title'},
	);

	if ($ofn{'file'} =~ /\.(bin|exe)$/i)
	{
		$new_file{'ext'} = lc($1);
	}
	else
	{
		return error("Invalid file type.", 1)
	}

	open file, $ofn{'file'};
	binmode file;
	$new_file{'raw'} = join('', <file>);
	close file;

	if ($new_file{'ext'} eq "bin")
	{
		$new_file{'work'} = [ $new_file{'raw'}, 0 ];
		return error("Invalid .BIN file size!\nAborting load process.", 1) if (length($new_file{'work'}->[0]) != 0x100000);
	}
	else
	{
		$new_file{'work'} = xflashx($new_file{'raw'});
		return error("Unable to process this .EXE file!\nPlease make sure that the file is valid.\n\nYou might also consider using XFlash-X to\nextract a .BIN file to work with instead.", 1) if (length($new_file{'work'}->[0]) != 0x100000);
	}

	if (substr($new_file{'work'}->[0], 0, 1) ne "\x02")
	{
		return error("This firmware appears to be corrupted.\nAborting load process.", 1);
	}

	%file_data = %new_file;
	load_file();

	return 1;
}

sub Cmds1_Click
{
	my(%ofn) = %ofn_def;

	$ofn{'title'} = "Select Output File";
	$ofn{'flags'} = $OFN_ENABLESIZING | $OFN_HIDEREADONLY | $OFN_PATHMUSTEXIST | $OFN_OVERWRITEPROMPT;

	if ($file_data{'ext'} eq "bin")
	{
		$ofn{'filter'} = [ [ "Firmwares (*.bin)", "*.bin" ] ];
		$ofn{'def_ext'} = "bin";
	}
	else
	{
		$ofn{'filter'} = [ [ "Firmwares (*.exe)", "*.exe" ] ];
		$ofn{'def_ext'} = "exe";
	}

	return 1 unless (OFNDialog($GetSaveFileName, \%ofn));

	save_file($ofn{'file'});

	return 1;
}

sub Cmds2_Click
{
	Win32::GUI::MessageBox($hWndMain, "$PROGRAM_TITLE\nVersion $PROGRAM_VERSION, built on $BUILD_STAMP\n\nWeb: http://codeguys.rpc1.org/", "About", MB_OK | MB_ICONINFORMATION);
	return 1;
}

1;
