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

import Feather.FeatherSettings;
import Feather.FeatherWidget;

enum EFeatherWindowTransformState
{
	NotBeingTransformed,
	IsBeingMoved,
	IsBeingResized
};

// An alternative to this is to use the config meta-data, but that will not work if you have multiple instances of the same type, which will be quite common.
struct FFeatherWindowSaveState
{
	FVector2D WindowPosition;
	FVector2D WindowSize;
	float TransparencyAlpha;
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
	FVisibilityChangedEvent OnVisibilityChanged;

	UPROPERTY(Category = "Feather|Events")
	FTransparencyChangedEvent OnTransparencyChanged;

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

	// If this is true, the window will save every time you transform the window with the mouse
	UPROPERTY(Category = "Feather|Settings")
	bool bAutoSaveOnCompletedTransform = true;

	private FVector2D CachedMouseStartPos;
	private FVector2D CachedStartPosition;
	private FVector2D CachedStartSize;


	UFUNCTION(BlueprintOverride)
	void FeatherConstruct()
	{
		Super::FeatherConstruct();

		if(!System::IsValid(RootCanvasSlot))
		{
			RootCanvasSlot = FindRootCanvasSlot(this);
		}

		UFeatherWindowStyle MyWindowStyle = GetWindowStyle();
		if(ensure(System::IsValid(MyWindowStyle), "Windows should have a window style!"))
		{
			MyWindowStyle.ActualWindow = this;
		}
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
				break;
			}
			case EFeatherWindowTransformState::IsBeingResized:
			{
				const FVector2D NewWindowSize = ScaledDeltaMousePosPx + CachedStartSize;
				SetWindowSize(NewWindowSize);
				break;
			}
			default:
			{
				return FEventReply::Unhandled();
			}
		}

		return FEventReply::Handled();
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
				return WidgetBlueprint::ReleaseMouseCapture(FEventReply::Handled());
			}
			case EFeatherWindowTransformState::IsBeingResized:
			{
				TransformState = EFeatherWindowTransformState::NotBeingTransformed;
				OnResizeEnd.Broadcast(this, GetWindowSize());
				return WidgetBlueprint::ReleaseMouseCapture(FEventReply::Handled());
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
		SaveState.TransparencyAlpha = GetWindowTransparency();
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
			SetWindowTransparency(SaveState.TransparencyAlpha);
			SetVisibility(SaveState.bIsVisible ? ESlateVisibility::Visible : ESlateVisibility::Hidden);
		}
	}

	UFUNCTION(BlueprintOverride)
	void ResetSettingsToDefault()
	{
		// Try to figure out a good configuration here.
		SetWindowPosition(FVector2D(0.0f, 0.0f));
		SetWindowSize(FVector2D(400.0f, 600.0f));
		SetWindowTransparency(1.0f);
		SetVisibility(ESlateVisibility::Visible);
	}

//////////////////////////////////////////////////////////////////////////////
// Event Callbacks

	UFUNCTION(Category = "Feather|Event Callbacks", BlueprintEvent, BlueprintCallable)
	void CloseWindow()
	{
		SetVisibility(ESlateVisibility::Collapsed);
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
		return WidgetBlueprint::CaptureMouse(FEventReply::Handled(), this);
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
		return WidgetBlueprint::CaptureMouse(FEventReply::Handled(), this);
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
				FMath::Clamp(NewPosition.X, DragMarginPx - SlotSize.X, ViewportSize.X - DragMarginPx),
				FMath::Clamp(NewPosition.Y, DragMarginPx - SlotSize.Y, ViewportSize.Y - DragMarginPx));

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
				NewWindowSize.X = FMath::Max(NewWindowSize.X, MinimumWindowSize.X);
				NewWindowSize.Y = FMath::Max(NewWindowSize.Y, MinimumWindowSize.Y);
			}
			if(bHasMaximumWindowSize)
			{
				NewWindowSize.X = FMath::Min(NewWindowSize.X, MaximumWindowSize.X);
				NewWindowSize.Y = FMath::Min(NewWindowSize.Y, MaximumWindowSize.Y);
			}

			RootCanvasSlot.SetSize(NewWindowSize);
			OnResized.Broadcast(this, NewWindowSize);
		}
		else
		{
			Warning("Feather: Cannot run setup without root canvas!");
		}
	}

	UFUNCTION(Category = "Feather|Accessors", BlueprintPure)
	float GetWindowTransparency() const
	{
		return RenderOpacity;
	}
	UFUNCTION(Category = "Feather|Accessors")
	void SetWindowTransparency(float NewAlpha)
	{
		RenderOpacity = FMath::Clamp(NewAlpha, 0.0f, 1.0f);
		OnTransparencyChanged.Broadcast(this, RenderOpacity);
	}

	UFUNCTION(Category = "Feather|Accessors", BlueprintPure)
	bool GetWindowVisibility() const
	{
		return IsVisible();
	}
	UFUNCTION(Category = "Feather|Accessors")
	void SetWindowVisibility(bool NewVisibility)
	{
		SetVisibility(NewVisibility ? ESlateVisibility::Visible : ESlateVisibility::Hidden);
		OnVisibilityChanged.Broadcast(this, NewVisibility);
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
