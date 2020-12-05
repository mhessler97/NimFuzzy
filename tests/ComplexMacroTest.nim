import fuzzyMacro

automf(-2.0..2.0, nb, ns, ze, ps, pb)

FuzzyControlSystem(Complex):
    Precedent:
        error(-2.0..2.0):
            nb = nb
            ns = ns
            ze = ze
            ps = ps
            pb = ps
        delta(-2.0..2.0):
            nb = nb
            ns = ns
            ze = ze
            ps = ps
            pb = ps
    Antecedent:
        output(-2.0..2.0):
            nb = nb
            ns = ns
            ze = ze
            ps = ps
            pb = ps
    rules:
        IF (error IS nb AND delta IS nb) OR (error IS ns AND delta IS nb) OR (error IS nb AND delta IS ns) THEN output is nb

        IF (error IS nb AND delta IS ze) OR (error IS nb AND delta IS ps) OR (error IS ns AND delta IS ns) OR \
           (error IS ns AND delta IS ze) OR (error IS ze AND delta IS ns) OR (error IS ze AND delta IS nb) OR \
           (error IS ps AND delta IS nb) THEN output is ns

        IF (error IS nb AND delta IS pb) OR (error IS ns AND delta IS ps) OR (error IS ze AND delta IS ze) OR \
           (error IS ps AND delta IS ns) OR (error IS pb AND delta IS nb) THEN output is ze

        IF (error IS ns AND delta IS pb) OR (error IS ze AND delta IS pb) OR (error IS ze AND delta IS ps) OR \
           (error IS ps AND delta IS ps) OR (error IS ps AND delta IS ze) OR (error IS pb AND delta IS ze) OR \
           (error IS pb AND delta IS ns) THEN output is ps

        IF (error IS ps AND delta IS pb) OR (error IS pb AND delta IS pb) OR (error IS pb AND delta IS ps) THEN output is pb

echo Complex(0.5,0.5)