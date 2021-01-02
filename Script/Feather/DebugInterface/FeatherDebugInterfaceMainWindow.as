// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceWindow;
import Feather.DebugInterface.FeatherDebugInterfaceUtils;

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

	UPROPERTY(Category = "Feather", EditDefaultsOnly, meta = (EditCondition = bAlternateOperationBackgroundColor))
	FLinearColor AlternatingOperationColor;
	default AlternatingOperationColor.R = 0.08f;
	default AlternatingOperationColor.G = 0.08f;
	default AlternatingOperationColor.B = 0.08f;

	UPROPERTY(Category = "Feather|Search", EditDefaultsOnly)
	bool bOnlyRegenerateSearchOnCommit = false;
	UPROPERTY(Category = "Feather|Search", EditDefaultsOnly)
	bool bGenerateSearchSuggestions = true;
	UPROPERTY(Category = "Feather|Search", EditDefaultsOnly)
	int MaxSearchSuggestions = 3;
	UPROPERTY(Category = "Feather|Search", EditDefaultsOnly)
	float MaxScoreFromMatch = 0.8f;
	UPROPERTY(Category = "Feather|Search", EditDefaultsOnly)
	float MaxScoreFromPosition = 1.0f - MaxScoreFromMatch;
	UPROPERTY(Category = "Feather|Search", EditDefaultsOnly)
	TArray<FString> IgnoredTokenSubstrings;
	default IgnoredTokenSubstrings.Add("feather");
	default IgnoredTokenSubstrings.Add("operation");

	// TODO: This could probably be done a lot better with nested lookup maps or something. Might not be necessary for a long time though.
	TSet<FString> SearchTargetTokens;

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
			OperationWidget.FeatherConstruct();
			Operations.Add(OperationWidget);

			// Add all search terms
			SearchTargetTokens.Add(GetSanitizedOperationName(OperationCDO));
			for(FName OperationTag : OperationCDO.OperationTags)
			{
				SearchTargetTokens.Add(OperationTag.ToString());
			}
		}

		SetupWindowManager();

		GetSearchTextBox().OnTextChanged.AddUFunction(this, n"SearchChanged");
		GetSearchTextBox().OnTextCommitted.AddUFunction(this, n"FinalizeSearch");

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
	void SearchChanged(FText& SearchText)
	{
		TArray<FString> SearchTokens;
		ParseSearchTokens(SearchText.ToString(), SearchTokens);

		ESlateVisibility SuggestionVisibility = RegenerateSearchSuggestions(SearchTokens)
			? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		GetSearchSuggestionsPanel().SetVisibility(SuggestionVisibility);

		if(!bOnlyRegenerateSearchOnCommit)
		{
			RegenerateSearch(SearchTokens);
		}
	}

	UFUNCTION()
	void FinalizeSearch(FText& SearchText, ETextCommit CommitMethod)
	{
		if(CommitMethod == ETextCommit::OnEnter)
		{
			GetSearchSuggestionsPanel().SetVisibility(ESlateVisibility::Collapsed);
		}

		if(bOnlyRegenerateSearchOnCommit)
		{
			TArray<FString> SearchTokens;
			ParseSearchTokens(SearchText.ToString(), SearchTokens);

			RegenerateSearch(SearchTokens);
		}
	}

	void ParseSearchTokens(FString SearchText, TArray<FString>& OutSearchTokens)
	{
		OutSearchTokens.Empty();

		FString Corpus = SearchText;
		FString LeftChop;
		FString RightChop;
		while(Corpus.Split(",", LeftChop, RightChop)
		   || Corpus.Split(" ", LeftChop, RightChop))
		{
			OutSearchTokens.Add(LeftChop.TrimStartAndEnd());
			Corpus = RightChop;
		}

		if(!Corpus.IsEmpty())
		{
			OutSearchTokens.Add(Corpus);
		}
	}

	bool RegenerateSearchSuggestions(const TArray<FString>& SearchTokens)
	{
		UVerticalBox SearchSuggestions = GetSearchSuggestionsPanel();
		SearchSuggestions.ClearChildren();

		if(SearchTokens.Num() <= 0 || !bGenerateSearchSuggestions)
		{
			return false;
		}

		// Only ever try to complete the last token.
		FString CurrentSearchToken = SearchTokens[SearchTokens.Num() - 1];
		TArray<FSearchSuggestionWithScore> ValidSuggestionsWithScores;
		for(FString TargetToken : SearchTargetTokens)
		{
			float MatchScore = CalculateTokenMatchScore(TargetToken, CurrentSearchToken);
			if(MatchScore == 1.0f)
			{
				// This token is already complete! Nothing to do here.
				return false;
			}
			else if(MatchScore > 0.0f)
			{
				FSearchSuggestionWithScore NewSuggestionWithScore;
				NewSuggestionWithScore.SearchSuggestion = FName(TargetToken);
				NewSuggestionWithScore.RankingScoreUNorm = MatchScore;
				ValidSuggestionsWithScores.Add(NewSuggestionWithScore);
			}
		}
		FeatherSorting::QuickSortSuggestions(ValidSuggestionsWithScores, 0, ValidSuggestionsWithScores.Num() - 1);

		int NumberOfSuggestions = FMath::Min(MaxSearchSuggestions, ValidSuggestionsWithScores.Num());
		if(NumberOfSuggestions == 0)
		{
			GetSearchSuggestionsPanel().SetVisibility(ESlateVisibility::Collapsed);
		}
		else
		{
			for(int i = 0; i < NumberOfSuggestions; i++)
			{
				FSearchSuggestionWithScore Suggestion = ValidSuggestionsWithScores[i];

				UFeatherButtonStyle SuggestionButton = CreateButton();
				UFeatherTextBlockStyle SuggestionText = CreateTextBlock();
				SuggestionText.GetTextWidget().SetText(FText::FromString(Suggestion.SearchSuggestion.ToString()));
				SuggestionButton.GetButtonWidget().SetContent(SuggestionText);
				SuggestionButton.OnClickedWithContext.AddUFunction(this, n"SuggestionClicked");
				SearchSuggestions.AddChildToVerticalBox(SuggestionButton);
			}
		}

		return true;
	}

	UFUNCTION()
	void SuggestionClicked(UFeatherButtonStyle ClickedButton)
	{
		GetSearchSuggestionsPanel().SetVisibility(ESlateVisibility::Collapsed);

		UFeatherTextBlockStyle SuggestionText = Cast<UFeatherTextBlockStyle>(ClickedButton.GetButtonWidget().GetContent());
		if(System::IsValid(SuggestionText))
		{
			FString SuggestionToUse = SuggestionText.GetTextWidget().GetText().ToString();
			FString CurrentSearchString = GetSearchTextBox().GetText().ToString();

			// Remove the final term.
			FString LeftChop;
			FString RightChop;
			if(CurrentSearchString.Split(",", LeftChop, RightChop)
				|| CurrentSearchString.Split(" ", LeftChop, RightChop))
			{
				CurrentSearchString = LeftChop;
			}
			else
			{
				CurrentSearchString = "";
			}

			FString NewSearchString = CurrentSearchString + " " + SuggestionToUse;
			GetSearchTextBox().SetText(FText::FromString(NewSearchString));
		}
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

		if(SearchResults.ChildrenCount > 0)
		{
			// No top padding allowed for first op!
			UFeatherDebugInterfaceOperation FirstOp = Cast<UFeatherDebugInterfaceOperation>(SearchResults.GetChildAt(0));
			if(System::IsValid(FirstOp))
			{
				FMargin NewPadding = FirstOp.GetPadding();
				NewPadding.Top = 0.0f;
				FirstOp.SetPadding(NewPadding);
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
			float NameMatchScore = CalculateTokenMatchScore(OperationName, Token);
			if(NameMatchScore > 0.99f)
			{
				// Direct hit on name. Always place at the top.
				return 1.0f;
			}

			CumulativeScore += NameMatchScore;

			for(FString OperationTag : Operation.OperationTags)
			{
				CumulativeScore += CalculateTokenMatchScore(OperationTag, Token);
			}
		}

		return CumulativeScore / float(SearchTokens.Num() + 1); // Add one for name
	}

	float CalculateTokenMatchScore(FString TargetToken, FString InputToTest)
	{
		int SubStringIndex = TargetToken.Find(InputToTest);
		if(SubStringIndex >= 0)
		{
			float MatchDegreeScore = float(InputToTest.Len()) / float(TargetToken.Len()) * MaxScoreFromMatch;
			float PositionScore = (1.0f - (float(SubStringIndex) / float(TargetToken.Len()))) * MaxScoreFromPosition;
			return FMath::Clamp(MatchDegreeScore + PositionScore, 0.0f, 1.0f);
		}

		// Token doesn't even contain input
		return 0.0f;
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
	bool SaveSettings()
	{
		for(auto Op : Operations)
		{
			Op.SaveSettings();
		}

		return Super::SaveSettings();
	}

	UFUNCTION(BlueprintOverride)
	bool LoadSettings()
	{
		for(auto Op : Operations)
		{
			if(!Op.LoadSettings())
			{
				Op.ResetSettingsToDefault();
			}
		}

		return Super::LoadSettings();
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
	UVerticalBox GetSearchSuggestionsPanel()
	{
		return nullptr;
	}

	UFUNCTION(Category = "Feather", BlueprintEvent)
	UEditableTextBox GetSearchTextBox()
	{
		return nullptr;
	}
};
