// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.FeatherWidget;
import Feather.FeatherSorting;
import Feather.FeatherUtils;

struct FSearchBoxSaveState
{
	FString SearchText;
	int MaxSearchSuggestions;
	float QuickSelectFoldoutSize;
};

event void FSearchChangedEvent(UFeatherSearchBox SearchBox, const TArray<FString>& SearchTokens, bool bSearchWasFinalized);

class UFeatherSearchBox : UFeatherWidget
{
	// Call whenever our search string changed
    UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
    FSearchChangedEvent OnSearchChanged;

	// These tokens are all the search tokens. We use these for autocomplete
    UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
    TSet<FString> AllSearchTargetTokens;

	// Some quick select tokens are special. This array contains those. These are added to the top of the quick select, with a small separation.
    UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
    TArray<FString> SpecialQuickSelectTokens;

	// All the quick select tokens (except for the special ones).
    UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
    TSet<FString> QuickSelectTokens;

	// How many search suggestions do we generate during autocomplete?
	UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
	int MaxSearchSuggestions = 3;

	// When showing the quick-select terms, how big do we make the foldout?
	UPROPERTY(Category = "Feather Search Box", EditDefaultsOnly)
	float QuickSelectFoldoutSize = 200.0f;

	TArray<FString> SortedQuickSelectTokens;
	TArray<FString> LatestSearchTokens;


    UFUNCTION(BlueprintOverride)
	void FeatherConstruct(FFeatherStyle InStyle, FFeatherConfig InConfig)
    {
		Super::FeatherConstruct(InStyle, InConfig);
		
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

	UFUNCTION(BlueprintOverride)
	void Reset()
	{
		SetSearchText(FText());
		MaxSearchSuggestions = 3;
		QuickSelectFoldoutSize = 200.0f;
	}

	UFUNCTION()
	void SearchChanged(FText& SearchText)
	{
		ParseSearchTokens(SearchText.ToString(), LatestSearchTokens);

		ESlateVisibility SuggestionVisibility = RegenerateSearchSuggestions(LatestSearchTokens)
				? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
		GetSearchSuggestions().SetVisibility(SuggestionVisibility);
		GetSearchSuggestions().ClearHeightOverride();
		GetSearchButton().SetCheckedState(ECheckBoxState::Unchecked);
		
        OnSearchChanged.Broadcast(this, LatestSearchTokens, false);

		SaveSettings();
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
			ESlateVisibility SuggestionVisibility = RegenerateQuickSuggestions()
				? ESlateVisibility::Visible : ESlateVisibility::Collapsed;
			GetSearchSuggestions().SetVisibility(SuggestionVisibility);
			GetSearchSuggestions().SetHeightOverride(QuickSelectFoldoutSize);
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
			OutSearchTokens.Add(Corpus.TrimStartAndEnd());
		}
	}
    
	bool RegenerateQuickSuggestions()
	{
		GetSearchSuggestionsPanel().ClearChildren();

		if(SortedQuickSelectTokens.Num() <= 0)
		{
			return false;
		}

		for(int i = 0; i < SpecialQuickSelectTokens.Num(); i++)
		{
			bool bLastEntry = i == SpecialQuickSelectTokens.Num() - 1;
			float BottomPadding = bLastEntry ? 20.0f : 0.0f;
			AddQuickSuggestion(SpecialQuickSelectTokens[i], BottomPadding);
		}

		for(FString Token : SortedQuickSelectTokens)
		{
			AddQuickSuggestion(Token, 0.0f);
		}

		return true;
	}

	void AddQuickSuggestion(FString Entry, float BottomPadding)
	{
		UFeatherButtonStyle SuggestionButton = CreateButton();
		UFeatherTextBlockStyle SuggestionText = CreateTextBlock();
		SuggestionText.GetTextWidget().SetText(FText::FromString(Entry));
		SuggestionButton.GetButtonWidget().SetContent(SuggestionText);
		FMargin EntryPadding;
		EntryPadding.Bottom = BottomPadding;
		SuggestionButton.SetPadding(EntryPadding);
		SuggestionButton.OnClickedWithContext.AddUFunction(this, n"QuickSuggestionClicked");
		GetSearchSuggestionsPanel().AddChildToVerticalBox(SuggestionButton);
	}

	bool RegenerateSearchSuggestions(const TArray<FString>& SearchTokens)
	{
		GetSearchSuggestionsPanel().ClearChildren();

		// Ignore special tokens
		FString SearchToken;
		for(int i = SearchTokens.Num() - 1; i >= 0; i--)
		{
			FString Token = SearchTokens[i];
			if(!SpecialQuickSelectTokens.Contains(Token))
			{
				SearchToken = Token;
				break;
			}
		}

		if(MaxSearchSuggestions == 0 || SearchToken.IsEmpty())
		{
			return false;
		}

		// Extract valid suggestions and rank them
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

		// Generate entries
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
			FString CurrentSearchString = GetSearchTextBox().GetText().ToString().TrimStartAndEnd();
			FString SuggestionToUse = SuggestionText.GetTextWidget().GetText().ToString();
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

	UFUNCTION(BlueprintOverride)
	void SaveToString(FString& InOutSaveString)
	{
		FSearchBoxSaveState SaveState;
		SaveState.SearchText = GetSearchText().ToString();
		SaveState.MaxSearchSuggestions = MaxSearchSuggestions;
		SaveState.QuickSelectFoldoutSize = QuickSelectFoldoutSize;
		FJsonObjectConverter::AppendUStructToJsonObjectString(SaveState, InOutSaveString);
	}

	UFUNCTION(BlueprintOverride)
	void LoadFromString(const FString& InSaveString)
	{
		FSearchBoxSaveState SaveState;
		if(FJsonObjectConverter::JsonObjectStringToUStruct(InSaveString, SaveState))
		{
			SetSearchText(FText::FromString(SaveState.SearchText));
			MaxSearchSuggestions = SaveState.MaxSearchSuggestions;
			QuickSelectFoldoutSize = SaveState.QuickSelectFoldoutSize;
		}
	}
	
	void SetMaxSearchSuggestions(int NewMaxSearchSuggestions)
	{
		MaxSearchSuggestions = NewMaxSearchSuggestions;
		RegenerateSearchSuggestions(LatestSearchTokens);
	}

	void SetQuickSelectFoldoutSize(float NewQuickSelectFoldoutSize)
	{
		QuickSelectFoldoutSize = NewQuickSelectFoldoutSize;
		RegenerateQuickSuggestions();
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
