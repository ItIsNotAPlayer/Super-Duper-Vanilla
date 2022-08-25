/// ------------------------------------- /// Vertex Shader /// ------------------------------------- ///

#ifdef VERTEX
    out vec2 texCoord;

    out vec4 glColor;

    #ifdef WORLD_CURVATURE
        uniform mat4 gbufferModelView;
        uniform mat4 gbufferModelViewInverse;
    #endif

    #if ANTI_ALIASING == 2
        /* Screen resolutions */
        uniform float viewWidth;
        uniform float viewHeight;

        #include "/lib/utility/taaJitter.glsl"
    #endif

    void main(){
        texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        
	    #ifdef WORLD_CURVATURE
            // Feet player pos
            vec4 vertexPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

            vertexPos.y -= dot(vertexPos.xz, vertexPos.xz) / WORLD_CURVATURE_SIZE;
            
            // Clip pos
            gl_Position = gl_ProjectionMatrix * (gbufferModelView * vertexPos);
        #else
            gl_Position = ftransform();
        #endif

        #if ANTI_ALIASING == 2
            gl_Position.xy += jitterPos(gl_Position.w);
        #endif

        glColor = gl_Color;
    }
#endif

/// ------------------------------------- /// Fragment Shader /// ------------------------------------- ///

#ifdef FRAGMENT
    in vec2 texCoord;

    in vec4 glColor;

    // Get albedo texture
    uniform sampler2D texture;

    void main(){
        vec4 albedo = texture2D(texture, texCoord) * glColor;

        // Alpha test, discard immediately
        if(albedo.a <= ALPHA_THRESHOLD) discard;

        #if WHITE_MODE == 1
            albedo.rgb = vec3(1);
        #elif WHITE_MODE == 2
            albedo.rgb = vec3(0);
        #elif WHITE_MODE == 3
            albedo.rgb = glColor.rgb;
        #endif

    /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(toLinear(albedo.rgb) * EMISSIVE_INTENSITY, albedo.a); // gcolor
    }
#endif