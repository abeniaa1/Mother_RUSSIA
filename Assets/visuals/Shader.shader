Shader "Unlit/Shader"
{
    Properties
    {
        //_Type ("Type", Integer) = 0
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        //Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Opaque"}
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            uint _Type = 1;

            float _Inc = 0;
            float _IncDiff = 0;
            
            uint _NumPoints = 0;
            float _Points[1024];
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                //UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                //float4 ogv : POSITION;
            };

            
            float mix(float a, float b, float t) {
                return a + (b - a) * t;
            }
            // 2D Random
            float random (in fixed2 st) {
                return (sin(dot(st.xy, fixed2(12.9898,78.233)))* 43758.5453123)%1;
            }

            // 2D Noise based on Morgan McGuire @morgan3d
            // https://www.shadertoy.com/view/4dS3Wd
            float noise (in fixed2 st) {
                fixed2 i = floor(st);
                fixed2 f = st%1;

                // Four corners in 2D of a tile
                float a = random(i);
                float b = random(i + fixed2(1.0, 0.0));
                float c = random(i + fixed2(0.0, 1.0));
                float d = random(i + fixed2(1.0, 1.0));

                // Smooth Interpolation

                // Cubic Hermine Curve.  Same as SmoothStep()
                fixed2 u = f*f*(3.0-2.0*f);
                // u = smoothstep(0.,1.,f);

                // Mix 4 coorners percentages
                return mix(a, b, u.x) +
                        (c - a)* u.y * (1.0 - u.x) +
                        (d - b) * u.x * u.y;
            }
            float sigmoid(float z) {
                return 1/(1+pow(2.712, -z));
            }
            fixed3 lerp(fixed3 a, fixed3 b, float t) {
                return a + (b - a) * t;
            }

            fixed3 bez(fixed3 a, fixed3 b, fixed3 c, fixed3 d, float t) {
                return lerp(
                    lerp(a,b,t),
                    lerp(c,d,t),
                    t
                );
            }

            float defaultShape(float z, float a) {
                return 1;// (1+z)*2;
            }

            


            float fireBallShape(float z, float a) {
                return min(
                    pow(sigmoid((z-2))*2, 2),
                    2*((1-sigmoid(z-1))-0.5)
                )*60;
            }

            float tentacleShape(float z, float a) {
                return (1-z)*(2 + noise(fixed2(a,a)*900)*3)/2;
            }

            float darknessShape(float z, float a) {
                return 0.5 + 1.5*noise(fixed2(z,a*90));
            }
            float lightningShape(float z, float a) {
                return 0.25 + 0.7*noise(fixed2(z*2,a)*20);
            }

            float getShape(float z, float a) {
                if (_Type == 0) {
                    return defaultShape(z, a);
                } else if (_Type == 1) {
                    return fireBallShape(z, a);
                } else if (_Type == 2) {
                    return darknessShape(z, a);
                } else if (_Type == 3) {
                    return lightningShape(z, a);
                } else if (_Type == 4) {
                    return tentacleShape(z, a);
                }
                return defaultShape(z, a);
            }

            float sourceToT(float z) {
                return max(0, min(0.9999, (_Inc - z*_IncDiff)/(1+_IncDiff)));
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.uv;
                //o.ogv = v.vertex;
                
                uint numSplines = (_NumPoints-1)/3;

                float _inc = sourceToT(v.vertex.z*100);
                int i = _inc*numSplines;
                float off = (_inc*numSplines)%1;

                o.vertex = mul( UNITY_MATRIX_VP, float4(bez(
                    fixed3(_Points[i*9], _Points[i*9+1], _Points[i*9+2]),
                    fixed3(_Points[i*9+3], _Points[i*9+4], _Points[i*9+5]),
                    fixed3(_Points[i*9+6], _Points[i*9+7], _Points[i*9+8]),
                    fixed3(_Points[i*9+9], _Points[i*9+10], _Points[i*9+11]),
                    off
                ) + fixed3(v.vertex.xy*getShape(v.vertex.z, atan2(v.vertex.y, v.vertex.x)),0) + fixed3(0,0,v.vertex.z), 1));

                //o.vertex =  v.vertex;


                //o.vertex = UnityObjectToClipPos(v.vertex);
                //UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                float _inc = sourceToT(i.vertex.z);

                float3 viewVector = mul(unity_CameraInvProjection, float4(i.uv.xy * 5 - 1, 0, 1));
                
                fixed4 col;
                if (_Type == 0) {
                    fixed3 vertex = i.vertex*420;//mul(unity_ObjectToWorld, float4(i.vertex));//UnityObjectToWorldPos(i.vertex);//mul(unity_CameraToWorld, float4(viewVector, 0)); //mul(_MainCameraToWorld, float4(i.vertex, 1.0)).xyz;
                    float z = sin(vertex.z)/2+0.5;
                    col.r = z;
                    col.g = 1.0-z;
                    col.b = (col.r*2.0+col.g)/3;
                    col.a = vertex.z%10 > 5 ? 0 : 1;
                } else if (_Type == 1) {                    
                    fixed3 vertex = i.vertex*420;//mul(unity_ObjectToWorld, float4(i.vertex));//UnityObjectToWorldPos(i.vertex);//mul(unity_CameraToWorld, float4(viewVector, 0)); //mul(_MainCameraToWorld, float4(i.vertex, 1.0)).xyz;
                    float z = sin(vertex.z)/2+0.5;
                    col.r = 0.5+z/2;
                    col.g = 0.3+z/3.4;
                    col.b = z/10;
                    col.a = 1;//vertex.z%10 > 5 ? 0 : 1;
                } else if (_Type == 2) {
                    fixed3 vertex = i.vertex*120;//mul(unity_ObjectToWorld, float4(i.vertex));//UnityObjectToWorldPos(i.vertex);//mul(unity_CameraToWorld, float4(viewVector, 0)); //mul(_MainCameraToWorld, float4(i.vertex, 1.0)).xyz;
                    return fixed4((vertex%10)/100,1);
                } else if (_Type == 3) {
                    float z = noise(fixed2(i.vertex.y,i.vertex.z))*0.2+0.2;
                    //fixed3 vertex = i.vertex*120;//mul(unity_ObjectToWorld, float4(i.vertex));//UnityObjectToWorldPos(i.vertex);//mul(unity_CameraToWorld, float4(viewVector, 0)); //mul(_MainCameraToWorld, float4(i.vertex, 1.0)).xyz;
                    return fixed4(z, z, 0.85,1);//(vertex%10)/100,1);
                } else if (_Type == 4) {
                    //fixed3 vertex = i.vertex*120;//mul(unity_ObjectToWorld, float4(i.vertex));//UnityObjectToWorldPos(i.vertex);//mul(unity_CameraToWorld, float4(viewVector, 0)); //mul(_MainCameraToWorld, float4(i.vertex, 1.0)).xyz;
                    return fixed4(0.1, 0.7, 0.05,1);//(vertex%10)/100,1);
                }
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
