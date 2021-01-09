// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherStyle;
import Feather.FeatherSettings;

event void FSettingsSavedEvent(UFeatherWidget Widget);
event void FSettingsLoadedEvent(UFeatherWidget Widget);
event void FResetToDefaultEvent(UFeatherWidget Widget);

// This is the base class we use for all widgets. Supports styling.
UCLASS(Abstract)
class UFeatherWidget : UUserWidget
{
	default SetPaletteCategory(FText::FromString("Feather"));

	UPROPERTY(Category = "Feather")
	FSettingsSavedEvent OnSettingsSaved;

	UPROPERTY(Category = "Feather")
	FSettingsLoadedEvent OnSettingsLoaded;
	
	UPROPERTY(Category = "Feather")
	FResetToDefaultEvent OnResetToDefault;

	UPROPERTY(Category = "Feather", NotEditable)
	bool bIsPossibleToSave = false;

	UPROPERTY(Category = "Feather|Style")
	FFeatherStyle Style;

	// This cascades down from the root
	FFeatherConfig FeatherConfiguration;

	// We want our own construct function that can be called after a style has been set.
	// Generally, you should be calling this yourself when you have set all necessary input variables.
	UFUNCTION(Category = "Feather", BlueprintEvent)
	void FeatherConstruct(FFeatherStyle InStyle, FFeatherConfig InConfig)
	{
		Style = InStyle;
		FeatherConfiguration = InConfig;
	}

	UFUNCTION(BlueprintOverride)
	void Construct()	
	{
		bIsPossibleToSave = true;
	}
	
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
	UFeatherMultiLineEditableTextStyle CreateMultiLineEditableText(FName StyleName = NAME_None, FName Opt_EditableTextName = NAME_None)
	{
		return ensure(Style.MultiLineEditableTextStyles.Contains(StyleName), "Requested style must exist!")
			? Cast<UFeatherMultiLineEditableTextStyle>(ConstructWidget(TSubclassOf<UWidget>(Style.MultiLineEditableTextStyles[StyleName]), Opt_EditableTextName))
			: nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherWidget CreateStyledWidget(TSubclassOf<UFeatherWidget> WidgetClass, bool bConstructRightAway = false, FName Opt_WidgetName = NAME_None)
	{
		UFeatherWidget NewWidget = Cast<UFeatherWidget>(ConstructWidget(WidgetClass, Opt_WidgetName));
		
		if(bConstructRightAway)
		{
			NewWidget.FeatherConstruct(Style, FeatherConfiguration);
		}

		return NewWidget;
	}

///////////////////////////////////////////////////////////////////////////////////////////////////

	// Call this when you want to save.
	UFUNCTION(Category = "Feather|Settings", BlueprintEvent, BlueprintCallable)
	void SaveSettings()
	{
		if(bIsPossibleToSave)
		{		
			FString SaveString;
			SaveToString(SaveString);
			FeatherSettings::SaveFeatherSettings(this, SaveString, FeatherConfiguration);
			OnSettingsSaved.Broadcast(this);
		}
	}

	// Call this when you want to load
	UFUNCTION(Category = "Feather|Settings", BlueprintEvent, BlueprintCallable)
	void LoadSettings()
	{
		if(bIsPossibleToSave)
		{
			bIsPossibleToSave = false;
			FString LoadString;
			if(FeatherSettings::LoadFeatherSettings(this, LoadString, FeatherConfiguration))
			{
				LoadFromString(LoadString);
			}
			bIsPossibleToSave = true;
			OnSettingsLoaded.Broadcast(this);
		}
	}

	// This is the main override to actually save your settings.
	UFUNCTION(Category = "Feather|Settings", BlueprintEvent)
	protected void SaveToString(FString& InOutSaveString) { }

	// This is the main override to actually load your settings.
	UFUNCTION(Category = "Feather|Settings", BlueprintEvent)
	protected void LoadFromString(const FString& InSaveString) { }

	// Reset all settings to the default
	UFUNCTION(Category = "Feather|Settings")
	void ResetSettingsToDefault() 
	{
		bIsPossibleToSave = false;
		Reset();
		bIsPossibleToSave = true;
		OnResetToDefault.Broadcast(this);
	}

	UFUNCTION(Category = "Feather|Settings", BlueprintEvent)
	void Reset() { }
};
