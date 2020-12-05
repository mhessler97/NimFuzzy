import math
{.experimental: "callOperator".}

using
    x:float

type fuzzymemberobject* = ref object of RootObj

method `()` *(fmf:fuzzymemberobject,x): float {.base.} =
    quit "to override!"

type Trimf* = ref object of fuzzymemberobject
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
  

type Trapmf = ref object of fuzzymemberobject
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
type Gaussmf = ref object of fuzzymemberobject
    c*,s*:float
    m*:Natural
method `()` *(fmf:Gaussmf,x): float =
    result = exp((-1/2)*((x-fmf.c)/fmf.s)^fmf.m)

proc gaussmf *(c,s:float,m:Natural): Gaussmf = Gaussmf(c:c, s:s, m:m)

type Gbellmf = ref object of fuzzymemberobject
    a*:Natural
    b*,c*:float
method `()` *(fmf:Gbellmf,x): float =
    result = 1/(1+((x-fmf.c)/fmf.b)^(2*fmf.a))
proc gbellmf *(a:Natural,b,c:float): Gbellmf = Gbellmf(a:a, b:b, c:c)

proc function(fmf:fuzzymemberobject,x): float = fmf(x)