import Feather.DebugInterface.OperationBaseClasses.FeatherSimpleCheckBoxOperationBase;
import Feather.FeatherSettings;

// An easy to use base class for auto operations that are tied to one or more console variables.
UCLASS(Abstract)
class UFeatherSimpleConsoleVariableOperation : UFeatherSimpleCheckBoxOperationBase
{
	// These are the  tied to this operation.
	UPROPERTY(Category = "Simple Console Variable Operation")
	TArray<FName> ConsoleVariableNames;

	// If this is true, then the first entry in ConsoleVariableNames will be used to determine current op state. If this is false, then all CVars need to be true to interpret the state of this op to be true.
	UPROPERTY(Category = "Simple Console Variable Operation")
	bool bIsFirstCVarMaster = true;

	UFUNCTION(BlueprintOverride)
	void OnCheckStateChanged(bool bChecked)
	{
		int StateInt = bChecked ? 1 : 0;
		for(FName CVarName : ConsoleVariableNames)
		{
			System::ExecuteConsoleCommand(CVarName.ToString() + " " + StateInt);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool IsCheckedByDefault() const
	{
		if(bIsFirstCVarMaster && ConsoleVariableNames.Num() > 0)
		{
			return System::GetConsoleVariableIntValue(ConsoleVariableNames[0].ToString()) != 0;
		}

		bool bIsChecked = false;
		for(FName CVarName : ConsoleVariableNames)
		{
			if(System::GetConsoleVariableIntValue(CVarName.ToString()) != 0)
			{
				bIsChecked = true;
				break;
			}
		}

		return bIsChecked;
	}
};