// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherConfig;
import Feather.FeatherWidget;

enum EFeatherRootVisibility
{
	Disabled,
	EnabledWithGame,
	EnabledUIOnly
};

namespace Feather
{
	UFUNCTION(Category = "Feather")
	UFeatherRoot CreateFeatherRoot(APlayerController Player, TSubclassOf<UFeatherRoot> RootWidgetType, int ZOrder = 0)
	{
		if(!ensure(RootWidgetType.IsValid(), "Must supply valid root widget type!")
		 || !ensure(System::IsValid(Player), "Must supply valid player!"))
		{
			return nullptr;
		}

		UFeatherRoot RootWidget = Cast<UFeatherRoot>(WidgetBlueprint::CreateWidget(RootWidgetType.Get(), Player));
		RootWidget.AddToViewport(ZOrder);
		return RootWidget;
	}
}

UCLASS(Abstract, Config = Game)
class UFeatherRoot : UFeatherWidget
{
	// This is set via ini, and the cascades down along the widgets.
	UPROPERTY(Category = "Feather|Config", Config, NotVisible)
	FFeatherConfig RootFeatherConfiguration;
	
	UFUNCTION(BlueprintOverride)
	void OnInitialized()
	{
		LoadConfig();
		FeatherConfiguration = RootFeatherConfiguration;
	}

	UFUNCTION(Category = "Feather", BlueprintEvent, BlueprintCallable)
	void SetRootVisibility(EFeatherRootVisibility NewRootVisibility, bool bAffectMouseCursor = true) 
	{
		if(bAffectMouseCursor)
		{
			OwningPlayer.SetbShowMouseCursor(NewRootVisibility != EFeatherRootVisibility::Disabled);
		}

		switch(NewRootVisibility)
		{
			case EFeatherRootVisibility::EnabledWithGame:
			{
				WidgetBlueprint::SetInputMode_GameAndUIEx(OwningPlayer, bHideCursorDuringCapture = false);
				break;
			}

			case EFeatherRootVisibility::EnabledUIOnly:
			{
				WidgetBlueprint::SetInputMode_UIOnlyEx(OwningPlayer);
				break;
			}

			default:
			{
				WidgetBlueprint::SetInputMode_GameOnly(OwningPlayer);				
				break;
			}
		}
	}

	UFUNCTION(Category = "Feather", BlueprintEvent, BlueprintPure)
	bool IsRootVisible() const { return false; }

//////////////////////////////////////////////////////

	UFUNCTION(BlueprintOverride)
	void SaveSettings()
	{
		Super::SaveSettings();
	}

	UFUNCTION(BlueprintOverride)
	void LoadSettings()
	{
		Super::LoadSettings();
	}

	UFUNCTION(BlueprintOverride)
	void Reset()
	{
		Super::Reset();
	}
};
