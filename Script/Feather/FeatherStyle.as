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
	FButtonClickedWithContextSignature OnClickedWithContext;

	UFUNCTION(Category = "Feather|Style", BlueprintEvent, BlueprintPure)
	UButton GetButtonWidget() { return nullptr; }

	UFUNCTION(Category = "Feather|Style", BlueprintEvent, BlueprintCallable)
	void ClickedWithContext(UFeatherButtonStyle ThisButton)
	{
		OnClickedWithContext.Broadcast(ThisButton);
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

struct FFeatherStyle
{
	UPROPERTY(Category = "Feather|Style")
	TSubclassOf<UFeatherWindowStyle> WindowStyle;

	UPROPERTY(Category = "Feather|Style")
	TSubclassOf<UFeatherButtonStyle> ButtonStyle;

	UPROPERTY(Category = "Feather|Style")
	TSubclassOf<UFeatherCheckBoxStyle> CheckBoxStyle;

	UPROPERTY(Category = "Feather|Style")
	TSubclassOf<UFeatherComboBoxStyle> ComboBoxStyle;

	UPROPERTY(Category = "Feather|Style")
	TSubclassOf<UFeatherSliderStyle> SliderStyle;

	UPROPERTY(Category = "Feather|Style")
	TSubclassOf<UFeatherTextBlockStyle> TextBlockStyle;

	UPROPERTY(Category = "Feather|Style")
	TSubclassOf<UFeatherEditableTextStyle> EditableTextStyle;
};
