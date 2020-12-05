
{.experimental: "callOperator".}
import math
import sequtils
import sugar
import tables
import macros
import macroutils
from fmfobjects import fuzzymemberobject
import utils

proc zip *[T] (sq:seq[seq[T]]): seq[seq[T]] = 
  let 
    n = sq.len
    t = sq[0].len
  for position in 0..t-1:
    var l : seq[T]
    for spot in 0..n-1:
      l.add(sq[spot][position])
    result.add(l)

using
    x:float

type fuzzyfunction* = proc(x:float):float

type fuzzymemberfunction* = fuzzymemberobject | fuzzyfunction

type Fuzzyset* = seq[fuzzymemberfunction]
type Fuzzyvariable*[fmf:fuzzymemberfunction] = ref object
    name*:string
    inputrange*:HSlice[float,float]
    fuzzytable*:OrderedTable[string,fmf]
proc `[]=` *[FMF:fuzzymemberfunction](fuzzy:var Fuzzyvariable[FMF], name:string, fmf:FMF) =
    fuzzy.fuzzytable[name] = fmf

proc `[]` *[fmf:fuzzymemberfunction](fuzzy:Fuzzyvariable[fmf], name:string):fuzzymemberfunction =
    fuzzy.fuzzytable[name]

proc `()` *[fmf:fuzzymemberfunction](fuzzy:Fuzzyvariable[fmf],x): seq[float] =
    for member in fuzzy.fuzzytable.values:
        result.add(member(x))
type FuzzyPair*[FMF:fuzzymemberfunction] = ref object
    variable: Fuzzyvariable[FMF]
    fmf: FMF
    fuzzylinguistic:string
proc `->` *[fmf:fuzzymemberfunction](fuzzy:Fuzzyvariable[fmf], name:string): FuzzyPair[fmf] =
    result = FuzzyPair[fmf](variable:fuzzy,fmf:fuzzy.fuzzytable[name],fuzzylinguistic:name)


type FuzzyOperator = enum
    AND,OR, STRAIGHT

type FuzzyRule*[fmf:fuzzymemberfunction] = ref object
    precedent*:seq[FuzzyPair[fmf]]
    operator*:FuzzyOperator
    antecedent*: FuzzyPair[fmf]

proc calculate *[fmf:fuzzymemberfunction](rule:FuzzyRule[fmf],ante:array, inp:Table[string,float]): auto = 
    var
        antecalc = ante#.applyIt(rule.antecedent.fmf(it))
        val:float
        valueset:seq[float]
    antecalc.applyIt(rule.antecedent.fmf(it))
    for pos, fuzzvar in rule.precedent:
        valueset.add(fuzzvar.fmf(inp[fuzzvar.variable.name]))
    case rule.operator
    of AND:
        val = valueset.min
    of OR:
        val = valueset.max
    of STRAIGHT:
        val = valueset[0]
    result = min(antecalc,val)

proc `&` *[fmf:fuzzymemberfunction](fp1,fp2:FuzzyPair[fmf]): FuzzyRule[fmf] =
    result = FuzzyRule[fmf]()
    result.precedent = @[fp1,fp2]
    result.operator = AND
proc `&` *[fmf:fuzzymemberfunction](fa: var FuzzyRule[fmf],fp:FuzzyPair[fmf]):FuzzyRule[fmf] =
    fa.precedent.add(fp)
    result = fa
proc `and` [fmf:fuzzymemberfunction](fp1,fp2:FuzzyPair[fmf]): FuzzyRule[fmf] =
    result = fp1 & fp2
proc `and` [fmf:fuzzymemberfunction](fa: var FuzzyRule[fmf],fp:FuzzyPair[fmf]):FuzzyRule[fmf] =
    fa & fp
proc `|` *[fmf:fuzzymemberfunction](fp1,fp2:FuzzyPair[fmf]): FuzzyRule[fmf] =
    result = FuzzyRule[fmf]()
    result.precedent = @[fp1,fp2]
    result.operator = OR
proc `|` *[fmf:fuzzymemberfunction](fa: var FuzzyRule[fmf],fp:FuzzyPair[fmf]):FuzzyRule[fmf] =
    fa.precedent.add(fp)
    result = fa
proc `or` *[fmf:fuzzymemberfunction](fp1,fp2:FuzzyPair[fmf]): FuzzyRule[fmf] =
    result = fp1 | fp2
proc `or` *[fmf:fuzzymemberfunction](fa: var FuzzyRule[fmf],fp:FuzzyPair[fmf]): FuzzyRule[fmf] =
    result = fa | fp
proc `=>:` *[fmf:fuzzymemberfunction](fr: FuzzyRule[fmf], fp:FuzzyPair[fmf]):FuzzyRule[fmf] =
    fr.antecedent = fp
    result = fr
proc `=>:` *[fmf:fuzzymemberfunction](fo:FuzzyPair[fmf],fp:FuzzyPair[fmf]):FuzzyRule[fmf] =
    result = FuzzyRule[fmf]()
    result.precedent =  @[fo]
    result.antecedent = fp
    result.operator = STRAIGHT
type FuzzyControlSystem*[fmf:fuzzymemberfunction] = object
    precedent*: seq[Fuzzyvariable[fmf]]
    antecedent*: seq[Fuzzyvariable[fmf]]
    rules*: seq[FuzzyRule[fmf]]

proc calculate *[fmf:fuzzymemberfunction](fcs:FuzzyControlSystem[fmf],inp:Table[string,float]): float =
  
    var 
      ante = linspace(fcs.antecedent[0].inputrange.a, fcs.antecedent[0].inputrange.b, 100)
      aggregate:seq[seq[float]]
    let dx = ante[1] - ante[0]
    for rule in fcs.rules:
        aggregate.add  @(rule.calculate(ante, inp))
    var fin:seq[float]
    var top:seq[float]
    for point in zip(aggregate):
        fin.add (max(point))
    for point in zip(fin,ante):
        top.add point[0] * point[1]
    result = sum(top) / sum(fin)

template fuzzy_converter *(body:typedesc[enum]) =
  converter fuzzy_enum_to_string *(inp:body):string = $inp
  
macro fuzzy_enum *(body:varargs[untyped]): untyped =
  result = StmtList()
  let Enum = EnumTy()
  for val in body:
    Enum.add(EnumFieldDef(newIdentNode(val.repr), newLit(val.repr)))
  result.add(TypeSection(TypeDef(newIdentNode("fuzzy_words"),newEmptyNode(),Enum)))

template fuzzy_values *(body:varargs[untyped]):untyped =
  fuzzy_enum(body)
  fuzzy_converter(fuzzy_words)
