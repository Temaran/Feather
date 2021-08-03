// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherStyle;

event void FFilterChangedEvent(UFeatherClassSelectorComboBoxStyle ComboBox, FString NewFilter);
event void FClassSelectionChangedEvent(UFeatherClassSelectorComboBoxStyle ComboBox, UClass NewClass);

UCLASS(Abstract)
class UFeatherClassSelectorComboBoxStyle : UFeatherStyleBase
{
	UPROPERTY(Category = "Class Selector")
	FFilterChangedEvent OnFilterChanged;

	UPROPERTY(Category = "Class Selector")
	FClassSelectionChangedEvent OnClassSelectionChanged;

	// We will populate the class combo box with all children of this base class.
	UPROPERTY(Category = "Class Selector")
	TSubclassOf<UObject> BaseClass;

	// We will populate the class combo box with all children of this base class.
	UPROPERTY(Category = "Class Selector")
	FText NoFilterText = FText::FromString("No Filter");

	// If any child class contains any of these strings, it will be filtered out. Case sensitive.
	UPROPERTY(Category = "Class Selector")
	TArray<FString> ExclusionFilters;
	default ExclusionFilters.Add("SKEL_");

	TMap<FName, UClass> ClassDictionary;

	UFUNCTION(BlueprintEvent)
	UFeatherEditableTextStyle GetFilterTextBox() { return nullptr; }

	UFUNCTION(BlueprintEvent)
	UFeatherComboBoxStyle GetClassListComboBox() { return nullptr; }

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		if(!ensure(BaseClass.IsValid(), "You must specify a base class for the class selector!"))
		{
			return;
		}

		TArray<UClass> AllSubclasses = UClass::GetAllSubclassesOf(BaseClass);
		for(UClass Subclass : AllSubclasses)
		{
			FString SubclassNameString = Subclass.Name.ToString();
			if(PassesExclusionFilter(SubclassNameString))
			{
				ClassDictionary.Add(Subclass.Name, Subclass);
			}
		}

		GetFilterTextBox().GetEditableText().SetHintText(NoFilterText);
		GetFilterTextBox().GetEditableText().OnTextChanged.AddUFunction(this, n"FilterChanged");
		GetClassListComboBox().GetComboBoxWidget().OnSelectionChanged.AddUFunction(this, n"ClassSelectionChanged");

		PopulateClasses("");
	}

	UFUNCTION()
	void FilterChanged(const FText&in NewFilter)
	{
		const FString FilterString = NewFilter.ToString();
		PopulateClasses(FilterString);
		OnFilterChanged.Broadcast(this, FilterString);
	}

	UFUNCTION()
	void ClassSelectionChanged(FString NewSelection, ESelectInfo SelectionType)
	{
		OnClassSelectionChanged.Broadcast(this, GetSelectedClass());
	}

	void PopulateClasses(FString FilterText)
	{
		UComboBoxString ActualClassComboBox = GetClassListComboBox().GetComboBoxWidget();
		FString PreviouslySelectedItem = ActualClassComboBox.GetSelectedOption();
		ActualClassComboBox.ClearOptions();

		for(auto Entry : ClassDictionary)
		{
			FString EntryClassString = Entry.Key.ToString();
			if(FilterText.IsEmpty() || EntryClassString.Contains(FilterText))
			{
				ActualClassComboBox.AddOption(EntryClassString);
			}
		}

		// Attempt to preserve selection...
		ActualClassComboBox.SetSelectedIndex(0);
		ActualClassComboBox.SetSelectedOption(PreviouslySelectedItem);
	}

	bool PassesExclusionFilter(FString& TestString)
	{
		for(FString ExclusionFilter : ExclusionFilters)
		{
			if(TestString.Contains(ExclusionFilter))
			{
				return false;
			}
		}

		return true;
	}

//////////////////////////////////////////////////////////////////////
// API

	UFUNCTION(Category = "Class Selector", BlueprintPure)
	FText GetFilter()
	{
		return GetFilterTextBox().GetEditableText().GetText();
	}

	UFUNCTION(Category = "Class Selector")
	void SetFilter(FText NewFilter)
	{
		GetFilterTextBox().GetEditableText().SetText(NewFilter);
	}

	UFUNCTION(Category = "Class Selector", BlueprintPure)
	UClass GetSelectedClass()
	{
		const FName OptionName = FName(GetClassListComboBox().GetComboBoxWidget().GetSelectedOption());
		if(ClassDictionary.Contains(OptionName))
		{
			return ClassDictionary[OptionName];
		}

		return nullptr;
	}

	UFUNCTION(Category = "Class Selector")
	void SetSelectedClass(UClass ClassToSelect)
	{
		GetClassListComboBox().GetComboBoxWidget().SetSelectedOption(ClassToSelect.Name.ToString());
	}
};
