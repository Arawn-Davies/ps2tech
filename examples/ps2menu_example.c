// Standalone demo of the ps2tech *menu* primitive (src/ps2_menu.c): a
// controller-driven list picker followed by a settings page, drawn on the
// libdebug text console. This is the successor to the ps2dev "hello world"
// sample — it doubles as the build-harness smoke test: if this links and boots,
// the toolchain + the menu primitive both work.
//
// ps2_menu.c calls PS2Pad_Init() for its (shared) controller bring-up. In a real
// game that lives in src/ps2_pad.c, but that file is still Doom-coupled (it pulls
// in doomkeys.h / d_event.h) and doesn't build standalone yet, so we provide a
// minimal local copy of just that one function here. With no controller the menu
// bounds its wait and auto-selects, so the demo can never hang.

#include <kernel.h>     // SleepThread
#include <sifrpc.h>     // SifInitRpc (needed before SifLoadModule)
#include <loadfile.h>   // SifLoadModule
#include <debug.h>      // init_scr, scr_printf
#include <libpad.h>     // padInit, padPortOpen

#include "ps2_menu.h"

// --- minimal shared pad bring-up (stands in for src/ps2_pad.c's PS2Pad_Init) --
// Same sequence as the real one: SIO2/pad managers from the BIOS (rom0:), then
// padInit + open port 0. Opened exactly once; the menu relies on that.
static char s_padBuf[256] __attribute__((aligned(64)));
static int  s_padInited = 0;

void PS2Pad_Init(void)
{
    if (s_padInited)
        return;
    SifLoadModule("rom0:SIO2MAN", 0, NULL);
    SifLoadModule("rom0:PADMAN", 0, NULL);
    padInit(0);
    padPortOpen(0, 0, s_padBuf);
    s_padInited = 1;
}

int main(int argc, char *argv[])
{
    (void)argc; (void)argv;

    SifInitRpc(0);   // bring up the IOP RPC link before loading rom0: modules
    init_scr();      // libdebug GS text console

    scr_printf("\n\n  ps2tech -- ps2menu example\n");
    scr_printf("  (hello-world smoke test: toolchain + menu primitive)\n");

    // 1) list picker -> returns the chosen index
    char *games[] = { "DOOM", "Quake", "Duke3D" };
    int   pick    = PS2_SelectMenu("Pick a game:", games, 3);

    // 2) settings page -> each setting's .cur is left at the chosen value
    char *music[] = { "OPL", "WAV", "None" };
    char *onoff[] = { "Off", "On" };
    ps2_setting_t settings[] = {
        { "Music",  music, 3, 0 },   // label, values, count, default index
        { "Filter", onoff, 2, 1 },
    };
    PS2_SettingsMenu("Settings:", settings, 2);

    // Report what the menu returned.
    scr_printf("\n  You picked : %s\n", games[pick]);
    scr_printf("  Music      : %s\n", music[settings[0].cur]);
    scr_printf("  Filter     : %s\n", onoff[settings[1].cur]);
    scr_printf("\n  build harness OK -- menu + pad linked and ran.\n");

    SleepThread();   // park so the program doesn't fall off the end
    return 0;
}
