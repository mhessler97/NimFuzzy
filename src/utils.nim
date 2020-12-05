

proc linspace*(start, stop: float,num:static[int], endpoint = true): array[num, float] =
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

template arraycomparator(name:untyped):untyped =
  proc name*[N:int,T:SomeNumber](a,b:array[N,T]): array[N,T] =
    for i in N.low..N.high:
      result[i] = name(a[i],b[i])
  proc name*[N:int,T:SomeNumber](a:array[N,T],b:T):array[N,T] =
    for i in N.low..N.high:
      result[i] = name(a[i],b)

template seqcomparator(name:untyped):untyped =
  proc name*[T:SomeNumber](a,b:seq[T]): seq[T] =
    result = newSeq(a.len)
    for i in a.low..a.high:
      result[i] = name(a[i],b[i])
  proc name*[T:SomeNumber](a:seq[T],b:T):seq[T] =
    result = newSeq(a.len)
    for i in a.low..a.high:
      result[i] = name(a[i],b)

template comparator(name:untyped):untyped =
    arraycomparator(name)
    #seqcomparator(name)

comparator(min)
comparator(max)


iterator slices*[A,N:int,T](a:array[A,array[N,T]]):array[A,T] =
  var result:array[A,T]
  for i in N.low..N.high:
    for j in A.low..A.high:
      result[j] = a[j][i]
    yield result

iterator enumslices*[A,N:int,T](a:array[A,array[N,T]]):(int, array[A,T]) =
  var counter = -1
  for slice in a.slices:
    inc counter
    yield (counter, slice)