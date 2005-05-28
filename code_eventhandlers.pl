sub Main_Terminate
{
	return -1;
}

sub Main_Activate
{
	if ($ObjStMain->IsVisible())
	{
		$ObjStMain->SetForegroundWindow();
		return 0;
	}

	return 1;
}

sub StMain_Terminate
{
	$ObjStMain->Hide();
	return 0;
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
			($MEDIA_SPEEDS[$i] > $file_data{'pr_limit'}) ? SetInvisible($ObjSpeeds[$i]) : SetVisible($ObjSpeeds[$i])
		}
	}
	else
	{
		$type = $file_data{'codes'}->[$idx][0];

		foreach $i (0 .. $#ObjSpeeds)
		{
			if ( ($MEDIA_SPEEDS[$i] > $file_data{'pr_limit'}  && $type =~ /^\+R/)  ||
			     ($MEDIA_SPEEDS[$i] > $file_data{'dr_limit'}  && $type =~ /^\-R/)  ||
			     ($MEDIA_SPEEDS[$i] > $file_data{'pr9_limit'} && $type =~ /^\+R9/) ||
			     ($MEDIA_SPEEDS[$i] > $file_data{'dr9_limit'} && $type =~ /^\-R9/) ||
			     ($MEDIA_SPEEDS[$i] > $file_data{'prw_limit'} && $type =~ /^\+RW/) ||
			     ($MEDIA_SPEEDS[$i] > $file_data{'drw_limit'} && $type =~ /^\-RW/) ||
			     ($MEDIA_SPEEDS[$i] == 1 && $type =~ /^\+/) )
			{
				SetDisable($ObjSpeeds[$i]);
				SetInvisible($ObjSpeeds[$i]);
			}
			elsif ($MEDIA_SPEEDS[$i] == 16 && $file_data{'speed_type'} == 2 && $file_data{'mctype'} == 4)
			{
				SetDisable($ObjSpeeds[$i]);
				SetVisible($ObjSpeeds[$i]);
			}
			else
			{
				SetEnable($ObjSpeeds[$i]);
				SetVisible($ObjSpeeds[$i]);
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

sub List_DblClick
{
	my($idx) = $ObjList->SelectedItem();
	my($i);

	if ($file_data{'strat_status'} >= 0 && $file_data{'codes'}->[$idx][0] =~ /^.R$/)
	{
		@StratList = grep { $_->[0] eq $file_data{'codes'}->[$idx][0] } @{$file_data{'codes'}};

		for ($i = 0; $i <= $#StratList; ++$i)
		{
			last if ($StratList[$i][3] == $file_data{'strats'}->[$idx]);
		}

		$ObjStList->Clear();
		$ObjStList->Add( map { $_->[2] } @StratList );
		$ObjStList->Select($i);

		if ($file_data{'codes'}->[$idx][0] eq "+R")
		{
			$ObjStMain->Text(sprintf("%s%s-%02X", @{$file_data{'codes'}->[$idx][1]}));
		}
		else
		{
			$ObjStMain->Text($file_data{'codes'}->[$idx][1][0]);
		}

		$ObjStMain->Left($ObjMain->Left() + $NC_WIDTH);
		$ObjStMain->Top($ObjMain->Top() + $NC_HEIGHT);
		$ObjStMain->Show();
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
sub Speeds7_Click { return proc_speed(); }
sub Speeds8_Click { return proc_speed(); }

sub SpdRep_Click
{
	my(%ofn) =
	(
		-owner				=> $hWndMain,
		-title				=> "Select File Name for the Media Code Report",
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

sub DefStrat_Click
{
	my($entry, $gen, $src, $dst, $st_count, $sp_count);

	if ($DEF_STRAT_REV eq "" || $#DEF_STRATS < 0)
	{
		error(qq(The "$DEFSTRATCONF" file is missing or corrupt.));
		return 1;
	}

	foreach $entry (@DEF_STRATS)
	{
		foreach $gen (@{$entry->[3]})
		{
			if ($file_data{'gen'} == $gen)
			{
				$src = find_index($entry->[0]);

				if ($src >= 0)
				{
					$dst = find_index($entry->[1]);

					if ( $dst >= 0 &&
					     $file_data{'strats'}->[$src] != $file_data{'codes'}->[$dst][3] &&
					     length($file_data{'codes'}->[$src][0]) == 2 && length($file_data{'codes'}->[$dst][0]) == 2 )
					{
						++$st_count;
						$file_data{'strats'}->[$src] = $file_data{'codes'}->[$dst][3];
						refresh_st_display($src);
					}

					if ( $#{$entry->[2]} == 0 && $entry->[2][0] > 0 &&
					     $file_data{'speeds'}->[$src] != $entry->[2][0] )
					{
						++$sp_count;
						$file_data{'speeds'}->[$src] = $entry->[2][0];
					}
				}

				last;

			} # END: if $gen

		} # END: foreach $gen

	} # END: foreach $entry

	List_Click();

	Win32::GUI::MessageBox($hWndMain, sprintf("%d write strategy replacement(s) applied.\n%d writing speed adjustment(s) applied.\n\nRevision %s", $st_count, $sp_count, $DEF_STRAT_REV), "Status", MB_OK | MB_ICONINFORMATION);

	return 1;
}

sub Patches0_Click
{
	SetCheck($ObjPatches[$PIDX_RS16], 0)	if ($ObjPatches[$PIDX_RS12]->GetCheck());

	return 1;
}

sub Patches1_Click
{
	SetCheck($ObjPatches[$PIDX_RS12], 0)	if ($ObjPatches[$PIDX_RS16]->GetCheck());

	return 1;
}

sub Patches3_Click
{
	if ($ObjPatches[$PIDX_ES]->GetCheck() && $ObjPatches[$PIDX_FS]->IsEnabled() && !$ObjPatches[$PIDX_FS]->GetCheck())
	{
		my($temp) = $PATCH_NAMES[$PIDX_FS];
		$temp =~ s/"/'/g;
		Win32::GUI::MessageBox($hWndMain, "If you choose to apply the \"$PATCH_NAMES[$PIDX_ES]\"\npatch, it is highly recommended that you also apply the\n\"$temp\" patch.", "Notice", MB_OK | MB_ICONINFORMATION);

		SetCheck($ObjPatches[$PIDX_FS], 1);
	}

	return 1;
}

sub Patches5_Click
{
	if ($ObjPatches[$PIDX_FF]->GetCheck() && !$FRCWarned)
	{
		$FRCWarned = 1;
		Win32::GUI::MessageBox($hWndMain, "It is recommended that you apply this patch only if your burns exhibit\na \"mountain\" error effect at the very end of a disc.\n\nPlease refer to the documentation for more information.\n\nYou will not see this message again until the next time this program\nis run.", "Notice", MB_OK | MB_ICONINFORMATION);
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
		read(file, $new_file{'work'}, -s file);
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
		$new_file{'andkey'} = $xfx->[0][0][4];
		$new_file{'exkey'} = $xfx->[0][0][5];
		$new_file{'exedata'} = $xfx->[1];

		return error("Unable to process this .EXE file!\nPlease make sure that the file is valid.\n\nIf this firmware flasher is scrambled/compressed, you\nshould consider downloading an unscrambled version\nof the flasher from one of these two websites:\n-  http://dhc014.rpc1.org/indexOEM.htm\n-  http://codeguys.rpc1.org/firmwares.html", 1) if (length($new_file{'work'}) != 0x100000);
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
	my($report);
	my($plus_r_cnt, $plus_rw_cnt, $plus_cnt) = @{$file_data{'mcpdata'}};
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

	# Needs to be cleaned up (might use speed in firmware to show highest burn speed)
	foreach $i (0 .. $file_data{'ncodes'} - 1)
	{
		$index = ($OP_REPORT_MODE > 0) ? sprintf("0x%02X: ", $file_data{'codes'}->[$i][3]) : "";

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

	$report  = "Drive type:\t    $file_data{'fwfamily'}\n";
	$report .= "Drive name string:\t    $file_data{'driveid'}    \n";
	$report .= "Firmware revision:\t    $file_data{'fwrev'}\n";
	$report .= "Firmware timestamp:   $file_data{'timestamp'}\n\n";

	$report .= "Save bitsetting:\t    " . ($file_data{'patch_status'}->[$PIDX_AB] < 0 ? "Yes" : "No") . "\n\n";

	$report .= "Max burn +R:\t    " . ($file_data{'pr_limit'} eq 2 ? "2.4" : "$file_data{'pr_limit'}") . "x\n" if ($file_data{'pr_limit'});
	$report .= "Max burn +R9:\t    " . ($file_data{'pr9_limit'} eq 2 ? "2.4" : "$file_data{'pr9_limit'}") . "x\n" if ($file_data{'pr9_limit'});
	$report .= "Max burn +RW:\t    " . ($file_data{'prw_limit'} eq 2 ? "2.4" : "$file_data{'prw_limit'}") . "x\n" if ($file_data{'prw_limit'});
	$report .= "Max burn -R:\t    $file_data{'dr_limit'}x\n" if ($file_data{'dr_limit'});
	$report .= "Max burn -R9:\t    $file_data{'dr9_limit'}x\n" if ($file_data{'dr9_limit'});
	$report .= "Max burn -RW:\t    $file_data{'drw_limit'}x\n" if ($file_data{'drw_limit'});

	$report .= "\n";

	$report .= "Total media codes:\t    $file_data{'ncodes'}\n\n";

	foreach $type (@types)
	{
		$report .= "Media Codes $type:\t    " . scalar(@{$typelists{$type}}) . "\n" if (scalar(@{$typelists{$type}}));
	}
	
	Win32::GUI::MessageBox($hWndMain, $report, "Firmware Information", MB_OK | MB_ICONINFORMATION);
	return 1;
}

sub Cmds3_Click
{
	Win32::GUI::MessageBox($hWndMain, "$PROGRAM_TITLE\nVersion $PROGRAM_VERSION, built on $BUILD_STAMP\n\nWeb: http://codeguys.rpc1.org/", "About", MB_OK | MB_ICONINFORMATION);
	return 1;
}

sub StList_DblClick
{
	StCmds0_Click();
	return 1;
}

sub StCmds0_Click
{
	my($idxa) = $ObjList->SelectedItem();
	my($idxb) = $ObjStList->SelectedItem();

	$ObjStMain->Hide();

	$file_data{'strats'}->[$idxa] = $StratList[$idxb][3];
	refresh_st_display($idxa);

	return 1;
}

sub StCmds1_Click
{
	$ObjStMain->Hide();
	return 1;
}

1;
