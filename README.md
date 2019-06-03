# TODO
- [white noise](https://www.ronja-tutorials.com/2018/09/02/white-noise.html)
- [날아다니는 나비 만들기](https://holdimprovae.blogspot.com/2019/02/studyunityshader.html)
- [Hbao Plus Analysis 0](https://hrmrzizon.github.io/2017/11/15/hbao-plus-analysis-0/)

- https://docs.unity3d.com/Manual/SL-DataTypesAndPrecision.html
- https://docs.unity3d.com/Manual/SL-ShaderPerformance.html

# 00.
- [Shader Development using Unity: Full Course](https://www.youtube.com/watch?v=FQ_5VQCc5XI&list=PL09X4HXJpa8kfw8cZjyYZel8WlOT5B1_k)
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



# 22. Rendering Pipeline - part 2
#pass



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
world-space normal = object-space normal * model matrix(_Object2World)
world-space tangent = object-space tangent * model matrix(_Object2World)
world-space binormal = cross(world-space normal, world-space tangent)
~~~


- 유니티의 rgb 입력 범위는 [0 ~ 1]
- 유니티의 노멀의 범위는 [-1 ~ 1]
- n따라서 rgb에서 노멀의 구할려면 범위를 2배로 늘리고, -1만큼 이동시켜줘야함.
- (color channel * 2) - 1


## 27. DXT-Compression
