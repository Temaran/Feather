// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

#if !RELEASE
import Feather.DebugInterface.FeatherDebugInterfaceOperation;
import Feather.Styles.FeatherClassSelectorComboBoxStyle;
import Feather.FeatherSettings;
import Feather.FeatherUtils;

struct FSpawnActorSaveState
{
	UPROPERTY()
	FString Filter;

	UPROPERTY()
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
	UFeatherClassSelectorComboBoxStyle ClassSelectorComboBox;

	UPROPERTY(Category = "Spawn Actor", EditDefaultsOnly)
	UClass SelectorBaseClass;

	FText ButtonText = FText::FromString(" Spawn ");
	FText ButtonToolTipText = FText::FromString("Click to spawn an actor of the selected type at the cursor/screen center.");
	float ButtonSeparation = 10.0f;


	UFUNCTION(BlueprintOverride)
	void Execute(FString Context)
	{
		SpawnClass(false);
	}

	UFUNCTION(BlueprintOverride)
	void SaveOperationToString(FString& InOutSaveString)
	{
		FSpawnActorSaveState SaveState;
		SaveState.Filter = ClassSelectorComboBox.GetFilterTextBox().GetText().ToString();
		SaveState.SelectedClass = ClassSelectorComboBox.GetClassListComboBox().GetSelectedOption();
		FJsonObjectConverter::AppendUStructToJsonObjectString(SaveState, InOutSaveString);
	}

	UFUNCTION(BlueprintOverride)
	void LoadOperationFromString(const FString& InSaveString)
	{
		FSpawnActorSaveState SaveState;
		if(FJsonObjectConverter::JsonObjectStringToUStruct(InSaveString, SaveState))
		{
			ClassSelectorComboBox.GetFilterTextBox().SetText(FText::FromString(SaveState.Filter));
			ClassSelectorComboBox.GetClassListComboBox().SetSelectedOption(SaveState.SelectedClass);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Reset()
	{
		Super::Reset();

		ClassSelectorComboBox.GetFilterTextBox().SetText(FText());
		ClassSelectorComboBox.GetClassListComboBox().SetSelectedIndex(0);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructOperation(UNamedSlot OperationRoot)
	{
		// Setup widget hierarchy
		UHorizontalBox HorizontalLayout = Cast<UHorizontalBox>(ConstructWidget(UHorizontalBox::StaticClass()));
		OperationRoot.SetContent(HorizontalLayout);

		SpawnButton = CreateButton();
		UHorizontalBoxSlot ButtonSlot = HorizontalLayout.AddChildToHorizontalBox(SpawnButton);
		FMargin ButtonPadding;
		ButtonPadding.Right = ButtonSeparation;
		ButtonSlot.Padding = ButtonPadding;

		ClassSelectorComboBox = Cast<UFeatherClassSelectorComboBoxStyle>(CreateStyle(TSubclassOf<UFeatherStyleBase>(UFeatherClassSelectorComboBoxStyle::StaticClass())));
		UHorizontalBoxSlot SelectorSlot = HorizontalLayout.AddChildToHorizontalBox(ClassSelectorComboBox);
		FSlateChildSize FillSize;
		FillSize.SizeRule = ESlateSizeRule::Fill;
		SelectorSlot.SetSize(FillSize);
		ClassSelectorComboBox.BaseClass = SelectorBaseClass;
		ClassSelectorComboBox.OnFilterChanged.AddUFunction(this, n"OnFilterChanged");
		ClassSelectorComboBox.OnClassSelectionChanged.AddUFunction(this, n"OnClassSelectionChanged");

		UFeatherTextBlockStyle SpawnButtonText = CreateTextBlock();
		SpawnButtonText.SetText(ButtonText);
		SpawnButtonText.SetToolTipText(ButtonToolTipText);

		UButton ActualSpawnButton = SpawnButton.GetButtonWidget();
		ActualSpawnButton.SetContent(SpawnButtonText);
		ActualSpawnButton.SetToolTipText(ButtonToolTipText);
		ActualSpawnButton.OnClicked.AddUFunction(this, n"SpawnButtonClicked");
	}

	UFUNCTION()
	void OnFilterChanged(UFeatherClassSelectorComboBoxStyle ComboBox, FString NewFilter)
	{
		SaveSettings();
	}
	UFUNCTION()
	void OnClassSelectionChanged(UFeatherClassSelectorComboBoxStyle ComboBox, UClass SelectedClass)
	{
		SaveSettings();
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
		bool bFocusFound = false;
		if(bForceLookAt)
		{
			bFocusFound = FeatherUtils::GetPlayerLookAt(PlayerFocus);
		}
		else
		{
			bFocusFound = FeatherUtils::GetPlayerFocus(PlayerFocus);
		}

		if(bFocusFound)
		{
			SpawnActor(ClassSelectorComboBox.GetSelectedClass(), PlayerFocus.Location);
		}
	}
};
#endif // RELEASE
