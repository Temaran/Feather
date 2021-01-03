// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceOperation;
import Feather.FeatherSettings;

struct FFeatherSimpleCheckBoxSaveState
{
	bool bIsChecked;
};

// An easy to use base class for simple operations that should have a checkbox!
UCLASS(Abstract)
class UFeatherSimpleCheckBoxOperationBase : UFeatherDebugInterfaceOperation
{
	UPROPERTY(Category = "Simple CheckBox")
	UHorizontalBox HorizontalBoxLayout;

	UPROPERTY(Category = "Simple CheckBox")
	UFeatherCheckBoxStyle MainCheckBox;

	UPROPERTY(Category = "Simple CheckBox")
	UFeatherTextBlockStyle MainCheckBoxLabel;

	UPROPERTY(Category = "Simple CheckBox")
	FText CheckBoxText;

	UPROPERTY(Category = "Simple CheckBox")
	FText CheckBoxToolTip;

	UPROPERTY(Category = "Simple CheckBox")
	float LabelSeparation = 10.0f;


	UFUNCTION(BlueprintOverride)
	void Execute(FString Context)
	{
		ECheckBoxState ToggleState = MainCheckBox.GetCheckBoxWidget().IsChecked() ? ECheckBoxState::Unchecked : ECheckBoxState::Checked;
		MainCheckBox.GetCheckBoxWidget().SetCheckedState(ToggleState);
	}

	UFUNCTION(BlueprintOverride)
	bool SaveSettings()
	{
		FFeatherSimpleCheckBoxSaveState SaveState;
		SaveState.bIsChecked = MainCheckBox.GetCheckBoxWidget().IsChecked();

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
		FFeatherSimpleCheckBoxSaveState SaveState;
		if(FeatherSettings::LoadFeatherSettings(this, SaveStateString)
			&& FJsonObjectConverter::JsonObjectStringToUStruct(SaveStateString, SaveState))
		{
			MainCheckBox.GetCheckBoxWidget().SetCheckedState(SaveState.bIsChecked ? ECheckBoxState::Checked : ECheckBoxState::Unchecked);
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ResetSettingsToDefault()
	{
		ECheckBoxState DefaultState = IsCheckedByDefault() ? ECheckBoxState::Checked : ECheckBoxState::Unchecked;
		MainCheckBox.GetCheckBoxWidget().SetCheckedState(DefaultState);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructOperation()
	{
		// Create layout
		HorizontalBoxLayout = Cast<UHorizontalBox>(ConstructWidget(TSubclassOf<UWidget>(UHorizontalBox::StaticClass())));
		SetRootWidget(HorizontalBoxLayout);

		// Create actual content
		MainCheckBox = CreateCheckBox();
		FMargin SeparationPadding;
		SeparationPadding.Right = LabelSeparation;
		MainCheckBox.SetPadding(SeparationPadding);
		HorizontalBoxLayout.AddChildToHorizontalBox(MainCheckBox);

		MainCheckBoxLabel = CreateTextBlock();
		HorizontalBoxLayout.AddChildToHorizontalBox(MainCheckBoxLabel);

		// Hook it up
		UTextBlock Text = MainCheckBoxLabel.GetTextWidget();
		Text.SetText(CheckBoxText);
		Text.SetToolTipText(CheckBoxToolTip);

		UCheckBox CheckBox = MainCheckBox.GetCheckBoxWidget();
		CheckBox.SetToolTipText(CheckBoxToolTip);
		CheckBox.SetCheckedState(IsCheckedByDefault() ? ECheckBoxState::Checked : ECheckBoxState::Unchecked);

		CheckBox.OnCheckStateChanged.AddUFunction(this, n"OnCheckStateChanged");
	}

//////////////////////////////////////////////////////
// Subclass API

	UFUNCTION(Category = "Simple CheckBox", BlueprintEvent)
	void OnCheckStateChanged(bool bChecked)
	{
	}

	UFUNCTION(Category = "Simple CheckBox", BlueprintEvent)
	bool IsCheckedByDefault() const
	{
		return false;
	}
};