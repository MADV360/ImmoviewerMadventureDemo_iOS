"#ifdef GL_ES       \n\
precision highp float;       \n\
#endif       \n\
       \n\
varying vec2 v_texCoord;       \n\
       \n\
uniform sampler2D u_texture0;       \n\
       \n\
void main()       \n\
{       \n\
    gl_FragColor = texture2D(u_texture0, v_texCoord);       \n\
}       \n\
"
