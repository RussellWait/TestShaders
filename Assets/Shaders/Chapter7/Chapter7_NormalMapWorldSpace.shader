
Shader "UnlitShadersBooks/Chapter7/NormalMapWorldSpace"
{
    // 属性模块
    Properties
    {
        // 颜色
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 纹理（名字为white）
        _MainTex ("Main Tex", 2D) = "white" {}
        // 法线纹理（默认值"bump"，为unity内置的法线纹理，当没有提供任何法线纹理时，对应模型自带的法线信息）
        _BumpMap ("Normal Map", 2D) = "bump" {}
        // 用于控制凹凸程度的属性，为0时，意味着该法线纹理不会对光照产生任何影响
        _BumpScale ("Bump Scale", Range(-2, 2)) = 1.0
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
            sampler2D _MainTex;     // 主纹理
            float4 _MainTex_ST;     // 由 纹理名_ST 命名的属性，用于获得该纹理的 缩放(S) 和 平移(T)
            sampler2D _BumpMap;     // 法线纹理
            float4 _BumpMap_ST;
            float _BumpScale;       // 纹理凹凸程度
            fixed4 _Specular;
            float _Gloss;

            // 定义顶点着色器的输入结构体
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;       // TANGENT告诉unity把顶点的切线方向填充到tangent中
                float4 texcoord : TEXCOORD0;    // unity会将模型的第一组纹理坐标存储到该变量中
            };

            // 定义顶点着色器的输出结构体（同时也是片元着色器的输入结构体）
            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
            };

            // 顶点着色器
            v2f vert(a2v v)
            {
                // 定义返回值
                v2f o;

                // 把顶点位置从模型空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                // 将两张纹理的坐标分别保存到 uv 的 xy 和 zw 分量中
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

                // 计算世界空间下的顶点、法线、切线、副切线
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                // 将上面计算的结果存在3个向量里
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i) : SV_Target
            {
                // 世界空间顶点
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
                // 世界空间光照方向
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                // 世界空间视角方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
                bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

                // 获取纹理采样 并与 颜色进行叠加
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                // 计算环境光部分
                fixed ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // 计算漫反射光部分
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));

                // 计算高亮反射部分
                fixed3 halfDir = normalize(lightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(bump, halfDir)), _Gloss);

                fixed3 color = ambient + diffuse + specular;

                return fixed4(color, 1.0);
            }

            // CG代码结束
            ENDCG
        }

    }

    // 设为内置Specular
    FallBack "Specular"
}
