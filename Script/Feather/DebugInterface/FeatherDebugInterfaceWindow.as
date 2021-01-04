// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherWindow;
import Feather.DebugInterface.FeatherDebugInterfaceOperation;

UCLASS(Abstract)
class UFeatherDebugInterfaceWindow : UFeatherWindow
{
	// The name of the window for display purposes.
	UPROPERTY(Category = "Feather", EditDefaultsOnly)
	FName WindowName = n"UnnamedWindow";

	// This is how large the window should be by default, when first created
	UPROPERTY(Category = "Feather", EditDefaultsOnly)
	FVector2D InitialSize = FVector2D(800.0f, 450.0f);

	// Persistant windows are still visible even if you hide the debug interface. This is useful if you just want to keep certain windows around even while input is handed back to the game.
	UPROPERTY(Category = "Feather", EditDefaultsOnly)
	bool bIsPersistent = false;


	UFUNCTION(BlueprintOverride)
	void FeatherConstruct()
	{
		Super::FeatherConstruct();
	}

	UFUNCTION(BlueprintOverride)
	void SaveSettings()
	{
		Super::SaveSettings();
	}

	UFUNCTION(BlueprintOverride)
	void LoadSettings()
	{
		Super::LoadSettings();
	}

	UFUNCTION(BlueprintOverride)
	void SaveToString(FString& InOutSaveString)
	{
		Super::SaveToString(InOutSaveString);
	}

	UFUNCTION(BlueprintOverride)
	void LoadFromString(const FString& InSaveString)
	{
		Super::LoadFromString(InSaveString);
	}

	UFUNCTION(BlueprintOverride)
	void ResetSettingsToDefault() 
	{
		Super::ResetSettingsToDefault();
	}
};
