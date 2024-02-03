#include "/lib/aces.glsl"



// custom tonemapper, probably trash according to color theory
vec3 simpleTonemap(vec3 color) {
	vec3 lowCurve = color * color;
	vec3 highCurve = 1.0 - 1.0 / (color * 10.0 + 1.0);
	return mix(lowCurve, highCurve, color);
}



void doColorCorrection(inout vec3 color) {
	
	// brightness
	color *= (BRIGHTNESS - 1.0) / 1.5 + 1.0;
	
	// tonemapper
	color = max(color, 0.0);
	#if TONEMAPPER == 0
		color = min(color, vec3(1.0));
	#elif TONEMAPPER == 1
		color = smoothMin(color, vec3(1.0), 0.01);
	#elif TONEMAPPER == 2
		color = simpleTonemap(color);
	#elif TONEMAPPER == 3
		color = acesFitted(color);
	#endif
	
	#ifdef USE_GAMMA_CORRECTION
		color = sqrt(color);
	#endif
	
	// contrast
	color = mix(CONTRAST_DETECT_COLOR, color, (CONTRAST - betterRainStrength * 0.15) / 5.0 + 1.0);
	
	// saturation & vibrance
	float colorLum = getColorLum(color);
	vec3 lumDiff = color - colorLum;
	float saturationAmount = (SATURATION + SATURATION_LIGHT * pow3(colorLum) + SATURATION_DARK * pow3(1 - colorLum) * 2.0 - betterRainStrength * 0.1) / 2.0;
	float vibranceAmount = maxAbs(lumDiff);
	vibranceAmount = sqrt(vibranceAmount);
	vibranceAmount *= pow10(1 - vibranceAmount * vibranceAmount) * VIBRANCE * 3.0;
	color += lumDiff * (saturationAmount + vibranceAmount);
	
	color.b += betterRainStrength * 0.01;
	
	#ifdef USE_GAMMA_CORRECTION
		#if GAMMA == 0
			color = pow2(color);
		#else
			const float realGamma = float(GAMMA) / 10.0;
			const float gammaMult = 1.0 - realGamma / 2.0;
			color = pow(color, vec3(2.0 * gammaMult));
		#endif
	#endif
	
}
