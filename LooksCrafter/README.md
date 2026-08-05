# LooksCrafter
Another wardrobe script for Figura avatars.
***
## Scripts purpose
Ever since I started making Figura avatars, I've wanted to create a modular wardrobe. Changing outfits is great, but what if my mood changes every day and I don't want to make a hundred outfits for every day? What if I want to "craft" outfits from clothing parts?

At first, I made additional layers on the model, but as it turns out, if the model faces are too close to each other and the person viewing them is far away, the model parts start to overlap, resulting in z-fighting.

It turns out that layering clothes requires some shenanigans on textures... which is what this script does.
***
## Features
In addition to basic texture layering, this script provides the following features:
* **Chroma-key colors** - You can specify a color that will remove pixels left by previous clothing layers. This is quite useful when your clothing elements may overlap in the same texture area.
* **Model parts control** - You can specify which model parts will be specifically shown or hidden. This allows you to complement your outfits with 3D elements and accessories.
* **`:onEquip()` & `:onUnequip()`** - If equipping or unequipping any piece of clothing needs a function to be executed, this can be specified.
* **Session-through config** - Automatic saving and loading of selected clothing items between game sessions.
* **Pings** - The pings are already embedded.
***
## Documentation
Use the script [documentation](https://github.com/Sh1zok/Figura-Scripts/wiki/%5BLooksCrafter%5D-Home) to start working with the script.
