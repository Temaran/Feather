// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceRoot;

class AFeatherDemoPlayerPawn : APawn
{
    UPROPERTY(DefaultComponent)
    UInputComponent ScriptInputComponent;

#if !RELEASE
	UPROPERTY(Category = "Debug", EditDefaultsOnly)
	TSubclassOf<UFeatherDebugInterfaceRoot> DebugInterfaceType;
    private UFeatherDebugInterfaceRoot DebugInterface;

	UFUNCTION()
	void ToggleDebugInterface(FKey Key)
	{
		if(System::IsValid(DebugInterface))
		{
			if(DebugInterface.GetDebugInterfaceVisibility())
			{
				FeatherDebugInterfaceRoot::SetDebugInterfaceState(DebugInterface, EDebugInterfaceState::Disabled);
			}
			else
			{
				FeatherDebugInterfaceRoot::SetDebugInterfaceState(DebugInterface, EDebugInterfaceState::EnabledWithGame);
			}
		}
	}
#endif // RELEASE

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
#if !RELEASE
		ensure(DebugInterfaceType.IsValid(), "Cannot find Debug Interface!");
		DebugInterface = FeatherDebugInterfaceRoot::CreateDebugInterface(Cast<APlayerController>(GetController()), DebugInterfaceType);
		FeatherDebugInterfaceRoot::SetDebugInterfaceState(DebugInterface, EDebugInterfaceState::EnabledWithGame);
        
		ScriptInputComponent.BindAction(n"ToggleDebugInterface", EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"ToggleDebugInterface"));
#endif // RELEASE
    }
};
