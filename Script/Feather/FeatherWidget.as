// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherStyle;

// This is the base class we use for all widgets. Supports styling.
UCLASS(Abstract)
class UFeatherWidget : UUserWidget
{
	default SetPaletteCategory(FText::FromString("Feather"));

	UPROPERTY(Category = "Feather|Style")
	FFeatherStyle Style;

	// We want our own construct function that can be called after a style has been set.
	UFUNCTION(Category = "Feather", BlueprintEvent)
	void FeatherConstruct()
	{
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherWindowStyle CreateWindow(FName Opt_WindowName = NAME_None)
	{
		return Cast<UFeatherWindowStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.WindowStyle), Opt_WindowName));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherButtonStyle CreateButton(FName Opt_ButtonName = NAME_None)
	{
		return Cast<UFeatherButtonStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.ButtonStyle), Opt_ButtonName));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherCheckBoxStyle CreateCheckBox(FName Opt_CheckBoxName = NAME_None)
	{
		return Cast<UFeatherCheckBoxStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.CheckBoxStyle), Opt_CheckBoxName));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherComboBoxStyle CreateComboBox(FName Opt_ComboBoxName = NAME_None)
	{
		return Cast<UFeatherComboBoxStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.ComboBoxStyle), Opt_ComboBoxName));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherSliderStyle CreateSlider(FName Opt_SliderName = NAME_None)
	{
		return Cast<UFeatherSliderStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.SliderStyle), Opt_SliderName));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherTextBlockStyle CreateTextBlock(FName Opt_TextBlockName = NAME_None)
	{
		return Cast<UFeatherTextBlockStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.TextBlockStyle), Opt_TextBlockName));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherEditableTextStyle CreateEditableText(FName Opt_EditableTextName = NAME_None)
	{
		return Cast<UFeatherEditableTextStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.EditableTextStyle), Opt_EditableTextName));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherWidget CreateStyledWidget(TSubclassOf<UFeatherWidget> WidgetClass, bool bConstructRightAway = false, FName Opt_WidgetName = NAME_None)
	{
		UFeatherWidget NewWidget = Cast<UFeatherWidget>(ConstructWidget(WidgetClass, Opt_WidgetName));
		NewWidget.Style = Style;
		
		if(bConstructRightAway)
		{
			NewWidget.FeatherConstruct();
		}

		return NewWidget;
	}

///////////////////////////////////////////////////////////////////////////////////////////////////

	// Save operation settings. Use the FeatherSettings namespace to do stuff in here!
	UFUNCTION(Category = "Feather|Settings", BlueprintEvent)
	bool SaveSettings()
	{
		return false;
	}

	// Load operation settings. Use the FeatherSettings namespace to do stuff in here!
	UFUNCTION(Category = "Feather|Settings", BlueprintEvent)
	bool LoadSettings()
	{
		return false;
	}

	// Reset all settings to the default
	UFUNCTION(Category = "Feather|Settings", BlueprintEvent)
	void ResetSettingsToDefault()
	{
	}
};
