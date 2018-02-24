"attribute vec2 a_position;     \n\
attribute vec2 a_texCoord;     \n\
     \n\
varying vec2 v_texCoord;     \n\
     \n\
void main(void) {     \n\
    gl_Position = vec4(a_position.xy, 0, 1);     \n\
\n\
    v_texCoord = a_texCoord;     \n\
}     \n\
"
