require 'timestamp.pl';

$PROGRAM_TITLE = 'OmniPatcher for LiteOn DVD-Writers';
$PROGRAM_VERSION = '1.0.0';

use Win32::GUI;

require "lib_win32ofn.pl";
require "lib_xflashx.pl";
require "lib_speedhack.pl";
require "lib_gui_helpers.pl";
require "code_patches.pl";
require "code_gui_funcs.pl";
require "code_initgui.pl";
require "code_eventhandlers.pl";

$ObjMain->Show();
Win32::GUI::Dialog();
