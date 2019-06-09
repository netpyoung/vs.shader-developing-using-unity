# TODO
- [white noise](https://www.ronja-tutorials.com/2018/09/02/white-noise.html)
- [날아다니는 나비 만들기](https://holdimprovae.blogspot.com/2019/02/studyunityshader.html)
- [Hbao Plus Analysis 0](https://hrmrzizon.github.io/2017/11/15/hbao-plus-analysis-0/)
- [한정현 컴퓨터그래픽스 (11장- 오일러 변환 및 쿼터니언)](https://www.youtube.com/watch?v=XgE7tOSc7AU&list=PLYEC1V9tJOl03WLDoUEKbiYW_Xt4W6LTl&index=12)
- [한정현 컴퓨터그래픽스 (15장 - 쉐도우 맵)](https://www.youtube.com/watch?v=kCuEtQh91U8&list=PLYEC1V9tJOl03WLDoUEKbiYW_Xt4W6LTl&index=16)

- https://docs.unity3d.com/Manual/SL-DataTypesAndPrecision.html
- https://docs.unity3d.com/Manual/SL-ShaderPerformance.html

# mipmap
- [유니티에서의 텍스쳐 밉맵과 필터링 (Texture Mipmap & filtering in Unity)](https://ozlael.tistory.com/45)
    - 텍스쳐에서 밉맵이란 텍스쳐에게 있어서 LOD같은 개념입니다

- [tex2Dlod와 tex2Dbias의 비교연구](https://chulin28ho.tistory.com/258)

# TODO texture
## ETC2
- OpenGL 3.0 이상.
## ASTC(Adaptive Scalable Texture Compression)
- 손실압축
- OpenGL 3.2 이상 혹은 OpenGL ES 3.1 + AEP(Android Extension Pack)
- iOS는 A8 processor를 사용하기 시작하는 기종부터 사용이 가능합니다. iPhone 6, iPad mini 4가 이에 해당합니다.
- 출처: https://ozlael.tistory.com/84?category=612211 [오즈라엘]

# 00.
- https://shaderdev.com/
- Chayan Vinayak Goswami
- TA 8 years

# 01. What is Shader

  쉐이더란 화면에 출력할 픽셀의 위치와 색상을 계산하는 함수
  쉐이더(shader)란 '색의 농담, 색조, 명암 효과를 주다.'라는 뜻을 가진 shade란 동사와 행동의 주체를 나타내는 접미사 '-er'을 혼합한 단어입니다. 즉, 색의 농담, 색조, 명암 등의 효과를 주는 주체가 쉐이더란 뜻
  - https://kblog.popekim.com/2011/11/01-part-1.html


|     | 코어갯수   | 연산                 |
| --- | ---------- | -------------------- |
| CPU | 몇개       | serial operation     |
| GPU | 수천개     | parallel operation   |


| 쉐이더              | 기능                                                     |
| ------------------- | -------------------------------------------------------- |
| Vertex              |                                                          |
| Geometry            | input primitive                                          |
| Fragment / Pixel    |                                                          |
| Compute             | 렌더링 파이프라인에 속해 있지 않음. GPU 병렬 처리 목적   |
| Tessellation / Hull | OpenGL 4, DirectX3D 11                                   |

- 2016 WWDC - Apple, Metal tesselation pipeline - fixed function shader (하드웨어 내장)



# 02. Working of a Shader
**TODO 정리 다시할것.**

## Vertex Input
- position **
- normal
- color
- ...

## Vertex Shader

## Vertex Output
- position
- other infos

## Rasterize
하드웨어

1. 지오메트리 구역의 픽셀을 찾음.
2. Vertex-Output을 이용하여 데이터들을 interpolate하여 픽셀쉐이더로 보냄.

geometry에 어떤 픽셀들이 화면에 그려지는지 결정함.
sampling
pixel - 하나 이상의 샘플을 지닐 수 있다.

ex)
2개의 샘플중 하나의 샘플만 지오메트리에 속할때
픽셀 쉐이더에 의해 계산되는 색이 평균화되어 픽셀에 부여된다.

fragment : contribute to find color of pixel
multi-sampling


A Fragment is a collection of values produced by the Rasterizer. Each fragment represents a sample-sized segment of a rasterized Primitive.
Fragment
Sample
Pixel

- ??? Sample과 Fragment는 뭐야?
https://stackoverflow.com/questions/31173002/what-is-the-difference-between-a-sample-a-pixel-and-a-fragment

        The size covered by a fragment is related to the pixel area, but rasterization can produce multiple fragments from the same triangle per-pixel, depending on various multisampling parameters and OpenGL state. There will be at least one fragment produced for every pixel area covered by the primitive being rasterized


## Pixel Shader



# 03. Components of a Shader
~~~
Properties

Sub-Shader
  hardware features(support graphics api(metal / gles / xbox360))
  [#pragma onlyrenderer metal]

  Pass
     occlusion pass
     lighting pass
     beuty(diffuse, color) pass

     Vertext-Shader-Input
     Vertext-Shader-Output

     Fragment-Shader-Input
     Fragment-Shader-Output

Fallback
~~~

# 04. Bare-bones shader
~~~ shader
Shader "x"
{
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            uniform half4 _Color;

            struct vertextInput
            {
                float4 vertext : POSITION;
            };

            struct vertextOutput
            {
                float4 pos : POSITION;
            };

            vertextOutput vert(vertextInput v)
            {
                vertextOutput o;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                return o;
            };

            half4 frag(vertexOutput i) : COLOR
            {
                return _Color;
            };

            ENDCG
        }
    }
}
~~~



# 05. Model-View-Projection Matrix
~~~
object space
  - Model Matrix
world space
  - View Matrix
view space
  - Projection Matrix
projection space
~~~


# 06. Depth Sorting / Z-Sorting
* Z-Sorting -> Render Queue -> Painter's algorithm

- Sorting (Depth Sorting / Z-Sorting)
~~~
ZWrite On  ;; override render Queue (forcing z-order)
ZWrite Off
~~~

- Render Queue

~~~
Tags { "Queue" = "Geometry-1" }
~~~
   0 Rendered First = back
5000 Rendered Last  = Front

| min   | default | max  |             |
| ----- | ------- | ---- | ----------- |
| 0     | 100     | 1499 | Background  |
| 150   | 2000    | 2399 | Geometry    |
| 2400  | 2450    | 2699 | AlphaTest   |
| 2700  | 3000    | 3599 | Transparent |
| 3600  | 4000    | 5000 | Overlay     |

- Painter's algorithm
  Based on distance from camera.

# 07. Sub Shader Tags
Tags는 `,`로 구분하지 않는다.(공백으로 구분.)

## Queue
## IgnoreProjection
"IgnoreProjection" = "True"
"IgnoreProjection" = "False"

## RenderType

보통 RenderType는 Queue와 같다.
"Queue" = "Transparent"
"RenderType" = "Transparent"

Camera.main.SetReplacement("X-rayShader", "Opaque")



# 08 Blending
Z-test => Pixel Shader => (Blending)
블랜딩 하는 경우는 보통, 투명 / 반투명한 픽셀이 다른 픽셀 앞에 올때.

Blend(srcFactor, blendOp, dstFactor)
srcFactor: 작업 대상
dstFactor: 컬러버퍼에 있는 값들
blendOp: +(default), min, max




# 09. Texture Mapping

~~~
Direct X     +-----+
             |     |
opengl/unity +-----+
~~~

~~~ shader
Properties
{
    _MainTex("Main Texture", "2D") = "white" {}
}

float4 texcoord : TEXCOORD0;

Tiling x, y
Offset z, w

Texture 속성
Wrap Mode - Clamp / Repeat
~~~


# 10. Gradient Pattern
Quad, Plane의 UV맵핑이 다르다.
Quad는 좌하단.
Plane은 우하단

Mac : Grapher
Other: https://www.desmos.com/calculator



# 11. Wave Functions
sqrt / sin / cos / tan


# 12. Line Pattern
~~~ shader
float drawLine(float2 uv, float start, float end)
{
    if (start < uv.x && uv.x < end)
    {
        return 1;
    }

    return 0;
}
~~~



# 13. Union and Intersection
#minor #pass



# 14. Circle Pattern
~~~ shader
float drawCircle(float2 uv, float2 center, float radius)
{
    float circle = pow((uv.y - center.y), 2) + pow((uv.x - center.x), 2);
    float sqrtRadius = pow(radious, 2);
    if (circle < sqrtRadius)
    {
        return 1;
    }
    return 0;
}
~~~



# 15. Smoothstep

- [smoonthstep](https://developer.download.nvidia.com/cg/smoothstep.html)

~~~
+----------+----------+----------+----------+
1(from)    0.75       0.5(to)    0.25       0

float smoothstep(float a, float b, float x)
{
    float t = saturate((x - a)/(b - a));
    return t*t*(3.0 - (2.0*t));
}
~~~

| from | to  |            |        |
|------|-----|------------|--------|
| 1    | 0.5 | texcoord.x | return |
| 1    | 0.5 | 0          | 1      |
| 1    | 0.5 | 0.25       | 1      |
| 1    | 0.5 | 0.5        | 1      |
| 1    | 0.5 | 0.75       | 0.5    |
| 1    | 0.5 | 1          | 0      |



# 16. Circle Fading Edges
#TODO



# 17. Pattern Animation
sin / abs



# 18. Vertex Animation
- 깃발을 sin으로 흔들고 `* (uv.x * amplitude)`로 위치 보정.


# 19. Normals
- face normal
- vertex normal



# 20. Normal-Vertex Animation
부풀리기 축소하기



# 21. Rendering Pipeline - part 1
# 22. Rendering Pipeline - part 2
- **TODO 이거 다시 쌈박하게 정리해야함.**
~~~
RenderState
- Vertex shader
- Pixel shader
- texture
- Lighting setting

DrawCall

[RenderState] [Draw A] [Draw B] [Draw C]
Batches - RenderState 변화 ABC 동일 RenderState
Saved by batching - A다음에 오는 B, C를 그릴 동안 RenderState변화가 없음.

Batches : 1     Saved by batching : 2
DrawCall - 3
~~~


# 23. Normal Maps _ Types
- ref: http://wiki.polycount.com/wiki/Normal_Map_Technical_Details
- 우리가 맨날 보는 퍼런맵은 Tangent-Space Normal Map임.
- 근데 왜 쓰는지 좀 알아보자.

## World-Space Normal Map
UP = blue
- does not require additional per-pixel transforms, so it works faster.
- won’t work right if your object changes shape (character animations)
- World-space is basically the same as object-space, except it requires the model to remain in its original orientation, neither rotating nor deforming, so it’s almost never used.

## Object-Space Normal Map
- forward/backward face기반(+z, -z).
- Normal의 xyz를 rgb로 Texture에 저장.
- 따라서 x, y, z가 0~1사이의 모든 방향으로 적절하게 분배되어 알록달록하게 보임.

## Tangent-Space Normal Map
- forward face기반.
Tangent Vector는 Normal Vector와 수직인 벡터이다(여러개...)
따라서 통상적으로 UV 좌표와 비교하여
- Tangent Vector: U 좌표와 일치하는 Vector
- BiTangent Vector: V 좌표와 일치하는 Vector

TBN-matrix
(Tangent Binormal Normal)
TBN = | Tx Ty Tz |
      | Bx By Bz |
      | Nx Ny Nz |
- 노멀맵이 적용된 물체의 표면을 기준으로 Normal Vector값을 연산하여 저장한 이미지이다.
- 물체는 보통 표면의 바깥(z)으로 튀어 나오므로 주로 파랗게 보임.
Predominantly-blue colors. Object can rotate and deform. Good for deforming meshes, like characters, animals, flags, etc.

- Easier to overlay painted details.
- Easier to use image compression.
- Slightly slower performance than an object-space map (but not by much).



- Right handedness, which coincides with OpenGL is indicated with a plus sign (ex. +Y)
- Left handedness, which coincides with DirectX, is indicated with a negative sign (ex. -Y)

| Software | Red | Green | Blue |
| -------- | --- | ----- | ---- |
| Maya     | X+  | Y+    | Z+   |
| Blender  | X+  | Y+    | Z+   |
| Unity    | X+  | Y+    | Z+   |
| 3ds Max  | X+  | Y-    | Z+   |
| Unreal   | X+  | Y-    | Z+   |



## 24 - Points and Vectors
#pass



## 25. Vector Multiplication

이거 이름 햇갈리기 쉬움.

| Dot Product   | Inner Product | 내적 |
- 닷은 점이니까 모이는건 내적
- 점이니까 두개 모아서 하나가 됨.
- 하나로 모이니 두 벡터 사이의 각도를 구할 수 있음.
- 각도니까 cos연산 들어감.
- https://rfriend.tistory.com/145



| Cross Product | Outer Product | 외적 |
- 크로스는 삐죽하니까 외적으로 외울껏.
- X 니까 삐저나옴.
- X가 직각이니 수직 구할때 씀.
- https://rfriend.tistory.com/146

교환법칙 성립안함

~~~
손가락 맨날 햇갈림 이케 외우자.
X : 엄지(엄지는 항상 오른쪽방향으로)
Y : 검지(검지는 항상 위쪽)
Z : 중지

X x Z = Y : 오른손 좌표계 - OpenGL(since 1992) '오'픈 지엘이니(or 먼저나왔으니) 오른쪽.
  /Z
 /
+---- X
|
|
Y
  Y
  |
  |
  +---- X
 /
/
Z

X x Z = Y : 왼손 좌표계 - DirectX(since 1995) 나중에 나왔으니 왼쪽.
Y
| /Z
|/
+---- X
~~~


## 26. Normal Map Shader - intro
TBN : (Tangent Binormal Normal)

~~~
(Object-space)TBN-matrix * (Tangent-space)Normal = (Object-space)Normal
(World-space)TBN-matrix * (Tangent-space)Normal = (World-space)Normal

(Tangent-space) Normal
* (Object-space)TBN-matrix
* Object2World / unity_ObjectToWorld
= (World-space) Normal


(Tangent-space) Normal
* (World-space)TBN-matrix
= (World-space) Normal
~~~

(World-space) TBN-matrix
~~~
v.normal
v.tangent
binormal = cross(normal, tangent)
--------------------------------
world-space normal = object-space normal * unity_WorldToObject
world-space tangent = object-space tangent * unity_ObjectToWorld
world-space binormal = cross(world-space normal, world-space tangent)
~~~

* 둘다 ObjectToWorld는 ? scale (1, 1, 1) =>  (2, 2, 2) 처럼 균등이면 문제가 없다. 하지만, 메쉬가 기울어져있으면,
    - https://forum.unity.com/threads/world-space-normal.58810/
    - https://stackoverflow.com/questions/13654401/why-transforming-normals-with-the-transpose-of-the-inverse-of-the-modelview-matr
    - normal은 표면에 수직이기에, 기울어져 shifting이 발생(틀린 라이트닝 발생.)
    - tangent는 표면가 밀착되었기에, 문제없음.
    - Even with the inverse-transpose transformation, normal vectors may lose their unit length; thus, they may need to be renormalized after the transformation.

![figure10.8](./res/figure10.8.jpg)

    world-space normal = object-space normal * unity_ObjectToWorld
    world-space tangent = object-space tangent * unity_ObjectToWorld
    world-space binormal = cross(world-space normal, world-space tangent)

- 유니티의 rgb 입력 범위는 [0 ~ 1]
- 유니티의 노멀의 범위는 [-1 ~ 1]
- n따라서 rgb에서 노멀의 구할려면 범위를 2배로 늘리고, -1만큼 이동시켜줘야함.
- (color channel * 2) - 1


## 27. DXT-Compression
- 손실압축.
- https://en.wikipedia.org/wiki/S3_Texture_Compression
- https://www.fsdeveloper.com/wiki/index.php?title=DXT_compression_explained
- 4x4 픽셀 중에, 색 2개를 고름. 2개의 색을 interpolation시켜서 4x4 color 인덱스를 만듬.

 - 노멀맵 같은 경우에는 red채널의 변화가 심하기 때문에, R채널을 A채널로 바꾸고 DXT5로 저장한 후 shader에서 AGB로 접근하여 샘플링하면 상당히 괜찮은 결과를 얻어낼 수 있습니다.
    - https://gpgstudy.com/forum/viewtopic.php?t=24598


- DXT1 포맷을 이용.

| V | color | channel | bit |
|---|-------|---------|-----|
| X | R     | color0  | 16  |
| Y | G     | color1  | 16  |
| Z | B     | x       | 0   |

- DXT5nm 포맷을 이용(퀄리티 업.)

| V | color | channel       | bit |
|---|-------|---------------|-----|
| X | R     | a0, a1        | 16  |
|   |       | alpha indices | 48  |
| Y | G     | color0,1      | 32  |
|   |       | color indices | 32  |
| Z | B     | x             | 0   |

- xyzw, wy => _g_r => rg => xyn // r이 뒤로 있으므로, 한바퀴 돌려줘야함.
- `normal.xy = packednormal.wy * 2 - 1;` (0 ~ 1 => -1 ~ 1)
- `Z`는 쉐이더에서 계산. 단위 벡터의 크기는 1인것을 이용.(sqrt(x^2 + y^2 + z^2) = 1)



## DXT1, (RGB 5:6:5), (RGBA 5:5:5:1)
|               |                |
|---------------|----------------|
| color0        | 16             |
| color1        | 16             |
| color indices | 4 * 4 * 2 = 32 |

    (RGB)24 * 16 = 384
    384 / 64 = 6
    6배를 아낄 수 있다.

## DXT3

|               |                |
|---------------|----------------|
| alpha         | 64             |
| color0        | 16             |
| color1        | 16             |
| color indices | 4 * 4 * 2 = 32 |


    (RGBA)32 * 16 = 512
    512 / 128 = 4
    4배를 아낄 수 있다.

## DXT5

|               |                |
|---------------|----------------|
| a0            | 8              |
| a1            | 8              |
| alpha indices | 48             |
| color0        | 16             |
| color1        | 16             |
| color indices | 4 * 4 * 2 = 32 |

    R4G4B4A4
    R4G4B4A4 (출력시 보간 A8)

- DXT5nm : https://github.com/castano/nvidia-texture-tools/wiki/NormalMapCompression
- normalmap compression : https://mgun.tistory.com/1892
- Texture types : http://wiki.polycount.com/wiki/Texture_types
- https://www.nvidia.com/object/real-time-normal-map-dxt-compression.html
- bc5 : https://docs.microsoft.com/en-us/windows/desktop/direct3d10/d3d10-graphics-programming-guide-resources-block-compression#bc5



## (Tangent-space) normal map to (World-space) normal

### tangent to dxt

    (Object-space) tangent * model matrix(_Object2World) = (World-space) tangent
    t.x =R=> 0 ~ 1 = `(r * 2) - 1` => -1 ~ 1
    t.y =G=>
    t.z =B=>

    R => dxt.alpha
    G => dxt.color0, 1


# 28. Normal Map Shader - part 1
# 29. Normal Map Shader - part 2

    o.normalWorld = normalize(mul(v.normal, unity_WorldToObject));
    o.tangentWorld = normalize(mul(v.tangent, unity_ObjectToWorld));
    o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w);


    uniform sampler2D _MainTex;
    uniform float4 _MainTex_ST;


* `UV`, `ST` 도대체 뭐야.
    - 3d 좌표계에서 xyzw 취함. uv남음. st남음.
    - uv - 텍스처 좌표계
    - st - 텍셀(texel = Texture + pixel) 좌표계


~~~
UV - texture's coordinate
       +----+ (1, 1)
       |    |
(0, 0) +----+

ST - surface's coordinate space.
       +----+ (32, 32)
       |    |
(0, 0) +----+

    o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw)

|    |        |
|----|--------|
| xy | tiling |
| zw | offset |
~~~

* 나중에 확인해볼껏 (http://egloos.zum.com/chulin28ho/v/5339578)

    일반적인 노멀맵은 (탄젠트, 바이노멀, 노멀) 순서로 저장 되어 있습니다.
    하지만, DirectX의 경우 표준좌표계는 (탄젠트, 노멀, 바이노멀) 순입니다.


* [노말맵은 왜 파란가?](https://www.youtube.com/watch?v=Y3rn-4Nup-E)
    - y는 뒤집어 저장하여 아티스트가 보기 편하도록 저장하는게 작업 효율이 좋다더라.

# 30. Outline Shader - intro
# 31. Outline Shader - code
# 32. Author_s Check-in
# 33. Multi Variant Shader and Cginc files
# 34. Multi Variant Shader - part 1
# 35. Multi Variant Shader - part 2
# 36. Basic Lighting Model and Rendering Path - part 1
# 36. Basic Lighting Model and Rendering Path - part 2
# 38. Diffuse Reflection - intro
# 39. Diffuse Reflection - code 1
# 39. Diffuse Reflection - code 2
