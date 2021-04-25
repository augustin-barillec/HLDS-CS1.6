/**
 * csdm_equip.sma
 * Allows for Counter-Strike to be played as DeathMatch.
 *
 * CSDM Equipment Menu
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
#include <csdm>

//Tampering with the author and name lines can violate the copyright
new PLUGINNAME[] = "CSDM Equip"
new VERSION[] = "2.00"
new AUTHORS[] = "CSDM Team"

#define	EQUIP_PRI	(1<<0)
#define	EQUIP_SEC	(1<<1)
#define	EQUIP_ARMOR	(1<<2)
#define	EQUIP_GREN	(1<<3)
#define	EQUIP_ALL	(EQUIP_PRI|EQUIP_SEC|EQUIP_ARMOR|EQUIP_GREN)

//Menus
new g_SecMenu[] = "CSDM: Secondary Weapons";	// Menu Name
new g_SecMenuID = -1;							// Menu ID
new g_cSecondary;								// Menu Callback
new bool:g_mSecStatus = true;					// Menu Available?

new g_PrimMenu[] = "CSDM: Primary Weapons";
new g_PrimMenuID = -1;
new g_cPrimary;
new bool:g_mPrimStatus = true;

new g_ArmorMenu[] = "CSDM: Armor";
new g_ArmorMenuID = -1;
new bool:g_mArmorStatus = true;

new g_NadeMenu[] = "CSDM: Grenades";
new g_NadeMenuID = -1;
new bool:g_mNadeStatus = true;

new g_EquipMenu[] = "CSDM: Equip";
new g_EquipMenuID = -1;

new bool:g_mShowuser[33] = true;

new bool:g_mAutoNades = false;
new bool:g_mAutoArmor = false;

//Weapon Selections
new g_SecWeapons[33][18];
new g_PrimWeapons[33][18];
new bool:g_mNades[33];
new bool:g_mArmor[33];

//Config weapon storage holders
new g_BotPrim[MAX_WEAPONS][18];
new g_iNumBotPrim;

new g_BotSec[MAX_WEAPONS][18];
new g_iNumBotSec;

new g_Secondary[MAX_SECONDARY][18];
new bool:g_DisabledSec[MAX_WEAPONS];
new g_iNumSec;

new g_Primary[MAX_PRIMARY][18];
new bool:g_DisabledPrim[MAX_WEAPONS];
new g_iNumPrim;

//Misc
new g_Armor = 0;
new bool:g_Flash = false;
new bool:g_Nade = false;
new bool:g_Smoke = false;

//Quick Fix for menu pages
new g_MenuPages[33] = {0};

new g_MenuState[33] = {0};

public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHORS);
	
// Menus and callbacks
	g_SecMenuID = menu_create(g_SecMenu, "m_SecHandler",0);
	g_PrimMenuID = menu_create(g_PrimMenu, "m_PrimHandler",0);
	g_ArmorMenuID = menu_create(g_ArmorMenu, "m_ArmorHandler",0);
	g_NadeMenuID = menu_create(g_NadeMenu, "m_NadeHandler",0);
	g_EquipMenuID = menu_create(g_EquipMenu, "m_EquipHandler",0);
	
	g_cSecondary = menu_makecallback("c_Secondary");
	g_cPrimary = menu_makecallback("c_Primary");
	
// Config reader
	
	// Settings
	csdm_reg_cfg("equip", "cfgSetting");
	
	// In order for weapon menu
	csdm_reg_cfg("secondary", "cfgSecondary");
	csdm_reg_cfg("primary", "cfgPrimary");
	csdm_reg_cfg("botprimary", "cfgBotPrim");
	csdm_reg_cfg("botsecondary", "cfgBotSec");
	
// Build Armor/Nade/Equip Menu's
	buildMenu();
	
	register_clcmd("say guns", "enableMenu")
	register_clcmd("say /guns", "enableMenu")
	register_clcmd("say menu", "enableMenu")
	register_clcmd("say enablemenu", "enableMenu")
	register_clcmd("say enable_menu", "enableMenu")
}

public client_connect(id)
{
	g_mShowuser[id] = true;
	g_mNades[id] = false;
	g_mArmor[id] = false;
	
	return PLUGIN_CONTINUE
}

public client_disconnect(id)
{
	g_mShowuser[id] = true;
	g_mNades[id] = false;
	g_mArmor[id] = false;
	
	return PLUGIN_CONTINUE
}

public cfgSecondary(readAction, line[], section[])
{
	if (readAction == CFG_READ)
	{
		if (g_iNumSec >= MAX_SECONDARY)
			return PLUGIN_HANDLED
		
		new wep[16], display[48], dis[4];
		new cmd[6];

		parse(line, wep, 15, display, 47, dis, 3);
		
		new disabled = str_to_num(dis)
		
		//Copy weapon into array
		format(g_Secondary[g_iNumSec], 17, "weapon_%s", wep);

		g_DisabledSec[g_iNumSec] = disabled ? false : true;
		
		format(cmd,5,"%d ",g_iNumSec);
		g_iNumSec++;
		
		//TODO: Add menu_destroy_items to remake menu on cfg reload
		menu_additem(g_SecMenuID, display, cmd, 0, g_cSecondary);
	}
	else if (readAction == CFG_RELOAD)
	{
		g_SecMenuID = menu_create(g_SecMenu, "m_SecHandler", 0);
		g_iNumSec = 0;
	}
	else if (readAction == CFG_DONE)
	{
		//Nothing for now
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_HANDLED
}

public cfgPrimary(readAction, line[], section[])
{
	if (readAction == CFG_READ)
	{
		if (g_iNumPrim >= MAX_PRIMARY)	
			return PLUGIN_HANDLED
			
		new wep[16], display[48], dis[4];
		new cmd[6];

		parse(line, wep, 15, display, 47, dis, 3);
		
		new disabled = str_to_num(dis);
		
		//Copy weapon into array
		format(g_Primary[g_iNumPrim], 17, "weapon_%s", wep);
		g_DisabledPrim[g_iNumPrim] = disabled ? false : true;
		
		format(cmd, 5, "%d", g_iNumPrim);
		g_iNumPrim++;
		
		//TODO: Add menu_destroy_items to remake menu on cfg reload
		menu_additem(g_PrimMenuID, display, cmd, 0, g_cPrimary);
	}
	else if (readAction == CFG_RELOAD)
	{
		g_PrimMenuID = menu_create(g_PrimMenu, "m_PrimHandler", 0);
		g_iNumPrim = 0;
	}
	else if (readAction == CFG_DONE)
	{
		//Nothing for now
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}
	
	
public cfgBotPrim(readAction, line[], section[])
{
	if (readAction == CFG_READ)
	{
	
		new wep[16], display[32];

		parse(line, wep, 15, display, 31 );
		
		//Copy weapon into array
		format(g_BotPrim[g_iNumBotPrim], 17, "weapon_%s", wep);
		g_iNumBotPrim++;
	}
	else if (readAction == CFG_RELOAD)
	{
		g_iNumBotPrim = 0;
	}
	else if (readAction == CFG_DONE)
	{
		//Nothing for now
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public cfgBotSec(readAction, line[], section[])
{
	if (readAction == CFG_READ)
	{
	
		new wep[16], display[32];

		parse(line, wep, 15, display, 31 );
		
		//Copy weapon into array
		format(g_BotSec[g_iNumBotSec], 17, "weapon_%s", wep);
		g_iNumBotSec++;
	}
	else if (readAction == CFG_RELOAD)
	{
		g_iNumBotSec = 0;
	}
	else if (readAction == CFG_DONE)
	{
		//Nothing for now
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public cfgSetting(readAction, line[], section[])
{
	if (readAction == CFG_READ)
	{

		new setting[16], sign[3], value[6];

		parse(line, setting, 15, sign, 2, value, 5);
		
		// Menus settings
		if (contain(setting,"menus") != -1)
		{
			if (containi(value, "p") != -1)
			{
				g_mPrimStatus = true;
			}
			
			if (containi(value, "s") != -1)
			{
				g_mSecStatus = true;
			}
			
			if (containi(value, "a") != -1)
			{
				g_mArmorStatus = true;
			}
			
			if (containi(value, "g") != -1)
			{
				g_mNadeStatus = true;
			}
			
			return PLUGIN_HANDLED
		}
		else if (contain(setting,"autoitems") != -1)
		{

			if (containi(value,"a")  != -1)
			{
				//Disable Armor Menu
				g_mArmorStatus = false;
				g_mAutoArmor = true;
				
				g_Armor = 1;
			}
						
			if (containi(value,"h") != -1)
			{
				//Disable Armor Menu
				g_mArmorStatus = false;
				g_mAutoArmor = true;
				g_Armor = 2;
			}
			
			if (containi(value,"g") != -1)
			{
				//Disable Grenade Menu
				g_mNadeStatus = false;
				g_mAutoNades = true;
			}
			
			return PLUGIN_HANDLED
		}
		else if (contain(setting,"grenades")  != -1 )
		{
			if (containi(value,"f") != -1)
			{
				g_Flash = true;
			}
			
			if (containi(value,"h") != -1)
			{
				g_Nade = true;
			}
			
			if (containi(value,"s") != -1)
			{
				g_Smoke = true;
			}
		}
		
		return PLUGIN_HANDLED
	}
	else if (readAction == CFG_RELOAD)
	{
		g_mArmorStatus = false;
		g_mArmorStatus = false;
		g_mNadeStatus = false;
		g_Flash = false;
		g_Nade = false;
		g_Smoke = false;
		g_Armor = 0;
		g_mSecStatus = false;
		g_mPrimStatus = false;
		g_mAutoNades = false;
	}
	else if (readAction == CFG_DONE)
	{
		//Nothing for now
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

//Secondary Weapon Callback
public c_Secondary(id, menu, item)
{

	if( item < 0 ) return PLUGIN_CONTINUE;
	
	new cmd[6], iName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback);
	
	new dis = str_to_num(cmd);
	
	//Check to see if item is disabled
	if (g_DisabledSec[dis])
	{
		return ITEM_DISABLED;
	}
	else
	{
		return ITEM_ENABLED;
	}
	
	return PLUGIN_HANDLED;
}

//Primary Weapon Callback
public c_Primary(id, menu, item)
{

	if (item < 0)
		return PLUGIN_CONTINUE;
	
	// Get item info
	new cmd[6], iName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback);
	
	new dis = str_to_num(cmd);
	
	//Check to see if item is disabled
	if (g_DisabledPrim[dis])
	{
		return ITEM_DISABLED;
	}
	else
	{
		return ITEM_ENABLED;
	}
	
	return PLUGIN_HANDLED;
}

//Equipment Menu handler
public m_EquipHandler(id, menu, item)
{
	if (item < 0) 
		return PLUGIN_CONTINUE;
	
	// Get item info
	new cmd[2], iName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, cmd,1, iName, 63, callback);
	
	new choice = str_to_num(cmd);
	
	switch(choice)
	{
		case 1:
		{
			if (g_mSecStatus)
			{
				menu_display(id, g_SecMenuID, 0);
			}
			else if (g_mPrimStatus)
			{
				g_MenuPages[id] = 0
				menu_display(id, g_PrimMenuID, 0);
			}
			else if (g_mArmorStatus)
			{
				menu_display(id, g_ArmorMenuID, 0);
			}
			else if (g_mNadeStatus)
			{
				if (g_mAutoArmor)
					equipUser(id, EQUIP_ARMOR)
				menu_display(id, g_NadeMenuID, 0)
			} else {
				if (g_mAutoArmor)
					equipUser(id, EQUIP_ARMOR)
				if (g_mAutoNades)
					equipUser(id, EQUIP_GREN)
			}
		}
		case 2:
		{
			// Equip person with last settings
			equipUser(id, EQUIP_ALL)
		}
		case 3:
		{
			g_mShowuser[id] = false;
			client_print(id, print_chat, "[CSDM] Type ^"guns^" in chat to re-enable your equip menu.")
			equipUser(id, EQUIP_ALL)
		}
	}
	
	return PLUGIN_HANDLED;
}

//Secondary Wep Menu handler
public m_SecHandler(id, menu, item)
{
	// Get item info
	new cmd[6], iName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback);
	
	new wep = str_to_num(cmd);
	
	copy(g_SecWeapons[id],17,g_Secondary[wep]);
	equipUser(id, EQUIP_SEC)
	
	// Show next menu here
	
	if (g_mPrimStatus)
	{
		g_MenuPages[id] = 0
		menu_display(id, g_PrimMenuID, 0);
	}
	else if (g_mArmorStatus)
	{
		menu_display(id, g_ArmorMenuID, 0);
	}
	else if (g_mNadeStatus)
	{
		if (g_mAutoArmor)
			equipUser(id, EQUIP_ARMOR)
		menu_display(id, g_NadeMenuID, 0)
	}
	else
	{
		if (g_mAutoArmor)
			equipUser(id, EQUIP_ARMOR)
		if (g_mAutoNades)
			equipUser(id, EQUIP_GREN)
	}
	
	return PLUGIN_HANDLED
}

//Primary Wep Menu handler
public m_PrimHandler(id, menu, item)
{
	if (item == MENU_BACK)
	{
		g_MenuPages[id]--;
		menu_display(id, menu, g_MenuPages[id]);
		return PLUGIN_HANDLED;
	} else if (item == MENU_MORE) {
		g_MenuPages[id]++;
		menu_display(id, menu, g_MenuPages[id]);
		return PLUGIN_HANDLED;
	} else if (item == MENU_EXIT) {
		g_MenuPages[id] = 0;
		return PLUGIN_HANDLED;
	}
	
	// Get item info
	new cmd[6], iName[64];
	new access, callback;
	
	if (menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback))
	{
		new wep = str_to_num(cmd);
	
		copy(g_PrimWeapons[id], 17, g_Primary[wep]);
		equipUser(id, EQUIP_PRI)
	}
		
	// Show next menu here
		
	if (g_mArmorStatus)
	{
		menu_display(id, g_ArmorMenuID, 0);
	}
	else if (g_mNadeStatus)
	{
		if (g_mAutoArmor)
			equipUser(id, EQUIP_ARMOR)
		menu_display(id, g_NadeMenuID, 0);
	} else {
		if (g_mAutoArmor)
			equipUser(id, EQUIP_ARMOR)
		if (g_mAutoNades)
			equipUser(id, EQUIP_GREN)
	}
	
	return PLUGIN_HANDLED
}

//Armor Menu handler
public m_ArmorHandler(id, menu, item)
{
	if (item < 0) return PLUGIN_CONTINUE;
	
	// Get item info
	new cmd[6], iName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, cmd,5, iName, 63, callback);
	
	new choice = str_to_num(cmd);
	
	if (choice == 1)
	{
		g_mArmor[id] = true;
	}
	else if (choice == 2)
	{
		g_mArmor[id] = false;
	}
	equipUser(id, EQUIP_ARMOR)
	
	// Show next menu here
	
	if (g_mNadeStatus)
	{
		menu_display(id, g_NadeMenuID, 0);
	} else {
		if (g_mAutoNades)
			equipUser(id, EQUIP_GREN)
	}
	
	return PLUGIN_HANDLED
}

//Nade Menu handler
public m_NadeHandler(id, menu, item)
{
	if (item < 0) return PLUGIN_CONTINUE;
	
	new cmd[6], iName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, cmd, 5, iName, 63, callback);
	
	new choice = str_to_num(cmd);
	
	if (choice == 1)
	{
		g_mNades[id] = true;
	}
	else if (choice == 2)
	{
		g_mNades[id] = false;
	}
	
	equipUser(id, EQUIP_GREN)

	return PLUGIN_HANDLED;
}

buildMenu()
{
	//Equip Menu
	menu_additem(g_EquipMenuID, "New Weapons", "1", 0, -1);
	menu_additem(g_EquipMenuID, "Previous Setup", "2", 0, -1);
	menu_additem(g_EquipMenuID, "2+Don't show menu again", "3", 0, -1);
	
	//Armor Menu
	menu_additem(g_ArmorMenuID, "Yes, armor up", "1", 0, -1);
	menu_additem(g_ArmorMenuID, "No Armor", "2", 0, -1);
	
	//Nade Menu
	menu_additem(g_NadeMenuID, "All Grenades", "1", 0, -1);
	menu_additem(g_NadeMenuID, "No Grenades", "2", 0, -1);
	
	return PLUGIN_HANDLED
}

equipUser(id, to)
{
	if (!is_user_alive(id) )
		return
	
	if (to & EQUIP_SEC)
	{
		//Give Secondary
		GiveUserFullWeapon(id, g_SecWeapons[id])
	}
	
	if (to & EQUIP_PRI)
	{
		//Give Primary
		GiveUserFullWeapon(id, g_PrimWeapons[id])
	}
	
	if (to & EQUIP_ARMOR)
	{
		//Give Armor
		if (g_mAutoArmor || g_mArmor[id])
		{
			new armor = g_mArmor[id] ? 2 : g_Armor;
			cs_set_user_armor(id, DEFAULT_ARMOR, CsArmorType:armor);
		}
	}
	
	if (to & EQUIP_GREN)
	{
		//Give Nades
		if (g_mNades[id] || g_mAutoNades)
		{
			if (g_Nade)
				GiveUserFullWeapon(id,"weapon_hegrenade");
			
			if (g_Smoke)
				GiveUserFullWeapon(id, "weapon_smokegrenade");
		
			if (g_Flash)
				GiveUserFullWeapon(id, "weapon_flashbang");
		}
		else
		{
			if (!g_mAutoNades)
				return

			if (g_Nade)
				GiveUserFullWeapon(id,"weapon_hegrenade");
			
			if (g_Smoke)
				GiveUserFullWeapon(id, "weapon_smokegrenade");
		
			if (g_Flash)
				GiveUserFullWeapon(id, "weapon_flashbang");
		}
	}
}

GiveUserFullWeapon(id, wp[])
{
	/** First check to make sure the user does not have a weapon in this slot */
	new wpnid = getWepId(wp);
	new weapons[MAX_WEAPONS], num
	new name[24], weap
	new slot = g_WeaponSlots[wpnid]
	if (slot == SLOT_SECONDARY || slot == SLOT_PRIMARY)
	{
		get_user_weapons(id, weapons, num)
		for (new i=0; i<num; i++)
		{
			weap = weapons[i]
			if (weap == wpnid)
				continue
			if (g_WeaponSlots[weap] == slot)
			{
				get_weaponname(weap, name, 23)
				csdm_force_drop(id, name)
			}
		}
	}
	
	csdm_give_item(id, wp);

	new bpammo = g_MaxBPAmmo[wpnid]
	if (bpammo)
		cs_set_user_bpammo(id, wpnid, bpammo);
}

// MAIN FUNCTION OF THE PLUGIN
public csdm_PostSpawn(player)
{
	if (is_user_bot(player))
	{
		new randPrim = random_num(0, g_iNumBotPrim-1);
		new randSec = random_num(0, g_iNumBotSec-1);

		GiveUserFullWeapon(player, g_BotPrim[randPrim]);
		GiveUserFullWeapon(player, g_BotSec[randSec]);
	}
	else
	{
		if (g_mShowuser[player])
		{
			g_MenuState[player] = 1
			menu_display(player, g_EquipMenuID, 0);
		}
		else
		{
			g_MenuState[player] = 0
			equipUser(player, EQUIP_ALL);
		}
	}
	
	return PLUGIN_CONTINUE
}

/*showep(id)
{
	menu_display(id, g_EquipMenuID, 0);
}*/

public enableMenu(id)
{
	if (!csdm_active())
		return PLUGIN_CONTINUE
		
	if (!g_mShowuser[id])
	{
		g_mShowuser[id] = true
		client_print(id, print_chat, "[CSDM] Your equip menu has been re-enabled.")
		if (!g_MenuState[id])
		{
			g_MenuState[id] = 1
			menu_display(id, g_EquipMenuID, 0)
		}
	} else {
		client_print(id, print_chat, "[CSDM] Your equip menu is already enabled.")
	}
	
	return PLUGIN_HANDLED
}
