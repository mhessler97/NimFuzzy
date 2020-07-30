# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import tables
import Fuzzy

#test "can add":
#  check add(5, 5) == 10

fuzzy_values low, medium, high
  
var
  func1 = trimf(1f, 1f, 5f)
  func2 = trimf(1f, 5f, 10f)
  func3 = trimf(5f, 10f, 10f)
var
  service = Fuzzyvariable(name:"service", inputrange:1d..10d)
  quality = Fuzzyvariable(name:"quality", inputrange:1d..10d)
  tip = Fuzzyvariable(name:"tip", inputrange:1d..25d)
service[low] = func1
service[medium] = func2
service[high] = func3
quality[low] = func1
quality[medium] = func2
quality[high] = func3
tip[low] = trimf(0d,0d,13d)
tip[medium] = trimf(0d,13d,25d)
tip[high] = trimf(13d,25d,25d)
let
  rule1 = (((service -> low) or (quality -> low)) =>: (tip -> low))
  rule2 = (service -> medium) =>: (tip -> medium)
  rule3 = ((service -> high) or (quality -> high)) =>: (tip -> high)
var FCS : FuzzyControlSystem
FCS.precedent = @[service, quality]
FCS.antecedent = @[tip]
FCS.rules = @[rule1, rule2, rule3]
echo FCS.calculate({"service":8.0,"quality":2.0}.totable)

