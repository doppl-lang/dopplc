module.exports =
  ast: null
  
  provide: (ast) ->
    @ast = ast
    @ast.body.members.push
      id: 'input'
      type: 'string'
      semantics:
        scope_semantic: 'static'
        monadic_semantic: 'just'
        action_semantic: 'state'
    @ast.body.members.push
      id: 'output'
      type: 'string'
      semantics:
        scope_semantic: 'static'
        monadic_semantic: 'just'
        action_semantic: 'future'
    return
