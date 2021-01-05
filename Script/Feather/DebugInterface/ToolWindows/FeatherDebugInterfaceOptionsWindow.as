// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceWindow;
import Feather.UtilWidgets.FeatherSearchBox;
import Feather.FeatherUtils;

event void FSaveOptionsEvent();

UCLASS(Abstract)
class UFeatherDebugInterfaceOptionsWindow : UFeatherDebugInterfaceWindow
{
	default WindowName = n"Options";

	UPROPERTY(Category = "Feather|Options")
	FSaveOptionsEvent OnSaveOptions;

	private UFeatherSearchBox SearchBox;

	UFUNCTION(BlueprintOverride)
	void FeatherConstruct()
	{
		Super::FeatherConstruct();

		GetMaxSearchSuggestionsText().OnTextChanged.AddUFunction(this, n"MaxSearchSuggestionsChanged");
		GetQuickSelectFoldoutSizeText().OnTextChanged.AddUFunction(this, n"QuickSelectFoldoutSizeChanged");
		GetResetButton().OnClicked.AddUFunction(this, n"OnResetSearch");
	}

	void SetSearchBox(UFeatherSearchBox InSearchBox)
	{
		SearchBox = InSearchBox;
		SearchBox.OnSettingsLoaded.AddUFunction(this, n"OnSearchSettingsLoaded");
		ReloadValues();
	}

	UFUNCTION()
	void ReloadValues()
	{
		GetMaxSearchSuggestionsText().SetText(FText::FromString("" + SearchBox.MaxSearchSuggestions));
		GetQuickSelectFoldoutSizeText().SetText(FText::FromString("" + SearchBox.QuickSelectFoldoutSize));
	}

	UFUNCTION()
	void OnSearchSettingsLoaded(UFeatherWidget Widget)
	{
		ReloadValues();
	}

	UFUNCTION()
	void MaxSearchSuggestionsChanged(FText& NewValue)
	{
		SearchBox.SetMaxSearchSuggestions(FeatherUtils::ParseLocaleInvariantFloat(NewValue.ToString()));
		SaveSearchBoxSettings();
	}
	
	UFUNCTION()
	void QuickSelectFoldoutSizeChanged(FText& NewValue)
	{
		SearchBox.SetQuickSelectFoldoutSize(FeatherUtils::ParseLocaleInvariantFloat(NewValue.ToString()));
		SaveSearchBoxSettings();
	}

	UFUNCTION()
	void OnResetSearch()
	{
		SearchBox.ResetSettingsToDefault();
		SaveSearchBoxSettings();
		ReloadValues();
	}

	void SaveSearchBoxSettings()
	{
		if(bIsConstructed)
		{
			SearchBox.SaveSettings();
		}
	}

//////////////////////////////////////////////////////////////////////////

	UFUNCTION(Category = "Feather|Options", BlueprintEvent)
	UEditableText GetMaxSearchSuggestionsText()
	{
		return nullptr;
	}
	
	UFUNCTION(Category = "Feather|Options", BlueprintEvent)
	UEditableText GetQuickSelectFoldoutSizeText()
	{
		return nullptr;
	}
	
	UFUNCTION(Category = "Feather|Options", BlueprintEvent)
	UButton GetResetButton()
	{
		return nullptr;
	}
};
