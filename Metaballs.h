
#pragma once

#include "EffectPass.h"
#include "Nodes/Camera.h"
#include "Nodes/Xform.h"

namespace Pimp 
{
	class Metaballs : public boost::noncopyable
	{
	public:
		// Structure fit for a vertical SSE transform, so no XYZ but XXXX, YYYYY, ZZZZ.
		// 16-byte alignment required.
		__declspec(align(16)) struct Metaball4
		{
			float X[4];
			float Y[4];
			float Z[4];
		};

		Metaballs();
		~Metaballs();

		bool Initialize();
		void Generate(unsigned int numBall4s, const Metaball4 &balls, float surfaceLevel);
		void Draw(Camera* camera);
		
		void SetRotation(const Quaternion &rotation);
		void SetMaps(Texture2D *envMap, Texture2D *projMap, float projScrollU = 0.f, float projScrollV = 0.f); // (*)
		void SetLighting(float shininess, float overbright);
		void SetRim(float rim);

		// (*) A 2D projection texture (projMap in SetMaps()) is optional.
		//     The (default) shader modulates the environment map (base) color.

	private:
		ID3D11Buffer *pVB, *pIB;
		ID3D11InputLayout *inputLayout;

		Effect effect;
		EffectTechnique effectTechnique;
		EffectPass effectPass;

		int varIndexEnvMap;
		int varIndexProjMap;
		int varIndexViewProjMatrix;
		int varIndexWorldMatrix;
		int varIndexWorldMatrixInv;
		int varIndexShininess;
		int varIndexOverbright;
		int varIndexProjScroll;
		int varIndexRim;

		bool isVisible;

		Xform *worldTrans;
		Texture2D *envMap, *projMap;
		float projScrollU, projScrollV;
		float shininess;
		float overbright;
		float rim;

		/* __forceinline */ unsigned int GetEdgeTableIndex();
		float CalculateIsoValue(unsigned int iGrid, float gridX, float gridY, float gridZ);
		void ProcessCube(unsigned int iGrid, unsigned int iX, unsigned int iY, unsigned int iZ);
		void Triangulate(unsigned int iGrid, float gridX, float gridY, float gridZ, unsigned int iEdgeTab, unsigned int edgeBits);
	};
}
