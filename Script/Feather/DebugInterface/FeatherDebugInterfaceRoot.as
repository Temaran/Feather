// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

struct FForceLoadPathDefinition
{
	UPROPERTY(Category = "Path Data")
	FName ForceLoadPath;

	UPROPERTY(Category = "Path Data")
	FName Opt_ForceLoadPathRegexThatMustMatchToIncludeFile;
}

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
	TArray<TSubclassOf<UFeatherDebugInterfaceToolWindow>> ToolWindowTypes;

	// This is how much we offset each window during initial spawn.
	UPROPERTY(Category = "Feather")
	FVector2D InitialCumulativeWindowOffset = FVector2D(50.0f, 50.0f);

	// This is the input mode that should be used when closing the main window.
	UPROPERTY(Category = "Feather")
	EFeatherInputType OnMainWindowCloseInputType = EFeatherInputType::GameAndUI;

	// Many objects that are used by the debug interface might be not referenced by anything in the game.
	// This means that Unreal will not actually load them in play, since it thinks it doesn't need them.
	// If operations or types you want to use in the interface don't show up, then add their content folder to these paths to force load them.
	// NOTE: For this to work in cooked builds, you must also add this path to your DefaultGame.ini. Something like this:
	// NOTE: If you are trying to make something spawn server side, you might also have to handle these paths on that side too!
	// [/Script/UnrealEd.ProjectPackagingSettings]
	// +DirectoriesToAlwaysCook=(Path="/Game/DebugInterface")
	UPROPERTY(Category = "Feather")
	TArray<FForceLoadPathDefinition> ForceLoadPaths;
	default ForceLoadPaths = CreateDefaultForceLoadPaths();

	UPROPERTY(Category = "Feather|Style")
	bool bUseLayoutStyleForAllWindows = true;

	UFeatherDebugInterfaceMainWindow MainWindow;
	TArray<UFeatherDebugInterfaceToolWindow> ToolWindows;
	TArray<UFeatherDebugInterfaceWindow> AllWindows;
	int CurrentTopZ;

	TArray<FForceLoadPathDefinition> CreateDefaultForceLoadPaths()
	{
		TArray<FForceLoadPathDefinition> LoadPaths;
		FForceLoadPathDefinition DebugInterfacePath;
		DebugInterfacePath.ForceLoadPath = n"/Game/DebugInterface";
		DebugInterfacePath.Opt_ForceLoadPathRegexThatMustMatchToIncludeFile = n"";
		LoadPaths.Add(DebugInterfacePath);

		return LoadPaths;
	}

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
		for(const FForceLoadPathDefinition& ForceLoadPath : ForceLoadPaths)
		{
			AssetRegistry::LoadAllBlueprintsUnderPath(ForceLoadPath.ForceLoadPath, ForceLoadPath.Opt_ForceLoadPathRegexThatMustMatchToIncludeFile.ToString());
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

			UFeatherDebugInterfaceToolWindow NewToolWindow = Cast<UFeatherDebugInterfaceToolWindow>(CreateFeatherWidget(TSubclassOf<UFeatherWidget>(ToolWindowType)));
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

		for(UFeatherDebugInterfaceToolWindow ToolWindow : ToolWindows)
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
