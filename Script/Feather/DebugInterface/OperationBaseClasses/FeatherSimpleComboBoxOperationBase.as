// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceOperation;
import Feather.FeatherSettings;

struct FFeatherSimpleComboBoxSaveState
{
	int SelectedIndex;
};

// An easy to use base class for simple operations that should have a combo box!
UCLASS(Abstract)
class UFeatherSimpleComboBoxOperationBase : UFeatherDebugInterfaceOperation
{
	UPROPERTY(Category = "Simple ComboBox")
	UHorizontalBox HorizontalBoxLayout;

	UPROPERTY(Category = "Simple ComboBox")
	UFeatherComboBoxStyle MainComboBox;

	UPROPERTY(Category = "Simple ComboBox")
	UFeatherTextBlockStyle MainComboBoxLabel;

	UPROPERTY(Category = "Simple ComboBox")
	FText ComboBoxLabelText;

	UPROPERTY(Category = "Simple ComboBox")
	TArray<FString> ComboBoxEntries;

	UPROPERTY(Category = "Simple ComboBox")
	FText ComboBoxToolTip;

	UPROPERTY(Category = "Simple ComboBox")
	float LabelSeparation = 10.0f;


	UFUNCTION(BlueprintOverride)
	bool SaveSettings()
	{
		FFeatherSimpleComboBoxSaveState SaveState;
		SaveState.SelectedIndex = MainComboBox.GetComboBoxWidget().GetSelectedIndex();

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
		FFeatherSimpleComboBoxSaveState SaveState;
		if(FeatherSettings::LoadFeatherSettings(this, SaveStateString)
			&& FJsonObjectConverter::JsonObjectStringToUStruct(SaveStateString, SaveState))
		{
			MainComboBox.GetComboBoxWidget().SetSelectedIndex(SaveState.SelectedIndex);
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ResetSettingsToDefault()
	{
		MainComboBox.GetComboBoxWidget().SetSelectedIndex(GetDefaultSelectedOptionIndex());
	}

	UFUNCTION(BlueprintOverride)
	void ConstructOperation()
	{
		// Create layout
		HorizontalBoxLayout = Cast<UHorizontalBox>(ConstructWidget(TSubclassOf<UWidget>(UHorizontalBox::StaticClass())));
		SetRootWidget(HorizontalBoxLayout);

		// Create actual content
		MainComboBoxLabel = CreateTextBlock();
		FMargin SeparationPadding;
		SeparationPadding.Right = LabelSeparation;
		MainComboBoxLabel.SetPadding(SeparationPadding);
		HorizontalBoxLayout.AddChildToHorizontalBox(MainComboBoxLabel);

		MainComboBox = CreateComboBox();
		UHorizontalBoxSlot ComboBoxSlot = HorizontalBoxLayout.AddChildToHorizontalBox(MainComboBox);
		FSlateChildSize FillSize;
		FillSize.SizeRule = ESlateSizeRule::Fill;
		ComboBoxSlot.SetSize(FillSize);

		// Hook it up
		UTextBlock Text = MainComboBoxLabel.GetTextWidget();
		Text.SetText(ComboBoxLabelText);
		Text.SetToolTipText(ComboBoxToolTip);

		UComboBoxString ComboBox = MainComboBox.GetComboBoxWidget();
		ComboBox.SetToolTipText(ComboBoxToolTip);
		for(FString ComboBoxEntry : ComboBoxEntries)
		{
			ComboBox.AddOption(ComboBoxEntry);
		}
		ComboBox.SetSelectedIndex(GetDefaultSelectedOptionIndex());

		ComboBox.OnSelectionChanged.AddUFunction(this, n"OnComboBoxSelectionChanged");
	}

	UFUNCTION()
	void OnComboBoxSelectionChanged_Internal(FString NewSelectedItem, ESelectInfo SelectionType)
	{
		SaveSettings();
		OnComboBoxSelectionChanged(NewSelectedItem, SelectionType);
	}

//////////////////////////////////////////////////////
// Subclass API

	UFUNCTION(Category = "Simple ComboBox", BlueprintEvent)
	void OnComboBoxSelectionChanged(FString NewSelectedItem, ESelectInfo SelectionType)
	{
	}

	UFUNCTION(Category = "Simple ComboBox", BlueprintEvent)
	int GetDefaultSelectedOptionIndex() const
	{
		return 0;
	}
};