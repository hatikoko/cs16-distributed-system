#include <amxmodx>
#include <fun>

#define PLUGIN "Zombie Plague Core"
#define VERSION "0.1"
#define AUTHOR "Alisher Akhmetov"

new bool:g_is_zombie[33];

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    // HLTV event fires at the start of every freeze time
    register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
    
    // Commands
    register_clcmd("say /zp", "cmd_zp_status");
    register_clcmd("say /force", "cmd_force_infect");
    
    server_print("[ZP] Core loaded with automatic retry system!");
}

public client_authorized(id) {
    g_is_zombie[id] = false;
}

public event_round_start() {
    // Reset states for all players
    for (new i = 1; i <= 32; i++) {
        g_is_zombie[i] = false;
    }
    
    // Remove any leftover tasks to avoid duplicate timers
    remove_task(100);
    
    client_print(0, print_chat, "[ZP] Infection spreading in 10 seconds...");
    
    // Schedule task with ID 100
    set_task(10.0, "task_make_first_zombie", 100);
}

public task_make_first_zombie() {
    new players[32], num;
    get_players(players, num, "a");

    if (num < 1) return;
    // FIX: If no players are spawned yet, retry in 3 seconds instead of aborting!
    if (num < 1) {
        client_print(0, print_chat, "[ZP] Waiting for players to spawn...");
        set_task(3.0, "task_make_first_zombie", 100);
        return;
    }
    
    // Pick random alive player
    new target = players[random_num(0, num - 1)];
    make_zombie(target);
}

public make_zombie(id) {
    g_is_zombie[id] = true;
    set_user_health(id, 2000);
    
    new name[32];
    get_user_name(id, name, charsmax(name));
    client_print(0, print_chat, "[ZP] %s is the First Zombie!", name);
}

public cmd_force_infect(id) {
    if (!is_user_alive(id)) return PLUGIN_HANDLED;
    make_zombie(id);
    return PLUGIN_HANDLED;
}

public cmd_zp_status(id) {
    if (g_is_zombie[id]) {
        client_print(id, print_chat, "[ZP] Status: ZOMBIE (%d HP)", get_user_health(id));
    } else {
        client_print(id, print_chat, "[ZP] Status: HUMAN");
    }
    return PLUGIN_HANDLED;
}