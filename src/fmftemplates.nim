import sequtils
import macros
import strformat

template trimf*(a,b,c:float): proc =
  (proc(x:float): float = 
    if (a == b) and (x == a):
      return 1
    elif (b == c) and (x == c):
      return 1
    elif x <= a:
      result = 0
    elif a <= x and x <= b:
      result = (x - a)/(b - a)
    elif b <= x and x <= c:
      result = (c - x)/(c - b)
    elif x >= c:
      result = 0
  ) 

template trapmf*(a,b,c,d:float): proc =
  (proc(x:float): float =
    if x <= a:
        result = 0
    elif a <= x and x <= b:
        result = (x - a)/(b - a)
    elif b <= x and x <= c:
        result = 1
    elif c <= x and x <= d:
        result = (d - x)/(d - c)
    elif x >= d:
        result = 0
  )

template Gaussmf*(c,s:float,m:Natural): proc =
  (proc(x:float): float =
    result = exp((-1/2)*((x-c)/s)^m)
  )

template gbellmf*(a:Natural,b,c:float): proc =
  (proc(x:float): float = 
    result = 1/(1+((x-c)/b)^(2*a))
  )

type fuzzymemberfunction* = proc(x:float):float

proc linspace*(start, stop: float,num:int, endpoint = true): seq[float] =
  result = 0.0.repeat num
  var
    step = start
    diff: float
    num = num
  if endpoint == true:
    diff = (stop - start) / float(num - 1)
  else:
    diff = (stop - start) / float(num)
  if diff < 0:
    return
  else:
    for i in 0..<num:
      result[i] = step
      step += diff

macro automf*(length:Hslice,names:varargs[untyped]):untyped = 
  result = nnkLetSection.newTree()
  let 
    lower = length[1].floatval
    upper = length[2].floatval
    total = names.len
    values = linspace(lower,upper,total)
  for i, name in names.pairs:
    let 
      a = values[max(i-1, 0)]
      b = values[i]
      c = values[min(i+1,total - 1)]
    let funcy = fmt"trimf({a}, {b}, {c})".parsestmt
  
    let asgn = nnkIdentDefs.newTree(
               name,
               newEmptyNode(),
               funcy)
    result.add asgn