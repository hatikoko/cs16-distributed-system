#include<cstrike>
#include <amxmodx>
#include <fun>
#include <hamsandwich>

#define PLUGIN "Zombie Plague Core"
#define VERSION "0.1"
#define AUTHOR "Alisher Akhmetov"

new bool:g_is_zombie[33];
new bool:g_round_ended;

//function that runs once plugin is read
public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);

    // HLTV event fires at the start of every freeze time
    register_event("HLTV", "event_round_start", "a", "1=0", "2=0");

    // Register a hook that intercepts damage on any player entity
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");

    // Commands
    register_clcmd("say /zp", "cmd_zp_status");
    register_clcmd("say /force", "cmd_force_infect");
    
    server_print("[ZP] Core loaded with automatic retry system!");
}
//makes everyone human when connects
public client_authorized(id) {
    g_is_zombie[id] = false;
}

//checks whether the round ends, once user disconnected
public client_disconnected(id) {
    g_is_zombie[id] = false;
    // Check if the disconnected player was the last human/zombie
    check_round_end();
}

//function when the round starts
public event_round_start() {
    g_round_ended = false;

    // Reset states for all players and put everyone on Human (CT) team
    for (new i = 1; i <= 32; i++) {
        g_is_zombie[i] = false;
        if(is_user_connected(i)) {
            cs_set_user_team(i, CS_TEAM_CT);
        }
    }
    
    // Remove any leftover tasks to avoid duplicate timers
    remove_task(100);
    
    client_print(0, print_chat, "[ZP] Infection spreading in 10 seconds...");
    
    // Schedule task with ID 100
    set_task(10.0, "task_make_first_zombie", 100);
}

//makes random zombie at the beginning of round
public task_make_first_zombie() {
    if(g_round_ended) return;

    new players[32], num;
    get_players(players, num, "a");

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

//makes zombie player with id
public make_zombie(id) {
    g_is_zombie[id] = true;
    
    //Switch TAB scoreboard team to Terrorist (Zombie)
    cs_set_user_team(id, CS_TEAM_T); 

    //give health
    set_user_health(id, 2000);
    
    //Strip all weapons and give knife
    strip_user_weapons(id);
    give_item(id, "weapon_knife");
    engclient_cmd(id, "weapon_knife");


    new name[32];
    get_user_name(id, name, charsmax(name));
    client_print(0, print_chat, "[ZP] %s is the First Zombie!", name);

    //Check if this infection ends the round
    check_round_end();
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
    // 1. Ensure both attacker and victim are valid connected players
    if (!is_user_connected(attacker) || !is_user_connected(victim))
        return HAM_IGNORED;
        
    // 2. Check if the attacker is a Zombie and the victim is a Human
    if (g_is_zombie[attacker] && !g_is_zombie[victim]) {
        // Infect the human
        make_zombie(victim);
        
        // Block standard CS weapon damage so the victim doesn't die
        return HAM_SUPERCEDE;
    }
    
    // Allow normal damage for all other cases (e.g., humans shooting zombies)
    return HAM_IGNORED;
}

public check_round_end() {
    if (g_round_ended) return;
    
    new players[32], num;
    get_players(players, num, "a"); // Get alive players
    
    new humans = 0;
    new zombies = 0;
    
    for (new i = 0; i < num; i++) {
        new id = players[i];
        if (g_is_zombie[id])
            zombies++;
        else
            humans++;
    }
    
    // Only check win conditions if the initial zombie has spawned
    if (zombies == 0 && humans == 0) return;
    
    // Win Condition 1: All Humans infected
    if (humans == 0 && zombies > 0) {
        g_round_ended = true;
        client_print(0, print_chat, "[ZP] --- ZOMBIES WIN! All humans were infected! ---");
        set_task(2.0, "task_restart_round");
    }
    // Win Condition 2: All Zombies killed
    else if (zombies == 0 && humans > 0 && task_exists(100) == 0) {
        // Only trigger if timer already expired (first zombie was selected)
        g_round_ended = true;
        client_print(0, print_chat, "[ZP] --- HUMANS WIN! All zombies were eliminated! ---");
        set_task(2.0, "task_restart_round");
    }
}

public task_restart_round() {
    server_cmd("sv_restartround 1");
}

//function for forcing the infections on id player
public cmd_force_infect(id) {
    if (!is_user_alive(id)) return PLUGIN_HANDLED;
    make_zombie(id);
    return PLUGIN_HANDLED;
}

//function to check whether player is zombie/human
public cmd_zp_status(id) {
    if (g_is_zombie[id]) {
        client_print(id, print_chat, "[ZP] Status: ZOMBIE (%d HP)", get_user_health(id));
    } else {
        client_print(id, print_chat, "[ZP] Status: HUMAN");
    }
    return PLUGIN_HANDLED;
}