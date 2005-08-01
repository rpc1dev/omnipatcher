##
# OmniPatcher for Optical Drives
# Main : Miscellaneous helper/utility functions
#
# Modified: 2005/07/25, C64K
#

sub op_dbgout # ( function, str )
{
	my($line) = sprintf("%-16s : %s", @_);

	if ($COM_PRINT_DEBUGGING_MESSAGES)
	{
		ui_appendtext($DebugTab->{'Log'}, "$line\r\n");
		dbgout("$line\n");
	}

	if ($OP_SAVE_LOG)
	{
		open logfile, ">>omnipatcher.log";
		print logfile "$line\n";
		close logfile;
	}
}

sub op_dbgdumpfw # ( )
{
	writebinary("$Current{'longname'}.opdbg.bin", \$Current{'fw'});
}

sub op_proc_args # ( )
{
	my($delim) = '<"::">';

	if ($#ARGV >= 0 && join($delim, @ARGV, '') =~ /^((?:-(?:savelog|customids)$delim)*)(?:(.+?)$delim)?(.*?)$/si && length($3) == 0)
	{
		my($switches, $filename) = ($1, $2);

		$OP_SAVE_LOG = 1 if ($switches =~ /savelog/i);
		$FW_ALLOW_CUSTOM_DRIVEIDS = 1 if ($switches =~ /customids/i);

		fw_load($filename) if ($filename ne '');
	}
}

1;
