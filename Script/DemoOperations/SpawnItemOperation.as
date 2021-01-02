// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

import Feather.DebugInterface.OperationBaseClasses.FeatherSpawnActorOperationBase;

// Some example items to work with.
UCLASS(Abstract)
class AExampleItem : AStaticMeshActor {};

// Allows you to spawn items at the cursor
class USpawnItemAtCursorOperation : UFeatherSpawnActorOperationBase
{
    default SelectorBaseClass = AExampleItem::StaticClass();
};
