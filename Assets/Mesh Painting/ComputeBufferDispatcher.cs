using UnityEngine;

[RequireComponent(typeof(MeshRenderer), typeof(MeshFilter))]
public class ComputeBufferDispatcher : MonoBehaviour
{
    [SerializeField] private ComputeShader _computeShader = default;
    [SerializeField] private Transform _painterSphere = default;

    private Mesh _mesh = default;
    private MeshRenderer _meshRenderer = default;
    private Material _material = default;
    private int _vertexCount = default;

    private int _kernelID = default;
    private int _threadGroups = default;
    private ComputeBuffer _vertexBuffer = default;
    private ComputeBuffer _colorBuffer = default;

    private Mesh Mesh
    {
        get
        {
            if (_mesh == null)
            {
                _mesh = GetComponent<Mesh>();
            }
            return _mesh;
        }
    }
    private MeshRenderer MeshRenderer
    {
        get
        {
            if (_meshRenderer == null)
            {
                _meshRenderer = GetComponent<MeshRenderer>();
            }
            return _meshRenderer;
        }
    }
    private Material Material
    {
        get
        {
            if (_material == null)
            {
                _material = MeshRenderer.sharedMaterial;
            }
            return _material;
        }
    }
    private int VertexCount
    {
        get
        {
            if (_vertexCount == 0)
            {
                _vertexCount = Mesh.vertexCount;
            }
            return _vertexCount;
        }
    }

    private void OnEnable()
    {
        _vertexBuffer = new ComputeBuffer(VertexCount, sizeof(float) * 3);
        _colorBuffer = new ComputeBuffer(VertexCount, sizeof(float) * 4);

        InitializeComputeShader();
    }

    private void OnDisable()
    {
        _vertexBuffer?.Dispose();
        _vertexBuffer = null;
        _colorBuffer?.Dispose();
        _colorBuffer = null;
    }

    private void InitializeComputeShader()
    {

    }
}
