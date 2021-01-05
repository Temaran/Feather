// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

struct FNameWithScore
{
	FName Name;
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
	void QuickSortSuggestions(TArray<FNameWithScore>& Suggestions, int LowIndex, int HighIndex, ESortDirection SortDirection = ESortDirection::Descending)
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
	int PartitionSuggestions(TArray<FNameWithScore>& Suggestions, int LowIndex, int HighIndex, ESortDirection SortDirection)
	{
		FNameWithScore Pivot = Suggestions[HighIndex];
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

	void SwapSuggestions(TArray<FNameWithScore>& Suggestions, int Idx1, int Idx2)
	{
		if(ensure(Suggestions.IsValidIndex(Idx1) && Suggestions.IsValidIndex(Idx2), "Index out of bounds in QuickSort! Should not happen!"))
		{
			FNameWithScore Temp = Suggestions[Idx1];
			Suggestions[Idx1] = Suggestions[Idx2];
			Suggestions[Idx2] = Temp;
		}
	}

	bool SuggestionAShouldRankBeforeSuggestionB(FNameWithScore A, FNameWithScore B)
	{
		if(A.RankingScoreUNorm == B.RankingScoreUNorm)
		{
			// Sort alphabetically
			return A.Name.ToString().Compare(B.Name.ToString()) <= 0;
		}

		return A.RankingScoreUNorm < B.RankingScoreUNorm;
	}
}
