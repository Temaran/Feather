// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherWidget;
import Feather.FeatherWindow;
import Feather.DebugInterface.FeatherDebugInterfaceWindow;
import Feather.DebugInterface.FeatherDebugInterfaceMainWindow;
import Feather.DebugInterface.FeatherDebugInterfaceOperation;

enum EDebugInterfaceState
{
	Disabled,
	EnabledWithGame,
	EnabledUIOnly
};

namespace UFeatherDebugInterfaceRoot
{
	UFUNCTION(Category = "Feather|Debug Interface")
	UFeatherDebugInterfaceRoot CreateDebugInterface(APlayerController Player, TSubclassOf<UFeatherDebugInterfaceRoot> RootWidgetType, int ZOrder = 0)
	{
		if(!ensure(RootWidgetType.IsValid(), "Must supply valid root widget type!")
		 || !ensure(System::IsValid(Player), "Must supply valid player!"))
		{
			return nullptr;
		}

		UFeatherDebugInterfaceRoot RootWidget = Cast<UFeatherDebugInterfaceRoot>(WidgetBlueprint::CreateWidget(RootWidgetType.Get(), Player));
		RootWidget.AddToViewport(ZOrder);
		return RootWidget;
	}

	UFUNCTION(Category = "Feather|Debug Interface")
	void SetDebugInterfaceState(UFeatherDebugInterfaceRoot DebugInterface, EDebugInterfaceState NewState)
	{
		if(!System::IsValid(DebugInterface))
		{
			return;
		}

		switch(NewState)
		{
			case EDebugInterfaceState::EnabledWithGame:
			{
				DebugInterface.SetDebugInterfaceVisibility(true);
				WidgetBlueprint::SetInputMode_GameAndUIEx(DebugInterface.OwningPlayer, bHideCursorDuringCapture = false);
				DebugInterface.OwningPlayer.SetbShowMouseCursor(true);
				break;
			}

			case EDebugInterfaceState::EnabledUIOnly:
			{
				DebugInterface.SetDebugInterfaceVisibility(true);
				WidgetBlueprint::SetInputMode_UIOnlyEx(DebugInterface.OwningPlayer);
				DebugInterface.OwningPlayer.SetbShowMouseCursor(true);
				break;
			}

			default:
			{
				DebugInterface.SetDebugInterfaceVisibility(false);
				WidgetBlueprint::SetInputMode_GameOnly(DebugInterface.OwningPlayer);
				DebugInterface.OwningPlayer.SetbShowMouseCursor(false);
				break;
			}
		}
	}
}

// This is just a container to configure the debug interface and provide a root canvas.
UCLASS(Abstract)
class UFeatherDebugInterfaceRoot : UFeatherWidget
{
	default SetPaletteCategory(FText::FromString("Feather"));

	UPROPERTY(Category = "Feather", NotEditable)
	UCanvasPanel RootCanvasPanel;

	// This is your main window type.
	UPROPERTY(Category = "Feather")
	TSubclassOf<UFeatherDebugInterfaceMainWindow> MainWindowType;

	// Add the tool window types you want to support here.
	UPROPERTY(Category = "Feather")
	TArray<TSubclassOf<UFeatherDebugInterfaceWindow>> ToolWindowTypes;

	// This is how much we offset each window during initial spawn.
	UPROPERTY(Category = "Feather")
	FVector2D InitialCumulativeWindowOffset = FVector2D(50.0f, 50.0f);

	UPROPERTY(Category = "Feather|Style")
	bool bUseLayoutStyleForAllWindows = true;

	UFeatherDebugInterfaceMainWindow MainWindow;
	TArray<UFeatherDebugInterfaceWindow> ToolWindows;
	TArray<UFeatherDebugInterfaceWindow> AllWindows;
	int CurrentTopZ;


	UFUNCTION(BlueprintOverride)
	void OnInitialized()
	{
		RootCanvasPanel = Cast<UCanvasPanel>(GetRootWidget());
		if(!System::IsValid(RootCanvasPanel))
		{
			RootCanvasPanel = Cast<UCanvasPanel>(ConstructWidget(UCanvasPanel::StaticClass()));
			SetRootWidget(RootCanvasPanel);
		}

		FVector2D CumulativePosition = InitialCumulativeWindowOffset;
		CurrentTopZ = 0;

		// Initialize windows
		MainWindow = Cast<UFeatherDebugInterfaceMainWindow>(CreateStyledWidget(TSubclassOf<UFeatherWidget>(MainWindowType)));
		if(ensure(System::IsValid(MainWindow), "Main window must be valid for the debug interface to work!"))
		{
			UCanvasPanelSlot CanvasSlot = RootCanvasPanel.AddChildToCanvas(MainWindow);
			CanvasSlot.SetPosition(CumulativePosition);
			CanvasSlot.SetSize(MainWindow.InitialSize);
			CanvasSlot.SetZOrder(CurrentTopZ);
			MainWindow.OnMainWindowClosed.AddUFunction(this, n"MainWindowClosed");
		}

		AllWindows.Add(MainWindow);
		for(TSubclassOf<UFeatherDebugInterfaceWindow> ToolWindowType : ToolWindowTypes)
		{
			if(!System::IsValid(ToolWindowType.Get())
				|| !ensure(!ToolWindowType.Get().IsA(UFeatherDebugInterfaceMainWindow::StaticClass()), "Tool windows cannot be of main window types!"))
			{
				continue;
			}

			UFeatherDebugInterfaceWindow NewToolWindow = Cast<UFeatherDebugInterfaceWindow>(CreateStyledWidget(TSubclassOf<UFeatherWidget>(ToolWindowType)));
			if(ensure(System::IsValid(NewToolWindow), "Tool window could not be created!"))
			{
				CumulativePosition += InitialCumulativeWindowOffset;
				CurrentTopZ++;

				ToolWindows.Add(NewToolWindow);
				AllWindows.Add(NewToolWindow);
				UCanvasPanelSlot CanvasSlot = RootCanvasPanel.AddChildToCanvas(NewToolWindow);
				CanvasSlot.SetPosition(CumulativePosition);
				CanvasSlot.SetSize(NewToolWindow.InitialSize);
				CanvasSlot.SetZOrder(CurrentTopZ);
			}
		}

		for(UFeatherDebugInterfaceWindow ToolWindow : ToolWindows)
		{
			ToolWindow.ConstructFeatherWidget();
		}

		MainWindow.ToolWindows = ToolWindows;
		MainWindow.ConstructFeatherWidget();

		// Set up Z-Order updating
		for(UFeatherDebugInterfaceWindow Window : AllWindows)
		{
			Window.OnResizeStart.AddUFunction(this, n"ReorderZ");
			Window.OnMoveStart.AddUFunction(this, n"ReorderZ");
			Window.OnForceOnTop.AddUFunction(this, n"ForceWindowOnTop");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		LoadSettings();
	}

	UFUNCTION()
	void MainWindowClosed()
	{
		UFeatherDebugInterfaceRoot::SetDebugInterfaceState(this, EDebugInterfaceState::Disabled);
	}

	UFUNCTION()
	void ReorderZ(UFeatherWindow Window, FVector2D Dummy)
	{
		ForceWindowOnTop(Window);
	}
	
	UFUNCTION()
	void ForceWindowOnTop(UFeatherWindow Window)
	{
		CurrentTopZ++;
		UCanvasPanelSlot CanvasSlot = Cast<UCanvasPanelSlot>(Window.Slot);
		if(ensure(System::IsValid(CanvasSlot), "All windows must reside on a canvas!"))
		{
			CanvasSlot.SetZOrder(CurrentTopZ);
		}
	}

	UFUNCTION(Category = "Feather")
	void SetDebugInterfaceVisibility(bool NewVisibility)
	{
		if(IsVisible() && IsAnyWindowVisible(true))
		{
			// Let each window handle itself, but we cannot hide the layout.
			for(UFeatherDebugInterfaceWindow Window : AllWindows)
			{
				Window.SetWindowVisibility(NewVisibility);
			}
		}
		else
		{
			// Since no persistant windows are visible we can just hide the entire layout!
			SetVisibility(NewVisibility ? ESlateVisibility::Visible : ESlateVisibility::Collapsed);
		}
	}
	UFUNCTION(Category = "Feather", BlueprintPure)
	bool GetDebugInterfaceVisibility() const
	{
		return IsVisible() && IsAnyWindowVisible();
	}
	UFUNCTION(Category = "Feather")
	void ToggleDebugInterfaceVisibility()
	{
		SetDebugInterfaceVisibility(!GetDebugInterfaceVisibility());
	}

	UFUNCTION(Category = "Feather", BlueprintPure)
	bool IsAnyWindowVisible(bool OnlyCheckPersistentWindows = false) const
	{
		for(UFeatherDebugInterfaceWindow Window : AllWindows)
		{
			if(OnlyCheckPersistentWindows)
			{
				return Window.bIsPersistent && Window.IsVisible();
			}
			else
			{
				return Window.IsVisible();
			}
		}

		return false;
	}

///////////////////////////////////////////////////////////
// Settings

	UFUNCTION(BlueprintOverride)
	void SaveSettings()
	{
		for(auto Window : AllWindows)
		{
			Window.SaveSettings();
		}
	}

	UFUNCTION(BlueprintOverride)
	void LoadSettings()
	{
		for(auto Window : AllWindows)
		{
			Window.LoadSettings();
		}
	}

	UFUNCTION(BlueprintOverride)
	void ResetSettingsToDefault()
	{
		Super::ResetSettingsToDefault();

		for(auto Window : AllWindows)
		{
			Window.ResetSettingsToDefault();
		}
	}
};
