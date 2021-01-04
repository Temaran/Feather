// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceOperation;
import Feather.FeatherSettings;
import Feather.FeatherUtils;

struct FTeleportToLocationSaveState
{
	FVector SavedLocation;
};

// Spawns an actor at the cursor. If no cursor is present, it will spawn in the camera look-at instead.
class UFeatherTeleportToLocationOperation : UFeatherDebugInterfaceOperation
{
	default OperationTags.Add(n"Player");
	default OperationTags.Add(n"Teleport");

	UPROPERTY(Category = "Teleport To Location", NotEditable)
	UFeatherButtonStyle TeleportButton;

	UPROPERTY(Category = "Teleport To Location", NotEditable)
	UFeatherEditableTextStyle TeleportTargetEditableText;

	UPROPERTY(Category = "Teleport To Location", NotEditable)
	UFeatherButtonStyle StoreButton;


	UFUNCTION(BlueprintOverride)
	void Execute(FString Context)
	{
		TeleportToTarget();
	}
	
    UFUNCTION(BlueprintOverride)
	void SaveOperationToString(FString& InOutSaveString)
	{
        FTeleportToLocationSaveState SaveState;
        if(FeatherUtils::StringToVector(TeleportTargetEditableText.GetText().ToString(), SaveState.SavedLocation))
        {
            FJsonObjectConverter::AppendUStructToJsonObjectString(SaveState, InOutSaveString);
        }
	}

	UFUNCTION(BlueprintOverride)
	void LoadOperationFromString(const FString& InSaveString)
	{
		FTeleportToLocationSaveState SaveState;
		if(FJsonObjectConverter::JsonObjectStringToUStruct(InSaveString, SaveState))
		{
            TeleportTargetEditableText.SetText(FText::FromString(FeatherUtils::VectorToString(SaveState.SavedLocation)));
		}
	}

	UFUNCTION(BlueprintOverride)
	void ResetSettingsToDefault()
	{
        TeleportTargetEditableText.SetText(FText::FromString(FeatherUtils::VectorToString(FVector::ZeroVector)));
	}

	UFUNCTION(BlueprintOverride)
	void ConstructOperation(UNamedSlot OperationRoot)
	{
        // Setup widget hierarchy
        UHorizontalBox HorizontalLayout = Cast<UHorizontalBox>(ConstructWidget(UHorizontalBox::StaticClass()));
        OperationRoot.SetContent(HorizontalLayout);

        TeleportButton = CreateButton();
        HorizontalLayout.AddChildToHorizontalBox(TeleportButton);
        UFeatherTextBlockStyle TeleportButtonText = CreateTextBlock();
        TeleportButton.GetButtonWidget().SetContent(TeleportButtonText);
        TeleportButtonText.GetTextWidget().SetText(FText::FromString("Teleport To:"));
        TeleportButton.SetToolTipText(FText::FromString("Teleport to the coordinates in the target field"));
        TeleportButton.GetButtonWidget().OnClicked.AddUFunction(this, n"TeleportToTarget");

        TeleportTargetEditableText = CreateEditableText();
        UHorizontalBoxSlot TextSlot = HorizontalLayout.AddChildToHorizontalBox(TeleportTargetEditableText);
        FSlateChildSize FillSize;
        FillSize.SizeRule = ESlateSizeRule::Fill;
        TextSlot.SetSize(FillSize);        
        FMargin TextPadding;
        TextPadding.Left = 10.0f;
        TextPadding.Right = 10.0f;
        TextSlot.SetPadding(TextPadding);
        TextSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);
        TeleportTargetEditableText.GetEditableText().SetHintText(FText::FromString("Type in target coordinates here. Or capture some with the store button"));
        TeleportTargetEditableText.SetToolTipText(FText::FromString("Type in the coordinates you want to teleport to here. It's easiest to fill this using the store button."));
        TeleportTargetEditableText.GetEditableText().OnTextChanged.AddUFunction(this, n"TargetChanged");

        StoreButton = CreateButton();
        HorizontalLayout.AddChildToHorizontalBox(StoreButton);
        UFeatherTextBlockStyle StoreButtonText = CreateTextBlock();
        StoreButton.GetButtonWidget().SetContent(StoreButtonText);
        StoreButtonText.GetTextWidget().SetText(FText::FromString("Store Current"));
        StoreButton.SetToolTipText(FText::FromString("Store your current position in the target field"));
        StoreButton.GetButtonWidget().OnClicked.AddUFunction(this, n"StoreCurrentPosition");
	}

	UFUNCTION()
	void TeleportToTarget()
	{
        FVector TeleportTarget;
        if(FeatherUtils::StringToVector(TeleportTargetEditableText.GetText().ToString(), TeleportTarget))
        {
            APawn PlayerPawn = Gameplay::GetPlayerPawn(0);
            if(System::IsValid(PlayerPawn))
            {
                PlayerPawn.SetActorLocation(TeleportTarget);
            }
        }
	}

	UFUNCTION()
	void StoreCurrentPosition()
	{
        APawn PlayerPawn = Gameplay::GetPlayerPawn(0);
        if(System::IsValid(PlayerPawn))
        {
            TeleportTargetEditableText.SetText(FText::FromString(FeatherUtils::VectorToString(PlayerPawn.GetActorLocation())));
        }
	}

    UFUNCTION()
    void TargetChanged(FText& NewTargetText)
    {        
        SaveSettings();
    }
};
