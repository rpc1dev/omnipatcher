require 'timestamp.pl';

$PROGRAM_TITLE = 'OmniPatcher for LiteOn DVD-Writers';
$PROGRAM_VERSION = '1.3.1';

use Win32::GUI;

require "lib_xflashx.pl";
require "lib_speedhack.pl";
require "code_patches.pl";
require "code_strat.pl";
require "code_gui_funcs.pl";
require "code_initgui.pl";
require "code_eventhandlers.pl";

require "code_extconfig.pl";

$ObjMain->Show();
Win32::GUI::Dialog();
