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
	FFeatherHotkey Hotkey;
};

event void FOperationHotkeyBoundSignature(UFeatherDebugInterfaceOperation Operation, FFeatherHotkey Hotkey);

UCLASS(Abstract)
class UFeatherDebugInterfaceOperation : UFeatherWidget
{   
	UPROPERTY(Category = "Keybind Capture")
    FOperationHotkeyBoundSignature OnHotkeyBound;

	// The hotkey capture button lets the user bind custom key combinations to execute this operation
	UPROPERTY(Category = "Feather")
	UFeatherHotkeyCaptureButton HotkeyCaptureButton;

	// The favourite button lets users add this operation to their favourites.
	UPROPERTY(Category = "Feather")
	UFeatherCheckBoxStyle FavouriteButton;

	// The save button lets users save their chosen operation state.
	UPROPERTY(Category = "Feather")
	UFeatherCheckBoxStyle SaveButton;

	// Should this operation save its state by default?
	UPROPERTY(Category = "Feather", EditDefaultsOnly)
	bool bSaveByDefault = false;

	// Operations that only work in standalone should not even show up when running networked!
	UPROPERTY(Category = "Feather", EditDefaultsOnly)
	bool bOnlyWorksInStandalone = false;

	// Operations that can execute can have keys bound to them.
	UPROPERTY(Category = "Feather", EditDefaultsOnly)
	bool bCanExecute = true;

	// Operations that can save will have a button for it.
	UPROPERTY(Category = "Feather", EditDefaultsOnly)
	bool bCanSave = true;

	// These are the tags that will be matched when searching for operations.
	UPROPERTY(Category = "Feather", EditDefaultsOnly)
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
		SaveState.bSaveOperationState = System::IsValid(SaveButton) ? SaveButton.IsChecked() : false;
		SaveState.Hotkey = System::IsValid(HotkeyCaptureButton) ? HotkeyCaptureButton.Hotkey : FFeatherHotkey();
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
			if(System::IsValid(SaveButton))
			{
				SaveButton.SetIsChecked(SaveState.bSaveOperationState);
			}
			if(System::IsValid(HotkeyCaptureButton))
			{
				HotkeyCaptureButton.SetNewHotkey(SaveState.Hotkey);
			}

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

		const float SpacerWidth = LeftPadding.Left + SeparationPadding.Left;

		UHorizontalBox LayoutBox = Cast<UHorizontalBox>(ConstructWidget(UHorizontalBox::StaticClass()));
		SetRootWidget(LayoutBox);

		FavouriteButton = CreateCheckBox(n"FavouriteButton");
		UHorizontalBoxSlot FavouriteSlot = LayoutBox.AddChildToHorizontalBox(FavouriteButton);
		FavouriteSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);
		FavouriteButton.SetToolTipText(FText::FromString("Favourite operations can be displayed by searching for 'Favourite'"));
		FavouriteButton.GetCheckBoxWidget().OnCheckStateChanged.AddUFunction(this, n"FavouriteStateChanged");

		if(bCanSave)
		{
			SaveButton = CreateCheckBox(n"SaveButton");
			UHorizontalBoxSlot SaveSlot = LayoutBox.AddChildToHorizontalBox(SaveButton);
			SaveSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);
			SaveSlot.SetPadding(LeftPadding);
			SaveButton.SetToolTipText(FText::FromString("If this is checked, your current settings for this operation will be saved"));
			SaveButton.GetCheckBoxWidget().OnCheckStateChanged.AddUFunction(this, n"SaveStateChanged");
			SaveButton.SetIsChecked(bSaveByDefault);
		}
		else
		{
			USpacer SaveSpacer = Cast<USpacer>(ConstructWidget(USpacer::StaticClass()));
			LayoutBox.AddChildToHorizontalBox(SaveSpacer);
			SaveSpacer.SetSize(FVector2D(SpacerWidth, 10.0f));
		}

		if(bCanExecute)
		{
			HotkeyCaptureButton = Cast<UFeatherHotkeyCaptureButton>(CreateStyledWidget(TSubclassOf<UFeatherWidget>(UFeatherHotkeyCaptureButton::StaticClass())));
			UHorizontalBoxSlot KeybindSlot = LayoutBox.AddChildToHorizontalBox(HotkeyCaptureButton);
			KeybindSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);
			KeybindSlot.SetPadding(LeftPadding);
			HotkeyCaptureButton.OnHotkeyBound.AddUFunction(this, n"HotkeyBound");
			HotkeyCaptureButton.FeatherConstruct();
		}
		else
		{
			USpacer KeybindSpacer = Cast<USpacer>(ConstructWidget(USpacer::StaticClass()));
			LayoutBox.AddChildToHorizontalBox(KeybindSpacer);
			KeybindSpacer.SetSize(FVector2D(SpacerWidth, 10.0f));
		}
		
		UNamedSlot Operation = Cast<UNamedSlot>(ConstructWidget(UNamedSlot::StaticClass()));
		UHorizontalBoxSlot OperationSlot = LayoutBox.AddChildToHorizontalBox(Operation);
		FSlateChildSize FillSize;
		FillSize.SizeRule = ESlateSizeRule::Fill;
		OperationSlot.SetSize(FillSize);
		OperationSlot.SetPadding(SeparationPadding);

		ConstructOperation(Operation);
	}

	UFUNCTION()
	void HotkeyBound(UFeatherHotkeyCaptureButton CaptureButton, FFeatherHotkey Hotkey)
	{
		OnHotkeyBound.Broadcast(this, Hotkey);
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
	void Reset() 
	{
		FavouriteButton.SetIsChecked(false);
		if(System::IsValid(SaveButton))
		{
			SaveButton.SetIsChecked(bSaveByDefault);
		}
		if(System::IsValid(HotkeyCaptureButton))
		{
			HotkeyCaptureButton.SetNewHotkey(FFeatherHotkey());
		}
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
