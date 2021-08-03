// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceWindow;
import Feather.UtilWidgets.FeatherSearchBox;
import Feather.FeatherUtils;

event void FSaveOptionsEvent();
event void FResetEverythingEvent();

UCLASS(Abstract)
class UFeatherDebugInterfaceOptionsWindow : UFeatherDebugInterfaceWindow
{
	default WindowName = n"Options";

	UPROPERTY(Category = "Feather|Options")
	FSaveOptionsEvent OnSaveOptions;

	UPROPERTY(Category = "Feather|Options")
	FResetEverythingEvent OnResetEverything;

	private UFeatherSearchBox SearchBox;

	UFUNCTION(BlueprintOverride)
	void FeatherConstruct(FFeatherStyle InStyle, FFeatherConfig InConfig)
    {
		Super::FeatherConstruct(InStyle, InConfig);

		GetMaxSearchSuggestionsText().OnTextChanged.AddUFunction(this, n"MaxSearchSuggestionsChanged");
		GetQuickSelectFoldoutSizeText().OnTextChanged.AddUFunction(this, n"QuickSelectFoldoutSizeChanged");
		GetResetButton().OnClicked.AddUFunction(this, n"ResetEverything");
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
	void MaxSearchSuggestionsChanged(const FText&in NewValue)
	{
		SearchBox.SetMaxSearchSuggestions(FeatherUtils::ParseLocaleInvariantFloat(NewValue.ToString()));
		SaveSearchBoxSettings();
	}

	UFUNCTION()
	void QuickSelectFoldoutSizeChanged(const FText&in NewValue)
	{
		SearchBox.SetQuickSelectFoldoutSize(FeatherUtils::ParseLocaleInvariantFloat(NewValue.ToString()));
		SaveSearchBoxSettings();
	}

	UFUNCTION()
	void ResetEverything()
	{
		OnResetEverything.Broadcast();
		ReloadValues();
	}

	void SaveSearchBoxSettings()
	{
		if(bIsPossibleToSave)
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
