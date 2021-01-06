# Feather
A library for creating an AS/UMG hybrid window system. Also includes a template debug interface for UE4 dev.

# Installation
To install Feather, simply copy the entire FeatherDemo/Script/Feather/... folder to your project's #MyProject#/Script/Feather/... folder.

You can also optionally copy the FeatherDemo/Content/DebugInterface/... folder to your project's #MyProject#/Content/DebugInterface/... folder if you want a default root with some windows and styles.

That's it. :)

# Setup
To set up feather, you only need to define some windows and add them to a canvas of your choice. The debug interface uses a root widget type to help you with this, and to automatically lay them out if you decide to use that.
That's really it. To see a concrete example, have a look in the demo project "FeatherDemo".

To get full use out of Feather, I recommend using styles as well. To see how that is set up, have a look at the default properties of the Layout widget blueprint in the FeatherDemo project.
If you want to use window features like dragging, resizing etc, all your windows should also have a windowstyle in their hierarchies.
Don't forget to override and hook up all the overrides in the window as well if you want to get full support. See the "Feather" category in WBP_DI_MainWindow widget in the FeatherDemo for details!

----------------------------------------------------------------------

# TODO
 - Implement keybinds

 - Make sure the cpp changes get merged
