#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

public static class WireboundMenu
{
    [MenuItem("Wirebound/Create Factory Test Scene Objects")]
    static void Create()
    {
        var go = new GameObject("WireboundBootstrap");
        go.AddComponent<FactoryGenerator>();
        Selection.activeGameObject = go;
        Undo.RegisterCreatedObjectUndo(go, "Wirebound bootstrap");
    }
}
#endif
