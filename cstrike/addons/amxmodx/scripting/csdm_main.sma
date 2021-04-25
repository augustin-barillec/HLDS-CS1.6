/**
 * csdm_main.sma
 * Allows for Counter-Strike to be played as DeathMatch.
 *
 * CSDM Main - Main plugin to communicate with module
 *
 * (C)2003-2005 David "BAILOPAN" Anderson
 *
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 */
 
#include <amxmodx>
#include <amxmisc>
#include <csdm>

new D_PLUGIN[]	= "CSDM Main"
new D_ACCESS	= ADMIN_MAP

new bool:g_StripWeapons = true
new bool:g_RemoveBomb = true
new g_StayTime = 0

//new g_MenuPages[33]
new g_MainMenu = -1

public plugin_natives()
{
	register_native("csdm_main_menu", "native_main_menu")
	register_library("csdm_main")
}

public native_main_menu(id, num)
{
	return g_MainMenu
}

public plugin_init()
{
	register_plugin(D_PLUGIN, CSDM_VERSION, "CSDM Team")
	
	register_clcmd("say respawn", "say_respawn")
	register_clcmd("say /respawn", "say_respawn")
	
	register_concmd("csdm_enable", "csdm_enable", D_ACCESS, "Enables CSDM")
	register_concmd("csdm_disable", "csdm_disable", D_ACCESS, "Disables CSDM")
	register_concmd("csdm_ctrl", "csdm_ctrl", D_ACCESS, "")
	register_concmd("csdm_reload", "csdm_reload", D_ACCESS, "Reloads CSDM Config")
	
	register_clcmd("csdm_menu", "csdm_menu", ADMIN_MENU, "CSDM Menu")
	register_clcmd("drop", "hook_drop")
	
	register_concmd("csdm_cache", "cacheInfo", ADMIN_MAP, "Shows cache information")
	
	csdm_reg_cfg("settings", "read_cfg")
	
	AddMenuItem("CSDM Menu", "csdm_menu", D_ACCESS, D_PLUGIN)
	g_MainMenu = menu_create("CSDM Menu", "use_csdm_menu")
	
	new callback = menu_makecallback("hook_item_display")
	menu_additem(g_MainMenu, "Enable/Disable", "csdm_ctrl", D_ACCESS, callback)
	menu_additem(g_MainMenu, "Reload Config", "csdm_reload", D_ACCESS)
}

public cacheInfo(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
		
	new ar[6]
	csdm_cache(ar)
	
	console_print(id, "[CSDM] Free tasks: respawn=%d, findweapon=%d", ar[0], ar[5])
	console_print(id, "[CSDM] Weapon removal cache: %d total, %d live", ar[4], ar[3])
	console_print(id, "[CSDM] Live tasks: %d (%d free)", ar[2], ar[1])
	
	return PLUGIN_HANDLED
}

public hook_drop(id)
{
	if (!csdm_active())
		return PLUGIN_CONTINUE
		
	if (g_StayTime > 20 || g_StayTime < 0)
		return PLUGIN_CONTINUE
	
	new wp, c, a, name[24]
	if (read_argc() <= 1)
	{
		wp = get_user_weapon(id, c, a)
	} else {
		read_argv(1, name, 23)
		wp = getWepId(name)
	}
	
	if (wp)
	{
		remove_weapon(id, wp)
	}
	
	return PLUGIN_CONTINUE
}

public csdm_PostDeath(killer, victim, headshot, const weapon[])
{
	if (g_StayTime > 20 || g_StayTime < 0)
		return PLUGIN_CONTINUE
	
	new weapons[MAX_WEAPONS], num
	new wp, slot
	
	get_user_weapons(victim, weapons, num)
	
	for (new i=0; i<num; i++)
	{
		wp = weapons[i]
		slot = g_WeaponSlots[wp]
		if (slot == SLOT_PRIMARY || slot == SLOT_SECONDARY || slot == SLOT_C4)
		{
			remove_weapon(victim, wp)
		}
	}
	
	return PLUGIN_CONTINUE
}

public csdm_PreSpawn(player, bool:fake)
{
	new team = get_user_team(player)
	if (g_StripWeapons)
	{
		if (team == _TEAM_T)
		{
			csdm_force_drop(player, "weapon_glock18")
		} else if (team == _TEAM_CT) {
			csdm_force_drop(player, "weapon_usp")
		}
	}
	if (team == _TEAM_T)
	{
		if (g_RemoveBomb)
		{
			new weapons[MAX_WEAPONS], num
			get_user_weapons(player, weapons, num)
			for (new i=0; i<num; i++)
			{
				if (weapons[i] == CSW_C4)
				{
					csdm_force_drop(player, "weapon_c4")
					break
				}
			}
		}
	}
}

remove_weapon(id, wp)
{
	new name[24]
	
	get_weaponname(wp, name, 23)

	if ((wp == CSW_C4) && g_RemoveBomb)
	{	
		csdm_remove_weapon(id, name, 0, 1)
	} else {
		if (wp != CSW_C4)
			csdm_remove_weapon(id, name, g_StayTime, 1)
	}
}

public hook_item_display(player, menu, item)
{
	new paccess, command[24], call
	
	menu_item_getinfo(menu, item, paccess, command, 23, _, 0, call)
	
	if (equali(command, "csdm_ctrl"))
	{
		if (!csdm_active())
		{
			menu_item_setname(menu, item, "Enable")
		} else {
			menu_item_setname(menu, item, "Disable")
		}
	}
}

public read_cfg(readAction, line[], section[])
{
	if (readAction == CFG_READ)
	{
		new setting[24], sign[3], value[32];

		parse(line, setting, 23, sign, 2, value, 31);
		
		if (equali(setting, "strip_weapons"))
		{
			g_StripWeapons = str_to_num(value) ? true : false
		} else if (equali(setting, "weapons_stay")) {
			g_StayTime = str_to_num(value)
		} else if (equali(setting, "spawnmode")) {
			new var = csdm_setstyle(value)
			if (var)
			{
				log_amx("CSDM spawn mode set to %s", value)
			} else {
				log_amx("CSDM spawn mode %s not found", value)
			}
		} else if (equali(setting, "remove_bomb")) {
			g_RemoveBomb = str_to_num(value) ? true : false
		} else if (equali(setting, "enabled")) {
			set_cvar_num(ACTIVE_CVAR, str_to_num(value))
		}
	}
}

public csdm_reload(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
		
	csdm_reload_cfg()
	
	client_print(id, print_chat, "[CSDM] Config file reloaded.")
		
	return PLUGIN_HANDLED
}

public csdm_menu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	menu_display(id, g_MainMenu, 0)
	
	return PLUGIN_HANDLED
}

public csdm_ctrl(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	set_cvar_num(ACTIVE_CVAR, get_cvar_num(ACTIVE_CVAR) ? 0 : 1)
	client_print(id, print_chat, "CSDM active changed.")
	
	return PLUGIN_HANDLED
}

public use_csdm_menu(id, menu, item)
{
	if (item < 0)
		return PLUGIN_CONTINUE
	
	new command[24], paccess, call
	if (!menu_item_getinfo(g_MainMenu, item, paccess, command, 23, _, 0, call))
	{
		log_amx("Error: csdm_menu_item() failed (menu %d) (page %d) (item %d)", g_MainMenu, 0, item)
		return PLUGIN_HANDLED
	}
	if (paccess && !(get_user_flags(id) & paccess))
	{
		client_print(id, print_chat, "You do not have access to this menu option.")
		return PLUGIN_HANDLED
	}
	
	client_cmd(id, command)
	
	return PLUGIN_HANDLED
}

public csdm_enable(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	set_cvar_num(ACTIVE_CVAR, 1)
	client_print(id, print_chat, "CSDM enabled.")
	
	return PLUGIN_HANDLED	
}

public csdm_disable(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	set_cvar_num(ACTIVE_CVAR, 0)
	client_print(id, print_chat, "CSDM disabled.")
	
	return PLUGIN_HANDLED	
}

public say_respawn(id)
{
	if (!is_user_alive(id) && csdm_active())
	{
		csdm_respawn(id)
	}
	
	return PLUGIN_CONTINUE
}
