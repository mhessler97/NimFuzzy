import macros
import tables
import strutils
import strformat
import logicparser
import utils
export utils
import fmftemplates
export fmftemplates
from math import sum
export sum

template paramnode(name:string, slice:Nimnode): Nimnode =
  nnkIdentDefs.newTree(
    newIdentNode(name),
    slice,
    newEmptyNode())

proc addempty(node: var Nimnode,times:int) =
  for _ in 1..times:
    node.add newEmptyNode()


proc apply*[N,T](a:var array[N,T],p:proc) =
  for val in a.mitems:
    val = p(val)

type fuzzyvar = object
    name:string
    values:Table[string, NimNode]
proc `[]`(fv:fuzzyvar,key:string): NimNode =
    fv.values[key]
proc `[]=`(fv: var fuzzyvar,key:string, value:NimNode) =
    fv.values[key] = value

proc fuzzyvarinit(name:string):fuzzyvar {.compileTime.}=
    result.name = name

proc `$`(val:fuzzyvar):string {.compileTime.} =
    result.add val.name & "\n"
    for variable in val.values.keys:
        result.add "\t" & variable & "\n"

template variableparser(line:Nimnode, fuzzy: var fuzzyvar, body: var Nimnode) =
  for function in line[2]:
    let linguistic = function[0].strval
    if function[1].kind == nnkIdent:
      fuzzy[linguistic] = newIdentNode function[1].repr
      
    elif function[1].kind == nnkCall:

      let 
        genfunc = gensym(nskLet, "func")

        asgn = nnkLetSection.newTree(
               nnkIdentDefs.newTree(
               genfunc,
               newEmptyNode(),
               function[1]         )
                                     )
      body.add asgn
      fuzzy[linguistic] = genfunc

proc getprecedent(stmt:string): (string,string) {.compileTime.} =
  var prec_place = stmt.rfind("THEN")
  result[0] = stmt[0 .. prec_place - 2]
  result[1] = stmt[prec_place + 5 .. ^1]

proc generate_rule_AST(r:rule, functable:Table[string, fuzzyvar]):NimNode =
  var op : string
  if r.operation == "OR":
    op = "max"
  elif r.operation == "AND":
    op = "min"
  elif r.operation == "STRAIGHT":

    return nnkCall.newTree(
                    functable[r.seq1[0]][r.seq1[^1]],
                    newIdentNode r.seq1[0]
                          )
  else: 
    discard
  if r.kind == seqtype:
    let first = r.seq1
    let second = r.seq2

    let f1 = nnkCall.newTree(
         functable[first[0]][first[^1]],
         newIdentNode(first[0])
         )
    let f2 = nnkCall.newTree(
         functable[second[0]][second[^1]],
         newIdentNode(second[0])
         )
    result = nnkCall.newTree(newIdentNode(op),f1, f2)
  elif r.kind == ruletype:
    
    result = nnkCall.newTree(newIdentNode(op),generate_rule_AST(r.rule1, functable), generate_rule_AST(r.rule2, functable))

proc ruleparser(line:string, precedents ,
                antecedents:Table[string, fuzzyvar], 
                body: var NimNode, count:int) =


  let 
    stmts = line[3..^1].getprecedent
    ante = stmts[1].split " "
    rules = stmts[0].logicparser
    procedure = generate_rule_AST(rules, precedents)
  var
    rest = line.split " "
    i = 0
    pairs: seq[rule]

  var antecname = antecedents[ante[0]][ante[^1]]

  var antenodes = nnkCall.newTree(
    nnkDotExpr.newTree(
      newIdentNode("antecalc"),
      newIdentNode("apply")
    ),
    antecname
  )
  body.add antenodes

  body.add nnkAsgn.newTree(
    nnkBracketExpr.newTree(
      newIdentNode("aggregate"),
      newLit(count)
      ),nnkCall.newTree(
      newIdentNode("min"),
      newIdentNode("antecalc"),
      procedure))

macro FuzzyControlSystem*(name:untyped, body:untyped):untyped =
  var main = nnkProcDef.newTree()
  result = nnkStmtList.newTree()
  main.add newIdentNode(name.repr)
  main.addempty 2
  let parameters = nnkFormalParams.newTree()
  parameters.add newIdentNode("float")
  var precedents: Table[string, fuzzyvar]
  var antecedents: Table[string, fuzzyvar]
  var procbody = nnkStmtList.newTree()
  let
    precedent = body[0]
    antecedent = body[1]
    rules = body[2]
  var
    lower:float
    upper:float
  for line in precedent[1..^1][0]:

    let 
      paramname = line[0].strval
      parmtree = paramnode(paramname, line[1])
    var fuzzy = fuzzyvarinit(paramname)
    parameters.add parmtree
    variableparser(line, fuzzy, result)

    precedents[fuzzy.name] = fuzzy
  for line in antecedent[1..^1][0]:
    let paramname = line[0].strval
    var fuzzy = fuzzyvarinit(paramname)
    variableparser(line, fuzzy, result)
    antecedents[fuzzy.name] = fuzzy
   
    if line[1][1].kind == nnkFloatLit:
      lower = line[1][1].floatval
    elif line[1][1].kind == nnkPrefix:
      lower = -line[1][1][1].floatval
    if line[1][2].kind == nnkFloatLit:
      upper = line[1][2].floatval
    elif line[1][2].kind == nnkPrefix:
      lower = -line[1][2][1].floatval

  var amount = 10
 
  var lintree = fmt"const ante = linspace({lower},{upper},{amount})".parseStmt
  procbody.add lintree
  procbody.add "var antecalc = ante".parseStmt
  procbody.add fmt"var top : array[{amount}, float]".parseStmt
  procbody.add fmt"var aggregate: array[{len(rules[1..^1][0])}, array[{amount}, float]]".parseStmt

  for i,line in rules[1..^1][0]:
    ruleparser(line.repr, precedents, antecedents, procbody, i)
    procbody.add fmt"antecalc = ante".parseStmt

  var loopstmt = nnkStmtList.newTree()
  loopstmt.add fmt"antecalc[i] = max(slice)".parseStmt
  loopstmt.add fmt"top[i] = antecalc[i] * ante[i]".parseStmt


  var forloop = nnkForStmt.newTree(
    newIdentNode("i"),
    newIdentNode("slice"),
    nnkDotExpr.newTree(
      newIdentNode("aggregate"),
      newIdentNode("enumslices")
    ),loopstmt)
  procbody.add forloop
  procbody.add "result = sum(top) / sum(antecalc)".parsestmt
  main.add parameters
  main.addempty 2
  main.add procbody
  result.add main
  echo result.repr


when isMainModule:
  let
    func1 = trimf(1f, 1f, 5f)
    func2 = trimf(1f, 5f, 10f)
    func3 = trimf(5f, 10f, 10f)

  FuzzyControlSystem(Tipper):
        Precedent:
          quality(1.0..15.0):
            low = func1
            medium = func2
            high = func3
          service(1.0..15.0):
            low = func1
            medium = func2
            high = func3
        Antecedent:
          tip(1.0..26.0):
            low = trimf(0,0,13)
            medium = trimf(0,13,25)
            high = trimf(13,25,25)
        rules:
          IF service IS low OR quality IS low THEN tip IS low
          IF service IS medium THEN tip IS medium
          IF service IS high OR quality IS high THEN tip IS high

  echo Tipper(2,8)