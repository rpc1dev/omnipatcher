##
# OmniPatcher for Optical Drives
# Firmware : Specifications/parameters table
#
# Modified: 2005/08/15, C64K
#

##
# DVD-Writers
#
%FW_PARAMS_LO_DVDRW =
(
	# fw_letter => [ 'fw_gen', 'fw_family', 'fw_ebank', 'fw_rbank', 'media_pbank', 'media_dbank', 'media_limits'->[ pr, prw, pr9, dr, drw, dr9 ], 'media_count_expected', 'fw_rs_limits'->list, 'fw_rs_defaults'->list, 'fw_idlist' ]
	#
	# Note that the speed limits encoded here are done
	# so in the order indicated in media_const.pl.
	#
	'~' => [ 0x000, 'DVD-Writer',     0x000000, 0x000000, 0x000000, 0x000000, [  0, 0, 0,  0, 0, 0 ],   0, [  0,  0,  0,  0,  0 ], [  0, 0, 0, 0, 0 ], [ ] ],

	'E' => [ 0x011, 'LDW-401S',       0x000000, 0x020000, 0x0C0000, 0x0D0000, [  4, 4, 0,  0, 0, 0 ],  75, [ 12,  8,  8,  8,  8 ], [ 12, 8, 6, 6, 6 ] ],
	'F' => [ 0x011, 'LDW-411S',       0x090000, 0x020000, 0x0C0000, 0x0D0000, [  4, 4, 0,  4, 4, 0 ],  75, [ 12,  8,  8,  8,  8 ], [ 12, 8, 6, 6, 6 ] ],
	'H' => [ 0x011, 'LDW-811S',       0x090000, 0x020000, 0x0C0000, 0x0D0000, [  8, 4, 0,  4, 4, 0 ], 100, [ 12,  8,  8,  8,  8 ], [ 12, 8, 6, 6, 6 ] ],
	'g' => [ 0x012, 'LDW-451S',       0x090000, 0x020000, 0x0C0000, 0x0D0000, [  4, 4, 0,  4, 4, 0 ], 100, [ 12,  8,  8,  8,  8 ], [ 12, 8, 6, 6, 6 ] ],
	'G' => [ 0x012, 'LDW-851S',       0x090000, 0x020000, 0x0C0000, 0x0D0000, [  8, 4, 0,  4, 4, 0 ], 100, [ 12,  8,  8,  8,  8 ], [ 12, 8, 6, 6, 6 ] ],
	'U' => [ 0x021, 'SOHW-812S/802S', 0x090000, 0x020000, 0x0C0000, 0x0D0000, [  8, 4, 0,  8, 4, 0 ], 150, [ 12,  8,  8,  8,  8 ], [ 12, 8, 8, 8, 6 ] ],
	'V' => [ 0x021, 'SOHW-832S/822S', 0x090000, 0x020000, 0x0C0000, 0x0D0000, [  8, 4, 2,  8, 4, 0 ], 150, [ 12,  8,  8,  8,  8 ], [ 12, 8, 8, 8, 6 ] ],
	'T' => [ 0x031, 'SOHW-1213S',     0x090000, 0x020000, 0x0C0000, 0x090000, [ 12, 4, 0,  8, 4, 0 ], 150, [ 16, 16, 16, 16, 12 ], [ 12, 8, 8, 8, 8 ] ],
	'A' => [ 0x032, 'SOHW-1613S',     0x090000, 0x020000, 0x0E0000, 0x090000, [ 16, 4, 0,  8, 4, 0 ], 190, [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 6 ] ],
	'B' => [ 0x032, 'SOHW-1633S',     0x090000, 0x020000, 0x0E0000, 0x090000, [ 16, 4, 2,  8, 4, 0 ], 190, [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 6 ] ],
	'b' => [ 0x032, 'SOHW-1633S-Enh.',0x090000, 0x020000, 0x0E0000, 0x090000, [ 16, 4, 4, 12, 4, 0 ], 220, [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 6 ] ],
	'C' => [ 0x032, 'SOHW-1653S',     0x090000, 0x020000, 0x0E0000, 0x090000, [ 16, 4, 4, 12, 4, 0 ], 220, [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 6 ] ],
	'J' => [ 0x033, 'SOHW-1673S',     0x0A0000, 0x020000, 0x0B0000, 0x100000, [ 16, 8, 4, 16, 6, 0 ], 250, [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 6 ] ],
	'K' => [ 0x033, 'SOHW-1693S',     0x0A0000, 0x020000, 0x0B0000, 0x100000, [ 16, 8, 4, 16, 6, 4 ], 250, [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 6 ] ],

	'L' => [ 0x111, 'SDW-421S',       0x000000, 0x030000, 0x000000, 0x000000, [  4, 2, 0,  0, 0, 0 ],   0, [  8,  8,  8,  8,  8 ], [  8, 6, 6, 6, 4 ] ],
	'M' => [ 0x111, 'SDW-431S',       0x0C0000, 0x040000, 0x0A0000, 0x0D0000, [  4, 2, 0,  2, 2, 0 ],  90, [  8,  8,  8,  8,  8 ], [  8, 6, 6, 6, 4 ] ],
	'P' => [ 0x121, 'SOSW-852S',      0x0C0000, 0x040000, 0x0A0000, 0x0D0000, [  8, 4, 2,  4, 4, 0 ], 140, [  8,  8,  8,  8,  8 ], [  8, 6, 8, 6, 4 ] ],
	'Q' => [ 0x121, 'SOSW-862S (?)',  0x0C0000, 0x040000, 0x0A0000, 0x0D0000, [  8, 4, 2,  0, 0, 0 ], 140, [  8,  8,  8,  8,  8 ], [  8, 6, 8, 6, 4 ] ],
	'u' => [ 0x131, 'SOSW-813S (?)',  0x070000, 0x000000, 0x0E0000, 0x100000, [  8, 8, 4,  8, 6, 4 ], 220, [  8,  8,  8,  8,  8 ], [  8, 6, 8, 6, 4 ] ],
	'v' => [ 0x131, 'SOSW-833S',      0x070000, 0x000000, 0x0E0000, 0x100000, [  8, 8, 4,  8, 6, 4 ], 220, [  8,  8,  8,  8,  8 ], [  8, 6, 8, 6, 4 ] ],
);

push( @{$FW_PARAMS_LO_DVDRW{'E'}}, [
	[ 'LITE-ON' , 'DVD+RW LDW-401S'  ],
	[ 'DVDRW'   , 'DRW-1S40'         ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'F'}}, [
	[ 'LITE-ON' , 'DVDRW LDW-411S'   ],
	[ 'DVDRW'   , 'DRW-1S41'         ],
	[ 'FREECOM_', 'DVD+/-RW4J'       ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'H'}}, [
	[ 'LITE-ON' , 'DVDRW LDW-811S'   ],
	[ 'DVDRW'   , 'DRW-1S81'         ],
	[ 'FREECOM_', 'DVD+/-RW8J'       ],
	[ 'Imation' , 'IMWDVRW8I'        ],
	[ 'Memorex' , 'DVDUR/RW 8412AJ'  ],
	[ 'TEAC'    , 'DV-W58G'          ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'g'}}, [
	[ 'LITE-ON' , 'DVDRW LDW-451S'   ],
	[ 'DVDRW'   , 'DRW-1S45'         ],
	[ 'FREECOM_', 'DVD+/-RW4J1'      ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'G'}}, [
	[ 'LITE-ON' , 'DVDRW LDW-851S'   ],
	[ 'DVDRW'   , 'DRW-1S85'         ],
	[ 'GIGABYTE', 'GO-W0804A'        ],
	[ 'WAITEC'  , 'ACTION8/1'        ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'U'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-812S'  ],
	[ 'LITE-ON' , 'DVD+RW SOHW-802S' ],
	[ 'DVDRW'   , 'DRW-2S81'         ],
	[ 'SONY'    , 'DVD RW DW-U18A'   ],
	[ 'FREECOM_', 'DVD+/-RW8J1'      ],
	[ 'GIGABYTE', 'GO-W0808A'        ],
	[ 'HIVISION', 'DRW2S81'          ],
	[ 'IOMEGA'  , 'DVDRW8440E2D-B'   ],
	[ 'Memorex' , 'DVD+/-RW True8XI' ],
	[ 'TEAC'    , 'DV-W58G-A'        ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'V'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-832S'  ],
	[ 'LITE-ON' , 'DVD+RW SOHW-822S' ],
	[ 'DVDRW'   , 'DRW-2S83'         ],
	[ 'SONY'    , 'DVD RW DRU-700A'  ],
	[ 'SONY'    , 'DVD RW DW-D18A'   ],
	[ 'HP'      , 'DVD Writer 530r'  ],
	[ 'PHILIPS' , 'ED8DVDRW'         ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'T'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-1213S' ],
	[ 'DVDRW'   , 'DRW-3S121'        ],
	[ 'SONY'    , 'DVD RW DW-U20A'   ],
	[ 'HIVISION', 'DRW3S121'         ],
	[ 'IOMEGA'  , 'DVDRW12448IND-B'  ],
	[ 'TDK'     , 'DVDRW1280B'       ],
	[ 'TEAC'    , 'DV-W512G'         ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'A'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-1613S' ],
	[ 'DVDRW'   , 'DRW-3S161'        ],
	[ 'SONY'    , 'DVD RW DW-U21A'   ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'B'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-1633S' ],
	[ 'DVDRW'   , 'DRW-3S163'        ],
	[ 'SONY'    , 'DVD RW DRU-710A'  ],
	[ 'SONY'    , 'DVD RW DW-D22A'   ],
	[ 'GIGABYTE', 'GO-W1608A'        ],
	[ 'HIVISION', 'DRW3S163'         ],
	[ 'HP'      , 'DVD Writer 630r'  ],	# Not verified
	[ 'Imation' , 'IMWDVRW16E'       ],
	[ 'Imation' , 'IMWDVRW16LI'      ],	# Not verified
	[ 'Memorex' , 'DVD+/-DLRWL1 F16' ],
	[ 'PHILIPS' , 'ED16DVDR'         ],
	[ 'TEAC'    , 'DV-W516G'         ],
	[ 'WAITEC'  , 'ACTION16/1'       ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'b'}}, $FW_PARAMS_LO_DVDRW{'B'}->[-1] );

push( @{$FW_PARAMS_LO_DVDRW{'C'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-1653S' ],
	[ 'DVDRW'   , 'DRW-3S165'        ],
	[ 'SONY'    , 'DVD RW DRU-710A'  ],	# Special case!
	[ 'SONY'    , 'DVD RW DW-D23A'   ],
	[ 'TDK'     , 'DVDRW1612DLB'     ],
	[ 'TEAC'    , 'DV-W516GA'        ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'J'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-1673S' ],
	[ 'DVDRW'   , 'DRW-3S167'        ],
	[ 'SONY'    , 'DVD RW DRU-720A'  ],
	[ 'SONY'    , 'DVD RW DW-D26A'   ],
	[ 'GIGABYTE', 'GO-W1616A'        ],
	[ 'HP'      , 'DVD Writer 635d'  ],	# Not verified
	[ 'IMATION' , 'IMWDVRW16DLE'     ],
	[ 'IMATION' , 'IMWDVRW16DLI'     ],
	[ 'Memorex' , 'DVD16+/-DL4RWlD2' ],
	[ 'TEAC'    , 'DV-W516GB'        ],
	[ 'WAITEC'  , 'ACTION164/1'      ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'K'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-1693S' ],
	[ 'DVDRW'   , 'DRW-3S169'        ],
	[ 'SONY'    , 'DVD RW DRU-800A'  ],
	[ 'SONY'    , 'DVD RW DW-Q28A'   ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'L'}}, [
	[ 'Slimtype', 'DVD+RW SDW-421S'  ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'M'}}, [
	[ 'Slimtype', 'DVDRW SDW-431S'   ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'P'}}, [
	[ 'Slimtype', 'DVDRW SOSW-852S'  ],
	[ 'SONY'    , 'DVD RW DW-D56A'   ],
	[ 'SONY'    , 'DVD+-RW DW-D56A'  ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'Q'}}, [
	[ 'Slimtype', 'DVD+RW SOSW-862S' ],
	[ 'SONY'    , 'DVD+RW DW-R56A'   ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'u'}}, [
	[ 'Slimtype', 'DVDRW SOSW-813S'  ],	# Not verified
	[ 'SONY'    , 'DVD RW DW-Q58A'   ],
] );

push( @{$FW_PARAMS_LO_DVDRW{'v'}}, [
	[ 'Slimtype', 'DVDRW SOSW-833S'  ],
	[ 'SONY'    , 'DVD RW DW-Q60A'   ],	# Not verified
] );

##
# Combos
#
%FW_PARAMS_LO_COMBO =
(
	# fw_letter => [ 'fw_family', 'fw_rs_limits'->list, 'fw_rs_defaults'->list, 'fw_idlist' ]
	#
	'~' => [ 'DVD-ROM/CD-Writer', [  0,  0,  0,  0,  0 ], [  0, 0, 0, 0, 0 ], [ ] ],

	'K' => [ 'LTC-48161H',        [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 4 ] ],
	'N' => [ 'SOHC-5232K',        [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 4 ] ],
	'O' => [ 'SOHC-4832K',        [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 4 ] ],
	'L' => [ 'SOHC-5235K',        [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 4 ] ],
	'M' => [ 'SOHC-4835K',        [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 4 ] ],
	'R' => [ 'SOHC-5236K',        [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 4 ] ],
	'r' => [ 'SOHC-5236V',        [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 4 ] ],
);

push( @{$FW_PARAMS_LO_COMBO{'K'}}, [
	[ 'LITE-ON' , 'COMBO LTC-48161H' ],
	[ 'COMBO'   , 'COB-1H4816'       ],
	[ 'SONY'    , 'CD-RW  CRX300E'   ],
	[ 'COMBO'   , '48X24-L0'         ],	# Not verified
	[ 'Memorex' , '48MAX 244816AJ'   ],
	[ 'TDK'     , 'CDRW482448BC'     ],
	[ 'TEAC'    , 'DW-548D'          ],
] );

push( @{$FW_PARAMS_LO_COMBO{'N'}}, [
	[ 'LITE-ON' , 'COMBO SOHC-5232K' ],
	[ 'COMBO'   , 'COB-2K5216'       ],
	[ 'SONY'    , 'CD-RW  CRX320E'   ],
	[ 'GIGABYTE', 'GO-B5232A'        ],	# Not verified
	[ 'HIVISION', 'COB2K5216'        ],
	[ 'Memorex' , '52MAX 325216AJ'   ],	# Not verified
	[ 'TDK'     , 'CDRW523252BC'     ],
	[ 'TEAC'    , 'DW-552G'          ],	# Not verified
] );

push( @{$FW_PARAMS_LO_COMBO{'O'}}, [
	[ 'LITE-ON' , 'COMBO SOHC-4832K' ],
] );

push( @{$FW_PARAMS_LO_COMBO{'L'}}, [
	[ 'LITE-ON' , 'COMBO SOHC-5235K' ],
	[ 'SONY'    , 'CD-RW  CRX320ED'  ],	# Not verified
] );

push( @{$FW_PARAMS_LO_COMBO{'M'}}, [
	[ 'LITE-ON' , 'COMBO SOHC-4835K' ],	# Not verified
#	[ 'SONY'    , 'CDRW/DVD CRX330E' ],	# Omitted for consistency
] );

push( @{$FW_PARAMS_LO_COMBO{'R'}}, [
	[ 'LITE-ON' , 'COMBO SOHC-5236K' ],
	[ 'COMBO'   , 'COB-6K5216'       ],
	[ 'SONY'    , 'CD-RW  CRX320EE'  ],	# Not verified
] );

push( @{$FW_PARAMS_LO_COMBO{'r'}}, [
	[ 'LITE-ON' , 'COMBO SOHC-5236V' ],
] );

##
# DVD-ROMs
#
%FW_PARAMS_LO_DVDROM =
(
	# fw_letter => [ 'fw_family', 'fw_rs_limits'->list, 'fw_rs_defaults'->list, 'fw_idlist' ]
	#
	'~' => [ 'DVD-ROM Drive',       [  0,  0,  0,  0,  0 ], [  0, 0, 0, 0, 0 ], [ ] ],

	'I' => [ 'LTD-122',             [  0,  0,  0,  0,  0 ], [  0, 0, 0, 0, 0 ] ],
	'G' => [ 'LTD-163 or LTD-163D', [ 16, 10, 16, 16, 10 ], [ 16, 8, 8, 8, 8 ] ],
	'C' => [ 'LTD-165H',            [ 16, 10, 16, 16, 10 ], [ 16, 8, 8, 8, 8 ] ],
	'D' => [ 'LTD-166S',            [ 16, 10, 16, 16, 10 ], [ 16, 8, 8, 8, 8 ] ],
	'9' => [ 'SOHD-167T',           [ 16, 10, 16, 16, 10 ], [ 16, 8, 8, 8, 8 ] ],
	'F' => [ 'SOHD-16P9S',          [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 8 ] ],
);

push( @{$FW_PARAMS_LO_DVDROM{'I'}}, [
	[ 'LITEON'  , 'DVD-ROM LTD122'   ],
	[ 'SONY'    , 'DVD-ROM DDU1211'  ],	# Not verified
	[ 'COMPAQ'  , 'DVD-ROM LTD122'   ],	# Not verified
	[ 'CREATIVE', 'DVD-ROM DVD1243E' ],
] );

push( @{$FW_PARAMS_LO_DVDROM{'G'}}, [
	[ 'LITEON'  , 'DVD-ROM LTD163'   ],
	[ 'JLMS'    , 'XJ-HD163'         ],
	[ 'DVD-ROM' , 'DVD-16X3H'        ],
	[ 'SONY'    , 'DVD-ROM DDU1611'  ],
	[ 'COMPAQ'  , 'DVD-ROM LTD163'   ],
	[ 'CREATIVE', 'DVD-ROM DVD1640E' ],	# Not verified
	[ 'Maxell'  , 'MDVD-ROM16'       ],
	[ 'Memorex' , 'DVD-MAXX 1648 AJ' ],
	[ '_NEC'    , 'DV-5800B'         ],	# Not verified
	[ 'LITEON'  , 'DVD-ROM LTD163D'  ],
	[ 'JLMS'    , 'XJ-HD163D'        ],
] );

push( @{$FW_PARAMS_LO_DVDROM{'C'}}, [
	[ 'LITEON'  , 'DVD-ROM LTD-165H' ],
	[ 'JLMS'    , 'XJ-HD165H'        ],
	[ 'DVD-ROM' , 'DVD-16X5H'        ],
] );

push( @{$FW_PARAMS_LO_DVDROM{'D'}}, [
	[ 'LITEON'  , 'DVD-ROM LTD-166S' ],
	[ 'JLMS'    , 'DVD-ROM LTD-166S' ],
	[ 'JLMS'    , 'XJ-HD166S'        ],
	[ 'DVD-ROM' , 'DVD-16X6S'        ],
	[ 'SONY'    , 'DVD-ROM DDU1612'  ],
	[ 'AOPEN'   , 'DVD1648/LKY'      ],
	[ 'GIGABYTE', 'GO-D1600A'        ],	# Not verified
	[ 'LEMEL'   , 'LDV-1648L'        ],	# Not verified
	[ 'Memorex' , '16X DVD-ROM AJiA' ],
	[ '_NEC'    , 'DV-5800C'         ],	# Not verified
] );

push( @{$FW_PARAMS_LO_DVDROM{'9'}}, [
	[ 'LITE-ON' , 'DVD SOHD-167T'    ],
	[ 'DVD-ROM' , 'DVD-7T16'         ],
	[ 'SONY'    , 'DVD-ROM DDU1613'  ],
	[ 'GIGABYTE', 'GO-D1600C'        ],	# Not verified
	[ 'HIVISION', 'DVD7T16'          ],
] );

push( @{$FW_PARAMS_LO_DVDROM{'F'}}, [
	[ 'LITE-ON' , 'DVD SOHD-16P9S'   ],
	[ 'DVD-ROM' , 'DVD-9S16P'        ],
	[ 'SONY'    , 'DVD-ROM DDU1615'  ],
	[ '_NEC'    , 'DV-5800D'         ],
	[ 'TEAC'    , 'DV-516G'          ],
] );

1;
