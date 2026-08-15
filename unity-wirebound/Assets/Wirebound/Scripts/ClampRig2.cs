using UnityEngine;

/// <summary>
/// ClampRig 2.0 — independent left (blue) / right (red) launcher hands.
/// LMB fires left, RMB fires right. Hold to keep stuck / held. Release retracts.
/// Stick both DualHandSocket components to open a gate.
/// </summary>
public class ClampRig2 : MonoBehaviour
{
    [Header("Refs")]
    public Camera cam;
    public Transform leftRest;
    public Transform rightRest;
    public LayerMask hitMask = ~0;

    [Header("Tune")]
    public float range = 28f;
    public float flySpeed = 90f;
    public float pullForce = 22f;
    public float retractSpeed = 48f;

    readonly Hand left = new Hand();
    readonly Hand right = new Hand();
    CharacterController body;
    Vector3 extraVel;

    sealed class Hand
    {
        public string id;
        public Color color;
        public Transform rest;
        public Transform visual;
        public LineRenderer cable;
        public enum State { Holstered, Flying, Stuck, Holding, Retract }
        public State state = State.Holstered;
        public Vector3 flyFrom, flyTo;
        public float flyT;
        public Vector3 stuckPoint;
        public DualHandSocket socket;
        public Grabable held;
        public RaycastHit pending;
        public bool hasPending;
    }

    void Awake()
    {
        if (!cam) cam = Camera.main;
        body = GetComponentInParent<CharacterController>();
        Build(left, "left", new Color(0.23f, 0.63f, 1f), leftRest);
        Build(right, "right", new Color(1f, 0.23f, 0.23f), rightRest);
    }

    void Build(Hand h, string id, Color color, Transform rest)
    {
        h.id = id;
        h.color = color;
        h.rest = rest;
        var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
        go.name = "Hand_" + id;
        go.transform.SetParent(transform.root, true);
        go.transform.localScale = new Vector3(0.09f, 0.05f, 0.12f);
        Object.Destroy(go.GetComponent<Collider>());
        var r = go.GetComponent<Renderer>();
        r.material = new Material(Shader.Find("Universal Render Pipeline/Lit"));
        r.material.color = color;
        r.material.EnableKeyword("_EMISSION");
        r.material.SetColor("_EmissionColor", color * 1.4f);
        h.visual = go.transform;

        var cableGo = new GameObject("Cable_" + id);
        h.cable = cableGo.AddComponent<LineRenderer>();
        h.cable.positionCount = 2;
        h.cable.startWidth = 0.012f;
        h.cable.endWidth = 0.012f;
        h.cable.material = new Material(Shader.Find("Sprites/Default"));
        h.cable.startColor = h.cable.endColor = color;
    }

    void Update()
    {
        if (Cursor.lockState != CursorLockMode.Locked) return;

        if (Input.GetMouseButtonDown(0)) Fire(left);
        if (Input.GetMouseButtonUp(0)) Release(left);
        if (Input.GetMouseButtonDown(1)) Fire(right);
        if (Input.GetMouseButtonUp(1)) Release(right);

        Step(left);
        Step(right);
        extraVel = Vector3.Lerp(extraVel, Vector3.zero, 1f - Mathf.Exp(-4f * Time.deltaTime));
    }

    public Vector3 ConsumePull()
    {
        var v = extraVel;
        return v;
    }

    void Fire(Hand h)
    {
        if (h.state == Hand.State.Flying) return;
        var ray = cam.ViewportPointToRay(new Vector3(0.5f, 0.5f, 0));
        h.flyFrom = h.rest ? h.rest.position : cam.transform.position;
        h.hasPending = Physics.Raycast(ray, out h.pending, range, hitMask, QueryTriggerInteraction.Ignore);
        h.flyTo = h.hasPending ? h.pending.point : ray.GetPoint(range);
        h.flyT = 0;
        h.state = Hand.State.Flying;
        h.visual.gameObject.SetActive(true);
    }

    void Release(Hand h)
    {
        if (h.held) h.held.heldBy = null;
        if (h.socket) h.socket.charged = false;
        h.held = null;
        h.socket = null;
        h.state = Hand.State.Retract;
    }

    void Step(Hand h)
    {
        var origin = h.rest ? h.rest.position : cam.transform.position;
        h.cable.SetPosition(0, origin);

        if (h.state == Hand.State.Holstered)
        {
            h.visual.position = origin;
            h.visual.rotation = cam.transform.rotation;
            h.cable.SetPosition(1, origin);
            h.cable.enabled = false;
            return;
        }

        h.cable.enabled = true;

        if (h.state == Hand.State.Flying)
        {
            float dist = Vector3.Distance(h.flyFrom, h.flyTo);
            h.flyT += Time.deltaTime * flySpeed / Mathf.Max(0.2f, dist);
            h.visual.position = Vector3.Lerp(h.flyFrom, h.flyTo, Mathf.Clamp01(h.flyT));
            h.visual.LookAt(h.flyTo);
            h.cable.SetPosition(1, h.visual.position);
            if (h.flyT >= 1f) Land(h);
            return;
        }

        if (h.state == Hand.State.Stuck)
        {
            h.visual.position = h.stuckPoint;
            h.visual.LookAt(origin);
            h.cable.SetPosition(1, h.stuckPoint);
            var to = h.stuckPoint - transform.position;
            to.y = 0f;
            if (to.magnitude > 1.4f) extraVel += to.normalized * pullForce * Time.deltaTime;
            return;
        }

        if (h.state == Hand.State.Holding && h.held)
        {
            var hold = origin + cam.transform.forward * 2.1f;
            hold.y = Mathf.Max(0.45f, hold.y);
            h.held.transform.position = Vector3.Lerp(h.held.transform.position, hold, 1f - Mathf.Exp(-12f * Time.deltaTime));
            h.visual.position = h.held.transform.position;
            h.cable.SetPosition(1, h.visual.position);
            return;
        }

        if (h.state == Hand.State.Retract)
        {
            h.visual.position = Vector3.MoveTowards(h.visual.position, origin, retractSpeed * Time.deltaTime);
            h.cable.SetPosition(1, h.visual.position);
            if ((h.visual.position - origin).sqrMagnitude < 0.04f)
                h.state = Hand.State.Holstered;
        }
    }

    void Land(Hand h)
    {
        if (!h.hasPending)
        {
            h.state = Hand.State.Retract;
            return;
        }

        var grab = h.pending.collider.GetComponentInParent<Grabable>();
        var sock = h.pending.collider.GetComponentInParent<DualHandSocket>();
        if (grab)
        {
            h.state = Hand.State.Holding;
            h.held = grab;
            grab.heldBy = h.id;
            return;
        }
        if (sock)
        {
            h.state = Hand.State.Stuck;
            h.stuckPoint = h.pending.point;
            h.socket = sock;
            sock.charged = true;
            return;
        }
        h.state = Hand.State.Stuck;
        h.stuckPoint = h.pending.point;
    }
}
