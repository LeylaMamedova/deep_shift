using UnityEngine;

[RequireComponent(typeof(CharacterController))]
public class FirstPersonMotor : MonoBehaviour
{
    public float walk = 5.1f;
    public float sprint = 7.4f;
    public float mouse = 1.6f;
    public Transform head;
    ClampRig2 rig;
    CharacterController cc;
    float pitch;
    float stamina = 100f;
    Vector3 pull;

    void Awake()
    {
        cc = GetComponent<CharacterController>();
        rig = GetComponentInChildren<ClampRig2>();
        if (!head) head = GetComponentInChildren<Camera>()?.transform;
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Escape))
        {
            Cursor.lockState = Cursor.lockState == CursorLockMode.Locked
                ? CursorLockMode.None
                : CursorLockMode.Locked;
            Cursor.visible = Cursor.lockState != CursorLockMode.Locked;
        }
        if (Cursor.lockState != CursorLockMode.Locked) return;

        float mx = Input.GetAxis("Mouse X") * mouse;
        float my = Input.GetAxis("Mouse Y") * mouse;
        transform.Rotate(0f, mx, 0f);
        pitch = Mathf.Clamp(pitch - my, -78f, 78f);
        if (head) head.localRotation = Quaternion.Euler(pitch, 0f, 0f);

        var input = new Vector3(Input.GetAxisRaw("Horizontal"), 0f, Input.GetAxisRaw("Vertical"));
        if (input.sqrMagnitude > 1f) input.Normalize();
        bool sp = Input.GetKey(KeyCode.LeftShift) && stamina > 0f && input.sqrMagnitude > 0f;
        float speed = sp ? sprint : walk;
        if (sp) stamina = Mathf.Max(0f, stamina - 18f * Time.deltaTime);
        else stamina = Mathf.Min(100f, stamina + 12f * Time.deltaTime);

        var wish = transform.TransformDirection(input) * speed;
        if (rig) pull = Vector3.Lerp(pull, rig.ConsumePull(), 0.5f);
        cc.Move((wish + pull + Vector3.down * 8f) * Time.deltaTime);
    }
}
