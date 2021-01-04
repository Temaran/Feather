// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.FeatherDebugInterfaceOperation;
import Feather.FeatherSorting;

struct FOperationWithScore
{
	UFeatherDebugInterfaceOperation Operation;
	float RankingScoreUNorm;
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
}
