// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

struct FFeatherConfig
{
	// If this is true, everything will always be saved to your %APPDATA% project subfolder, otherwise save to ProjectUserDir. This is very useful if you want to use the same window settings no matter if you're in PIE, or testing a build.
	UPROPERTY(Category = "Feather|Config")
	bool bAlwaysSaveToAppData = true;

	// This will be relative to the ProjectUserDir if AlwaysSaveToAppData is false, otherwise it is relative to your project's %APPDATA%
	UPROPERTY(Category = "Feather|Config")
	FString SettingsSavePath = "Feather/";
};
