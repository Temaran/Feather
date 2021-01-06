// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.OperationBaseClasses.FeatherSimpleSliderOperationBase;

// This adds a simple slider to control time dilation in the game.
class UFeatherTimeDilationOperation : UFeatherSimpleSliderOperationBase
{
	default OperationTags.Add(n"General");
	default OperationTags.Add(n"Time");

	default bCanExecute = false;

	default SliderLabelText = FText::FromString("Time Dilation");
	default SliderLabelToolTip = FText::FromString("Control how quickly time flows for everyone.");
	default SliderToolTipPrefix = "Time Dilation: ";


	UFUNCTION(BlueprintOverride)
	float GetDefaultSliderValue() const
	{
		return 1.0f;
	}

	UFUNCTION(BlueprintOverride)
	void OnSliderValueChanged(float NewSliderValue)
	{
		Gameplay::SetGlobalTimeDilation(NewSliderValue);
	}
};
