// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceWindow;
import Feather.DebugInterface.FeatherDebugInterfaceUtils;
import Feather.DebugInterface.FeatherWindowSelectionBox;
import Feather.DebugInterface.ToolWindows.FeatherDebugInterfaceOptionsWindow;
import Feather.UtilWidgets.FeatherSearchBox;
import Feather.FeatherSorting;
import Feather.FeatherUtils;

event void FMainWindowClosedEvent();

UCLASS(Abstract)
class UFeatherDebugInterfaceMainWindow : UFeatherDebugInterfaceWindow
{
	default WindowName = n"Debug Interface";

	UPROPERTY(Category = "Feather")
	FMainWindowClosedEvent OnMainWindowClosed;

	UPROPERTY(Category = "Feather", NotEditable)
	TArray<UFeatherDebugInterfaceOperation> Operations;

	UPROPERTY(Category = "Feather", NotEditable)
	TArray<UFeatherDebugInterfaceWindow> ToolWindows;

	UPROPERTY(Category = "Feather", EditDefaultsOnly)
	TArray<TSubclassOf<UFeatherDebugInterfaceOperation>> IgnoredOperationTypes;

	// We run a custom input system in the main window to react to our custom hotkeys. This is the frequency of which this system is updated.
	UPROPERTY(Category = "Feather", EditDefaultsOnly)
	float InputPollFrequencyHz = 30.0f;

	// To make it easier to see the different ops, we can alternate the background. This is the alternate color
	UPROPERTY(Category = "Feather", EditDefaultsOnly)
	bool bAlternateOperationBackgroundColor = true;

	UPROPERTY(Category = "Feather", EditDefaultsOnly)
	bool bOnlyRegenerateSearchOnCommit = false;

	UPROPERTY(Category = "Feather", EditDefaultsOnly)
	TArray<FString> IgnoredTokenSubstrings;
	default IgnoredTokenSubstrings.Add("feather");
	default IgnoredTokenSubstrings.Add("operation");

	UPROPERTY(Category = "Feather", EditDefaultsOnly, meta = (EditCondition = bAlternateOperationBackgroundColor))
	FLinearColor AlternatingOperationColor;
	default AlternatingOperationColor.R = 0.08f;
	default AlternatingOperationColor.G = 0.08f;
	default AlternatingOperationColor.B = 0.08f;

	FString FavouritesQuickEntry = "Favourites";
	TArray<FString> SpecialQuickEntries;
	TMap<UFeatherDebugInterfaceOperation, bool> KeybindOpsToMainButtonStates;
	default SpecialQuickEntries.Add(FavouritesQuickEntry);

	UFUNCTION(BlueprintOverride)
	void FeatherConstruct(FFeatherStyle InStyle, FFeatherConfig InConfig)
	{
		Super::FeatherConstruct(InStyle, InConfig);

		SetupSearchBox();
		SetupWindowManager();
		SetupToolWindows();
		RegenerateSearch(TArray<FString>());

		const float UpdateFreqToUse = (InputPollFrequencyHz < SMALL_NUMBER) ? 30.0f : InputPollFrequencyHz;
		const float UpdateTime = 1.0f / UpdateFreqToUse;
		System::SetTimer(this, n"PollInput", UpdateTime, true);
	}

	UFUNCTION()
	void HotkeyBoundToOperation(UFeatherDebugInterfaceOperation Operation, FFeatherHotkey Hotkey)
	{
		// We are conservative here in that we will never remove operations from the poll list during runtime.
		if(Hotkey.MainKey.IsValid() && System::IsValid(Operation))
		{
			KeybindOpsToMainButtonStates.Add(Operation, false);
		}
	}

	UFUNCTION()
	void PollInput()
	{
		if(!System::IsValid(OwningPlayer))
		{
			return;
		}

		const float PollTime = System::GetGameTimeInSeconds();
		const float PostRecordIgnoreTimeSecs = 0.5;

		TMap<UFeatherDebugInterfaceOperation, bool> NewKeybindOpsToMainButtonStates;
		for(auto OperationPair : KeybindOpsToMainButtonStates)
		{
			UFeatherDebugInterfaceOperation Operation = OperationPair.Key;
			if(!System::IsValid(Operation.HotkeyCaptureButton)
				|| !Operation.HotkeyCaptureButton.Hotkey.MainKey.IsValid())
			{
				continue;
			}

			FFeatherHotkey& OpHotKey = Operation.HotkeyCaptureButton.Hotkey;

			bool bPrevMainKeyState = OperationPair.Value;
			bool bCurrentMainKeyState = OwningPlayer.IsInputKeyDown(OpHotKey.MainKey);
			NewKeybindOpsToMainButtonStates.Add(Operation, bCurrentMainKeyState);

			if(!bPrevMainKeyState && bCurrentMainKeyState)
			{
				// Was just pressed, check the held keys

				const float TimeSinceRecording = PollTime - Operation.HotkeyCaptureButton.RecordedTimestamp;
				if(TimeSinceRecording > PostRecordIgnoreTimeSecs)
				{
					bool bAllHeldKeysArePressed = true;
					for(FKey HeldKey : OpHotKey.HeldKeys)
					{
						if(!OwningPlayer.IsInputKeyDown(HeldKey))
						{
							bAllHeldKeysArePressed = false;
							break;
						}
					}

					if(bAllHeldKeysArePressed)
					{
						// All conditions were met!
						Operation.Execute();
					}
				}
			}
		}

		// Update Keystates
		for(auto OperationPair : NewKeybindOpsToMainButtonStates)
		{
			if(KeybindOpsToMainButtonStates.Contains(OperationPair.Key))
			{
				KeybindOpsToMainButtonStates[OperationPair.Key] = OperationPair.Value;
			}
		}
	}

	void SetupSearchBox()
	{
		UVerticalBox SearchResults = GetResultsPanel();
		UFeatherSearchBox MySearchBox = GetSearchBox();
		MySearchBox.OnSearchChanged.AddUFunction(this, n"SearchChanged");

		// Now automatically add AS-defined debug ops to their chosen paths
		TArray<UClass> AllDebugOperationTypes = UClass::GetAllSubclassesOf(UFeatherDebugInterfaceOperation::StaticClass());
		for(UClass IgnoredType : IgnoredOperationTypes)
		{
			AllDebugOperationTypes.Remove(IgnoredType);
		}
		for(UClass DebugOpType : AllDebugOperationTypes)
		{
			if(DebugOpType.GetName().ToString().StartsWith("SKEL_"))
			{
				// Don't include BP Skeletal classes
				continue;
			}

			// Create the auto widget
			UFeatherDebugInterfaceOperation OperationCDO = Cast<UFeatherDebugInterfaceOperation>(DebugOpType.GetDefaultObject());
			UFeatherDebugInterfaceOperation OperationWidget = Cast<UFeatherDebugInterfaceOperation>(CreateFeatherWidget(TSubclassOf<UFeatherWidget>(OperationCDO.Class)));
			if(!System::IsValid(OperationWidget))
			{
				Warning("Feather: Debug operation '" + OperationCDO.GetName() + "' could not be created!");
				continue;
			}
			OperationWidget.FeatherConstruct(FeatherStyle, FeatherConfiguration);
			OperationWidget.OnHotkeyBound.AddUFunction(this, n"HotkeyBoundToOperation");
			Operations.Add(OperationWidget);

			if(!OperationCDO.Static_IsOperationSupported(OwningPlayer))
			{
				// Disable the widget if not in standalone and set tooltip
				OperationWidget.SetIsEnabled(false);
				SetAllChildrenToolTipsToStandaloneOnly(OperationWidget);
			}

			// Add all search terms
			MySearchBox.AllSearchTargetTokens.Add(GetSanitizedOperationName(OperationCDO));
			for(FName OperationTag : OperationCDO.OperationTags)
			{
				const FString TagToken = OperationTag.ToString();
				ensure(!SpecialQuickEntries.Contains(TagToken), "Illegal operation tag found! You cannot special quick entries as tags! Offending operation: " + OperationCDO.GetName().ToString() + " Offending tag: " + TagToken);
				MySearchBox.AllSearchTargetTokens.Add(TagToken);
				MySearchBox.QuickSelectTokens.Add(TagToken);
			}

			UVerticalBoxSlot OperationSlot = SearchResults.AddChildToVerticalBox(OperationWidget);
			FSlateChildSize FillSize;
			FillSize.SizeRule = ESlateSizeRule::Automatic;
			OperationSlot.SetSize(FillSize);
		}

		for(FString SpecialEntry : SpecialQuickEntries)
		{
			MySearchBox.AllSearchTargetTokens.Add(SpecialEntry);
			MySearchBox.SpecialQuickSelectTokens.Add(SpecialEntry);
		}
		MySearchBox.FeatherConstruct(FeatherStyle, FeatherConfiguration);
	}

	void SetupWindowManager()
	{
		UFeatherWindowSelectionBox MyWindowManager = GetWindowManager();
		MyWindowManager.ToolWindows = ToolWindows;
		MyWindowManager.FeatherConstruct(FeatherStyle, FeatherConfiguration);
	}

	void SetupToolWindows()
	{
		for(UFeatherDebugInterfaceWindow ToolWindow : ToolWindows)
		{
			UFeatherDebugInterfaceOptionsWindow OptionsWindow = Cast<UFeatherDebugInterfaceOptionsWindow>(ToolWindow);
			if(System::IsValid(OptionsWindow))
			{
				OptionsWindow.SetSearchBox(GetSearchBox());
			}
		}
	}

	void SetAllChildrenToolTipsToStandaloneOnly(UWidget CurrentWidget)
	{
		CurrentWidget.SetToolTipText(FText::FromString("This operation only works in Standalone!"));
		UPanelWidget MaybePanel = Cast<UPanelWidget>(CurrentWidget);
		if(System::IsValid(MaybePanel))
		{
			for(int ChildIdx = 0; ChildIdx < MaybePanel.ChildrenCount; ChildIdx++)
			{
				SetAllChildrenToolTipsToStandaloneOnly(MaybePanel.GetChildAt(ChildIdx));
			}
		}

		UUserWidget MaybeUserWidget = Cast<UUserWidget>(CurrentWidget);
		if(System::IsValid(MaybeUserWidget))
		{
			SetAllChildrenToolTipsToStandaloneOnly(MaybeUserWidget.RootWidget);
		}
	}

	UFUNCTION()
	void SearchChanged(UFeatherSearchBox SearchBox, const TArray<FString>& SearchTokens, bool bSearchWasFinalized)
	{
		if(bOnlyRegenerateSearchOnCommit == bSearchWasFinalized)
		{
			RegenerateSearch(SearchTokens);
		}
	}

	void RegenerateSearch(const TArray<FString>& SearchTokens)
	{
		// Test and purge Special Tokens
		TArray<FString> ActualTokens = SearchTokens;
		bool bFilterToFavourites = ActualTokens.Contains(FavouritesQuickEntry);
		for(FString SpecialEntry : SpecialQuickEntries)
		{
			ActualTokens.Remove(SpecialEntry);
		}

		// Figure out which operations should be displayed
		TArray<FOperationWithScore> CandidateOperations;
		for(auto Op : Operations)
		{
			// Default to collapsed, we then make them visible if they are selected
			Op.SetVisibility(ESlateVisibility::Collapsed);

			if(bFilterToFavourites && !Op.FavouriteButton.GetCheckBoxWidget().IsChecked())
			{
				// If we only allow favourites and the op is not favourited, skip.
				continue;
			}

			float RankingScoreUNorm = ScoreOperation(Op, ActualTokens);
			if(RankingScoreUNorm > 0.0f)
			{
				FOperationWithScore NewOpAndScore;
				NewOpAndScore.Operation = Op;
				NewOpAndScore.RankingScoreUNorm = RankingScoreUNorm;
				CandidateOperations.Add(NewOpAndScore);
			}
		}
		//FeatherSorting::QuickSortOperations(CandidateOperations, 0, CandidateOperations.Num() - 1);

		bool bUseAlternateBackgroundForEntry = false;
		for(auto Candidate : CandidateOperations)
		{
			Candidate.Operation.SetVisibility(ESlateVisibility::Visible);
			Candidate.Operation.SetBackgroundColor(bUseAlternateBackgroundForEntry
				? AlternatingOperationColor : FLinearColor::Transparent);

			if(bAlternateOperationBackgroundColor)
			{
				bUseAlternateBackgroundForEntry = !bUseAlternateBackgroundForEntry;
			}
		}
	}

	float ScoreOperation(UFeatherDebugInterfaceOperation Operation, const TArray<FString>& SearchTokens)
	{
		if(SearchTokens.Num() <= 0)
		{
			// If there are no search terms, just return everything.
			return 1.0f;
		}

		FString OperationName = GetSanitizedOperationName(Operation);

		float CumulativeScore = 0.0f;
		for(FString Token : SearchTokens)
		{
			float NameMatchScore = FeatherUtils::CalculateTokenMatchScore(OperationName, Token);
			if(NameMatchScore > 0.99f)
			{
				// Direct hit on name. Always place at the top.
				return 1.0f;
			}

			CumulativeScore += NameMatchScore;

			for(FName OperationTag : Operation.OperationTags)
			{
				CumulativeScore += FeatherUtils::CalculateTokenMatchScore(OperationTag.ToString(), Token);
			}
		}

		return CumulativeScore / float(SearchTokens.Num() + 1); // Add one for name
	}

	FString GetSanitizedOperationName(UFeatherDebugInterfaceOperation Operation)
	{
		if(!ensure(System::IsValid(Operation), "Tried to get name for invalid op!"))
		{
			return "";
		}

		FString OriginalName = Operation.Class.GetName().ToString().TrimStartAndEnd();
		FString Output = OriginalName;
		for(FString IgnoredSubstring : IgnoredTokenSubstrings)
		{
			Output = Output.Replace(IgnoredSubstring, "");
		}

		ensure(!SpecialQuickEntries.Contains(Output), "Illegal operation name found! You cannot name operations similarly to special quick entries! Offending operation: " + OriginalName);

		return Output;
	}

///////////////////////////////////////////////////////////////////////

	UFUNCTION(BlueprintOverride, meta = (NoSuperCall))
	void CloseWindow()
	{
		OnMainWindowClosed.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void SaveSettings()
	{
		Super::SaveSettings();

		if(bIsPossibleToSave)
		{
			for(auto Op : Operations)
			{
				Op.SaveSettings();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void LoadSettings()
	{
		Super::LoadSettings();

		for(auto Op : Operations)
		{
			Op.LoadSettings();
		}

		GetSearchBox().LoadSettings();
	}

	UFUNCTION(BlueprintOverride, meta = (NoSuperCall))
	void Reset()
	{
		// Don't call super
		SetWindowSize(MinimumWindowSize);
		SetWindowTransparency(1.0f);
		SetVisibility(ESlateVisibility::Visible);

		for(auto Op : Operations)
		{
			Op.ResetSettingsToDefault();
		}

		GetSearchBox().ResetSettingsToDefault();
	}

///////////////////////////////////////////////////////////////////////

	UFUNCTION(Category = "Feather", BlueprintEvent)
	UVerticalBox GetResultsPanel()
	{
		return nullptr;
	}

	UFUNCTION(Category = "Feather", BlueprintEvent)
	UFeatherWindowSelectionBox GetWindowManager()
	{
		return nullptr;
	}

	UFUNCTION(Category = "Feather", BlueprintEvent)
	UFeatherSearchBox GetSearchBox()
	{
		return nullptr;
	}
};
