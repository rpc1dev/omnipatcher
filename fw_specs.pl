##
# OmniPatcher for LiteOn DVD-Writers
# Firmware : Specifications/parameters table
#
# Modified: 2005/06/27, C64K
#

%FW_PARAMS =
(
	# fw_letter => [ 'fw_gen', 'fw_family', 'fw_ebank', 'fw_rbank', 'media_pbank', 'media_dbank', 'media_limits'->[ pr, prw, pr9, dr, drw, dr9 ], 'media_count_expected', 'fw_rs_limits'->list, 'fw_rs_defaults'->list, 'fw_idlist' ]
	#
	# Note that the speed limits encoded here are done
	# so in the order indicated in media_const.pl.
	#
	'~' => [ 0x000, 'Unknown',        0x000000, 0x000000, 0x000000, 0x000000, [  0, 0, 0,  0, 0, 0 ],   0, [  0,  0,  0,  0,  0 ], [  0, 0, 0, 0, 0 ] ],

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
	'C' => [ 0x032, 'SOHW-1653S',     0x090000, 0x020000, 0x0E0000, 0x090000, [ 16, 4, 4, 12, 4, 0 ], 220, [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 6 ] ],
	'J' => [ 0x033, 'SOHW-1673S',     0x0A0000, 0x020000, 0x0B0000, 0x100000, [ 16, 8, 4, 16, 6, 0 ], 250, [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 6 ] ],
	'K' => [ 0x033, 'SOHW-1693S',     0x0A0000, 0x020000, 0x0B0000, 0x100000, [ 16, 8, 4, 16, 6, 4 ], 250, [ 16, 16, 16, 16, 12 ], [ 16, 8, 8, 8, 6 ] ],

	'L' => [ 0x111, 'SDW-421S',       0x000000, 0x030000, 0x000000, 0x000000, [  4, 4, 0,  0, 0, 0 ],   0, [  8,  8,  8,  8,  8 ], [  8, 6, 6, 6, 4 ] ],
	'M' => [ 0x111, 'SDW-431S',       0x0C0000, 0x040000, 0x0A0000, 0x0D0000, [  4, 4, 0,  4, 2, 0 ],  90, [  8,  8,  8,  8,  8 ], [  8, 6, 6, 6, 4 ] ],
	'P' => [ 0x121, 'SOSW-852S',      0x0C0000, 0x040000, 0x0A0000, 0x0D0000, [  8, 4, 2,  8, 4, 0 ], 140, [  8,  8,  8,  8,  8 ], [  8, 6, 8, 6, 4 ] ],
	'Q' => [ 0x121, 'SOSW-862S',      0x0C0000, 0x040000, 0x0A0000, 0x0D0000, [  8, 4, 2,  0, 0, 0 ], 140, [  8,  8,  8,  8,  8 ], [  8, 6, 8, 6, 4 ] ],
);

push( @{$FW_PARAMS{'E'}}, [
	[ 'LITE-ON' , 'DVD+RW LDW-401S'  ],
	[ 'DVDRW'   , 'DRW-1S40'         ],
] );

push( @{$FW_PARAMS{'F'}}, [
	[ 'LITE-ON' , 'DVDRW LDW-411S'   ],
	[ 'DVDRW'   , 'DRW-1S41'         ],
	[ 'FREECOM_', 'DVD+/-RW4J'       ],
] );

push( @{$FW_PARAMS{'H'}}, [
	[ 'LITE-ON' , 'DVDRW LDW-811S'   ],
	[ 'DVDRW'   , 'DRW-1S81'         ],
	[ 'FREECOM_', 'DVD+/-RW8J'       ],
	[ 'Imation' , 'IMWDVRW8I'        ],
	[ 'Memorex' , 'DVDUR/RW 8412AJ'  ],
	[ 'TEAC'    , 'DV-W58G'          ],
] );

push( @{$FW_PARAMS{'g'}}, [
	[ 'LITE-ON' , 'DVDRW LDW-451S'   ],
	[ 'DVDRW'   , 'DRW-1S45'         ],
	[ 'FREECOM_', 'DVD+/-RW4J1'      ],
] );

push( @{$FW_PARAMS{'G'}}, [
	[ 'LITE-ON' , 'DVDRW LDW-851S'   ],
	[ 'DVDRW'   , 'DRW-1S85'         ],
	[ 'GIGABYTE', 'GO-W0804A'        ],
	[ 'WAITEC'  , 'ACTION8/1'        ],
] );

push( @{$FW_PARAMS{'U'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-812S'  ],
	[ 'LITE-ON' , 'DVD+RW SOHW-802S' ],
	[ 'DVDRW'   , 'DRW-2S81'         ],
	[ 'SONY'    , 'DVD RW DW-U18A'   ],
	[ 'FREECOM_', 'DVD+/-RW8J1'      ],
	[ 'GIGABYTE', 'GO-W0808A'        ],
	[ 'HIVISION', 'DRW2S81'          ],
	[ 'Memorex' , 'DVD+/-RW True8XI' ],
	[ 'TEAC'    , 'DV-W58G-A'        ],
] );

push( @{$FW_PARAMS{'V'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-832S'  ],
	[ 'LITE-ON' , 'DVD+RW SOHW-822S' ],
	[ 'DVDRW'   , 'DRW-2S83'         ],
	[ 'SONY'    , 'DVD RW DRU-700A'  ],
	[ 'SONY'    , 'DVD RW DW-D18A'   ],
	[ 'HP'      , 'DVD Writer 530r'  ],
	[ 'PHILIPS' , 'ED8DVDRW'         ],
] );

push( @{$FW_PARAMS{'T'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-1213S' ],
	[ 'DVDRW'   , 'DRW-3S121'        ],
	[ 'SONY'    , 'DVD RW DW-U20A'   ],
	[ 'HIVISION', 'DRW3S121'         ],
	[ 'IOMEGA'  , 'DVDRW12448IND-B'  ],
	[ 'TDK'     , 'DVDRW1280B'       ],
	[ 'TEAC'    , 'DV-W512G'         ],
] );

push( @{$FW_PARAMS{'A'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-1613S' ],
	[ 'DVDRW'   , 'DRW-3S161'        ],
	[ 'SONY'    , 'DVD RW DW-U21A'   ],
] );

push( @{$FW_PARAMS{'B'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-1633S' ],
	[ 'DVDRW'   , 'DRW-3S163'        ],
	[ 'SONY'    , 'DVD RW DRU-710A'  ],
	[ 'SONY'    , 'DVD RW DW-D22A'   ],
	[ 'GIGABYTE', 'GO-W1608A'        ],
	[ 'HIVISION', 'DRW3S163'         ],
	[ 'HP'      , 'DVD Writer 630r'  ],	# Not verified
	[ 'IMATION' , 'IMWDVRW16LI'      ],	# Not verified
	[ 'Memorex' , 'DVD+/-DLRWL1 F16' ],
	[ 'PHILIPS' , 'ED16DVDR'         ],
	[ 'TEAC'    , 'DV-W516G'         ],
	[ 'WAITEC'  , 'ACTION16/1'       ],
] );

push( @{$FW_PARAMS{'C'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-1653S' ],
	[ 'DVDRW'   , 'DRW-3S165'        ],
	[ 'SONY'    , 'DVD RW DRU-710A'  ],
	[ 'SONY'    , 'DVD RW DW-D23A'   ],
	[ 'TDK'     , 'DVDRW1612DLB'     ],
	[ 'TEAC'    , 'DV-W516GA'        ],
] );

push( @{$FW_PARAMS{'J'}}, [
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

push( @{$FW_PARAMS{'K'}}, [
	[ 'LITE-ON' , 'DVDRW SOHW-1693S' ],
	[ 'DVDRW'   , 'DRW-3S169'        ],
	[ 'SONY'    , 'DVD RW DRU-800A'  ],
	[ 'SONY'    , 'DVD RW DW-Q28A'   ],
] );

push( @{$FW_PARAMS{'L'}}, [
	[ 'Slimtype', 'DVD+RW SDW-421S'  ],
] );

push( @{$FW_PARAMS{'M'}}, [
	[ 'Slimtype', 'DVDRW SDW-431S'   ],
] );

push( @{$FW_PARAMS{'P'}}, [
	[ 'Slimtype', 'DVDRW SOSW-852S'  ],
	[ 'SONY'    , 'DVD RW DW-D56A'   ],
	[ 'SONY'    , 'DVD+-RW DW-D56A'  ],
] );

push( @{$FW_PARAMS{'Q'}}, [
	[ 'Slimtype', 'DVD+RW SOSW-862S' ],
	[ 'SONY'    , 'DVD+RW DW-R56A'   ],
] );

1;
