// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

/* This is the base class for all feather windows.
 * When using this, you should override the following functions on your UMG widget:
 *
 * You should also bind these methods to widget events (check each method for more details)
 * - OnWindowStartMove
 * - OnWindowStartResize
 */

enum EFeatherWindowTransformState
{
	NotBeingTransformed,
	IsBeingMoved,
	IsBeingResized
};

// An alternative to this is to use the config meta-data, but that will not work if you have multiple instances of the same type, which will be quite common.
struct FFeatherWindowSaveState
{
	UPROPERTY()
	FVector2D WindowPosition;

	UPROPERTY()
	FVector2D WindowSize;

	UPROPERTY()
	float TransparencyAlpha;

	UPROPERTY()
	bool bIsVisible;
};

event void FMoveStartEvent(UFeatherWindow Window, FVector2D NewPositionPx);
event void FMovedEvent(UFeatherWindow Window, FVector2D NewPositionPx);
event void FMoveEndEvent(UFeatherWindow Window, FVector2D NewPositionPx);
event void FResizeStartEvent(UFeatherWindow Window, FVector2D NewSizePx);
event void FResizedEvent(UFeatherWindow Window, FVector2D NewSizePx);
event void FResizeEndEvent(UFeatherWindow Window, FVector2D NewSizePx);
event void FVisibilityChangedEvent(UFeatherWindow Window, bool NewVisibility);
event void FTransparencyChangedEvent(UFeatherWindow Window, float NewTransparencyAlpha);
event void FForceOnTopEvent(UFeatherWindow Window);

UCLASS(Abstract)
class UFeatherWindow : UFeatherWidget
{
	// All windows must live on a "root canvas". This canvas usually covers the entire screen, but it could be smaller. The window will attempt to find its own slot on root canvas when it initializes.
	UPROPERTY(Category = "Feather", NotEditable)
	UCanvasPanelSlot RootCanvasSlot;

	UPROPERTY(Category = "Feather|Events")
	FMovedEvent OnMoveStart;
	UPROPERTY(Category = "Feather|Events")
	FMovedEvent OnMoved;
	UPROPERTY(Category = "Feather|Events")
	FMovedEvent OnMoveEnd;

	UPROPERTY(Category = "Feather|Events")
	FResizedEvent OnResizeStart;
	UPROPERTY(Category = "Feather|Events")
	FResizedEvent OnResized;
	UPROPERTY(Category = "Feather|Events")
	FResizedEvent OnResizeEnd;

	UPROPERTY(Category = "Feather|Events")
	FVisibilityChangedEvent OnWindowVisibilityChanged;

	UPROPERTY(Category = "Feather|Events")
	FTransparencyChangedEvent OnWindowTransparencyChanged;

	UPROPERTY(Category = "Feather|Events")
	FForceOnTopEvent OnForceOnTop;

	UPROPERTY(Category = "Feather|Transformation", NotEditable)
	EFeatherWindowTransformState TransformState = EFeatherWindowTransformState::NotBeingTransformed;

	UPROPERTY(Category = "Feather|Transformation")
	bool bHasMinimumWindowSize = true;
	UPROPERTY(Category = "Feather|Transformation", meta = (EditCondition = HasMinimumWindowSize))
	FVector2D MinimumWindowSize = FVector2D(800.0f, 450.0f);

	UPROPERTY(Category = "Feather|Transformation")
	bool bHasMaximumWindowSize = false;
	UPROPERTY(Category = "Feather|Transformation", meta = (EditCondition = HasMaximumWindowSize))
	FVector2D MaximumWindowSize = FVector2D(1024.0f, 800.0f);

	// We need to prevent the window from going off the screen when dragging it around.
	UPROPERTY(Category = "Feather|Transformation")
	float DragMarginPx = 100.0f;

	UPROPERTY(Category = "Feather|Settings")
	float MinimumOpacityUNorm = 0.2f;

	// If this is true, the window will save every time you transform the window with the mouse
	UPROPERTY(Category = "Feather|Settings")
	bool bAutoSaveOnCompletedTransform = true;

	private FVector2D CachedMouseStartPos;
	private FVector2D CachedStartPosition;
	private FVector2D CachedStartSize;


	UFUNCTION(BlueprintOverride)
	void FeatherConstruct(FFeatherStyle InStyle, FFeatherConfig InConfig)
	{
		Super::FeatherConstruct(InStyle, InConfig);

		if(!System::IsValid(RootCanvasSlot))
		{
			RootCanvasSlot = FindRootCanvasSlot(this);
		}

		UFeatherWindowStyle MyWindowStyle = GetWindowStyle();
		if(ensure(System::IsValid(MyWindowStyle), "Windows should have a window style!"))
		{
			MyWindowStyle.SetNewActualWindow(this);
		}

		check(MinimumOpacityUNorm >= 0.0f && MinimumOpacityUNorm <= 1.0f, "Bad minimum opacity defined! Needs to be a UNorm!");
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseMove(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		const FVector2D ScreenSpaceMousePosPx = Input::PointerEvent_GetScreenSpacePosition(MouseEvent);
		const FVector2D DeltaMousePosPx = ScreenSpaceMousePosPx - CachedMouseStartPos;
		const FVector2D ScaledDeltaMousePosPx = DeltaMousePosPx / WidgetLayout::GetViewportScale();

		switch(TransformState)
		{
			case EFeatherWindowTransformState::IsBeingMoved:
			{
				const FVector2D NewWindowPosition = ScaledDeltaMousePosPx + CachedStartPosition;
				SetWindowPosition(NewWindowPosition);
				return FEventReply::Handled();
			}
			case EFeatherWindowTransformState::IsBeingResized:
			{
				const FVector2D NewWindowSize = ScaledDeltaMousePosPx + CachedStartSize;
				SetWindowSize(NewWindowSize);
				return FEventReply::Handled();
			}
			default:
			{
				return FEventReply::Unhandled();
			}
		}

		return FEventReply::Unhandled();
	}

	UFUNCTION(BlueprintOverride)
	FEventReply OnMouseButtonUp(FGeometry MyGeometry, FPointerEvent MouseEvent)
	{
		if(bAutoSaveOnCompletedTransform && TransformState != EFeatherWindowTransformState::NotBeingTransformed)
		{
			SaveSettings();
		}

		switch(TransformState)
		{
			case EFeatherWindowTransformState::IsBeingMoved:
			{
				TransformState = EFeatherWindowTransformState::NotBeingTransformed;
				OnMoveEnd.Broadcast(this, GetWindowPosition());
				FEventReply Reply = FEventReply::Handled();
				return WidgetBlueprint::ReleaseMouseCapture(Reply);
			}
			case EFeatherWindowTransformState::IsBeingResized:
			{
				TransformState = EFeatherWindowTransformState::NotBeingTransformed;
				OnResizeEnd.Broadcast(this, GetWindowSize());
				FEventReply Reply = FEventReply::Handled();
				return WidgetBlueprint::ReleaseMouseCapture(Reply);
			}
			default:
			{
				return FEventReply::Unhandled();
			}
		}

		return FEventReply::Unhandled();
	}

//////////////////////////////////////////////////////////////////////////////
// Settings

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
	void SaveToString(FString& InOutSaveString)
	{
		FFeatherWindowSaveState SaveState;
		SaveState.WindowPosition = GetWindowPosition();
		SaveState.WindowSize = GetWindowSize();
		SaveState.TransparencyAlpha = GetWindowOpacity();
		SaveState.bIsVisible = IsVisible();
		FJsonObjectConverter::AppendUStructToJsonObjectString(SaveState, InOutSaveString);
	}

	UFUNCTION(BlueprintOverride)
	void LoadFromString(const FString& InSaveString)
	{
		FFeatherWindowSaveState SaveState;
		if(FJsonObjectConverter::JsonObjectStringToUStruct(InSaveString, SaveState))
		{
			SetWindowPosition(SaveState.WindowPosition);
			SetWindowSize(SaveState.WindowSize);
			SetWindowOpacity(SaveState.TransparencyAlpha);
			SetVisibility(SaveState.bIsVisible ? ESlateVisibility::Visible : ESlateVisibility::Hidden);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Reset()
	{
		// Try to figure out a good configuration here.
		SetWindowSize(MinimumWindowSize);
		SetWindowOpacity(1.0f);
		SetVisibility(ESlateVisibility::Collapsed);
	}

//////////////////////////////////////////////////////////////////////////////
// Event Callbacks

	UFUNCTION(Category = "Feather|Event Callbacks", BlueprintEvent, BlueprintCallable)
	void CloseWindow()
	{
		SetVisibility(ESlateVisibility::Collapsed);
		SaveSettings();
	}

	// You must bind this to the OnMouseButtonDown event of the element you want to use for dragging.
	UFUNCTION(Category = "Feather|Event Callbacks")
	FEventReply OnWindowStartMove(FGeometry MyGeometry, FPointerEvent& MouseEvent)
	{
		if(!System::IsValid(RootCanvasSlot))
		{
			Warning("Feather: Window must reside on a canvas!");
			return FEventReply::Unhandled();
		}

		CachedMouseStartPos = Input::PointerEvent_GetScreenSpacePosition(MouseEvent);
		CachedStartPosition = RootCanvasSlot.GetPosition();
		TransformState = EFeatherWindowTransformState::IsBeingMoved;
		OnMoveStart.Broadcast(this, CachedStartPosition);
		FEventReply Reply = FEventReply::Handled();
		return WidgetBlueprint::CaptureMouse(Reply, this);
	}

	// You must bind this to the OnMouseButtonDown event of the element you want to use for resizing.
	UFUNCTION(Category = "Feather|Event Callbacks")
	FEventReply OnWindowStartResize(FGeometry MyGeometry, FPointerEvent& MouseEvent)
	{
		if(!System::IsValid(RootCanvasSlot))
		{
			Warning("Feather: Window must reside on a canvas!");
			return FEventReply::Unhandled();
		}

		CachedMouseStartPos = Input::PointerEvent_GetScreenSpacePosition(MouseEvent);
		CachedStartSize = RootCanvasSlot.GetSize();
		TransformState = EFeatherWindowTransformState::IsBeingResized;
		OnResizeStart.Broadcast(this, CachedStartSize);
		FEventReply Reply = FEventReply::Handled();
		return WidgetBlueprint::CaptureMouse(Reply, this);
	}

//////////////////////////////////////////////////////////////////////////////
// Overrides

	UFUNCTION(Category = "Feather", BlueprintEvent, BlueprintPure)
	UFeatherWindowStyle GetWindowStyle()
	{
		return nullptr;
	}

//////////////////////////////////////////////////////////////////////////////
// Accessors

	UFUNCTION(Category = "Feather|Accessors", BlueprintPure)
	FVector2D GetWindowPosition() const
	{
		if(System::IsValid(RootCanvasSlot))
		{
			return RootCanvasSlot.GetPosition();
		}
		else
		{
			Warning("Feather: Cannot run setup without root canvas!");
			return FVector2D::ZeroVector;
		}
	}
	UFUNCTION(Category = "Feather|Accessors")
	void SetWindowPosition(FVector2D NewPosition)
	{
		if(System::IsValid(RootCanvasSlot))
		{
			const FVector2D SlotSize = RootCanvasSlot.GetSize();
			const FVector2D ViewportSize = WidgetLayout::GetViewportWidgetGeometry().GetLocalSize();
			const FVector2D NewWindowPosition = FVector2D(
				Math::Clamp(NewPosition.X, DragMarginPx - SlotSize.X, ViewportSize.X - DragMarginPx),
				Math::Clamp(NewPosition.Y, DragMarginPx - SlotSize.Y, ViewportSize.Y - DragMarginPx));

			RootCanvasSlot.SetPosition(NewWindowPosition);
			OnMoved.Broadcast(this, NewWindowPosition);
		}
		else
		{
			Warning("Feather: Cannot run setup without root canvas!");
		}
	}

	UFUNCTION(Category = "Feather|Accessors", BlueprintPure)
	FVector2D GetWindowSize() const
	{
		if(System::IsValid(RootCanvasSlot))
		{
			return RootCanvasSlot.GetSize();
		}
		else
		{
			Warning("Feather: Cannot run setup without root canvas!");
			return FVector2D::ZeroVector;
		}
	}
	UFUNCTION(Category = "Feather|Accessors")
	void SetWindowSize(FVector2D NewSize)
	{
		if(System::IsValid(RootCanvasSlot))
		{
			FVector2D NewWindowSize = NewSize;
			if(bHasMinimumWindowSize)
			{
				NewWindowSize.X = Math::Max(NewWindowSize.X, MinimumWindowSize.X);
				NewWindowSize.Y = Math::Max(NewWindowSize.Y, MinimumWindowSize.Y);
			}
			if(bHasMaximumWindowSize)
			{
				NewWindowSize.X = Math::Min(NewWindowSize.X, MaximumWindowSize.X);
				NewWindowSize.Y = Math::Min(NewWindowSize.Y, MaximumWindowSize.Y);
			}

			RootCanvasSlot.SetSize(NewWindowSize);
			OnResized.Broadcast(this, NewWindowSize);
		}
		else
		{
			Warning("Feather: Cannot run setup without root canvas!");
		}
	}

	/* The window opacity is clamped to MinimumOpacityUNorm.
	 * GetWindowOpacity will reproject the actual render opacity to a UNorm,
	 * while GetWindowRenderOpacity will give you the actual render opacity.
	 */
	UFUNCTION(Category = "Feather|Accessors", BlueprintPure)
	float GetWindowOpacity() const
	{
		const float TotalRange = 1.0f - MinimumOpacityUNorm;
		const float CalculatedWindowOpacity = TotalRange > 0.0f ? ((RenderOpacity - MinimumOpacityUNorm) / TotalRange) : 1.0f;
		return Math::Clamp(CalculatedWindowOpacity, 0.0f, 1.0f);
	}
	UFUNCTION(Category = "Feather|Accessors", BlueprintPure)
	float GetWindowRenderOpacity() const
	{
		return RenderOpacity;
	}
	UFUNCTION(Category = "Feather|Accessors")
	void SetWindowOpacity(float NewOpacityUNorm)
	{
		float ClampedAlphaUNorm = Math::Clamp(NewOpacityUNorm, 0.0f, 1.0f);
		RenderOpacity = Math::Lerp(MinimumOpacityUNorm, 1.0f, ClampedAlphaUNorm);
		OnWindowTransparencyChanged.Broadcast(this, RenderOpacity);
		SaveSettings();
	}

	UFUNCTION(Category = "Feather|Accessors", BlueprintPure)
	bool GetWindowVisibility() const
	{
		return IsVisible();
	}
	UFUNCTION(Category = "Feather|Accessors")
	void SetWindowVisibility(bool bNewVisibility)
	{
		SetVisibility(bNewVisibility ? ESlateVisibility::Visible : ESlateVisibility::Hidden);
		OnWindowVisibilityChanged.Broadcast(this, bNewVisibility);
	}

//////////////////////////////////////////////////////////////////////////////
// API
	UFUNCTION(Category = "Feather")
	void ForceWindowOnTop()
	{
		OnForceOnTop.Broadcast(this);
	}

//////////////////////////////////////////////////////////////////////////////
// Private Methods

	private UCanvasPanelSlot FindRootCanvasSlot(UWidget CurrentWidget)
	{
		UCanvasPanelSlot CurrentSlot = Cast<UCanvasPanelSlot>(CurrentWidget.Slot);
		if(System::IsValid(CurrentSlot))
		{
			return CurrentSlot;
		}

		UWidget ParentWidget = GetParent();
		return System::IsValid(ParentWidget) ? FindRootCanvasSlot(ParentWidget) : nullptr;
	}
};
