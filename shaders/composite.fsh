#version 330 compatibility

/* 
 * REALISM ENGINE - LABPBR 1.3 & POM PIPELINE
 * Shader GLSL optimizado para Iris/Sodium
 */

uniform sampler2D gtexture;   // Albedo (Color base)
uniform sampler2D normals;    // Mapas de Normales + Altura (POM)
uniform sampler2D specular;   // LabPBR (R=Smoothness, G=Metal, B=Porosity, A=Emissive)
uniform sampler2D depthtex0;  

in vec4 color;
in vec2 texcoord;
in vec3 viewVector;

out vec4 fragColor;

// Algoritmo de Parallax Occlusion Mapping (POM) de alto rendimiento
vec2 calculatePOM(vec2 uv, vec3 viewDir) {
    float scale = 0.04; // Intensidad del relieve 3D
    const float minLayers = 8.0;
    const float maxLayers = 32.0;
    float numLayers = mix(maxLayers, minLayers, abs(dot(vec3(0.0, 0.0, 1.0), viewDir)));
    
    float layerDepth = 1.0 / numLayers;
    float currentLayerDepth = 0.0;
    
    vec2 P = viewDir.xy * scale; 
    vec2 deltaTexCoords = P / numLayers;
    
    vec2 currentTexCoords = uv;
    float currentDepthMapValue = 1.0 - texture(normals, currentTexCoords).a;
    
    while(currentLayerDepth < currentDepthMapValue) {
        currentTexCoords -= deltaTexCoords;
        currentDepthMapValue = 1.0 - texture(normals, currentTexCoords).a;
        currentLayerDepth += layerDepth;
    }
    
    return currentTexCoords;
}

void main() {
    vec2 finalUV = calculatePOM(texcoord, normalize(viewVector));
    
    vec4 albedo = texture(gtexture, finalUV) * color;
    vec4 normalData = texture(normals, finalUV);
    vec4 specData = texture(specular, finalUV);
    
    float roughness = 1.0 - specData.r;
    float metalness = specData.g;
    float emissive = specData.a; 
    
    vec3 N = normalize(normalData.rgb * 2.0 - 1.0);
    vec3 L = normalize(vec3(0.5, 1.0, 0.3)); 
    
    float diff = max(dot(N, L), 0.15); 
    vec3 finalLighting = albedo.rgb * diff;
    
    // Auto-iluminación incandescente para Lava y bloques emisivos
    if (emissive > 0.01) {
        finalLighting += albedo.rgb * emissive * 2.5;
    }

    fragColor = vec4(finalLighting, albedo.a);
}
