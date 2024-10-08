#version 330 core
out vec4 FragColor;

in vec3 LightingColor;
in vec3 Normal;
in vec3 FragPos;
in vec3 LightPos;
in vec2 TexCoords;

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    float shininess;
};

struct Light {
    vec3 position;
    vec3 direction;
    float cutOff;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    float constant;
    float linear;
    float quadratic;
};

uniform vec3 objectColor;
uniform Material material;
uniform Light light;

void main()
{
    vec3 lightDir = normalize(-FragPos);
    float theta = dot(lightDir, normalize(-light.direction));

    if (theta > light.cutOff) {
        vec3 ambient = light.ambient * texture(material.diffuse, TexCoords).rgb;

        vec3 norm = normalize(Normal);
        float diff = max(dot(norm, lightDir), 0.0);
        vec3 diffuse = light.diffuse * diff * texture(material.diffuse, TexCoords).rgb;

        vec3 viewDir = normalize(-FragPos);
        vec3 reflectDir = reflect(-lightDir, norm);  
        float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
        vec3 specular = light.specular * spec * texture(material.specular, TexCoords).rgb;

        float distance = length(-FragPos);
        float attenuation = 1.0 / (light.constant + light.linear * distance + light.quadratic * (distance * distance));

        // ambient  *= attenuation; 
        diffuse  *= attenuation;
        specular *= attenuation;
        FragColor = vec4(ambient + diffuse + specular, 1.0);
    } else {
        FragColor = vec4(light.ambient * texture(material.diffuse, TexCoords).rgb, 1.0);
    }
}
