# Docile

[![Build Status](https://travis-ci.org/MichaelHatherly/Docile.jl.svg?branch=master)](https://travis-ci.org/MichaelHatherly/Docile.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/ttlbaxp6pgknfru5/branch/master?svg=true)](https://ci.appveyor.com/project/MichaelHatherly/docile-jl/branch/master)
[![Coverage Status](http://codecov.io/github/MichaelHatherly/Docile.jl/coverage.svg?branch=master)](http://codecov.io/github/MichaelHatherly/Docile.jl?branch=master)
[![Docile](http://pkg.julialang.org/badges/Docile_0.4.svg)](http://pkg.julialang.org/?pkg=Docile&ver=0.4)

*Documentation extensions for [Julia](http://www.julialang.org)*

```julia
Pkg.update()
Pkg.add("Docile")
```

Complete package documentation is available [here](doc/build/SUMMARY.md).

#### Feature Summary

Docstring-local variables and per-argument docstrings:

```julia
using Docile, Docile.Hooks
register!(
    doc!args,
    doc!kwarg,
    doc!sig
)

"""
    $doc!sig

...

$doc!args

$doc!kwargs
"""
function func(
        "docs for `foo`...",
        foo,
        "docs for `bar`...",
        bar;
        "docs for `baz`...",
        baz = 1
    )
    # ...
end
```

Directives, `@<name>{...}`, for adding cross-references, code and REPL blocks with automatic output,
and any other user-defined behaviours:

```julia
using Docile, Docile.Hooks
register!(directives)

"""
@esc{@repl{
A = rand(3, 3)
b = [1, 2, 3]
A \ b
}}

See also: @esc{@ref{g}}
"""
function func(...)
    # ...
end

"""
...
"""
g(x) = x
```

A build system for generating static markdown files from a combination of docstrings and
external files. Source files can contain directives to splice in docstrings, add cross-references, etc.

```julia
using Docile, MyPackage

makedocs()
```