
const EXTERNAL_FILES = Dict("README.md" => joinpath("..", "README.md"))

"""
    makedocs()

Generate markdown documentation from templated files.

**Keyword Arguments:**

``source = "src"``

Directory to collect markdown files from. The provided path is treated as being relative to
the directory in which the build script is run.

``build = "build"``

Destination directory for output files. As with ``source`` the path is relative to the build
script's directory.

``clean = false``

Should the build directory be deleted before building? ``external`` files are not affected
by this.

``external = $(EXTERNAL_FILES)``

User-defined files that, if found in ``source``, will be written to the provided paths
rather than the default in ``build``. ``makedocs`` writes ``README.md`` files to the parent
folder by default. This can be disabled by setting ``external = Dict()``.

**Usage:**

Import ``Docile`` and the modules that should be documented. Then call ``makedocs`` with any
additional settings that are needed.

```jl
using Docile, MyModule

makedocs()                   # Without any customisations.
makedocs(source = "../docs") # With a source folder called ``docs`` in the directory one up.
makedocs(clean = true)       # Clean out build directory before building.
```
"""
function makedocs(;
    source   = "src",
    build    = "build",
    clean    = false,
    external = EXTERNAL_FILES,
    )
    cd(Base.source_dir()) do
        clean && isdir(build) && rm(build, recursive = true)
        input = files(x -> endswith(x, ".md"), source)
        width = maximum(map(length, input))
        for each in input
            file = relpath(each, source)
            out  = get(external, file, joinpath(build, file))
            dir  = dirname(out)
            isdir(dir) || mkpath(dir)
            message(each, out, width)
            loadfile(each, out)
        end
    end
end

message(a, b, w) = println("Building: $(rpad(string("'", a, "'"), w + 2)) --> '$(b)'")
