%{

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#define YYDEBUG 0

extern int yylineno;	// absolute, from flex
extern int linenum;		// custom, adjusted for includes

int yylex(void)	;
void yyerror(char *s)	;
int sym[26]	;                   /* symbol table */

%}

	// ==============================================================
	// YACC term declarations, precedence and associativity
	// ==============================================================

%start goal
	// file type
%token KW_LIBRARY KW_UNIT  KW_PROGRAM
	// packages
%token KW_PACKAGE KW_REQUIRES KW_CONTAINS
	// dependencies
%token KW_USES KW_EXPORTS
	// file warnings
%token KW_PLATFORM KW_DEPRECATED
	// units keywords
%token KW_INTERF KW_IMPL KW_FINALIZ KW_INIT
	// objects
%token KW_OBJECT KW_RECORD KW_CLASS
	// functions
%token KW_FUNCTION KW_PROCEDURE KW_PROPERTY
	// general
%token KW_OF KW_OUT KW_PACKED KW_INHERITED
	// scopre qualifiers
%token KW_PROTECTED KW_PUBLIC KW_PUBLISHED KW_PRIVATE
	// sec headers
%token KW_CONST KW_VAR KW_THRVAR KW_TYPE KW_CONSTRUCTOR KW_DESTRUCTOR KW_ASM
	//main_blocks
%token KW_BEGIN KW_END KW_WITH KW_DO
	// control flow loops
%token KW_FOR KW_TO KW_DOWNTO KW_REPEAT KW_UNTIL KW_WHILE
	// control flow others
%token KW_IF KW_THEN KW_ELSE KW_CASE KW_GOTO KW_LABEL
	// control flow exceptions
%token KW_RAISE KW_AT KW_TRY KW_EXCEPT KW_FINALLY KW_ON
	// function qualifiers
%token KW_ABSOLUTE KW_ABSTRACT KW_ASSEMBLER KW_DYNAMIC KW_EXPORT KW_EXTERNAL KW_FORWARD KW_INLINE KW_OVERRIDE KW_OVERLOAD KW_REINTRODUCE KW_VIRTUAL KW_VARARGS
	// function call types
%token KW_PASCAL KW_SAFECALL KW_STDCALL KW_CDECL KW_REGISTER
	// properties keywords
%token KW_NAME KW_READ KW_WRITE KW_INDEX KW_STORED KW_DEFAULT KW_NODEFAULT KW_IMPLEMENTS
	// types
%token TYPE_INT64 TYPE_INT TYPE_LONGINT TYPE_LONGWORD TYPE_SMALLINT TYPE_SHORTINT TYPE_WORD TYPE_BYTE TYPE_CARDINAL TYPE_UINT64
%token TYPE_CHAR TYPE_PCHAR TYPE_WIDECHAR TYPE_WIDESTR TYPE_STR TYPE_RSCSTR TYPE_SHORTSTR
%token TYPE_FLOAT TYPE_REAL48 TYPE_DOUBLE TYPE_EXTENDED
%token TYPE_BOOL TYPE_COMP TYPE_CURRENCY TYPE_OLEVAR TYPE_VAR TYPE_ARRAY TYPE_CURR TYPE_FILE TYPE_PTR TYPE_SET

	// pseudo, hints, added, etc
%token ASM_OP

		// lowest precedence |
		//					 v


%nonassoc LOWESTPREC  EXPR_SINGLE

	// dangling else
%right KW_THEN 
%right KW_ELSE 

	// literais
%token CONST_INT CONST_REAL CONST_CHAR CONST_STR IDENTIFIER CONST_NIL CONST_BOOL
	// misc, separators
%nonassoc KW_RANGE COMMA COLON SEMICOL KW_ASSIGN
	// relational/comparative
%left KW_EQ KW_GT KW_LT KW_LE KW_GE KW_DIFF KW_IN KW_IS
	// additive
%left KW_SUM KW_SUB KW_OR KW_XOR
	// multiplicative
%left KW_MUL KW_DIV KW_QUOT KW_MOD KW_SHL KW_SHR KW_AS KW_AND

%left KW_DEREF KW_DOT

%left UNARY KW_NOT KW_ADDR

%nonassoc LBRAC RBRAC LPAREN RPAREN

%nonassoc MAXPREC

	//		Highest precedence ^
	// ==============================================================
	// ==============================================================

%%

goal: file KW_DOT		{ YYACCEPT; }
	;

file
	: program
	| package
	| library
	| unit
	;

	/*
	portability
		: KW_PLATFORM
		| KW_DEPRECATED
		| KW_LIBRARY
		;

	port_opt
		:
		| portability
		;
	*/


	// ========================================================================
	// Top-level Sections
	// ========================================================================

program
	: KW_PROGRAM id SEMICOL	usesclauseopt main_block
	| 						usesclauseopt main_block
	;

library
	: KW_LIBRARY id SEMICOL usesclauseopt main_block
	;

unit
	: KW_UNIT id /*port_opt*/ SEMICOL interfsec implementsec initsec
	;

package
	: id id SEMICOL requiresclause containsclause KW_END
	;

requiresclause
	: id idlist SEMICOL
	;

containsclause
	: id idlist SEMICOL
	;

usesclauseopt
	: 
	| KW_USES useidlist SEMICOL
	;

useidlist
	: useid
	| useidlist COMMA useid
	;
	
useid
	: id
	| id KW_IN string_const
	;

implementsec
	: KW_IMPL usesclauseopt	maindecllist
	| KW_IMPL usesclauseopt
	;

interfsec
	: KW_INTERF usesclauseopt interfdecllist
	;

interfdecllist
	:
	| interfdecllist interfdecl
	;

initsec
	: KW_INIT stmtlist KW_END
	| KW_FINALIZ stmtlist KW_END
	| KW_INIT stmtlist KW_FINALIZ stmtlist KW_END
	| block
	| KW_END
	;

main_block
	: maindecllist	block
	|				block
	;
	
maindecllist
	: maindeclsec
	| maindecllist maindeclsec
	;

declseclist
	: funcdeclsec
	| declseclist funcdeclsec
	;

	

	// ========================================================================
	// Declaration sections
	// ========================================================================

interfdecl
	: basicdeclsec
	| staticclassopt procproto
	| thrvarsec
//	| rscstringsec
	;

maindeclsec
	: basicdeclsec
	| thrvarsec
	| exportsec
	| staticclassopt procdeclnondef
	| staticclassopt procdefinition
	| labeldeclsec
	;

funcdeclsec
	: basicdeclsec
	| labeldeclsec
	| procdefinition
	| procdeclnondef
	;

basicdeclsec
	: constsec
	| typesec
	| varsec
	;

typesec
	: KW_TYPE typedecl
	| typesec typedecl
	;

	
	// labels
	
labeldeclsec
	: KW_LABEL labelidlist SEMICOL
	;
	
labelidlist 
	: labelid
	| labelidlist COMMA labelid
	;

labelid
	: CONST_INT /* must be decimal integer in the range 0..9999 */
	| id
	;

	// Exports
		
exportsec
	: KW_EXPORTS exportsitemlist
	;

exportsitemlist
	: exportsitem
	| exportsitemlist COMMA exportsitem
	;

exportsitem
	: id
	| id KW_NAME  string_const
	| id KW_INDEX expr
	;
	



	// ========================================================================
	// Functions
	// ========================================================================

	// Prototypes/headings/signatures

	// proc decl for impl sections, needs a external/forward
procdeclnondef
	: procdefproto func_nondef_list funcdir_strict_opt
	;

procdefinition
	: procdefproto proc_define SEMICOL
	;

	// proc proto for definitions or external/forward decls
procdefproto
	: procbasickind qualid formalparams funcretopt SEMICOL funcdir_strict_opt
	;

	// check that funcrecopt is null for every kind except FUNCTION
procproto
	: procbasickind qualid formalparams funcretopt SEMICOL funcdirectopt  /*port_opt*/ 
	;

funcretopt
	:
	| COLON funcrettype 
	;

staticclassopt
	:
	| KW_CLASS
	;

procbasickind
	: KW_FUNCTION
	| KW_PROCEDURE
	| KW_CONSTRUCTOR
	| KW_DESTRUCTOR
	;

proceduretype
	: KW_PROCEDURE formalparams ofobjectopt
	| KW_FUNCTION  formalparams COLON funcrettype ofobjectopt
	;

ofobjectopt
	:
	| KW_OF KW_OBJECT
	;

	// Function blocks and parameters

proc_define
	: func_block
	| assemblerstmt
	;


func_block
	: declseclist block
	| 			  block
	;

formalparams
	: 
	| LPAREN RPAREN
	| LPAREN formalparamslist RPAREN
	;

formalparamslist
	: formalparm
	| formalparamslist SEMICOL formalparm
	;

formalparm
	: paramqualif	idlist paramtypeopt
	| 				idlist paramtypespec paraminitopt
	| KW_CONST		idlist paramtypeopt paraminitopt
	;

paramqualif
	: KW_VAR
	| KW_OUT
	;

paramtypeopt
	: 
	| paramtypespec
	;

paramtypespec
	: COLON funcparamtype
	;

paraminitopt
	: 
	| KW_EQ expr	// evaluates to constant
	;

	
	// Function directives
	
funcdirectopt
	:
	| funcdirective_list SEMICOL
	;

funcdirectopt_nonterm
	:
	| funcdirective_list 
	;

funcdir_strict_opt
	: 
	| funcdir_strict_list
	;

funcdirective_list
	: funcdirective 
	| funcdirective_list SEMICOL funcdirective
	;

funcdir_strict_list
	: funcdir_strict SEMICOL
	| funcdir_strict_list funcdir_strict SEMICOL
	;

func_nondef_list
	: funcdir_nondef SEMICOL
	| func_nondef_list funcdir_nondef SEMICOL 
	;

funcdirective
	: funcdir_strict
	| funcdir_nondef
	;

funcdir_strict
	: funcqualif
	| funccallconv
	;

funcdir_nondef
	: KW_EXTERNAL string_const externarg
	| KW_EXTERNAL qualid externarg
	| KW_EXTERNAL
	| KW_FORWARD
	;

externarg
	: 
	| id string_const 	// id == NAME
	| id qualid		 	// id == NAME
	;

funcqualif
	: KW_ABSOLUTE
	| KW_ABSTRACT
	| KW_ASSEMBLER
	| KW_DYNAMIC
	| KW_EXPORT
	| KW_INLINE
	| KW_OVERRIDE
	| KW_OVERLOAD
	| KW_REINTRODUCE
	| KW_VIRTUAL
	| KW_VARARGS
	;

funccallconv
	: KW_PASCAL
	| KW_SAFECALL
	| KW_STDCALL
	| KW_CDECL
	| KW_REGISTER
	;



	
	// ========================================================================
	// Statements
	// ========================================================================
	
block
	: KW_BEGIN stmtlist KW_END
	;

stmtlist
	: stmt SEMICOL stmtlist
	| stmt
	;

stmt
	: nonlbl_stmt
	| labelid COLON nonlbl_stmt
	;

nonlbl_stmt
	:
	| inheritstmts
	| goto_stmt
	| block
	| ifstmt
	| casestmt
	| repeatstmt
	| whilestmt
	| forstmt
	| with_stmt
	| tryexceptstmt		// purely Delphi stuff!
	| tryfinallystmt
	| raisestmt
	| assemblerstmt
	;

inheritstmts
	: KW_INHERITED
	| KW_INHERITED assign
	| KW_INHERITED proccall
	| proccall
	| assign
	;

assign
	: lvalue KW_ASSIGN expr
	| lvalue KW_ASSIGN KW_INHERITED expr
	;


goto_stmt
	: KW_GOTO labelid
	;

ifstmt
	: KW_IF expr KW_THEN nonlbl_stmt KW_ELSE nonlbl_stmt
	| KW_IF expr KW_THEN nonlbl_stmt
	;

casestmt
	: KW_CASE expr KW_OF caseselectorlist else_case KW_END
	;

else_case
	:
	| KW_ELSE nonlbl_stmt
	| KW_ELSE nonlbl_stmt SEMICOL
	;

caseselectorlist
	: caseselector
	| caseselectorlist SEMICOL caseselector
	;

caseselector
	:
	| caselabellist COLON nonlbl_stmt
	;

caselabellist
	: caselabel
	| caselabellist COMMA caselabel
	;

	// all exprs must be evaluate to const
caselabel
	: expr
	| expr KW_RANGE expr
	;

repeatstmt
	: KW_REPEAT stmtlist KW_UNTIL expr
	;

whilestmt
	: KW_WHILE expr KW_DO nonlbl_stmt
	;

forstmt
	: KW_FOR id KW_ASSIGN expr KW_TO	 expr KW_DO nonlbl_stmt
	| KW_FOR id KW_ASSIGN expr KW_DOWNTO expr KW_DO nonlbl_stmt
	;

	// expr must yield a ref to a record, object, class, interface or class type
with_stmt
	: KW_WITH exprlist KW_DO nonlbl_stmt
	;

tryexceptstmt
	: KW_TRY stmtlist KW_EXCEPT exceptionblock KW_END
	;

exceptionblock
	: onlist KW_ELSE stmtlist
	| onlist
	| stmtlist
	;

onlist
	: ondef
	| onlist ondef
	;

ondef
	: KW_ON id COLON id KW_DO nonlbl_stmt SEMICOL
	| KW_ON 		 id KW_DO nonlbl_stmt SEMICOL
	;

tryfinallystmt
	: KW_TRY  stmtlist KW_FINALLY stmtlist KW_END
	;

raisestmt
	: KW_RAISE
	| KW_RAISE lvalue
	| KW_RAISE			KW_AT expr
	| KW_RAISE lvalue	KW_AT expr
	;

assemblerstmt
	: KW_ASM asmcode KW_END		// not supported
	;

asmcode
	: ASM_OP
	| asmcode ASM_OP
	;





	// ========================================================================
	// Variables and Expressions
	// ========================================================================

varsec
	: KW_VAR vardecllist
	;
	
thrvarsec
	: KW_THRVAR vardecllist
	;

vardecllist
	: vardecl
	| vardecllist vardecl
	;

	/* VarDecl
		On Windows -> idlist ':' Type [(ABSOLUTE (id | ConstExpr))	| '=' ConstExpr] [portability]
		On Linux   -> idlist ':' Type [ ABSOLUTE (Ident)			| '=' ConstExpr] [portability]
	*/

vardecl
	: idlist COLON vartype vardeclopt SEMICOL
	| idlist COLON proceduretype SEMICOL funcdirectopt
	| idlist COLON proceduretype SEMICOL funcdirectopt_nonterm KW_EQ CONST_NIL SEMICOL
	;

vardeclopt
	: /*port_opt*/
	| KW_ABSOLUTE id  /*port_opt*/
	| KW_EQ constexpr /*portabilityonapt*/
	;

	// func call, type cast or identifier
proccall
	: id
	| lvalue KW_DOT id						// field access
	| lvalue LPAREN exprlistopt RPAREN
	| lvalue LPAREN casttype RPAREN			// for funcs like High, Low, Sizeof etc
	;

lvalue
	: proccall						// proc_call or cast
//	| KW_INHERITED proccall		// TODO
	| expr KW_DEREF 						// pointer deref
	| lvalue LBRAC exprlist RBRAC			// array access
	| string_const LBRAC exprlist RBRAC		// string access
	| casttype LPAREN exprlistopt RPAREN	// cast with pre-defined type

//	| LPAREN lvalue RPAREN		// TODO
	;

expr
	: literal
	| lvalue
	| setconstructor
	| KW_ADDR expr
	| KW_NOT expr
	| sign	 expr %prec UNARY
	| LPAREN expr RPAREN
	| expr relop expr %prec KW_EQ
	| expr addop expr %prec KW_SUB
	| expr mulop expr %prec KW_MUL
	;

sign
	: KW_SUB
	| KW_SUM
	;
mulop
	: KW_MUL
	| KW_DIV
	| KW_QUOT
	| KW_MOD
	| KW_SHR
	| KW_SHL
	| KW_AND
	;
addop
	: KW_SUB
	| KW_SUM
	| KW_OR
	| KW_XOR
	;
relop
	: KW_EQ
	| KW_DIFF
	| KW_LT
	| KW_LE
	| KW_GT
	| KW_GE
	| KW_IN
	| KW_IS
	| KW_AS
	;

literal
	: CONST_INT
	| CONST_BOOL
	| CONST_REAL
	| CONST_NIL
	| string_const
	;

discrete
	: CONST_INT
	| CONST_CHAR
	| CONST_BOOL
	;

string_const
	: CONST_STR
	| CONST_CHAR 
	| string_const CONST_STR
	| string_const CONST_CHAR
	;

id	: IDENTIFIER
	;

idlist
	: id
	| idlist COMMA id
	;

qualid
	: id
	| qualid KW_DOT id
	;
	
exprlist
	: expr
	| exprlist COMMA expr
	;

exprlistopt
	:
	| exprlist
	;





	// ========================================================================
	// Sets and Enums literals
	// ========================================================================

	/* examples:
		SmallNums : Set of 0..55;		// Set of the first 56 set members
		SmallNums := [3..12,23,30..32];	// Set only some of the members on
		
		type TDay = (Mon=1, Tue, Wed, Thu, Fri, Sat, Sun);	// Enumeration values
		TWeekDays = Mon..Fri;	// Enumeration subranges
		TWeekend  = Sat..Sun;

		[red, green, MyColor]
		[1, 5, 10..K mod 12, 23]
		['A'..'Z', 'a'..'z', Chr(Digit + 48)]
	*/

rangetype
	: sign rangestart KW_RANGE expr
	| rangestart KW_RANGE expr
	;

rangestart
	: discrete
	| qualid
	| id LPAREN casttype RPAREN
	| id LPAREN literal RPAREN
	;

enumtype
	: LPAREN enumtypeellist RPAREN
	;

enumtypeellist
	: enumtypeel
	| enumtypeellist COMMA enumtypeel
	;

enumtypeel
	: id 
	| id KW_EQ expr
	;

setconstructor
	: LBRAC	RBRAC
	| LBRAC setlist	RBRAC
	;

setlist
	: setelem
	| setlist COMMA setelem
	;
	
setelem
	: expr
	| expr KW_RANGE expr
	;




	
	// ========================================================================
	// Constants
	// ========================================================================

	/*
	// Resource strings, windows-only

	rscstringsec
		: TYPE_RSCSTR  constrscdecllist
		;

	constrscdecllist
		: constrscdecl
		| constrscdecllist constrscdecl
		;

	constrscdecl
		: id KW_EQ literal SEMICOL
		;	
	
	// --------------------------------
	*/
	
constsec
	: KW_CONST constdecl
	| constsec constdecl
	;

constdecl
	: id KW_EQ constexpr /*port_opt*/ SEMICOL			// true const
	| id COLON vartype KW_EQ constexpr /*port_opt*/ SEMICOL		// typed const
	;

constexpr
	: expr
	| arrayconst
	| recordconst
	;

	// 1 or more exprs
arrayconst
	: LPAREN constexpr COMMA constexprlist RPAREN
	;

constexprlist
	: constexpr
	| constexprlist COMMA constexpr
	;

recordconst
	: LPAREN fieldconstlist RPAREN
	| LPAREN fieldconstlist SEMICOL RPAREN
	;

fieldconstlist
	: fieldconst
	| fieldconstlist SEMICOL fieldconst
	;

fieldconst
	: id COLON constexpr 
	;





	// ========================================================================
	// Composite Types
	// ========================================================================
	
	// Records and objects are treated as classes
	
classtype
	: class_keyword heritage class_struct_opt KW_END
	| class_keyword heritage		// forward decl
	;

class_keyword
	: KW_CLASS
	| KW_OBJECT
	| KW_RECORD
	;

heritage
	:
	| LPAREN idlist RPAREN		// inheritance from class and interf(s) 
	;

class_struct_opt
	: fieldlist complist scopeseclist
	;

scopeseclist
	: 
	| scopeseclist scopesec
	;

scopesec
	: scope_decl fieldlist complist
	;

scope_decl
	: KW_PUBLISHED
	| KW_PUBLIC
	| KW_PROTECTED
	| KW_PRIVATE
	;

fieldlist
	: 
	| fieldlist objfield
	;
		
complist
	:
	| complist class_comp
	;

objfield
	: idlist COLON type SEMICOL
	;
	
class_comp
	: staticclassopt procproto
	| property
	;

interftype
	: KW_INTERF heritage classmethodlistopt classproplistopt KW_END
	;

classmethodlistopt
	: methodlist
	|
	;

methodlist
	: procproto
	| methodlist procproto
	;


	
	
	
	// ========================================================================
	// Properties
	// ========================================================================
	
	
classproplistopt
	: classproplist
	|
	;

classproplist
	: property
	| classproplist property
	;

property
	: KW_PROPERTY id SEMICOL
	| KW_PROPERTY id propinterfopt COLON funcrettype indexspecopt propspecifiers SEMICOL defaultdiropt
	;

defaultdiropt
	:
	| id SEMICOL	// id == DEFAULT
	;

propinterfopt
	:
	| LBRAC idlisttypeidlist RBRAC
	;
	
idlisttypeidlist
	: idlisttypeid
	| idlisttypeidlist SEMICOL idlisttypeid
	;

idlisttypeid
	: idlist COLON funcparamtype
	| KW_CONST idlist COLON funcparamtype
	;

indexspecopt
	:
	| KW_INDEX expr
	;


	// Ugly, but the only way...
	// 1st-id: specifier - default, implements, read, write, stored
	// 2nd-id: argument
propspecifiers
	:
	| id id 
	| id id id id
	| id id id id id id
	| id id id id id id id id
	| id id id id id id id id id id 
	;


/*	// Properties directive: emitted as ids since they are not real keywords

	propspecifiers
		: indexspecopt readacessoropt writeacessoropt storedspecopt defaultspecopt implementsspecopt
		;

	storedspecopt
		:
		| KW_STORED id
		;

	defaultspecopt
		:
		| KW_DEFAULT literal
	//	| KW_NODEFAULT	not supported by now
		;

	implementsspecopt
		:
		| KW_IMPLEMENTS id
		;

	readacessoropt
		:
		| KW_READ	id
		;

	writeacessoropt
		:
		| KW_WRITE	id
		;
	*/

	
	
	// ========================================================================
	// Types
	// ========================================================================

typedecl
	: id KW_EQ typeopt vartype /*port_opt*/ SEMICOL
	| id KW_EQ typeopt proceduretype /*port_opt*/ SEMICOL funcdirectopt 
	;

typeopt
	:
	| KW_TYPE
	;

type
	: vartype
	| proceduretype
	;

vartype
	: simpletype
	| enumtype
	| rangetype
	| varianttype
	| refpointertype
	// metaclasse
	| classreftype
	// object definition
	| KW_PACKED  packedtype
	| packedtype
	;

packedtype
	: structype
	| restrictedtype
	;

classreftype
	: KW_CLASS KW_OF scalartype
	;

simpletype
	: scalartype
	| realtype
	| stringtype
	| TYPE_PTR
	;

ordinaltype
	: enumtype
	| rangetype
	| scalartype
	;

scalartype
	: inttype
	| chartype
	| qualid		// user-defined type
	;

realtype
	: TYPE_REAL48
	| TYPE_FLOAT
	| TYPE_DOUBLE
	| TYPE_EXTENDED
	| TYPE_CURR
	| TYPE_COMP
	;

inttype
	: TYPE_BYTE
	| TYPE_BOOL
	| TYPE_INT
	| TYPE_SHORTINT
	| TYPE_SMALLINT
	| TYPE_LONGINT
	| TYPE_INT64
	| TYPE_UINT64
	| TYPE_WORD
	| TYPE_LONGWORD
	| TYPE_CARDINAL
	;

chartype
	: TYPE_CHAR
	| TYPE_WIDECHAR
	;

stringtype
	: TYPE_STR		// dynamic size
	| TYPE_PCHAR
	| TYPE_STR LBRAC expr RBRAC
	| TYPE_SHORTSTR
	| TYPE_WIDESTR
	;

varianttype
	: TYPE_VAR
	| TYPE_OLEVAR
	;

structype
	: arraytype
	| settype
	| filetype
	;
	
restrictedtype
	: classtype
	| interftype
	;

arraysizelist
	: rangetype
	| arraysizelist COMMA rangetype
	;

arraytype
	: TYPE_ARRAY LBRAC arraytypedef RBRAC KW_OF type /*port_opt*/
	| TYPE_ARRAY KW_OF type /*port_opt*/
	;

arraytypedef
	: arraysizelist
	| inttype
	| chartype
	| qualid
	;

settype
	: TYPE_SET KW_OF ordinaltype /*port_opt*/
	;

filetype
	: TYPE_FILE KW_OF type /*port_opt*/
	| TYPE_FILE
	;

refpointertype
	: KW_DEREF type /*port_opt*/
	;

funcparamtype
	: simpletype
	| TYPE_ARRAY KW_OF simpletype /*port_opt*/
	;

funcrettype
	: simpletype
	;
	
	// simpletype w/o user-defined types
casttype
	: inttype
	| chartype
	| realtype
	| stringtype
	| TYPE_PTR
	;


%%

extern int yydebug;

void yyerror(char *s) {
    fprintf(stdout, "Line %d %s\n", linenum, s);
}


int main(int argc, char** argv)
{
#if YYDEBUG
	if (YYDEBUG) yydebug = 1;
#endif
   	int yyret = yyparse();

	if (yyret == 0)
		printf("Parsing finished ok\n");
	else
		printf("Parsing failed\n");
		
    return yyret;
}



