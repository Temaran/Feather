#if !RELEASE
import Feather.DebugInterface.FeatherDebugInterfaceOperation;

// These operations have no AS code, and is completely implemented in UMG. You have to override GetViewRoot() however. Just put your root widget in there!
// Also, don't forget to set your operation tags in the Class Defaults!
UCLASS(Abstract)
class UFeatherUMGOnlyOperationBase : UFeatherDebugInterfaceOperation
{
	UFUNCTION(BlueprintEvent)
	UWidget GetViewRoot() { return nullptr; }

	UFUNCTION(BlueprintOverride)
	void ConstructOperation(UNamedSlot OperationRoot)
	{
		OperationRoot.SetContent(GetViewRoot());
	}
};
#endif // RELEASE
