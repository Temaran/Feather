// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherWidget;
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

	UPROPERTY(Category = "Feather|Search", EditDefaultsOnly)
	TArray<FString> IgnoredTokenSubstrings;
	default IgnoredTokenSubstrings.Add("feather");
	default IgnoredTokenSubstrings.Add("operation");

    FLinearColor SuggestionsBackgroundColor = FLinearColor(0.05f, 0.05f, 0.05f, 1.0f);
    UFeatherCheckBoxStyle SearchButton;
    UFeatherEditableTextStyle SearchText;
    UVerticalBox SearchSuggestionsPanel;
    
    
    UFUNCTION(BlueprintOverride)
    void FeatherConstruct()
    {
        FSlateChildSize FillSize;
        FillSize.SizeRule = ESlateSizeRule::Fill;

        UVerticalBox VerticalLayout = Cast<UVerticalBox>(ConstructWidget(UVerticalBox::StaticClass()));
        SetRootWidget(VerticalLayout);

        UHorizontalBox HorizontalLayout = Cast<UHorizontalBox>(ConstructWidget(UHorizontalBox::StaticClass()));
        VerticalLayout.AddChildToVerticalBox(HorizontalLayout);

        SearchButton = CreateCheckBox(n"SearchButton");        
		SearchButton.GetCheckBoxWidget().OnCheckStateChanged.AddUFunction(this, n"SearchButtonStateChanged");
        HorizontalLayout.AddChildToHorizontalBox(SearchButton);

        SearchText = CreateEditableText();
		SearchText.GetEditableText().OnTextChanged.AddUFunction(this, n"SearchChanged");
		SearchText.GetEditableText().OnTextCommitted.AddUFunction(this, n"FinalizeSearch");
        UHorizontalBoxSlot TextSlot = HorizontalLayout.AddChildToHorizontalBox(SearchText);
        TextSlot.SetSize(FillSize);

        UBorder SearchSuggestionsBorder = Cast<UBorder>(ConstructWidget(UBorder::StaticClass()));
        SearchSuggestionsBorder.SetBrushColor(SuggestionsBackgroundColor);
        UVerticalBoxSlot SuggestionSlot = VerticalLayout.AddChildToVerticalBox(SearchSuggestionsBorder);
        SuggestionSlot.SetSize(FillSize);

        SearchSuggestionsPanel = Cast<UVerticalBox>(ConstructWidget(UVerticalBox::StaticClass()));
        SearchSuggestionsPanel.SetVisibility(ESlateVisibility::Collapsed);
        SearchSuggestionsBorder.SetContent(SearchSuggestionsPanel);
    }

	UFUNCTION()
	void SearchChanged(FText& SearchText)
	{
		TArray<FString> SearchTokens;
		ParseSearchTokens(SearchText.ToString(), SearchTokens);

		ESlateVisibility SuggestionVisibility = RegenerateSearchSuggestions(SearchTokens)
			? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		SearchSuggestionsPanel.SetVisibility(SuggestionVisibility);

        OnSearchChanged.Broadcast(this, SearchTokens, false);
	}

	UFUNCTION()
	void FinalizeSearch(FText& SearchText, ETextCommit CommitMethod)
	{
		if(CommitMethod == ETextCommit::OnEnter)
		{
			SearchSuggestionsPanel.SetVisibility(ESlateVisibility::Collapsed);
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
		SearchSuggestionsPanel.ClearChildren();

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

		return NumberOfSuggestions > 0;
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
};
