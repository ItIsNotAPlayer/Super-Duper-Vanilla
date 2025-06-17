float getOutline(in ivec2 iUv, in float depthOrigin, in bool realSky){
    ivec2 topRightCorner = iUv - OUTLINE_PIXEL_SIZE;
    ivec2 bottomLeftCorner = iUv + OUTLINE_PIXEL_SIZE;

    // (1.0 - screenPos.z) / near
    // near / (1.0 - screenPos.z)

    #if OUTLINES == 1
        float nearPlane = near;

        #ifdef DISTANT_HORIZONS
            if(realSky) nearPlane = dhNearPlane;
        #endif

        float depth0 = nearPlane / (1.0 - getDepthTex(topRightCorner));
        float depth1 = nearPlane / (1.0 - getDepthTex(bottomLeftCorner));
        float depth2 = nearPlane / (1.0 - getDepthTex(ivec2(topRightCorner.x, bottomLeftCorner.y)));
        float depth3 = nearPlane / (1.0 - getDepthTex(ivec2(bottomLeftCorner.x, topRightCorner.y)));

        float sumDepth = depth0 + depth1 + depth2 + depth3;

        // Calculate standard outlines
        return saturate(sumDepth - (nearPlane * 4.0) / (1.0 - depthOrigin));
    #else
        float depth0 = 64.0 / (1.0 - getDepthTex(topRightCorner));
        float depth1 = 64.0 / (1.0 - getDepthTex(bottomLeftCorner));
        float depth2 = 64.0 / (1.0 - getDepthTex(ivec2(topRightCorner.x, bottomLeftCorner.y)));
        float depth3 = 64.0 / (1.0 - getDepthTex(ivec2(bottomLeftCorner.x, topRightCorner.y)));

        float sumDepth = depth0 + depth1 + depth2 + depth3;

        // Calculate dungeons outlines
        return saturate((1.0 - depthOrigin) * sumDepth - 256.0);
    #endif
}