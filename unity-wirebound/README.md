# Wirebound — Unity (URP)

Original toy-factory horror. Dual-hand **ClampRig 2.0** (blue left / red right). Not affiliated with MOB Games.

## Install

1. Install **Unity 6** (or 2022.3 LTS) + **Universal Render Pipeline**.
2. New project → URP 3D.
3. Copy `Assets/Wirebound` into your project's `Assets` folder.
4. Create an empty GameObject named `Bootstrap`, add `FactoryGenerator`.
5. Press Play.

For the cinematic menu: create a Canvas, add five Buttons (CONTINUE, NEW GAME, SETTINGS, CREDITS, QUIT), put `MainMenuController` on the Canvas, and assign the buttons.

## High graphics (URP)

`GraphicsBootstrap` on the camera turns on:

- HDR + MSAA
- Bloom, vignette, film grain, chromatic aberration
- Exponential fog (deep red)
- Very High shadows (Ultra)

In the URP Asset also enable:

- HDR
- Native RenderPass
- Shadow cascade count 4
- Soft Shadows
- SSAO renderer feature (optional)

HDRP is even closer to the screenshot (volumetric fog). If you switch to HDRP, keep the ClampRig scripts and replace `GraphicsBootstrap` with an HDRP Volume (Fog + Bloom + Tonemapping ACES).

## ClampRig 2.0 controls

| Input | Action |
| --- | --- |
| LMB | Fire / hold left (blue) hand |
| RMB | Fire / hold right (red) hand |
| Release | Retract that hand |
| Both sockets | Opens the dual-hand gate |
| WASD / Shift | Move / sprint |
| Esc | Unlock mouse |

Stick a hand to a surface and hold to pull yourself. Grab crates by hitting them. Charge **both** gate sockets at once to open the door.

## Original art

Use your own meshes for Hushhorn and the factory. Do not import Poppy Playtime / CatNap assets — those are owned by MOB Games.
