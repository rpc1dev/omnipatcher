##
# Mtk Rebanking Common Library
# 1.0.0 (11 Nov 2004)
#

sub mtk_rebank # ( &data, mode[, preserve_bootcode ] )
{
	my($data, $mode, $preserve_bootcode) = @_;
	my($ret, $i);

	if ($mode == 1 && length($$data) == 0x100000)
	{
		for ($i = 0; $i < 0x15; ++$i)
		{
			$ret .= substr($$data, 0x4000, 0x4000);
			$ret .= substr($$data, 0xC000 * $i + 0x8000, ($i < 0x14) ? 0xC000 : 0x8000);
		}

		$ret .= substr($$data, 0x0, 0x4000) if ($preserve_bootcode);
	}
	elsif ($mode == 0 && length($$data) == 0x150000)
	{
		# Note: Restoration will work only if the bootcode has been preserved.

		$ret  = substr($$data, 0x14C000, 0x4000);
		$ret .= substr($$data, 0x000000, 0x4000);

		for ($i = 0; $i < 0x15; ++$i)
		{
			$ret .= substr($$data, 0x10000 * $i + 0x4000, ($i < 0x14) ? 0xC000 : 0x8000);
		}
	}
	else
	{
		$ret = $$data;
	}

	return $ret;
}

sub mtk_rebank_check # ( &data )
{
	my($data) = @_;
	my($bank);
	my($verify_good) = 1;

	for ($bank = 0; $bank < length($$data); $bank += 0x10000)
	{
		$verify_good = 0 if (substr($$data, $bank, 1) ne "\x02");
	}

	return 0 if ($verify_good);

	$verify_good = 1;

	$verify_good = 0 if (substr($$data, 0x0000, 1) ne "\x02");
	$verify_good = 0 if (substr($$data, 0x4000, 1) ne "\x02");
	$verify_good = 0 if (substr($$data, 0xFFF8, 8) ne "LITEONIT");

	return $verify_good;
}

1;
