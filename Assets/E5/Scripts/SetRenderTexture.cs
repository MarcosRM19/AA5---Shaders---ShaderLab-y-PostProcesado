using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class SetRenderTexture : MonoBehaviour
{
    [SerializeField] RenderTexture rt;
    [SerializeField] Transform target;
    
    void Awake()
    {
        Shader.SetGlobalTexture("_GlobalEffectRT", rt);
        Shader.SetGlobalFloat("_OrthographicCamSize", GetComponent<Camera>().orthographicSize);
    }
 
    private void Update()
    {
        Shader.SetGlobalVector("_Position", transform.position);
    }
}
