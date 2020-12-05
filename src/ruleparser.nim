type variable = object
  name:string

type statement = ref object
  name:variable
  value:string

type operation = enum
  AND,OR,STRAIGHT

type logickind = enum
  statementkind, treekind


type tree = ref object
  op:operation
  case firstkind:logickind
  of statementkind:
    statement1:statement
  of treekind:
    tree1:tree
  case secondkind:logickind
  of statementkind:
    statement2:statement
  of treekind:
    tree2:tree
    
proc `$`(s:statement):string =
  result = $s.name.name & " is " & $s.value
  
proc `$`(t:tree):string =
  if t.firstkind == statementkind:
    result.add $t.statement1
  elif t.firstkind == treekind:
    result.add $t.tree1
  if t.op == AND:
    result.add " and "
  elif t.op == OR:
    result.add " or "
  if t.secondkind == statementkind:
    result.add $t.statement2
  elif t.secondkind == treekind:
    result.add $t.tree2

proc Newtree(op:operation,firstkind, secondkind:logickind):tree =
  result = tree(op:op,firstkind:firstkind,secondkind:secondkind)
  
template generate_rules(operator,operatorenum:untyped):untyped =
  proc `operator`(s1:statement,s2:statement):tree = 
    result = Newtree(operatorenum,statementkind,statementkind)
    result.statement1 = s1
    result.statement2 = s2

  proc `operator`(s1:statement,t2:tree):tree = 
    result = Newtree(operatorenum,statementkind,treekind)
    result.statement1 = s1
    result.tree2 = t2

  proc `operator`(t1:tree,t2:tree):tree = 
    result = Newtree(operatorenum,treekind,treekind)
    result.tree1 = t1
    result.tree2 = t2

  proc `operator`(t1:tree,s2:statement):tree = 
    result = Newtree(operatorenum,treekind,statementkind)
    result.tree1 = t1
    result.statement2 = s2

proc `->`(name:variable,value:string):statement = 
  result = new statement
  result.name = name
  result.value = value

generate_rules(`and`,AND)
generate_rules(`or`, OR)
var quality = variable(name:"quality")
var food = variable(name:"food")
var service = variable(name:"service")

var rule = ((quality -> "low") and (food -> "bad")) or (service -> "poor")
echo rule

a:seq[string]





    
