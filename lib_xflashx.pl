sub xflashx # ( data )
{
	my($data) = @_;
	my($i, $offset);
	my($start_pattern, $size_pattern, $name_pattern, $table_pattern);

	foreach $i (1 .. 4)
	{
		$start_pattern .= 'BIN_START' . $i . '=(\d{10})\x00';
		$size_pattern .= 'BIN_SIZE' . $i . '=(\d{10})\x00';
		$name_pattern .= 'NEW_FW' . $i . '=([\w\x00].{6})\x00';
	}

	$table_pattern = 'HOW_MANY_BIN=(\d+\x00+)' . "$start_pattern$size_pattern$name_pattern";

	if ($data =~ /$table_pattern/g)
	{
		$offset  = pos($data);
		$offset += $2;

		if ($1 >= 1 && $offset + $6 < length($data))
		{
			return [ substr($data, $offset, $6), $offset ];
		}
	}

	return [ '', 0 ];
}

1;
