# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import tables
import Fuzzy
import fmftemplates

proc `~=`(a,b:float):bool =
  abs(a-b) < 1e-5

fuzzy_values low, medium, high

var
  func1 = trimf(1f, 1f, 5f)
  func2 = trimf(1f, 5f, 10f)
  func3 = trimf(5f, 10f, 10f)
var
  service = Fuzzyvariable[fuzzyfunction](name:"service", inputrange:1d..10d)
  quality = Fuzzyvariable[fuzzyfunction](name:"quality", inputrange:1d..10d)
  tip = Fuzzyvariable[fuzzyfunction](name:"tip", inputrange:1d..25d)
service[low] = func1
service[medium] = func2
service[high] = func3
quality[low] = func1
quality[medium] = func2
quality[high] = func3
tip[low] = trimf(0f,0f,13f)
tip[medium] = trimf(0d,13d,25f)
tip[high] = trimf(13f,25f,25f)
var
  rule1 = (((service -> low) or (quality -> low)) =>: (tip -> low))
  rule2 = (service -> medium) =>: (tip -> medium)
  rule3 = ((service -> high) or (quality -> high)) =>: (tip -> high)
var FCS : FuzzyControlSystem[fuzzyfunction]
FCS.precedent = @[service, quality]
FCS.antecedent = @[tip]
FCS.rules = @[rule1, rule2, rule3]

#3
echo FCS.calculate({"quality":2.0, "service":8.0}.totable)# ~= 12.45769

