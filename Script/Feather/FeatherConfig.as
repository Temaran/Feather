// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

/*
 * This is the master config file for feather. Since we want this to be accessible from anywhere, and forcing the creation of a base-ini is just as much (if not more) of a hassle, this will serve as the master "config" for Feather.
 * Just make any changes you want in-line here, and if you update, you will have to merge this file like normal (but your merge tool should make this exceedingly easy).
 */

namespace FeatherConfig
{
	// If this is true, everything will always be saved to your %APPDATA% project subfolder, otherwise save to ProjectUserDir. This is very useful if you want to use the same window settings no matter if you're in PIE, or testing a build.
	const bool bAlwaysSaveToAppData = true;

	// This will be relative to the ProjectUserDir if AlwaysSaveToAppData is false, otherwise it is relative to your project's %APPDATA%
	const FString SettingsSavePath = "Feather/";
};