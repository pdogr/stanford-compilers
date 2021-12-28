/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%option noyywrap
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <stdlib.h>


/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

int comment_depth = 0;
int len = 0;
int consumed_eof = 0;
#define INSERT_OR_DIE(ch) {\
	if (len >= MAX_STR_CONST -1){\
		cool_yylval.error_msg = "String constant too long";\
		BEGIN(END_OF_STRING_ERROR);\
		return ERROR;\
	}\
	++len;\
	*string_buf_ptr++ = ch;\
}
%}

%x IN_COMMENT
%x NESTED_COMMENT
%x IN_STRING
%x END_OF_STRING_ERROR

LOWER [a-z]
UPPER [A-Z]
DIGITS [0-9]
LETTER ({LOWER}|{UPPER})
SUFFIX ({LETTER}|{DIGITS}|"_")*
TYPE ("SELF_TYPE"|{UPPER}{SUFFIX})
OBJECT ("self"|{LETTER}{SUFFIX})
DARROW "=>"
CLASS (?i:class)
ELSE (?i:else)
FI (?i:fi)
IF (?i:if)
IN (?i:in)
INHERITS (?i:inherits)
ISVOID (?i:isvoid)
LET (?i:let)
LOOP (?i:loop)
POOL (?i:pool)
THEN (?i:then)
WHILE (?i:while)
CASE (?i:case)
ESAC (?i:esac)
NEW (?i:new)
OF (?i:of)
NOT (?i:not)
TRUE t(?i:rue)
FALSE f(?i:alse)
LE "<="
ASSIGN "<-"

WS [ \f\r\t\v]+

%%

\" {
	string_buf_ptr = string_buf;
	len = 0;
	BEGIN(IN_STRING);
}

"--" {
 BEGIN(IN_COMMENT);
}

"(*" {
	++comment_depth;
	BEGIN(NESTED_COMMENT);
}

<END_OF_STRING_ERROR>{

	\n|\" {
		BEGIN(INITIAL);

	}
	. ;
}

<IN_STRING>{
		\" {
			BEGIN(INITIAL);
			*string_buf_ptr = '\0';
			cool_yylval.symbol = idtable.add_string(string_buf,len);
			return STR_CONST;
		}

		<<EOF>> {
			if(consumed_eof) yyterminate();
			consumed_eof = 1;

			cool_yylval.error_msg = "EOF in string constant";
			return ERROR;
		}

		\0 {
			cool_yylval.error_msg = "String contains null character";
			BEGIN(END_OF_STRING_ERROR);
			return ERROR;
		}

		\n {
			cool_yylval.error_msg = "Unterminated string constant";
			++curr_lineno;
			BEGIN(INITIAL);
			return ERROR;
		}

		\\b {
			INSERT_OR_DIE('\b');
		}

		\\t {
			INSERT_OR_DIE('\t');
		}

		\\n {
			INSERT_OR_DIE('\n');
		}

		\\f {
			INSERT_OR_DIE('\f');
		}
		
		\\[^\0] {
			INSERT_OR_DIE(yytext[1]);
		}

		. {
			char *yptr = yytext;
			while (*yptr){
				INSERT_OR_DIE(*yptr);
				++yptr;
			}
		}
}

<IN_COMMENT>{

	\n {
		++curr_lineno;
		BEGIN(INITIAL);
	}

	[^\n]+ 

}

<NESTED_COMMENT>{

	"*)" {
		--comment_depth;
		if (!comment_depth){
			BEGIN(INITIAL);
		}
	}

	"(*" {
		++comment_depth;
	}

	\n {
		++curr_lineno;
	}

	<<EOF>> {
			if (consumed_eof) yyterminate();
			consumed_eof = 1;

			cool_yylval.error_msg = "EOF in comment";
			return ERROR;
	}
	
	. ;
}

"*)" {
		cool_yylval.error_msg = "Unmatched *)";
		return ERROR;
}

{DARROW} return DARROW;
{CLASS} return CLASS;
{ELSE} return ELSE;
{FI} return FI;
{IF} return IF;
{IN} return IN;
{INHERITS} return INHERITS;
{ISVOID} return ISVOID;
{LET} return LET;
{LOOP} return LOOP;
{POOL} return POOL;
{THEN} return THEN;
{WHILE} return WHILE;
{CASE} return CASE;
{ESAC} return ESAC;
{NEW} return NEW;
{OF} return OF;
{NOT} return NOT;
{LE} return LE;
{ASSIGN} return ASSIGN;

{TRUE} {
	cool_yylval.boolean = true;
	return BOOL_CONST;
	
}

{FALSE} {
	cool_yylval.boolean = false;
	return BOOL_CONST;
	
}

("+"|"-"|"*"|"/"|"~"|"<"|"=") {
	return (int)yytext[0];
}

("{"|"}"|"("|")"|";"|"."|":"|","|"@") {
	return (int)yytext[0];
}


{DIGITS}+ {
	cool_yylval.symbol = idtable.add_string(yytext);
	return INT_CONST;
}

{TYPE} {
	cool_yylval.symbol = idtable.add_string(yytext);
	return TYPEID;
}

{OBJECT} {
	cool_yylval.symbol = idtable.add_string(yytext);
	return OBJECTID;
}

\n {
	curr_lineno++;
}

{WS} ;

. {
	cool_yylval.error_msg = yytext;
	return ERROR;
}

%%
