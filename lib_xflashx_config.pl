# XFlash-X helper
#
$XFX_HELPER = 'upx.exe';


# XFlash-X helper not-found error handling
#
sub XFX_HELPER_ERR # ( )
{
	error(qq("$XFX_HELPER" could not be found!), 0);
}


# XFlash-X helper execution method... use system() or not; 0=no (def), 1=yes
#
$XFX_HELPER_SYSTEM = 1;


# XFlash-X helper tempfile suffix
#
$XFX_TEMP_SUFFIX = '.xflashx-temp';


# Allow unscrambling of scrambled firmwares; 0=no (def), 1=yes
#
$XFX_UNSCRAMBLE = 0;


# Keep the UPX temp file; 0=no (def), 1=yes
#
$XFX_KEEP_TEMP = 0;


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
