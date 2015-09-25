{
  var vars = {};

  function create_var (name) {
    vars[name] = "var";
  };

  function create_fun (name) {
    vars[name] = "fun";
  };

  function is_var (name) {
    return vars[name] === "var";
  };

  function is_fun (name) {
    return vars[name] === "fun";
  };

  function is_var_or_fun (name) {
    return is_var(name) || is_fun(name);
  };

  function gen(type, options) {
    console.log(type, JSON.stringify(options), ' --> ', JSON.stringify(location()));
    return _.extend({ type: type }, options)
  }
}

start
  = statement*

statement
  = e:if_statement eol* { return e }
  / e:for_statement eol* { return e }
  / e:function_def_statement eol* { return e }
  / e:function_call_statement eol* { return e }
  / e:block eol* { return e }
  / e:expr eol* { return e }
  / e:assign_statement eol* { return e }
  / eol+ { return null }

block
  = lbrace body:statement* rbrace { console.log("block", JSON.stringify(location())); return body }

function_def_statement
  = def name:id args:(function_def_arguments)? e:block { create_fun(name); return gen("fundef", { name: name, args: args, body: e }) }

function_call_statement
  = name:function_variable args:(function_call_arguments)? { return gen("funcall", { name: name, args: args }) }

function_call_arguments
  = left:expr rest:(comma e:expr { return e })* { console.log(left, rest); return rest ? [left].concat(rest) : [left] }

function_def_arguments
  = left:id rest:(e:id { return e })* { return rest ? [left].concat(rest) : [left] }

if_statement
  = if e:expr t:block f:else_statement? { return gen("if", { expr: e, t: t, f: f }) }

else_statement
  = else body:block { return body }
  / else i:if { return i }

for_statement
  = for name:id in each:variable body:block { return gen("for", { name: name, each: each, body: body }) }
  / for name:id min:expr max:expr body:block { return gen("for", { name: name, min: min, max: max, body: body }) }

assign_statement
  = v:id assign e:expr { create_var(v); return gen("assign", { name: v, expr: e }) }

expr
  = left:term op:expr_ops right:expr { return gen("call", { name:op, args:[left, right] }) }
  / term

term
  = left:factor op:term_ops right:term { return gen("call", { name: op, args:[left, right] }) }
  / factor

factor
  = value
  / lparen e:expr rparen { return e }

id
  = _ !reserved l:[a-z_]i r:$[a-z0-9_]i* { return l + (r || "") }

variable
  = v:id &{ return is_var(v) } { return gen("var", { name: v }) }

function_variable
  = v:id &{ return is_fun(v) } { return v }

number
  = _ num:(hex / float / integer / octal / binary / boolean) { return num }

integer
  = [+-]? [0-9]+ exponent? { return gen("num", { value: parseInt(text(), 10) }) }

float
  = [+-]? [0-9]+ "." [0-9]+ exponent? { return gen("num", { value: parseFloat(text()) }) }

hex
  = "0x"i digits:$[0-9a-f]i+ { return gen("num", { value: parseInt(digits, 16) }) }

octal
  = "0o"i digits:$[0-7]i+ { return gen("num", { value: parseInt(digits, 8) }) }

binary
  = "0b"i digits:$[01]i+ { return gen("num", { value: parseInt(digits, 2) }) }

exponent
  = [eE] [+-] integer

boolean
  = _ v:("true"i / "false"i) { return gen("num", { value: v === "true" }) }

string
  = _ "'" chars:$string_char* "'" { return gen("str", { value: chars }) }

string_char
  = !("'" / "\\" / eol) . { return text() }
  / "\\" sequence:escape_char { return sequence }
  / "\\" eol { return "" }

escape_char
  = "'"
  / "\\"
  / "b"  { return "\b" }
  / "f"  { return "\f" }
  / "n"  { return "\n" }
  / "r"  { return "\r" }
  / "t"  { return "\t" }
  / "v"  { return "\x0B" }

array
  = lbracket left:expr rest:(comma v:expr { return v })* rbracket { return gen("arr", { values: rest ? [left].concat(rest) : [left] }) }
  / lbracket rbracket { return gen("arr", { values: [] }) }

value
  = variable
  / number
  / array
  / string

expr_ops
  = _ "+" { return "+" }
  / _ "-" { return "-" }
  / _ "and" { return "and" }
  / _ "or" { return "or" }
  / _ "<" { return "<" }
  / _ ">" { return ">" }
  / _ "<=" { return "<=" }
  / _ ">=" { return ">=" }
  / _ "!=" { return "!=" }
  / _ "==" { return "==" }

term_ops
  = _ "*" { return "*" }
  / _ "/" { return "/" }

reserved
  = "if"i
  / "else"i
  / "def"i
  / "for"i
  / "in"i
  / "and"i
  / "or"i

comma
  = _ ","

lparen
  = _ "("

rparen
  = _ ")"

lbrace
  = (eol / _) "{"

rbrace
  = (eol / _) "}"

lbracket
  = _ "["

rbracket
  = _ "]"

assign
  = _ "=" { return "=" }

def
  = _ "def"i ws+

if
  = _ "if"i ws+

else
  = (eol? / _) "else"i (eol / _)

for
  = _ "for"i ws+

in
  = ws+ "in"i ws+

comment
  = ";" (!cr .)*

ws
  = [ \t]

_
  = ws*

eol
  = _ comment* cr { return null }

cr
  = "\n"
