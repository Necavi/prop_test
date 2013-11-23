#pragma semicolon 1

#include <sourcemod>

#define VERSION "2.0"

#tryinclude <jenkins>

#if !defined BUILD
#define BUILD "0"
#endif

public Plugin:myinfo = 
{
	name = "prop_test",
	author = "necavi",
	description = "Allows easy testing of entity properties.",
	version = VERSION,
	url = "http://necavi.org"
}
public OnPluginStart()
{
	CreateConVar("sm_proptest_version", VERSION, "", FCVAR_PLUGIN);
	CreateConVar("sm_proptest_build", BUILD, "", FCVAR_PLUGIN);
	RegAdminCmd("set_ent_prop", Command_SetEntProp, ADMFLAG_CUSTOM3, "set_ent_prop <entity> <prop> <value> - sets the value of an entity property (use -1 to target yourself)");
	RegAdminCmd("get_ent_prop", Command_GetEntProp, ADMFLAG_CUSTOM3, "get_ent_prop <entity> <prop> - gets the value of an entity property (use -1 to target yourself)");
}
public Action:Command_GetEntProp(client, args)
{
	HandleEntPropCommand(client, args, false);
	return Plugin_Handled;
}
public Action:Command_SetEntProp(client, args)
{
	HandleEntPropCommand(client, args, true);
	return Plugin_Handled;
}
HandleEntPropCommand(client, args, setProp)
{
	new String:prop[128];
	new String:sTarget[8];
	new PropFieldType:field;
	GetCmdArg(1, sTarget, sizeof(sTarget));
	new temp = StringToInt(sTarget);
	new target = temp > -1 ? temp : client;
	GetCmdArg(2, prop, sizeof(prop));
	new offset;
	new String:cls[256];
	GetEntityClassname(target, cls, sizeof(cls));
	new String:name[256];
	if(ValidPlayer(target))
	{
		GetClientName(target, name, sizeof(name));
	}
	else
	{
		strcopy(name, sizeof(name), cls);
	}
	offset = FindSendPropInfo(cls, prop, field);
	new PropType:type = Prop_Send;
	if(offset <= 0)
	{
		offset = FindDataMapOffs(target, prop, field);
		type = Prop_Data;
	}
	if(offset == 0)
	{
		PrintTag(client, "\x03%s \x01has no offset on \x05%s\x01.", prop, cls);
		return;
	}
	else if(offset == -1)
	{
		PrintTag(client, "\x03%s \x01does not exist on \x05%s\x01.", prop, cls);
		return;
	}
	switch(field)
	{
		case PropField_Integer:
		{
			if(setProp)
			{
				new String:arg[16];
				GetCmdArg(3, arg, sizeof(arg));
				SetEntProp(target, type, prop, StringToInt(arg));
				PrintTag(client,"Set \x05%s\x01's \x03%s \x01prop to \x04%s\x01.", name, prop, arg);
			}
			else
			{
				PrintTag(client,"\x05%s\x01's \x03%s \x01prop is \x04%d\x01.", name, prop, GetEntProp(target, type, prop));
			}
		}
		case PropField_Float:
		{
			if(setProp)
			{
				new String:arg[16];
				GetCmdArg(3, arg, sizeof(arg));
				SetEntPropFloat(target, type, prop, StringToFloat(arg));
				PrintTag(client,"Set \x05%s\x01's \x03%s \x01prop to \x04%s\x01.", name, prop, arg);
			}
			else
			{
				PrintTag(client,"\x05%s\x01's \x03%s \x01prop is \x04%f\x01.", name, prop, GetEntPropFloat(target, type, prop));
			}
		}
		case PropField_Entity:
		{
			if(setProp)
			{
				new String:arg[16];
				GetCmdArg(3, arg, sizeof(arg));
				SetEntPropEnt(target, type, prop, StringToInt(arg));
				PrintTag(client,"Set \x05%s\x01's \x03%s \x01prop to \x04%s\x01.", name, prop, arg);
			}
			else
			{
				PrintTag(client,"\x05%s\x01's \x03%s \x01prop is \x04%d\x01.", name, prop, GetEntPropEnt(target, type, prop));
			}
		}
		case PropField_Vector:
		{
			if(setProp)
			{
				if(args == 5)
				{
					new String:buffer[16];
					new Float:vec[3];
					for(new i; i <3;i ++)
					{
						GetCmdArg(i + 2, buffer, sizeof(buffer));
						vec[i] = StringToFloat(buffer);
					}
					SetEntPropVector(target, type, prop, vec);
					PrintTag(client, "Set \x05%s\x01's \x03%s \x01prop to <\x04%f\x01:\x04%f\x01:\x04%f\x01>\x01.", target, prop, vec[0], vec[1], vec[2]);
				} 
				else 
				{
					PrintTag(client, "Please pass this function a vector (three float values).");
				}
			}
			else
			{
				new Float:vec[3];
				GetEntPropVector(target, type, prop, vec);
				PrintTag(client,"\x05%s\x01's \x03%s \x01prop is <\x04%f\x01:\x04%f\x01:\x04%f\x01>\x01.", target, prop, vec[0], vec[1], vec[2]);
			}
		}
		case PropField_String:
		{
			if(setProp)
			{
				new String:arg[256];
				new String:buffer[64];
				for(new i; i < (args - 2); i++)
				{
					GetCmdArg(i, buffer, sizeof(buffer));
					StrCat(arg, sizeof(arg), buffer);
				}
				SetEntPropString(target, type, prop, arg);
				PrintTag(client,"Set \x05%s\x01's \x03%s \x01prop to \x04%s\x01.", name, prop, arg);
			}
			else
			{
				new String:buffer[256];
				GetEntPropString(target, type, prop, buffer, sizeof(buffer));
				PrintTag(client,"\x05%s\x01's \x03%s \x01prop is \x04%s\x01.", name, prop, buffer);
			}
		}
		default:
		{
			PrintTag(client, "\x03%s \x01is unsupported on \x05%s\x01.", prop, name);
		}
	}
}
bool:ValidPlayer(client)
{
	if(client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	return false;
}
PrintTag(client, const String:message[], any:...)
{
	new String:buffer[256];
	new String:fmessage[256];
	Format(buffer, sizeof(buffer), "\x01\x03[Prop]\x01 %s", message);
	VFormat(fmessage, sizeof(fmessage), buffer, 3);
	ReplyToCommand(client, fmessage);
}


