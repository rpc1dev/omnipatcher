##
# Code Guys Perl Projects
# Common : General utility functions
#
# Modified: 2005/07/22, C64K
# Revision: 1.1.6
#
# Implicit dependencies: (none)
#

##
# External/extended configuration loader
#
$COM_EXTCONFIG_FILE = '.extconfig';

sub load_extconfig # ( )
{
	if (-f $COM_EXTCONFIG_FILE)
	{
		open file, $COM_EXTCONFIG_FILE;
		map { eval } (<file>);
		close file;
	}
}

##
# Debugging
#
$COM_PRINT_DEBUGGING_MESSAGES = 0;

sub dbgout # ( debugging_output )
{
	##
	# Prints debug messages.
	#
	print @_ if ($COM_PRINT_DEBUGGING_MESSAGES);
}

##
# String-manipulation utilities
#
sub nullpad # ( str, len )
{
	##
	# Adds trailing null characters to a string to achieve a specific length.
	#
	my($str, $len) = @_;
	return $str . chr(0x00) x ($len - length($str));
}

sub nulltrim # ( str )
{
	##
	# Trims trailing null characters from a string.
	#
	my($str) = @_;
	$str =~ s/\x00+$//g;
	return $str;
}

sub ltrim # ( str )
{
	##
	# Trims leading whitespace.
	#
	my($str) = @_;
	$str =~ s/^\s+//;
	return $str;
}

sub rtrim # ( str )
{
	##
	# Trims trailing whitespace.
	#
	my($str) = @_;
	$str =~ s/\s+$//;
	return $str;
}

sub trim # ( str )
{
	##
	# Trims whitespace.
	#
	return ltrim(rtrim($_[0]));
}

sub str2hex # ( str )
{
	##
	# Returns a hex representation of a string, e.g., "E1 C0 DE 47".
	#
	return join(' ', map { sprintf('%02X', ord($_)) } split (//, $_[0]));
}

sub str2be16b # ( str )
{
	##
	# Converts a standard 8-bit string to a 16-bit string.
	#
	return chr(0x00) . join(chr(0x00), split(//, $_[0]));
}

sub be16b2str # ( be16b )
{
	##
	# Converts a 16-bit string to a standard 8-bit string.
	#
	my($be16b) = @_;
	my($ret, $i);

	for ($i = 1; $i < length($be16b); $i += 2)
	{
		$ret .= substr($be16b, $i, 1);
	}

	return $ret;
}

sub int2be16b # ( int )
{
	##
	# Converts an integer to a string representing a 16-bit big endian integer.
	#
	return pack("n", $_[0]);
}

sub be16b2int # ( be16b )
{
	##
	# Converts a string representing a 16-bit big endian integer to an integer.
	#
	return unpack("n", $_[0]);
}

sub notstr # ( str )
{
	##
	# Returns a string with NOT applied to all of its bytes.
	#
	return join('', map { chr(ord($_) ^ 0xFF) } split(//, $_[0]));
}

sub rev_end # ( str )
{
	##
	# Chunks a string of 8-bit bytes into a string of 16-bit words and
	# then flips the LSB and MSB of each word; useful because IDE drive
	# identifications are byte-swapped like this (ATAPI is "normal").
	#
	my($str) = @_;
	my($ret, $i);

	for ($i = 0; $i < length($str); $i += 2)
	{
		$ret .= reverse(substr($str, $i, 2));
	}

	return $ret;
}

##
# Array utilities
#
sub sum # ( number_array )
{
	##
	# Takes the sum of all elements in an array.
	#
	my($ret) = 0;
	map { $ret += $_ } @_;
	return $ret;
}

sub makeset # ( number_array )
{
	##
	# Turns a list into a set... i.e., remove all duplicates
	#
	my($x) = shift;
	return $x unless (@_);
	return (grep { $x == $_ } @_) ? makeset(@_) : ($x, makeset(@_));
}

sub min # ( number_array )
{
	return ( sort {$a <=> $b} @_ )[0];
}

sub max # ( number_array )
{
	return ( sort {$b <=> $a} @_ )[0];
}

##
# File utilities
#
sub loadbinary # ( filename, &buffer )
{
	##
	# Loads a binary file into a buffer (passed by reference)
	#
	my($filename, $buffer) = @_;

	open bfile, $filename;
	binmode bfile;
	read(bfile, ${$buffer}, -s bfile);
	close bfile;
}

sub writebinary # ( filename, &buffer )
{
	##
	# Writes a binary file from a buffer (passed by reference).
	#
	my($filename, $buffer) = @_;

	open bfile, ">$filename";
	binmode bfile;
	print bfile ${$buffer};
	close bfile;
}

##
# Firmware utilities
#
sub getfwid_mtk # ( &str, rule_levels, internal_fwlen )
{
	##
	# Extracts basic firmware information.
	# Returns: (rule_level, vid, pid, fwrev, timestamp, int_fwrev)
	#
	my($str, $rule_levels, $internal_fwlen) = @_;
	my(@ret);

	# Run getfwid_mtk_helper with different levels of search rule relaxations
	# until a result is found or until we run out of rule relaxation levels
	#
	foreach my $rule_level (@{$rule_levels})
	{
		@ret = getfwid_mtk_helper($str, $rule_level, $internal_fwlen);

		if ($ret[0])
		{
			$ret[0] = $rule_level;
			last;
		}
	}

	return @ret;
}

sub getfwid_mtk_helper # ( &str, rule_level, internal_fwlen )
{
	##
	# Extracts basic firmware information.
	# Returns: (found, vid, pid, fwrev, timestamp, int_fwrev)
	#
	my($str, $rule_level, $internal_fwlen) = @_;
	my($core, $pattern, $internal_fwrev);

	# Rule relaxations: Weaker pattern rules means more matches, especially
	# for the older firmwares, but also increases the risk of false positives...
	# most DVDRW drives should be fine with level 1, most drives with level 2,
	# and level 3 will cover the legacy drives.
	#
	if ($rule_level == 1)
	{
		$core = substr(${$str}, 0x4000);
		$pattern = '\x05\x80\x00\x32\x5B\x00{3}(.{8})(.{16})(.{4})(.{16})';
	}
	elsif ($rule_level == 2)
	{
		$core = substr(${$str}, 0x4000);
		$pattern = '\x05\x80\x00\x32[\x1F\x5B]\x00{3}(.{8})(.{16})(.{4})(.{16})';
	}
	elsif ($rule_level == 3)
	{
		$core = substr(${$str}, 0x4000);
		$pattern = '\x05\x80\x00[\x31\x32][\x1F\x5B]\x00{3}(.{8})(.{16})(.{4})(.{0})';
	}
	elsif ($rule_level == 4)
	{
		$core = substr(${$str}, 0x0000);
		$pattern = '\x05\x80\x00[\x31\x32][\x1F\x5B]\x00{3}(.{8})(.{16})(.{4})(.{0})';
	}

	# Regexp patterns for finding the internal firmware version...
	#
	my(@internal_fwpats) =
	(
		'\x7D([\x00\x20-\x7F])\x90.{19,23}' x 16,
		'\x7B([\x00\x20-\x7F])\x7D.{10,12}' x 16,
		'\x7D([\x00\x20-\x7F])\x7F.{5,8}' x 16,
	);

	# Extract the internal firmware version...
	#
	if ( $core =~ /$internal_fwpats[0]/s ||
	     $core =~ /$internal_fwpats[1]/s ||
	     $core =~ /$internal_fwpats[2]/s )
	{
		$internal_fwrev = join('', map { substr($core, $-[$_], $+[$_] - $-[$_]) } (1 .. $internal_fwlen));
	}

	# Extract the drive identification... and convert null bytes to spaces
	#
	my(@ret) =
	(
		map { my($x) = $_; $x =~ s/\x00/ /sg; $x; }
		($core =~ /$pattern/s) ?
		(1, $1, $2, $3, $4, $internal_fwrev) :
		(0, '', '', '', '', $internal_fwrev)
	);

	$ret[4] = '' if ($ret[4] !~ /(?:199|20[01])\d/s);

	return @ret;
}

sub normalize_timestamp # ( str )
{
	##
	# Returns the time in a [ year, month, date ] format,
	# which is useful when dealing with those pesky Sony timestamps
	#
	my($str) = @_;

	if ($str =~ /(\d{4})\/(\d{2})\/(\d{2})/s)
	{
		return [ $1, $2, $3 ];
	}
	elsif ($str =~ /([A-Z][a-z]{2})(\d{2}) ,(\d{4})/s)
	{
		my(%months) =
		(
			Jan =>  1, Feb =>  2, Mar =>  3, Apr =>  4,
			May =>  5, Jun =>  6, Jul =>  7, Aug =>  8,
			Sep =>  9, Oct => 10, Nov => 11, Dec => 12,
		);

		return [ $3, $months{$1}, $2 ];
	}
	else
	{
		return [ 0, 0, 0 ];
	}
}

sub format_fwrev # ( std, int )
{
	##
	# Formats the standard and internal firmware revisions into one
	# combined firmware revision suitable for concise display
	#
	my($std, $int) = @_;

	return $std if ($int eq '');
	return $int if ($std eq '');

	my($std_pattern) = quotemeta($std);

	$int =~ s/^$std_pattern//s;
	$int = "-$int" if (length($int) > 0 && substr($int, 0, 1) ne '-');

	return "$std$int";
}

1;
