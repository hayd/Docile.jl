module Extensions

using Compat

"""
!!summary(Methods to extend how Docile handles parsing of docstrings.)

These methods could just as easily be defined outside of the package and allow
for package authors to customise how their documentation is presented to users.
"""
Extensions

import ..Formats: Formats, @META_str
import ..Cache

"""
!!summary(Get the value stored in an object's metadata field.)

In the following example the value associated with the field ``:author`` is
spliced back into the docstring in place of it:

    \\!!get(author)

When no field is found in the metadata for the object, the module and package
metadata are searched in turn.
"""
function Formats.metamacro(::META"get", body, mod, obj)
    out = Cache.findmeta(mod, obj, symbol(body), Any)
    isnull(out) && throw(KeyError("No metadata found in $(obj) for '$(body)'."))
    get(out)
end

"""
!!summary(Set the value for a field in an object's metadata.)

    \\!!set(author:Author's Name)

The key in this example is ``:author`` and the value is ``"Author's Name"``.
"""
function Formats.metamacro(::META"set", body, mod, obj)
    key, value = @compat(split(body, ':', limit = 2))
    Cache.getmeta(mod, obj)[symbol(key)] = value
    ""
end

function Formats.metamacro(::META"setget", body, mod, obj)
    Base.warn_once("'!!setget(...)' is deprecated. Using '!!var(...)' instead.")
    Formats.metamacro(META"var"(), body, mod, obj)
end

"""
!!summary(Equivalent to ``!!set`` followed by ``!!get`` for the provided key.)

    \\!!var(author:Author's Name)

The key in this example is ``:author`` and the value is ``"Author's Name"``.
"""
function Formats.metamacro(::META"var", body, mod, obj)
    key, value = @compat(split(body, ':', limit = 2))
    Cache.getmeta(mod, obj)[symbol(key)] = value
end

"""
!!summary(Specify a short (120 character) summary for a docstring.)

    \\!!summary(...)

The text will be used in the generated index page produced by Lexicon.

A warning is printed when a summary exceeds the character limit.
"""
function Formats.metamacro(::META"summary", body, mod, obj)
    length(body) > 120 && warn("Overlong summary in '$(obj)' docstring.")
    Cache.getmeta(mod, obj)[:summary] = body
    body
end

"""
!!summary(Make the contained text only appear in non-interactive output.)

    \\!!longform(
    ...
    )

In the REPL the text is not displayed. Other ``metamacro`` calls can be nested
inside a ``\\!!longform(...)`` call, such as ``\\!!include(...)``.
"""
function Formats.metamacro(::META"longform", body, mod, obj)
    body = Formats.extractmeta!(body, mod, obj) # Make nestable.
    Cache.getmeta(mod, obj)[:longform] = body
    isinteractive() ? "" : body
end

"""
!!summary(Splice the contents of a file in place of the ``metamacro`` call.)

    \\!!include(filename)

``filename`` must reference an available file found relative to the source file
where the ``metamacro`` is called from.
"""
function Formats.metamacro(::META"include", body, mod, obj)
    meta = Cache.getmeta(mod, obj)
    filename = abspath(joinpath(dirname(meta[:textsource][2]), body))
    isfile(filename) || throw(ArgumentError("Unknown '!!include(...)' file: $(filename)"))
    Formats.extractmeta!(readall(filename), mod, obj)
end

end
