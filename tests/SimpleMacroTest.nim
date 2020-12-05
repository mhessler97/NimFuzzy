import fuzzyMacro

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