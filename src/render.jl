@doc """
Write the documentation stored in `modulename` module to the specified file `file`
in the format guessed from the file's extension.

Currently supported formats: `HTML`.
""" ->
function save(file::String, modulename::Module; mathjax = false)
    isdefined(modulename, METADATA) || error("module $(modulename) is not documented.")
    mime = MIME("text/$(strip(last(splitext(file)), '.'))")
    save(file, mime, getfield(modulename, METADATA); mathjax = mathjax)
end

@doc "Display the contents of a module's manual pages." ->
function manual(m::Module)
    isdefined(m, METADATA) || error("module $(m) is not documented.")
    getfield(m, METADATA).manual
end

## plain ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

function writemime(io::IO, mime::MIME"text/plain", ents::Entries)
    for (m, ent) in ents.entries
        println(io, ">>>")
        println(io, AnsiColor.colorize(:blue, "\n • $(m)\n"; mode = "bold"))
        writemime(io, mime, ent)
    end
end

function writemime(io, ::MIME"text/plain", entry::Entry)
    println(io, entry.docs)
    # print metadata if any
    if !isempty(entry.meta)
        println(io, AnsiColor.colorize(:green, " • Details:\n"))
    end
    for (k, v) in entry.meta
        if isa(v, Vector)
            println(io, "\t ∘ ", k, ":")
            for line in v
                if isa(line, NTuple)
                    println(io, "\t\t", AnsiColor.colorize(:cyan, string(line[1])), ": ", line[2])
                else
                    println(io, "\t\t", string(line))
                end
            end
        else
            println(io, "\t ∘ ", k, ": ", v)
        end
        println(io)
    end
end

function writemime(io::IO, mime::MIME"text/plain", manual::Manual)
    for page in manual.manual
        writemime(io, mime, page)
    end
end

## html TODO: tidy, avoid using wrap ––––––––––––––––––––––––––––––––––––––––––––––––––––

function save(file::String, mime::MIME"text/html", documentation::Documentation; mathjax = false)
    open(file, "w") do f
        info("writing documentation to $(file)")
        writemime(f, mime, documentation; mathjax = mathjax)
    end
    
    # copy static files
    src = joinpath(Pkg.dir("Docile"), "static")
    dst = joinpath(dirname(file), "static")
    isdir(dst) || mkpath(dst)
    for file in readdir(src)
        info("copying $(file) to $(dst)")
        cp(joinpath(src, file), joinpath(dst, file))
    end
end

function writemime(io::IO, mime::MIME"text/html", manual::Manual)
    for page in manual.manual
        writemime(io, mime, page)
    end
end

const CATEGORY_ORDER = [:module, :function, :method, :type, :macro, :global]

function writemime(io::IO, mime::MIME"text/html", documentation::Documentation; mathjax = false)
    header(io, mime, documentation)
    writemime(io, mime, documentation.manual)
    
    index = Dict{Symbol, Any}()
    for (obj, entry) in documentation.entries
        addentry!(index, obj, entry)
    end
    
    println(io, "<h1>Reference</h1>")
    
    entries = Entries()
    wrap(io, "ul", "class='index'") do
        for k in CATEGORY_ORDER
            haskey(index, k) || continue
            wrap(io, "li") do
                println(io, "<strong>$(k)s:</strong>")
            end
            wrap(io, "li") do
                wrap(io, "ul") do
                    for (s, obj) in index[k]
                        push!(entries, obj, documentation.entries[obj])
                        wrap(io, "li") do
                            print(io, "<a href='#$(s)'>", s, "</a>")
                        end
                    end
                end
            end
        end
    end
    writemime(io, mime, entries)
    footer(io, mime, documentation; mathjax = mathjax)
end

function writemime(io::IO, mime::MIME"text/html", ents::Entries)
    wrap(io, "div", "class='entries'") do
        for (obj, ent) in ents.entries
            writemime(io, mime, obj, ent)
        end
    end
end

function writemime{category}(io::IO, mime::MIME"text/html", obj, ent::Entry{category})
    wrap(io, "div", "class='entry'") do
        objname = writeobj(obj)
        wrap(io, "div", "id='$(objname)' class='entry-name category-$(category)'") do
            print(io, "<div class='category'>[$(category)] &mdash; </div> ")
            println(io, objname)
        end
        wrap(io, "div", "class='entry-body'") do
            writemime(io, mime, ent.docs)
            wrap(io, "div", "class='entry-meta'") do
                println(io, "<strong>Details:</strong>")
                wrap(io, "table", "class='meta-table'") do
                    for k in sort(collect(keys(ent.meta)))
                        wrap(io, "tr") do
                            print(io, "<td><strong>", k, ":</strong></td>")
                            wrap(io, "td") do
                                writemime(io, mime, Meta{k}(ent.meta[k]))
                            end
                        end
                    end
                end
            end
        end
    end
end

type Meta{keyword}
    content
end

function writemime(io::IO, mime::MIME"text/html", md::Meta)
    println(io, "<code>", md.content, "</code>")
end

function writemime(io::IO, ::MIME"text/html", m::Union(Meta{:parameters}, Meta{:fields}))
    for (k, v) in m.content
        println(io, "<p><code>", k, ":</code>", v, "</p>")
    end
end

function writemime(io::IO, ::MIME"text/html", m::Meta{:source})
    path = last(split(m.content[2], r"v[\d\.]+(/|\\)"))
    print(io, "<code><a href='$(url(m))'>$(path):$(m.content[1])</a></code>")
end

function header(io::IO, ::MIME"text/html", doc::Documentation)
    println(io, """
    <!doctype html>
    
    <meta charset="utf-8">
    
    <title>$(doc.modname)</title>
    
    <link rel="stylesheet" type="text/css"
          href="//cdnjs.cloudflare.com/ajax/libs/codemirror/4.5.0/codemirror.min.css">
    
    <link rel="stylesheet" type="text/css" href="static/custom.css">
    
    <h1 class='package-header'>$(doc.modname)</h1>
    """)
end

function footer(io::IO, ::MIME"text/html", doc::Documentation; mathjax = false)
    println(io, """
    
    <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
    <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/codemirror/4.5.0/codemirror.min.js"></script>
    <script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/codemirror/4.5.0/mode/julia/julia.min.js"></script>
    
    $(mathjax ? "<script type='text/javascript' src='http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML'></script>" : "")
    
    <script type="text/javascript" src="static/custom.js"></script>
    """)
end

## utils ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

function wrap(fn::Function, io::IO, tag::String, attributes::String = "")
    println(io, "<", tag, " ", attributes, ">")
    fn()
    println(io, "</", tag, ">")
end

writeobj(any) = string(any)
writeobj(m::Method) = first(split(string(m), " at "))

function addentry!{category}(index, obj, entry::Entry{category})
    section, pair = get!(index, category, (String, Any)[]), (writeobj(obj), obj)
    insert!(section, searchsortedlast(section, pair, by = x -> first(x)) + 1, pair)
end

# from base/methodshow.jl
function url(m::Meta{:source})
    line, file = m.content
    try
        d = dirname(file)
        u = Pkg.Git.readchomp(`config remote.origin.url`, dir=d)
        u = match(Pkg.Git.GITHUB_REGEX,u).captures[1]
        root = cd(d) do # dir=d confuses --show-toplevel, apparently
            Pkg.Git.readchomp(`rev-parse --show-toplevel`)
        end
        if beginswith(file, root)
            commit = Pkg.Git.readchomp(`rev-parse HEAD`, dir=d)
            return "https://github.com/$u/tree/$commit/"*file[length(root)+2:end]*"#L$line"
        else
            return Base.fileurl(file)
        end
    catch
        return Base.fileurl(file)
    end
end
