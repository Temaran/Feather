// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherWidget;

event void FFilterChangedEvent(UFeatherClassSelectorComboBox ComboBox, FString NewFilter);

class UFeatherClassSelectorComboBox : UFeatherWidget
{
    UPROPERTY(Category = "Class Selector", NotEditable)
    UFeatherEditableTextStyle FilterBox;

    UPROPERTY(Category = "Class Selector", NotEditable)
    UFeatherComboBoxStyle ClassComboBox;

    UPROPERTY(Category = "Class Selector")
    FFilterChangedEvent OnFilterChanged;

    // Filter text box cannot be smaller than this
    UPROPERTY(Category = "Class Selector", EditDefaultsOnly)
    float MinFilterBoxWidth = 150.0f;

    // Tooltip for the class selector
    UPROPERTY(Category = "Class Selector", EditDefaultsOnly)
    FText FilterToolTip = FText::FromString("Filter the selection here");
    
    UPROPERTY(Category = "Class Selector", EditDefaultsOnly)
    FText ClassComboBoxToolTip = FText::FromString("Select the class you want here");

    // This is what will be displayed in the filter text box before anything has been typed.
    UPROPERTY(Category = "Class Selector", EditDefaultsOnly)
    FText FilterHint = FText::FromString("Type here to filter classes");

    // We will populate the class combo box with all children of this base class.
    UPROPERTY(Category = "Class Selector", EditDefaultsOnly)
    UClass BaseClass;

    // If any child class contains any of these strings, it will be filtered out. Case sensitive.
    UPROPERTY(Category = "Class Selector", EditDefaultsOnly)
    TArray<FString> ExclusionFilters;
    default ExclusionFilters.Add("SKEL_");

    TMap<FName, UClass> ClassDictionary;

    UFUNCTION(BlueprintOverride)
    void FeatherConstruct()
    {
        Super::FeatherConstruct();

        if(!ensure(System::IsValid(BaseClass), "You must specify a base class for the class selector!"))
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

        // Setup widget hierarchy
        UHorizontalBox HorizontalLayout = Cast<UHorizontalBox>(ConstructWidget(UHorizontalBox::StaticClass()));
        SetRootWidget(HorizontalLayout);

        FilterBox = CreateEditableText();
        UHorizontalBoxSlot FilterSlot = HorizontalLayout.AddChildToHorizontalBox(FilterBox);
        FSlateChildSize FillSize;
        FillSize.SizeRule = ESlateSizeRule::Fill;
        FilterSlot.SetSize(FillSize);
        FilterSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);

        ClassComboBox = CreateComboBox();
        HorizontalLayout.AddChildToHorizontalBox(ClassComboBox);
        
        UEditableText ActualFilterBox = FilterBox.GetEditableText();
        ActualFilterBox.SetToolTipText(FilterToolTip);
        ActualFilterBox.SetHintText(FilterHint);
        ActualFilterBox.OnTextChanged.AddUFunction(this, n"FilterChanged");

        UComboBoxString ActualComboBox = ClassComboBox.GetComboBoxWidget();
        ActualComboBox.SetToolTipText(ClassComboBoxToolTip);

        PopulateClasses("");
    }

    UFUNCTION()
    void FilterChanged(FText& NewFilter)
    {
        PopulateClasses(NewFilter.ToString());
        OnFilterChanged.Broadcast(this, NewFilter.ToString());
    }

    void PopulateClasses(FString FilterText)
    {
        UComboBoxString ActualClassComboBox = ClassComboBox.GetComboBoxWidget();
        FString PreviouslySelectedItem = ActualClassComboBox.GetSelectedOption();
        ActualClassComboBox.ClearOptions();

        for(auto Entry : ClassDictionary)
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
        return FilterBox.GetEditableText().GetText();
    }

    UFUNCTION(Category = "Class Selector")
    void SetFilter(FText NewFilter)
    {
        FilterBox.GetEditableText().SetText(NewFilter);
    }

    UFUNCTION(Category = "Class Selector", BlueprintPure)
    UClass GetSelectedClass()
    {
        FName OptionName = FName(ClassComboBox.GetComboBoxWidget().GetSelectedOption());

        if(ClassDictionary.Contains(FName(OptionName)))
        {
            return ClassDictionary[OptionName];
        }

        return nullptr;
    }

    UFUNCTION(Category = "Class Selector")
    void SetSelectedClass(UClass ClassToSelect)
    {
        ClassComboBox.GetComboBoxWidget().SetSelectedOption(ClassToSelect.Name.ToString());
    }
};
