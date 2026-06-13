# ps2tech

Shared PlayStation 2 platform primitives for retro id-tech-style ports —
**ps2oom** (DOOM), **ps2quake** (Quake), **ps2uke** (Duke3D). All three are
8-bit-palettized, software-rendered games with identical PS2 needs, and each
currently reimplements the same platform layer from scratch. ps2tech distills
that layer into one place so a fourth port (or a fix to an old one) is cheap.

## Status: initial extraction (read-only copy)

This is a **straight copy** from the existing ports, not yet refactored into
clean game-agnostic primitives. Nothing here is wired into a build yet, and the
source ports are untouched. The next pass distills `reference/` down into the
`src/` primitives and gives them a small public API.

```
ps2tech/
├── src/            clean-ish primitives copied from ps2oom (the starting point)
│   ├── ps2_audio_driver.c   audsrv bring-up: lmb patch -> libsd/audsrv IRX -> audsrv_init
│   ├── ps2_bootscr.c        libdebug GS text console for the boot log
│   ├── ps2_drivers_stub.c   THE boot fix: override waitUntilDeviceIsReady (~28s
│   │                          stall) + stub unused USB/dev9 drivers
│   ├── ps2_cdfs.c           cdfs (ISO9660) bring-up for on-demand disc reads
│   ├── ps2_menu.c/.h         controller-driven setup menu (list + settings page)
│   └── ps2_pad.c            libpad: forced analog, sticks + buttons (DOOM-mapped;
│                              the mapping needs degenericising)
└── reference/      game-coupled sources to distill the primitives FROM
    ├── doom/   i_audsrvsound.c (audsrv mixer loop), doomgeneric_ps2_gs.c
    │           (gsKit 8bpp blit), opl_ps2.c (DBOPL render), w_file_cdfs.c
    └── quake/  snd_ps2.c, vid_ps2.c (gsKit), in_ps2.c (USB kb+m!), cd_ps2.c
```

Having **two** reference implementations per primitive (doom/ + quake/) is the
point: the common core is whatever they agree on.

## The primitives to extract

| Primitive | What it does | Distill from |
|---|---|---|
| **audio** | audsrv bring-up + a mixer thread that does `audsrv_wait_audio` → `audsrv_play_audio` (the blocking call self-paces). `ps2tech_audio_open(fmt)` / `ps2tech_audio_submit(pcm, n)`. | `src/ps2_audio_driver.c`, `reference/{doom/i_audsrvsound,quake/snd_ps2,quake/cd_ps2}.c` |
| **video** | 8-bit palettized framebuffer → PSMT8 texture + CLUT, GS upscale. `ps2tech_blit8(fb, pal)`. | `reference/{doom/doomgeneric_ps2_gs,quake/vid_ps2}.c` |
| **input** | libpad (forced analog) + USB keyboard/mouse. `ps2tech_pad_read()`, `ps2tech_kbd_*`. | `src/ps2_pad.c`, `reference/quake/in_ps2.c` |
| **boot** | driver bring-up + the `waitUntilDeviceIsReady` fix + libdebug console. | `src/ps2_drivers_stub.c`, `src/ps2_bootscr.c` |
| **storage** | cdfs / on-demand file reads (WAD / PAK / GRP). | `src/ps2_cdfs.c`, `reference/doom/w_file_cdfs.c` |
| **menu** | controller setup menu (already fairly game-agnostic). | `src/ps2_menu.c/.h` |

The **audio** primitive is the highest priority — it's what ps2uke is stuck on,
and there are already two proven copies to distill from.

## What stays per-game

Only the platform open/submit/blit/read is shareable. The actual *mixing* and
*decoding* stay in each game (DOOM mixes SFX + DBOPL FM; Quake decodes
IMA-ADPCM; Duke does VOC + its own music), as does the input *mapping*.

## Provenance

Copied from `Arawn-Davies/ps2oom` (ps2/) and the local ps2quake tree.
Built on [ps2sdk](https://github.com/ps2dev/ps2sdk) + gsKit (ps2dev), GPLv2.
