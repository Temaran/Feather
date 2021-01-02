// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherWidget;

UCLASS(Abstract)
class UFeatherDebugInterfaceOperation : UFeatherWidget
{
	// Operations that only work in standalone should not even show up when running networked!
	UPROPERTY(Category = "Feather")
	bool bOnlyWorksInStandalone = false;

	// These are the tags that will be matched when searching for operations.
	UPROPERTY(Category = "Feather")
	TArray<FName> OperationTags;

	// Padding applied to the widget.
	UPROPERTY(Category = "Feather")
	FMargin AutoPadding;
	default AutoPadding.Top = 10.0f;
	default AutoPadding.Bottom = 10.0f;
	default AutoPadding.Left = 0.0f;
	default AutoPadding.Right = 0.0f;

	// Don't try to override this one, override ConstructOperation instead.
	UFUNCTION(BlueprintOverride)
	void FeatherConstruct()
	{
		Super::FeatherConstruct();
		Padding = AutoPadding;
		ConstructOperation();
	}

//////////////////////////////////////////////////////////////////////////////////////////////////
// Operation API
// You are expected to override all these functions, 
// including the settings ones for all actual operations.
//
// When creating a new operation, first see if you can subclass a simple operation base
// (see FeatherTimeDilationOperation as an example). 
// If that is not enough, subclass this fully (see FeatherSpawnAtCursorOperation for an example)

	// You should be using this for your initialization logic as base class properties and the environment will have been set up by the time this is called.
	UFUNCTION(Category = "Feather", BlueprintEvent)
	void ConstructOperation()
	{
	}

	// Execute this operation. This means different things depending on the operation. Usually this is what's called when you execute the key combo bound to this operation.
	UFUNCTION(Category = "Feather", BlueprintEvent)
	void Execute(FString Context = "")
	{
	}

// Settings API - It is recommended to use the JSON API here since that will work no matter the type of instance you are running (Standalone / PIE / Built).
// Another option is using the default ini-config system, but it will not work in all situations.
	UFUNCTION(BlueprintOverride)
	bool SaveSettings()
	{
		return Super::SaveSettings();
	}

	UFUNCTION(BlueprintOverride)
	bool LoadSettings()
	{
		return Super::LoadSettings();
	}

	UFUNCTION(BlueprintOverride)
	void ResetSettingsToDefault()
	{
		Super::ResetSettingsToDefault();
	}

//////////////////////////////////////////////////////////////////////////////////////////////////
// Static API - Should only be called from CDO

	// Unsupported debug operations should not show up in the interface.
	UFUNCTION(Category = "Feather", BlueprintEvent)
	bool Static_IsOperationSupported() const
	{
		bool bStandaloneTest = System::IsStandalone() || !bOnlyWorksInStandalone;
		return bStandaloneTest;
	}
};
