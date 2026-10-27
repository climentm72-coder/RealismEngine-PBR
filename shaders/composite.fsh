#version 130

/* 
 * REALISM ENGINE - ULTRA LIGHTWEIGHT PBR & POM PIPELINE
 * Compatible con Iris, Sodium y OpenGL 3.2+
 */

uniform sampler2D gtexture;   // Albedo base
uniform sampler2D normals;    // Mapas de normales (LabPBR)
uniform sampler2D specular;   // Mapas especulares (LabPBR)

varying vec4 color;
varying vec2 texcoord;
varying vec3 viewVector;

// Algoritmo POM optimizado compatible con OpenGL 3.2
vec2 calculatePOM(vec2 uv, vec3 viewDir) {
    float scale = 0.04;
    const float minLayers = 8.0;
    const float maxLayers = 32.0;
    float numLayers = mix(maxLayers, minLayers, abs(dot(vec3(0.0, 0.0, 1.0), viewDir)));
    
    float layerDepth = 1.0 / numLayers;
    float currentLayerDepth = 0.0;
    
    vec2 P = viewDir.xy * scale; 
    vec2 deltaTexCoords = P / numLayers;
    
    vec2 currentTexCoords = uv;
    float currentDepthMapValue = 1.0 - texture2D(normals, currentTexCoords).a;
    
    for(int i = 0; i < 32; i++) {
        if(currentLayerDepth >= currentDepthMapValue) break;
        currentTexCoords -= deltaTexCoords;
        currentDepthMapValue = 1.0 - texture2D(normals, currentTexCoords).a;
        currentLayerDepth += layerDepth;
    }
    
    return currentTexCoords;
}

void main() {
    vec3 normalizedView = length(viewVector) > 0.0 ? normalize(viewVector) : vec3(0.0, 0.0, 1.0);
    vec2 finalUV = calculatePOM(texcoord, normalizedView);
    
    vec4 albedo = texture2D(gtexture, finalUV) * color;
    vec4 normalData = texture2D(normals, finalUV);
    vec4 specData = texture2D(specular, finalUV);
    
    float emissive = specData.a; 
    
    vec3 N = normalize(normalData.rgb * 2.0 - 1.0);
    vec3 L = normalize(vec3(0.5, 1.0, 0.3)); 
    
    float diff = max(dot(N, L), 0.2); 
    vec3 finalLighting = albedo.rgb * diff;
    
    // Auto-emisión de lava e iluminación incandescente
    if (emissive > 0.01) {
        finalLighting += albedo.rgb * emissive * 2.5;
    }

    gl_FragColor = vec4(finalLighting, albedo.a);
}
