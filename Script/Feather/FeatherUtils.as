// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

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
			FVector CameraLocation = FirstPlayer.PlayerCameraManager.GetCameraLocation();
			FVector CameraDirection = FirstPlayer.PlayerCameraManager.GetCameraRotation().ForwardVector;
			
			FVector End = CameraLocation + CameraDirection * 100000.0f;
			TArray<AActor> IgnoredActors;
			IgnoredActors.Add(FirstPlayer);
			IgnoredActors.Add(FirstPlayer.GetControlledPawn());
			return System::LineTraceSingle(CameraLocation, End, ETraceTypeQuery::Visibility, true, IgnoredActors, EDrawDebugTrace::None, OutLookAt, true);
		}

		return false;
	}

	UFUNCTION(Category = "Feather|Utils")
	bool StringToVector(const FString& InString, FVector& OutVector)
	{
		FString Temp;
		FString X;
		FString Y;
		FString Z;

		if(InString.Split(" ", X, Temp) && Temp.Split(" ", Y, Z))
		{
			OutVector.X = ParseLocaleInvariantFloat(X);
			OutVector.Y = ParseLocaleInvariantFloat(Y);
			OutVector.Z = ParseLocaleInvariantFloat(Z);
			return true;
		}

		return false;
	}

	UFUNCTION(Category = "Feather|Utils", BlueprintPure)
	FString VectorToString(const FVector& InVector)
	{
		return "" + InVector.X + " " + InVector.Y + " " + InVector.Z;
	}
	
	UFUNCTION(Category = "Feather|Utils", BlueprintPure)
	FString CleanNumeric(const FString& Input)
	{
		FString InputString = Input.Replace(",", ".");
		FString OutputString = "";
		for(int CharIdx = 0; CharIdx < InputString.Len(); CharIdx++)
		{
			FString Char = InputString.Mid(CharIdx, 1);
			if(Char.IsNumeric() || Char.Compare(".") == 0)
			{
				OutputString += Char;
			}
		}

		return OutputString;
	}

	UFUNCTION(Category = "Feather|Utils", BlueprintPure)
	int ParseLocaleInvariantInt(const FString& LocalIntString)
	{
		return String::Conv_StringToInt(CleanNumeric(LocalIntString));
	}

	UFUNCTION(Category = "Feather|Utils", BlueprintPure)
	float ParseLocaleInvariantFloat(const FString& LocaleFloatString)
	{
		return String::Conv_StringToFloat(CleanNumeric(LocaleFloatString));
	}
	
	UFUNCTION(Category = "Feather|Utils", BlueprintPure)
	float CalculateTokenMatchScore(FString TargetToken, FString InputToTest)
	{
		const float MaxScoreFromMatch = 0.8f;
		const float MaxScoreFromPosition = 1.0f - MaxScoreFromMatch;
		
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
}
