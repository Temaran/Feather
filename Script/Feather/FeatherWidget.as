// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherStyle;
import Feather.FeatherSettings;

// This is the base class we use for all widgets. Supports styling.
UCLASS(Abstract)
class UFeatherWidget : UUserWidget
{
	default SetPaletteCategory(FText::FromString("Feather"));

	UPROPERTY(Category = "Feather", NotEditable)
	bool bIsLoading = false;

	UPROPERTY(Category = "Feather", NotEditable)
	bool bIsConstructed = false;

	UPROPERTY(Category = "Feather|Style")
	FFeatherStyle Style;


	// We want our own construct function that can be called after a style has been set.
	UFUNCTION(Category = "Feather")
	void ConstructFeatherWidget()
	{
		FeatherConstruct();
		bIsConstructed = true;
	}
	
	UFUNCTION(Category = "Feather", BlueprintEvent)
	protected void FeatherConstruct() { }

	UFUNCTION(Category = "Feather|Style")
	UFeatherWindowStyle CreateWindow(FName StyleName = NAME_None, FName Opt_WindowName = NAME_None)
	{
		return ensure(Style.WindowStyles.Contains(StyleName), "Requested style must exist!")
			? Cast<UFeatherWindowStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.WindowStyles[StyleName]), Opt_WindowName))
			: nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherButtonStyle CreateButton(FName StyleName = NAME_None, FName Opt_ButtonName = NAME_None)
	{
		return ensure(Style.ButtonStyles.Contains(StyleName), "Requested style must exist!")
			? Cast<UFeatherButtonStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.ButtonStyles[StyleName]), Opt_ButtonName))
			: nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherCheckBoxStyle CreateCheckBox(FName StyleName = NAME_None, FName Opt_CheckBoxName = NAME_None)
	{
		return ensure(Style.CheckBoxStyles.Contains(StyleName), "Requested style must exist!")
			? Cast<UFeatherCheckBoxStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.CheckBoxStyles[StyleName]), Opt_CheckBoxName))
			: nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherComboBoxStyle CreateComboBox(FName StyleName = NAME_None, FName Opt_ComboBoxName = NAME_None)
	{
		return ensure(Style.ComboBoxStyles.Contains(StyleName), "Requested style must exist!")
			? Cast<UFeatherComboBoxStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.ComboBoxStyles[StyleName]), Opt_ComboBoxName))
			: nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherSliderStyle CreateSlider(FName StyleName = NAME_None, FName Opt_SliderName = NAME_None)
	{
		return ensure(Style.SliderStyles.Contains(StyleName), "Requested style must exist!")
			? Cast<UFeatherSliderStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.SliderStyles[StyleName]), Opt_SliderName))
			: nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherTextBlockStyle CreateTextBlock(FName StyleName = NAME_None, FName Opt_TextBlockName = NAME_None)
	{
		return ensure(Style.TextBlockStyles.Contains(StyleName), "Requested style must exist!")
			? Cast<UFeatherTextBlockStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.TextBlockStyles[StyleName]), Opt_TextBlockName))
			: nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherEditableTextStyle CreateEditableText(FName StyleName = NAME_None, FName Opt_EditableTextName = NAME_None)
	{
		return ensure(Style.EditableTextStyles.Contains(StyleName), "Requested style must exist!")
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
			NewWidget.ConstructFeatherWidget();
		}

		return NewWidget;
	}

///////////////////////////////////////////////////////////////////////////////////////////////////

	// Call this when you want to save.
	UFUNCTION(Category = "Feather|Settings", BlueprintEvent, BlueprintCallable)
	void SaveSettings()
	{
		if(!bIsLoading && bIsConstructed)
		{		
			FString SaveString;
			SaveToString(SaveString);
			SaveString = SaveString.Replace("\r\n}{", ","); // Support widget hierarchies with unique save structs.
			FeatherSettings::SaveFeatherSettings(this, SaveString);
		}
	}

	// Call this when you want to load
	UFUNCTION(Category = "Feather|Settings", BlueprintEvent, BlueprintCallable)
	void LoadSettings()
	{
		if(!bIsLoading)
		{
			bIsLoading = true;
			FString LoadString;
			if(FeatherSettings::LoadFeatherSettings(this, LoadString))
			{
				LoadFromString(LoadString);
			}
			bIsLoading = false;
		}
	}

	// This is the main override to actually save your settings.
	UFUNCTION(Category = "Feather|Settings", BlueprintEvent)
	protected void SaveToString(FString& InOutSaveString) { }

	// This is the main override to actually load your settings.
	UFUNCTION(Category = "Feather|Settings", BlueprintEvent)
	protected void LoadFromString(const FString& InSaveString) { }

	// Reset all settings to the default
	UFUNCTION(Category = "Feather|Settings", BlueprintEvent)
	void ResetSettingsToDefault() {	}
};
