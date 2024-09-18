
// 设置Shader名字
Shader "UnlitShadersBooks/Chapter5/SimpleShader"
{
    // 属性模块
    Properties {
        // 声明一个Color类型的属性
        _Color ("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0)
    }

    SubShader
    {
        Pass
        {
            // CG代码开始
            CGPROGRAM

            // 声明包含顶点着色器的代码
            #pragma vertex vert
            // 声明包含片元着色器的代码
            #pragma fragment frag

            // 定义一个属性名称和类型都匹配的变量
            fixed4 _Color;

            // 使用一个结构体来定义顶点着色器的输入
            struct a2v {
                // POSITION语义告诉Unity，用模型空间的顶点坐标填充vertex变量
                float4 vertex : POSITION;
                // NORMAL语义告诉Unity，用模型空间的法线方向填充normal变量
                float3 normal : NORMAL;
                // TEXCOORD0语义告诉Unity，用模型的第一套纹理坐标填充texcoord变量
                float4 texcoord : TEXCOORD0;
            };

            // 使用一个结构体来定义顶点着色器的输出
            struct v2f {
                // SV_POSITION语义告诉Unity，pos里包含了顶点在裁剪空间中的位置信息
                float4 pos : SV_POSITION;
                // COLOR0语义告诉Unity，color用于存储颜色信息
                fixed3 color : COLOR0;
            };

            /**
             * 顶点着色器代码
             * 逐顶点处理输入的顶点v
             * 输出一个float4类型的变量
             * POSITION，SV_POSITION 是CG/HLSL中的语义，用于告诉系统用户需要哪些输入值，以及输出是什么
             *   POSITION告诉Unity，把模型顶点坐标填充到输入参数v
             *   SV_POSITION告诉Unity，顶点着色器的输出是裁剪空间中的顶点坐标
             */

            /*
            float4 vert(float4 v : POSITION) : SV_POSITION {
                // 把顶点坐标从模型空间转换到裁剪空间
                return UnityObjectToClipPos (v);
            }
             */

            v2f vert(a2v v) {
                // 声明输出结构
                v2f o;

                // 计算顶点坐标从模型空间转换到裁剪空间
                o.pos = UnityObjectToClipPos (v.vertex);
                // v.normal包含了顶点的法线方向，范围为[-1.0, 1.0]
                // 把分量范围映射到[0.0, 1.0]，并保存
                o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);

                return o; 
            }

            /**
             * 片元着色器代码
             * 输出一个fixed4类型的变量
             * SV_Target 也是CG/HLSL中的语义，用于告诉系统输出是什么
             *   SV_Target告诉Unity，把用户的输出颜色存储到一个渲染目标中（这里为默认的帧缓存中）
             */
            fixed4 frag(v2f i) : SV_Target {
                // 使用_Color属性来控制输出颜色
                fixed3 c = i.color;
                c *= _Color.rgb;

                return fixed4(c, 1.0);
            }

            // CG代码结束
            ENDCG
        }
    }
}
