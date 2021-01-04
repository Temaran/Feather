// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceWindow;
import Feather.DebugInterface.FeatherDebugInterfaceSorting;
import Feather.UtilWidgets.FeatherSearchBox;
import Feather.FeatherSorting;
import Feather.FeatherUtils;

struct FDebugInterfaceMainWindowSaveState
{
	FString SearchText;
};

UCLASS(Abstract)
class UFeatherDebugInterfaceMainWindow : UFeatherDebugInterfaceWindow
{
	default WindowName = n"MainWindow";

	UPROPERTY(Category = "Feather", NotEditable)
	TArray<UFeatherDebugInterfaceOperation> Operations;

	UPROPERTY(Category = "Feather", NotEditable)
	TArray<UFeatherDebugInterfaceWindow> ToolWindows;

	UPROPERTY(Category = "Feather", EditDefaultsOnly)
	TArray<TSubclassOf<UFeatherDebugInterfaceOperation>> IgnoredOperationTypes;

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


	UFUNCTION(BlueprintOverride)
	void FeatherConstruct()
	{
		Super::FeatherConstruct();

		// Now automatically add AS-defined debug ops to their chosen paths
		TArray<UClass> AllDebugOperationTypes = UClass::GetAllSubclassesOf(UFeatherDebugInterfaceOperation::StaticClass());
		for(UClass IgnoredType : IgnoredOperationTypes)
		{
			AllDebugOperationTypes.Remove(IgnoredType);
		}

		UFeatherSearchBox MySearchBox = GetSearchBox();
		MySearchBox.Style = Style;
		MySearchBox.OnSearchChanged.AddUFunction(this, n"SearchChanged");
		MySearchBox.ConstructFeatherWidget();

		for(UClass DebugOpType : AllDebugOperationTypes)
		{
			UFeatherDebugInterfaceOperation OperationCDO = Cast<UFeatherDebugInterfaceOperation>(DebugOpType.GetDefaultObject());
			if(!OperationCDO.Static_IsOperationSupported())
			{
				continue;
			}

			// Create the auto widget
			UFeatherDebugInterfaceOperation OperationWidget = Cast<UFeatherDebugInterfaceOperation>(CreateStyledWidget(TSubclassOf<UFeatherWidget>(OperationCDO.Class)));
			if(!System::IsValid(OperationWidget))
			{
				Warning("Feather: Debug operation '" + OperationCDO.GetName() + "' could not be created!");
				continue;
			}

			OperationWidget.Style = Style;
			OperationWidget.ConstructFeatherWidget();
			Operations.Add(OperationWidget);

			// Add all search terms
			MySearchBox.SearchTargetTokens.Add(GetSanitizedOperationName(OperationCDO));
			for(FName OperationTag : OperationCDO.OperationTags)
			{
				MySearchBox.SearchTargetTokens.Add(OperationTag.ToString());
			}
		}

		SetupWindowManager();

		RegenerateSearch(TArray<FString>());
	}

	void SetupWindowManager()
	{
		UVerticalBox WindowManagerBox = GetWindowManagerPanel();
		WindowManagerBox.ClearChildren();

		for(UFeatherDebugInterfaceWindow Window : ToolWindows)
		{
			Window.SetVisibility(ESlateVisibility::Collapsed);

			UFeatherButtonStyle WindowButton = CreateButton();
			UFeatherTextBlockStyle WindowText = CreateTextBlock();
			WindowText.GetTextWidget().SetText(FText::FromString(Window.WindowName.ToString()));
			WindowButton.GetButtonWidget().SetContent(WindowText);
			WindowButton.OnClickedWithContext.AddUFunction(this, n"WindowButtonClicked");
			WindowManagerBox.AddChildToVerticalBox(WindowButton);
		}
	}

	UFUNCTION()
	void WindowButtonClicked(UFeatherButtonStyle ClickedButton)
	{
		FText ClickedWindowName = Cast<UFeatherTextBlockStyle>(ClickedButton.GetButtonWidget().GetContent()).GetTextWidget().GetText();

		for(UFeatherDebugInterfaceWindow Window : ToolWindows)
		{
			if(Window.WindowName == FName(ClickedWindowName.ToString()))
			{
				Window.SetVisibility(ESlateVisibility::Visible);
				break;
			}
		}

		GetWindowManager().SetIsExpanded(false);
	}

	UFUNCTION()
	void SearchChanged(UFeatherSearchBox SearchBox, const TArray<FString>& SearchTokens, bool bSearchWasFinalized)
	{
		if(bOnlyRegenerateSearchOnCommit == bSearchWasFinalized)
		{
			RegenerateSearch(SearchTokens);
		}

		SaveSettings();
	}

	void RegenerateSearch(const TArray<FString>& SearchTokens)
	{
		UVerticalBox SearchResults = GetResultsPanel();
		SearchResults.ClearChildren();

		// Figure out which operations should be displayed
		TArray<FOperationWithScore> CandidateOperations;
		for(auto Op : Operations)
		{
			float RankingScoreUNorm = ScoreOperation(Op, SearchTokens);
			if(RankingScoreUNorm > 0.0f)
			{
				FOperationWithScore NewOpAndScore;
				NewOpAndScore.Operation = Op;
				NewOpAndScore.RankingScoreUNorm = RankingScoreUNorm;
				CandidateOperations.Add(NewOpAndScore);
			}
		}
		FeatherSorting::QuickSortOperations(CandidateOperations, 0, CandidateOperations.Num() - 1);

		bool bUseAlternateBackgroundForEntry = false;
		for(auto Candidate : CandidateOperations)
		{
			if(bUseAlternateBackgroundForEntry)
			{
				UOverlay AlternateOverlay = Cast<UOverlay>(ConstructWidget(UOverlay::StaticClass()));

				UImage BackgroundImage = Cast<UImage>(ConstructWidget(UImage::StaticClass()));
				BackgroundImage.SetColorAndOpacity(AlternatingOperationColor);
				UOverlaySlot ImageSlot = AlternateOverlay.AddChildToOverlay(BackgroundImage);
				ImageSlot.SetHorizontalAlignment(EHorizontalAlignment::HAlign_Fill);
				ImageSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Fill);

				UOverlaySlot OpSlot = AlternateOverlay.AddChildToOverlay(Candidate.Operation);
				OpSlot.SetHorizontalAlignment(EHorizontalAlignment::HAlign_Fill);
				OpSlot.SetVerticalAlignment(EVerticalAlignment::VAlign_Center);

				UVerticalBoxSlot OverlaySlot = SearchResults.AddChildToVerticalBox(AlternateOverlay);
				FSlateChildSize FillSize;
				FillSize.SizeRule = ESlateSizeRule::Fill;
				OverlaySlot.SetSize(FillSize);
			}
			else
			{
				SearchResults.AddChildToVerticalBox(Candidate.Operation);
			}

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

			for(FString OperationTag : Operation.OperationTags)
			{
				CumulativeScore += FeatherUtils::CalculateTokenMatchScore(OperationTag, Token);
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

		FString Output = Operation.Class.GetName().ToString().TrimStartAndEnd();
		for(FString IgnoredSubstring : IgnoredTokenSubstrings)
		{
			Output = Output.Replace(IgnoredSubstring, "");
		}

		return Output;
	}

///////////////////////////////////////////////////////////////////////

	UFUNCTION(BlueprintOverride)
	void SaveSettings()
	{
		Super::SaveSettings();
		
		for(auto Op : Operations)
		{
			Op.SaveSettings();
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
	}

	UFUNCTION(BlueprintOverride)
	void SaveToString(FString& InOutSaveString)
	{
		Super::SaveToString(InOutSaveString);

		FDebugInterfaceMainWindowSaveState SaveState;
		SaveState.SearchText = GetSearchBox().GetSearchText().ToString();
		FJsonObjectConverter::AppendUStructToJsonObjectString(SaveState, InOutSaveString);
	}

	UFUNCTION(BlueprintOverride)
	void LoadFromString(const FString& InSaveString)
	{
		Super::LoadFromString(InSaveString);

		FDebugInterfaceMainWindowSaveState SaveState;
		if(FJsonObjectConverter::JsonObjectStringToUStruct(InSaveString, SaveState))
		{
			GetSearchBox().SetSearchText(FText::FromString(SaveState.SearchText));
		}
	}

	UFUNCTION(BlueprintOverride)
	void ResetSettingsToDefault()
	{
		Super::ResetSettingsToDefault();

		for(auto Op : Operations)
		{
			Op.ResetSettingsToDefault();
		}
	}

///////////////////////////////////////////////////////////////////////

	UFUNCTION(Category = "Feather", BlueprintEvent)
	UVerticalBox GetResultsPanel()
	{
		return nullptr;
	}

	UFUNCTION(Category = "Feather", BlueprintEvent)
	UExpandableArea GetWindowManager()
	{
		return nullptr;
	}

	UFUNCTION(Category = "Feather", BlueprintEvent)
	UVerticalBox GetWindowManagerPanel()
	{
		return nullptr;
	}

	UFUNCTION(Category = "Feather", BlueprintEvent)
	UFeatherSearchBox GetSearchBox()
	{
		return nullptr;
	}
};
