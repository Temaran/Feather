// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceOperation;
import Feather.DebugInterface.FeatherDebugInterfaceUtils;
import Feather.FeatherSettings;

struct FAbilitySystemDebugSaveState
{
	bool bShowingDebug;
};

// Adds a more user friendly way of interacting with the ability system debugger.
class UAbilitySystemDebugOperation : UFeatherDebugInterfaceOperation
{
	default OperationTags.Add(n"GAS");

	UPROPERTY(Category = "Ability System Debug", NotEditable)
	UFeatherCheckBoxStyle ShowAbilitySystemDebugCheckBox;
    
	UPROPERTY(Category = "Ability System Debug", NotEditable)
	UFeatherButtonStyle PreviousActorButton;
    
	UPROPERTY(Category = "Ability System Debug", NotEditable)
	UFeatherButtonStyle NextActorButton;
    
	UPROPERTY(Category = "Ability System Debug", NotEditable)
	UFeatherButtonStyle ChangeCategoryButton;


	UFUNCTION(BlueprintOverride)
	void Execute(FString Context)
	{
        ShowAbilitySystemDebugCheckBox.GetCheckBoxWidget().SetIsChecked(!ShowAbilitySystemDebugCheckBox.GetCheckBoxWidget().IsChecked());
	}

	UFUNCTION(BlueprintOverride)
	bool SaveSettings()
	{
		FAbilitySystemDebugSaveState SaveState;
        SaveState.bShowingDebug = ShowAbilitySystemDebugCheckBox.GetCheckBoxWidget().IsChecked();

		FString SaveStateString;
		if(FJsonObjectConverter::UStructToJsonObjectString(SaveState, SaveStateString))
		{
			return FeatherSettings::SaveFeatherSettings(this, SaveStateString);
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool LoadSettings()
	{
		FString SaveStateString;
		FAbilitySystemDebugSaveState SaveState;
		if(FeatherSettings::LoadFeatherSettings(this, SaveStateString)
			&& FJsonObjectConverter::JsonObjectStringToUStruct(SaveStateString, SaveState))
		{
            ShowAbilitySystemDebugCheckBox.GetCheckBoxWidget().SetIsChecked(SaveState.bShowingDebug);
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ResetSettingsToDefault()
	{
        ShowAbilitySystemDebugCheckBox.GetCheckBoxWidget().SetIsChecked(false);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructOperation()
	{
        FMargin LeftPadding;
        LeftPadding.Left = 10.0f;

        FMargin RightPadding;
        RightPadding.Right = 10.0f;

        // Setup widget hierarchy
        UHorizontalBox HorizontalLayout = Cast<UHorizontalBox>(ConstructWidget(UHorizontalBox::StaticClass()));
        SetRootWidget(HorizontalLayout);

        ShowAbilitySystemDebugCheckBox = CreateCheckBox();
        UHorizontalBoxSlot CheckBoxSlot = HorizontalLayout.AddChildToHorizontalBox(ShowAbilitySystemDebugCheckBox);
        ShowAbilitySystemDebugCheckBox.GetCheckBoxWidget().OnCheckStateChanged.AddUFunction(this, n"OnShowAbilityCheckBoxStateChanged");
        CheckBoxSlot.SetPadding(RightPadding);
        CheckBoxSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);

        UFeatherTextBlockStyle CheckBoxLabel = CreateTextBlock();
        UHorizontalBoxSlot LabelSlot = HorizontalLayout.AddChildToHorizontalBox(CheckBoxLabel);
        FSlateChildSize FillSize;
        FillSize.SizeRule = ESlateSizeRule::Fill;
        LabelSlot.SetSize(FillSize);
        LabelSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);        
        CheckBoxLabel.GetTextWidget().SetText(FText::FromString("Show Ability System Debug"));

        PreviousActorButton = CreateButton();
        HorizontalLayout.AddChildToHorizontalBox(PreviousActorButton);
        PreviousActorButton.GetButtonWidget().OnClicked.AddUFunction(this, n"OnPreviousActor");
        UFeatherTextBlockStyle PreviousActorText = CreateTextBlock();
        PreviousActorButton.GetButtonWidget().SetContent(PreviousActorText);
        PreviousActorText.GetTextWidget().SetText(FText::FromString(" ^ "));
        
        NextActorButton = CreateButton();
        UHorizontalBoxSlot NextActorSlot = HorizontalLayout.AddChildToHorizontalBox(NextActorButton);
        NextActorButton.GetButtonWidget().OnClicked.AddUFunction(this, n"OnNextActor");
        NextActorSlot.SetPadding(LeftPadding);
        UFeatherTextBlockStyle NextActorText = CreateTextBlock();
        NextActorButton.GetButtonWidget().SetContent(NextActorText);
        NextActorText.GetTextWidget().SetText(FText::FromString(" ^ "));
        NextActorButton.SetRenderTransformAngle(180.0f);
        
        ChangeCategoryButton = CreateButton();
        UHorizontalBoxSlot ChangeCategorySlot = HorizontalLayout.AddChildToHorizontalBox(ChangeCategoryButton);
        ChangeCategoryButton.GetButtonWidget().OnClicked.AddUFunction(this, n"OnChangeCategory");
        ChangeCategorySlot.SetPadding(LeftPadding);
        UFeatherTextBlockStyle ChangeCategoryText = CreateTextBlock();
        ChangeCategoryButton.GetButtonWidget().SetContent(ChangeCategoryText);
        ChangeCategoryText.GetTextWidget().SetText(FText::FromString(" Category "));
	}

    UFUNCTION()
    void OnShowAbilityCheckBoxStateChanged(bool bNewCheckState)
    {
        System::ExecuteConsoleCommand(bNewCheckState ? "ShowDebug AbilitySystem" : "ShowDebug");
        SaveSettings();
    }

    UFUNCTION()
    void OnPreviousActor()
    {
        System::ExecuteConsoleCommand("AbilitySystem.Debug.PrevTarget");
    }

    UFUNCTION()
    void OnNextActor()
    {
        System::ExecuteConsoleCommand("AbilitySystem.Debug.NextTarget");
    }

    UFUNCTION()
    void OnChangeCategory()
    {
        System::ExecuteConsoleCommand("AbilitySystem.Debug.NextCategory");
    }
};
