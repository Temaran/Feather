// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceOperation;
import Feather.FeatherSettings;

// An easy to use base class for simple operations that should have a checkbox!
UCLASS(Abstract)
class UFeatherSimpleButtonOperationBase : UFeatherDebugInterfaceOperation
{
	UPROPERTY(Category = "Simple Button")
	UFeatherButtonStyle MainButton;

	UPROPERTY(Category = "Simple Button")
	UFeatherTextBlockStyle MainButtonText;

	UPROPERTY(Category = "Simple Button")
	FText ButtonText;

	UPROPERTY(Category = "Simple Button")
	FText ButtonToolTip;


	UFUNCTION(BlueprintOverride)
	void Execute(FString Context)
	{
		OnButtonClicked();
	}

	UFUNCTION(BlueprintOverride)
	void ConstructOperation(UNamedSlot OperationRoot)
	{
		// Setup button
		MainButtonText = CreateTextBlock();
		UTextBlock Text = MainButtonText.GetTextWidget();
		Text.SetText(ButtonText);
		Text.SetToolTipText(ButtonToolTip);

		MainButton = CreateButton();
        OperationRoot.SetContent(MainButton);
		UButton Button = MainButton.GetButtonWidget();
		Button.SetContent(MainButtonText);
		Button.SetToolTipText(ButtonToolTip);
		Button.OnClicked.AddUFunction(this, n"OnButtonClicked");
	}

//////////////////////////////////////////////////////
// Subclass API

	UFUNCTION(Category = "Simple Button", BlueprintEvent)
	void OnButtonClicked()
	{
	}
};