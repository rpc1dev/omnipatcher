##
# OmniPatcher for LiteOn DVD-Writers
# Main : Application-specific configuration overrides
#
# Modified: 2005/06/12, C64K
#

##
# General Options
#
$OP_SAVE_LOG = 0;

##
# Firmware Options
#
$FW_ALLOW_CUSTOM_DRIVEIDS = 0;
$FW_ALLOW_ADVANCED_AUTOBS = 0;

##
# Media Options
#
$MEDIA_REPORT_MODE = 0;		# 0 = normal, 1 = show indices, 2 = show indices and sort by index

##
# UI Options
#
$UI_USE_TABS = 1;
$UI_USE_ROOT = 1;
$UI_USE_SUNKEN = 1;

##
# XFlash Options
#
$COM_XF_PRINT_STATUS         = 0;				# Print status messages?
$COM_XF_UPX_ERR              = sub { &ui_error("'$COM_XF_UPX' could not be found!"); };
$COM_XF_UPX_SYSTEM           = 1;				# Use system() to invoke UPX?
$COM_XF_EXTR_SCRAMSIZE       = 0x110000;		# Scrambled flasher threshold size; -1 to disable
$COM_XF_EXTR_FINGERPRINT     = 0;				# Output to the status stream a md5sum of the firmware?

1;
