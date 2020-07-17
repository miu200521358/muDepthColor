////////////////////////////////////////////////////////////////////////////////////////////////
//
//  muDepthColor.fx ver1.0.0
//  深度カラーエフェクト
//  作成: miu( ベース: DepthMap(エーアイス様), M4Layer(ミーフォ茜様) )
//
////////////////////////////////////////////////////////////////////////////////////////////////

// カラールックアップテーブルのファイル名
#define LUT_FILENAME "Rainbow.png"

// [M4Layer(ミーフォ茜様)]より /////////////////////////////////
// レイヤーモード
// 0: 通常
// 1: 加算
// 2: 減算
// 3: 乗算
// 4: スクリーン
// 5: オーバーレイ
// 6: ハードライト
// 7: ソフトライト
// 8: ビビッドライト
// 9: リニアライト
// 10: ピンライト
// 11: 覆い焼き
// 12: 焼き込み
// 13: 比較 (暗)
// 14: 比較 (明)
// 15: 差の絶対値
// 16: 除外
#define LAYER_MODE 3


// 解らない人はここから下はいじらないでください
////////////////////////////////////////////////////////////////////////////////////////////////


// アクセ情報の取得
float AcsX : CONTROLOBJECT < string name = "(self)"; string item = "X"; >;
float AcsY : CONTROLOBJECT < string name = "(self)"; string item = "Y"; >;
float AcsZ : CONTROLOBJECT < string name = "(self)"; string item = "Z"; >;
float AcsTr : CONTROLOBJECT < string name = "(self)"; string item = "Tr"; >;
float AcsSi : CONTROLOBJECT < string name = "(self)"; string item = "Si"; >;

// 混色手法
#if LAYER_MODE == 17
#define IS_COMPOSITE_BLENDING
#elif LAYER_MODE == 18
#define IS_COMPOSITE_BLENDING
#elif LAYER_MODE == 19
#define IS_COMPOSITE_BLENDING
#elif LAYER_MODE == 20
#define IS_COMPOSITE_BLENDING
#endif

// 深度距離 [DepthMap(エーアイス様)]より /////////////////////////////////
float zfar
<
   string UIName = "zFar";
   string UIWidget = "Slider";
   string UIHelp = "Far(遠距離)";
   bool UIVisible =  true;
   float UIMin = 0.0;
   float UIMax = 10.0;
> = 1.0;

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;


// オリジナルの描画結果を記録するためのレンダーターゲット
texture ScnMap : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0, 1.0};
    bool AntiAlias = false;
    string Format = "A8B8G8R8"; // 通常はこっち
//    string Format = "A16B16G16R16F"; // こうすると後のALを阻害しない
    int MipLevels = 1;
>;
sampler ScnSamp = sampler_state {
    texture = <ScnMap>;
    MinFilter = NONE;
    MagFilter = NONE;
    MipFilter = NONE;
    AddressU  = WRAP;
    AddressV  = WRAP;
};

// 深度を測るレンダーターゲット ////////////////
texture muDCMaskRT: OFFSCREENRENDERTARGET <
    string Description = "Depth,Mask OffScreen RenderTarget for muDepth(In)VisibleMask.fxsub";
    float4 ClearColor = { 0, 0, 0, 1 };
    string Format="G32R32F";
    float ClearDepth = 1.0;
    bool AntiAlias = false;
    string DefaultEffect = "self = hide; * = muDepthVisibleMask.fxsub;";
>;

sampler DrawSampler = sampler_state
{
    Texture = <muDCMaskRT>;
    ADDRESSU = WRAP;
    ADDRESSV = WRAP;
    FILTER = NONE;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};

// トーンカーブのヒント用テクスチャ ////////////////
texture LutTexture : TEXTURE <
    string ResourceName = LUT_FILENAME;
>;
sampler LutSampler = sampler_state {
    texture = <LutTexture>;
    Filter = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

// 深度バッファ
texture DepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0f, 1.0f};
>;

// スクリーンサイズ
float2 ViewportSize : VIEWPORTPIXELSIZE;

static float2 ViewportOffset = float2(0.5,0.5) / ViewportSize;

// 深度のリニア化
float LinearizeDepth(float depth, float near, float far)
{
    return (2.0 * near) / (far + near - depth * (far - near));
}

/////////////////////////////////
// VSからPSに渡す構造体
struct VS_OUTPUT {
    float4 Pos      : POSITION;
    float2 Tex      : TEXCOORD0;
};


// 混色計算 [M4Layer(ミーフォ茜様)]より ///////////////////
#ifdef IS_COMPOSITE_BLENDING

float Lum(float3 rgb)
{
    return rgb.r * 0.3 + rgb.g * 0.59 + rgb.b * 0.11;
}

float3 ClipColor(float3 rgb)
{
    float l = Lum(rgb);
    float n = min(rgb.r, min(rgb.g, rgb.b));
    float x = max(rgb.r, max(rgb.g, rgb.b));
    
    if (n < 0)
    {
        float lMinusN = l - n;
        
        rgb = float3
        (
            l + (rgb.r - l) * l / lMinusN,
            l + (rgb.g - l) * l / lMinusN,
            l + (rgb.b - l) * l / lMinusN
        );
    }
    
    if (x > 1)
    {
        float oneMinusL = 1 - l;
        float xMinusL = x - l;
        
        rgb = float3
        (
            l + (rgb.r - l) * oneMinusL / xMinusL,
            l + (rgb.g - l) * oneMinusL / xMinusL,
            l + (rgb.b - l) * oneMinusL / xMinusL
        );
    }
    
    return rgb;
}

float3 SetLum(float3 rgb, float l)
{
    float d = l - Lum(rgb);
    
    rgb += float3(d, d, d);
    
    return ClipColor(rgb);
}

float Sat(float3 rgb)
{
    return max(rgb.r, max(rgb.g, rgb.b)) - min(rgb.r, min(rgb.g, rgb.b));
}

float3 SetSat(float3 rgb, float s)
{
    float3 rt = rgb;
    float maxValue = max(rgb.r, max(rgb.g, rgb.b));
    float minValue = min(rgb.r, min(rgb.g, rgb.b));
    float midValue =
        rgb.r < maxValue && rgb.r > minValue ? rgb.r :
        rgb.g < maxValue && rgb.g > minValue ? rgb.g :
        rgb.b < maxValue && rgb.b > minValue ? rgb.b : (maxValue + minValue) / 2;
    
    if (maxValue > minValue)
    {
        [unroll]
        for (int i = 0; i < 3; i++)
        {
            if (rgb[i] == midValue)
                rt[i] = (midValue - minValue) * s / (maxValue - minValue);
            else if (rgb[i] == maxValue)
                rt[i] = s;
            else
                rt[i] = 0;
        }
    }
    else
    {
        rt = 0;
    }
    
    return rt;
}

float3 Blend(float3 a, float3 b)
{
#if LAYER_MODE == 17
    return SetLum(SetSat(b, Sat(a)), Lum(a));   // 色相
#elif LAYER_MODE == 18
    return SetLum(SetSat(a, Sat(b)), Lum(a));   // 彩度
#elif LAYER_MODE == 19
    return SetLum(b, Lum(a));                   // カラー
#elif LAYER_MODE == 20
    return SetLum(a, Lum(b));                   // 輝度
#else
    return b;   // 通常
#endif
}

#else

float Blend(float a, float b, float c)
{
#if LAYER_MODE == 1
    return a + b;   // 加算
#elif LAYER_MODE == 2
    return a - b;   // 減算
#elif LAYER_MODE == 3
    return a * b;   // 乗算
#elif LAYER_MODE == 4
    return 1 - (1 - a) * (1 - b);   // スクリーン
#elif LAYER_MODE == 5
    return a < 0.5
        ? a * b * 2
        : 1 - (1 - a) * (1 - b) * 2;    // オーバーレイ
#elif LAYER_MODE == 6
    return b < 0.5
        ? a * b * 2
        : 1 - (1 - a) * (1 - b) * 2;    // ハードライト
#elif LAYER_MODE == 7
    return (1 - b) * pow(a, 2) + b * (1 - pow(1 - b, 2));   // ソフトライト
#elif LAYER_MODE == 8
    return b < 0.5
        ? (a >= 1 - b * 2 ? 0 : (a - (1 - b * 2)) / (b * 2))
        : (a < 2 - b * 2 ? a / (2 - b * 2) : 1);    // ビビッドライト
#elif LAYER_MODE == 9
    return b < 0.5
        ? (a < 1 - b * 2 ? 0 : b * 2 + a - 1)
        : (a < 2 - b * 2 ? b * 2 + a - 1 : 1);  // リニアライト
#elif LAYER_MODE == 10
    return b < 0.5
        ? (b * 2 < a ? b * 2 : a)
        : (b * 2 - 1 < a ? a : b * 2 - 1);  // ピンライト
#elif LAYER_MODE == 11
    return a > 0 ? a / (1 - b) : 0; // 覆い焼き
#elif LAYER_MODE == 12
    return b > 0 ? 1 - (1 - a) / b : 0; // 焼き込み
#elif LAYER_MODE == 13
    return min(a, b);   // 比較 (暗)
#elif LAYER_MODE == 14
    return max(a, b);   // 比較 (明)
#elif LAYER_MODE == 15
    return abs(a - b);  // 差の絶対値
#elif LAYER_MODE == 16
    return a + b - 2 * a * b;   // 除外
#else
    return lerp(a, b, c);       // 通常
#endif
}

#endif

/////////////////////////////////
// 頂点シェーダ
VS_OUTPUT VS_DepthDraw(float4 Pos : POSITION, float2 Tex : TEXCOORD0)
{
    VS_OUTPUT Out;

    Out.Pos = Pos;
    Out.Tex = Tex + ViewportOffset;

    return Out;
}

/////////////////////////////////
// ピクセルシェーダ
float4 PS_DepthDraw(VS_OUTPUT IN) : COLOR
{
    float2 uv = IN.Tex;                             // テクスチャ
    float4 DepthMask = tex2D(DrawSampler, uv);      // 深度とマスク情報
    float Depth = DepthMask.r;                      // 深度
    float Mask = DepthMask.g;                       // マスク
// return float4(Mask.rrr, 1);
    float4 OrgColor = tex2D(ScnSamp, uv);           // 元の色

    // 深度のリニア化(サイズでzfar調整)
    float LinearDepth = LinearizeDepth(Depth, 0.05 + (AcsZ / 100), AcsSi);
//return float4(LinearDepth.rrr,1);

    // 深度からの色の決定
    float3 LutColor = tex2D(LutSampler, float2(LinearDepth, uv.x) + float2(AcsY / 10, AcsX / 10));
    // マスクをかけた色合い(All or Nothing)
    float3 MaskLutColor = lerp(LutColor, float3(0, 0, 0), Mask);
//return float4(MaskLutColor.r, MaskLutColor.g, MaskLutColor.b, 1);
    
    // 元画面との合成(M4Layerベース)
    float3 OrgLutColor;
    
#ifdef IS_COMPOSITE_BLENDING
    OrgLutColor.rgb = Blend(OrgColor, MaskLutColor.rgb);
#else
    [unroll]
    for (int i = 0; i < 3; i++) {
        OrgLutColor[i] = Blend(OrgColor[i], LutColor[i], AcsTr);
    }
#endif
    
    // 最終的な色（InvisibleMaskが掛かってるところは深度カラーを出さない）
    float4 Result;
    Result.rgb = lerp(OrgColor.rgb, OrgLutColor.rgb, 1 - Mask);
    Result.a = OrgColor.a;

    return Result;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// バッファクリアの色とか初期値とか
float4 ClearColor = {0, 0, 0, 0};
float ClearDepth  = 1.0;

technique PostEffectTec <
    string Script =
        "RenderColorTarget0=ScnMap;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "ScriptExternal=Color;"

        "RenderColorTarget0=;"
        "RenderDepthStencilTarget=;"
        "Pass=DepthDraw;"
    ;
>{
    pass DepthDraw < string Script = "Draw=Buffer;"; >{
        AlphaBlendEnable = false;
        VertexShader = compile vs_2_0 VS_DepthDraw();
        PixelShader  = compile ps_2_0 PS_DepthDraw();
    }
};

