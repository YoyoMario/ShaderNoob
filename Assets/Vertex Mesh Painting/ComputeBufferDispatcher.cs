using Unity.Collections;
using UnityEngine;

[RequireComponent(typeof(MeshRenderer), typeof(MeshFilter))]
public class ComputeBufferDispatcher : MonoBehaviour
{
    private const string KERNEL_NAME = "CSMain";
    private const string COMPUTE_VERTEX_BUFFER_NAME = "_VertexBuffer";
    private const string COMPUTE_COLOR_BUFFER_NAME = "_ColorBuffer";
    private const string COMPUTE_VERTEX_COUNT_NAME = "_VertexCount";
    private const string SHADER_COLOR_BUFFER_NAME = "_ColorBuffer";

    [SerializeField] private ComputeShader _computeShader = default;
    [SerializeField] private Transform _painterSphere = default;

    private MeshFilter _meshFilter = default;
    private MeshRenderer _meshRenderer = default;
    private Material _material = default;
    private int _vertexCount = default;

    private int _kernelID = default;
    private int _threadGroups = default;
    private ComputeBuffer _vertexBuffer = default;
    private ComputeBuffer _colorBuffer = default;

    private MeshFilter MeshFilter
    {
        get
        {
            if (_meshFilter == null)
            {
                _meshFilter = GetComponent<MeshFilter>();
            }
            return _meshFilter;
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
                _vertexCount = MeshFilter.sharedMesh.vertexCount;
            }
            return _vertexCount;
        }
    }

    private void OnDrawGizmos()
    {
        if (!_painterSphere)
        {
            return;
        }

        Gizmos.DrawWireSphere(_painterSphere.position, _painterSphere.localScale.x/2f);
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
        _kernelID = _computeShader.FindKernel(KERNEL_NAME);
        _computeShader.GetKernelThreadGroupSizes(_kernelID, out uint threadGroupX, out uint thredGroupY, out uint threadGroupZ);
        _threadGroups = Mathf.CeilToInt((float)VertexCount / threadGroupX);

        using (Mesh.MeshDataArray meshDataArray = Mesh.AcquireReadOnlyMeshData(MeshFilter.sharedMesh))
        {
            Mesh.MeshData meshData = meshDataArray[0];
            using (NativeArray<Vector3> vertexArray = new NativeArray<Vector3>(VertexCount, Allocator.TempJob, NativeArrayOptions.UninitializedMemory))
            {
                meshData.GetVertices(vertexArray);
                _vertexBuffer.SetData(vertexArray);
            }
        }

        _computeShader.SetBuffer(_kernelID, COMPUTE_VERTEX_BUFFER_NAME, _vertexBuffer);
        _computeShader.SetBuffer(_kernelID, COMPUTE_COLOR_BUFFER_NAME, _colorBuffer);
        _computeShader.SetInt(COMPUTE_VERTEX_COUNT_NAME, VertexCount);

        Material.SetBuffer(SHADER_COLOR_BUFFER_NAME, _colorBuffer);
    }

    private void Update()
    {
        _computeShader.SetMatrix("_LocalToWorld", transform.localToWorldMatrix);
        _computeShader.SetVector("_Sphere", new Vector4(_painterSphere.position.x, _painterSphere.position.y, _painterSphere.position.z, _painterSphere.localScale.x/2));

        _computeShader.Dispatch(_kernelID, _threadGroups, 1, 1);
    }
}
