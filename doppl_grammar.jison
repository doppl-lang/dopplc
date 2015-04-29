/* description: Doppl grammar. */

/* lexical grammar */
%lex
%%

\b"task"\b                      return 'TASK'
\b"init"\b                      return 'INIT'

\b"byte"\b                      return 'BYTE'
\b"int"\b                       return 'INT'
\b"float"\b                     return 'FLOAT'
\b"string"\b                    return 'STRING'

"="                             return '='
"("                             return '('
")"                             return ')'
"{"                             return '{'
"}"                             return '}'
":"                             return ':'
","                             return ','

[0-9]+\b                        return 'NUMBER_LITERAL'
\".*\"                          return 'STRING_LITERAL'
[a-zA-Z]+[0-9a-zA-Z_]*\b        return 'IDENTIFIER'

"#".*\n                          /* ignore comments */
[ \t]+                          return 'WHITESPACE'
\n                              return 'NEWLINE'
<<EOF>>                         return 'EOF'
.                               return 'INVALID'

/lex

/* operator associations and precedence */

%left 'ASSIGN'

%start task

%% /* language grammar */

task
    : taskheader '{' taskbody '}' whitespaces EOF
        { 
            $$ = { header: $1, body: $3 }; 
            require('./ast').provide($$);
        }
    ;

taskheader
    : whitespaces TASK whitespaces '(' whitespaces NUMBER_LITERAL whitespaces ')' whitespaces IDENTIFIER whitespaces
        { 
            $$ = { range: $6, id: $10 };
        }
    ;

taskbody
    : init_state_declaration whitespaces
        {
            $$ = { init_state: $2 , members: [], states: [] };
        }
    | init_state_declaration declarations whitespaces
        {
            $$ = { init_state: $1 , members: $2.members, states: $2.states };
        }
    | declarations init_state_declaration whitespaces
        {
            $$ = { init_state: $2 , members: $1.members, states: $1.states };
        }
    | declarations init_state_declaration declarations whitespaces
        {
            var members = [];
            var states = [];
            members = members.concat($1.members);
            members = members.concat($3.members);
            states = states.concat($1.states);
            states = states.concat($3.states);
            $$ = { init_state: $2 , members: members, states: states };
        }
    ;

declarations
    : state_declaration
        {
            $$ = { members: [], states: [$1] };
        }
    | member_declaration
        {
            $$ = { members: [$1], states: [] };
        }
    | declarations member_declaration
        {
            $1.members.push($2);
            $$ = { members: $1.members , states: $1.states };
        }
    | declarations state_declaration
        {
            $1.states.push($2);
            $$ = { members: $1.members, states: $1.states };
        }
    ;

statebody
    : declarations whitespaces
    | whitespaces
        {
            $$ = { members: [], states: [] };
        }
    ;

member_declaration
    : whitespaces IDENTIFIER whitespaces '=' whitespaces type spaces NEWLINE
        {
            $$ = { id: $2, type: $6 };
        }
    ;

state_declaration
    : whitespaces IDENTIFIER whitespaces ':' whitespaces '{' statebody '}' spaces NEWLINE
        {
            $$ = { id: $2, body: $7 };
        }
    ;

init_state_declaration
    : whitespaces INIT whitespaces ':' whitespaces '{' statebody '}' spaces NEWLINE
        {
            $$ = { id: $2, body: $7 };
        }
    ;

type
    : BYTE
    | INT
    | FLOAT
    | STRING
    | IDENTIFIER
    ;

newlines
    : NEWLINE
    | newlines NEWLINE
    ;

spaces  
    : WHITESPACE
    |
    ;

whitespaces
    : NEWLINE whitespaces
    | WHITESPACE whitespaces
    |
    ;
