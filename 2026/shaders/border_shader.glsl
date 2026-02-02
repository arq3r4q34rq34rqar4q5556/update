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
    bool rainbow = (abs(v_color.a - RAINBOW) < eps);
    bool emptyCell = (abs(v_color.a - EMPTY_CELL) < eps);

    if (emptyCell){ drawEmptyCell(); return; }
    if (rainbow) { needBorder = true; }
    if (disableCircleCrop) { gl_FragColor =  texColor * vec4(v_color.r, v_color.g, v_color.b, 1.0); return; }

    float len = length(CENTER_COORD - v_texCoords);

    if (!needBorder) {
        // This part is for non-bordered cells (like food), we leave it as is.
        gl_FragColor = (smoothstep(RADIUS+BORDER/div, RADIUS+BORDER/div-SOFTNESS, len)) * texColor * v_color;
    } else { 
        // --- START: SIGMA CLIENT "COSMIC" GLOW V2 ---

        // 1. Define Geometry & Borders
        float border_width = BORDER * 2.5;
        float cell_radius = RADIUS - border_width;

        // 2. Create the "Cosmic Aurora" color
        float aurora_angle = v_time * 0.4 + v_texCoords.y * 15.0;
        vec3 colorA = vec3(0.1, 0.0, 0.4); // Deep Space Blue
        vec3 colorB = vec3(0.9, 0.3, 1.0); // Nebula Magenta
        vec3 aurora_color = mix(colorA, colorB, 0.5 + 0.5 * cos(aurora_angle));

        // 3. Create a sparkling "Stardust" effect
        float grid_density = 150.0;
        vec2 star_coords = v_texCoords * grid_density;
        float star_hash = fract(sin(dot(star_coords, vec2(12.9898, 78.233))) * 43758.5453);
        float sparkle = pow(max(0.0, star_hash - 0.98), 2.0) * 100.0;
        float blink = 0.5 + 0.5 * sin(v_time * 3.0 + star_hash * 30.0);
        vec3 stardust_color = vec3(1.0, 1.0, 0.8) * sparkle * blink;

        // 4. Define the Glow Band
        float glow_band = smoothstep(cell_radius, cell_radius + SOFTNESS, len) - smoothstep(RADIUS, RADIUS + SOFTNESS, len);

        // 5. Combine effects for the final glow color
        vec3 final_glow = (aurora_color + stardust_color) * glow_band;

        // 6. Get the cell's main color (from player's choice, passed in v_color)
        vec4 final_cell_color = v_color;

        // Crop the cell color to a clean circle. The glow will exist outside this crop.
        float cell_crop = 1.0 - smoothstep(cell_radius, cell_radius + SOFTNESS, len);
        final_cell_color *= cell_crop;
        
        // 7. Combine Cell Color and Glow
        // Additive blending ensures the glow is AROUND the cell, not ON it.
        gl_FragColor = vec4(final_cell_color.rgb + final_glow, final_cell_color.a + glow_band);

        // --- END: SIGMA CLIENT "COSMIC" GLOW V2 ---
    }
}
