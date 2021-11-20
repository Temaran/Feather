// Copyright 2020 Cadic AB. All Rights Reserved.
// @URL     https://github.com/Temaran/Feather
// @Author  Fredrik Lindh [Temaran] (temaran@gmail.com)
////////////////////////////////////////////////////////////

// Some example items to work with.
UCLASS(Abstract)
class AExampleItem : AStaticMeshActor {};

#if !RELEASE
// Allows you to spawn items at the cursor
class UFeatherDemoSpawnItemAtCursorOperation : UFeatherSpawnActorOperationBase
{
    default SelectorBaseClass = AExampleItem::StaticClass();
};
#endif // RELEASE
