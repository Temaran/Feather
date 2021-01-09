// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

#if !RELEASE
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
		MainCheckBox.SetIsChecked(!MainCheckBox.IsChecked());
	}

	UFUNCTION(BlueprintOverride)
	void SaveOperationToString(FString& InOutSaveString)
	{
		FFeatherSimpleCheckBoxSaveState SaveState;
		SaveState.bIsChecked = MainCheckBox.IsChecked();
		FJsonObjectConverter::AppendUStructToJsonObjectString(SaveState, InOutSaveString);
	}

	UFUNCTION(BlueprintOverride)
	void LoadOperationFromString(const FString& InSaveString)
	{
		FFeatherSimpleCheckBoxSaveState SaveState;
		if(FJsonObjectConverter::JsonObjectStringToUStruct(InSaveString, SaveState))
		{
			MainCheckBox.SetIsChecked(SaveState.bIsChecked);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Reset()
	{
		Super::Reset();
		
		MainCheckBox.SetIsChecked(IsCheckedByDefault());
	}

	UFUNCTION(BlueprintOverride)
	void ConstructOperation(UNamedSlot OperationRoot)
	{
		// Create layout
		HorizontalBoxLayout = Cast<UHorizontalBox>(ConstructWidget(TSubclassOf<UWidget>(UHorizontalBox::StaticClass())));
        OperationRoot.SetContent(HorizontalBoxLayout);

		// Create actual content
		MainCheckBox = CreateCheckBox();
		FMargin SeparationPadding;
		SeparationPadding.Right = LabelSeparation;
		MainCheckBox.SetPadding(SeparationPadding);
		UHorizontalBoxSlot MainSlot = HorizontalBoxLayout.AddChildToHorizontalBox(MainCheckBox);
		MainSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);

		MainCheckBoxLabel = CreateTextBlock();
		HorizontalBoxLayout.AddChildToHorizontalBox(MainCheckBoxLabel);

		// Hook it up
		UTextBlock Text = MainCheckBoxLabel.GetTextWidget();
		Text.SetText(CheckBoxText);
		Text.SetToolTipText(CheckBoxToolTip);

		UCheckBox CheckBox = MainCheckBox.GetCheckBoxWidget();
		CheckBox.SetToolTipText(CheckBoxToolTip);
		CheckBox.SetIsChecked(IsCheckedByDefault());

		CheckBox.OnCheckStateChanged.AddUFunction(this, n"OnCheckStateChanged_Internal");
	}

	UFUNCTION()
	void OnCheckStateChanged_Internal(bool bChecked)
	{
        SaveSettings();
		OnCheckStateChanged(bChecked);
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
#endif // RELEASE
