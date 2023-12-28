using System.Collections;
using UnityEngine;

[RequireComponent(typeof(Renderer))]
public class HologramDistortionVisualizer : MonoBehaviour
{
    private const string SHADER_KEY_WORD_VERTEX_DISTORT_AMOUNT = "_VertexDistortAmount";
    private const string SHADER_KEY_WORD_VERTEX_DISTORT_SPEED = "_VertexDistortSpeed";
    private const string SHADER_KEY_WORD_VERTEX_AMOUNT_OF_WOBBLES = "_AmountOfWobbles";

    [SerializeField] private float _delay = 0.1f;
    [Space]
    [SerializeField] private Vector2 _distortAmountMinimumMaximum = default;
    [SerializeField] private Vector2 _distortSpeedMinimumMaximum = default;
    [SerializeField] private Vector2 _worblesAmountMinimumMaximum = default;

    private Renderer _renderer = default;
    private Material _material = default;

    private Renderer Renderer
    {
        get
        {
            if (_renderer == null)
            {
                _renderer = GetComponent<Renderer>();
            }
            return _renderer;
        }
    }
    private Material Material
    {
        get
        {
            if (_material == null)
            {
                _material = Renderer.material;
            }
            return _material;
        }
    }

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            StartCoroutine(GlitchCoroutine(_delay, _distortAmountMinimumMaximum, SHADER_KEY_WORD_VERTEX_DISTORT_AMOUNT));
            StartCoroutine(GlitchCoroutine(_delay, _distortSpeedMinimumMaximum, SHADER_KEY_WORD_VERTEX_DISTORT_SPEED));
            StartCoroutine(GlitchCoroutine(_delay, _worblesAmountMinimumMaximum, SHADER_KEY_WORD_VERTEX_AMOUNT_OF_WOBBLES));
        }
    }
    private IEnumerator GlitchCoroutine(float delay, Vector2 minMax, string shaderVariableName)
    {
        Material.SetFloat(shaderVariableName, GetRandomFloat(minMax.x, minMax.y));
        yield return new WaitForSeconds(delay);
        Material.SetFloat(shaderVariableName, 0);
    }

    private float GetRandomFloat(float min, float max)
    {
        System.Random rng = new System.Random();

        // Perform arithmetic in double type to avoid overflowing
        double range = (double)max - (double)min;
        double sample = rng.NextDouble();
        double scaled = (sample * range) + min;
        return (float)scaled;
    }
}
