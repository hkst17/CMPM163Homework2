Shader "Custom/3D"
{
    Properties {
        _CellSize ("Cell Size", Range(0, 1)) = 1
        _Cube ("Cubemap", CUBE) = "" {}
        _ScrollSpeed ("Scroll Speed", Range(1,10)) = 1
        
    }
    SubShader {
        Pass{
            Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma target 3.0

            #include "Random.cginc"
            #include "UnityCG.cginc"

            float _CellSize;
            float _ScrollSpeed;
            samplerCUBE _Cube;

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            

            struct v2f  {
                float4 vertex : SV_POSITION;
                float3 normalInWorldCoords : NORMAL;
                float3 vertexInWorldCoords : TEXCOORD1;
            };

            float easeIn(float interpolator) { return interpolator * interpolator; }

            float easeOut(float interpolator){ return 1 - easeIn(1 - interpolator); }

            float easeInOut(float interpolator){
                float easeInValue = easeIn(interpolator);
                float easeOutValue = easeOut(interpolator);
                return lerp(easeInValue, easeOutValue, interpolator);
            }

            float perlinNoise(float3 value){
                float3 fraction = frac(value);

                float interpolatorX = easeInOut(fraction.x);
                float interpolatorY = easeInOut(fraction.y);
                float interpolatorZ = easeInOut(fraction.z);

                float3 cellNoiseZ[2];
                [unroll]
                for(int z=0;z<=1;z++){
                    float3 cellNoiseY[2];
                    [unroll]
                    for(int y=0;y<=1;y++){
                        float3 cellNoiseX[2];
                        [unroll]
                        for(int x=0;x<=1;x++){
                            float3 cell = floor(value) + float3(x, y, z);
                            float3 cellDirection = rand3dTo3d(cell) * 2 - 1;
                            float3 compareVector = fraction - float3(x, y, z);
                            cellNoiseX[x] = dot(cellDirection, compareVector);
                        }
                        cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
                    }
                    cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
                }
                float3 noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
                return noise;
            }
            
            v2f vert (appdata v) {
                v2f o;
                o.vertexInWorldCoords = mul(unity_ObjectToWorld, v.vertex); //Vertex position in WORLD coords
                o.normalInWorldCoords = UnityObjectToWorldNormal(v.normal); //Normal 
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float4 frag (v2f i) : SV_Target {
                float3 value = i.vertexInWorldCoords / _CellSize;
                value.y += _Time.y * _ScrollSpeed;
                //get noise and adjust it to be ~0-1 range
                float noise = perlinNoise(value) + 0.5;

                noise = frac(noise * 6);

                float pixelNoiseChange = fwidth(noise);

                float heightLine = smoothstep(1-pixelNoiseChange, 1, noise);
                heightLine += smoothstep(pixelNoiseChange, 0, noise);

                float3 P = i.vertexInWorldCoords.xyz;
                 
                float3 vIncident = normalize(P - _WorldSpaceCameraPos);

                float3 vReflect = reflect( vIncident, i.normalInWorldCoords );

                float4 reflectColor = texCUBE( _Cube, vReflect );

                float3 vRefract = refract( vIncident, i.normalInWorldCoords, 0.5 );

                //float4 refractColor = texCUBE( _Cube, vRefract );

                float3 vRefractRed = refract( vIncident, i.normalInWorldCoords, 0.1 );
                float3 vRefractGreen = refract( vIncident, i.normalInWorldCoords, 0.4 );
                float3 vRefractBlue = refract( vIncident, i.normalInWorldCoords, 0.7 );

                float4 refractColorRed = texCUBE( _Cube, float3( vRefractRed ) );
                float4 refractColorGreen = texCUBE( _Cube, float3( vRefractGreen ) );
                float4 refractColorBlue = texCUBE( _Cube, float3( vRefractBlue ) );
                float4 refractColor = float4(refractColorRed.r, refractColorGreen.g, refractColorBlue.b, 1.0);


                return heightLine == 0 ? float4(lerp(reflectColor, refractColor, 0.5).rgb, 1) : float4(1,1,1,1);
            }
        ENDCG
        }
    }
    FallBack "Standard"
}   