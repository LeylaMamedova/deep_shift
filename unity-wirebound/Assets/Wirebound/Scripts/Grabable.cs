using UnityEngine;

public class Grabable : MonoBehaviour
{
    public string kind = "crate";
    [HideInInspector] public string heldBy;
}

public class DualHandSocket : MonoBehaviour
{
    public bool charged;
    DualHandGate gate;

    void Awake() => gate = GetComponentInParent<DualHandGate>();
    void Update()
    {
        var r = GetComponent<Renderer>();
        if (r) r.material.SetColor("_EmissionColor", (charged ? 2.2f : 0.4f) * r.material.color);
        gate?.Tick();
    }
}

public class DualHandGate : MonoBehaviour
{
    public Transform doorLeft;
    public Transform doorRight;
    public DualHandSocket[] sockets;
    public Collider block;
    bool open;

    public void Tick()
    {
        if (open || sockets == null || sockets.Length < 2) return;
        foreach (var s in sockets) if (!s || !s.charged) return;
        open = true;
        if (block) block.enabled = false;
    }

    void Update()
    {
        if (!open) return;
        if (doorLeft) doorLeft.localPosition = Vector3.Lerp(doorLeft.localPosition, new Vector3(-3.1f, doorLeft.localPosition.y, 0f), Time.deltaTime * 2.5f);
        if (doorRight) doorRight.localPosition = Vector3.Lerp(doorRight.localPosition, new Vector3(3.1f, doorRight.localPosition.y, 0f), Time.deltaTime * 2.5f);
    }
}
