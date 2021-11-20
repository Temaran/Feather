// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

class UFeatherWindowSelectionBox : UFeatherWidget
{
	UPROPERTY(Category = "Feather", NotEditable)
	TArray<UFeatherDebugInterfaceToolWindow> ToolWindows;

	UFUNCTION(BlueprintOverride)
	void FeatherConstruct(FFeatherStyle InStyle, FFeatherConfig InConfig)
	{
		Super::FeatherConstruct(InStyle, InConfig);

		GetMenuPanel().ClearChildren();
		for(UFeatherDebugInterfaceWindow Window : ToolWindows)
		{
			Window.SetVisibility(ESlateVisibility::Collapsed);

			UFeatherButtonStyle WindowButton = CreateButton();
			UFeatherTextBlockStyle WindowText = CreateTextBlock();
			WindowText.GetTextWidget().SetText(FText::FromString(Window.WindowName.ToString()));
			WindowButton.GetButtonWidget().SetContent(WindowText);
			WindowButton.OnClickedWithContext.AddUFunction(this, n"WindowButtonClicked");
			GetMenuPanel().AddChildToVerticalBox(WindowButton);
		}

		GetMenuButton().OnCheckStateChanged.AddUFunction(this, n"MenuButtonStateChanged");

		GetMenuPanel().SetVisibility(ESlateVisibility::Collapsed);
	}

	UFUNCTION()
	void MenuButtonStateChanged(bool bNewSearchState)
	{
		GetMenuPanel().SetVisibility(bNewSearchState
			? ESlateVisibility::Visible : ESlateVisibility::Collapsed);
	}

	UFUNCTION()
	void WindowButtonClicked(UFeatherButtonStyle ClickedButton)
	{
		FText ClickedWindowName = Cast<UFeatherTextBlockStyle>(ClickedButton.GetButtonWidget().GetContent()).GetTextWidget().GetText();

		for(UFeatherDebugInterfaceWindow Window : ToolWindows)
		{
			if(Window.WindowName == FName(ClickedWindowName.ToString()))
			{
				Window.SetVisibility(ESlateVisibility::Visible);
				Window.ForceWindowOnTop();
				Window.SaveSettings();
				break;
			}
		}

		GetMenuButton().SetCheckedState(ECheckBoxState::Unchecked);
		GetMenuPanel().SetVisibility(ESlateVisibility::Collapsed);
	}

///////////////////////////////////////////////////////////////////////

	UFUNCTION(Category = "Feather", BlueprintEvent)
	UCheckBox GetMenuButton()
	{
		return nullptr;
	}

	UFUNCTION(Category = "Feather", BlueprintEvent)
	UVerticalBox GetMenuPanel()
	{
		return nullptr;
	}
};
