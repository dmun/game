#version 330 core
layout(location = 0) in vec3 aPos;
layout(location = 1) in vec3 aColor;

out vec3 ourColor;

uniform float ourOffset;

void main()
{
    vec3 newPos = aPos;
    newPos.x += ourOffset;
    gl_Position = vec4(newPos, 1.0);
    ourColor = aColor;
}
