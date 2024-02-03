flat vec2 lightCoord;
flat float sunraysAmountMult;



#ifdef FSH

const int SAMPLE_COUNT = int(SUNRAYS_QUALITY * SUNRAYS_QUALITY / 2);
float getSunraysAmount(inout uint rng) {
	
	
	#if SUNRAYS_STYLE == 1
		vec2 pos = texcoord;
		float noise = (randomFloat(rng) - 1.0) * 0.2 + 1.0;
		vec2 coordStep = (lightCoord - pos) / SAMPLE_COUNT * noise;
		
	#elif SUNRAYS_STYLE == 2
		vec2 pos = texcoord;
		vec2 coordStep = (lightCoord - pos) / SAMPLE_COUNT;
		float noise = randomFloat(rng) * 0.7;
		pos += coordStep * noise;
		
	#endif
	
	float total = 0.0;
	for (int i = 1; i < SAMPLE_COUNT; i ++) {
		#ifdef SUNRAYS_FLICKERING_FIX
			if (pos.x < 0.0 || pos.x > 1.0 || pos.y < 0.0 || pos.y > 1.0) {
				total *= float(SAMPLE_COUNT) / i;
				break;
			}
		#endif
		float depth = texelFetch(DEPTH_BUFFER_ALL, ivec2(pos * viewSize), 0).r;
		if (depthIsSky(toLinearDepth(depth))) {
			total += 1.0 + float(i) / SAMPLE_COUNT;
		}
		pos += coordStep;
	}
	total /= SAMPLE_COUNT;
	
	if (total > 0.0) total = max(total, 0.2);
	
	float output = sqrt(total) * sunraysAmountMult;
	output *= max(1.0 - length(lightCoord - 0.5) * 1.5, 0.0);
	
	return output;
}

#endif



#ifdef VSH

void calculateLightCoord() {
	
	vec3 lightPos = shadowLightPosition * mat3(gbufferProjection);
	lightPos /= lightPos.z;
	lightCoord = lightPos.xy * 0.5 + 0.5;
	
}

// this entire function SHOULD be computed on the cpu, but it has to be glsl code because it uses settings that are ONLY defined in glsl
void calculateSunraysAmount() {
	
	sunraysAmountMult =
		rawSkylightPercents.x * SUNRAYS_AMOUNT_DAY +
		rawSkylightPercents.y * SUNRAYS_AMOUNT_NIGHT +
		rawSkylightPercents.z * SUNRAYS_AMOUNT_SUNRISE +
		rawSkylightPercents.w * SUNRAYS_AMOUNT_SUNSET;
	
	if (isOtherLightSource) {
		if (isSun) {
			sunraysAmountMult *= rawSkylightPercents.x + rawSkylightPercents.z + rawSkylightPercents.w;
		} else {
			sunraysAmountMult *= rawSkylightPercents.y;
		}
	}
	
	sunraysAmountMult *= 1.0 - betterRainStrength * 0.7;
	
	sunraysAmountMult *= 0.3;
	
}

#endif
