/**
 * csdm_protection.sma
 * CSDM plugin that lets you have spawn protection
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
#include <engine>
#include <csdm>

new g_ProtColors[3] = { 0, 255, 0 }
new g_GlowAlpha
new g_Protected[33]
new bool:g_Enabled = false
new Float:g_ProtTime = 2.0

//Tampering with the author and name lines can violate the copyright
new PLUGINNAME[] = "CSDM Protection"
new VERSION[] = "2.00"
new AUTHORS[] = "BAILOPAN"

public plugin_init()
{
	register_plugin(PLUGINNAME, VERSION, AUTHORS);
	
	csdm_reg_cfg("protection", "read_cfg")
}

public client_connect(id)
{
	g_Protected[id] = 0
}

public client_disconnect(id)
{
	if (g_Protected[id])
	{
		remove_task(g_Protected[id])
		g_Protected[id] = 0
	}
}

SetProtection(id)
{
	if (g_Protected[id])
		remove_task(g_Protected[id])
		
	if (!is_user_connected(id))
		return
		
	set_task(g_ProtTime, "ProtectionOver", id)
	g_Protected[id] = id
	set_rendering(id, kRenderFxGlowShell, g_ProtColors[0], g_ProtColors[1], g_ProtColors[2], kRenderNormal, 255)
	entity_set_float(id, EV_FL_takedamage, 0.0)
}

RemoveProtection(id)
{
	if (g_Protected[id])
		remove_task(g_Protected[id])
		
	ProtectionOver(id)
}

public ProtectionOver(id)
{
	g_Protected[id] = 0
	
	if (!is_user_connected(id))
		return
	
	set_rendering(id, kRenderFxNone, 0, 0, 0, kRenderNormal, 0)
	entity_set_float(id, EV_FL_takedamage, 2.0)
}

public csdm_PostDeath(killer, victim, headshot, const weapon[])
{
	if (!g_Enabled)
		return
		
	RemoveProtection(victim)
}

public csdm_PostSpawn(player, bool:fake)
{
	SetProtection(player)
}

public client_PreThink(id)
{
	if (!g_Enabled || !g_Protected[id] || !is_user_connected(id))
		return
	
	new buttons = entity_get_int(id,EV_INT_button);
     
	if ( (buttons & IN_ATTACK) || (buttons & IN_ATTACK2) )
	{
		RemoveProtection(id)
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
		
		if (equali(setting, "colors"))
		{
			new red[10], green[10], blue[10], alpha[10]
			parse(value, red, 9, green, 9, blue, 9, alpha, 9)
			
			g_ProtColors[0] = str_to_num(red)
			g_ProtColors[1] = str_to_num(green)
			g_ProtColors[2] = str_to_num(blue)
			g_GlowAlpha = str_to_num(alpha)
		} else if (equali(setting, "enabled")) {
			g_Enabled = str_to_num(value) ? true : false
		} else if (equali(setting, "time")) {
			g_ProtTime = str_to_float(value)
		}
	}
}
