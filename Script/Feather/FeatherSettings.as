// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

/*
 * This is the settings system Feather uses.
 *
 * Why not simply use the config system you might ask? Good question!
 * The UObject config system is really quite powerful, and you can even store per-object config settings using the PerObjectConfig specifier. There are some problems however:
 * - AS currently does not support PerObjectConfig, so if someone happens to want to config two objects of the same type, that doesn't work.
 * - Even though we can create our own config file, we can only write to the Saved/ version of that config. So if we want to make sure that our standalone versions of the game can read the data we created in editor, we would have to manually copy, or run the engine with -SaveToUserDir. This is a bit too extreme for comfort.
 * - The engine caches ini content on startup, which means that modifying / reloading ini data during editor runtime works quite poorly. You can tackle this with aggressive flushing, but it's still error prone.
 * - Many properties we might want to serialize lives on base classes, or are more abstract and cannot be marked with Config. In those cases we would have to create proxy-properties to copy back and forth from. Using this approach, we keep all settings in a neat JSON struct. Much simpler.
 */

namespace FeatherSettings
{
	UFUNCTION(Category = "Feather|Settings")
	bool SaveFeatherSettings(UObject Owner, const FString& SettingsToSave, const FFeatherConfig& FeatherConfig, FString FileNameOverride = "")
	{
		if(!ensure(System::IsValid(Owner), "Cannot save for null object"))
		{
			return false;
		}

		const FString FilePath = GetSaveFilePath(FileNameOverride.IsEmpty() ? Owner.Class.GetName().ToString() : FileNameOverride, FeatherConfig);
		if(FFileHelper::SaveStringToFile(SettingsToSave, FilePath))
		{
			//Log("Feather: Saved window settings to path: " + FilePath);
			return true;
		}
		else
		{
			Error("Feather: Could not save window settings to file! \n\nSettings: " + SettingsToSave + "\n\nPath: " + FilePath);
			return false;
		}
	}

	UFUNCTION(Category = "Feather|Settings")
	bool LoadFeatherSettings(UObject Owner, FString& SettingsToLoad, const FFeatherConfig& FeatherConfig, FString FileNameOverride = "")
	{
		if(!ensure(System::IsValid(Owner), "Cannot load for null object"))
		{
			return false;
		}

		const FString FilePath = GetSaveFilePath(FileNameOverride.IsEmpty() ? Owner.Class.GetName().ToString() : FileNameOverride, FeatherConfig);
		if(FFileHelper::LoadFileToString(SettingsToLoad, FilePath))
		{
			//Log("Feather: Loaded window settings from path: " + FilePath);
			return true;
		}

		//Log("Feather: " + Owner.GetName() + " did not load any settings from file: " + FilePath);
		return false;
	}

	UFUNCTION(Category = "Feather|Settings")
	FString GetSaveFilePath(FString RecordNameOverride, const FFeatherConfig& FeatherConfig)
	{
		const FString BasePath = FeatherConfig.bAlwaysSaveToAppData ? FPlatformProcess::UserSettingsDir() : FPaths::ProjectUserDir();
		const FString ExpandedPath = FPaths::CombinePaths(BasePath, FeatherConfig.SettingsSavePath);
		const FString SaveFileName = RecordNameOverride + ".json";
		const FString FullPath = FPaths::CombinePaths(ExpandedPath, SaveFileName);
		return FullPath;
	}
}
