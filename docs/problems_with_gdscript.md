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
- doesn't always raise errors when things go wrong
    - have to inherit from `Node` in order to use `connect`, but if you didn't know that or forget, no error will be raised, the connected method will simply never be called...
- rips off python but changes syntax and conventions arbitrarily just to be different, such as booleans being lower case or using null instead of None, func instead of def etc.
- seems aimed towards basic functionality and novice programmers. The language does not provide any facilities such as higher order functions or list comprehensions for functional-style programming leading to very clumsy and explicit code.
    - writing 10+ lines for something that python could do in a single line is a bit exhausting
- bugs. I am not used to having to deal with bugs in the language
    - eg `is_nan` currently just doesn't work at all. `is_nan(nan)` returns false...
- not well documented. One good example is the documentation for Input.set_mouse_mode: 'Set the mouse mode. See the constants for more information.'. Which constants would those be? You haven't said...
    - also, inconsistent styling. Some arguments are written `likethis` and others `like_this` for no reason, simply sloppy adherence to a single coding style.
        - even worse, some functions have this problem too: `printraw()` and `print_stack()`
- the debugging support is virtually non-existent

