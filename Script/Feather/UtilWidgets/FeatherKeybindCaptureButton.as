// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherWidget;

struct FFeatherKeyCombination
{
    FKey MainKey;
    TArray<FKey> HeldKeys;

    FFeatherKeyCombination()
    {
        MainKey = FKey();
        HeldKeys.Empty();
    }
};

event void FNewKeyBoundSignature(UFeatherKeybindCaptureButton CaptureButton, FFeatherKeyCombination KeyCombination);

class UFeatherKeybindCaptureButton : UFeatherWidget
{
    // This is called when a key combo is successfully bound
    UPROPERTY(Category = "Keybind Capture")
    FNewKeyBoundSignature OnKeyBound;
    
    UPROPERTY(Category = "Keybind Capture")
    UFeatherCheckBoxStyle KeybindButton;

    UPROPERTY(Category = "Keybind Capture")
    FFeatherKeyCombination KeyCombo;

    bool bIsRecording = false;

    UFUNCTION(BlueprintOverride)
    void FeatherConstruct()
    {
        Super::FeatherConstruct();

        KeybindButton = CreateCheckBox(n"KeybindButton");
        KeybindButton.GetCheckBoxWidget().OnCheckStateChanged.AddUFunction(this, n"KeybindButtonClicked");
        SetRootWidget(KeybindButton);

        UpdateToolTip();
    }

    UFUNCTION()
    void KeybindButtonClicked(bool bCurrentKeybindState)
    {
        if(bCurrentKeybindState)
        {
            KeyCombo.MainKey = FKey();
            KeyCombo.HeldKeys.Empty();
            bIsRecording = true;
            KeybindButton.SetToolTipText(FText::FromString("Input a key combination to record it!"));
        }
        else
        {
            bIsRecording = false;
        }
    }

    UFUNCTION(BlueprintOverride)
    FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
    {
        if(bIsRecording 
            && InKeyEvent.Key != EKeys::LeftMouseButton
            && InKeyEvent.Key != EKeys::RightMouseButton)
        {
            KeyCombo.HeldKeys.Add(InKeyEvent.Key);
        }

        return FEventReply::Unhandled();
    }

    UFUNCTION(BlueprintOverride)
    FEventReply OnKeyUp(FGeometry MyGeometry, FKeyEvent InKeyEvent)
    {
        if(bIsRecording 
            && InKeyEvent.Key != EKeys::LeftMouseButton
            && InKeyEvent.Key != EKeys::RightMouseButton)
        {
            KeyCombo.MainKey = InKeyEvent.Key;
            KeyCombo.HeldKeys.Remove(InKeyEvent.Key);
            UpdateToolTip();
            KeybindButton.SetIsChecked(false);
            OnKeyBound.Broadcast(this, KeyCombo);
            bIsRecording = false;

            return FEventReply::Handled();
        }
        
        return FEventReply::Unhandled();
    }

    void SetNewKeyCombo(FFeatherKeyCombination NewKeyCombo)
    {
        KeyCombo = NewKeyCombo;
        UpdateToolTip();
        OnKeyBound.Broadcast(this, KeyCombo);
    }

    void UpdateToolTip()
    {
        if(KeyCombo.MainKey.IsValid())
        {
            FString HotKeyString;
            for(FKey HeldKey : KeyCombo.HeldKeys)
            {
                HotKeyString += HeldKey.ToString() + "+";
            }
            HotKeyString += KeyCombo.MainKey.ToString();

            KeybindButton.SetToolTipText(FText::FromString("Click to rebind. Current hotkey is: " + HotKeyString));
        }
        else
        {
            KeybindButton.SetToolTipText(FText::FromString("Click this button to record a hotkey combination for this operation!"));
        }
    }
};
