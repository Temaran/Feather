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
	TSubclassOf<UFeatherRoot> DebugInterfaceType;
    private UFeatherRoot DebugInterface;

	UFUNCTION()
	void ToggleDebugInterface(FKey Key)
	{
		if(System::IsValid(DebugInterface))
		{
			if(DebugInterface.IsRootVisible())
			{
				DebugInterface.SetRootVisibility(EFeatherRootVisibility::Disabled);
			}
			else
			{
				DebugInterface.SetRootVisibility(EFeatherRootVisibility::EnabledWithGame);
			}
		}
	}
#endif // RELEASE

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		System::SetTimer(this, n"CreateDebugInterface", 0.1f, false);
    }

	UFUNCTION()
	void CreateDebugInterface()
	{
#if !RELEASE
		ensure(DebugInterfaceType.IsValid(), "Cannot find Debug Interface!");
		DebugInterface = Feather::CreateFeatherRoot(Cast<APlayerController>(GetController()), DebugInterfaceType);
		DebugInterface.SetRootVisibility(EFeatherRootVisibility::EnabledWithGame);
        
		ScriptInputComponent.BindAction(n"ToggleDebugInterface", EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"ToggleDebugInterface"));
#endif // RELEASE
	}
};
