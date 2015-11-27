mustache = require 'mustache'
fs = require 'fs'
util = require 'util'
ast = undefined

#Dictionary of abstract syntax tree (initialized after parse)
compileSuccess = true

setGlobalAst = (newAst) ->
  ast = newAst
  return

solveYield = (instruction) ->
  solveOperation instruction.right

solveNumber = (instruction) ->
  number = instruction.number
  console.log 'Checking number:    ' + number
  if number.search('0x') != -1
    'int'
  else if number.search('0o') != -1
    explode = number.split('o')
    instruction.number = '0' + explode[1]
    'int'
  else if number.search('0b') != -1
    'int'
  else if number.search(/\./) != -1
    'float'
  else
    'int'

typeOfSymbol = (symbol, cursor, scope) ->
  console.log 'Checking symbol:    ' + symbol.id

  if !cursor
    # TODO : error (symbol is not defined)
    console.log '\'' + symbol.id + '\' is not defined'
    compileSuccess = false
    return

  console.log 'Cursor on:     ' + (if cursor.id then cursor.id else '')
  
  #if(cursor.id && cursor.id === '') console.log(util.inspect(cursor, {showHidden: false, depth: 1}));
  if cursor.body
    return solveState(cursor)
  if cursor.members
    found = false
    #Check current state
    if cursor.id == symbol.id
      if scope
        scope = cursor.id + '/' + scope
      else
        scope = cursor.id
      if cursor.type
        return cursor.type
      else
        return solveState(cursor)
    
    #console.log("Crawling scope:     " + scope);
    # Check members
    i = 0
    while i < cursor.members.length
      if cursor.members[i].id == symbol.id
        symbol.type = solveMember(cursor.members[i])
        found = true
        return symbol.type
      i++
    
    #Check states
    i = 0
    while i < cursor.states.length
      if cursor.states[i].id == symbol.id
        symbol.type = solveState(cursor.states[i])
        if symbol.parameters
          if symbol.parameters.application
            type = symbol.type.split(', ')
            
            j = 0
            while j < symbol.parameters.application.length
              key = symbol.parameters.application[j].id
              if cursor.states[i].parameter_declarations
                if cursor.states[i].parameter_declarations.signature
                  k = 0
                  while k < cursor.states[i].parameter_declarations.signature.length
                    if cursor.states[i].parameter_declarations.signature[k].id == key
                      if type[k + 1]
                        type[k + 1] = ''
                    k++
              j++

            appliedType = []
            j = 0
            while j < type.length
              if type[j] != ''
                appliedType.push type[j]
              j++

            symbol.type = appliedType.join(', ')

        found = true
        return symbol.type
      i++

    #Check parameter declarations
    if cursor.parameter_declarations
      i = 0
      while i < cursor.parameter_declarations.signature.length
        console.log 'Signature:    ' + cursor.parameter_declarations.signature[i].id
        if cursor.parameter_declarations.signature[i].id == symbol.id
          symbol.type = solveMember(cursor.parameter_declarations.signature[i])
          found = true
          return symbol.type
        i++

    typeOfSymbol symbol, cursor.parent, scope
  else
    typeOfSymbol symbol, cursor.parent, scope

solveOperation = (instruction) ->
  result = undefined

  if instruction.type
    return instruction.type

  if instruction.left

    if instruction.transition
      solveOperation instruction.transition

    if instruction.left.id
      result = typeOfSymbol(instruction.left, instruction.left)
      if result == undefined
        # TODO : error (symbol is not defined)
        compileSuccess = false
        return result
    else
      result = solveOperation(instruction.left)

    if instruction.right
      rightResult = solveOperation(instruction.right)
      if result == rightResult or result == 'byte' and rightResult == 'int'
        return result
      else
        # TODO: error (type mismatch on operation)
        console.log 'Left hand type is not the same as right hand type'
        compileSuccess = false
        return result

    return result

  else if instruction.id
    result = typeOfSymbol(instruction, instruction)
    if result == undefined
      # TODO : error (symbol is not defined)
      console.log '\'' + instruction.id + '\' is not defined'
      compileSuccess = false
    return result

  else if instruction.number
    instruction.type = solveNumber(instruction)
    return instruction.type

  else if instruction.bool
    instruction.type = 'bool'
    return instruction.type

  else if instruction.string
    instruction.type = 'string'
    return instruction.type

  else if instruction.group
    instruction.type = solveOperation(instruction.group)
    return instruction.type

  return

solveMember = (member) ->
  console.log 'Solving member: ' + member.id
  if member.semantics.action_semantic == 'data'
    member.semantics.action_semantic = 'DM'
  if member.semantics.action_semantic == 'future'
    member.semantics.action_semantic = 'FM'
  if member.semantics.action_semantic == 'state'
    member.semantics.action_semantic = 'SM'
  member.type

solveState = (state) ->
  console.log 'Solving state:      ' + state.id
  if state.type
    return state.type

  result = undefined
  if state.body

    if state.semantics
      if state.semantics.action_semantic == 'data'
        state.semantics.action_semantic = 'DM'
      if state.semantics.action_semantic == 'future'
        state.semantics.action_semantic = 'FM'
      if state.semantics.action_semantic == 'state'
        state.semantics.action_semantic = 'SM'

    state.body.expressions.forEach (expression) ->
      switch expression.operation
        when 'yield'
          result = solveYield(expression)
        when 'transition'
          result = solveState(expression.transition)
        when 'finish'
        else
          result = solveOperation(expression)
          break
      return

    state.body.states.forEach solveState
    state.body.members.forEach solveMember

    yields = state.body.expressions.filter ((expression) ->
      expression.operation == 'yield'
    )

    if yields.length
      yieldType = undefined
      i = 0
      while i < yields.length
        if !yieldType
          yieldType = solveYield(yields[i])
        else if yieldType != yields[i].type
          # TODO : error (yield types does not match)
          console.log 'Yield types does not match.'
          compileSuccess = false
          yieldType = undefined
          break
        i++
      result = yieldType
    else
      result = 'void'

    if state.parameter_declarations
      if state.parameter_declarations.signature
        j = 0
        while j < state.parameter_declarations.signature.length
          result += ', SM<' + state.parameter_declarations.signature[j].type + '>'
          j++
  else
    result = typeOfSymbol(state, state)
    if result == undefined
      # TODO : error (symbol is not defined)
      compileSuccess = false

  state.type = result

  # if state.id.substring(0, 4) == 'ANON'
  #    state.parent.states.push state

  result

module.exports =
  generate: (ast) ->
    setGlobalAst ast

    ast.body.states.forEach solveState
    solveState ast.body.init_state
    ast.body.members.forEach solveMember

    view = {}
    view.header = ast.header
    view.private_members = ast.body.members.filter((member) ->
      member.semantics.scope_semantic == 'private'
    )
    view.shared_members = ast.body.members.filter((member) ->
      member.semantics.scope_semantic == 'shared'
    )

    view.states = ast.body.states
    view.states.push ast.body.init_state

    render_expression = (expression) ->
      console.log 'Expression'
      console.log expression
      
      result = 
        str: ''

      switch
        when expression.id?
          if expression.parameters? and !(util.isArray expression.parameters)
            console.log expression.para
            expression.parameters.application = expression.parameters.application.sort (a,b) -> if a.id < b.id then -1 else 1

            result.str = result.str + '(FM<' + expression.type + '>(' + expression.id + ', false, '

            for app in expression.parameters.application
              result.str = result.str + (render_expression app.value) + ', '
            result.str = result.str.slice 0, -2

            result.str = result.str + ')).get() '
          else
            result.str = result.str + expression.id

        when expression.number?
          result.str = result.str + expression.number

        when expression.bool?
          result.str = result.str + expression.bool

        when expression.string?
          result.str = result.str + '"' + expression.string + '"'

        when expression.group?
          result.str = result.str + '( ' + (render_expression expression.group) + ' )'

        else
          switch
            when expression.operation is 'yield'
              result.str = result.str + 'yield.set_value(' + (render_expression expression.right) + ') '
            when expression.operation is 'transition'
              result.str = result.str + 'next.set(' + (render_expression expression.transition) + ');return '
            when expression.operation is 'finish'
              result.str = result.str + 'next.set(finish);return'
            else
              

              if expression.operation is '++'
                expression.operation = '+'

              if expression.operation is '='
                if expression.right? and expression.right.body? and expression.right.id? and expression.right.id.substring(0, 4) == 'ANON'
                  result.str = result.str + 'SM<' + expression.right.type + '> ' + expression.right.id + ';\n'
                  result.str = result.str + render_state_body expression.right

                result.str = result.str + (render_expression expression.left)
                result.str = result.str + '.set( '
                result.str = result.str + (render_expression expression.right) + ') '
              else
                result.str = result.str + (render_expression expression.left)
                result.str = result.str + ' ' + expression.operation
                if expression.right
                  result.str = result.str + ' ' + (render_expression expression.right) + '.get() '

  
      console.log result.str
      expression.expression_bodie = result.str
    
    render_state_body = (state1, captureByRef) ->
      state1.body.expressions.forEach (e) -> e.expression_bodie = (render_expression e) + ';\n'

      state1.body.states.forEach (state2) ->
        state2.body.expressions.forEach render_expression

        render_state_body state2

      template = if captureByRef? then 'task_state_bodies.mustache' else 'state_bodies.mustache'
      state1.state_bodie = mustache.render (fs.readFileSync template, 'utf8'), state1
    
    ast.body.states.forEach (s) -> render_state_body s, true

    output = mustache.render (fs.readFileSync 'doppl.cpp.mustache', 'utf8'), view
    result =
      error: !compileSuccess
      output: output
    result
