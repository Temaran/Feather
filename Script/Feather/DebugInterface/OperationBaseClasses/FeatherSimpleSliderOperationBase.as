// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

#if !RELEASE
import Feather.DebugInterface.FeatherDebugInterfaceOperation;
import Feather.FeatherSettings;

struct FFeatherSimpleSliderSaveState
{
	float SliderValue;
};

// An easy to use base class for simple operations that should have a slider!
UCLASS(Abstract)
class UFeatherSimpleSliderOperationBase : UFeatherDebugInterfaceOperation
{
	UPROPERTY(Category = "Simple Slider")
	UHorizontalBox HorizontalBoxLayout;

	UPROPERTY(Category = "Simple Slider")
	UFeatherSliderStyle MainSlider;

	UPROPERTY(Category = "Simple Slider")
	UFeatherTextBlockStyle MainSliderLabel;

	UPROPERTY(Category = "Simple Slider")
	FText SliderLabelText;

	UPROPERTY(Category = "Simple Slider")
	FText SliderLabelToolTip;

	UPROPERTY(Category = "Simple Slider")
	FString SliderToolTipPrefix;

	UPROPERTY(Category = "Simple Slider")
	float LabelSeparation = 10.0f;


	UFUNCTION(BlueprintOverride)
	void SaveOperationToString(FString& InOutSaveString)
	{
		FFeatherSimpleSliderSaveState SaveState;
		SaveState.SliderValue = MainSlider.GetValue();
		FJsonObjectConverter::AppendUStructToJsonObjectString(SaveState, InOutSaveString);
	}

	UFUNCTION(BlueprintOverride)
	void LoadOperationFromString(const FString& InSaveString)
	{
		FFeatherSimpleSliderSaveState SaveState;
		if(FJsonObjectConverter::JsonObjectStringToUStruct(InSaveString, SaveState))
		{
			MainSlider.SetValue(SaveState.SliderValue);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Reset()
	{
		Super::Reset();
		
		MainSlider.SetValue(GetDefaultSliderValue());
	}

	UFUNCTION(BlueprintOverride)
	void ConstructOperation(UNamedSlot OperationRoot)
	{
		// Create layout
		HorizontalBoxLayout = Cast<UHorizontalBox>(ConstructWidget(TSubclassOf<UWidget>(UHorizontalBox::StaticClass())));
        OperationRoot.SetContent(HorizontalBoxLayout);

		// Create actual content
		MainSliderLabel = CreateTextBlock();
		FMargin SeparationPadding;
		SeparationPadding.Right = LabelSeparation;
		MainSliderLabel.SetPadding(SeparationPadding);
		HorizontalBoxLayout.AddChildToHorizontalBox(MainSliderLabel);

		MainSlider = CreateSlider();
		UHorizontalBoxSlot SliderSlot = HorizontalBoxLayout.AddChildToHorizontalBox(MainSlider);
		FSlateChildSize FillSize;
		FillSize.SizeRule = ESlateSizeRule::Fill;
		SliderSlot.SetSize(FillSize);

		// Hook it up
		UTextBlock Text = MainSliderLabel.GetTextWidget();
		Text.SetText(SliderLabelText);
		Text.SetToolTipText(SliderLabelToolTip);

		USlider Slider = MainSlider.GetSliderWidget();
		Slider.SetValue(GetDefaultSliderValue());
		Slider.SetToolTipText(FText::FromString(SliderToolTipPrefix + Slider.GetValue()));

		Slider.OnValueChanged.AddUFunction(this, n"OnSliderValueChanged_Internal");
	}

	UFUNCTION()
	void OnSliderValueChanged_Internal(float NewSliderValue)
	{
		MainSlider.GetSliderWidget().SetToolTipText(FText::FromString(SliderToolTipPrefix + NewSliderValue));
		SaveSettings();
		OnSliderValueChanged(NewSliderValue);
	}

//////////////////////////////////////////////////////
// Subclass API

	UFUNCTION(Category = "Simple Slider", BlueprintEvent)
	void OnSliderValueChanged(float NewSliderValue)
	{
	}

	UFUNCTION(Category = "Simple Slider", BlueprintEvent)
	float GetDefaultSliderValue() const
	{
		return 0.0f;
	}
};
#endif // RELEASE
