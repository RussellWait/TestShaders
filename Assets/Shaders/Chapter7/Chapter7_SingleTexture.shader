
Shader "UnlitShadersBooks/Chapter7/SingleTexture"
{
    // 属性模块
    Properties
    {
        // 颜色
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 纹理（名字为white）
        _MainTex ("Main Tex", 2D) = "white" {}
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
            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; // 由 纹理名_ST 命名的属性，用于获得该纹理的 缩放(S) 和 平移(T)
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
                float2 uv : TEXCOORD2;  // 存储纹理坐标的变量
            };

            // 顶点着色器
            v2f vert(a2v v)
            {
                // 定义返回值
                v2f o;

                // 把顶点位置从模型空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);

                // 获得世界空间下法向量方向
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                // 获得世界空间下顶点坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                // 获得uv坐标（先对纹理进行缩放，然后进行偏移计算）s
                // o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // 下述写法等效
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            // 片元着色器
            fixed4 frag(v2f i) : SV_Target
            {
                // 变换得到世界空间的法线向量
                fixed3 worldNormal = normalize(i.worldNormal);

                // 获取当前光源的方向
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                // 获取纹理采样 并与 颜色进行叠加
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                // 计算环境光部分
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // 计算漫反射光部分 _LightColor0 可以获取当前位置的光源颜色和强度信息（想要得到正确的值，需要定义合适的LightMode标签）
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                // 获得世界空间的摄像机位置
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                // 获得世界空间的 half direction
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                
                // 计算高亮反射部分
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

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
