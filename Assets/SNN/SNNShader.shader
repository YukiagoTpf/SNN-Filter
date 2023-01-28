Shader "MyCustomURP/RenderFeature/SNN"
{
    Properties
    {
      _MainTex("MainTex",2D) = "white"{}
    }
        SubShader
    {
        Tags{"RenderPipeline" = "UniversalRenderPipeline"}

        Cull Off ZWrite Off ZTest Always
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
        float _half_width;
        float4 _MainTex_TexelSize;
        CBUFFER_END

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_SourceTex); // 原图
        SAMPLER(sampler_SourceTex);
        float CalcDistance(in float3 c0, in float3 c1)
        {
            float3 sub = c0 - c1;
            return dot(sub, sub);
        }

        // Symmetric Nearest Neighbor
        float3 SNN( float2 ScennUV,TEXTURE2D(mainTexture),SAMPLER(mainTextureSamper) )
        {
            
	        float2 src_size = _ScreenParams.xy;
            float2 inv_src_size = 1.0f / src_size;
            float2 uv = ScennUV;
            
            float3 c0 = SAMPLE_TEXTURE2D(mainTexture,mainTextureSamper,uv);
            
            float4 sum = float4(0.0f, 0.0f, 0.0f, 0.0f);
            
            for (int i = 0; i <= _half_width; ++i) {
                float3 c1 = SAMPLE_TEXTURE2D(mainTexture,mainTextureSamper, uv + float2(+i, 0) * inv_src_size).rgb;
                float3 c2 = SAMPLE_TEXTURE2D(mainTexture,mainTextureSamper, uv + float2(-i, 0) * inv_src_size).rgb;
                
                float d1 = CalcDistance(c1, c0);
                float d2 = CalcDistance(c2, c0);
                if (d1 < d2) {
                    sum.rgb += c1;
                } else {
                    sum.rgb += c2;
                }
                sum.a += 1.0f;
            }
 	        for (int j = 1; j <= _half_width; ++j) {
    	        for (int i = -_half_width; i <= _half_width; ++i) {
                    float3 c1 = SAMPLE_TEXTURE2D(mainTexture,mainTextureSamper, uv + float2(+i, +j) * inv_src_size).rgb;
                    float3 c2 = SAMPLE_TEXTURE2D(mainTexture,mainTextureSamper, uv + float2(-i, -j) * inv_src_size).rgb;
                    
                    float d1 = CalcDistance(c1, c0);
                    float d2 = CalcDistance(c2, c0);
                    if (d1 < d2) {
            	        sum.rgb += c1;
                    } else {
                        sum.rgb += c2;
                    }
                    sum.a += 1.0f;
		        }
            }
            return sum.rgb / sum.a;
        }
         struct a2v
         {
             float4 positionOS:POSITION;
             float2 uv:TEXCOORD;
         };

         struct v2f
         {
             float4 positionCS:SV_POSITION;
             float2 uv:TEXCOORD;
         };
         v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }
         half4 FRAG(v2f i) :SV_TARGET
            {
                float4 finalColor = (0,0,0,0);
                finalColor.a = 1.0f;
    	        finalColor.rgb = SNN(i.uv,_MainTex,sampler_MainTex);
                float3 Source = SAMPLE_TEXTURE2D(_SourceTex,sampler_SourceTex,i.uv).rgb;
                float3 SNNFinal =finalColor.rgb;
                finalColor.rgb = SNNFinal;
                return finalColor;
            }
        ENDHLSL

        pass
        {
            HLSLPROGRAM
            #pragma vertex VERT
            #pragma fragment FRAG
            ENDHLSL
        }
    }
}