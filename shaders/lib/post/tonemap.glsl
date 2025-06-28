const float oneMinusShoulder = 1.0 - SHOULDER_STRENGTH;

const float shoulderFactor = oneMinusShoulder * 3.0;
const float shoulderWhitePointFactor = oneMinusShoulder / (WHITE_POINT * WHITE_POINT);

// Luminance function
float getLuminance(in vec3 col){
	return dot(col, vec3(0.2126, 0.7152, 0.0722));
}

// Saturation function
vec3 saturation(in vec3 col, in float a){
	float luma = getLuminance(col);
	return (col - luma) * a + luma;
}

// Contrast function
vec3 contrast(in vec3 col, in float a){
	return (col - 0.5) * a + 0.5;
}

// Modified Reinhard extended luminance tonemapping
vec3 modifiedReinhardExtended(in vec3 color){
	float sumCol = sumOf(color);
	return color * ((3.0 + sumCol * shoulderWhitePointFactor) / (shoulderFactor + sumCol));
}

/*
vec3 modifiedReinhardExtended(in vec3 color){
	color *= EXPOSURE;
	float sumCol = sumOf(color);
	float rainHardFactor = (3.0 + sumCol * shoulderWhitePointFactor) / (shoulderFactor + sumCol);
	vec3 tonemapped = color * rainHardFactor;

	// Color tinting, exposure, and tonemapping
    const float coefficient = exp2(EXPOSURE) - 1.0;
	vec3 exposureFactor = (coefficient * tonemapped) / (1.0 + (coefficient - 1.0) * tonemapped);

	return tonemapped;
}

float coefficient = EXPOSURE * 0.00392156863;
(coefficient * color + color) / (coefficient * color + 1.0)
(coefficient * color) / (1.0 + (coefficient - 1.0) * color)
*/

// Modified Reinhard Jodie extended tonemapping
// Might eventually become an option...maybe
vec3 modifiedReinhardJodieExtended(in vec3 color){
	float sumCol = sumOf(color);

	vec3 reinhardColorFactor = color * ((1.0 + color * shoulderWhitePointFactor) / (oneMinusShoulder + color));
	vec3 reinhardLumaFactor = color * ((3.0 + sumCol * shoulderWhitePointFactor) / (shoulderFactor + sumCol));

	return (reinhardColorFactor - reinhardLumaFactor) * reinhardColorFactor + reinhardLumaFactor;
}

uint maxIndex(vec3 v){
    // Compare y > x and z > max(x, y)
    bool y_gt_x = v.y > v.x;
    bool z_gt_y = v.z > v.y;
    bool z_gt_x = v.z > v.x;

    // Convert booleans to uints (true=1, false=0)
    uint is_z_max = uint(z_gt_x && z_gt_y);
    uint is_y_max = uint(y_gt_x && !z_gt_y);

    // Index is 2 if z is max, 1 if y is max, 0 otherwise (x is max)
    return is_z_max * 2u + is_y_max;
}

uint minIndex(vec3 v){
    // Compare y > x and z > max(x, y)
    bool y_gt_x = v.y < v.x;
    bool z_gt_y = v.z < v.y;
    bool z_gt_x = v.z < v.x;

    // Convert booleans to uints (true=1, false=0)
    uint is_z_max = uint(z_gt_x && z_gt_y);
    uint is_y_max = uint(y_gt_x && !z_gt_y);

    // Index is 2 if z is max, 1 if y is max, 0 otherwise (x is max)
    return is_z_max * 2u + is_y_max;
}

#define DESATURATION_AMOUNT 0.0

vec3 resaturatedTonemap(vec3 color){
    float maxC = maxOf(color);
    uint maxIdx = maxIndex(color);

    float minC = minOf(color);
    uint minIdx = minIndex(color);
	
    float S     = (maxC - minC) / maxC; // Target saturation
    uint midIdx = 3u - (maxIdx + minIdx);
    float midC = color[midIdx];

    // DESATURATION_AMOUNT controls the desaturation of very bright areas (default = 0.35)
    S *= 1.0 * inversesqrt(squared(maxC * DESATURATION_AMOUNT) + 1.0);

    // Any tonemap you'd like
    color = color / (1.0 + color);

    // Redefine color values
    maxC = maxOf(color);
    minC = minOf(color);
    midC = color[3u - (maxIdx + minIdx)];

    // Calculate Interpolation Factor
    float k = (midC - minC) / (maxC - minC);

    // Resaturate color
    color[maxIdx] = maxC;
    color[minIdx] = (1.0 - S) * maxC;
    color[midIdx] = maxC * (1.0 - S * (1.0 - k));

    return color;
}