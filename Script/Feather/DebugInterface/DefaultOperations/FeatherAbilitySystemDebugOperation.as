// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

#if !RELEASE
import Feather.DebugInterface.FeatherDebugInterfaceOperation;
import Feather.FeatherSettings;
import Feather.FeatherUtils;

struct FAbilitySystemDebugSaveState
{
	bool bShowingDebug;
};

// Adds a more user friendly way of interacting with the ability system debugger.
class UFeatherAbilitySystemDebugOperation : UFeatherDebugInterfaceOperation
{
	default OperationTags.Add(n"GAS");

	UPROPERTY(Category = "Ability System Debug", NotEditable)
	UFeatherCheckBoxStyle ShowAbilitySystemDebugCheckBox;

	UPROPERTY(Category = "Ability System Debug", NotEditable)
	UFeatherButtonStyle PreviousActorButton;

	UPROPERTY(Category = "Ability System Debug", NotEditable)
	UFeatherButtonStyle NextActorButton;

	UPROPERTY(Category = "Ability System Debug", NotEditable)
	UFeatherButtonStyle ChangeCategoryButton;


	UFUNCTION(BlueprintOverride)
	void Execute(FString Context)
	{
        ShowAbilitySystemDebugCheckBox.SetIsChecked(!ShowAbilitySystemDebugCheckBox.IsChecked());
	}

	UFUNCTION(BlueprintOverride)
	void SaveOperationToString(FString& InOutSaveString)
	{
        FAbilitySystemDebugSaveState SaveState;
        SaveState.bShowingDebug = ShowAbilitySystemDebugCheckBox.IsChecked();
        FJsonObjectConverter::AppendUStructToJsonObjectString(SaveState, InOutSaveString);
	}

	UFUNCTION(BlueprintOverride)
	void LoadOperationFromString(const FString& InSaveString)
	{
		FAbilitySystemDebugSaveState SaveState;
		if(FJsonObjectConverter::JsonObjectStringToUStruct(InSaveString, SaveState))
		{
            if(SaveState.bShowingDebug)
            {
                // Only call this if it's actually saved to be on. Since this is using the hidden state in-engine, it's a bit wonky.
                ShowAbilitySystemDebugCheckBox.SetIsChecked(true);
            }
		}
	}

	UFUNCTION(BlueprintOverride)
	void Reset()
	{
		Super::Reset();

        if(ShowAbilitySystemDebugCheckBox.IsChecked())
        {
            ShowAbilitySystemDebugCheckBox.SetIsChecked(false);
        }
	}

	UFUNCTION(BlueprintOverride)
	void ConstructOperation(UNamedSlot OperationRoot)
	{
        FMargin LeftPadding;
        LeftPadding.Left = 10.0f;

        FMargin RightPadding;
        RightPadding.Right = 10.0f;

        // Setup widget hierarchy
        UHorizontalBox HorizontalLayout = Cast<UHorizontalBox>(ConstructWidget(UHorizontalBox::StaticClass()));
        OperationRoot.SetContent(HorizontalLayout);

        ShowAbilitySystemDebugCheckBox = CreateCheckBox();
        UHorizontalBoxSlot CheckBoxSlot = HorizontalLayout.AddChildToHorizontalBox(ShowAbilitySystemDebugCheckBox);
        ShowAbilitySystemDebugCheckBox.GetCheckBoxWidget().OnCheckStateChanged.AddUFunction(this, n"OnShowAbilityCheckBoxStateChanged");
        CheckBoxSlot.SetPadding(RightPadding);
        CheckBoxSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);

        UFeatherTextBlockStyle CheckBoxLabel = CreateTextBlock();
        UHorizontalBoxSlot LabelSlot = HorizontalLayout.AddChildToHorizontalBox(CheckBoxLabel);
        FSlateChildSize FillSize;
        FillSize.SizeRule = ESlateSizeRule::Fill;
        LabelSlot.SetSize(FillSize);
        LabelSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);
        CheckBoxLabel.GetTextWidget().SetText(FText::FromString("Show Ability System Debug"));
		CheckBoxLabel.GetTextWidget().SetToolTipText(FText::FromString("Toggles the engine ability system debugger"));

        PreviousActorButton = CreateButton();
        HorizontalLayout.AddChildToHorizontalBox(PreviousActorButton);
        PreviousActorButton.GetButtonWidget().OnClicked.AddUFunction(this, n"OnPreviousActor");
        UFeatherTextBlockStyle PreviousActorText = CreateTextBlock();
        PreviousActorButton.GetButtonWidget().SetContent(PreviousActorText);
		PreviousActorButton.SetToolTipText(FText::FromString("Go to the previous actor"));
        PreviousActorText.GetTextWidget().SetText(FText::FromString(" ^ "));

        NextActorButton = CreateButton();
        UHorizontalBoxSlot NextActorSlot = HorizontalLayout.AddChildToHorizontalBox(NextActorButton);
        NextActorButton.GetButtonWidget().OnClicked.AddUFunction(this, n"OnNextActor");
        NextActorSlot.SetPadding(LeftPadding);
        UFeatherTextBlockStyle NextActorText = CreateTextBlock();
        NextActorButton.GetButtonWidget().SetContent(NextActorText);
		NextActorButton.SetToolTipText(FText::FromString("Go to the next actor"));
        NextActorText.GetTextWidget().SetText(FText::FromString(" ^ "));
        NextActorButton.SetRenderTransformAngle(180.0f);

        ChangeCategoryButton = CreateButton();
        UHorizontalBoxSlot ChangeCategorySlot = HorizontalLayout.AddChildToHorizontalBox(ChangeCategoryButton);
        ChangeCategoryButton.GetButtonWidget().OnClicked.AddUFunction(this, n"OnChangeCategory");
        ChangeCategorySlot.SetPadding(LeftPadding);
        UFeatherTextBlockStyle ChangeCategoryText = CreateTextBlock();
        ChangeCategoryButton.GetButtonWidget().SetContent(ChangeCategoryText);
		ChangeCategoryButton.SetToolTipText(FText::FromString("Cycle the debugging category"));
        ChangeCategoryText.GetTextWidget().SetText(FText::FromString(" Category "));
	}

    UFUNCTION()
    void OnShowAbilityCheckBoxStateChanged(bool bNewCheckState)
    {
        System::ExecuteConsoleCommand(bNewCheckState ? "ShowDebug AbilitySystem" : "ShowDebug");
        SaveSettings();
    }

    UFUNCTION()
    void OnPreviousActor()
    {
        System::ExecuteConsoleCommand("AbilitySystem.Debug.PrevTarget");
    }

    UFUNCTION()
    void OnNextActor()
    {
        System::ExecuteConsoleCommand("AbilitySystem.Debug.NextTarget");
    }

    UFUNCTION()
    void OnChangeCategory()
    {
        System::ExecuteConsoleCommand("AbilitySystem.Debug.NextCategory");
    }
};
#endif // RELEASE
