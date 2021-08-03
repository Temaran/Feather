// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherRoot;
import Feather.FeatherWindow;
import Feather.DebugInterface.FeatherDebugInterfaceWindow;
import Feather.DebugInterface.FeatherDebugInterfaceMainWindow;
import Feather.DebugInterface.FeatherDebugInterfaceOperation;

// This is just a container to configure the debug interface and provide a root canvas.
UCLASS(Abstract)
class UFeatherDebugInterfaceRoot : UFeatherRoot
{
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

	// This is the input mode that should be used when closing the main window.
	UPROPERTY(Category = "Feather")
	EFeatherInputType OnMainWindowCloseInputType = EFeatherInputType::GameAndUI;

	// Many objects that are used by the debug interface might be not referenced by anything. You can force load all of their subclasses here.
	UPROPERTY(Category = "Feather")
	TArray<FName> ForceLoadPaths;
	default ForceLoadPaths.Add(n"/Game/DebugInterface/");

	// Other objects we might want to load by soft object path
	UPROPERTY(Category = "Feather")
	TArray<FSoftClassPath> ForceLoadClasses;

	UPROPERTY(Category = "Feather|Style")
	bool bUseLayoutStyleForAllWindows = true;

	UFeatherDebugInterfaceMainWindow MainWindow;
	TArray<UFeatherDebugInterfaceWindow> ToolWindows;
	TArray<UFeatherDebugInterfaceWindow> AllWindows;
	int CurrentTopZ;


	UFUNCTION(BlueprintOverride)
	void OnInitialized()
	{
		Super::OnInitialized();

		RootCanvasPanel = Cast<UCanvasPanel>(GetRootWidget());
		if(!System::IsValid(RootCanvasPanel))
		{
			RootCanvasPanel = Cast<UCanvasPanel>(ConstructWidget(UCanvasPanel::StaticClass()));
			SetRootWidget(RootCanvasPanel);
		}

		FVector2D CumulativePosition = InitialCumulativeWindowOffset;
		CurrentTopZ = 0;

		// Force load classes
		for(FName ForceLoadPath : ForceLoadPaths)
		{
			// @TODO: This is not working in cooked.. Not sure what is wrong.
			// AssetRegistry::LoadAllBlueprintsUnderPath(ForceLoadPath);
		}
		for(FSoftClassPath ClassPath : ForceLoadClasses)
		{
			ClassPath.TryLoadClass();
		}

		// Initialize windows
		MainWindow = Cast<UFeatherDebugInterfaceMainWindow>(CreateFeatherWidget(TSubclassOf<UFeatherWidget>(MainWindowType)));
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

			UFeatherDebugInterfaceWindow NewToolWindow = Cast<UFeatherDebugInterfaceWindow>(CreateFeatherWidget(TSubclassOf<UFeatherWidget>(ToolWindowType)));
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
			ToolWindow.FeatherConstruct(FeatherStyle, FeatherConfiguration);

			UFeatherDebugInterfaceOptionsWindow OptionsWindow = Cast<UFeatherDebugInterfaceOptionsWindow>(ToolWindow);
			if(System::IsValid(OptionsWindow))
			{
				OptionsWindow.OnResetEverything.AddUFunction(this, n"ResetEverything");
			}
		}

		MainWindow.ToolWindows = ToolWindows;
		MainWindow.FeatherConstruct(FeatherStyle, FeatherConfiguration);

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
		Super::Construct();
		LoadSettings();
	}

	UFUNCTION()
	void ResetEverything()
	{
		ResetSettingsToDefault();
		SaveSettings();
	}

	UFUNCTION()
	void MainWindowClosed()
	{
		SetRootVisibility(false, OnMainWindowCloseInputType);
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

	UFUNCTION(BlueprintOverride)
	void SetRootVisibility(bool bNewVisibility, EFeatherInputType InputType, bool bAffectMouseCursor)
	{
		Super::SetRootVisibility(bNewVisibility, InputType, bAffectMouseCursor);
		SetWindowVisibility(bNewVisibility);
	}

	UFUNCTION(BlueprintOverride)
	bool IsRootVisible() const
	{
		return IsVisible() && IsAnyWindowVisible();
	}

	void SetWindowVisibility(bool bNewVisibility)
	{
		if(IsVisible() && IsAnyWindowVisible(true))
		{
			// Let each window handle itself, but we cannot hide the layout.
			for(UFeatherDebugInterfaceWindow Window : AllWindows)
			{
				Window.SetWindowVisibility(bNewVisibility);
			}
		}
		else
		{
			// Since no persistant windows are visible we can just hide the entire layout!
			SetVisibility(bNewVisibility ? ESlateVisibility::Visible : ESlateVisibility::Collapsed);
		}
	}

	bool IsAnyWindowVisible(bool bOnlyCheckPersistentWindows = false) const
	{
		for(UFeatherDebugInterfaceWindow Window : AllWindows)
		{
			if(bOnlyCheckPersistentWindows)
			{
				if(Window.bIsPersistent && Window.IsVisible())
				{
					return true;
				}
			}
			else if(Window.IsVisible())
			{
				return true;
			}
		}

		return false;
	}

///////////////////////////////////////////////////////////
// Settings

	UFUNCTION(BlueprintOverride)
	void SaveSettings()
	{
		Super::SaveSettings();

		if(bIsPossibleToSave)
		{
			for(auto Window : AllWindows)
			{
				Window.SaveSettings();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void LoadSettings()
	{
		Super::LoadSettings();

		for(auto Window : AllWindows)
		{
			Window.LoadSettings();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Reset()
	{
		Super::Reset();

		for(auto Window : AllWindows)
		{
			Window.ResetSettingsToDefault();
		}
	}
};
