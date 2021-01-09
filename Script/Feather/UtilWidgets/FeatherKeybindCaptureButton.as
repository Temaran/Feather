// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherWidget;

struct FFeatherHotkey
{
    FKey MainKey;
    TArray<FKey> HeldKeys;

    FFeatherHotkey()
    {
        MainKey = FKey();
        HeldKeys.Empty();
    }
};

event void FHotkeyBoundSignature(UFeatherHotkeyCaptureButton CaptureButton, FFeatherHotkey Hotkey);

class UFeatherHotkeyCaptureButton : UFeatherWidget
{
    // This is called when a key combo is successfully bound
    UPROPERTY(Category = "Keybind Capture")
    FHotkeyBoundSignature OnHotkeyBound;
    
    UPROPERTY(Category = "Keybind Capture")
    UFeatherCheckBoxStyle KeybindButton;

    UPROPERTY(Category = "Keybind Capture")
    FFeatherHotkey Hotkey;

    float RecordedTimestamp = 0.0f;
    bool bIsRecording = false;

    UFUNCTION(BlueprintOverride)
	void FeatherConstruct(FFeatherStyle InStyle, FFeatherConfig InConfig)
    {
		Super::FeatherConstruct(InStyle, InConfig);

        KeybindButton = CreateCheckBox(n"HotkeyCaptureCheckBox");
        KeybindButton.GetCheckBoxWidget().OnCheckStateChanged.AddUFunction(this, n"KeybindButtonClicked");
        SetRootWidget(KeybindButton);

        UpdateToolTip();
    }

    UFUNCTION()
    void KeybindButtonClicked(bool bCurrentKeybindState)
    {
        if(bCurrentKeybindState)
        {
            Hotkey.MainKey = FKey();
            Hotkey.HeldKeys.Empty();
            bIsRecording = true;
            UpdateToolTip();
        }
        else
        {
            if(bIsRecording)
            {
                // Reset hotkey
                Hotkey.MainKey = FKey();
                Hotkey.HeldKeys.Empty();
                OnHotkeyBound.Broadcast(this, Hotkey);
                bIsRecording = false;
                UpdateToolTip();
            }
            else
            {
                bIsRecording = false;
            }
        }
    }

    UFUNCTION(BlueprintOverride)
    FEventReply OnKeyDown(FGeometry MyGeometry, FKeyEvent InKeyEvent)
    {
        if(bIsRecording 
            && InKeyEvent.Key != EKeys::LeftMouseButton
            && InKeyEvent.Key != EKeys::RightMouseButton)
        {
            Hotkey.HeldKeys.Add(InKeyEvent.Key);
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
            Hotkey.MainKey = InKeyEvent.Key;
            Hotkey.HeldKeys.Remove(InKeyEvent.Key);
            RecordedTimestamp = System::GetGameTimeInSeconds();
            
            // Turn off recording before setting the checked state, otherwise the key could be cleared.
            bIsRecording = false;
            KeybindButton.SetIsChecked(false);
            
            UpdateToolTip();
            OnHotkeyBound.Broadcast(this, Hotkey);
        }
        
        return FEventReply::Unhandled();
    }

    void SetNewHotkey(FFeatherHotkey NewHotkey)
    {
        Hotkey = NewHotkey;
        UpdateToolTip();
        OnHotkeyBound.Broadcast(this, Hotkey);
    }

    void UpdateToolTip()
    {
        if(bIsRecording)
        {            
            KeybindButton.SetToolTipText(FText::FromString("Input a key combination to record it! Click the button again to reset the hotkey."));
        }
        else if(Hotkey.MainKey.IsValid())
        {
            FString HotkeyString;
            for(FKey HeldKey : Hotkey.HeldKeys)
            {
                HotkeyString += HeldKey.ToString() + "+";
            }
            HotkeyString += Hotkey.MainKey.ToString();

            KeybindButton.SetToolTipText(FText::FromString("Click to rebind. Double click to reset. Current hotkey is: " + HotkeyString));
        }
        else
        {
            KeybindButton.SetToolTipText(FText::FromString("Click this button to record a hotkey combination for this operation!"));
        }
    }
};
