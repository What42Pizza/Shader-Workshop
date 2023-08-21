//-------------------//
//        TAA        //
//-------------------//

// This code was taken from Complementary Reimagined
// Link: https://modrinth.com/shader/complementary-reimagined



const int clampingOffsetCount = 8;
ivec2 clampingOffsets[clampingOffsetCount] = ivec2[clampingOffsetCount](
	ivec2(-1, -1),
	ivec2( 0, -1),
	ivec2( 1, -1),
	ivec2(-1,  0),
	ivec2( 1,  0),
	ivec2(-1,  1),
	ivec2( 0,  1),
	ivec2( 1,  1)
);



// Previous frame reprojection from Chocapic13
vec2 reprojection(vec3 pos, vec3 cameraOffset) {
	pos = pos * 2.0 - 1.0;
	
	vec4 viewPosPrev = gbufferProjectionInverse * vec4(pos, 1.0);
	viewPosPrev /= viewPosPrev.w;
	viewPosPrev = gbufferModelViewInverse * viewPosPrev;
	
	vec4 previousPosition = viewPosPrev + vec4(cameraOffset, 0.0);
	previousPosition = gbufferPreviousModelView * previousPosition;
	previousPosition = gbufferPreviousProjection * previousPosition;
	return previousPosition.xy / previousPosition.w * 0.5 + 0.5;
}



void neighbourhoodClamping(vec3 color, inout vec3 prevColor, float rawDepth) {
	float depth = toLinearDepth(rawDepth);
	vec3 minColor = color;
	vec3 maxColor = color;
	
	for (int i = 0; i < clampingOffsetCount; i++) {
		ivec2 offsetCoord = texelcoord + clampingOffsets[i];
		vec3 offsetColor = texelFetch(MAIN_BUFFER, offsetCoord, 0).rgb;
		minColor = min(minColor, offsetColor);
		maxColor = max(maxColor, offsetColor);
	}
	
	prevColor = clamp(prevColor, minColor, maxColor);
}



void doTAA(inout vec3 color, inout vec3 newPrev, float depth, float linearDepth, vec2 prevCoord, float handFactor) {
	
	if (
		prevCoord.x < 0.0 || prevCoord.x > 1.0 ||
		prevCoord.y < 0.0 || prevCoord.y > 1.0
	) {
		newPrev = color;
		return;
	}
	
	vec3 prevColor = texture2D(TAA_PREV_BUFFER, prevCoord).rgb;
	
	neighbourhoodClamping(color, prevColor, depth);
	
	const float blendMin = 0.3;
	const float blendMax = 0.98;
	const float blendVariable = 0.2;
	const float blendConstant = 0.65;
	const float depthFactor = 0.13;
	
	vec2 velocity = (texcoord - prevCoord.xy) * viewSize;
	float velocityAmount = dot(velocity, velocity) * 10.0;
	
	float blendAmount = blendConstant
		+ exp(-velocityAmount) * blendVariable
		+ sqrt(linearDepth) * depthFactor
		+ handFactor;
	blendAmount = clamp(blendAmount, blendMin, blendMax);
	//blendAmount *= float(
	//	prevCoord.x > 0.0 && prevCoord.x < 1.0 &&
	//	prevCoord.y > 0.0 && prevCoord.y < 1.0
	//);
	
	color = mix(color, prevColor, blendAmount);
	newPrev = color;
	
}
