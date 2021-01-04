// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceWindow;
import Feather.DebugInterface.FeatherDebugInterfaceSorting;
import Feather.UtilWidgets.FeatherSearchBox;
import Feather.UtilWidgets.FeatherWindowSelectionBox;
import Feather.FeatherSorting;
import Feather.FeatherUtils;

struct FDebugInterfaceMainWindowSaveState
{
	FString SearchText;
};

UCLASS(Abstract)
class UFeatherDebugInterfaceMainWindow : UFeatherDebugInterfaceWindow
{
	default WindowName = n"Debug Interface";

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

		SetupSearchBox();
		SetupWindowManager();
		RegenerateSearch(TArray<FString>());
	}

	void SetupSearchBox()
	{
		UFeatherSearchBox MySearchBox = GetSearchBox();
		MySearchBox.Style = Style;
		MySearchBox.OnSearchChanged.AddUFunction(this, n"SearchChanged");

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
			OperationWidget.ConstructFeatherWidget();
			Operations.Add(OperationWidget);

			// Add all search terms
			MySearchBox.AllSearchTargetTokens.Add(GetSanitizedOperationName(OperationCDO));
			for(FName OperationTag : OperationCDO.OperationTags)
			{
				const FString TagToken = OperationTag.ToString();
				MySearchBox.AllSearchTargetTokens.Add(TagToken);
				MySearchBox.QuickSelectTokens.Add(TagToken);
			}
		}
		MySearchBox.ConstructFeatherWidget();
	}

	void SetupWindowManager()
	{
		UFeatherWindowSelectionBox MyWindowManager = GetWindowManager();
		MyWindowManager.ToolWindows = ToolWindows;
		MyWindowManager.Style = Style;
		MyWindowManager.ConstructFeatherWidget();
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
