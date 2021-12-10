vec3 binarySearch(vec3 clipPosRayDir, vec3 startPos, int binarySearchSteps){
	for(int y = 0; y < binarySearchSteps; y++){
		vec3 screenPos = startPos * 0.5 + 0.5;
		if(screenPos.x < 0 || screenPos.y < 0 || screenPos.x > 1 || screenPos.y > 1) break;

		clipPosRayDir *= 0.5;
		startPos += texture2D(depthtex0, screenPos.xy).x < screenPos.z ? -clipPosRayDir : clipPosRayDir;
	}

	return startPos;
}

vec3 rayTraceScene(vec3 clipPos, vec3 viewPos, vec3 rayDir, int steps, int binarySearchSteps){
	// If hand, do simple, flipped reflections
	if(clipPos.z < 0.056){
		vec3 handScreenPos = toScreenSpacePos(toScreen(viewPos + rayDir * 128.0).xy);
		return vec3(handScreenPos.xy, handScreenPos.z != 1);
	}

	vec3 clipPosRayDir = toScreen(viewPos + rayDir) * 2.0 - 1.0; // Put it back to clip space...
	clipPosRayDir = normalize(clipPosRayDir - clipPos) * (2.0 / steps);

	// Clip pos is our startPos
	for(int x = 0; x < steps; x++){
		// We raytrace here
		clipPos += clipPosRayDir;
		vec3 newScreenPos = clipPos * 0.5 + 0.5;
		if(newScreenPos.x < 0 || newScreenPos.y < 0 || newScreenPos.x > 1 || newScreenPos.y > 1) return vec3(0);
		float currDepth = texture2D(depthtex0, newScreenPos.xy).x;

		if(newScreenPos.z > currDepth && (newScreenPos.z - currDepth) < 0.056){
			if(binarySearchSteps == 0) return vec3(newScreenPos.xy, currDepth != 1);
			return vec3(binarySearch(clipPosRayDir, clipPos, binarySearchSteps).xy * 0.5 + 0.5, currDepth != 1);
		}
	}
	
	return vec3(0);
}