using UnityEngine;

/// <summary>
/// Builds a red-lit factory hall at play time so you can test ClampRig 2.0 without placing art.
/// Replace primitives with your own meshes when you have them.
/// </summary>
public class FactoryGenerator : MonoBehaviour
{
    public Transform playerSpawn;
    public GameObject hushhornPrefab;

    void Start()
    {
        BuildHall();
        SpawnPlayer();
        SpawnStalker();
        SpawnGate();
        SpawnCrates();
        Lighting();
    }

    void Lighting()
    {
        var sun = new GameObject("RedKey").AddComponent<Light>();
        sun.type = LightType.Spot;
        sun.color = new Color(1f, 0.18f, 0.28f);
        sun.intensity = 18f;
        sun.range = 40f;
        sun.spotAngle = 90f;
        sun.shadows = LightShadows.Soft;
        sun.transform.position = new Vector3(0f, 6f, 12f);
        sun.transform.LookAt(new Vector3(0f, 0f, 20f));
        RenderSettings.fog = true;
        RenderSettings.fogColor = new Color(0.08f, 0.01f, 0.02f);
        RenderSettings.fogDensity = 0.04f;
    }

    void BuildHall()
    {
        Floor(new Vector3(0, 0, 24), new Vector3(12, 1, 56));
        Wall(new Vector3(-4.2f, 2.3f, 24), new Vector3(0.35f, 4.6f, 52));
        Wall(new Vector3(4.2f, 2.3f, 24), new Vector3(0.35f, 4.6f, 52));
        Wall(new Vector3(0, 2.3f, -1.2f), new Vector3(8.6f, 4.6f, 0.4f));
        for (int i = 0; i < 7; i++)
        {
            var lamp = GameObject.CreatePrimitive(PrimitiveType.Cube);
            lamp.transform.position = new Vector3(0f, 4.35f, 6f + i * 7f);
            lamp.transform.localScale = new Vector3(0.5f, 0.12f, 0.9f);
            var mat = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            mat.EnableKeyword("_EMISSION");
            mat.SetColor("_EmissionColor", new Color(2f, 0.15f, 0.25f));
            lamp.GetComponent<Renderer>().material = mat;
            var l = lamp.AddComponent<Light>();
            l.type = LightType.Point;
            l.color = new Color(1f, 0.2f, 0.3f);
            l.intensity = 6f;
            l.range = 10f;
            l.shadows = LightShadows.Soft;
        }
    }

    void SpawnPlayer()
    {
        var p = GameObject.Find("Player");
        if (p) return;
        p = new GameObject("Player");
        p.transform.position = playerSpawn ? playerSpawn.position : new Vector3(0f, 1f, 2.5f);
        p.AddComponent<CharacterController>();
        var camGo = new GameObject("Camera");
        camGo.transform.SetParent(p.transform);
        camGo.transform.localPosition = new Vector3(0f, 0.62f, 0f);
        camGo.AddComponent<Camera>();
        camGo.AddComponent<AudioListener>();
        camGo.AddComponent<GraphicsBootstrap>();
        camGo.AddComponent<PlayerFlashlight>();
        var left = new GameObject("LeftRest").transform;
        var right = new GameObject("RightRest").transform;
        left.SetParent(camGo.transform);
        right.SetParent(camGo.transform);
        left.localPosition = new Vector3(-0.28f, -0.22f, 0.42f);
        right.localPosition = new Vector3(0.28f, -0.22f, 0.42f);
        var rig = camGo.AddComponent<ClampRig2>();
        rig.cam = camGo.GetComponent<Camera>();
        rig.leftRest = left;
        rig.rightRest = right;
        p.AddComponent<FirstPersonMotor>().head = camGo.transform;
    }

    void SpawnStalker()
    {
        GameObject h;
        if (hushhornPrefab) h = Instantiate(hushhornPrefab);
        else
        {
            h = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            h.name = "Hushhorn";
            h.transform.localScale = new Vector3(1.2f, 1.4f, 1.6f);
        }
        h.transform.position = new Vector3(0f, 1f, 34f);
        if (!h.GetComponent<CharacterController>()) h.AddComponent<CharacterController>();
        var ai = h.GetComponent<HushhornAI>() ?? h.AddComponent<HushhornAI>();
        var player = GameObject.Find("Player");
        if (player) ai.target = player.transform;
    }

    void SpawnGate()
    {
        var gate = new GameObject("Gate");
        gate.transform.position = new Vector3(0f, 0f, 40f);
        var g = gate.AddComponent<DualHandGate>();
        g.doorLeft = Box("DoorL", gate.transform, new Vector3(-1.05f, 1.8f, 0f), new Vector3(2.05f, 3.6f, 0.18f)).transform;
        g.doorRight = Box("DoorR", gate.transform, new Vector3(1.05f, 1.8f, 0f), new Vector3(2.05f, 3.6f, 0.18f)).transform;
        g.block = g.doorLeft.GetComponent<Collider>();
        var s1 = Socket(gate.transform, new Vector3(-1.55f, 1.6f, 0.22f), Color.blue);
        var s2 = Socket(gate.transform, new Vector3(1.55f, 1.6f, 0.22f), Color.red);
        g.sockets = new[] { s1, s2 };
    }

    void SpawnCrates()
    {
        Vector3[] spots = { new(-1.6f, 0.4f, 8f), new(1.7f, 0.4f, 14f), new(-1.4f, 0.4f, 22f) };
        foreach (var s in spots)
        {
            var c = GameObject.CreatePrimitive(PrimitiveType.Cube);
            c.transform.position = s;
            c.transform.localScale = Vector3.one * 0.8f;
            c.AddComponent<Grabable>();
        }
    }

    static DualHandSocket Socket(Transform parent, Vector3 local, Color color)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        go.transform.SetParent(parent);
        go.transform.localPosition = local;
        go.transform.localScale = new Vector3(0.32f, 0.06f, 0.32f);
        go.transform.localRotation = Quaternion.Euler(90f, 0f, 0f);
        var mat = new Material(Shader.Find("Universal Render Pipeline/Lit"));
        mat.color = color;
        mat.EnableKeyword("_EMISSION");
        mat.SetColor("_EmissionColor", color);
        go.GetComponent<Renderer>().material = mat;
        return go.AddComponent<DualHandSocket>();
    }

    static GameObject Box(string name, Transform parent, Vector3 pos, Vector3 scale)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        go.name = name;
        go.transform.SetParent(parent);
        go.transform.localPosition = pos;
        go.transform.localScale = scale;
        return go;
    }

    static void Floor(Vector3 pos, Vector3 scale)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        go.name = "Floor";
        go.transform.position = pos;
        go.transform.localScale = scale;
        var mat = new Material(Shader.Find("Universal Render Pipeline/Lit"));
        mat.color = new Color(0.08f, 0.07f, 0.09f);
        mat.SetFloat("_Metallic", 0.75f);
        mat.SetFloat("_Smoothness", 0.72f);
        go.GetComponent<Renderer>().material = mat;
    }

    static void Wall(Vector3 pos, Vector3 scale)
    {
        var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        go.transform.position = pos;
        go.transform.localScale = scale;
        go.GetComponent<Renderer>().material.color = new Color(0.22f, 0.1f, 0.1f);
    }
}
