var mustache = require('mustache');
var fs = require('fs');

var ast;            //Dictionary of abstract syntax tree (initialized after parse)
var sym = {};       //Dictionary of symbols
var compileSuccess = true;

function setGlobalAst(newAst) {
    ast = newAst;
}

function solveYield(instruction) {
    return solveOperation(instruction.right);
}

function solveNumber(number) {
    // TODO : check regex to decide if byte, int or float
}

function typeOfSymbol(symbol) {
    // TODO : crawl parents to decide type, 
    //        if not found add symbol to symbol table and solve if necessary
    console.log("Checking symbol:    " + symbol);
}

function solveOperation(instruction) {
    if (instruction.left) {
        var result;
        if (instruction.left.id) {
            result = typeOfSymbol(instruction.left.id);
            if (result === undefined) {
                // TODO : error (symbol is not defined)
                compileSuccess = false;
                result = 'invalid';
            }
        } else {
            result = solveOperation(instruction.left);
        }

        if (instruction.transition) {
            solveOperation(instruction.transition);
        }

        if (result === solveOperation(instruction.right)) return result;
        else {
            // TODO: error (type mismatch on operation)
            compileSuccess = false;
            return result;
        }
    } else if (instruction.id) {
        return typeOfSymbol(instruction.id);
    } else if (instruction.number) {
        return solveNumber(instruction.number);
    } else if (instruction.bool) {
        return 'bool';
    } else if (instruction.string) {
        return 'string';
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
}

function solveState(state) {
    console.log("Solving state: " + state.id);
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
    } else {
        result = typeOfSymbol(state.id);
    }

    // TODO : compare all yield types
    
    state.type = result;
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
        ast.body.states.forEach(solveState);

        var output = mustache.render(fs.readFileSync("doppl.cpp.template", "utf8"), view);
        return { error: !compileSuccess, output: output};
    }
};