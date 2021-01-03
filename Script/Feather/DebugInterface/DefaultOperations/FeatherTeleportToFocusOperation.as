// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.OperationBaseClasses.FeatherSimpleButtonOperationBase;
import Feather.DebugInterface.FeatherDebugInterfaceUtils;

// Teleport to the center of the screen or the cursor depending on the context.
class UFeatherTeleportToFocusOperation : UFeatherSimpleButtonOperationBase
{    
	default OperationTags.Add(n"Player");
	default OperationTags.Add(n"Teleport");
    
    default ButtonText = FText::FromString("Teleport to focus");
    default ButtonToolTip = FText::FromString("Teleports you to your current focus. This is the center of the screen unless you are invoking using a hotkey with a cursor, in which case it's the cursor.");


    UFUNCTION(BlueprintOverride)
    void Execute(FString Context)
    {
        TeleportToFocus(false);
    }

    UFUNCTION(BlueprintOverride)
    void OnButtonClicked()
    {
        TeleportToFocus(true);
    }

    void TeleportToFocus(bool bForceLookAt)
	{
        APawn PlayerPawn = Gameplay::GetPlayerPawn(0);
        if(!System::IsValid(PlayerPawn))
		{
            return;
		}

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
            PlayerPawn.SetActorLocation(PlayerFocus.Location);
		}
	}
};
