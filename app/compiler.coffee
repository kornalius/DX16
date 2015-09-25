module.exports.compile = (ast) ->

  generate_args = (args) ->
    l = []
    for a in args
      if a._type == 'block'
        l.push(generate_block(a.body))
      else
        l.push(generate(a))
    return l.join(',')

  generate_block = (node) ->
    s = '{'
    if _.isArray(node)
      for n in node
        s += generate(n)
    else if node._type == 'block'
      return generate_block(node.body)
    s += '}'
    return s

  generate = (node) ->
    statements = []

    if _.isArray(node)
      generate(n) for n in node
    else
      switch node?._type
        when 'block'
          statements.push("function #{generate_block(node.body)};")

        when 'fun'
          statements.push "#{node.name} = function (#{generate_args(node.args)}) #{generate_block(node.body)};"

        when 'assign'
          statements.push "#{node.name} = #{generate(node.expr)};"

        when 'if'
          statements.push "if #{generate(node.expr)} #{generate_block(node.t)}#{if node.f? then ' else ' + generate(node.f) else ''}"

        when 'call'
          if node.name in '-,+,*,/,>,<,>,==,<=,>=,!='.split(',')
            statements.push "(#{generate(node.args[0])} #{node.name} #{generate(node.args[1])})"
          else if node.name.name?.toLowerCase() == 'if'
            statements.push "if (#{generate(node.args[0])}) #{generate_block(node.args[1].body)}#{if node.args.length == 3 then ' else ' + generate_block(node.args[2].body) else ''}"
          else
            statements.push "#{node.name.name}(#{generate_args(node.args)});"

        when 'str'
          statements.push "'#{node.value}'"

        when 'num'
          statements.push "#{node.value}"

        when 'bool'
          statements.push "#{node.value}"

        when 'var'
          statements.push node.name

        when 'funvar'
          statements.push node.name

        when 'arr'
          statements.push "[#{generate_args(node.values)}]"

    return statements.join(' ')


  l = []
  for a in ast
    l.push(generate(a))
  return l.join('\n')
