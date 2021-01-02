// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceOperation;

namespace FeatherUtils
{
	// This will return the look-at if there is no cursor, otherwise it will return the point under the cursor.
	UFUNCTION(Category = "Feather|Utils")
	bool GetPlayerFocus(FHitResult& OutFocus)
	{
		APlayerController FirstPlayer = Gameplay::GetPlayerController(0);
		if(System::IsValid(FirstPlayer))
		{
			if(FirstPlayer.bShowMouseCursor)
			{
				return FirstPlayer.GetHitResultUnderCursorByChannel(ETraceTypeQuery::Visibility, true, OutFocus);
			}
			else
			{
				return GetPlayerLookAt(OutFocus);
			}
		}

		return false;
	}

	// Get the look-at of the first player. This is the point under the middle of the screen.
	UFUNCTION(Category = "Feather|Utils")
	bool GetPlayerLookAt(FHitResult& OutLookAt)
	{
		APlayerController FirstPlayer = Gameplay::GetPlayerController(0);
		if(System::IsValid(FirstPlayer) && System::IsValid(FirstPlayer.PlayerCameraManager))
		{
			const FVector2D ViewportSize = WidgetLayout::GetViewportWidgetGeometry().GetLocalSize();
			const FVector2D ViewportCenter = ViewportSize / 2.0f;

			FVector UnprojectedPosition;
			FVector UnprojectedDirection;
			if(FirstPlayer.DeprojectScreenPositionToWorld(ViewportCenter.X, ViewportCenter.Y, UnprojectedPosition, UnprojectedDirection))
			{
				FVector End = UnprojectedPosition + UnprojectedDirection * 100000.0f;
				TArray<AActor> IgnoredActors;
				IgnoredActors.Add(FirstPlayer);
				IgnoredActors.Add(FirstPlayer.GetControlledPawn());
				return System::LineTraceSingle(UnprojectedPosition, End, ETraceTypeQuery::Visibility, true, IgnoredActors, EDrawDebugTrace::None, OutLookAt, true);
			}
		}

		return false;
	}
}

struct FOperationWithScore
{
	UFeatherDebugInterfaceOperation Operation;
	float RankingScoreUNorm;
};

struct FSearchSuggestionWithScore
{
	FName SearchSuggestion;
	float RankingScoreUNorm;
};

enum ESortDirection
{
	Ascending,
	Descending
};

// TODO: Obviously this would be a lot better to put into C++, but I want to see if I can keep it AS only. Adding a good sorting API to AS would be the best solution! Making it so you can implement comparison operations for arbitrary types would be best...?
// Adapted from: https://www.geeksforgeeks.org/cpp-program-for-quicksort/
namespace FeatherSorting
{
	void QuickSortOperations(TArray<FOperationWithScore>& Operations, int LowIndex, int HighIndex, ESortDirection SortDirection = ESortDirection::Descending)
	{
		if (LowIndex < HighIndex && Operations.IsValidIndex(LowIndex) && Operations.IsValidIndex(HighIndex))
		{
			// After partitioning, the item at the PartitionIndex is in its right place.
			int PartitionIndex = PartitionOperations(Operations, LowIndex, HighIndex, SortDirection);

			// Separately sort elements before and after partition.
			QuickSortOperations(Operations, LowIndex, PartitionIndex - 1);
			QuickSortOperations(Operations, PartitionIndex + 1, HighIndex);
		}
	}

	// This function takes last element as pivot, places the pivot element at its correct position in sorted array, and places all smaller (smaller than pivot) to left of pivot and all greater elements to right of pivot.
	int PartitionOperations(TArray<FOperationWithScore>& Operations, int LowIndex, int HighIndex, ESortDirection SortDirection)
	{
		FOperationWithScore Pivot = Operations[HighIndex];
		int i = (LowIndex - 1);  // Index of smaller element

		for (int j = LowIndex; j <= HighIndex - 1; j++)
		{
			if(!Operations.IsValidIndex(j))
			{
				continue;
			}

			// If current element is smaller than or equal to pivot
			bool bShouldFlip = OperationAShouldRankBeforeOperationB(Operations[j], Pivot);
			if(SortDirection == ESortDirection::Descending)
			{
				bShouldFlip = !bShouldFlip;
			}

			if (bShouldFlip)
			{
				i++;    // increment index of smaller element
				SwapOperations(Operations, i, j);
			}
		}

		SwapOperations(Operations, i + 1, HighIndex);
		return (i + 1);
	}

	void SwapOperations(TArray<FOperationWithScore>& Operations, int Idx1, int Idx2)
	{
		if(ensure(Operations.IsValidIndex(Idx1) && Operations.IsValidIndex(Idx2), "Index out of bounds in QuickSort! Should not happen!"))
		{
			FOperationWithScore Temp = Operations[Idx1];
			Operations[Idx1] = Operations[Idx2];
			Operations[Idx2] = Temp;
		}
	}

	bool OperationAShouldRankBeforeOperationB(FOperationWithScore A, FOperationWithScore B)
	{
		if(!System::IsValid(A.Operation) || !System::IsValid(B.Operation))
		{
			return true;
		}

		if(A.RankingScoreUNorm == B.RankingScoreUNorm)
		{
			// Sort alphabetically
			return A.Operation.Class.GetName().ToString().Compare(B.Operation.Class.GetName().ToString()) <= 0;
		}

		return A.RankingScoreUNorm < B.RankingScoreUNorm;
	}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	void QuickSortSuggestions(TArray<FSearchSuggestionWithScore>& Suggestions, int LowIndex, int HighIndex, ESortDirection SortDirection = ESortDirection::Descending)
	{
		if (LowIndex < HighIndex && Suggestions.IsValidIndex(LowIndex) && Suggestions.IsValidIndex(HighIndex))
		{
			// After partitioning, the item at the PartitionIndex is in its right place.
			int PartitionIndex = PartitionSuggestions(Suggestions, LowIndex, HighIndex, SortDirection);

			// Separately sort elements before and after partition.
			QuickSortSuggestions(Suggestions, LowIndex, PartitionIndex - 1);
			QuickSortSuggestions(Suggestions, PartitionIndex + 1, HighIndex);
		}
	}

	// This function takes last element as pivot, places the pivot element at its correct position in sorted array, and places all smaller (smaller than pivot) to left of pivot and all greater elements to right of pivot.
	int PartitionSuggestions(TArray<FSearchSuggestionWithScore>& Suggestions, int LowIndex, int HighIndex, ESortDirection SortDirection)
	{
		FSearchSuggestionWithScore Pivot = Suggestions[HighIndex];
		int i = (LowIndex - 1);  // Index of smaller element

		for (int j = LowIndex; j <= HighIndex - 1; j++)
		{
			// If current element is smaller than or equal to pivot
			if(!Suggestions.IsValidIndex(j))
			{
				continue;
			}

			bool bShouldFlip = SuggestionAShouldRankBeforeSuggestionB(Suggestions[j], Pivot);
			if(SortDirection == ESortDirection::Descending)
			{
				bShouldFlip = !bShouldFlip;
			}

			if (bShouldFlip)
			{
				i++;    // increment index of smaller element
				SwapSuggestions(Suggestions, i, j);
			}
		}

		SwapSuggestions(Suggestions, i + 1, HighIndex);
		return (i + 1);
	}

	void SwapSuggestions(TArray<FSearchSuggestionWithScore>& Suggestions, int Idx1, int Idx2)
	{
		if(ensure(Suggestions.IsValidIndex(Idx1) && Suggestions.IsValidIndex(Idx2), "Index out of bounds in QuickSort! Should not happen!"))
		{
			FSearchSuggestionWithScore Temp = Suggestions[Idx1];
			Suggestions[Idx1] = Suggestions[Idx2];
			Suggestions[Idx2] = Temp;
		}
	}

	bool SuggestionAShouldRankBeforeSuggestionB(FSearchSuggestionWithScore A, FSearchSuggestionWithScore B)
	{
		if(A.RankingScoreUNorm == B.RankingScoreUNorm)
		{
			// Sort alphabetically
			return A.SearchSuggestion.ToString().Compare(B.SearchSuggestion.ToString()) <= 0;
		}

		return A.RankingScoreUNorm < B.RankingScoreUNorm;
	}
}
