using UnityEngine;

/// <summary>Original stalker mascot. Place on a four-legged mesh of your own making.</summary>
[RequireComponent(typeof(CharacterController))]
public class HushhornAI : MonoBehaviour
{
    public Transform target;
    public float speed = 3.2f;
    public float catchRange = 1.35f;
    CharacterController cc;
    float bob;

    void Awake() => cc = GetComponent<CharacterController>();

    void Update()
    {
        if (!target) return;
        var to = target.position - transform.position;
        to.y = 0f;
        if (to.sqrMagnitude > 0.05f)
        {
            var dir = to.normalized;
            cc.Move((dir * speed + Vector3.down * 6f) * Time.deltaTime);
            transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(dir), Time.deltaTime * 6f);
        }
        bob += Time.deltaTime * 2.4f;
        var p = transform.position;
        p.y = Mathf.Sin(bob) * 0.05f;
        transform.position = p;
        if (to.magnitude < catchRange)
            Debug.Log("Hushhorn caught the player — hook your game-over UI here.");
    }
}
