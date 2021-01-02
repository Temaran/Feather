// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

UCLASS(Abstract)
class UFeatherWindowStyle : UUserWidget
{
	// Set this to your UFeatherWindow
	UPROPERTY(Category = "Feather|Style")
	UWidget ActualWindow;

	UFUNCTION(Category = "Feather|Style", BlueprintEvent, BlueprintPure)
	UNamedSlot GetWindowContentSlot() { return nullptr; }
};

event void FButtonClickedWithContextSignature(UFeatherButtonStyle ThisButton);
UCLASS(Abstract)
class UFeatherButtonStyle : UUserWidget
{
	UPROPERTY(Category = "Feather|Style")
	bool bUseStyleOverride;

	UPROPERTY(Category = "Feather|Style", meta = (EditCondition = bUseStyleOverride))
	FButtonStyle OverrideButtonStyle;
	
	UPROPERTY(Category = "Feather|Style", meta = (EditCondition = bUseStyleOverride))
	FLinearColor OverrideButtonTint;

	UPROPERTY(Category = "Feather|Style")
	FButtonClickedWithContextSignature OnClickedWithContext;

	UFUNCTION(Category = "Feather|Style", BlueprintEvent, BlueprintPure)
	UButton GetButtonWidget() { return nullptr; }

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		SetStyleOverride();
	}
	
	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		SetStyleOverride();
	}

	UFUNCTION(Category = "Feather|Style", BlueprintEvent, BlueprintCallable)
	void ClickedWithContext(UFeatherButtonStyle ThisButton)
	{
		OnClickedWithContext.Broadcast(ThisButton);
	}

	void SetStyleOverride()
	{
		if(bUseStyleOverride)
		{
			GetButtonWidget().SetStyle(OverrideButtonStyle);
			GetButtonWidget().SetBackgroundColor(OverrideButtonTint);
		}
	}
};

UCLASS(Abstract)
class UFeatherCheckBoxStyle : UUserWidget
{
	UFUNCTION(Category = "Feather|Style", BlueprintEvent, BlueprintPure)
	UCheckBox GetCheckBoxWidget() { return nullptr; }
};

UCLASS(Abstract)
class UFeatherComboBoxStyle : UUserWidget
{
	UFUNCTION(Category = "Feather|Style", BlueprintEvent, BlueprintPure)
	UComboBoxString GetComboBoxWidget() { return nullptr; }
};

UCLASS(Abstract)
class UFeatherSliderStyle : UUserWidget
{
	UFUNCTION(Category = "Feather|Style", BlueprintEvent, BlueprintPure)
	USlider GetSliderWidget() { return nullptr; }
};

UCLASS(Abstract)
class UFeatherTextBlockStyle : UUserWidget
{
	UFUNCTION(Category = "Feather|Style", BlueprintEvent, BlueprintPure)
	UTextBlock GetTextWidget() { return nullptr; }
};

UCLASS(Abstract)
class UFeatherEditableTextStyle : UUserWidget
{
	UFUNCTION(Category = "Feather|Style", BlueprintEvent, BlueprintPure)
	UEditableText GetEditableText() { return nullptr; }
};

// This is the main style container. You can add multiple styles and identify them by name. Default styles have an empty identifier
struct FFeatherStyle
{
	UPROPERTY(Category = "Feather|Style")
	TMap<FName, TSubclassOf<UFeatherWindowStyle>> WindowStyles;

	UPROPERTY(Category = "Feather|Style")
	TMap<FName, TSubclassOf<UFeatherButtonStyle>> ButtonStyles;

	UPROPERTY(Category = "Feather|Style")
	TMap<FName, TSubclassOf<UFeatherCheckBoxStyle>> CheckBoxStyles;

	UPROPERTY(Category = "Feather|Style")
	TMap<FName, TSubclassOf<UFeatherComboBoxStyle>> ComboBoxStyles;

	UPROPERTY(Category = "Feather|Style")
	TMap<FName, TSubclassOf<UFeatherSliderStyle>> SliderStyles;

	UPROPERTY(Category = "Feather|Style")
	TMap<FName, TSubclassOf<UFeatherTextBlockStyle>> TextBlockStyles;

	UPROPERTY(Category = "Feather|Style")
	TMap<FName, TSubclassOf<UFeatherEditableTextStyle>> EditableTextStyles;
};
