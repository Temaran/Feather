import Feather.FeatherStyle;
import Feather.Utils.AssetRegistryUtils;

event void FPrimaryAssetFilterChangedEvent(UFeatherPrimaryAssetSelectorComboBoxStyle ComboBox, FString NewFilter);
event void FPrimaryAssetSelectionChangedEvent(UFeatherPrimaryAssetSelectorComboBoxStyle ComboBox, FName NewAsset);

UCLASS(Abstract)
class UFeatherPrimaryAssetSelectorComboBoxStyle : UFeatherStyleBase
{
    UPROPERTY(Category = "Primary Asset Selector")
    FPrimaryAssetFilterChangedEvent OnFilterChanged;

    UPROPERTY(Category = "Primary Asset Selector")
    FPrimaryAssetSelectionChangedEvent OnPrimaryAssetSelectionChanged;

    // We will populate the class combo box with all children of this base class.
    UPROPERTY(Category = "Primary Asset Selector")
    TSubclassOf<UObject> PrimaryAssetClass;

	UPROPERTY(Category = "Primary Asset Selector")
	FString AssetPrefix;

    UPROPERTY(Category = "Primary Asset Selector")
    FText NoFilterText = FText::FromString("No Filter");

    TMap<FString, FName> AssetDictionary;

	UFUNCTION(BlueprintEvent)
	UFeatherEditableTextStyle GetFilterTextBox() { return nullptr; }

	UFUNCTION(BlueprintEvent)
	UFeatherComboBoxStyle GetPrimaryAssetListComboBox() { return nullptr; }

    UFUNCTION(BlueprintOverride)
	void Construct()
    {
        if(!ensure(PrimaryAssetClass.IsValid(), "You must specify a base class for the class selector!"))
        {
            return;
        }

		AssetDictionary = FeatherAssetRegistryUtils::GetNameOfAllAssetsWithClass(PrimaryAssetClass, AssetPrefix);

		GetFilterTextBox().GetEditableText().SetHintText(NoFilterText);
        GetFilterTextBox().GetEditableText().OnTextChanged.AddUFunction(this, n"FilterChanged");
        GetPrimaryAssetListComboBox().GetComboBoxWidget().OnSelectionChanged.AddUFunction(this, n"PrimaryAssetSelectionChanged");

        PopulateAssets("");
    }

    UFUNCTION()
    void FilterChanged(const FText&in NewFilter)
    {
        PopulateAssets(NewFilter.ToString());
        OnFilterChanged.Broadcast(this, NewFilter.ToString());
    }

    UFUNCTION()
    void PrimaryAssetSelectionChanged(FString NewSelection, ESelectInfo SelectionType)
    {
        OnPrimaryAssetSelectionChanged.Broadcast(this, GetSelectedAsset());
    }

    void PopulateAssets(FString FilterText)
    {
        UComboBoxString ActualClassComboBox = GetPrimaryAssetListComboBox().GetComboBoxWidget();
        FString PreviouslySelectedItem = ActualClassComboBox.GetSelectedOption();
        ActualClassComboBox.ClearOptions();

        for(auto Entry : AssetDictionary)
        {
            FString EntryClassString = Entry.Key;

            if(FilterText.IsEmpty() || EntryClassString.Contains(FilterText))
            {
                ActualClassComboBox.AddOption(EntryClassString);
            }
        }

        // Attempt to preserve selection...
        ActualClassComboBox.SetSelectedIndex(0);
        ActualClassComboBox.SetSelectedOption(PreviouslySelectedItem);
    }

//////////////////////////////////////////////////////////////////////
// API

    UFUNCTION(Category = "Primary Asset Selector", BlueprintPure)
    FText GetFilter()
    {
        return GetFilterTextBox().GetEditableText().GetText();
    }

    UFUNCTION(Category = "Primary Asset Selector")
    void SetFilter(FText NewFilter)
    {
        GetFilterTextBox().GetEditableText().SetText(NewFilter);
    }

    UFUNCTION(Category = "Primary Asset Selector", BlueprintPure)
    FName GetSelectedAsset()
    {
        FString OptionName = GetPrimaryAssetListComboBox().GetComboBoxWidget().GetSelectedOption();

        if(AssetDictionary.Contains(OptionName))
        {
            return AssetDictionary[OptionName];
        }

        return NAME_None;
    }
};
