// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherStyle;
import Feather.FeatherSettings;

event void FSettingsSavedEvent(UFeatherWidget Widget);
event void FSettingsLoadedEvent(UFeatherWidget Widget);
event void FResetToDefaultEvent(UFeatherWidget Widget);

// This is the base class we use for all widgets. Supports styling. Not having templates is rough sometimes..
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
	FFeatherStyle FeatherStyle;

	// This cascades down from the root
	FFeatherConfig FeatherConfiguration;

	// We want our own construct function that can be called after a style has been set.
	// Generally, you should be calling this yourself when you have set all necessary input variables.
	UFUNCTION(Category = "Feather", BlueprintEvent)
	void FeatherConstruct(FFeatherStyle InStyle, FFeatherConfig InConfig)
	{
		FeatherConfiguration = InConfig;

		// Cascade styles
		for(auto StyleData : InStyle.DefaultStyles)
		{
			if(!FeatherStyle.DefaultStyles.Contains(StyleData))
			{
				FeatherStyle.DefaultStyles.Add(StyleData);
			}
		}
		
		for(auto StyleData : InStyle.NamedStyles)
		{
			if(!FeatherStyle.NamedStyles.Contains(StyleData.Key))
			{
				FeatherStyle.NamedStyles.Add(StyleData.Key, StyleData.Value);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Construct()	
	{
		bIsPossibleToSave = true;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherWidget CreateStyledWidget(TSubclassOf<UFeatherWidget> WidgetClass, bool bConstructRightAway = false, FName Opt_WidgetName = NAME_None)
	{
		UFeatherWidget NewWidget = Cast<UFeatherWidget>(ConstructWidget(WidgetClass, Opt_WidgetName));
		
		if(bConstructRightAway)
		{
			NewWidget.FeatherConstruct(FeatherStyle, FeatherConfiguration);
		}

		return NewWidget;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherStyleBase CreateStyle(TSubclassOf<UFeatherStyleBase> StyleType, FName StyleName, FName Opt_Name = NAME_None)
	{
		if(FeatherStyle.NamedStyles.Contains(StyleName))
		{
			return Cast<UFeatherStyleBase>(ConstructWidget(TSubclassOf<UWidget>(FeatherStyle.NamedStyles[StyleName]), Opt_Name));
		}
		else
		{
			for(TSubclassOf<UFeatherStyleBase> DefaultStyle : FeatherStyle.DefaultStyles)
			{
				if(DefaultStyle.IsValid() && DefaultStyle.Get().IsChildOf(StyleType))
				{
					return Cast<UFeatherStyleBase>(ConstructWidget(TSubclassOf<UWidget>(DefaultStyle), Opt_Name));
				}
			}			
		}

		Error("Style could not be created! No named style was found (Name: " + StyleName.ToString() + "), and a default style did not exist!");
		return nullptr;
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherWindowStyle CreateWindow(FName StyleName = NAME_None, FName Opt_Name = NAME_None)
	{
		return Cast<UFeatherWindowStyle>(CreateStyle(TSubclassOf<UFeatherStyleBase>(UFeatherWindowStyle::StaticClass()), StyleName, Opt_Name));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherButtonStyle CreateButton(FName StyleName = NAME_None, FName Opt_Name = NAME_None)
	{
		return Cast<UFeatherButtonStyle>(CreateStyle(TSubclassOf<UFeatherStyleBase>(UFeatherButtonStyle::StaticClass()), StyleName, Opt_Name));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherCheckBoxStyle CreateCheckBox(FName StyleName = NAME_None, FName Opt_Name = NAME_None)
	{
		return Cast<UFeatherCheckBoxStyle>(CreateStyle(TSubclassOf<UFeatherStyleBase>(UFeatherCheckBoxStyle::StaticClass()), StyleName, Opt_Name));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherComboBoxStyle CreateComboBox(FName StyleName = NAME_None, FName Opt_Name = NAME_None)
	{
		return Cast<UFeatherComboBoxStyle>(CreateStyle(TSubclassOf<UFeatherStyleBase>(UFeatherComboBoxStyle::StaticClass()), StyleName, Opt_Name));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherSliderStyle CreateSlider(FName StyleName = NAME_None, FName Opt_Name = NAME_None)
	{
		return Cast<UFeatherSliderStyle>(CreateStyle(TSubclassOf<UFeatherStyleBase>(UFeatherSliderStyle::StaticClass()), StyleName, Opt_Name));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherTextBlockStyle CreateTextBlock(FName StyleName = NAME_None, FName Opt_Name = NAME_None)
	{
		return Cast<UFeatherTextBlockStyle>(CreateStyle(TSubclassOf<UFeatherStyleBase>(UFeatherTextBlockStyle::StaticClass()), StyleName, Opt_Name));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherEditableTextStyle CreateEditableText(FName StyleName = NAME_None, FName Opt_Name = NAME_None)
	{
		return Cast<UFeatherEditableTextStyle>(CreateStyle(TSubclassOf<UFeatherStyleBase>(UFeatherEditableTextStyle::StaticClass()), StyleName, Opt_Name));
	}

	UFUNCTION(Category = "Feather|Style")
	UFeatherMultiLineEditableTextStyle CreateMultiLineEditableText(FName StyleName = NAME_None, FName Opt_Name = NAME_None)
	{
		return Cast<UFeatherMultiLineEditableTextStyle>(CreateStyle(TSubclassOf<UFeatherStyleBase>(UFeatherMultiLineEditableTextStyle::StaticClass()), StyleName, Opt_Name));
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
			OnSettingsLoaded.Broadcast(this);
			bIsPossibleToSave = true;
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
		OnResetToDefault.Broadcast(this);
		bIsPossibleToSave = true;
	}

	UFUNCTION(Category = "Feather|Settings", BlueprintEvent)
	void Reset() { }
};
