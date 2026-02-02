attribute vec4 a_position;
attribute vec4 a_color;
attribute vec2 a_texCoord0;

uniform mat4 u_projTrans;
uniform float u_time; // Sigma Client: Add time uniform for animation

varying vec4 v_color;
varying vec2 v_texCoords;
varying float v_scale;
varying float v_time; // Sigma Client: Pass time to fragment shader

void main() {
    v_color = a_color;
    v_texCoords = a_texCoord0;
    v_time = u_time; // Sigma Client: Pass time

    //for jelly physics
    //some vertices have scale from 0.7 to 1.0
    //and some from 0.0 to 0.3
    //we pass only value from 0.0 to 0.3 too all vercies
    //we set same value to all vertices so fragment shader do not interpolate it
    //interpolation can be disabled with "flat" interpolation qualifier,
    //but it's not present in opengl es 2.0

    if (a_texCoord0.x < 0.5) {
        v_scale = a_texCoord0.x;
    } else {
        v_scale = 1. - a_texCoord0.x;
    }

    gl_Position = u_projTrans * a_position;
}
