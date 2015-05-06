var mustache = require('mustache');
var fs = require('fs');
var util = require('util');

var ast; //Dictionary of abstract syntax tree (initialized after parse)
var sym = {}; //Dictionary of symbols
var compileSuccess = true;

function setGlobalAst(newAst) {
    ast = newAst;
}

function solveYield(instruction) {
    return solveOperation(instruction.right);
}

function solveNumber(instruction) {
    var number = instruction.number;
    console.log("Checking number:    " + number);
    if (number.search('0x') !== -1) {
        return 'int';
    } else if (number.search('0o') !== -1) {
        var explode = number.split('o');
        instruction.number = '0' + explode[1];
        return 'int';
    } else if (number.search('0b') !== -1) {
        return 'int';
    } else if (number.search('.') !== -1) {
        return 'float';
    } else {
        return 'int';
    }
}

function typeOfSymbol(symbol, cursor, scope) {
    // TODO : crawl parents to decide type, 
    //        if not found add symbol to symbol table and solve if necessary
    console.log("Checking symbol:    " + symbol.id);

    if (!cursor) {
        // TODO : error (symbol is not defined)
        console.log("'" + symbol.id + "' is not defined");
        compileSuccess = false;
        return undefined;
    }

    console.log("Cursor on:     " + (cursor.id ? cursor.id : ''));
    //if(cursor.id && cursor.id === '') console.log(util.inspect(cursor, {showHidden: false, depth: 1}));

    if (cursor.body) return solveState(cursor);


    if (cursor.members) {
        var found = false;

        //Check current state
        if (cursor.id === symbol.id) {
            if (scope) scope = cursor.id + '/' + scope;
            else scope = cursor.id;

            if (cursor.type) return cursor.type;
            else return solveState(cursor);
        }

        //console.log("Crawling scope:     " + scope);

        // Check members
        for (var i = 0; i < cursor.members.length; i++) {
            if (cursor.members[i].id === symbol.id) {
                symbol.type = solveMember(cursor.members[i]);
                found = true;
                return symbol.type;
            }
        }

        //Check states
        for (i = 0; i < cursor.states.length; i++) {
            if (cursor.states[i].id === symbol.id) {
                // TODO : compare symbol.application with cursor.states[i].parameter_declarations
                symbol.type = solveState(cursor.states[i]);
                found = true;
                return symbol.type;
            }
        }

        //Check parameter declarations
        if (cursor.parameter_declarations) {
            for (i = 0; i < cursor.parameter_declarations.signature.length; i++) {
                console.log("Signature:    " + cursor.parameter_declarations.signature[i].id);
                if (cursor.parameter_declarations.signature[i].id === symbol.id) {
                    symbol.type = solveMember(cursor.parameter_declarations.signature[i]);
                    found = true;
                    return symbol.type;
                }
            }
        }

        return typeOfSymbol(symbol, cursor.parent, scope);
    } else {
        return typeOfSymbol(symbol, cursor.parent, scope);
    }

}

function solveOperation(instruction) {
    var result;

    if (instruction.type) return instruction.type;

    if (instruction.left) {
        if (instruction.transition) {
            solveOperation(instruction.transition);
        }

        if (instruction.left.id) {
            result = typeOfSymbol(instruction.left, instruction.left);
            if (result === undefined) {
                // TODO : error (symbol is not defined)
                compileSuccess = false;
                return result;
            }
        } else {
            result = solveOperation(instruction.left);
        }


        if (instruction.right) {
            var rightResult = solveOperation(instruction.right);
            if (result === rightResult || (result === 'byte' && rightResult === 'int')) return result;
            else {
                // TODO: error (type mismatch on operation)
                console.log("Left hand type is not the same as right hand type");
                compileSuccess = false;
                return result;
            }
        }

        return result;
    } else if (instruction.id) {
        result = typeOfSymbol(instruction, instruction);
        if (result === undefined) {
            // TODO : error (symbol is not defined)
            console.log("'" + instruction.id + "' is not defined");
            compileSuccess = false;
        }
        return result;
    } else if (instruction.number) {
        instruction.type = solveNumber(instruction);
        return instruction.type;
    } else if (instruction.bool) {
        instruction.type = 'bool';
        return instruction.type;
    } else if (instruction.string) {
        instruction.type = 'string';
        return instruction.type;
    } else if (instruction.group) {
        instruction.type = solveOperation(instruction.group);
        return instruction.type;
    }
}

function solveMember(member) {
    console.log("Solving member: " + member.id);
    if (member.semantics.action_semantic === 'data') {
        member.semantics.action_semantic = 'DM';
    }
    if (member.semantics.action_semantic === 'future') {
        member.semantics.action_semantic = 'FM';
    }
    if (member.semantics.action_semantic === 'state') {
        member.semantics.action_semantic = 'SM';
    }
    return member.type;
}

function solveState(state) {
    console.log("Solving state:      " + state.id);

    if (state.type) return state.type;

    var result;
    if (state.body) {
        state.body.expressions.forEach(function(expression) {
            switch (expression.operation) {
                case 'yield':
                    result = solveYield(expression);
                    break;
                case 'transition':
                    result = solveState(expression.transition);
                    break;

                case 'finish':
                    break;
                default:
                    result = solveOperation(expression);
                    break;
            }
        });

        state.body.states.forEach(solveState);

        var yields = state.body.expressions.filter(function(expression) {
            return expression.operation === 'yield';
        });

        if (yields.length) {
            var yieldType;
            for (var i = 0; i < yields.length; i++) {
                if (!yieldType) yieldType = solveYield(yields[i]);
                else if (yieldType !== yields[i].type) {
                    // TODO : error (yield types does not match)
                    console.log('Yield types does not match.');
                    compileSuccess = false;
                    yieldType = undefined;
                    break;
                }
            }
            result = yieldType;
        } else {
            result = 'void';
        }
    } else {
        result = typeOfSymbol(state, state);
        if (result === undefined) {
            // TODO : error (symbol is not defined)
            compileSuccess = false;
        }
    }

    state.type = result;
    return result;
}

module.exports = {
    generate: function(ast) {
        setGlobalAst(ast);

        var view = {};

        view.header = ast.header;

        view.private_members = ast.body.members.filter(function(member) {
            return member.semantics.scope_semantic === 'private';
        });

        view.shared_members = ast.body.members.filter(function(member) {
            return member.semantics.scope_semantic === 'shared';
        });

        solveState(ast.body.init_state);
        //ast.body.states.forEach(solveState);

        var output = mustache.render(fs.readFileSync("doppl.cpp.mustache", "utf8"), view);
        return {
            error: !compileSuccess,
            output: output
        };
    }
};