using UnityEngine;
[ExecuteInEditMode]

public class ActiveCamera : MonoBehaviour
{
    private void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
    }
}
