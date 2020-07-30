
{.experimental: "callOperator".}
import math
import sequtils
import sugar
import tables
import macros
import macroutils

proc linspace *(start, final, step: float): seq[float] =
  var 
    current = start
    sequence = newSeq[float](0)
  while current <= final:
    sequence.add(current)
    current += step
  return sequence

proc seqmin *[T:SomeNumber](a,b:openarray[T]): seq[T] =
  let k = collect(newSeq):
    for d in zip(a,b):
      min(d[0],d[1])
  result = k

proc seqmax *[T:SomeNumber] (a,b:openarray[T]): seq[T] =
  let k = collect(newSeq):
    for d in zip(a,b):
      max(d[0],d[1])
  result = k

proc zip *[T] (sq:seq[seq[T]]): seq[seq[T]] = 
  let 
    n = sq.len
    t = sq[0].len
  var k:seq[seq[T]]
  for position in 0..t-1:
    var l : seq[T]
    for spot in 0..n-1:
      l.add(sq[spot][position])
    k.add(l)
  result = k

#template low (slice:Hslice): auto = slice.a
#template high (slice:Hslice): auto = slice.b

using
    x:float

type fuzzymemberfunction* = ref object of RootObj
method `()` (fmf:fuzzymemberfunction,x): float {.base.} =
    quit "to override!"
type Trimf = ref object of fuzzymemberfunction
  a*,b*,c*:float
method `()` *(fmf:Trimf, x): float =
  if (fmf.a == fmf.b) and (x == fmf.a):
      return 1
  if (fmf.b == fmf.c) and (x == fmf.c):
      return 1
  if x <= fmf.a:
    result = 0
  elif fmf.a <= x and x <= fmf.b:
    result = (x - fmf.a)/(fmf.b - fmf.a)
  elif fmf.b <= x and x <= fmf.c:
    result = (fmf.c - x)/(fmf.c - fmf.b)
  elif x >= fmf.c:
    result = 0
proc trimf *(a,b,c:float): Trimf = 
    #if not (a <= b <= c):
    #    raise newException(ValueError,"a is not less than b or b is not less than c")
    result = Trimf(a:a,b:b,c:c)
  

type Trapmf = ref object of fuzzymemberfunction
    a*,b*,c*,d*:float
method `()` *(fmf:Trapmf,x): float =
    if x <= fmf.a:
        result = 0
    elif fmf.a <= x and x <= fmf.b:
        result = (x - fmf.a)/(fmf.b - fmf.a)
    elif fmf.b <= x and x <= fmf.c:
        result = 1
    elif fmf.c <= x and x <= fmf.d:
        result = (fmf.d - x)/(fmf.d - fmf.c)
    elif x >= fmf.d:
        result = 0
proc trapmf *(a,b,c,d:float): Trapmf = Trapmf(a:a,b:b,c:c,d:d)
type Gaussmf = ref object of fuzzymemberfunction
    c*,s*:float
    m*:Natural
method `()` *(fmf:Gaussmf,x): float =
    result = exp((-1/2)*((x-fmf.c)/fmf.s)^fmf.m)

proc gaussmf *(c,s:float,m:Natural): Gaussmf = Gaussmf(c:c, s:s, m:m)

type Gbellmf = ref object of fuzzymemberfunction
    a*:Natural
    b*,c*:float
method `()` *(fmf:Gbellmf,x): float =
    result = 1/(1+((x-fmf.c)/fmf.b)^(2*fmf.a))
proc gbellmf *(a:Natural,b,c:float): Gbellmf = Gbellmf(a:a, b:b, c:c)

proc function(fmf:fuzzymemberfunction,x): float = fmf(x)

type Fuzzyset* = seq[fuzzymemberfunction]
type Fuzzyvariable* = ref object
    name*:string
    inputrange*:HSlice[float,float]
    fuzzytable*:OrderedTable[string,fuzzymemberfunction]
proc `[]=` *(fuzzy:var Fuzzyvariable, name:string, fmf:fuzzymemberfunction) =
    fuzzy.fuzzytable[name] = fmf

proc `[]` *(fuzzy:Fuzzyvariable, name:string):fuzzymemberfunction =
    fuzzy.fuzzytable[name]

proc `()` *(fuzzy:Fuzzyvariable,x): seq[float] =
    for member in fuzzy.fuzzytable.values:
        result.add(member(x))
type FuzzyPair* = object
    variable: Fuzzyvariable
    fmf: fuzzymemberfunction
    fuzzylinguistic:string
proc `->` *(fuzzy:Fuzzyvariable,name:string): FuzzyPair =
    result = FuzzyPair(variable:fuzzy,fmf:fuzzy.fuzzytable[name],fuzzylinguistic:name)

proc `is` *(fuzzy:Fuzzyvariable,name:string): FuzzyPair =
    result = FuzzyPair(variable:fuzzy,fmf:fuzzy.fuzzytable[name], fuzzylinguistic:name)

type FuzzyOperator = enum
    AND,OR, STRAIGHT

type FuzzyRule* = ref object
    precedent*:seq[FuzzyPair]
    operator*:FuzzyOperator
    antecedent*: FuzzyPair

proc calculate *(rule:FuzzyRule,ante:seq[float], inp:Table[string,float]): auto = 
    var
        antecalc = ante.map(proc (x):float = rule.antecedent.fmf(x))
        val:float
        valueset:seq[float]
    
    #ante = #tip[low](x))
    
    for pos, fuzzvar in rule.precedent:
        valueset.add(fuzzvar.fmf(inp[fuzzvar.variable.name]))
    case rule.operator
    of AND:
        val = valueset.min
    of OR:
        val = valueset.max
    of STRAIGHT:
        val = valueset[0]
    valueset = val.repeat(ante.len-1)
    result = seqmin(valueset,antecalc)

proc `&` *(fp1,fp2:FuzzyPair): FuzzyRule =
    result = FuzzyRule()
    result.precedent = @[fp1,fp2]
    result.operator = AND
proc `&` *(fa: var FuzzyRule,fp:FuzzyPair):FuzzyRule =
    fa.precedent.add(fp)
    result = fa
proc `and` (fp1,fp2:FuzzyPair): FuzzyAnd =
    result = fp1 & fp2
proc `and` (fa: FuzzyRule,fp:FuzzyPair):FuzzyAnd =
    result = fa & fp
proc `|` *(fp1,fp2:FuzzyPair): FuzzyRule =
    result = FuzzyRule()
    result.precedent = @[fp1,fp2]
    result.operator = OR
proc `|` *(fa: var FuzzyRule,fp:FuzzyPair):FuzzyRule =
    fa.precedent.add(fp)
    result = fa
proc `or` *(fp1,fp2:FuzzyPair): FuzzyRule =
    result = fp1 | fp2
proc `or` *(fa: var FuzzyRule,fp:FuzzyPair): FuzzyRule =
    result = fa | fp
proc `=>:` *(fr: FuzzyRule, fp:FuzzyPair):FuzzyRule =
    fr.antecedent = fp
    result = fr
proc `=>:` *(fo:FuzzyPair,fp:FuzzyPair):FuzzyRule =
    result = FuzzyRule()
    result.precedent =  @[fo]
    result.antecedent = fp
    result.operator = STRAIGHT
type FuzzyControlSystem* = object
    precedent*: seq[Fuzzyvariable]
    antecedent*: seq[Fuzzyvariable]
    rules*: seq[FuzzyRule]

proc calculate *(fcs:FuzzyControlSystem,inp:Table[string,float]): float =
    var aggregate:seq[seq[float]]
    let dx = 1.0
    var ante = linspace(fcs.antecedent[0].inputrange.a, fcs.antecedent[0].inputrange.b, dx)
    for rule in fcs.rules:
        aggregate.add(rule.calculate(ante, inp))
    
    var fin:seq[float]
    for point in zip(aggregate):
        let maxy = max(point)
        fin.add(maxy)
    #var k:seq[float]
    #for d in zip(fin, ante):
    #    k.add(d[0]*d[1])

    #let top = sum(k.map(proc (x):float = x*dx))
    #let bottom = sum(fin.map(proc (x):float = x*dx))
    let fmfintegral = sum(fin.map(proc (x):float = x*dx))
    #result = top/bottom
    result = fmfintegral

template fuzzy_converter *(body:typedesc[enum]) =
  converter fuzzy_enum_to_string *(inp:body):string = $inp
  
macro fuzzy_enum *(body:varargs[untyped]): untyped =
  result = StmtList()
  let Enum = EnumTy()
  for val in body:
    Enum.add(EnumFieldDef(newIdentNode(val.repr),newLit(val.repr)))
  result.add(TypeSection(TypeDef(newIdentNode("fuzzy_words"),newEmptyNode(),Enum)))

template fuzzy_values *(body:varargs[untyped]):untyped =
  fuzzy_enum(body)
  fuzzy_converter(fuzzy_words)