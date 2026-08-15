using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

/// <summary>
/// Sharp cinematic menu matching a left-stack / right-art layout.
/// Put this on a Canvas. Assign buttons in the inspector, or let Awake wire by name.
/// </summary>
public class MainMenuController : MonoBehaviour
{
    public Button continueBtn;
    public Button newGameBtn;
    public Button settingsBtn;
    public Button creditsBtn;
    public Button quitBtn;
    public GameObject settingsPanel;
    public GameObject creditsPanel;
    public string gameScene = "Factory";

    const string SaveKey = "wirebound-unity-save";

    void Awake()
    {
        if (continueBtn) continueBtn.interactable = PlayerPrefs.HasKey(SaveKey);
        if (continueBtn) continueBtn.onClick.AddListener(() => SceneManager.LoadScene(gameScene));
        if (newGameBtn) newGameBtn.onClick.AddListener(() =>
        {
            PlayerPrefs.DeleteKey(SaveKey);
            SceneManager.LoadScene(gameScene);
        });
        if (settingsBtn) settingsBtn.onClick.AddListener(() => Toggle(settingsPanel));
        if (creditsBtn) creditsBtn.onClick.AddListener(() => Toggle(creditsPanel));
        if (quitBtn) quitBtn.onClick.AddListener(Application.Quit);
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;
    }

    void Toggle(GameObject panel)
    {
        if (!panel) return;
        bool on = !panel.activeSelf;
        if (settingsPanel) settingsPanel.SetActive(false);
        if (creditsPanel) creditsPanel.SetActive(false);
        panel.SetActive(on);
    }
}
