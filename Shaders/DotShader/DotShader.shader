/*
Copyright 2018 Cassaundra Smith

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

cassaundra@actuallyeverything.com
*/
Shader "Custom/DotShader" {
	Properties {
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color", Color) = (0.5,0.5,0.5,1)
		_DotCount("Dot Count", Float ) = 20
		_AddDotRadius("Add Dot Radius", Range(0, 0.293)) = 0
		_Angle("Angle", Range(0, 90)) = 0.0
		_ShadowAlpha("Shadow Alpha", Range(0, 1)) = 0.1
		_ShadowColorBurn("Shadow Color Burn", Range(0, 10)) = 1.0
		_ShadowPower("Shadow Power", Float) = 0.0
		_ShadowTightness("Shadow Tightness", Range(0.001, 10)) = 1.0
	}

	SubShader {

		Tags {
			"RenderType"="Opaque"
		}

		Pass {
			Name "FORWARD"
			Tags {
				"LightMode"="ForwardBase"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define UNITY_PASS_FORWARDBASE
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			// #include "../Aura/Shaders/Aura.cginc"
			#pragma multi_compile_fwdbase_fullshadows
			#pragma multi_compile_fog
			#pragma target 3.0

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float _DotCount;
			float _AddDotRadius;
			float _Angle;
			float _ShadowAlpha;
			float _ShadowColorBurn;
			float _ShadowPower;
			float _ShadowTightness;

			float4 _LightColor0;

			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
				float4 projPos : TEXCOORD2;
				float2 uv : TEXCOORD6;
				LIGHTING_COORDS(3,4)
				UNITY_FOG_COORDS(5)
			};

			VertexOutput vert (VertexInput v) {
				VertexOutput o = (VertexOutput)0;
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.pos = UnityObjectToClipPos( v.vertex );


				UNITY_TRANSFER_FOG(o,o.pos);
				o.projPos = ComputeScreenPos (o.pos);
				COMPUTE_EYEDEPTH(o.projPos.z);
				TRANSFER_VERTEX_TO_FRAGMENT(o);

							//o.frustumSpacePosition = Aura_GetFrustumSpaceCoordinates(v.vertex);


				o.uv = TRANSFORM_TEX(v.uv, _MainTex);


				return o;
			}
			float4 frag(VertexOutput i) : COLOR {
				float3 normalDirection = normalize(i.normalDir);

				float2 sceneUVs = (i.projPos.xy / i.projPos.w);
				sceneUVs /= max(_ScreenParams.x, _ScreenParams.y);

				if(_Angle != 0.0) {
					_Angle = radians(_Angle);

					sceneUVs.x *= _ScreenParams.x/_ScreenParams.y;

					float2 pivot = float2(0.5, 0.5);

					float cosAngle = cos(_Angle);
					float sinAngle = sin(_Angle);
					float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
 
					float2 uv = sceneUVs.xy - pivot;
					sceneUVs.xy = mul(rot, uv);
					sceneUVs += pivot;
					sceneUVs.x /= _ScreenParams.x/_ScreenParams.y;
				}

				float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
				float attenuation = LIGHT_ATTENUATION(i);
				float NdotL = max(0, _ShadowPower+dot(normalDirection, lightDirection));
				float3 lighting = max(0.0, pow(NdotL+.5, _ShadowTightness)-.5) * attenuation * _LightColor0.a;

				lighting = pow(lighting, 1);

				float2 cellPos = frac((sceneUVs.rg*(1.0/float2(_ScreenParams.z-1, _ScreenParams.w-1).rg) * _DotCount)); // position in emergent grid cell
				float distanceFromCenter = distance(cellPos, float2(0.5,0.5)); // distance from center
				float circleRadius = (0.708*(1.0 - lighting)) + _AddDotRadius; // circle radius

				float4 finalRGBA = tex2D(_MainTex, i.uv) * _Color; // draw normally
				if(circleRadius > .6 || distanceFromCenter < circleRadius) {
			   		finalRGBA = pow(tex2D(_MainTex, i.uv), _ShadowColorBurn) * _ShadowAlpha * _Color; // draw with shadow
				}

				UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
				return finalRGBA;
			}
			ENDCG
		}

		Pass {
			Name "FORWARD_DELTA"
			Tags {
				"LightMode"="ForwardAdd"
			}

			BlendOp Max
			Blend One One

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#define UNITY_PASS_FORWARDADD
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog
			#pragma target 3.0

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
			float _DotCount;
			float _AddDotRadius;
			float _Angle;
			float _ShadowAlpha;
			float _ShadowColorBurn;
			float _ShadowPower;
			float _ShadowTightness;

			float4 _LightColor0;

			struct VertexInput {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};
			struct VertexOutput {
				float4 pos : SV_POSITION;
				float4 posWorld : TEXCOORD0;
				float3 normalDir : TEXCOORD1;
				float4 projPos : TEXCOORD2;
				float2 uv : TEXCOORD6;
				LIGHTING_COORDS(3,4)
				UNITY_FOG_COORDS(5)
			};

			VertexOutput vert (VertexInput v) {
				VertexOutput o = (VertexOutput)0;
				o.normalDir = UnityObjectToWorldNormal(v.normal);
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.pos = UnityObjectToClipPos( v.vertex );
				UNITY_TRANSFER_FOG(o,o.pos);
				o.projPos = ComputeScreenPos (o.pos);
				COMPUTE_EYEDEPTH(o.projPos.z);
				TRANSFER_VERTEX_TO_FRAGMENT(o);


				o.uv = TRANSFORM_TEX(v.uv, _MainTex);

				return o;
			}
			float4 frag(VertexOutput i) : COLOR {
				float3 normalDirection = normalize(i.normalDir);

				float2 sceneUVs = (i.projPos.xy / i.projPos.w);
				sceneUVs /= max(_ScreenParams.x, _ScreenParams.y);

				if(_Angle != 0.0) {
					_Angle = radians(_Angle);

					sceneUVs.x *= _ScreenParams.x/_ScreenParams.y;

					float2 pivot = float2(0.5, 0.5);

					float cosAngle = cos(_Angle);
					float sinAngle = sin(_Angle);
					float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
 
					float2 uv = sceneUVs.xy - pivot;
					sceneUVs.xy = mul(rot, uv);
					sceneUVs += pivot;
					sceneUVs.x /= _ScreenParams.x/_ScreenParams.y;
				}

				float3 lightDirection = normalize(lerp(_WorldSpaceLightPos0.xyz, _WorldSpaceLightPos0.xyz - i.posWorld.xyz,_WorldSpaceLightPos0.w));
				// float attenuation = LIGHT_ATTENUATION(i);
				float NdotL = max(0, _ShadowPower+dot(normalDirection, lightDirection));
				float3 lighting = max(0.0, pow(NdotL+.5, _ShadowTightness)-.5) *  _LightColor0.a;

				lighting = pow(lighting, 1);

				float2 cellPos = frac((sceneUVs.rg*(1.0/float2(_ScreenParams.z-1, _ScreenParams.w-1).rg) * _DotCount)); // position in emergent grid cell
				float distanceFromCenter = distance(cellPos, float2(0.5,0.5)); // distance from center
				float circleRadius = (0.708*(1.0 - lighting)) + _AddDotRadius; // circle radius

				float4 finalRGBA = tex2D(_MainTex, i.uv) * _Color; // draw normally
				if(circleRadius > .6 || distanceFromCenter < circleRadius) {
			   		finalRGBA = pow(tex2D(_MainTex, i.uv), _ShadowColorBurn) * _ShadowAlpha * _Color; // draw with shadow
				}

				//Aura Support
				//Aura_ApplyLighting(color, i.frustumSpacePosition, 1.0f);
				//Aura_ApplyFog(color, i.frustumSpacePosition);
				UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
				return finalRGBA;
			}
			ENDCG
		}
	}

	FallBack "Toon/Lit"
}