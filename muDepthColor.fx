////////////////////////////////////////////////////////////////////////////////////////////////
//
//  muDepthColor.fx ver1.0.0
//  �[�x�J���[�G�t�F�N�g
//  �쐬: miu( �x�[�X: DepthMap(�G�[�A�C�X�l), M4Layer(�~�[�t�H���l) )
//
////////////////////////////////////////////////////////////////////////////////////////////////

// �J���[���b�N�A�b�v�e�[�u���̃t�@�C����
#define LUT_FILENAME "Rainbow.png"

// [M4Layer(�~�[�t�H���l)]��� /////////////////////////////////
// ���C���[���[�h
// 0: �ʏ�
// 1: ���Z
// 2: ���Z
// 3: ��Z
// 4: �X�N���[��
// 5: �I�[�o�[���C
// 6: �n�[�h���C�g
// 7: �\�t�g���C�g
// 8: �r�r�b�h���C�g
// 9: ���j�A���C�g
// 10: �s�����C�g
// 11: �����Ă�
// 12: �Ă�����
// 13: ��r (��)
// 14: ��r (��)
// 15: ���̐�Βl
// 16: ���O
#define LAYER_MODE 3


// ����Ȃ��l�͂������牺�͂�����Ȃ��ł�������
////////////////////////////////////////////////////////////////////////////////////////////////


// �A�N�Z���̎擾
float AcsX : CONTROLOBJECT < string name = "(self)"; string item = "X"; >;
float AcsY : CONTROLOBJECT < string name = "(self)"; string item = "Y"; >;
float AcsZ : CONTROLOBJECT < string name = "(self)"; string item = "Z"; >;
float AcsTr : CONTROLOBJECT < string name = "(self)"; string item = "Tr"; >;
float AcsSi : CONTROLOBJECT < string name = "(self)"; string item = "Si"; >;

// ���F��@
#if LAYER_MODE == 17
#define IS_COMPOSITE_BLENDING
#elif LAYER_MODE == 18
#define IS_COMPOSITE_BLENDING
#elif LAYER_MODE == 19
#define IS_COMPOSITE_BLENDING
#elif LAYER_MODE == 20
#define IS_COMPOSITE_BLENDING
#endif

// �[�x���� [DepthMap(�G�[�A�C�X�l)]��� /////////////////////////////////
float zfar
<
   string UIName = "zFar";
   string UIWidget = "Slider";
   string UIHelp = "Far(������)";
   bool UIVisible =  true;
   float UIMin = 0.0;
   float UIMax = 10.0;
> = 1.0;

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;


// �I���W�i���̕`�挋�ʂ��L�^���邽�߂̃����_�[�^�[�Q�b�g
texture ScnMap : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0, 1.0};
    bool AntiAlias = false;
    string Format = "A8B8G8R8"; // �ʏ�͂�����
//    string Format = "A16B16G16R16F"; // ��������ƌ��AL��j�Q���Ȃ�
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

// �[�x�𑪂郌���_�[�^�[�Q�b�g ////////////////
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

// �g�[���J�[�u�̃q���g�p�e�N�X�`�� ////////////////
texture LutTexture : TEXTURE <
    string ResourceName = LUT_FILENAME;
>;
sampler LutSampler = sampler_state {
    texture = <LutTexture>;
    Filter = LINEAR;
    ADDRESSU = CLAMP;
    ADDRESSV = CLAMP;
};

// �[�x�o�b�t�@
texture DepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0f, 1.0f};
>;

// �X�N���[���T�C�Y
float2 ViewportSize : VIEWPORTPIXELSIZE;

static float2 ViewportOffset = float2(0.5,0.5) / ViewportSize;

// �[�x�̃��j�A��
float LinearizeDepth(float depth, float near, float far)
{
    return (2.0 * near) / (far + near - depth * (far - near));
}

/////////////////////////////////
// VS����PS�ɓn���\����
struct VS_OUTPUT {
    float4 Pos      : POSITION;
    float2 Tex      : TEXCOORD0;
};


// ���F�v�Z [M4Layer(�~�[�t�H���l)]��� ///////////////////
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
    return SetLum(SetSat(b, Sat(a)), Lum(a));   // �F��
#elif LAYER_MODE == 18
    return SetLum(SetSat(a, Sat(b)), Lum(a));   // �ʓx
#elif LAYER_MODE == 19
    return SetLum(b, Lum(a));                   // �J���[
#elif LAYER_MODE == 20
    return SetLum(a, Lum(b));                   // �P�x
#else
    return b;   // �ʏ�
#endif
}

#else

float Blend(float a, float b, float c)
{
#if LAYER_MODE == 1
    return a + b;   // ���Z
#elif LAYER_MODE == 2
    return a - b;   // ���Z
#elif LAYER_MODE == 3
    return a * b;   // ��Z
#elif LAYER_MODE == 4
    return 1 - (1 - a) * (1 - b);   // �X�N���[��
#elif LAYER_MODE == 5
    return a < 0.5
        ? a * b * 2
        : 1 - (1 - a) * (1 - b) * 2;    // �I�[�o�[���C
#elif LAYER_MODE == 6
    return b < 0.5
        ? a * b * 2
        : 1 - (1 - a) * (1 - b) * 2;    // �n�[�h���C�g
#elif LAYER_MODE == 7
    return (1 - b) * pow(a, 2) + b * (1 - pow(1 - b, 2));   // �\�t�g���C�g
#elif LAYER_MODE == 8
    return b < 0.5
        ? (a >= 1 - b * 2 ? 0 : (a - (1 - b * 2)) / (b * 2))
        : (a < 2 - b * 2 ? a / (2 - b * 2) : 1);    // �r�r�b�h���C�g
#elif LAYER_MODE == 9
    return b < 0.5
        ? (a < 1 - b * 2 ? 0 : b * 2 + a - 1)
        : (a < 2 - b * 2 ? b * 2 + a - 1 : 1);  // ���j�A���C�g
#elif LAYER_MODE == 10
    return b < 0.5
        ? (b * 2 < a ? b * 2 : a)
        : (b * 2 - 1 < a ? a : b * 2 - 1);  // �s�����C�g
#elif LAYER_MODE == 11
    return a > 0 ? a / (1 - b) : 0; // �����Ă�
#elif LAYER_MODE == 12
    return b > 0 ? 1 - (1 - a) / b : 0; // �Ă�����
#elif LAYER_MODE == 13
    return min(a, b);   // ��r (��)
#elif LAYER_MODE == 14
    return max(a, b);   // ��r (��)
#elif LAYER_MODE == 15
    return abs(a - b);  // ���̐�Βl
#elif LAYER_MODE == 16
    return a + b - 2 * a * b;   // ���O
#else
    return lerp(a, b, c);       // �ʏ�
#endif
}

#endif

/////////////////////////////////
// ���_�V�F�[�_
VS_OUTPUT VS_DepthDraw(float4 Pos : POSITION, float2 Tex : TEXCOORD0)
{
    VS_OUTPUT Out;

    Out.Pos = Pos;
    Out.Tex = Tex + ViewportOffset;

    return Out;
}

/////////////////////////////////
// �s�N�Z���V�F�[�_
float4 PS_DepthDraw(VS_OUTPUT IN) : COLOR
{
    float2 uv = IN.Tex;                             // �e�N�X�`��
    float4 DepthMask = tex2D(DrawSampler, uv);      // �[�x�ƃ}�X�N���
    float Depth = DepthMask.r;                      // �[�x
    float Mask = DepthMask.g;                       // �}�X�N
// return float4(Mask.rrr, 1);
    float4 OrgColor = tex2D(ScnSamp, uv);           // ���̐F

    // �[�x�̃��j�A��(�T�C�Y��zfar����)
    float LinearDepth = LinearizeDepth(Depth, 0.05 + (AcsZ / 100), AcsSi);
//return float4(LinearDepth.rrr,1);

    // �[�x����̐F�̌���
    float3 LutColor = tex2D(LutSampler, float2(LinearDepth, uv.x) + float2(AcsY / 10, AcsX / 10));
    // �}�X�N���������F����(All or Nothing)
    float3 MaskLutColor = lerp(LutColor, float3(0, 0, 0), Mask);
//return float4(MaskLutColor.r, MaskLutColor.g, MaskLutColor.b, 1);
    
    // ����ʂƂ̍���(M4Layer�x�[�X)
    float3 OrgLutColor;
    
#ifdef IS_COMPOSITE_BLENDING
    OrgLutColor.rgb = Blend(OrgColor, MaskLutColor.rgb);
#else
    [unroll]
    for (int i = 0; i < 3; i++) {
        OrgLutColor[i] = Blend(OrgColor[i], LutColor[i], AcsTr);
    }
#endif
    
    // �ŏI�I�ȐF�iInvisibleMask���|�����Ă�Ƃ���͐[�x�J���[���o���Ȃ��j
    float4 Result;
    Result.rgb = lerp(OrgColor.rgb, OrgLutColor.rgb, 1 - Mask);
    Result.a = OrgColor.a;

    return Result;
}

////////////////////////////////////////////////////////////////////////////////////////////////
// �o�b�t�@�N���A�̐F�Ƃ������l�Ƃ�
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

