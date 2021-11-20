// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

struct FAutoExecSaveState
{
	UPROPERTY()
	FString StartUpExecs;

	UPROPERTY()
	FString ShutDownExecs;
};

UCLASS(Abstract)
class UFeatherDebugInterfaceAutoExecWindow : UFeatherDebugInterfaceToolWindow
{
	default WindowName = n"AutoExec";

	private bool bHasRunStartUpExecs = false;

	UFUNCTION(BlueprintOverride)
	void FeatherConstruct(FFeatherStyle InStyle, FFeatherConfig InConfig)
	{
		Super::FeatherConstruct(InStyle, InConfig);

		GetStartUpBox().OnTextCommitted.AddUFunction(this, n"StartUpExecsCommitted");
		GetShutDownBox().OnTextCommitted.AddUFunction(this, n"ShutDownExecsCommitted");
	}

	UFUNCTION()
	void StartUpExecsCommitted(const FText&in NewExecs, ETextCommit CommitMethod)
	{
		SaveSettings();
	}

	UFUNCTION()
	void ShutDownExecsCommitted(const FText&in NewExecs, ETextCommit CommitMethod)
	{
		SaveSettings();
	}

	UFUNCTION(BlueprintOverride)
	void Destruct()
	{
		ExecuteCorpusString(GetShutDownBox().GetText().ToString());
	}

	void ExecuteCorpusString(FString ExecCorpus)
	{
		FString Corpus = ExecCorpus;
		FString CurrentExec;
		FString RemainingString;
		while(Corpus.Split("\r\n", CurrentExec, RemainingString))
		{
			CurrentExec = CurrentExec.TrimStartAndEnd();
			if(!CurrentExec.IsEmpty())
			{
				System::ExecuteConsoleCommand(CurrentExec);
			}

			Corpus = RemainingString;
		}

		Corpus = Corpus.TrimStartAndEnd();
		if(!Corpus.IsEmpty())
		{
			System::ExecuteConsoleCommand(Corpus);
		}
	}

	UFUNCTION(BlueprintOverride)
	void SaveToString(FString& InOutSaveString)
	{
		Super::SaveToString(InOutSaveString);

		FAutoExecSaveState SaveState;
		SaveState.StartUpExecs = GetStartUpBox().GetText().ToString();
		SaveState.ShutDownExecs = GetShutDownBox().GetText().ToString();
		FJsonObjectConverter::AppendUStructToJsonObjectString(SaveState, InOutSaveString);
	}

	UFUNCTION(BlueprintOverride)
	void LoadFromString(const FString& InSaveString)
	{
		Super::LoadFromString(InSaveString);

		FAutoExecSaveState SaveState;
		if(FJsonObjectConverter::JsonObjectStringToUStruct(InSaveString, SaveState))
		{
			GetStartUpBox().SetText(FText::FromString(SaveState.StartUpExecs));
			GetShutDownBox().SetText(FText::FromString(SaveState.ShutDownExecs));
		}

		if(!bHasRunStartUpExecs)
		{
			ExecuteCorpusString(GetStartUpBox().GetText().ToString());
			bHasRunStartUpExecs = true;
		}
	}

////////////////////////////////////////////////////////////////////////

	UFUNCTION(Category = "AutoExec", BlueprintEvent)
	UMultiLineEditableText GetStartUpBox()
	{
		return nullptr;
	}

	UFUNCTION(Category = "AutoExec", BlueprintEvent)
	UMultiLineEditableText GetShutDownBox()
	{
		return nullptr;
	}
};
