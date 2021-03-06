/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 by Bart Kiers
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * Project      : sqlite-parser; an ANTLR4 grammar for SQLite
 *                https://github.com/bkiers/sqlite-parser
 * Developed by : Bart Kiers, bart@big-o.nl
 */
grammar Sqlite;

@header {
    package com.squareup.sqldelight;
}

parse
 : ( sql_stmt_list | error ) EOF
 ;

error
 : UNEXPECTED_CHAR 
 ;

sql_stmt_list
 : import_stmt* (create_table_stmt ';')? ( sql_stmt ';' )*
 ;

import_stmt
 : K_IMPORT java_type_name ';'
 ;

sql_stmt
 : ( JAVADOC_COMMENT )? sql_stmt_name ':' ( K_EXPLAIN ( K_QUERY K_PLAN )? )? ( alter_table_stmt
                                      | analyze_stmt
                                      | create_index_stmt
                                      | create_trigger_stmt
                                      | create_view_stmt
                                      | delete_stmt
                                      | drop_index_stmt
                                      | drop_table_stmt
                                      | drop_trigger_stmt
                                      | drop_view_stmt
                                      | insert_stmt
                                      | pragma_stmt
                                      | reindex_stmt
                                      | release_stmt
                                      | savepoint_stmt
                                      | select_stmt
                                      | update_stmt
                                      | vacuum_stmt )
 ;

alter_table_stmt
 : K_ALTER K_TABLE table_name
   ( K_RENAME K_TO new_table_name
   | K_ADD K_COLUMN? column_def
   )
 ;

analyze_stmt
 : K_ANALYZE table_or_index_name
 ;

create_index_stmt
 : K_CREATE K_UNIQUE? K_INDEX ( K_IF K_NOT K_EXISTS )?
   index_name K_ON table_name '(' indexed_column ( ',' indexed_column )* ')'
   ( K_WHERE expr )?
 ;

create_table_stmt
 : ( JAVADOC_COMMENT )? K_CREATE ( K_TEMP | K_TEMPORARY )? K_TABLE ( K_IF K_NOT K_EXISTS )?
   table_name
   ( '(' column_def ( ',' column_def )* ( ',' table_constraint )* ')' ( K_WITHOUT IDENTIFIER )?
   | K_AS select_stmt 
   )
 ;

create_trigger_stmt
 : K_CREATE ( K_TEMP | K_TEMPORARY )? K_TRIGGER ( K_IF K_NOT K_EXISTS )?
   trigger_name ( K_BEFORE  | K_AFTER | K_INSTEAD K_OF )?
   ( K_DELETE | K_INSERT | K_UPDATE ( K_OF column_name ( ',' column_name )* )? ) K_ON table_name
   ( K_FOR K_EACH K_ROW )? ( K_WHEN expr )?
   K_BEGIN ( ( update_stmt | insert_stmt | delete_stmt | select_stmt ) ';' )+ K_END
 ;

create_view_stmt
 : K_CREATE ( K_TEMP | K_TEMPORARY )? K_VIEW ( K_IF K_NOT K_EXISTS )?
   view_name K_AS select_stmt
 ;

delete_stmt
 : with_clause? K_DELETE K_FROM table_name
   ( K_WHERE expr )?
 ;

drop_index_stmt
 : K_DROP K_INDEX ( K_IF K_EXISTS )? index_name
 ;

drop_table_stmt
 : K_DROP K_TABLE ( K_IF K_EXISTS )? table_name
 ;

drop_trigger_stmt
 : K_DROP K_TRIGGER ( K_IF K_EXISTS )? trigger_name
 ;

drop_view_stmt
 : K_DROP K_VIEW ( K_IF K_EXISTS )? view_name
 ;

insert_stmt
 : with_clause? ( K_INSERT 
                | K_REPLACE
                | K_INSERT K_OR K_REPLACE
                | K_INSERT K_OR K_ROLLBACK
                | K_INSERT K_OR K_ABORT
                | K_INSERT K_OR K_FAIL
                | K_INSERT K_OR K_IGNORE ) K_INTO
   table_name ( '(' column_name ( ',' column_name )* ')' )?
   ( K_VALUES values
   | select_stmt
   | K_DEFAULT K_VALUES
   )
 ;

pragma_stmt
 : K_PRAGMA pragma_name ( '=' pragma_value
                                               | '(' pragma_value ')' )?
 ;

reindex_stmt
 : K_REINDEX ( collation_name
             | ( table_name | index_name )
             )?
 ;

release_stmt
 : K_RELEASE K_SAVEPOINT? savepoint_name
 ;

savepoint_stmt
 : K_SAVEPOINT savepoint_name
 ;

select_stmt
 : with_clause?
   select_or_values ( compound_operator select_or_values )*
   ( K_ORDER K_BY ordering_term ( ',' ordering_term )* )?
   ( K_LIMIT expr ( ( K_OFFSET | ',' ) expr )? )?
 ;

select_or_values
 : K_SELECT ( K_DISTINCT | K_ALL )? result_column ( ',' result_column )*
   ( K_FROM ( table_or_subquery ( ',' table_or_subquery )* | join_clause ) )?
   ( K_WHERE expr )?
   ( K_GROUP K_BY expr ( ',' expr )* having_stmt? )?
 | K_VALUES values
 ;

having_stmt
 : K_HAVING expr
 ;

values
 : '(' expr ( ',' expr )* ')' ( ',' values )?
 ;

update_stmt
 : with_clause? K_UPDATE ( K_OR K_ROLLBACK
                         | K_OR K_ABORT
                         | K_OR K_REPLACE
                         | K_OR K_FAIL
                         | K_OR K_IGNORE )? table_name
   K_SET column_name '=' setter_expr ( ',' column_name '=' setter_expr )* ( K_WHERE expr )?
 ;

vacuum_stmt
 : K_VACUUM
 ;

column_def
 : ( JAVADOC_COMMENT )? column_name type_name column_constraint*
 ;

type_name
 : sqlite_type_name ( '(' signed_number ')'
                    | '(' signed_number ',' signed_number ')' )?
                    (K_AS annotation* java_type_name)?
 ;

annotation
 : '@' java_type ( '(' annotation_value ')'
                 | '(' IDENTIFIER '=' annotation_value ( ',' IDENTIFIER '=' annotation_value )* ')'
                 )?
 ;

annotation_value
 : java_type_name '.class'
 | IDENTIFIER
 | INTEGER_LITERAL
 | REAL_LITERAL
 | '{' annotation_value ( ',' annotation_value )* '}'
 ;

column_constraint
 : ( K_CONSTRAINT name )?
   ( K_PRIMARY_KEY ( K_ASC | K_DESC )? conflict_clause K_AUTOINCREMENT?
   | K_NOT? K_NULL conflict_clause
   | K_UNIQUE conflict_clause
   | K_CHECK '(' expr ')'
   | K_DEFAULT (signed_number | literal_value | '(' expr ')' | time_value)
   | K_COLLATE collation_name
   | foreign_key_clause
   )
 ;

conflict_clause
 : ( K_ON K_CONFLICT ( K_ROLLBACK
                     | K_ABORT
                     | K_FAIL
                     | K_IGNORE
                     | K_REPLACE
                     )
   )?
 ;

/*
    SQLite understands the following binary operators, in order from highest to
    lowest precedence:

    ||
    *    /    %
    +    -
    <<   >>   &    |
    <    <=   >    >=
    =    ==   !=   <>   IS   IS NOT   IN   LIKE   GLOB   MATCH   REGEXP
    AND
    OR
*/
expr
 : literal_value
 | ( BIND_DIGITS | ( ':' ) IDENTIFIER )
 | ( table_name '.' )? column_name
 | unary_operator expr
 | expr PIPE2 expr
 | expr ( STAR | DIV | MOD ) expr
 | expr ( PLUS | MINUS ) expr
 | expr ( LT2 | GT2 | AMP | PIPE ) expr
 | expr ( LT | LT_EQ | GT | GT_EQ ) expr
 | expr ( ASSIGN | EQ | NOT_EQ1 | NOT_EQ2 ) expr
 | expr K_NOT? K_IN ( '(' ( select_stmt
                          | expr ( ',' expr )*
                          )?
                      ')'
                    | table_name
                    | ( BIND_DIGITS | ( ':' ) IDENTIFIER ) )
 | function_name '(' ( K_DISTINCT? expr ( ',' expr )* | STAR )? ')'
 | OPEN_PAR expr CLOSE_PAR
 | K_CAST '(' expr K_AS type_name ')'
 | expr K_COLLATE collation_name
 | expr K_NOT? ( K_LIKE | K_GLOB | K_REGEXP | K_MATCH ) expr ( K_ESCAPE expr )?
 | expr K_AND expr
 | expr K_OR expr
 | expr ( K_ISNULL | K_NOTNULL | K_NOT K_NULL )
 | expr K_IS K_NOT? expr
 | expr K_NOT? K_BETWEEN expr K_AND expr
 | ( ( K_NOT )? K_EXISTS )? '(' select_stmt ')'
 | K_CASE expr? ( K_WHEN expr K_THEN return_expr )+ ( K_ELSE expr )? K_END
 | raise_function
 ;

setter_expr
 : expr
 | time_value
 ;

return_expr
 : expr
 ;

foreign_key_clause
 : K_REFERENCES foreign_table ( '(' column_name ( ',' column_name )* ')' )?
   ( ( K_ON ( K_DELETE | K_UPDATE ) ( K_SET K_NULL
                                    | K_SET K_DEFAULT
                                    | K_CASCADE
                                    | K_RESTRICT
                                    | K_NO K_ACTION )
     | K_MATCH name
     ) 
   )*
   ( K_NOT? K_DEFERRABLE ( K_INITIALLY K_DEFERRED | K_INITIALLY K_IMMEDIATE )? )?
 ;

raise_function
 : K_RAISE '(' ( K_IGNORE 
               | ( K_ROLLBACK | K_ABORT | K_FAIL ) ',' error_message )
           ')'
 ;

indexed_column
 : column_name ( K_COLLATE collation_name )? ( K_ASC | K_DESC )?
 ;

table_constraint
 : ( K_CONSTRAINT name )?
   ( ( K_PRIMARY_KEY | K_UNIQUE ) '(' indexed_column ( ',' indexed_column )* ')' conflict_clause
   | K_CHECK '(' expr ')'
   | K_FOREIGN_KEY '(' column_name ( ',' column_name )* ')' foreign_key_clause
   )
 ;

with_clause
 : K_WITH K_RECURSIVE? common_table_expression ( ',' common_table_expression )*
 ;

qualified_table_name
 : table_name ( K_INDEXED K_BY index_name
              | K_NOT K_INDEXED )?
 ;

ordering_term
 : expr ( K_COLLATE collation_name )? ( K_ASC | K_DESC )?
 ;

pragma_value
 : signed_number
 | name
 | STRING_LITERAL
 ;

common_table_expression
 : table_name ( '(' column_name ( ',' column_name )* ')' )? K_AS '(' select_stmt ')'
 ;

result_column
 : '*'
 | table_name '.' '*'
 | expr ( K_AS? column_alias )?
 ;

table_or_subquery
 : table_name ( K_AS? table_alias )?
   ( K_INDEXED K_BY index_name
   | K_NOT K_INDEXED )?
 | '(' ( table_or_subquery ( ',' table_or_subquery )*
       | join_clause )
   ')'
 | '(' select_stmt ')' ( K_AS? table_alias )?
 ;

join_clause
 : table_or_subquery ( join_operator table_or_subquery join_constraint )*
 ;

join_operator
 : ','
 | K_NATURAL? ( K_LEFT K_OUTER? | K_INNER | K_CROSS )? K_JOIN
 ;

join_constraint
 : ( K_ON expr
   | K_USING '(' column_name ( ',' column_name )* ')' )?
 ;

compound_operator
 : K_UNION
 | K_UNION K_ALL
 | K_INTERSECT
 | K_EXCEPT
 ;

signed_number
 : ( '+' | '-' )? ( INTEGER_LITERAL | REAL_LITERAL )
 ;

literal_value
 : INTEGER_LITERAL
 | REAL_LITERAL
 | STRING_LITERAL
 | BLOB_LITERAL
 | K_NULL
 ;

time_value
 : K_CURRENT_TIME
 | K_CURRENT_DATE
 | K_CURRENT_TIMESTAMP
 ;

unary_operator
 : '-'
 | '+'
 | '~'
 | K_NOT
 ;

error_message
 : STRING_LITERAL
 ;

column_alias
 : IDENTIFIER
 ;

keyword
 : K_ABORT
 | K_ACTION
 | K_ADD
 | K_AFTER
 | K_ALL
 | K_ALTER
 | K_ANALYZE
 | K_AND
 | K_AS
 | K_ASC
 | K_ATTACH
 | K_AUTOINCREMENT
 | K_BEFORE
 | K_BEGIN
 | K_BETWEEN
 | K_BY
 | K_CASCADE
 | K_CASE
 | K_CAST
 | K_CHECK
 | K_COLLATE
 | K_COLUMN
 | K_COMMIT
 | K_CONFLICT
 | K_CONSTRAINT
 | K_CREATE
 | K_CROSS
 | K_CURRENT_DATE
 | K_CURRENT_TIME
 | K_CURRENT_TIMESTAMP
 | K_DATABASE
 | K_DEFAULT
 | K_DEFERRABLE
 | K_DEFERRED
 | K_DELETE
 | K_DESC
 | K_DETACH
 | K_DISTINCT
 | K_DROP
 | K_EACH
 | K_ELSE
 | K_END
 | K_ESCAPE
 | K_EXCEPT
 | K_EXCLUSIVE
 | K_EXISTS
 | K_EXPLAIN
 | K_FAIL
 | K_FOR
 | K_FOREIGN_KEY
 | K_FROM
 | K_FULL
 | K_GLOB
 | K_GROUP
 | K_HAVING
 | K_IF
 | K_IGNORE
 | K_IMMEDIATE
 | K_IMPORT
 | K_IN
 | K_INDEX
 | K_INDEXED
 | K_INITIALLY
 | K_INNER
 | K_INSERT
 | K_INSTEAD
 | K_INTERSECT
 | K_INTO
 | K_IS
 | K_ISNULL
 | K_JOIN
 | K_LEFT
 | K_LIKE
 | K_LIMIT
 | K_MATCH
 | K_NATURAL
 | K_NO
 | K_NOT
 | K_NOTNULL
 | K_NULL
 | K_OF
 | K_OFFSET
 | K_ON
 | K_OR
 | K_ORDER
 | K_OUTER
 | K_PLAN
 | K_PRAGMA
 | K_PRIMARY_KEY
 | K_QUERY
 | K_RAISE
 | K_RECURSIVE
 | K_REFERENCES
 | K_REGEXP
 | K_REINDEX
 | K_RELEASE
 | K_RENAME
 | K_REPLACE
 | K_RESTRICT
 | K_RIGHT
 | K_ROLLBACK
 | K_ROW
 | K_SAVEPOINT
 | K_SELECT
 | K_SET
 | K_TABLE
 | K_TEMP
 | K_TEMPORARY
 | K_THEN
 | K_TO
 | K_TRANSACTION
 | K_TRIGGER
 | K_UNION
 | K_UNIQUE
 | K_UPDATE
 | K_USING
 | K_VACUUM
 | K_VALUES
 | K_VIEW
 | K_WHEN
 | K_WHERE
 | K_WITH
 | K_WITHOUT
 | K_INTEGER
 | K_REAL
 | K_TEXT
 | K_BLOB
 | K_JAVA_BOOLEAN
 | K_JAVA_INTEGER
 | K_JAVA_LONG
 | K_JAVA_FLOAT
 | K_JAVA_DOUBLE
 | K_JAVA_STRING
 | K_JAVA_BYTE_ARRAY
 ;

// TODO check all names below

name
 : any_name
 ;

function_name
 : any_name
 ;

table_name 
 : IDENTIFIER
 ;

table_or_index_name 
 : any_name
 ;

new_table_name 
 : any_name
 ;

column_name 
 : IDENTIFIER | STRING_LITERAL
 ;

sql_stmt_name
 : IDENTIFIER
 ;

collation_name 
 : any_name
 ;

foreign_table 
 : any_name
 ;

index_name 
 : any_name
 ;

trigger_name
 : any_name
 ;

view_name 
 : IDENTIFIER
 ;

pragma_name 
 : any_name
 ;

savepoint_name 
 : any_name
 ;

table_alias 
 : IDENTIFIER
 ;


sqlite_type_name: K_INTEGER | K_REAL | K_TEXT | K_BLOB;

java_type_name
  : K_JAVA_BOOLEAN
  | K_JAVA_SHORT
  | K_JAVA_INTEGER
  | K_JAVA_LONG
  | K_JAVA_FLOAT
  | K_JAVA_DOUBLE
  | K_JAVA_STRING
  | K_JAVA_BYTE_ARRAY
  | custom_type
  ;

// Because '>>' is considered a single character there has to be some hacky stuff going on
// to have it accepted by the parser.
custom_type
 : java_type ( ( '<' java_type_name ( ',' java_type_name )* '>' )
             | ( '<' ( java_type_name ',' )* java_type '<' java_type_name2 ( ',' java_type_name2 )* '>>' ) )?
 ;

java_type_name2
 : java_type_name
 ;

java_type
 : ( ( IDENTIFIER | keyword ) '.' )* ( IDENTIFIER | keyword )
 ;

any_name
 : IDENTIFIER 
 | STRING_LITERAL
 | '(' any_name ')'
 ;

K_JAVA_BOOLEAN: B 'o' 'o' 'l' 'e' 'a' 'n';
K_JAVA_SHORT: S 'h' 'o' 'r' 't';
K_JAVA_INTEGER: I 'n' 't' 'e' 'g' 'e' 'r';
K_JAVA_LONG: L 'o' 'n' 'g';
K_JAVA_FLOAT: F 'l' 'o' 'a' 't';
K_JAVA_DOUBLE: D 'o' 'u' 'b' 'l' 'e';
K_JAVA_STRING: S 't' 'r' 'i' 'n' 'g';
K_JAVA_BYTE_ARRAY: 'b' 'y' 't' 'e' '[' ']';

K_INTEGER: 'I' 'N' 'T' 'E' 'G' 'E' 'R';
K_REAL: 'R' 'E' 'A' 'L';
K_TEXT: 'T' 'E' 'X' 'T';
K_BLOB: 'B' 'L' 'O' 'B';

SCOL : ';';
DOT : '.';
OPEN_PAR : '(';
CLOSE_PAR : ')';
COMMA : ',';
ASSIGN : '=';
STAR : '*';
PLUS : '+';
MINUS : '-';
TILDE : '~';
PIPE2 : '||';
DIV : '/';
MOD : '%';
LT2 : '<<';
GT2 : '>>';
AMP : '&';
PIPE : '|';
LT : '<';
LT_EQ : '<=';
GT : '>';
GT_EQ : '>=';
EQ : '==';
NOT_EQ1 : '!=';
NOT_EQ2 : '<>';
QUOTE : '\'';

// http://www.sqlite.org/lang_keywords.html
K_ABORT : A B O R T;
K_ACTION : A C T I O N;
K_ADD : A D D;
K_AFTER : A F T E R;
K_ALL : A L L;
K_ALTER : A L T E R;
K_ANALYZE : A N A L Y Z E;
K_AND : A N D;
K_AS : A S;
K_ASC : A S C;
K_ATTACH : A T T A C H;
K_AUTOINCREMENT : A U T O I N C R E M E N T;
K_BEFORE : B E F O R E;
K_BEGIN : B E G I N;
K_BETWEEN : B E T W E E N;
K_BY : B Y;
K_CASCADE : C A S C A D E;
K_CASE : C A S E;
K_CAST : C A S T;
K_CHECK : C H E C K;
K_COLLATE : C O L L A T E;
K_COLUMN : C O L U M N;
K_COMMIT : C O M M I T;
K_CONFLICT : C O N F L I C T;
K_CONSTRAINT : C O N S T R A I N T;
K_CREATE : C R E A T E;
K_CROSS : C R O S S;
K_CURRENT_DATE : C U R R E N T '_' D A T E;
K_CURRENT_TIME : C U R R E N T '_' T I M E;
K_CURRENT_TIMESTAMP : C U R R E N T '_' T I M E S T A M P;
K_DATABASE : D A T A B A S E;
K_DEFAULT : D E F A U L T;
K_DEFERRABLE : D E F E R R A B L E;
K_DEFERRED : D E F E R R E D;
K_DELETE : D E L E T E;
K_DESC : D E S C;
K_DETACH : D E T A C H;
K_DISTINCT : D I S T I N C T;
K_DROP : D R O P;
K_EACH : E A C H;
K_ELSE : E L S E;
K_END : E N D;
K_ESCAPE : E S C A P E;
K_EXCEPT : E X C E P T;
K_EXCLUSIVE : E X C L U S I V E;
K_EXISTS : E X I S T S;
K_EXPLAIN : E X P L A I N;
K_FAIL : F A I L;
K_FOR : F O R;
K_FOREIGN_KEY : F O R E I G N ' ' K E Y;
K_FROM : F R O M;
K_FULL : F U L L;
K_GLOB : G L O B;
K_GROUP : G R O U P;
K_HAVING : H A V I N G;
K_IF : I F;
K_IGNORE : I G N O R E;
K_IMMEDIATE : I M M E D I A T E;
K_IMPORT : I M P O R T;
K_IN : I N;
K_INDEX : I N D E X;
K_INDEXED : I N D E X E D;
K_INITIALLY : I N I T I A L L Y;
K_INNER : I N N E R;
K_INSERT : I N S E R T;
K_INSTEAD : I N S T E A D;
K_INTERSECT : I N T E R S E C T;
K_INTO : I N T O;
K_IS : I S;
K_ISNULL : I S N U L L;
K_JOIN : J O I N;
K_LEFT : L E F T;
K_LIKE : L I K E;
K_LIMIT : L I M I T;
K_MATCH : M A T C H;
K_NATURAL : N A T U R A L;
K_NO : N O;
K_NOT : N O T;
K_NOTNULL : N O T N U L L;
K_NULL : N U L L;
K_OF : O F;
K_OFFSET : O F F S E T;
K_ON : O N;
K_OR : O R;
K_ORDER : O R D E R;
K_OUTER : O U T E R;
K_PLAN : P L A N;
K_PRAGMA : P R A G M A;
K_PRIMARY_KEY : P R I M A R Y ' ' K E Y;
K_QUERY : Q U E R Y;
K_RAISE : R A I S E;
K_RECURSIVE : R E C U R S I V E;
K_REFERENCES : R E F E R E N C E S;
K_REGEXP : R E G E X P;
K_REINDEX : R E I N D E X;
K_RELEASE : R E L E A S E;
K_RENAME : R E N A M E;
K_REPLACE : 'R' 'E' 'P' 'L' 'A' 'C' 'E'; // TODO Make all keywords force caps?
K_RESTRICT : R E S T R I C T;
K_RIGHT : R I G H T;
K_ROLLBACK : R O L L B A C K;
K_ROW : R O W;
K_SAVEPOINT : S A V E P O I N T;
K_SELECT : S E L E C T;
K_SET : S E T;
K_TABLE : T A B L E;
K_TEMP : T E M P;
K_TEMPORARY : T E M P O R A R Y;
K_THEN : T H E N;
K_TO : T O;
K_TRANSACTION : T R A N S A C T I O N;
K_TRIGGER : T R I G G E R;
K_UNION : U N I O N;
K_UNIQUE : U N I Q U E;
K_UPDATE : U P D A T E;
K_USING : U S I N G;
K_VACUUM : V A C U U M;
K_VALUES : V A L U E S;
K_VIEW : V I E W;
K_WHEN : W H E N;
K_WHERE : W H E R E;
K_WITH : W I T H;
K_WITHOUT : W I T H O U T;

IDENTIFIER
 : '"' (~'"' | '""')* '"'
 | '`' (~'`' | '``')* '`'
 | '[' ~']'* ']'
 | [a-zA-Z_] [a-zA-Z_0-9]*
 ;

INTEGER_LITERAL
 : DIGIT+ ( E [-+]? DIGIT+ )?
 ;

REAL_LITERAL
 : DIGIT+  '.' DIGIT* ( E [-+]? DIGIT+ )?
 | '.' DIGIT+ ( E [-+]? DIGIT+ )?
 ;

BIND_DIGITS
 : '?' DIGIT*
 ;

STRING_LITERAL
 : '\'' ( ~'\'' | '\'\'' )* '\''
 ;

BLOB_LITERAL
 : X STRING_LITERAL
 ;

SINGLE_LINE_COMMENT
 : '--' ~[\r\n]* -> channel(HIDDEN)
 ;

JAVADOC_COMMENT
 : '/**' .*? ( '*/' | EOF )
 ;

MULTILINE_COMMENT
 : '/*' .*? ( '*/' | EOF ) -> channel(HIDDEN)
 ;

SPACES
 : [ \u000B\t\r\n] -> channel(HIDDEN)
 ;

UNEXPECTED_CHAR
 : .
 ;

fragment DIGIT : [0-9];

fragment A : [aA];
fragment B : [bB];
fragment C : [cC];
fragment D : [dD];
fragment E : [eE];
fragment F : [fF];
fragment G : [gG];
fragment H : [hH];
fragment I : [iI];
fragment J : [jJ];
fragment K : [kK];
fragment L : [lL];
fragment M : [mM];
fragment N : [nN];
fragment O : [oO];
fragment P : [pP];
fragment Q : [qQ];
fragment R : [rR];
fragment S : [sS];
fragment T : [tT];
fragment U : [uU];
fragment V : [vV];
fragment W : [wW];
fragment X : [xX];
fragment Y : [yY];
fragment Z : [zZ];
