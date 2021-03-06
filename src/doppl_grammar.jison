/* description: Doppl grammar. */

/* lexical grammar */
%lex
%%

\b"task"\b                      return 'TASK'
\b"init"\b                      return 'INIT'

\b"yield"\b                     return 'YIELD'
\b"finish"\b                    return 'FINISH'

\b"data"\b                      return 'DATA'
\b"future"\b                    return 'FUTURE'
\b"state"\b                     return 'STATE'
\b"memory"\b                    return 'MEMORY'
\b"element"\b                   return 'ELEMENT'

\b"just"\b                      return 'JUST'
\b"maybe"\b                     return 'MAYBE'
\b"once"\b                      return 'ONCE'
\b"sole"\b                      return 'SOLE'

\b"private"\b                   return 'PRIVATE'
\b"shared"\b                    return 'SHARED'

\b"byte"\b                      return 'BYTE'
\b"bool"\b                      return 'BOOL'
\b"int"\b                       return 'INT'
\b"float"\b                     return 'FLOAT'
\b"string"\b                    return 'STRING'

"-->"                           return "-->"
"->"                            return "->"

"++"                            return '++'
"=="                            return '=='
"<"                             return '<'
">"                             return '>'
"<="                            return '<='
">="                            return '>='
"="                             return '='
"+"                             return '+'
"-"                             return '-'
"*"                             return '*'
"/"                             return '/'
"&"                             return '&'
"|"                             return '|'
"^"                             return '^'
\b"and"\b                       return 'AND'
\b"nand"\b                      return 'NAND'
\b"or"\b                        return 'OR'
\b"nor"\b                       return 'NOR'
\b"xor"\b                       return 'XOR'

"!"                             return '!'
"`"                             return '`'

L?\"(\\.|[^\\"])*\"             return 'STRING_LITERAL'
(\b"true"\b)|(\b"false"\b)      return 'BOOL_LITERAL'
\b[0-9]*\.[0-9]+\b              return 'NUMBER_LITERAL'
\b[0-9]+\b                      return 'NUMBER_LITERAL'
\b0x[0-9a-fA-F]+\b              return 'NUMBER_LITERAL'
\b0o[0-7]+\b                    return 'NUMBER_LITERAL'
\b0b[01]+\b                     return 'NUMBER_LITERAL'
\b[a-zA-Z_]+[0-9a-zA-Z_]*\b      return 'IDENTIFIER'

"("                             return '('
")"                             return ')'
"{"                             return '{'
"}"                             return '}'
":"                             return ':'
","                             return /* ignore comma */
"."                             return '.'

"#".*\n                         return 'NEWLINE' /* ignore comments */
[ \t]+                          /* ignore whitespaces */
\n                              return 'NEWLINE'
<<EOF>>                         return 'EOF'
.                               return 'INVALID'

/lex

%start task

%% /* language grammar */

task
    : taskheader '{' taskbody '}' whitespaces EOF
        { 
            $$ = { header: $1, body: $3 };
            $$.body.id = $$.header.id;

            for(var i = 0; i < $$.body.states.length; i++) {
                $$.body.states[i].body.parent = $$.body;
            }
            $$.body.init_state.body.parent = $$.body;

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
            $$ = { init_state: $1 , members: [], states: [] };
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
    : instructions whitespaces
        {
            $$ = { members: $1.members, states: $1.states, expressions: $1.expressions };
            for(var i = 0; i < $$.expressions.length; i++) {
                if($$.expressions[i].left) $$.expressions[i].left.parent = $$;
                if($$.expressions[i].right) {
                    $$.expressions[i].right.parent = $$;
                    if($$.expressions[i].right.body) $$.expressions[i].right.body.parent = $$;
                }
                if($$.expressions[i].transition) $$.expressions[i].transition.parent = $$;
            }
        }
    | whitespaces
        {
            $$ = { members: [], states: [], expressions: [] };
        }
    ;

instructions
    : instructions state_declaration
        {
            $1.states.push($2)
            $$ = { members: $1.members, states: $1.states, expressions: $1.expressions };
        }
    | instructions member_declaration
        {
            $1.members.push($2)
            $$ = { members: $1.members, states: $1.states, expressions: $1.expressions };
        }
    | instructions expression
        {
            $1.expressions.push($2)
            $$ = { members: $1.members, states: $1.states, expressions: $1.expressions };
        }
    | state_declaration
        {
            $$ = { members: [], states: [$1], expressions: [] };
        }
    | member_declaration
        {
            $$ = { members: [$1], states: [], expressions: [] };
        }
    | expression
        {
            $$ = { members: [], states: [], expressions: [$1] };
        }
    ;

expression
    : whitespaces IDENTIFIER '=' operations NEWLINE
        {
            $$ = { left: { id: $2 } , operation: $3 , right: $4 };
        }
    | whitespaces IDENTIFIER '=' operations transition NEWLINE
        {
            $$ = { left: { id: $2 } , operation: $3 , right: $4 , transition: $5};
        }
    | whitespaces transition NEWLINE
        {
            $$ = { operation: 'transition', transition: $2 };
        }
    | whitespaces YIELD operations NEWLINE
        {
            $$ = { operation: $2 , right: $3 };
        }
    | whitespaces FINISH NEWLINE
        {
            $$ = { operation: $2 };
        }
    ;

operations
    : whitespaces value
        {
            $$ = $2;
        }
    
    | whitespaces value binary_operator operations
        {
            $$ = { left: $2 , operation: $3 , right: $4 };
            $$.left.parent = $$;
            $$.right.parent = $$;
        }
    | whitespaces '(' operations whitespaces ')'
        {
            $$ = { group: $3 };
            $$.group.parent = $$;
        }
    | whitespaces unary_operator operations
        {
            $$ = { operation: $2 , right: $3 };
            $$.right.parent = $$;
        }
    ;

transition
    : '->' whitespaces state_id
        {
            $$ = { block: true , id: $3 , parameters: [] }
        }
    | '->' whitespaces state_id '(' parameters ')'
        {
            $$ = { block: false , id: $3 , parameters: $5 }
        }
    |'-->' whitespaces state_id
        {
            $$ = { block: true , id: $3 , parameters: [] }
        }
    | '-->' whitespaces state_id '(' parameters whitespaces ')'
        {
            $$ = { block: false , id: $3 , parameters: $5}
        }
    ;

state_id
    : IDENTIFIER
    | INIT
    ;

parameters
    : parameters parameter
        {
            $1.application.push($1);
            $$ = { application: $1.application };
        }
    | parameter
        {
            $$ = { application: [$1] };
        }
    ;

parameter
    : whitespaces IDENTIFIER whitespaces ':' operations
        {
            $$ = { id: $2 , value: $5 };
        }
    ;

binary_operator
    : '+'
    | '-'
    | '*'
    | '/'
    | '='
    | AND
    | NAND
    | OR
    | NOR
    | XOR
    | '++'
    | '<'
    | '>'
    | '<='
    | '>='
    | '=='
    | '&'
    | '|'
    | '^'
    ;

unary_operator
    : '!'
    | '-'
    | '`'
    ;


member_declaration
    : whitespaces semantics IDENTIFIER whitespaces ':' whitespaces type NEWLINE
        {
            $$ = { id: $3, type: $7 , semantics: $2};
        }
    | whitespaces IDENTIFIER whitespaces ':' whitespaces type NEWLINE
        {
            $$ = { id: $2, type: $6 , semantics: { scope_semantic: 'private', monadic_semantic: 'just', action_semantic: 'data' } };
        }
    ;

state_declaration
    : whitespaces IDENTIFIER whitespaces ':' whitespaces '{' statebody '}' NEWLINE
        {
            $$ = { id: $2, body: $7 , parameter_declarations: { signature:[] } , semantics: { scope_semantic: 'static', monadic_semantic: 'just', action_semantic: 'state' } };
            $$.body.id = $$.id;
            $$.body.parameter_declarations = $$.parameter_declarations;
        }
    | whitespaces IDENTIFIER whitespaces ':' whitespaces '(' parameter_declarations whitespaces ')' whitespaces '{' statebody '}' NEWLINE
        {
            $$ = { id: $2, body: $12, parameter_declarations: $7 , semantics: { scope_semantic: 'static', monadic_semantic: 'just', action_semantic: 'state' }};
            $$.body.id = $$.id;
            $$.body.parameter_declarations = $$.parameter_declarations;
        }
    ;

parameter_declarations
    : parameter_declarations parameter_declaration
        {
            $1.signature.push($2);
            $$ = { signature: $1.signature };
        }
    | parameter_declaration
        {
            $$ = { signature: [$1] }
        }
    ;

parameter_declaration
    : whitespaces semantics IDENTIFIER whitespaces ':' whitespaces type
        {
            $$ = { id: $3, type: $7, semantics: $2 };
        }
    | whitespaces IDENTIFIER whitespaces ':' whitespaces type
        {
            $$ = { id: $2, type: $6, semantics: { scope_semantic: 'private', monadic_semantic: 'just', action_semantic: 'data' } };
        }
    ;

init_state_declaration
    : whitespaces INIT whitespaces ':' whitespaces '{' statebody '}' NEWLINE
        {
            $$ = { id: $2, body: $7, semantics: { scope_semantic: 'static', monadic_semantic: 'just', action_semantic: 'state' } };
        }
    ;

semantics
    : scopesemantic monadicsemantic actionsemantic
        {
            $$ = { scope_semantic: $1, monadic_semantic: $2, action_semantic: $3 };
        }
    | scopesemantic monadicsemantic
        {
            $$ = { scope_semantic: $1, monadic_semantic: $2, action_semantic: 'data' };
        }
    | scopesemantic actionsemantic
        {
            $$ = { scope_semantic: $1, monadic_semantic: 'just', action_semantic: $2 };
        }
    | scopesemantic 
        {
            $$ = { scope_semantic: $1, monadic_semantic: 'just', action_semantic: 'data' };
        }
    | monadicsemantic actionsemantic
        {
            $$ = { scope_semantic: 'private', monadic_semantic: $1, action_semantic: $2 };
        }
    | monadicsemantic 
        {
            $$ = { scope_semantic: 'private', monadic_semantic: $1, action_semantic: 'data' };
        }
    | actionsemantic
        {
            $$ = { scope_semantic: 'private', monadic_semantic: 'just', action_semantic: $1 };
        }
    ;

actionsemantic
    : DATA whitespaces
    | FUTURE whitespaces
    | STATE whitespaces
    | MEMORY whitespaces
    | ELEMENT whitespaces
    ;

monadicsemantic
    : JUST whitespaces
    | MAYBE whitespaces
    | ONCE whitespaces
    ;

scopesemantic
    : PRIVATE whitespaces
    | SHARED whitespaces
    ;

value
    : IDENTIFIER
        {
            $$ = { id: $1 };
        }
    | IDENTIFIER '(' parameters whitespaces ')'
        {
            $$ = { id: $1, parameters: $3 };
        }
    | ':' whitespaces '{' statebody '}'
        {
            function makeid() {
                var text = "";
                var possible = "abcdefghijklmnopqrstuvwxyz";

                for( var i=0; i < 11; i++ )
                    text += possible.charAt(Math.floor(Math.random() * possible.length));

                return 'ANON_'+ text;
            }

            $$ = { id: makeid(), body: $4, parameter_declarations: [] };
            $$.body.id = $$.id;
        }
    | ':' whitespaces '(' parameter_declarations whitespaces ')' '{' statebody '}'
        {
            function makeid() {
                var text = "";
                var possible = "abcdefghijklmnopqrstuvwxyz";

                for( var i=0; i < 11; i++ )
                    text += possible.charAt(Math.floor(Math.random() * possible.length));

                return 'ANON_'+ text;
            }

            $$ = { id: makeid(), body: $8, parameter_declarations: $4 };
            $$.body.id = $$.id;
        }
    | INIT
        {
            $$ = { id: $1 };
        }
    | NUMBER_LITERAL
        {
            $$ = { number: $1 };
        }
    | BOOL_LITERAL
        {
            $$ = { bool: $1 };
        }
    | STRING_LITERAL
        {
            var value = $1.substring(1, $1.length - 1);
            
            // Escapes
            value = value.replace(/\\a/g, '\a');
            value = value.replace(/\\b/g, '\b');
            value = value.replace(/\\f/g, '\f');
            value = value.replace(/\\n/g, '\n');
            value = value.replace(/\\r/g, '\r');
            value = value.replace(/\\t/g, '\t');
            value = value.replace(/\\"/g, '"');
            value = value.replace(/\\/g, '\\');

            $$ = { string: value };
        }
    ;

type
    : value_type
    | value_type '(' parameter_declarations whitespaces ')'
    {
        var pack = function(list) {
            var result = '';
            console.log(list);
            for(var i = 0; i < list.length; i++) {
                result += ', SM<' + list[i].type + '>'
            }
            return result;
        };
        $$ = $1 + pack($3.signature);
    }
    ;

value_type
    : BYTE
    | INT
    | FLOAT
    | STRING
    | BOOL
    | IDENTIFIER
    ;

whitespaces
    : NEWLINE whitespaces
    |
    ;
