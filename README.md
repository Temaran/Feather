# Feather
A library for creating an AS/UMG hybrid window system. Also includes a template debug interface for UE4 dev.

# Installation
To install Feather you currently need this PR: https://github.com/Hazelight/UnrealEngine-Angelscript/pull/128
Hopefully, it will get merged into angelscript-master fairly soon!
Then, simply copy the entire FeatherDemo/Script/Feather/... folder to your project's #MyProject#/Script/Feather/... folder.

You can also optionally copy the FeatherDemo/Content/DebugInterface/... folder to your project's #MyProject#/Content/DebugInterface/... folder if you want a default root with some windows and styles.

That's it. :)

# Setup
To set up feather, you only need to define some windows and add them to a canvas of your choice. The debug interface uses a root widget type to help you with this, and to automatically lay them out if you decide to use that.
That's really it. To see a concrete example, have a look in the demo project "FeatherDemo".

To get full use out of Feather, I recommend using styles as well. To see how that is set up, have a look at the default properties of the Layout widget blueprint in the FeatherDemo project.
If you want to use window features like dragging, resizing etc, all your windows should also have a windowstyle in their hierarchies.
Don't forget to override and hook up all the overrides in the window as well if you want to get full support. See the "Feather" category in WBP_DI_MainWindow widget in the FeatherDemo for details!

# Problems
There are some things regarding the design I'm not 100% happy with. Most of them come from AS limitations. I might turn these into issues later down the line.

Feather:
* Sorting in AS is very limited and having to implement my own quicksort is not great. This feels like a fairly high prio thing to fix. Normally, I would implement the sorting method in cpp and leave it at that, but forcing the project to AS only of course blocks me from using that strategy. See sorting files for more details.
* Having to define UFUNCTION overrides in intermediate classes is annoying as always in AS. I think this comes from Blueprint, but patching AS to automatically generate these UFUNCTION stubs when they are needed would make base class code so much cleaner.
* It feels like a shame to have to implement a custom serialization system, but considering the weaknesses of UE's savegames and config ini's, this currently seems like the best option.
* The relationship between window style and window is not good. This stems from the fact that AS supports neither Delegates, nor Interfaces. If we had delegates then the style could expose delegates for stuff like Resize. Events won't work since they cannot return the needed EventReply. If AS had proper interfaces, we could make an IFeatherWindow that could hold the necessary methods. But since interfaces in AS are essentially base classes, and we want window to derive from UFeatherWidget, that doesn't work either.

Debug Interface:
* Since we have so many objects that are dynamically added, serialization feels messy. I think it's in a fairly good state now, but I can't help but think that there might be a better solution.

----------------------------------------------------------------------

# TODO
 - Make sure the cpp changes get merged
