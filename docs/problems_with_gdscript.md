# Problems with GDScript #
I don't like gdscript very much, here is why.
- immature. Feels very half-done
    - there are many missing features which makes some tasks impossible, such as casting a string to an integer with error handling. Calling `int('hi')` returns 0 with no indication that there was an error...
    - no user defined exceptions. Very challenging to do error handling in general
    - can't catch built in exceptions, just have to make sure to avoid them
    - too many things fail silently
    - can't explicitly assign to named arguments eg `f(place_arg, named_arg=some_val)` which would be useful for self-documenting the code. Instead have to write a comment explaining what `input.split(' ', false, 1)` means. `input.split(' ', allow_empty=false, maxsplits=1)` would be much nicer.
    - not enough data structures. There is no `set` for example. Ties in with the complaint about performance, yes you can use a list instead, but I don't want to.
- doesn't seem performance oriented, have to always resort to slow workarounds for missing language features
    - for example, cannot return multiple values from a function, so have to construct a list instead and place the multiple elements inside the list, and there is no pattern matching either so you have to manually unpack the list as well
- missing 'quality of life' language features such as
    - syntax for exponents: `a**x` or `a^x`
    - variadic arguments
    - automatic constructors based on the attributes present in the class
    - destructors
- using `ClassName.new` is clunky
- can't access variables and functions of an outer class from within an inner class because the language lacks closures: https://github.com/godotengine/godot/issues/4472
- doesn't always raise errors when things go wrong
    - have to inherit from `Node` in order to use `connect`, but if you didn't know that or forget, no error will be raised, the connected method will simply never be called...
- rips off python but changes syntax and conventions arbitrarily just to be different, such as booleans being lower case or using null instead of None, func instead of def etc.
- seems aimed towards basic functionality and novice programmers. The language does not provide any facilities such as higher order functions or list comprehensions for functional-style programming leading to very clumsy and explicit code.
    - writing 10+ lines for something that python could do in a single line is a bit exhausting
- bugs. I am not used to having to deal with bugs in the language
    - eg `is_nan` currently just doesn't work at all. `is_nan(nan)` returns false...
    - `Engine.editor_hint` is supposed to tell when in the editor and when in the game, but doesn't seem to work when called from a plugin...
- not well documented. One good example is the documentation for Input.set_mouse_mode: 'Set the mouse mode. See the constants for more information.'. Which constants would those be? You haven't said...
    - also, inconsistent styling. Some arguments are written `likethis` and others `like_this` for no reason, simply sloppy adherence to a single coding style.
        - even worse, some functions have this problem too: `printraw()` and `print_stack()`
    - some of the naming is a bit suspect
        - https://godot.readthedocs.io/en/3.0/classes/class_rectangleshape2d.html
        - 'extents - The rectangle’s half extents'
- the debugging support is virtually non-existent
- too many things change silently between versions. Change is good, but not clearly documenting when an API breaking change is introduced is stupid.
- there are many problems that aren't caught by the editor which cause runtime issues.
    - eg https://github.com/godotengine/godot/issues/7584#issuecomment-342968502
    - For example, using a custom class as an export variable: can't find the script file because the class is defined inline and not in its own file. So giving it its own file works, but causes runtime errors because it gets down-converted back to Object from whatever custom type you had, making any accesses crash.
        - this could have been avoided by either clearly documenting what is and isn't allowed (I'm still not sure when `export (Array, some_type)` became illegal) or by having the editor flag it up as a problem, or by providing better error messages.
        - the error messages don't even have any google results, it looks like very few people have built their own editor plugins. The examples in the documentation are shockingly simple and useless and don't help beyond getting set up.
- inherited classes cannot override methods in the parent class which are called by the engine. i.e if the child overrides `_process`, both the child and parent versions of `_process` get called!
    - this was a design decision chosen specifically to avoid problems some users were having when migrating from another language 'squirrel'. What a stupid way to design a language, to prevent newbies from being too scared, while reducing the overall flexibility.
    - also: the order that they get called in isn't even specified!!!
    - however for methods which aren't callbacks, they do get overridden and to call the function in the super class `.some_method()` is used
        - the syntax for this is a bit dumb IMO
    - https://github.com/godotengine/godot/issues/6500
    - a workaround is to create a separate function like `_on_process()` which _can_ be overriden, then in `_process` just call `_on_process`...
- the type annotation system is half-baked at the time of writing (3.1)
    - cannot annotate nullable/optional types <https://github.com/godotengine/godot-proposals/issues/162>
    - cannot annotate values as being enums
- I spent ages trying to figure out a problem with getting a transform from the viewport to the local frame of a node
    - The problem turned out to be that Transform2D.inverse() DOES NOT RETURN THE INVERSE!!!
    - from the docs:
        "Returns the inverse of the transform, under the assumption that the transformation is composed of rotation and translation (no scaling, use affine_inverse for transforms with scaling)."
    - !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    - Transform2D.affine_inverse() is the actual operation which performs the inverse
    - I think this is the single most brain-dead decision for gdscript yet. No doubt the assumption that there is no scale component is used to create a more efficient inverse implementation, however making this THE DEFAULT behaviour of a method called `inverse' is the stupidest thing I've seen from an API in a while. The optimised version of a method with extra assumptions should be the one which has a name like `rigid_inverse` to make the assumption explicit


# Problems with Godot
although I like godot, there are many things wrong with it
- documentation is terrible
- most error messages are not useful
    - eg when loading a plugin with a syntax error or similar (like preloading something that doesn't exist), godot says it doesn't inherit from PluginEditor even when it does.
