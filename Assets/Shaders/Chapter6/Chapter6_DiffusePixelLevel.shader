
// 漫反射 - 逐像素光照
Shader "UnlitShadersBooks/Chapter6/DiffusePixelLevel"
{
    // 属性模块
    Properties
    {
        // 漫反射颜色
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        // 顶点/片元着色器的代码需要写在Pass语义块里
        Pass
        {
            /**
             * 指明光照模型
             * LightMode为Pass标签的一种，定义该Pass在Unity光照流水线中的角色
             * 只用定义了正确的LightMode才能得到一些Unity的内置光照变量
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
            fixed4 _Diffuse;

            // 定义顶点着色器的输入结构体
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            // 定义顶点着色器的输出结构体（同时也是片元着色器的输入结构体）
            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal : TEXCOORD0;
            };

            // 顶点着色器
            v2f vert(a2v v)
            {
                // 定义返回值
                v2f o;

                // 把顶点位置从模型空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                // 把世界空间下的法线传递给片元着色器
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i) : SV_Target
            {
                // 通过 UNITY_LIGHTMODEL_AMBIENT 得到环境光部分
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 变换得到世界空间的法线向量
                fixed3 worldNormal = normalize(i.worldNormal);

                // _WorldSpaceLightPos0 可以获取当前光源的方向（只针对仅有一个光源且为平行光的情形）
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 计算漫反射光部分 _LightColor0 可以获取当前位置的光源颜色和强度信息（想要得到正确的值，需要定义合适的LightMode标签）
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                fixed3 color = ambient + diffuse;

                return fixed4(color, 1.0);
            }

            // CG代码结束
            ENDCG
        }
    }

    // 设为内置Diffuse
    FallBack "Diffuse"
}