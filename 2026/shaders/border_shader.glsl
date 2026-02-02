#ifdef GL_ES
#define LOWP lowp
precision mediump float;
#else
#define LOWP
#endif

varying LOWP vec4 v_color;
varying vec2 v_texCoords;

varying float v_scale;  //jelly physics, to adjust crop and border radius
varying float v_time; // Sigma Client: Receive time from vertex shader

uniform sampler2D u_texture;

//RED AREA
uniform float u_curRadius;
uniform vec2 u_curPos;

uniform float u_nextRadius;
uniform vec2 u_nextPos;
uniform float u_raBorderWidth;
uniform int u_keepTexture;  //keep texture druing red area drawing

const vec2 CENTER_COORD = vec2(0.5, 0.5);

//SKIN BORDER
float RADIUS = 0.488;
float BORDER = 0.02;
float SOFTNESS = 0.005;
const float eps = 0.03;

// determine cell type by alpha
const float HAS_BORDER = 0.95;
const float RED_AREA = 0.90; // draw red area
const float NO_CROP = 0.85; //disable circle crop (used for nicknames)
const float RAINBOW = 0.80;
const float EMPTY_CELL = 0.75;


float div = 1.5; //offset to adjust image cropping and border width

void drawRedArea() {
    // Implementation remains the same
    float len, alpha;
    len = length(u_nextPos - v_texCoords);
    alpha = 1.0 + smoothstep(u_nextRadius, u_nextRadius + u_raBorderWidth, len) - smoothstep(u_nextRadius - u_raBorderWidth, u_nextRadius, len);
    if (u_keepTexture == 1) { gl_FragColor = texture2D(u_texture, v_texCoords); } else { gl_FragColor = vec4(1.0, 1.0, 1.0, 0.0); }
    gl_FragColor = mix(vec4(0.0, 1.0, 0.0, 0.6), gl_FragColor, alpha);
    len = length(u_curPos - v_texCoords);
    alpha = step(u_curRadius, len);
    gl_FragColor = mix(gl_FragColor,vec4(1.0, 0.0, 0.0, 0.7),  alpha * 0.7);
    alpha = 1.0 + smoothstep(u_curRadius, u_curRadius + u_raBorderWidth, len) - smoothstep(u_curRadius - u_raBorderWidth, u_curRadius, len);
    gl_FragColor = mix(vec4(1.0, 0.0, 0.0, 1.0), gl_FragColor, alpha);
    if (u_keepTexture == 1) { gl_FragColor.a = 0.4; }
}

void drawEmptyCell() {
    // Implementation remains the same
    float len = length(CENTER_COORD - v_texCoords);
    vec4 borderColor = vec4(0.84, 0.84, 0.84, 1.0);
    vec4 fillColor = vec4(1.0, 1.0, 1.0, 1.0);
    vec4 v_color2 = vec4(v_color);
    v_color2.a = 1.0;
    vec4 color;
    if (len < 0.5){ color = borderColor; if (len  < 0.5 * 0.954) { color = fillColor; } } else { color = vec4(0.0, 0.0, 0.0, 0.0); }
    gl_FragColor = color * v_color2;
}

void main()
{
    if (abs(v_color.a - RED_AREA) < eps) { drawRedArea(); return; }

    float scale = v_scale;
    RADIUS -= scale;

    vec4 texColor = texture2D(u_texture, v_texCoords);
    bool needBorder = (abs(v_color.a - HAS_BORDER) < eps);
    bool disableCircleCrop = (abs(v_color.a - NO_CROP) < eps);
    bool rainbow = (abs(v_color.a - RAINBOW) < eps); // We keep this flag to trigger our effect
    bool emptyCell = (abs(v_color.a - EMPTY_CELL) < eps);

    if (emptyCell){ drawEmptyCell(); return; }
    if (rainbow) { needBorder = true; }
    if (disableCircleCrop) { gl_FragColor =  texColor * vec4(v_color.r, v_color.g, v_color.b, 1.0); return; }

    float len = length(CENTER_COORD - v_texCoords);

    if (!needBorder) {
        // This part is for non-bordered cells (like food), we leave it as is.
        gl_FragColor = (smoothstep(RADIUS+BORDER/div, RADIUS+BORDER/div-SOFTNESS, len)) * texColor * v_color;
    } else { 
        // --- START: SIGMA CLIENT GLOW EFFECT ---

        // 1. Create a pulsating animation using time.
        float pulse = 0.5 + 0.5 * sin(v_time * 5.0);
        
        // 2. Define the two colors for our animated glow.
        vec3 colorA = vec3(0.5, 0.1, 1.0); // Vibrant Purple
        vec3 colorB = vec3(0.1, 0.8, 1.0); // Bright Cyan
        vec3 glowColor = mix(colorA, colorB, pulse); // Animate between colors.

        // 3. Calculate the rim factor. This determines where the glow appears.
        // We use smoothstep to create a soft, anti-aliased edge for the glow.
        float rim = 1.0 - smoothstep(RADIUS - BORDER, RADIUS, len);
        
        // 4. Combine the player's color with the texture, then add the glow.
        vec4 finalColor = texColor * v_color;
        finalColor.rgb = mix(finalColor.rgb, glowColor, rim);
        
        // 5. Crop the entire cell to a circle for a clean look.
        float circleCrop = 1.0 - smoothstep(RADIUS, RADIUS + SOFTNESS, len);
        finalColor.a *= circleCrop;

        gl_FragColor = finalColor;

        // --- END: SIGMA CLIENT GLOW EFFECT ---
    }
}
