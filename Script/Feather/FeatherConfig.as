// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

// This config exists on all widgets, but is set from the root, cascading down. The root itself loads its settings from ini. If you want to override this, the best way is to edit your project's Config/DefaultGame.ini file and add something like the following:
// [/Game/DebugInterface/WBP_DI_Root.WBP_DI_Root_C]
// RootFeatherConfiguration=(bAlwaysSaveToAppData=True,SettingsSavePath="Feather/IniOverride/")
struct FFeatherConfig
{
	// If this is true, everything will always be saved to your %APPDATA% project subfolder, otherwise save to ProjectUserDir. This is very useful if you want to use the same window settings no matter if you're in PIE, or testing a build.
	UPROPERTY(Category = "Feather|Config")
	bool bAlwaysSaveToAppData = true;

	// This will be relative to the ProjectUserDir if AlwaysSaveToAppData is false, otherwise it is relative to your project's %APPDATA%
	UPROPERTY(Category = "Feather|Config")
	FString SettingsSavePath = "Feather/";
};
