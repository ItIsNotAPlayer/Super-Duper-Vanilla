// Fragment GL version
#version 330 compatibility

#define GBUFFERS
#define PARTICLES_TRANSLUCENT
#define FRAGMENT

#include "/lib/settings.glsl"
#include "/lib/utility/common.glsl"

#include "world.glsl"
#include "/main/gbuffers/gbuffers_particles_translucent.glsl"