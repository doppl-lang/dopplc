module.exports = {
    ast: null,
    provide: function(ast) {
        this.ast = ast;
        this.ast.body.members.push({
            id: 'input',
            type: 'string',
            semantics: {
                scope_semantic: 'shared',
                monadic_semantic: 'just',
                action_semantic: 'state'
            }
        });
        this.ast.body.members.push({
            id: 'output',
            type: 'string',
            semantics: {
                scope_semantic: 'shared',
                monadic_semantic: 'just',
                action_semantic: 'future'
            }
        });
    }
};