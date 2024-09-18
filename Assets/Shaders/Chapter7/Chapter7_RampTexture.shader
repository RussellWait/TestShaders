// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'


Shader "UnlitShadersBooks/Chapter7/RampTexture"
{
    // 属性模块
    Properties
    {
        // 颜色
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 纹理
        _RampTex ("Ramp Tex", 2D) = "white" {}
        // 高亮反射颜色
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        // 控制高亮区域大小
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }

    SubShader
    {
        // 顶点/片元着色器的代码需要写在Pass语义块里
        Pass
        {
            /**
             * 指明光照模型
             * LightMode为Pass标签的一种，定义该Pass在unity光照流水线中的角色
             * 只用定义了正确的LightMode才能得到一些unity的内置光照变量
             */
            Tags {"LightMode"="ForwardBase"}

            // CG代码开始
            CGPROGRAM

            // 定义一个 顶点着色器 和 片元着色器
            #pragma vertex vert
            #pragma fragment frag

            // 引入内置文件（为了后面能使用一些变量）
            #include "Lighting.cginc"

            // 呼应声明中属性的变量
            fixed4 _Color;
            sampler2D _RampTex;
            float4 _RampTex_ST;
            fixed4 _Specular;
            float _Gloss;

            // 定义顶点着色器的输入结构体
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;    // unity会将模型的第一组纹理坐标存储到该变量中
            };

            // 定义顶点着色器的输出结构体（同时也是片元着色器的输入结构体）
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            // 顶点着色器
            v2f vert(a2v v)
            {
                // 定义返回值
                v2f o;

                // 把顶点位置从模型空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                // 把法线从模型空间转换到世界空间
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                // 把顶点从模型空间转换到世界空间
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                // uv坐标转换
                o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);

                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i) : SV_Target
            {
                // 世界空间法向量
                fixed3 worldNormal = normalize(i.worldNormal);
                // 世界空间光照方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                // 计算环境光部分
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 计算漫反射光部分
                fixed halfLambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
                fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;
                fixed3 diffuse = _LightColor0.rgb * diffuseColor;

                // 计算高亮反射部分
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                fixed4 color = fixed4(ambient + diffuse + specular, 1.0);

                return color;
            }

            // CG代码结束
            ENDCG
        }

    }

    // 设为内置Specular
    FallBack "Specular"
}
