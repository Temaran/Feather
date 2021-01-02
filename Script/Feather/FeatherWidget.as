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
	UFeatherWindowStyle CreateWindow(FName StyleName = NAME_None, FName Opt_WindowName = NAME_None)
	{
		return Style.WindowStyles.Contains(StyleName)
			? Cast<UFeatherWindowStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.WindowStyles[StyleName]), Opt_WindowName))
			: nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherButtonStyle CreateButton(FName StyleName = NAME_None, FName Opt_ButtonName = NAME_None)
	{
		return Style.ButtonStyles.Contains(StyleName)
			? Cast<UFeatherButtonStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.ButtonStyles[StyleName]), Opt_ButtonName))
			: nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherCheckBoxStyle CreateCheckBox(FName StyleName = NAME_None, FName Opt_CheckBoxName = NAME_None)
	{
		return Style.CheckBoxStyles.Contains(StyleName)
			? Cast<UFeatherCheckBoxStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.CheckBoxStyles[StyleName]), Opt_CheckBoxName))
			: nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherComboBoxStyle CreateComboBox(FName StyleName = NAME_None, FName Opt_ComboBoxName = NAME_None)
	{
		return Style.ComboBoxStyles.Contains(StyleName)
			? Cast<UFeatherComboBoxStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.ComboBoxStyles[StyleName]), Opt_ComboBoxName))
			: nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherSliderStyle CreateSlider(FName StyleName = NAME_None, FName Opt_SliderName = NAME_None)
	{
		return Style.SliderStyles.Contains(StyleName)
			? Cast<UFeatherSliderStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.SliderStyles[StyleName]), Opt_SliderName))
			: nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherTextBlockStyle CreateTextBlock(FName StyleName = NAME_None, FName Opt_TextBlockName = NAME_None)
	{
		return Style.TextBlockStyles.Contains(StyleName)
			? Cast<UFeatherTextBlockStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.TextBlockStyles[StyleName]), Opt_TextBlockName))
			: nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherEditableTextStyle CreateEditableText(FName StyleName = NAME_None, FName Opt_EditableTextName = NAME_None)
	{
		return Style.EditableTextStyles.Contains(StyleName)
			? Cast<UFeatherEditableTextStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.EditableTextStyles[StyleName]), Opt_EditableTextName))
			: nullptr;
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
