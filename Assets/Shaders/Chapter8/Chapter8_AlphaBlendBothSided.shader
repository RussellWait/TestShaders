
Shader "UnlitShadersBooks/Chapter8/AlphaBlendBothSided"
{
    // 属性模块
    Properties
    {
        // 颜色
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
        // 纹理（名字为white）
        _MainTex ("Main Tex", 2D) = "white" {}
        // 透明度测试时阈值
        _AlphaScale ("Alpha Scale", Range(0, 1)) = 0.5
    }

    SubShader
    {
        // 定义管线的渲染行为和优化渲染过程
        Tags
        {
            "Queue"="Transparent"       // 指定渲染队列为Transparent
            "IgnoreProjector"="True"    // 指定不受任何投影器影响
            "RenderType"="Transparent"  // 指定渲染类型为使用透明度混合的
        }

        // 顶点/片元着色器的代码需要写在Pass语义块里
        // 剔除正面的渲染
        Pass
        {
            /**
             * 指明光照模型
             * LightMode为Pass标签的一种，定义该Pass在Unity光照流水线中的角色
             * 只用定义了正确的LightMode才能得到一些Unity的内置光照变量
             */
            Tags {"LightMode"="ForwardBase"}

            // 指定需要剔除的面，语义为 Cull Back | Front | Off
            Cull Front

            // 关闭深度写入
            ZWrite Off
            // 设置混合因子
            Blend SrcAlpha OneMinusSrcAlpha

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
            fixed _AlphaScale;

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

                // 纹理采样
                fixed4 texColor = tex2D(_MainTex, i.uv);

                // 颜色叠加
                fixed3 albedo = texColor.rgb * _Color.rgb;

                // 计算环境光部分
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // 计算漫反射光部分 _LightColor0 可以获取当前位置的光源颜色和强度信息（想要得到正确的值，需要定义合适的LightMode标签）
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                fixed4 color = fixed4(ambient + diffuse, texColor.a * _AlphaScale);

                return color;
            }

            // CG代码结束
            ENDCG
        }

        // 顶点/片元着色器的代码需要写在Pass语义块里
        // 剔除背面的渲染
        Pass
        {
            /**
             * 指明光照模型
             * LightMode为Pass标签的一种，定义该Pass在Unity光照流水线中的角色
             * 只用定义了正确的LightMode才能得到一些Unity的内置光照变量
             */
            Tags {"LightMode"="ForwardBase"}

            // 指定需要剔除的面，语义为 Cull Back | Front | Off
            Cull Back

            // 关闭深度写入
            ZWrite Off
            // 设置混合因子
            Blend SrcAlpha OneMinusSrcAlpha

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
            fixed _AlphaScale;

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

                // 纹理采样
                fixed4 texColor = tex2D(_MainTex, i.uv);

                // 颜色叠加
                fixed3 albedo = texColor.rgb * _Color.rgb;

                // 计算环境光部分
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // 计算漫反射光部分 _LightColor0 可以获取当前位置的光源颜色和强度信息（想要得到正确的值，需要定义合适的LightMode标签）
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                fixed4 color = fixed4(ambient + diffuse, texColor.a * _AlphaScale);

                return color;
            }

            // CG代码结束
            ENDCG
        }
    }

    // 设为内置Specular
    FallBack "Transparent/Cutout/VertexLit"
}
