namespace FeatherAssetRegistryUtils
{
	// Given a class, return all the names of the assets that are of this class. NOTE: A blueprint class will not work with this function.
	UFUNCTION(BlueprintCallable)
	TMap<FString, FName> GetNameOfAllAssetsWithClass(TSubclassOf<UObject> Class, FString AssetNamePrefix, bool bSortNames = true)
	{
		TArray<FAssetData> AssetData;
		AssetRegistry::GetAssetsByClass(Class.Get().GetName(), AssetData, true);

		TMap<FString, FName> OutputNamesAndPaths;

		for (const FAssetData& Asset : AssetData)
		{
			OutputNamesAndPaths.Add(Asset.AssetName.ToString().RightChop(AssetNamePrefix.Len()), Asset.ObjectPath);
		}

		if (bSortNames)
		{
			TArray<FString> Names;

			for (TMapIterator<FString, FName> It : OutputNamesAndPaths)
			{
				Names.Add(It.GetKey());
			}

			Names.Sort();

			TMap<FString, FName> SortedNames;

			for (const FString& Name : Names)
			{
				SortedNames.Add(Name, OutputNamesAndPaths[Name]);
			}

			OutputNamesAndPaths = SortedNames;
		}

		return OutputNamesAndPaths;
	}

	UFUNCTION(BlueprintCallable)
	UObject GetAssetByObjectPath(FName Path)
	{
		FAssetData Asset = AssetRegistry::GetAssetByObjectPath(Path);

		return UAssetRegistryHelpers::GetAsset(Asset);
	}
}
