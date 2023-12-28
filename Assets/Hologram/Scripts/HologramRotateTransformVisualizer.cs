using UnityEngine;

public class HologramRotateTransformVisualizer : MonoBehaviour
{
    [SerializeField] private float _rotateSpeed = 2;

    void Update()
    {

        Quaternion rotation = transform.rotation;
        Quaternion localRotation = Quaternion.Euler(Vector3.up * (_rotateSpeed * Time.deltaTime));
        transform.rotation = localRotation * transform.rotation;
    }
}
