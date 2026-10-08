#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>

#define PLUGIN "Zombie Plague Core"
#define VERSION "0.1"
#define AUTHOR "Alisher Akhmetov"

// Track player states (index 32 max players)
new bool:g_is_zombie[33];

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    // Register a simple test command to verify it works in-game
    register_clcmd("say /zp", "cmd_zp_status");
    
    server_print("[ZP] Core plugin initialized successfully!");
}

// Reset player states on client connect
public client_authorized(id) {
    g_is_zombie[id] = false;
}

// Simple test command handler
public cmd_zp_status(id) {
    client_print(id, print_chat, "[ZP] Zombie Plague core is active and running!");
    return PLUGIN_HANDLED;
}