using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SetPosition : MonoBehaviour
{
    [SerializeField] RenderTexture renderTexture;
    
    void Awake()
    {
        Shader.SetGlobalTexture("_RenderTexture", renderTexture);
        Shader.SetGlobalFloat("_OrthographicCamera", GetComponent<Camera>().orthographicSize);
    }
 
    private void Update()
    {
        Shader.SetGlobalVector("_Position", transform.position);
    }
}
