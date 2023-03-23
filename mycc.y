/* TODO: TO BE COMPLETED */

%{

#include "lex.yy.h"
#include "global.h"
static struct ClassFile cf;

%}

/* declares YYSTYPE type of attribute for all tokens and nonterminals */
%union
{ Symbol *sym;  /* token value yylval.sym is the symbol table entry of an ID */
  unsigned num; /* token value yylval.num is the value of an int constant */
  float flt;    /* token value yylval.flt is the value of a float constant */
  char *str;    /* token value yylval.str is the value of a string constant */
  unsigned loc; /* location of instruction to backpatch */
}

/* Declare ID token and its attribute type 'sym' */
%token <sym> ID

/* Declare INT tokens (8 bit, 16 bit, 32 bit) and their attribute type 'num' */
%token <num> INT8 INT16 INT32

/* Declare FLT token (not used in this assignment) */
%token <flt> FLT

/* Declare STR token (not used in this assignment) */
%token <str> STR

/* Declare tokens for keywords */
/* Note: install_id() returns Symbol* for both keywords and identifiers */
%token <sym> BREAK DO ELSE FOR IF RETURN WHILE

/* Declare operator tokens */
/* TODO: TO BE COMPLETED WITH ASSOCIATIVITY AND PRECEDENCE DECLARATIONS */

/*prec 14*/
%right AA XA OA
%right RA LA
%right TA DA MA
%right PA NA
%right '='

/* prec12 */
%left OR

/* prec11 */
%left AN

/* prec10 */
%left '|'

/* prec9 */
%left '^'

/* prec8 */ 
%left '&'

/* prec7 */
%left EQ NE

/* prec6 */
%left '<' LE  '>' GE

/* prec5 */
%left LS RS

/* prec4 */
%right '+' '-'

/* prec3 */
%left '*' '/' '%'

/* prec2 */
%right '!' '~'

/* prec1 */
%left AR
%left PP NN


  

/* Declare attribute types for marker nonterminals, such as L M and N */
/* TODO: TO BE COMPLETED WITH ADDITIONAL NONMARKERS AS NECESSARY */
%type <loc> L M N P

%%

stmts   : stmts stmt
        | /* empty */
        ;

stmt    : ';'
        | expr ';'      { emit(pop); /* do not leave a value on the stack */ }
        | IF '(' expr ')' M stmt
						{
							backpatch($5, pc - $5);
						}
        | IF '(' expr ')' M stmt  ELSE  N L stmt L 
                        			{ 
							backpatch($5, $9 - $5);
							backpatch($8, $11 - $8);
						}
        | WHILE '(' L expr ')' M stmt N
                        			{ 
							backpatch($6, pc - $6);
							backpatch($8, $3 - $8);
						}
        | DO L stmt WHILE '(' expr ')' M N L';'
                       				{ 
							backpatch($8, $10 - $8);
							backpatch($9, $2 - $9);
							 
						}
        | FOR '(' expr  P ';' L expr M N ';' L expr P N ')' L stmt N
                        			{ 
						backpatch($8, pc-$8);
                            			backpatch($9, $16-$9);
                            			backpatch($14, $6-$14);
                            			backpatch($18, $11-$18);
						}
        | RETURN expr ';'
                        { emit(istore_2); /* return val goes in local var 2 */ }
        | BREAK ';'
                        { /* TODO: BONUS!!! */ error("break not implemented"); }
        | '{' stmts '}'
        | error ';'     { yyerrok; }
        ;

expr    : ID   '=' expr { emit(dup); emit2(istore, $1->localvar); }
        | ID   PA  expr { emit2(iload , $1->localvar); emit(iadd); emit(dup); emit2(istore, $1->localvar);}
        | ID   NA  expr { emit2(iload , $1->localvar); emit(swap); emit(isub); emit(dup); emit2(istore, $1->localvar);}
        | ID   TA  expr { emit2(iload , $1->localvar); emit(imul); emit(dup); emit2(istore, $1->localvar);}
        | ID   DA  expr { emit2(iload , $1->localvar); emit(swap); emit(idiv); emit(dup); emit2(istore, $1->localvar);}
        | ID   MA  expr { emit2(iload , $1->localvar); emit(swap); emit(irem); emit(dup); emit2(istore, $1->localvar);}
        | ID   AA  expr { emit2(iload , $1->localvar); emit(iand); emit(dup); emit2(istore, $1->localvar);} 
        | ID   XA  expr { emit2(iload , $1->localvar); emit(ixor); emit(dup); emit2(istore, $1->localvar);} 
        | ID   OA  expr { emit2(iload , $1->localvar); emit(ior);  emit(dup); emit2(istore, $1->localvar);} 
        | ID   LA  expr { emit2(iload , $1->localvar); emit(swap); emit(ishl); emit(dup); emit2(istore, $1->localvar);} 
        | ID   RA  expr { emit2(iload , $1->localvar); emit(swap); emit(ishr); emit(dup); emit2(istore, $1->localvar);} 
        | expr OR  expr { emit(ior); }
        | expr AN  expr { emit(iand);}
        | expr '|' expr { emit(ior); }
        | expr '^' expr { emit(ixor);}
        | expr '&' expr { emit(iand);}
        | expr EQ  expr { 
							int a = pc;
							emit3(if_icmpeq, 0);		// If values are equal, go to emit 1
								emit(iconst_0);			// If values aren't equal, emit 0
								int b = pc;
								emit3(goto_, 0);
							backpatch(a, pc - a);
								emit(iconst_1);
							backpatch(b, pc - b);
						}
        | expr NE  expr { 
							int a = pc;
							emit3(if_icmpne, 0);		// If values are not equal, go to emit 1
								emit(iconst_0);			// If values are equal, emit 0
								int b = pc;
								emit3(goto_, 0);
							backpatch(a, pc - a);
								emit(iconst_1);
							backpatch(b, pc - b);
						}
        | expr '<' expr { 
							int a = pc;
							emit3(if_icmplt, 0);		// If left value is less than right value, go to emit 1
								emit(iconst_0);			// Else, emit 0
								int b = pc;
								emit3(goto_, 0);
							backpatch(a, pc - a);
								emit(iconst_1);
							backpatch(b, pc - b);
						}
        | expr '>' expr { 
							int a = pc;
							emit3(if_icmpgt, 0);		// If left value is greater than right value, go to emit 1
								emit(iconst_0);			// Else, emit 0
								int b = pc;
								emit3(goto_, 0);
							backpatch(a, pc - a);
								emit(iconst_1);
							backpatch(b, pc - b);
						}
        | expr LE  expr { 
							int a = pc;
							emit3(if_icmple, 0);		// If left value is less than or equal to right value, go to emit 1
								emit(iconst_0);			// Else, emit 0
								int b = pc;
								emit3(goto_, 0);
							backpatch(a, pc - a);
								emit(iconst_1);
							backpatch(b, pc - b);
						}
        | expr GE  expr { 
							int a = pc;
							emit3(if_icmpge, 0);		// If left value is greater than or equal to right value, go to emit 1
								emit(iconst_0);			// Else, emit 0
								int b = pc;
								emit3(goto_, 0);
							backpatch(a, pc - a);
								emit(iconst_1);
							backpatch(b, pc - b);
						}
        | expr LS  expr { emit(ishl); }
        | expr RS  expr { emit(ishr); }
        | expr '+' expr { emit(iadd); }
        | expr '-' expr { emit(isub); }
        | expr '*' expr { emit(imul); }
        | expr '/' expr { emit(idiv); }
        | expr '%' expr { emit(irem); }


        | '!' expr      { emit(ineg); emit(iconst_1); emit(iadd); }
        | '~' expr      { emit(ineg); emit(iconst_1); emit(iadd); }
        | '+' expr %prec '!' /* '+' at same precedence level as '!' */
                        { /* leave empty to ignore '+' */ }
        | '-' expr %prec '!' /* '-' at same precedence level as '!' */
                        { emit(ineg); }
        | '(' expr ')'
        | '$' INT8      { emit(aload_1); emit2(bipush, $2); emit(iaload); }
        | PP ID         { emit(iconst_1); emit2(iload, $2 ->localvar); emit(iadd); emit(dup); emit2(istore, $2 ->localvar); }
        | NN ID         { emit2(iload, $2 ->localvar); emit(iconst_1); emit(isub); emit(dup); emit2(istore, $2 ->localvar); }
        | ID PP         { emit2(iload, $1 ->localvar); emit(dup); emit(iconst_1); emit(iadd); emit2(istore, $1 ->localvar); }
        | ID NN         { emit2(iload, $1 ->localvar); emit(dup); emit(iconst_1); emit(isub); emit2(istore, $1 ->localvar); }
        | ID            { emit2(iload, $1->localvar); }
        | INT8          { emit2(bipush, $1); }
        | INT16         { emit3(sipush, $1); }
        | INT32         { emit2(ldc, constant_pool_add_Integer(&cf, $1)); }
	| FLT		{ error("float constant not supported in Pr3"); }
	| STR		{ error("string constant not supported in Pr3"); }
        ;

L       : /* empty */   { $$ = pc; }
        ;

M       : /* empty */   { $$ = pc;	/* location of inst. to backpatch */
			  emit3(ifeq, 0);
			}
        ;

N       : /* empty */   { $$ = pc;	/* location of inst. to backpatch */
			  emit3(goto_, 0);
			}
        ;

P       : /* empty */ {emit(pop); }
	;

/* TODO: TO BE COMPLETED WITH ADDITIONAL NONMARKERS AS NEEDED */

%%

int main(int argc, char **argv)
{
	int index1, index2, index3;
	int label1, label2;

	// set up new class file structure
	init_ClassFile(&cf);

	// class has public access
	cf.access = ACC_PUBLIC;

	// class name is "Code"
	cf.name = "Code";

	// no fields
	cf.field_count = 0;

	// one method
	cf.method_count = 1;

	// allocate array of methods (just one "main" in our example)
	cf.methods = (struct MethodInfo*)malloc(cf.method_count * sizeof(struct MethodInfo));

	if (!cf.methods)
		error("Out of memory");

	// method has public access and is static
	cf.methods[0].access = (enum access_flags)(ACC_PUBLIC | ACC_STATIC);

	// method name is "main"
	cf.methods[0].name = "main";

	// method descriptor of "void main(String[] arg)"
	cf.methods[0].descriptor = "([Ljava/lang/String;)V";

	// max operand stack size of this method
	cf.methods[0].max_stack = 100;

	// the number of local variables in the local variable array
	//   local variable 0 contains "arg"
	//   local variable 1 contains "val"
	//   local variable 2 contains "i" and "result"
	cf.methods[0].max_locals = 100;

	// set up new bytecode buffer
	init_code();
	
	// generate prologue code

/*LOC*/ /*CODE*/			/*SOURCE*/
/*000*/	emit(aload_0);
/*001*/	emit(arraylength);		// arg.length
/*002*/	emit2(newarray, T_INT);
/*004*/	emit(astore_1);			// val = new int[arg.length]
/*005*/	emit(iconst_0);
/*006*/	emit(istore_2);			// i = 0
	label1 = pc;			// label1:
/*007*/	emit(iload_2);
/*008*/	emit(aload_0);
/*009*/	emit(arraylength);
	label2 = pc;
/*010*/	emit3(if_icmpge, PAD);		// if i >= arg.length then goto label2
/*013*/	emit(aload_1);
/*014*/	emit(iload_2);
/*015*/	emit(aload_0);
/*016*/	emit(iload_2);
/*017*/	emit(aaload);			// push arg[i] parameter for parseInt
	index1 = constant_pool_add_Methodref(&cf, "java/lang/Integer", "parseInt", "(Ljava/lang/String;)I");
/*018*/	emit3(invokestatic, index1);	// invoke Integer.parseInt(arg[i])
/*021*/	emit(iastore);			// val[i] = Integer.parseInt(arg[i])
/*022*/	emit32(iinc, 2, 1);		// i++
/*025*/	emit3(goto_, label1 - pc);	// goto label1
	backpatch(label2, pc - label2);	// label2:

	// end of prologue code

	init();

	if (argc > 1)
		if (!(yyin = fopen(argv[1], "r")))
			error("Cannot open file for reading");

	if (yyparse() || errnum > 0)
		error("Compilation errors: class file not saved");

	fprintf(stderr, "Compilation successful: saving %s.class\n", cf.name);

	// generate epilogue code

	index2 = constant_pool_add_Fieldref(&cf, "java/lang/System", "out", "Ljava/io/PrintStream;");
/*036*/	emit3(getstatic, index2);	// get static field System.out of type PrintStream
/*039*/	emit(iload_2);			// push parameter for println()
	index3 = constant_pool_add_Methodref(&cf, "java/io/PrintStream", "println", "(I)V");
/*040*/	emit3(invokevirtual, index3);	// invoke System.out.println(result)
/*043*/	emit(return_);			// return

	// end of epilogue code

	// length of bytecode is in the emitter's pc variable
	cf.methods[0].code_length = pc;
	
	// must copy code to make it persistent
	cf.methods[0].code = copy_code();

	if (!cf.methods[0].code)
		error("Out of memory");

	// save class file to "Calc.class"
	save_classFile(&cf);

	return 0;
}

