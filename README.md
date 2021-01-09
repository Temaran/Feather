# Feather
Do you think creating Unreal UI in slate has too slow iteration time? Do you like the layout functionality of UMG, but still avoid it because merging Blueprint is frustrating?
Then maybe this library is for you!

Feather is a UI library for Unreal Engine 4 that lets you create your visual layouts in UMG, but allows you to define as much logic as you want (all of it preferably!) in AngelScript.
Literally the best of both worlds!

Feather allows you to do the following:
* Define your visual styles in the intuitive UMG editor interface.
* Use these styles by name when creating your UI.
* Keep all your logic in AngelScript.
* Create window hierarchies with most of the things you expect from such a system out of the box.
* An optional JSON-based settings system that works no matter if you're in PIE, stand-alone or using a finished build. All of them will read the same settings. You can opt to use the in-engine config ini's instead if you prefer though.
* An implementation of a debug interface that lets you easily create debug operations for testing and iterating on your project based on an easy-to-learn search interface. It even supports binding keys to your favourite ops!

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

# TODO
 - Implement style cascading