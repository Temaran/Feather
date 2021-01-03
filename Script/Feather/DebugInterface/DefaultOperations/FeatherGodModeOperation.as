// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.OperationBaseClasses.FeatherSimpleCheckBoxOperationBase;

// Toggle player vulnerability
class UFeatherGodModeOperation : UFeatherSimpleCheckBoxOperationBase
{
	default OperationTags.Add(n"Player");
	default OperationTags.Add(n"God");
    
    default CheckBoxText = FText::FromString("God Mode");
    default CheckBoxToolTip = FText::FromString("God mode makes your character invulnerable.");


    UFUNCTION(BlueprintOverride)
    bool IsCheckedByDefault() const
    {
        APawn PlayerPawn = Gameplay::GetPlayerPawn(0);
        if(System::IsValid(PlayerPawn))
        {
            return !PlayerPawn.bCanBeDamaged;
        }

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void OnCheckStateChanged(bool bChecked)
    {
        APawn PlayerPawn = Gameplay::GetPlayerPawn(0);
        if(System::IsValid(PlayerPawn))
        {
            PlayerPawn.bCanBeDamaged = !bChecked;
        }
    }
};
