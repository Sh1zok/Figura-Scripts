# Reanimated
Figura's animation implementation *sucks*<!-- AND SUCKS IT SO FUCKING HARD! --> so I made my own.
***
> [!CAUTION]
> This README.md file contains information that will be relevant in the\
> future but is not currently relevant. The script is still in the WIP stage.\
> Use the script only if you understand what you're doing.
***
## The whole story
It's no secret that Figura's animation implementation isn't the best.

There are several scripts that complement Figura's animations(for example, [GSAnimBlend](https://github.com/GrandpaScout/GSAnimBlend), [AnimationTags](https://github.com/Bitslayn/AnimationTags), [Aurianims](https://github.com/lua-gods/figura-libraries/tree/main/aurianims), etc.), and many avatar creators actively use them.

All of these scripts inject their solutions through [metatables](https://www.lua.org/pil/13.html), but sometimes injection isn't the answer. Sometimes a more in-depth approach is needed. For example, I needed to know whether a specific animation was affecting a specific model part at this time and the original implementation couldn't provide this data.<sup>>:T</sup>

So, I came up with the idea of ​​going deeper. I recreated the animation implementation from scratch to gain more control over animations and set limitations myself.

And before you get absolutely **amazed** or completely *terrified*<sub>(ipromisethisideaisnotthatbad)</sub>(It depends on how good you are at coding), let me tell you about my animation implementation - "Reanimated".
## Script purpose
This script was created to solve *fundamental* shortcomings in Figura animations such as:
* **Blendlessness** - Animations in Figura are *<ins>poorly</ins>* merging<sub>(or don't merge at all)</sub> with other animations, vanilla animations, and scripted transformations.
* **Lack of control** - Animations in Figura have minimal functionality for control. It is impossible to create/edit animation via script.
* **Disorganization** - Animations are not organized into any groups. It is *<ins>not</ins>* possible to play/stop multiple animations at once.
## How does this script solve these problems?
* **Intro/Outro & Blending** - Animations are now divided into three parts: an intro - the transition from the idle to the animation, the animation itself, and an outro - the transition from the animation to the idle. All gaps between parts will be blended.
* **Keyframe&Transformation tables** - Each animation now has a keyframes table. Keyframe changes are reflected in the animation in real time; Each model part now has its own individual transformation table, which records the transformation sources.
* **Tags** - You can now assign tags to animations. Using tags, you can interact with multiple animations in the same way at once.

In addition, the script adds other functionality related to animations.
> [!TIP]
> Use the script [documentation](https://github.com/Sh1zok/Figura-Scripts/wiki/%5BReanimated%5D-Home) to learn about all the features and start working with the script.

## Questions you may ask
* Do I have to port animations from Blockbench manually?
> No! The script automatically imports Blockbench animations upon initialization.
* What about performance? Does the FPS drop significantly?
> I haven't run tests with multiple avatars at the same time but based on my experience, the FPS drops are minor.
> 
> My setup and test results:\
> CPU: Intel Core i5-12400\
> GPU: Intel(R) UHD Graphics 730(Integrated)\
> RAM: 8x2GB DDR5 4800MHz\
> Figura 0.1.5+1.21.8\
> Just staying still in the world: 280 FPS avg.\
> While an animation is playing: 271 FPS avg.
* What about compatibility with other scripts?
> If the script is aimed at changing the metatables of model parts or animations, it's probably not compatible.\
> If it doesn't interact with the metatables of either, it's probably compatible.\
> But I don't know for sure. I haven't run any compatibility tests yet.

## TO-DO List
- [ ] Intro and Outro
- [ ] Smoooth and controllable blending between animations
- [ ] Opacity animation keyframes
- [ ] Color animation keyframes
