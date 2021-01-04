// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherWidget;
import Feather.FeatherSorting;
import Feather.FeatherUtils;

event void FSearchChangedEvent(UFeatherSearchBox SearchBox, const TArray<FString>& SearchTokens, bool bSearchWasFinalized);

class UFeatherSearchBox : UFeatherWidget
{
    UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
    FSearchChangedEvent OnSearchChanged;

    UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
    TSet<FString> AllSearchTargetTokens;

    UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
    TSet<FString> QuickSelectTokens;

    UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
    bool bGenerateSearchSuggestions = true;

	UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
	int MaxSearchSuggestions = 3;

	UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
	float MaxScoreFromMatch = 0.8f;

	UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
	float MaxScoreFromPosition = 1.0f - MaxScoreFromMatch;

	UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
	float SearchButtonFoldoutSize = 170.0f;

	TArray<FString> SortedQuickSelectTokens;

    UFUNCTION(BlueprintOverride)
    void FeatherConstruct()
    {
		Super::FeatherConstruct();
		
		GetSearchButton().OnCheckStateChanged.AddUFunction(this, n"SearchButtonStateChanged");
		GetSearchTextBox().OnTextChanged.AddUFunction(this, n"SearchChanged");
		GetSearchTextBox().OnTextCommitted.AddUFunction(this, n"FinalizeSearch");

		for(FString Token : QuickSelectTokens)
		{
			SortedQuickSelectTokens.Add(Token);
		}
		SortedQuickSelectTokens.Sort();

		GetSearchSuggestions().SetVisibility(ESlateVisibility::Collapsed);
    }

	UFUNCTION()
	void SearchChanged(FText& SearchText)
	{
		TArray<FString> SearchTokens;
		ParseSearchTokens(SearchText.ToString(), SearchTokens);

		if(SearchTokens.Num() > 0)
		{
			FString CurrentSearchToken = SearchTokens[SearchTokens.Num() - 1];
			ESlateVisibility SuggestionVisibility = RegenerateSearchSuggestions(CurrentSearchToken)
				? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
			GetSearchSuggestions().SetVisibility(SuggestionVisibility);
			GetSearchSuggestions().ClearHeightOverride();
			GetSearchButton().SetCheckedState(ECheckBoxState::Unchecked);
		}
		else
		{
			GetSearchSuggestions().SetVisibility(ESlateVisibility::Collapsed);
		}
		
        OnSearchChanged.Broadcast(this, SearchTokens, false);
	}

	UFUNCTION()
	void FinalizeSearch(FText& SearchText, ETextCommit CommitMethod)
	{
		if(CommitMethod == ETextCommit::OnEnter)
		{
			GetSearchSuggestions().SetVisibility(ESlateVisibility::Collapsed);
		}

        TArray<FString> SearchTokens;
        ParseSearchTokens(SearchText.ToString(), SearchTokens);

        OnSearchChanged.Broadcast(this, SearchTokens, true);
	}

	UFUNCTION()
	void SearchButtonStateChanged(bool bNewSearchState)
	{
		if(bNewSearchState)
		{
			ESlateVisibility SuggestionVisibility = RegenerateSearchSuggestions()
				? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
			GetSearchSuggestions().SetVisibility(SuggestionVisibility);
			GetSearchSuggestions().SetHeightOverride(SearchButtonFoldoutSize);
		}
		else
		{
			GetSearchSuggestions().SetVisibility(ESlateVisibility::Collapsed);
			GetSearchSuggestions().ClearHeightOverride();
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
    
	bool RegenerateSearchSuggestions()
	{
		GetSearchSuggestionsPanel().ClearChildren();

		if(!bGenerateSearchSuggestions || SortedQuickSelectTokens.Num() <= 0)
		{
			return false;
		}

		for(FString Token : SortedQuickSelectTokens)
		{
			UFeatherButtonStyle SuggestionButton = CreateButton();
			UFeatherTextBlockStyle SuggestionText = CreateTextBlock();
			SuggestionText.GetTextWidget().SetText(FText::FromString(Token));
			SuggestionButton.GetButtonWidget().SetContent(SuggestionText);
			SuggestionButton.OnClickedWithContext.AddUFunction(this, n"QuickSuggestionClicked");
			GetSearchSuggestionsPanel().AddChildToVerticalBox(SuggestionButton);
		}

		return true;
	}

	bool RegenerateSearchSuggestions(FString SearchToken)
	{
		GetSearchSuggestionsPanel().ClearChildren();

		if(!bGenerateSearchSuggestions)
		{
			return false;
		}

		// Only ever try to complete the last token.
		TArray<FNameWithScore> ValidSuggestionsWithScores;
		for(FString TargetToken : AllSearchTargetTokens)
		{
			float MatchScore = FeatherUtils::CalculateTokenMatchScore(TargetToken, SearchToken);
			if(MatchScore == 1.0f)
			{
				// This token is already complete! Nothing to do here.
				return false;
			}
			else if(MatchScore > 0.0f)
			{
				FNameWithScore NewSuggestionWithScore;
				NewSuggestionWithScore.Name = FName(TargetToken);
				NewSuggestionWithScore.RankingScoreUNorm = MatchScore;
				ValidSuggestionsWithScores.Add(NewSuggestionWithScore);
			}
		}
		FeatherSorting::QuickSortSuggestions(ValidSuggestionsWithScores, 0, ValidSuggestionsWithScores.Num() - 1);

		int NumberOfSuggestions = FMath::Min(MaxSearchSuggestions, ValidSuggestionsWithScores.Num());
		for(int i = 0; i < NumberOfSuggestions; i++)
		{
			FNameWithScore Suggestion = ValidSuggestionsWithScores[i];

			UFeatherButtonStyle SuggestionButton = CreateButton();
			UFeatherTextBlockStyle SuggestionText = CreateTextBlock();
			SuggestionText.GetTextWidget().SetText(FText::FromString(Suggestion.Name.ToString()));
			SuggestionButton.GetButtonWidget().SetContent(SuggestionText);
			SuggestionButton.OnClickedWithContext.AddUFunction(this, n"CompletionSuggestionClicked");
			GetSearchSuggestionsPanel().AddChildToVerticalBox(SuggestionButton);
		}

		return NumberOfSuggestions > 0;
	}

	UFUNCTION()
	void CompletionSuggestionClicked(UFeatherButtonStyle ClickedButton)
	{
		GetSearchSuggestions().SetVisibility(ESlateVisibility::Collapsed);

		UFeatherTextBlockStyle SuggestionText = Cast<UFeatherTextBlockStyle>(ClickedButton.GetButtonWidget().GetContent());
		if(System::IsValid(SuggestionText))
		{
			const FString SuggestionToUse = SuggestionText.GetTextWidget().GetText().ToString();
			FString CurrentSearchString = GetSearchTextBox().GetText().ToString().TrimStartAndEnd();

			// Remove the final term.
			FString LeftChop;
			FString RightChop;
			if(CurrentSearchString.Split(",", LeftChop, RightChop, SearchDir = ESearchDir::FromEnd)
				|| CurrentSearchString.Split(" ", LeftChop, RightChop, SearchDir = ESearchDir::FromEnd))
			{
				CurrentSearchString = LeftChop + " ";
			}
			else
			{
				CurrentSearchString = "";
			}

			const FString NewSearchString = CurrentSearchString + SuggestionToUse;
			GetSearchTextBox().SetText(FText::FromString(NewSearchString));
			GetSearchTextBox().SetKeyboardFocus();
		}
	}
	
	UFUNCTION()
	void QuickSuggestionClicked(UFeatherButtonStyle ClickedButton)
	{
		GetSearchSuggestions().SetVisibility(ESlateVisibility::Collapsed);
		GetSearchSuggestions().ClearHeightOverride();
		GetSearchButton().SetCheckedState(ECheckBoxState::Unchecked);

		UFeatherTextBlockStyle SuggestionText = Cast<UFeatherTextBlockStyle>(ClickedButton.GetButtonWidget().GetContent());
		if(System::IsValid(SuggestionText))
		{
			const FString SuggestionToUse = SuggestionText.GetTextWidget().GetText().ToString();
			FString CurrentSearchString = GetSearchTextBox().GetText().ToString().TrimStartAndEnd();

			if(CurrentSearchString.IsEmpty())
			{
				CurrentSearchString = SuggestionToUse;
			}
			else
			{
				CurrentSearchString += " " + SuggestionToUse;
			}

			GetSearchTextBox().SetText(FText::FromString(CurrentSearchString));
			GetSearchTextBox().SetKeyboardFocus();
		}
	}

///////////////////////////////////////////////////////////////////////

	UFUNCTION(Category = "Feather", BlueprintPure)
	FText GetSearchText()
	{
		return GetSearchTextBox().GetText();
	}
	
	UFUNCTION(Category = "Feather")
	void SetSearchText(FText NewText)
	{
		GetSearchTextBox().SetText(NewText);
	}

///////////////////////////////////////////////////////////////////////

	UFUNCTION(Category = "Feather", BlueprintEvent)
	UCheckBox GetSearchButton()
	{
		return nullptr;
	}

	UFUNCTION(Category = "Feather", BlueprintEvent)
	USizeBox GetSearchSuggestions()
	{
		return nullptr;
	}

	UFUNCTION(Category = "Feather", BlueprintEvent)
	UVerticalBox GetSearchSuggestionsPanel()
	{
		return nullptr;
	}

	UFUNCTION(Category = "Feather", BlueprintEvent)
	UEditableText GetSearchTextBox()
	{
		return nullptr;
	}
};
