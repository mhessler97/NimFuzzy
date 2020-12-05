import sequtils
import strutils 

type rulekind* = enum
  ruletype,seqtype

type rule* = ref object
    operation*:string
    case kind*:rulekind
    of ruletype:
      rule1*:rule
      rule2*:rule
    of seqtype:
      seq1*:seq[string]
      seq2*:seq[string]
      
proc `$`*(r:rule):string =

  if r.operation == "STRAIGHT":
    return r.seq1.join(" ")
  if r.kind == seqtype:
    result.add r.seq1.join(" ") & " " & r.operation & " " & r.seq2.join(" ")
  elif r.kind == ruletype:
    result.add "(" & $r.rule1 & ") " & r.operation & " (" & $r.rule2 & ")"

proc NewRule(op:string,kind:rulekind): rule =

  result = rule(operation:op.strip,kind:kind)

proc create_statement(stmt:string):rule =
    var splitrule =  stmt.splitWhitespace

    if splitrule.len == 3:
      result = NewRule("STRAIGHT", seqtype)
      result.seq1 = splitrule
    else:
      result = NewRule(splitrule[3],seqtype)
      result.seq1 = splitrule[0..2]
      result.seq2 = splitrule[4..6]
    
proc logicparser*(statement:string):rule =
  type bracketplace = tuple[place:int,kind:char]
  var 
    statement = statement.replace("\n").strip.replace("\\").splitWhitespace.join(" ")
    brackets : seq[bracketplace]

  for i,letter in statement.pairs:
    if letter in ['(',')']:
      brackets.add (i, letter)
  var statements : seq[string]
  var Rules:rule
  var counter = 0
  var lastop:string
  if brackets.len == 0:
    Rules = create_statement(statement)
  while brackets.len > 0:
    var place1 = brackets[counter]
    var op:string
    
    if place1.kind == '(':
      if brackets[counter + 1].kind == ')':
        var place2 = brackets[counter + 1]
        var newrule = create_statement statement[(place1.place + 1)..(place2.place - 1)]
        
        if brackets.len != 2:
          op = statement[(place2.place + 1) .. (brackets[counter + 2].place - 1)]
          if Rules.isNil:
            Rules = newrule
          else:
            var chainrule = NewRule(lastop, ruletype)
            chainrule.rule1 = Rules
            chainrule.rule2 = newrule
            Rules = chainrule
          statements.add op
        else:
          var chainrule = NewRule(lastop, ruletype)
          chainrule.rule1 = Rules
          chainrule.rule2 = newrule
          Rules = chainrule
       
        lastop = op
        brackets.delete(counter, counter + 1)
  
      else:
        counter += 1
    else:
      counter -= 1
      if counter == -1:
        break
  result = Rules
when isMainModule:
  let statement1 = """(error IS nb AND delta IS nb) OR 
  (error IS ns AND delta IS nb) OR (error IS nb AND delta IS ns)"""
  let statement2 = "service IS low OR quality IS low"
  let statement3 = """(error IS nb AND delta IS ze) OR (error IS nb AND delta IS ps) OR (error IS ns AND delta IS ns) OR \
           (error IS ns AND delta IS ze) OR (error IS ze AND delta IS ns) OR (error IS ze AND delta IS nb) OR \
           (error IS ps AND delta IS nb)"""
  echo statement1.logicparser
  echo statement2.logicparser
  echo statement3.logicparser