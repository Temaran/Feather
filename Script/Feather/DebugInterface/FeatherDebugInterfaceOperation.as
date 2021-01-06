// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.UtilWidgets.FeatherKeybindCaptureButton;
import Feather.FeatherWidget;

struct FDebugInterfaceOperationSaveState
{
	bool bIsFavourite;
	bool bSaveOperationState;
	FFeatherKeyCombination KeyCombination;
};

UCLASS(Abstract)
class UFeatherDebugInterfaceOperation : UFeatherWidget
{
	// The keybind button lets the user bind custom key combinations to execute this operation
	UPROPERTY(Category = "Feather")
	UFeatherKeybindCaptureButton KeybindButton;

	// The favourite button lets users add this operation to their favourites.
	UPROPERTY(Category = "Feather")
	UFeatherCheckBoxStyle FavouriteButton;

	// The save button lets users save their chosen operation state.
	UPROPERTY(Category = "Feather")
	UFeatherCheckBoxStyle SaveButton;

	// Should this operation save its state by default?
	UPROPERTY(Category = "Feather")
	bool bSaveByDefault = false;

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

//////////////////////////////////////////////////////////////////////////////////////////////////
// Final Overrides
// Don't override these further. I wish we had the final keyword in AS.

	UFUNCTION(BlueprintOverride)
	void SaveToString(FString& InOutSaveString) 
	{
		FDebugInterfaceOperationSaveState SaveState;
		SaveState.bIsFavourite = FavouriteButton.IsChecked();
		SaveState.bSaveOperationState = SaveButton.IsChecked();
		SaveState.KeyCombination = KeybindButton.KeyCombo;
		FJsonObjectConverter::AppendUStructToJsonObjectString(SaveState, InOutSaveString);

		if(SaveState.bSaveOperationState)
		{
			SaveOperationToString(InOutSaveString);
		}
	}

	UFUNCTION(BlueprintOverride)
	void LoadFromString(const FString& InSaveString) 
	{
		FDebugInterfaceOperationSaveState SaveState;
		if(FJsonObjectConverter::JsonObjectStringToUStruct(InSaveString, SaveState))
		{
			FavouriteButton.SetIsChecked(SaveState.bIsFavourite);
			SaveButton.SetIsChecked(SaveState.bSaveOperationState);
			KeybindButton.SetNewKeyCombo(SaveState.KeyCombination);

			if(SaveState.bSaveOperationState)
			{				
				LoadOperationFromString(InSaveString);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void FeatherConstruct()
	{
		Super::FeatherConstruct();
		Padding = AutoPadding;

		FMargin LeftPadding;
		LeftPadding.Left = 5.0f;
		
		FMargin SeparationPadding;
		SeparationPadding.Left = 20.0f;

		UHorizontalBox LayoutBox = Cast<UHorizontalBox>(ConstructWidget(UHorizontalBox::StaticClass()));
		SetRootWidget(LayoutBox);

		KeybindButton = Cast<UFeatherKeybindCaptureButton>(CreateStyledWidget(TSubclassOf<UFeatherWidget>(UFeatherKeybindCaptureButton::StaticClass())));
		UHorizontalBoxSlot KeybindSlot = LayoutBox.AddChildToHorizontalBox(KeybindButton);
		KeybindSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);
		KeybindButton.OnKeyBound.AddUFunction(this, n"KeyBound");
		KeybindButton.FeatherConstruct();

		FavouriteButton = CreateCheckBox(n"FavouriteButton");
		UHorizontalBoxSlot FavouriteSlot = LayoutBox.AddChildToHorizontalBox(FavouriteButton);
		FavouriteSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);
		FavouriteSlot.SetPadding(LeftPadding);
		FavouriteButton.SetToolTipText(FText::FromString("Favourite operations can be displayed by searching for 'Favourite'"));
		FavouriteButton.GetCheckBoxWidget().OnCheckStateChanged.AddUFunction(this, n"FavouriteStateChanged");

		SaveButton = CreateCheckBox(n"SaveButton");
		UHorizontalBoxSlot SaveSlot = LayoutBox.AddChildToHorizontalBox(SaveButton);
		SaveSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);
		SaveSlot.SetPadding(LeftPadding);
		SaveButton.SetToolTipText(FText::FromString("If this is checked, your current settings for this operation will be saved"));
		SaveButton.GetCheckBoxWidget().OnCheckStateChanged.AddUFunction(this, n"SaveStateChanged");
		SaveButton.SetIsChecked(bSaveByDefault);

		UNamedSlot Operation = Cast<UNamedSlot>(ConstructWidget(UNamedSlot::StaticClass()));
		UHorizontalBoxSlot OperationSlot = LayoutBox.AddChildToHorizontalBox(Operation);
		FSlateChildSize FillSize;
		FillSize.SizeRule = ESlateSizeRule::Fill;
		OperationSlot.SetSize(FillSize);
		OperationSlot.SetPadding(SeparationPadding);

		ConstructOperation(Operation);
	}

	UFUNCTION()
	void KeyBound(UFeatherKeybindCaptureButton CaptureButton, FFeatherKeyCombination KeyCombination)
	{
		SaveSettings();
	}

	UFUNCTION()
	void FavouriteStateChanged(bool bNewFavouriteState)
	{
		SaveSettings();
	}

	UFUNCTION()
	void SaveStateChanged(bool bNewSaveState)
	{
		SaveSettings();
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
	protected void ConstructOperation(UNamedSlot OperationRoot) { }

	// Execute this operation. This means different things depending on the operation. Usually this is what's called when you execute the key combo bound to this operation.
	UFUNCTION(Category = "Feather", BlueprintEvent)
	void Execute(FString Context = "") { }

// Settings API - It is recommended to use the JSON API here since that will work no matter the type of instance you are running (Standalone / PIE / Built).
// Another option is using the default ini-config system, but it will not work in all situations.
	UFUNCTION(Category = "Feather", BlueprintEvent)
	void SaveOperationToString(FString& InOutSaveString) { }

	UFUNCTION(Category = "Feather", BlueprintEvent)
	void LoadOperationFromString(const FString& InSaveString) { }

	UFUNCTION(BlueprintOverride)
	void ResetSettingsToDefault() { }

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
