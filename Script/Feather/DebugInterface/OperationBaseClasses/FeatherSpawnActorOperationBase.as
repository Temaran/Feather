// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceOperation;
import Feather.DebugInterface.FeatherDebugInterfaceUtils;
import Feather.UtilWidgets.FeatherClassSelectorComboBox;
import Feather.FeatherSettings;

struct FSpawnActorSaveState
{
	FString Filter;
	FString SelectedClass;
};

// Spawns an actor at the cursor. If no cursor is present, it will spawn in the camera look-at instead.
UCLASS(Abstract)
class UFeatherSpawnActorOperationBase : UFeatherDebugInterfaceOperation
{
	default OperationTags.Add(n"General");
	default OperationTags.Add(n"Spawn");

	UPROPERTY(Category = "Spawn Actor", NotEditable)
	UFeatherButtonStyle SpawnButton;

	UPROPERTY(Category = "Spawn Actor", NotEditable)
	UFeatherClassSelectorComboBox ClassSelectorComboBox;

	UPROPERTY(Category = "Spawn Actor", EditDefaultsOnly)
	UClass SelectorBaseClass;
	
	FText ButtonText = FText::FromString("Spawn");
	FText ButtonToolTipText = FText::FromString("Click to spawn an actor of the selected type at the cursor/screen center.");
	float ButtonSeparation = 10.0f;

	UFUNCTION(BlueprintOverride)
	void Execute(FString Context = "")
	{
		SpawnClass(false);
	}

	UFUNCTION(BlueprintOverride)
	bool SaveSettings()
	{
		FSpawnActorSaveState SaveState;
		SaveState.Filter = ClassSelectorComboBox.FilterBox.GetEditableText().GetText().ToString();
		SaveState.SelectedClass = ClassSelectorComboBox.ClassComboBox.GetComboBoxWidget().GetSelectedOption();

		FString SaveStateString;
		if(FJsonObjectConverter::UStructToJsonObjectString(SaveState, SaveStateString))
		{
			return FeatherSettings::SaveFeatherSettings(this, SaveStateString);
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool LoadSettings()
	{
		FString SaveStateString;
		FSpawnActorSaveState SaveState;
		if(FeatherSettings::LoadFeatherSettings(this, SaveStateString)
			&& FJsonObjectConverter::JsonObjectStringToUStruct(SaveStateString, SaveState))
		{
			ClassSelectorComboBox.FilterBox.GetEditableText().SetText(FText::FromString(SaveState.Filter));
			ClassSelectorComboBox.ClassComboBox.GetComboBoxWidget().SetSelectedOption(SaveState.SelectedClass);
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ResetSettingsToDefault()
	{
		ClassSelectorComboBox.FilterBox.GetEditableText().SetText(FText());
		ClassSelectorComboBox.ClassComboBox.GetComboBoxWidget().SetSelectedIndex(0);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructOperation()
	{
        // Setup widget hierarchy
        UHorizontalBox HorizontalLayout = Cast<UHorizontalBox>(ConstructWidget(UHorizontalBox::StaticClass()));
        SetRootWidget(HorizontalLayout);

        SpawnButton = CreateButton();
        UHorizontalBoxSlot ButtonSlot = HorizontalLayout.AddChildToHorizontalBox(SpawnButton);
		FMargin ButtonPadding;
		ButtonPadding.Right = ButtonSeparation;
		ButtonSlot.Padding = ButtonPadding;

        ClassSelectorComboBox = Cast<UFeatherClassSelectorComboBox>(CreateStyledWidget(TSubclassOf<UFeatherWidget>(UFeatherClassSelectorComboBox::StaticClass())));
        UHorizontalBoxSlot SelectorSlot = HorizontalLayout.AddChildToHorizontalBox(ClassSelectorComboBox);		
        FSlateChildSize FillSize;
        FillSize.SizeRule = ESlateSizeRule::Fill;
        SelectorSlot.SetSize(FillSize);
		ClassSelectorComboBox.BaseClass = SelectorBaseClass;
		ClassSelectorComboBox.FeatherConstruct();
        
		UTextBlock SpawnButtonText = Cast<UTextBlock>(ConstructWidget(UTextBlock::StaticClass()));
		SpawnButtonText.SetText(ButtonText);
		SpawnButtonText.SetToolTipText(ButtonToolTipText);

		UButton ActualSpawnButton = SpawnButton.GetButtonWidget();
		ActualSpawnButton.SetContent(SpawnButtonText);
		ActualSpawnButton.SetToolTipText(ButtonToolTipText);
		ActualSpawnButton.OnClicked.AddUFunction(this, n"SpawnButtonClicked");
	}

	UFUNCTION()
	void SpawnButtonClicked()
	{
		// Since we're clicking in the interface, it doesn't make sense to use the cursor pos.
		SpawnClass(true);
	}

	void SpawnClass(bool bForceLookAt)
	{
		FHitResult PlayerFocus;
		if(bForceLookAt)
		{
			if(FeatherUtils::GetPlayerLookAt(PlayerFocus))
			{			
				SpawnActor(ClassSelectorComboBox.GetSelectedClass(), PlayerFocus.Location);
			}
		}
		else
		{
			if(FeatherUtils::GetPlayerFocus(PlayerFocus))
			{			
				SpawnActor(ClassSelectorComboBox.GetSelectedClass(), PlayerFocus.Location);
			}
		}
	}
};
