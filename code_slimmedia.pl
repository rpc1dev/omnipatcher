$DASH_PATTERN_SLIM = '.\xFF{13}|\x00{13}.|(?:\w[\w \-=\.,\xAD\x00\!\/\[\]]{11}..)';

$PLUS_LEN_SLIM = $PLUS_LEN;
$DASH_LEN_SLIM = 14;

sub slim2norm_spd # ( )
{
	return 0b00011110 if ($_[0] == 0x08);
	return 0b00001110 if ($_[0] == 0x06);
	return 0b00000110 if ($_[0] == 0x04);
	return 0b00000010 if ($_[0] == 0x02);
	return 0b00000001 if ($_[0] == 0x01);
	return 0b00000000;
}

sub norm2slim_spd # ( )
{
	return 0x08 if ($_[0] >= 0b00010000);
	return 0x06 if ($_[0] >= 0b00001000);
	return 0x04 if ($_[0] >= 0b00000100);
	return 0x02 if ($_[0] >= 0b00000010);
	return 0x01 if ($_[0] >= 0b00000001);
	return 0x00;
}

sub getcodes_slim # ( )
{
	my($data, $type);
	my($x, $y, $p, $i);
	my(@codes, @speeds, @ret);
	my($id, $mid, $tid, $rid, %used);

	$data = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);
	%used = ();

	foreach $type ( [ '+R', $PLUS_SAMPLE ],
	                [ '+RW', $PLUSRW_SAMPLE ],
	                [ '+R9', $PLUSD_SAMPLE ] )
	{
		pos $data = 0;

		if ($data =~ /($type->[1])/sg)
		{
			$x = pos($data);
			$y = length($1);

			for ($p = $x - $y; nullunbuf(substr($data, $p - $PLUS_LEN_SLIM, $PLUS_LEN_SLIM)) =~ /$PLUS_PATTERN/s; $p -= $PLUS_LEN_SLIM) { }

			@codes = ();

			for ($i = $p; ; $i += $PLUS_LEN_SLIM)
			{
				$id = nullunbuf(substr($data, $i, $PLUS_LEN_SLIM));

				if ($id =~ /$PLUS_PATTERN/s)
				{
					$mid = nulltrim(substr($id, 0, 8));
					$tid = nulltrim(substr($id, 8, 3));
					$rid = ord(substr($id, 11, 1));
					$spd = ord(substr($id, 12, 1));

					$spd = slim2norm_spd($spd);

					push @codes, [ $type->[0], [ $mid, $tid, $rid, $spd ], sprintf("%-8s/%-3s/%02X", $mid, $tid, $rid) ];
				}
				else
				{
					last;
				}
			}

			foreach $i (0 .. $#codes)
			{
				$codes[$i][3] = $i;

				unless ($used{"$codes[$i][0]$codes[$i][2]$codes[$i][1][3]"} == 1 || ($codes[$i][1][0] eq "" && $codes[$i][1][1] eq "") || substr($codes[$i][1][0], 0, 1) eq "\xFF")
				{
					push @ret, $codes[$i];
					$used{"$codes[$i][0]$codes[$i][2]$codes[$i][1][3]"} = 1;
				}
				else
				{
					dbgout("getcodes_slim(): Discarded \"$codes[$i][2]\"\n");
				}
			}

		} # if sample is found

	} # + type loop

	$data = substr($file_data{'work'}, $file_data{'dbankpos'}, 0x10000);
	%used = ();

	foreach $type ( [ '-R', $DASHR_SAMPLE ],
	                [ '-RW', $DASHRW_SAMPLE ] )
	{
		pos $data = 0;

		if ($data =~ /($type->[1])/sg)
		{
			$x = pos($data);
			$y = length($1);

			for ($p = $x - $y; substr($data, $p - $DASH_LEN_SLIM, $DASH_LEN_SLIM) =~ /$DASH_PATTERN_SLIM/s; $p -= $DASH_LEN_SLIM) { }

			@codes = @speeds = ();

			for ($i = $p; ; $i += $DASH_LEN_SLIM)
			{
				$id = substr($data, $i, $DASH_LEN_SLIM);

				if ($id =~ /$DASH_PATTERN_SLIM/s)
				{
					$mid = nulltrim(substr($id, 0, 12));
					$rid = ord(substr($id, 12, 1));
					$spd = ord(substr($id, 13, 1));

					$spd = slim2norm_spd($spd);

					push @codes, [ $type->[0], [ $mid, $rid, $spd ], sprintf("%-12s/%02X", $mid, $rid) ];
				}
				else
				{
					last;
				}
			}

			foreach $i (0 .. $#codes)
			{
				$codes[$i][3] = $i;

				unless ($used{"$codes[$i][0]$codes[$i][2]$codes[$i][1][2]"} == 1 || $codes[$i][1][0] eq "" || substr($codes[$i][1][0], 1, 1) eq chr(0xFF))
				{
					push @ret, $codes[$i];
					$used{"$codes[$i][0]$codes[$i][2]$codes[$i][1][2]"} = 1;
				}
				else
				{
					dbgout("getcodes_slim(): Discarded \"$codes[$i][2]\"\n");
				}
			}

		} # if sample is found

	} # - type loop

	return sort { ($a->[0] cmp $b->[0]) ? $a->[0] cmp $b->[0] : uc($a->[2]) cmp uc($b->[2]) } @ret;
}

sub setcodes_slim # ( )
{
	my($data, $type);
	my($patch, $idx);
	my($code_old, $code_new);

	$data = substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000);

	foreach $patch (@{$file_data{'plus_patches'}})
	{
		$code_old = quotemeta(pcode2str([$patch->[0], $patch->[1], $patch->[2], norm2slim_spd($patch->[3])], 1));
		$code_new = pcode2str([$patch->[0], $patch->[1], $patch->[2], norm2slim_spd($patch->[4])], 1);

		$data =~ s/$code_old/$code_new/g;
	}

	substr($file_data{'work'}, $file_data{'pbankpos'}, 0x10000, $data);
	$data = substr($file_data{'work'}, $file_data{'dbankpos'}, 0x10000);

	foreach $type ( [ '-R', $file_data{'dashr_patches'} ],
	                [ '-RW', $file_data{'dashrw_patches'} ] )
	{
		foreach $patch (@{$type->[1]})
		{
			$idx = translate_index([$type->[0], $patch->[0]]);

			if ($idx >= 0)
			{
				$code_old = quotemeta(nullpad($file_data{'codes'}->[$idx][1][0], 12) .  chr($file_data{'codes'}->[$idx][1][1]) . chr(norm2slim_spd($file_data{'codes'}->[$idx][1][2])));
				$code_new = nullpad($file_data{'codes'}->[$idx][1][0], 12) .  chr($file_data{'codes'}->[$idx][1][1]) . chr(norm2slim_spd($patch->[1]));

				$data =~ s/$code_old/$code_new/g;
			}
			else
			{
				dbgout("setcodes_slim(): translate_index() returns failure\n");
			}
		}
	}

	substr($file_data{'work'}, $file_data{'dbankpos'}, 0x10000, $data);
}

1;
