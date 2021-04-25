/**
 * csdm_misc.sma
 * Allows for Counter-Strike to be played as DeathMatch.
 *
 * CSDM Miscellanious Settings
 *
 * By Freecode and BAILOPAN
 * (C)2003-2005 David "BAILOPAN" Anderson
 *
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 */
 
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <csdm>

new bool:g_BlockBuy = true
new bool:g_AmmoRefill = true
new bool:g_RadioMsg = false

#define MAXMENUPOS 34

new g_Aliases[MAXMENUPOS][] = {"usp","glock","deagle","p228","elites","fn57","m3","xm1014","mp5","tmp","p90","mac10","ump45","ak47","galil","famas","sg552","m4a1","aug","scout","awp","g3sg1","sg550","m249","vest","vesthelm","flash","hegren","sgren","defuser","nvgs","shield","primammo","secammo"} 
new g_Aliases2[MAXMENUPOS][] = {"km45","9x19mm","nighthawk","228compact","elites","fiveseven","12gauge","autoshotgun","smg","mp","c90","mac10","ump45","cv47","defender","clarion","krieg552","m4a1","bullpup","scout","magnum","d3au1","krieg550","m249","vest","vesthelm","flash","hegren","sgren","defuser","nvgs","shield","primammo","secammo"}

//Tampering with the author and name lines can violate the copyright
new PLUGINNAME[] = "CSDM Misc"
new VERSION[] = "2.00"
new AUTHORS[] = "CSDM Team"

public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHORS);
	register_event("CurWeapon", "hook_CurWeapon", "be", "1=1")
	
	register_clcmd("buy", "generic_block")
	register_clcmd("buyammo1", "generic_block")
	register_clcmd("buyammo2", "generic_block")
	register_clcmd("buyequip", "generic_block")
	register_clcmd("cl_autobuy", "generic_block")
	register_clcmd("cl_rebuy", "generic_block")
	register_clcmd("cl_setautobuy", "generic_block")
	register_clcmd("cl_setrebuy", "generic_block")
	
	register_concmd("csdm_pvlist", "pvlist")
	
	csdm_reg_cfg("misc", "read_cfg")
}

public pvlist(id, level, cid)
{
	new players[32], num, pv, name[32]
	get_players(players, num)
	
	for (new i=0; i<num; i++)
	{
		pv = players[i]
		get_user_name(pv, name, 31)
		console_print(id, "[CSDM] Player %s flags: %d deadflags: %d", name, entity_get_int(pv, EV_INT_flags), entity_get_int(pv, EV_INT_deadflag))
	}
	
	return PLUGIN_HANDLED
}

public generic_block(id, level, cid)
{
	if (csdm_active())
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	precache_sound("radio/locknload.wav")
	precache_sound("radio/letsgo.wav")
} 

public csdm_PostSpawn(player, bool:fake)
{
	if (g_RadioMsg && !is_user_bot(player))
	{
		if (get_user_team(player) == _TEAM_T)
		{
			client_cmd(player, "spk radio/letsgo")
		} else {
			client_cmd(player, "spk radio/locknload")
		}
	}
}

public client_command(id)
{
	if (csdm_active() && g_BlockBuy)
	{
		new arg[13]
		if (read_argv(0, arg, 12) > 11)
			return PLUGIN_CONTINUE 
		new a = 0 
		do {
			if (equali(g_Aliases[a], arg) || equali(g_Aliases2[a], arg)) { 
				return PLUGIN_HANDLED 
			}
		} while(++a < MAXMENUPOS)
	}
	
	return PLUGIN_CONTINUE 
} 

public hook_CurWeapon(id)
{
	if (!g_AmmoRefill || !csdm_active())
		return
	
	new wp = read_data(2)
	
	if (g_WeaponSlots[wp] == SLOT_PRIMARY || g_WeaponSlots[wp] == SLOT_SECONDARY)
	{
		new ammo = read_data(3)
		
		if (ammo < 1)
			cs_set_user_bpammo(id, wp, g_MaxBPAmmo[wp])
	}
}

public read_cfg(readAction, line[], section[])
{
	if (!csdm_active())
		return
		
	if (readAction == CFG_READ)
	{
		new setting[24], sign[3], value[32];

		parse(line, setting, 23, sign, 2, value, 31);
		
		if (equali(setting, "remove_objectives"))
		{
			new mapname[24]
			get_mapname(mapname, 23)
			
			if (containi(mapname, "de_") != -1 && containi(value, "d") != -1)
			{
				RemoveEntityAll("func_bomb_target")
				RemoveEntityAll("info_bomb_target")
			}
			if (containi(mapname, "as_") != -1 && containi(value, "a") != -1)
			{
				RemoveEntityAll("func_vip_safetyzone")
				RemoveEntityAll("info_vip_start")
			}
			if (containi(mapname, "cs_") != -1 && containi(value, "c") != -1)
			{
				RemoveEntityAll("func_hostage_rescue")
				RemoveEntityAll("info_hostage_rescue")
			}
			if (containi(value, "b") != -1)
			{
				RemoveEntityAll("func_buyzone")
			}
		} else if (equali(setting, "block_buy")) {
			g_BlockBuy = str_to_num(value) ? true : false
		} else if (equali(setting, "ammo_refill")) {
			g_AmmoRefill = str_to_num(value) ? true : false
		} else if (equali(setting, "spawn_radio_msg")) {
			g_RadioMsg = str_to_num(value) ? true : false
		}
	}
}

stock RemoveEntityAll(name[])
{
	new ent = find_ent_by_class(0, name)
	new temp
	while (ent)
	{
		temp = find_ent_by_class(ent, name)
		remove_entity(ent)
		ent = temp
	}
}
