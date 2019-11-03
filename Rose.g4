grammar Rose;

//Parser Rules

program : PROCEDURE IDENTIFIER IS DECLARE 
		{System.out.println("\t.data");} variables 
		BEGIN {System.out.println("\t.text");} 
		{System.out.println("main:");} sRtn = statements[0, 1] END SEMICOLON;

variables : variables_plus ;
variables_plus : variable variables_plus | ;
variable : IDENTIFIER {System.out.print($IDENTIFIER.text);}
		COLON INTEGER {if ($INTEGER.text.compareTo( "integer") == 0){ System.out.println(":      .word 0"); }}
		SEMICOLON ; 

statements[int reg, int label] returns[int rReg, int rLabel] : spRtn = statements_plus[$reg, $label] {$rReg = $spRtn.rReg; $rLabel = $spRtn.rLabel;};
statements_plus[int reg, int label] returns[int rReg, int rLabel]: sRtn = statement[$reg, $label] spRtn = statements_plus[$sRtn.rReg, $sRtn.rLabel] {$rReg= $spRtn.rReg; $rLabel = $spRtn.rLabel;}
		| {$rReg = $reg; $rLabel = $label;};
statement[int reg, int label] returns[int rReg, int rLabel] : 
		aRtn = assignment_statement[$reg] {$rReg = $aRtn.rReg; $rLabel = $label;}
		| ifRtn = if_statement[$reg, $label] {$rReg = $ifRtn.rReg; $rLabel = $ifRtn.rLabel;}
		| fsRtn = for_statement[$reg, $label] {$rReg = $fsRtn.rReg; $rLabel = $fsRtn.rLabel;}
		| exit_statement {$rReg = $reg; $rLabel = $label;}
		| rsRtn = read_statement[$reg] {$rReg = $rsRtn.rReg; $rLabel = $label;} 
		| wsRtn = write_statement[$reg] {$rReg = $wsRtn.rReg; $rLabel = $label;};


assignment_statement[int reg] returns[int rReg]: IDENTIFIER ASSIGN aeRet = arith_expression[$reg] SEMICOLON {System.out.println("\tla $" + "t" + $aeRet.rReg + ", " + $IDENTIFIER.text);
																											 System.out.println("\tsw $" + "t" + $aeRet.rPlace + ", 0($" + "t" + $aeRet.rReg + ")");	
																											 $rReg = $aeRet.rReg - 1; };

if_statement[int reg, int label] returns[int rReg, int rLabel]: IF {System.out.println("#if");} beRtn = bool_expression[$rReg, $label+3, $label, $label+1]
								   								THEN {System.out.println("L" + $label + ": #then");}
								   								sRtn = statements[$beRtn.rReg, $beRtn.rLabel] 
								   								ieesRtn = if_end_else_statement[$sRtn.rReg, $sRtn.rLabel, $label+1, $label+2] {$rReg = $ieesRtn.rReg; $rLabel = $ieesRtn.rLabel; };
if_end_else_statement[int reg, int label, int fLabel, int nLabel] returns[int rReg, int rLabel]: END IF SEMICOLON {System.out.println("L" + $fLabel + ": #end if"); $rReg = $reg; $rLabel = $label-1;}
																				   			   | ELSE {System.out.println("\tb L" + $nLabel);
																					   	   		 System.out.println("L" + $fLabel + ": #else");}
																				   				 sRtn = statements[$reg, $label] END IF SEMICOLON {System.out.println("L" + $nLabel + ": #end if");
																					 			 $rReg = $sRtn.rReg; $rLabel = $sRtn.rLabel;} ;

for_statement[int reg, int label] returns[int rReg, int rLabel]: FOR IDENTIFIER IN {System.out.println("\t#" + $IDENTIFIER.text + " = 1;");} aeRtn1 = arith_expression[$reg] 
																	{System.out.println("\tla $" + "t" + $aeRtn1.rReg + ", " + $IDENTIFIER.text);
																	 System.out.println("\tsw $" + "t" + $aeRtn1.rPlace + ", 0($" + "t" + $aeRtn1.rReg + ")");
																	 System.out.println("L" + $label + ": #for begin");}
																 TO aeRtn2 = arith_expression[$aeRtn1.rReg-1]
																	{System.out.println("\tla $" + "t" + $aeRtn2.rReg + ", " + $IDENTIFIER.text);
																	 System.out.println("\tlw $" + "t" + $aeRtn2.rReg + ", 0($" + "t" + $aeRtn2.rReg + ")");
																	 System.out.println("\tble $" + "t" + $aeRtn2.rReg + ", $" + "t" + $aeRtn2.rPlace + ", L" + ($label+1));
																	 System.out.println("\tb L" + ($label+2));
																 	 System.out.println("L" + ($label+1) + ": #for statement(true)");}
																 LOOP sRtn = statements[$aeRtn2.rReg-1, $label+3] 
																 {System.out.println("\t#" + $IDENTIFIER.text + "++");
																  System.out.println("\tla $" + "t" + $sRtn.rReg + ", " + $IDENTIFIER.text);
																  System.out.println("\tlw $" + "t" + $sRtn.rReg + ", 0($" + "t" + $sRtn.rReg + ")");
																  System.out.println("\tli $" + "t" + ($sRtn.rReg+1) + ", 1");
																  System.out.println("\tadd $" + "t" + $sRtn.rReg + ", $" + "t" + $sRtn.rReg + ", $" + "t" + ($sRtn.rReg+1));
																  System.out.println("\tla $" + "t" + ($sRtn.rReg+1) + ", " + $IDENTIFIER.text);
																  System.out.println("\tsw $" + "t" + $sRtn.rReg + ", 0($" + "t" + ($sRtn.rReg+1) + ")");}
																 END LOOP SEMICOLON {System.out.println("\tb L" + $label);
																	 				 System.out.println("L" + ($label+2) + ": #end for(false)");
																 					 $rReg = $sRtn.rReg; $rLabel = $sRtn.rLabel;} ;

exit_statement : EXIT SEMICOLON {System.out.println("\tli $" + "v0" + ", 10");
					 			 System.out.println("\tsyscall"); };

read_statement[int reg] returns[int rReg] : READ IDENTIFIER SEMICOLON { System.out.println("\tli $" + "v0" + ", 5");
																		System.out.println("\tsyscall");
																		System.out.println("\tla $" + "t" + reg + ", " + $IDENTIFIER.text);
																		System.out.println("\tsw $" + "v0" + ", 0($" + "t" + reg + ")");
																		$rReg = $reg; };
write_statement[int reg] returns[int rReg] : WRITE aeRtn = arith_expression[$reg] SEMICOLON {System.out.println("\tmove $" + "a0, $" + "t" + $aeRtn.rPlace);
																		   					 System.out.println("\tli $" + "v0" + ", 1");
																		   					 System.out.println("\tsyscall"); 
																							 $rReg = $aeRtn.rReg-1; };

bool_expression[int reg, int label, int tLabel, int fLabel] returns[int rReg, int rLabel] : btRtn = bool_term[$reg, $label, $tLabel, $fLabel] 
																						 bepRtn = bool_expression_plus[$btRtn.rReg, $btRtn.rLabel, $tLabel, $fLabel, $btRtn.rPoint]
																						 {$rReg = $bepRtn.rReg; $rLabel = $bepRtn.rLabel;};
bool_expression_plus[int reg, int label, int tLabel, int fLabel, int point] returns[int rReg, int rLabel]: OR {if($point == 0){ 
																												System.out.println(", L" + $tLabel); 
																												System.out.println("\tb L" + $label);
																												System.out.println("L" + $label + ":"); }
																											else{
																												System.out.println(", L" + $label); 
																												System.out.println("\tb L" + $tLabel);
																												System.out.println("L" + $label + ":"); }}
																										btRtn = bool_term[$reg, $label+1, $tLabel, $fLabel] 
																										bepRtn = bool_expression_plus[$btRtn.rReg, $btRtn.rLabel, $tLabel, $fLabel, $btRtn.rPoint] 
																										{$rReg = $bepRtn.rReg; $rLabel = $bepRtn.rLabel;}
																										| {if($point == 0){
																												System.out.println(", L" + $tLabel);
																										   		System.out.println("\tb L" + $fLabel); }
																											else{
																												System.out.println(", L" + $tLabel);
																										   		System.out.println("\tb L" + $fLabel); } 
																											$rReg = $reg; $rLabel = $label;} ;
																												

bool_term[int reg, int label, int tLabel, int fLabel] returns[int rReg, int rLabel, int rPoint] : bfRtn = bool_factor[$reg] 
																							   btpRtn = bool_term_plus[$bfRtn.rReg, $label, $tLabel, $fLabel, $bfRtn.rPoint] 
																							   {$rReg = $btpRtn.rReg; $rLabel = $btpRtn.rLabel; $rPoint = $btpRtn.rPoint;} ;
bool_term_plus[int reg, int label, int tLabel, int fLabel, int point] returns[int rReg, int rLabel, int rPoint]: AND {if($point == 0){
																													System.out.println(", L" + $label); 
																													System.out.println("\tb L" + $fLabel);
																													System.out.println("L" + $label + ":");}
																												  else{
																													System.out.println(", L" + $fLabel); 
																													System.out.println("\tb L" + $label);
																													System.out.println("L" + $label + ":");
																												  }}
																												  bfRtn = bool_factor[$reg] 
																												  btpRtn = bool_term_plus[$bfRtn.rReg, $label+1, $tLabel, $fLabel, $bfRtn.rPoint]
																											  {$rReg = $btpRtn.rReg; $rLabel = $btpRtn.rLabel; $rPoint = $btpRtn.rPoint;}
																						  					| {$rReg = $reg; $rLabel = $label; $rPoint = $point;} ;

bool_factor[int reg] returns[int rReg, int rPoint]: POINT bpRtn = bool_primary[$reg] {$rReg = $bpRtn.rReg; $rPoint = 1;}
																				  | bpRtn = bool_primary[$reg] {$rReg = $bpRtn.rReg; $rPoint = 0;} ;
bool_primary[int reg] returns[int rReg] : ae1Rtn = arith_expression[$reg] roRtn = relation_op ae2Rtn = arith_expression[$ae1Rtn.rReg] 
										  {System.out.print("\t" + $roRtn.rIns + " $" + "t" + $ae1Rtn.rPlace + ", $" + "t" + $ae2Rtn.rPlace);
										   $rReg = $ae2Rtn.rReg-2;} ;
relation_op returns[String rIns]: EQUAL {$rIns = "beq";} | NOT_EQUAL {$rIns = "bne";} | GREATER {$rIns = "bgt";}
								| GREATER_EQUAL {$rIns = "bge";} | LESS {$rIns = "blt";} | LESS_EQUAL {$rIns = "ble";} ;

arith_expression[int reg] returns[int rReg, int rPlace] : atRtn = arith_term[$reg] aepRtn = arith_expression_plus[$atRtn.rReg, $atRtn.rPlace] 
														{$rReg = $aepRtn.rReg; $rPlace = $aepRtn.rPlace; };
arith_expression_plus[int reg, int place] returns[int rReg, int rPlace] : ADD atRtn = arith_term[$reg] {System.out.println("\tadd $" + "t" + $place + ", $" + "t" + $place + ", $"+ "t" + $atRtn.rPlace);} 
																			aepRtn = arith_expression_plus[$atRtn.rReg - 1, $place]
																			{$rReg = $aepRtn.rReg; $rPlace = $aepRtn.rPlace; }
																		| SUB atRtn = arith_term[$reg] {System.out.println("\tsub $" + "t" + $place + ", $" + "t" + $place + ", $"+ "t" + $atRtn.rPlace);} 
																			aepRtn = arith_expression_plus[$atRtn.rReg - 1, $place]
																			{$rReg = $aepRtn.rReg; $rPlace = $aepRtn.rPlace; }
																		| {$rReg = $reg; $rPlace = $place; };

arith_term[int reg] returns[int rReg, int rPlace] : afRtn = arith_factor[$reg] atpRtn = arith_term_plus[$afRtn.rReg, $afRtn.rPlace] {$rReg = $atpRtn.rReg; $rPlace = $atpRtn.rPlace; };
arith_term_plus[int reg, int place] returns[int rReg, int rPlace] : MUL afRtn = arith_factor[$reg] {System.out.println("\tmul $" + "t" + $place + ", $" + "t" + $place + ", $" + "t" + $afRtn.rPlace); }
																		atRtn = arith_term_plus[$afRtn.rReg-1, $place]
																		{$rReg = $atRtn.rReg; $rPlace = $atRtn.rPlace; }
																| DIVIDE afRtn = arith_factor[$reg] {System.out.println("\tdiv $" + "t" + $place + ", $" + "t" + $place + ", $" + "t" + $afRtn.rPlace); }
																		atRtn = arith_term_plus[$afRtn.rReg-1, $place]
																		{$rReg = $atRtn.rReg; $rPlace = $atRtn.rPlace; }
																| MOD afRtn = arith_factor[$reg] {System.out.println("rem $" + "t" + $place + ", $" + "t" + $place + ", $" + "t" + $afRtn.rPlace); }
																		atRtn = arith_term_plus[$afRtn.rReg-1, $place]
																		{$rReg = $atRtn.rReg; $rPlace = $atRtn.rPlace; }
																| {$rReg = $reg; $rPlace = $place; };

arith_factor[int reg] returns[int rReg, int rPlace] : SUB apRtn = arith_primary[$reg] {System.out.println("\tneg $" + "t" + $apRtn.rPlace + ", $" + "t" + $apRtn.rPlace);
																						$rReg = $apRtn.rReg; $rPlace = $apRtn.rPlace; }
													| apRtn = arith_primary[$reg] {$rReg = $apRtn.rReg; $rPlace = $apRtn.rPlace; };

arith_primary[int reg] returns[int rReg, int rPlace] : CONST {System.out.println("\tli $" + "t" + $reg + ", " + $CONST.text);
															$rPlace = $reg;
															$rReg = $reg + 1; }
		| IDENTIFIER {System.out.println("\tla $" + "t" + $reg + ", " + $IDENTIFIER.text);
						System.out.println("\tlw $" + "t" + $reg + ", 0($" + "t" + $reg + ")" );
						$rPlace = $reg;
						$rReg = $reg + 1; }
		| OPEN_PAREN aeRtn = arith_expression[$reg] CLOASE_PAREN {$rReg = $aeRtn.rReg; $rPlace = $aeRtn.rPlace; };



//Lexer Rules

IDENTIFIER: ([A-Z]|'_') ([A-Z0-9]|'_')*;

BEGIN: 'begin';
DECLARE: 'declare';
ELSE: 'else';
END: 'end';
EXIT: 'exit';
FOR: 'for';
IF: 'if';
IN: 'in';
INTEGER: 'integer';
IS: 'is';
LOOP: 'loop';
PROCEDURE: 'procedure';
READ: 'read';
THEN: 'then';
WRITE: 'write';

CONST: [1-9] ([0-9])* | [0-9];

COLON: ':';
TO: '..';
SEMICOLON: ';';
ADD: '+';
SUB: '-';
MUL: '*';
DIVIDE: '/';
MOD: '%';
EQUAL: '=';
NOT_EQUAL: '<>';
GREATER: '>';
GREATER_EQUAL: '>=';
LESS: '<';
LESS_EQUAL: '<=';
AND: '&&';
OR: '||';
POINT: '!';
ASSIGN: ':=';
OPEN_PAREN: '(';
CLOASE_PAREN: ')';

SEPARATE: (' '|'\t'|'\r'|'\n')+ {skip();};
COMMENT: '//' (.)*? '\n' {skip();};
