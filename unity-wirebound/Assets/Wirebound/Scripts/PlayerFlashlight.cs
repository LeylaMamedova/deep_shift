using UnityEngine;

public class PlayerFlashlight : MonoBehaviour
{
    public Light spot;
    public KeyCode toggle = KeyCode.F;
    bool on = true;

    void Awake()
    {
        if (!spot)
        {
            var go = new GameObject("Flashlight");
            go.transform.SetParent(transform, false);
            go.transform.localPosition = new Vector3(0.12f, -0.08f, 0.15f);
            spot = go.AddComponent<Light>();
            spot.type = LightType.Spot;
            spot.color = new Color(1f, 0.94f, 0.8f);
            spot.range = 24f;
            spot.spotAngle = 44f;
            spot.intensity = 8f;
            spot.shadows = LightShadows.Soft;
        }
        Apply();
    }

    void Update()
    {
        if (Input.GetKeyDown(toggle))
        {
            on = !on;
            Apply();
        }
        if (on && Random.value < 0.01f) spot.intensity = Random.Range(2f, 8f);
        else if (on) spot.intensity = 8f;
    }

    void Apply()
    {
        if (spot) spot.enabled = on;
    }
}
