
Shader "UnlitShadersBooks/Chapter7/NormalMapTangentSpace"
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
            float4 _MainTex_ST;
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
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
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

                // 等同于下述内置宏
                // // 计算副切线
                // float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
                // // 构造一个矩阵，将向量从对象空间变换到切线空间（切线方向、副切线方向、法线方向）
                // float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);

                // 上述构造矩阵的代码等同于下面内置宏（包含于Lighting.cginc中）
                TANGENT_SPACE_ROTATION;

                // 将光照方向由对象空间转换到切线空间
                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
                // 将视角方向由对象空间转换到切线空间
                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i) : SV_Target
            {
                // 切线空间光照方向
                fixed3 tangentLightDir = normalize(i.lightDir);
                // 切线空间视角方向
                fixed3 tangentViewDir = normalize(i.viewDir);

                // 对_BumpMap采样
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);

                // 切线空间法线
                fixed3 tangentNormal;

                // 如果没有把法线纹理类型设为Normal map，则需要用以下代码手动实现
                // // 把packedNormal的xy分量，按照公式映射会法线方向
                // tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
                // // 由于法线都是都是单位矢量，所以z分量可以根据xy计算得（z为正值）
                // tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // 如果把法线纹理类型设为Normal map，则需要用以下代码实现
                // 使用UnpackNormal获得正确的法线方向
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // 获取纹理采样 并与 颜色进行叠加
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                // 计算环境光部分
                fixed ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // 计算漫反射光部分
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                // 计算高亮反射部分
                fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

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
