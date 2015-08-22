
struct VSInput
{	
	float4 position : POSITION;
	float3 normal : NORMAL;
};

struct VSOutput
{
	float4 screenPos : SV_Position;
	float4 color : COLOR;
	float2 texCoord : TEXCOORD0;
	float2 texCoordProj : TEXCOORD1;
	float3 normal : TEXCOORD2;
	float3 view : TEXCOORD3;
};

cbuffer Constants
{
	float4x4 mViewProj;
	float4x4 mWorld;
	float4x4 mWorldInv;
	float shininess;
	float overbright;
	float2 projScroll;
	float rim;
};

float3 LightVertex(
	float3 position,
	float3 normal,
	float3 view,
	float3 lightPos,
	float3 lightColor)
{
	// Directional light with a little ambient.
	float3 L = normalize(lightPos - position);
	float diffuse = 0.1f + 0.9f*max(dot(normal, L), 0.f);

	// Calculate basic specular reflection.
	float3 V = normalize(view - position);
	float3 H = normalize(L + V);
	float specular = overbright*pow(max(dot(normal, H), 0), shininess);

	return overbright*(lightColor*diffuse + specular); // Monochromatic specular.
}	

VSOutput MainVS(VSInput input)
{ 
	VSOutput output;

	float4 worldPos = mul(input.position, mWorld);
	float3 worldNormal = mul(input.normal, (float3x3) mWorld);
	float3 lightPos = mul(float3(0.f, 0.f, 1.f), (float3x3) mWorld);
	float3 view = normalize(mViewProj._41_42_43 - worldPos.xyz);

	output.screenPos = mul(worldPos, mViewProj);
	output.color = float4(LightVertex(worldPos.xyz, worldNormal, view, lightPos, float3(1.f, 1.f, 1.f)), 1.f);
	output.texCoord = worldNormal.xy*0.5f + 0.5f;
	output.texCoordProj = worldPos.xy + projScroll;
	output.normal = worldNormal;
	output.view = view;

	return output;
}

Texture2D envMap;
Texture2D projMap;

SamplerState samplerTexture
{
	AddressU = WRAP;
	AddressV = WRAP;
	Filter = MIN_MAG_MIP_LINEAR;
};

float4 MainPS(VSOutput input) : SV_Target0
{
	float viewFacing = dot(normalize(input.view), normalize(input.normal));
	float _rim = saturate((viewFacing-0.2f)*8.f);
	_rim = lerp(1.f, _rim, rim);

	float4 baseColor = envMap.Sample(samplerTexture, input.texCoord);
	float4 projColor = projMap.Sample(samplerTexture, input.texCoordProj);

	return baseColor*projColor*input.color*float4(_rim.xxx,1.0);
}


technique11 Blobs
{
	pass Default
	{
		SetVertexShader(CompileShader(vs_4_0, MainVS()));
		 SetPixelShader(CompileShader(ps_4_0, MainPS()));		
	}
}
