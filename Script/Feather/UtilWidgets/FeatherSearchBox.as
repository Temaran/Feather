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
    TSet<FString> SearchTargetTokens;

    UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
    bool bGenerateSearchSuggestions = true;

	UPROPERTY(Category = "Feather|Search", EditDefaultsOnly)
	int MaxSearchSuggestions = 3;

	UPROPERTY(Category = "Feather|Search", EditDefaultsOnly)
	float MaxScoreFromMatch = 0.8f;

	UPROPERTY(Category = "Feather|Search", EditDefaultsOnly)
	float MaxScoreFromPosition = 1.0f - MaxScoreFromMatch;


    UFUNCTION(BlueprintOverride)
    void FeatherConstruct()
    {
		Super::FeatherConstruct();
		
		GetSearchButton().OnCheckStateChanged.AddUFunction(this, n"SearchButtonStateChanged");
		GetSearchTextBox().OnTextChanged.AddUFunction(this, n"SearchChanged");
		GetSearchTextBox().OnTextCommitted.AddUFunction(this, n"FinalizeSearch");

		GetSearchSuggestions().SetVisibility(ESlateVisibility::Collapsed);
    }

	UFUNCTION()
	void SearchChanged(FText& SearchText)
	{
		TArray<FString> SearchTokens;
		ParseSearchTokens(SearchText.ToString(), SearchTokens);

		ESlateVisibility SuggestionVisibility = RegenerateSearchSuggestions(SearchTokens)
			? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		GetSearchSuggestions().SetVisibility(SuggestionVisibility);

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
		GetSearchSuggestionsPanel().ClearChildren();

		if(SearchTokens.Num() <= 0 || !bGenerateSearchSuggestions)
		{
			return false;
		}

		// Only ever try to complete the last token.
		FString CurrentSearchToken = SearchTokens[SearchTokens.Num() - 1];
		TArray<FNameWithScore> ValidSuggestionsWithScores;
		for(FString TargetToken : SearchTargetTokens)
		{
			float MatchScore = FeatherUtils::CalculateTokenMatchScore(TargetToken, CurrentSearchToken);
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
			SuggestionButton.OnClickedWithContext.AddUFunction(this, n"SuggestionClicked");
			GetSearchSuggestionsPanel().AddChildToVerticalBox(SuggestionButton);
		}

		return NumberOfSuggestions > 0;
	}

	UFUNCTION()
	void SuggestionClicked(UFeatherButtonStyle ClickedButton)
	{
		GetSearchSuggestions().SetVisibility(ESlateVisibility::Collapsed);

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
	UBorder GetSearchSuggestions()
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
