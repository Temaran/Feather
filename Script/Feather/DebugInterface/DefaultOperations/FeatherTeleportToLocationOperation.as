// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceOperation;
import Feather.DebugInterface.FeatherDebugInterfaceUtils;
import Feather.FeatherSettings;

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
	bool SaveSettings()
	{
		FTeleportToLocationSaveState SaveState;
        if(!FeatherUtils::StringToVector(TeleportTargetEditableText.GetEditableText().GetText().ToString(), SaveState.SavedLocation))
        {
            return false;
        }

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
		FTeleportToLocationSaveState SaveState;
		if(FeatherSettings::LoadFeatherSettings(this, SaveStateString)
			&& FJsonObjectConverter::JsonObjectStringToUStruct(SaveStateString, SaveState))
		{
            TeleportTargetEditableText.GetEditableText().SetText(FText::FromString(FeatherUtils::VectorToString(SaveState.SavedLocation)));
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ResetSettingsToDefault()
	{
        TeleportTargetEditableText.GetEditableText().SetText(FText::FromString(FeatherUtils::VectorToString(FVector::ZeroVector)));
	}

	UFUNCTION(BlueprintOverride)
	void ConstructOperation()
	{
        // Setup widget hierarchy
        UHorizontalBox HorizontalLayout = Cast<UHorizontalBox>(ConstructWidget(UHorizontalBox::StaticClass()));
        SetRootWidget(HorizontalLayout);

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
        if(FeatherUtils::StringToVector(TeleportTargetEditableText.GetEditableText().GetText().ToString(), TeleportTarget))
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
            TeleportTargetEditableText.GetEditableText().SetText(FText::FromString(FeatherUtils::VectorToString(PlayerPawn.GetActorLocation())));
        }
	}
};
