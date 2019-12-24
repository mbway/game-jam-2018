
# Choice of language for this game #
Initially GDScript was used to develop the game, this was the obvious choice for developing during a game jam since it has the least friction to get working and performance or tidiness was not a concern during the game jam.

As the project progresses, more emphasis needs to be placed on better code quality and re-usability.
There were several candidates:

# C++ or Rust through GDNative #
although these languages would be a good choice when developing on a single platform, It appears that the effort to get cross compilation working for all the possible targets that we might want to support is a large hurdle.

- Cross compiling Linux -> OSX appears to be almost possible, but painful to get working
- exporting for Web Assembly seems to currently be unavailable for godot
- it makes it harder for other godot users to integrate components into their own projects

note: in the future if web assembly could be used as a platform agnostic compilation target, through WASI to the godot engine, this would be perfect for this use case, however it has not been implemented yet
- <https://github.com/godotengine/godot-proposals/issues/147>
- <https://github.com/godotengine/godot/issues/28303>


# GDScript #
I really don't like gdscript for reasons outlined in `problems_with_gdscript.md`

# C# #
Since C# support for Godot is a widely requested feature with financial backing, it is probably the path with least friction (other than gdscript) and has support for all platforms (including web assembly)

The downsides are:
- still a managed language
- PascalCase
- Microsoft Involvement (although less so because godot uses mono rather than the microsoft runtime)

The advantages are:
- a proper language with a proper standard library
- first class support in Godot
- supported on all platforms
- should be easier to translate C# -> C++ than to translate gdscript -> C++ in future if the wasi situation changes, since the paradigms are more similar

