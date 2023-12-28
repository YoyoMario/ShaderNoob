
# Shader Noob

This project started a new journey for me. Breaking down shader implementation and combining them in the latest step. This technique allows me to comprehend what's going on.

This repository will remain public, to serve others the same purpose if needed.


## #1 Portal Shader

Inspiration for this shader came from [Cyan's Twitter](https://twitter.com/Cyanilux/status/1124280282285248512) post.

![](https://github.com/YoyoMario/ShaderNoob/blob/main/Assets/Simple%20Portal/github%20image.gif)
![](https://github.com/YoyoMario/ShaderNoob/blob/main/Assets/Simple%20Portal/github%20image%201.gif)

## #2 Hologram Shader

Inspiration for this shader came from [Cyan's Twitter]([https://twitter.com/Cyanilux/status/1124280282285248512](https://twitter.com/Cyanilux/status/1126814494058061824)) post.
Except, this was done for flat surfaces or UI, I did it for 3D objects.
I came across multiple issues whilst developing this: 
- glittering effect which was a result of oversaturated colors since I was adding multiple result values
- depth pre-pass was missing, and I could see different meshes of the same material behind the original model which was looking odd

![](https://github.com/YoyoMario/ShaderNoob/blob/main/Assets/Hologram/ezgif-5-e7e4bcfad5.gif)

