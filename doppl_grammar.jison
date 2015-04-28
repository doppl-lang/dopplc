/* description: Doppl grammar. */

/* lexical grammar */
%lex
%%

\s+                             /* ignore whitespaces*/

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

';'                             return 'NEWLINE'
<<EOF>>                         return 'EOF'
.                               return 'INVALID'

/lex

/* operator associations and precedence */

%left 'ASSIGN'

%start task

%% /* language grammar */

task
    : taskheader '{' taskbody '}' EOF
        { 
            $$ = { header: $1, body: $3 }; 
            console.log($$); // TODO : change console.log with C++ code generator function
        }
    ;

taskheader
    : TASK '(' NUMBER_LITERAL ')' IDENTIFIER
        { 
            $$ = { range: $3, name: $5 };
        }
    | error
        {   
            console.log("");
            console.log("Syntax error on line: " + @$.first_line + ':' + @$.first_column + '   Invalid task header.');
        }
    ;

taskbody
    : declarations init_state_declaration declarations
        {
            var members = [];
            var states = [];
            members = members.concat($1.members);
            members = members.concat($3.members);
            states = states.concat($1.states);
            states = states.concat($3.states);
            $$ = { init_state: $2 , members: members, states: states };
        }
    | init_state_declaration declarations
        {
            $$ = { init_state: $1, members: $2.members, states: $2.states };
        }
    | declarations init_state_declaration
        {
            $$ = { init_state: $2, members: $1.members, states: $1.states };
        }
    | init_state_declaration
        {
            $$ = { init_state: $1, members: [], states: [] };
        }
    | error
        {   
            console.log("");
            console.log("Syntax error on line: " + @$.first_line + ':' + @$.first_column + '   Invalid task body.');
        }
    ;

declarations
    : declarations member_declaration
        {
            $1.members.push($2);
            $$ = { members: $1.members , states: $1.states };
        }
    | declarations state_declaration
        {
            $1.states.push($2);
            $$ = { members: $1.members, states: $1.states };
        }
    | state_declaration
        {
            $$ = { members: [], states: [$1] };
        }
    | member_declaration
        {
            $$ = { members: [$1], states: [] };
        }
    ;

member_declaration
    : IDENTIFIER '=' type newlines
    ;

state_declaration
    : IDENTIFIER ':' '{' '}'
    ;

init_state_declaration
    : INIT ':' '{' '}' 
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
