# XFlash-X helper
#
$XFX_HELPER = 'xflashx_helper.exe';


# XFlash-X helper not-found error handling
#
sub XFX_HELPER_ERR # ( )
{
	error(qq("$XFX_HELPER" could not be found!), 0);
}


# XFlash-X tempfile suffix
#
$XFX_TEMP_SUFFIX = '.xflashx-temp';


# Delete temp file; 0=no, 1=yes (def)
#
$XFX_DELETE_TEMP = 1;


# Print debug messages; 0=no (def), 1=yes
#
$XFX_PRINT_DEBUG = 0;


# Print status messages; 0=no, 1=yes (def)
#
$XFX_PRINT_STATUS = 0;


# Scrambled flasher threshold size; -1=do not use threshold (def), other=scrambled if <= size
#
$XFX_SCRAMSIZE = 0x110000;


# Verify firmwares & reject possible corrupts; 0=no, 1=yes (def)
#
$XFX_VERIFYFW = 1;


# Return extended info; 0=no (def), 1=yes
#
$XFX_RET_EXTENDED = 1;


1;
