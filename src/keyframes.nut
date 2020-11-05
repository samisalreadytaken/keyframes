//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//- v1.1.14 -------------------------------------------------------------
IncludeScript("vs_library");
IncludeScript("vs_library/vs_interp");

if ( !("_KF_" in getroottable()) )
	::_KF_ <- { _VER_ = "1.1.14" };;

local _ = function(){

V <- ::Vector;
Q <- ::Quaternion;

::V <- V.weakref();
::Q <- Q.weakref();

try( DoIncludeScript("keyframes_data", getroottable()) )
catch(e){} // file does not exist

SendToConsole("alias kf_add\"script _KF_.AddKeyframe()\"");
SendToConsole("alias kf_remove\"script _KF_.RemoveKeyframe()\"");
SendToConsole("alias kf_remove_undo\"script _KF_.UndoLast(1)\"");
SendToConsole("alias kf_clear\"script _KF_.RemoveAllKeyframes()\"");
SendToConsole("alias kf_insert\"script _KF_.InsertKeyframe()\"");
SendToConsole("alias kf_copy\"script _KF_.CopyKeyframe()\"");
SendToConsole("alias kf_replace\"script _KF_.ReplaceKeyframe()\"");
SendToConsole("alias kf_replace_undo\"script _KF_.UndoLast(0)\"");
SendToConsole("alias kf_removefov\"script _KF_.RemoveFOV()\"");
SendToConsole("alias kf_compile\"script _KF_.Compile()\"");
SendToConsole("alias kf_play\"script _KF_.Play()\"");
SendToConsole("alias kf_stop\"script _KF_.Stop()\"");
SendToConsole("alias kf_save\"script _KF_.Save()\"");
SendToConsole("alias kf_savekeys\"script _KF_.Save(1)\"");
// SendToConsole("alias kf_save_precise\"script _KF_.ToggleSaveMode()\"");
SendToConsole("alias kf_mode_ang\"script _KF_.SetInterpMode(0)\"");
SendToConsole("alias kf_edit\"script _KF_.ToggleEditMode()\"");
SendToConsole("alias kf_select\"script _KF_.SelectKeyframe()\"");
SendToConsole("alias kf_see\"script _KF_.SeeKeyframe()\"");
SendToConsole("alias kf_next\"script _KF_.NextKeyframe()\"");
SendToConsole("alias kf_prev\"script _KF_.PrevKeyframe()\"");
SendToConsole("alias kf_showkeys\"script _KF_.ShowToggle(0)\"");
SendToConsole("alias kf_showpath\"script _KF_.ShowToggle(1)\"");
SendToConsole("alias kf_trim_undo\"script _KF_.UndoLastTrim()\"");
SendToConsole("alias kf_cmd\"script _KF_.PrintCmd()\"");

//--------------------------------------------------------------

SendToConsole("clear;script _KF_.PostSpawn()");

VS.GetLocalPlayer();

local FRAMETIME = 0.015625;
local flShowTime = FrameTime()*6;
local MAX_COORD_VEC = Vector(MAX_COORD_FLOAT-1,MAX_COORD_FLOAT-1,MAX_COORD_FLOAT-1);
local EF =
{
	ON  = (1<<4)|(1<<6)|(1<<3)|0,
	OFF = (1<<4)|(1<<6)|(1<<3)|(1<<5)
}

SND_BUTTON <- "UIPanorama.container_countdown";

if ( !("_Compile" in this) )
{
	_Compile <- delegate this :
	{
		RTIME = 0.0,
		_CLI = 0,
		_STP = 0,
		_IDX = 0,
		_CMX = 0,
		Catmull_Rom_Spline = ::VS.Catmull_Rom_Spline.bindenv(::VS),
		Catmull_Rom_SplineQ = ::VS.Catmull_Rom_SplineQ.bindenv(::VS),
		QAngleNormalize = ::VS.QAngleNormalize.bindenv(::VS),
		VectorAngles = ::VS.VectorAngles.weakref(),
		sort = function(x,y)
		{
			if ( x[0] > y[0] ) return  1;
			if ( x[0] < y[0] ) return -1;
			return 0;
		}
	}

	_Save <- delegate this :
	{
		_LIM = 0,
		_STP = 0,
		_IDX = 0,
		_CMX = 0,

		ToString = null,
		LOG = null,
		data_pos_save = null,
		data_ang_save = null
	}

	m_data_pos_kf <- [];   // Vector position
	m_data_dir_kf <- [];   // Vector direction
	m_data_quat_kf <- [];  // Quaternion orientation
	m_data_fov_kf <- [];
	m_data_pos_comp <- []; // Vector position
	m_data_ang_comp <- []; // QAngle angle
	m_data_fov_comp <- [];
	m_list_last_replace <- [];
	m_list_last_remove <- [];
	m_data_last_trim_pos <- [];
	m_data_last_trim_ang <- [];

	m_bSavePrecise <- false;
	m_iSaveType <- -1;
	m_bCompiling <- false;
	m_bInPlayback <- false;
	m_bInEditMode <- false;
	m_bPlaybackPending <- false;
	m_bInterpModeAng <- true;
	m_bTrimDirection <- true;
	m_nSelectedKeyframe <- -1;
	m_flInterpResolution <- 0.01;
	m_nDrawResolution <- 25;
	m_nCurrKeyframe <- 0;
	m_bShowPath <- true;
	m_bShowKeys <- true;
	m_bSeeing <- false;
	IN_ROLL_1 <- false;
	IN_ROLL_0 <- false;
	IN_FOV_1 <- false;
	IN_FOV_0 <- false;
	__STP <- floor(1.0/m_flInterpResolution);
	m_iFOV <- 90;
	m_vecLastQuatKey <- null;

	QuaternionAngles <- ::VS.QuaternionAngles2.bindenv(::VS);
	Msg <- ::print;
};

if ( !("HPlayerEye" in getroottable()) )
	::HPlayerEye <- VS.CreateMeasure(HPlayer.GetName(),null,true);

if ( !("m_hThinkSet" in this) )
{
	m_hThinkSet <- VS.Timer(true,FRAMETIME,null,null,false,true).weakref();

	m_hThinkEdit <- VS.Timer(true,flShowTime-FrameTime(),null,null,false,true).weakref();

	m_hThinkKeys <- VS.Timer(true,FrameTime()*2.5,null,null,false,true).weakref();

	m_hGameText <- VS.CreateEntity("game_text",
	{
		channel = 200,
		color = Vector(255,138,0),
		holdtime = flShowTime,
		x = 0.475,
		y = 0.55
	},true).weakref();

	m_hGameText2 <- VS.CreateEntity("game_text",
	{
		channel = 201,
		color = Vector(255,138,0),
		holdtime = flShowTime,
		x = 0.56,
		y = 0.485
	},true).weakref();

	m_hHudHint <- VS.CreateEntity("env_hudhint",null,true).weakref();

	m_hCam <- VS.CreateEntity("point_viewcontrol",{ spawnflags = 1<<3 }).weakref();

	m_hListener <- VS.CreateEntity("game_ui",{ spawnflags = 1<<7, fieldofview = -1.0 },true).weakref();

	VS.AddOutput( m_hListener, "UnpressedAttack",  null );
	VS.AddOutput( m_hListener, "UnpressedAttack2", null );

	PrecacheModel("keyframes/kf_circle_orange.vmt");

	m_hKeySprite <- VS.CreateEntity("env_sprite",
	{
		rendermode = 8, // only 8 works when spawned through script, don't ask why
		glowproxysize = 64.0, // MAX_GLOW_PROXY_SIZE
		effects = EF.OFF
	},true).weakref();

	m_hKeySprite.SetModel("keyframes/kf_circle_orange.vmt");

//--------------------------------------------------------

	local sc = m_hThinkSet.GetScriptScope();
	sc.cam <- m_hCam.weakref();
	sc.pos <- m_data_pos_comp.weakref();
	sc.ang <- m_data_ang_comp.weakref();
	sc.fov <- m_data_fov_comp.weakref();
	sc.idx <- 0;
	sc.lim <- 0;
};

local szMapName = ::split(::GetMapName(),"/").top();

local s_aStrLoading;

// build loading string
if (1)
{
	local len = 0x20;
	local i1 = -1, i2 = 0;
	local d = "●", b = " ";
	local a = array(len,b);

	s_nIdxLoading <- 0;
	s_aStrLoading = [];

	for ( local i = len; i--; )
	{
		++i1;
		++i2;
		i1 = i1 & 0x1F;
		i2 = i2 & 0x1F;

		a[i1] = b;
		a[i2] = d;

		local t = "";

		foreach(s in a) t += s;

		s_aStrLoading.append(t);
	}
};

// load materials
DebugDrawLine(Vector(),Vector(1,1,1),0,0,0,true,1);
DebugDrawBox(Vector(),Vector(),Vector(1,1,1),0,0,0,254,1);

//--------------------------------------------------------------

local m_hCam = m_hCam;
function SetAngles(v):(m_hCam)
{
	return m_hCam.SetAngles(v.x,v.y,v.z);
}

function PlaySound(s)
{
	return ::HPlayer.EmitSound(s);
}

local ShowHudHint = VS.ShowHudHint;
local m_hHudHint = m_hHudHint;
function Hint(s):(ShowHudHint,m_hHudHint)
{
	return ShowHudHint( m_hHudHint, ::HPlayer, s );
}

function Error(s)
{
	Msg(s + "\n");
	PlaySound("Bot.Stuck2");
}

function MsgFail(s)
{
	Msg(s + "\n");
	// PlaySound("Player.WeaponSelected");
	PlaySound("UIPanorama.buymenu_failure");
}

function MsgHint(s)
{
	Msg(s + "\n");
	Hint(s);
}

// TODO: cleanup
// Process large data by splitting it into chunks, recursively process the chunkss
function LoadData( i = null ) : (szMapName)
{
	if ( m_bCompiling )
		return MsgFail("Cannot load file while compiling!");

	if ( i == null )
	{
		i = "lk_" + szMapName;

		if ( !( i in this ) && !( i in getroottable() ) )
		{
			i = "l_" + szMapName;
		};
	};

	if ( typeof i == "string" )
	{
		if ( i in getroottable() )
		{
			i = getroottable()[i];
		}
		else if ( i in this )
		{
			i = this[i];
		}
		else
		{
			return MsgFail("Invalid input.");
		};;
	};

	if ( typeof i != "table" )
		return MsgFail("Invalid input.");

	if ( !("pos" in i) || !("ang" in i) )
		return MsgFail("Invalid input.");

	if ( !i.pos.len() || !i.ang.len() )
		return MsgFail("Empty input.");

	Msg("Preparing to load...\n");
	PlaySound(SND_BUTTON);

	// b/w compat
	if ( "anq" in i )
	{
		i.quat <- delete i.anq;
	};

	// keyframe data
	if ( "quat" in i )
	{
		data_pos_load <- m_data_pos_kf.weakref();
		data_ang_load <- m_data_dir_kf.weakref();
		data_quat_load <- m_data_quat_kf.weakref();
		data_fov_load <- m_data_fov_kf.weakref();

		data_quat_load.resize( i.quat.len() );

		bLoadType <- 0;
	}
	// path data
	else
	{
		data_pos_load <- m_data_pos_comp.weakref();
		data_ang_load <- m_data_ang_comp.weakref();
		data_fov_load <- m_data_fov_comp.weakref();

		bLoadType <- 1;
	};

	if ( data_pos_load.len() != data_ang_load.len() )
		return Error("[ERROR] Corrupted data!");

	data_pos_load.resize( i.pos.len() );
	data_ang_load.resize( i.ang.len() );

	if ( "fov" in i )
		data_fov_load.resize( i.fov.len() );

	data_load_input <- i.weakref();

	_LIM <- i.pos.len();
	_STP <- 1450;
	_IDX <- 0;
	_CMX <- clamp( _STP, 0, _LIM );

	Msg("Loading (1/3) .");

	return LoadInternal();
}

function LoadInternal():(FRAMETIME)
{
	if ( "pos" in data_load_input )
	{
		Msg(".");

		for ( local i = _IDX; i < _CMX; ++i )
			data_pos_load[i] = data_load_input["pos"][i];

		_IDX += _STP;
		_CMX = ::clamp( _CMX + _STP, 0, _LIM );

		if ( _IDX >= _CMX )
		{
			Msg("\nLoading (2/3) .");

			delete data_pos_load;
			delete data_load_input["pos"];

			_IDX = 0;
			_CMX = ::clamp( _STP, 0, _LIM );
			return LoadInternal();
		};

		return::VS.EventQueue.AddEvent( LoadInternal, FRAMETIME, this );
	};

	if ( "ang" in data_load_input )
	{
		Msg(".");

		for ( local i = _IDX; i < _CMX; ++i )
			data_ang_load[i] = data_load_input["ang"][i];

		_IDX += _STP;
		_CMX = ::clamp( _CMX + _STP, 0, _LIM );

		if ( _IDX >= _CMX )
		{
			Msg("\nLoading (3/3) .");

			delete data_ang_load;
			delete data_load_input["ang"];

			_IDX = 0;
			_CMX = ::clamp( _STP, 0, _LIM );
			return LoadInternal();
		};

		return::VS.EventQueue.AddEvent( LoadInternal, FRAMETIME, this );
	};

	if ( "quat" in data_load_input )
	{
		Msg(".");

		for ( local i = _IDX; i < _CMX; ++i )
			data_quat_load[i] = data_load_input["quat"][i];

		_IDX += _STP;
		_CMX = ::clamp( _CMX + _STP, 0, _LIM );

		if ( _IDX >= _CMX )
		{
			Msg(".");

			delete data_quat_load;
			delete data_load_input["quat"];

			_IDX = 0;
			_CMX = ::clamp( _STP, 0, _LIM );
			return LoadInternal();
		};

		return::VS.EventQueue.AddEvent( LoadInternal, FRAMETIME, this );
	};

	if ( "fov" in data_load_input )
	{
		Msg(".");

		foreach( i, a in data_load_input["fov"] )
			data_fov_load[i] = clone a;

		delete data_fov_load;
		delete data_load_input["fov"];

		return LoadInternal();
	};

	local szInput = ::VS.GetVarName( delete data_load_input );

	PlaySound(SND_BUTTON);
	Msg("\n\nLoading complete! \"" + szInput + "\" ( " +
		(bLoadType ? m_data_pos_comp.len()*FRAMETIME + " seconds" : m_data_pos_kf.len() + " keyframes" ) + " )\n");


	delete _LIM;
	delete _STP;
	delete _IDX;
	delete _CMX;

	delete bLoadType;

	if ( szInput in this )
		delete this[szInput];
	else if ( szInput in getroottable() )
		delete getroottable()[szInput];;
}

//--------------------------------------------------------------

// see mode listen WASD
function ListenKeys(i)
{
	if (i)
	{
		ListenMouse(0);

		::VS.AddOutput( m_hListener, "PressedAttack",  NextKeyframe );
		::VS.AddOutput( m_hListener, "PressedAttack2", PrevKeyframe );

		m_hListener.ConnectOutput("PressedMoveRight","PressedMoveRight");
		m_hListener.ConnectOutput("UnpressedMoveRight","UnpressedMoveRight");
		m_hListener.ConnectOutput("PressedMoveLeft","PressedMoveLeft");
		m_hListener.ConnectOutput("UnpressedMoveLeft","UnpressedMoveLeft");
		m_hListener.ConnectOutput("PressedForward","PressedForward");
		m_hListener.ConnectOutput("UnpressedForward","UnpressedForward");
		m_hListener.ConnectOutput("PressedBack","PressedBack");
		m_hListener.ConnectOutput("UnpressedBack","UnpressedBack");

		m_hListener.SetTeam( ::HPlayer.IsNoclipping().tointeger() );

		// freeze player
		::HPlayer.__KeyValueFromInt( "movetype", 0 );
	}
	else
	{
		m_hListener.DisconnectOutput("PressedAttack","PressedAttack");
		m_hListener.DisconnectOutput("PressedAttack2","PressedAttack2");
		m_hListener.DisconnectOutput("PressedMoveRight","PressedMoveRight");
		m_hListener.DisconnectOutput("UnpressedMoveRight","UnpressedMoveRight");
		m_hListener.DisconnectOutput("PressedMoveLeft","PressedMoveLeft");
		m_hListener.DisconnectOutput("UnpressedMoveLeft","UnpressedMoveLeft");
		m_hListener.DisconnectOutput("PressedForward","PressedForward");
		m_hListener.DisconnectOutput("UnpressedForward","UnpressedForward");
		m_hListener.DisconnectOutput("PressedBack","PressedBack");
		m_hListener.DisconnectOutput("UnpressedBack","UnpressedBack");

		// UNDONE: continue previous state
		// ::HPlayer.__KeyValueFromInt( "movetype", m_hListener.GetTeam() ? 8 : 2 );

		// just enable noclip
		// saving state causes problems for some reason
		// can't be bothered to find a solution
		::HPlayer.__KeyValueFromInt( "movetype", 8 );
	};
}

// default listen MOUSE1, MOUSE2
function ListenMouse(i)
{
	if (i)
	{
		ListenKeys(0);

		::VS.AddOutput( m_hListener, "PressedAttack",  AddKeyframe );
		::VS.AddOutput( m_hListener, "PressedAttack2", RemoveKeyframe );
	}
	else
	{
		m_hListener.DisconnectOutput("PressedAttack","PressedAttack");
		m_hListener.DisconnectOutput("PressedAttack2","PressedAttack2");
	};
}

VS.AddOutput( m_hListener, "PressedMoveRight",  "_KF_.KEY_ROLL_1(1)" );
VS.AddOutput( m_hListener, "UnpressedMoveRight","_KF_.KEY_ROLL_1(0)" );
VS.AddOutput( m_hListener, "PressedMoveLeft",   "_KF_.KEY_ROLL_0(1)" );
VS.AddOutput( m_hListener, "UnpressedMoveLeft", "_KF_.KEY_ROLL_0(0)" );
VS.AddOutput( m_hListener, "PressedForward",    "_KF_.KEY_FOV_1(1)"  );
VS.AddOutput( m_hListener, "UnpressedForward",  "_KF_.KEY_FOV_1(0)"  );
VS.AddOutput( m_hListener, "PressedBack",       "_KF_.KEY_FOV_0(1)"  );
VS.AddOutput( m_hListener, "UnpressedBack",     "_KF_.KEY_FOV_0(0)"  );

// +use to see
VS.AddOutput( m_hListener, "PlayerOff", function()
{
	SeeKeyframe(0,1);

	::EntFireByHandle( m_hThinkKeys, "Disable" );
	IN_FOV_1 = false;
	IN_FOV_0 = false;
	IN_ROLL_1 = false;
	IN_ROLL_0 = false;

	::EntFireByHandle( m_hListener, "Activate", "", 0, ::HPlayer )
}, this );

//--------------------------------------------------------------

local nRollIncr = 4;

// Think keys roll
function KEY_ThinkRoll() : (nRollIncr)
{
	if ( IN_ROLL_1 )
	{
		m_vecLastQuatKey.z = ::clamp( m_vecLastQuatKey.z.tointeger() + nRollIncr, -180, 180 );
		SetAngles( m_vecLastQuatKey );
		Hint( "Roll "+m_vecLastQuatKey.z );
	}
	else if ( IN_ROLL_0 )
	{
		m_vecLastQuatKey.z = ::clamp( m_vecLastQuatKey.z.tointeger() - nRollIncr, -180, 180 );
		SetAngles( m_vecLastQuatKey );
		Hint( "Roll "+m_vecLastQuatKey.z );
	};;

	PlaySound("UIPanorama.store_item_rollover");
}

local fFovRate = FrameTime()*6;

// Think keys fov
function KEY_ThinkFOV() : (fFovRate)
{
	if ( IN_FOV_1 )
	{
		m_iFOV = ::clamp( m_iFOV-2, 1, 179 );
		Hint( "FOV "+m_iFOV );
		m_hCam.SetFov( m_iFOV, fFovRate );
	}
	else if ( IN_FOV_0 )
	{
		m_iFOV = ::clamp( m_iFOV+2, 1, 179 );
		Hint( "FOV "+m_iFOV );
		m_hCam.SetFov( m_iFOV, fFovRate );
	};;

	PlaySound("UIPanorama.store_item_rollover");
}

// roll clockwise
function KEY_ROLL_1(i)
{
	if (i)
	{
		if ( !m_bSeeing )
			return MsgFail("You need to be in see mode to use the key controls.");

		::VS.OnTimer( m_hThinkKeys, KEY_ThinkRoll );
		m_vecLastQuatKey = QuaternionAngles( m_data_quat_kf[m_nCurrKeyframe], ::Vector() );

		IN_ROLL_1 = true;
		::EntFireByHandle( m_hThinkKeys, "Enable" );
	}
	else
	{
		if ( !m_bSeeing )
			return;

		IN_ROLL_1 = false;
		::EntFireByHandle( m_hThinkKeys, "Disable" );

		// save last set data
		m_data_quat_kf[m_nCurrKeyframe] = ::VS.AngleQuaternion( m_vecLastQuatKey, ::Quaternion() );
	};
}

// roll counter-clockwise
function KEY_ROLL_0(i)
{
	if (i)
	{
		if ( !m_bSeeing )
			return MsgFail("You need to be in see mode to use the key controls.");

		::VS.OnTimer( m_hThinkKeys, KEY_ThinkRoll );
		m_vecLastQuatKey = QuaternionAngles( m_data_quat_kf[m_nCurrKeyframe], ::Vector() );

		IN_ROLL_0 = true;
		::EntFireByHandle( m_hThinkKeys, "Enable" );
	}
	else
	{
		if ( !m_bSeeing )
			return;

		IN_ROLL_0 = false;
		::EntFireByHandle( m_hThinkKeys, "Disable" );

		// save last set data
		m_data_quat_kf[m_nCurrKeyframe] = ::VS.AngleQuaternion( m_vecLastQuatKey, ::Quaternion() );
	};
}

// fov in
function KEY_FOV_1(i)
{
	if (i)
	{
		if ( !m_bSeeing )
			return MsgFail("You need to be in see mode to use the key controls.");

		::VS.OnTimer( m_hThinkKeys, KEY_ThinkFOV );
		m_iFOV = 90;
		IN_FOV_1 = true;
		::EntFireByHandle( m_hThinkKeys, "Enable" );

		// get current fov value
		foreach( i,v in m_data_fov_kf ) if ( v[0] == m_nCurrKeyframe )
		{
			m_iFOV = v[1] ? v[1] : 90;
			return;
		};

		// if the keyframe doesnt have any fov data, create one
		m_data_fov_kf.append( [m_nCurrKeyframe,0,0] );
	}
	else
	{
		if ( !m_bSeeing )
			return;

		IN_FOV_1 = false;
		::EntFireByHandle( m_hThinkKeys, "Disable" );

		foreach( i,v in m_data_fov_kf ) if ( v[0] == m_nCurrKeyframe )
			v[1] = m_iFOV;
	};
}

// fov out
function KEY_FOV_0(i)
{
	if (i)
	{
		if ( !m_bSeeing )
			return MsgFail("You need to be in see mode to use the key controls.");

		::VS.OnTimer( m_hThinkKeys, KEY_ThinkFOV );
		m_iFOV = 90;
		IN_FOV_0 = true;
		::EntFireByHandle( m_hThinkKeys, "Enable" );

		// get current fov value
		foreach( i,v in m_data_fov_kf ) if ( v[0] == m_nCurrKeyframe )
		{
			m_iFOV = v[1] ? v[1] : 90;
			return;
		};

		// if the keyframe doesnt have any fov data, create one
		m_data_fov_kf.append( [m_nCurrKeyframe,0,0] ); // -1
	}
	else
	{
		if ( !m_bSeeing )
			return;

		IN_FOV_0 = false;
		::EntFireByHandle( m_hThinkKeys, "Disable" );

		foreach( i,v in m_data_fov_kf ) if ( v[0] == m_nCurrKeyframe )
			v[1] = m_iFOV;
	};
}

//--------------------------------------------------------------

function ShowToggle(t)
{
	// kf_showpath
	if (t)
	{
		m_bShowPath = !m_bShowPath;
		Msg( m_bShowPath ? "Showing path\n" : "Hiding path\n" );
	}
	// kf_showkeys
	else
	{
		m_bShowKeys = !m_bShowKeys;
		Msg( m_bShowKeys ? "Showing keyframes\n" : "Hiding keyframes\n" );
	};

	::SendToConsole("clear_debug_overlays");
	PlaySound(SND_BUTTON);
}

// kf_edit
function ToggleEditMode():(EF)
{
	if ( m_bCompiling )
		return MsgFail("Cannot "+(m_bInEditMode?"disable":"enable")+" edit mode while compiling!");

	if ( !m_data_pos_kf.len() )
	{
		m_data_pos_kf.clear();
		m_data_dir_kf.clear();
	};

	if ( !m_data_pos_comp.len() )
	{
		m_data_pos_comp.clear();
		m_data_ang_comp.clear();
	};

	m_bInEditMode = !m_bInEditMode;

	// on
	if ( m_bInEditMode )
	{
		if ( ::developer() > 1 )
		{
			Msg("Setting developer level to 1\n");
			::SendToConsole("developer 1");
		};

		// DrawOverlay(1);
		::SendToConsole( "cl_drawhud 1" );
		m_hKeySprite.__KeyValueFromInt( "effects", EF.ON );
		::EntFireByHandle( m_hThinkEdit, "Enable" );

		Msg("Edit mode enabled.\n");
	}
	// off
	else
	{
		// unsee
		if ( m_bSeeing )
			SeeKeyframe(1);

		// DrawOverlay(0);
		m_hKeySprite.__KeyValueFromInt( "effects", EF.OFF );
		::EntFireByHandle( m_hThinkEdit, "Disable" );
		::EntFireByHandle( m_hGameText2, "SetText", "", 0, ::HPlayer );

		Msg("Edit mode disabled.\n");
	};

	::SendToConsole("clear_debug_overlays");
	PlaySound(SND_BUTTON);
}

// kf_select
function SelectKeyframe( bShowMsg = 1 )
{
	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to select.");

	// ( m_nSelectedKeyframe != m_nCurrKeyframe )
	if ( m_nSelectedKeyframe == -1 )
	{
		m_nSelectedKeyframe = m_nCurrKeyframe;

		if ( bShowMsg )
			MsgHint("Selected keyframe #" + m_nSelectedKeyframe);
	}
	else
	{
		if ( bShowMsg )
			MsgHint("Unselected keyframe #" + m_nSelectedKeyframe);

		// unsee silently
		if ( m_bSeeing )
			SeeKeyframe(1);

		m_nSelectedKeyframe = -1;
	};

	PlaySound(SND_BUTTON);
}

// kf_next
function NextKeyframe()
{
	if ( m_nSelectedKeyframe == -1 )
		return MsgFail("You need to have a keyframe selected to use kf_next.");

	local t = (m_nSelectedKeyframe+1) % m_data_pos_kf.len();
	local b = m_bSeeing;		// hold current value

	// unsee silently
	if (b) SeeKeyframe(1,0);

	m_nSelectedKeyframe = t;
	m_nCurrKeyframe = t;

	// then see again
	if (b) SeeKeyframe(0,0);
}

// kf_prev
function PrevKeyframe()
{
	if ( m_nSelectedKeyframe == -1 )
		return MsgFail("You need to have a keyframe selected to use kf_prev.");

	local n = m_nSelectedKeyframe-1;

	if ( n < 0 )
		n += m_data_pos_kf.len();

	local t = n % m_data_pos_kf.len();
	local b = m_bSeeing;

	// unsee silently
	if (b) SeeKeyframe(1,0);

	m_nSelectedKeyframe = t;
	m_nCurrKeyframe = t;

	// then see again
	if (b) SeeKeyframe(0,0);
}

// kf_see
// TODO: a better method?
function SeeKeyframe( bUnsafeUnsee = 0, bShowMsg = 1 ) : (EF)
{
	if ( bUnsafeUnsee )
	{
		__CompileFOV();
		m_bSeeing = false;
		if ( m_nSelectedKeyframe != -1 ) SelectKeyframe(0);
		m_hKeySprite.__KeyValueFromInt( "effects", EF.ON );
		m_hCam.SetFov(0,0.1);
		::EntFireByHandle( m_hCam, "Disable", "", 0, ::HPlayer );
		ListenMouse(1);
		return;
	};

	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot use see while in playback!");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to use see.");

	if ( !m_data_pos_kf.len() )
		return MsgFail("No keyframes found.");

	m_bSeeing = !m_bSeeing;

	if ( m_bSeeing )
	{
		// if not selected, select
		if ( m_nSelectedKeyframe == -1 )
			SelectKeyframe(0);

		// hide the helper
		m_hKeySprite.__KeyValueFromInt( "effects", EF.OFF );

		// set fov and pos to selected
		foreach( v in m_data_fov_kf ) if ( v[0] == m_nSelectedKeyframe )
			m_hCam.SetFov(v[1],0.25);

		m_hCam.SetOrigin( m_data_pos_kf[m_nSelectedKeyframe] );
		SetAngles( QuaternionAngles( m_data_quat_kf[m_nSelectedKeyframe] ) );
		::EntFireByHandle( m_hCam, "Enable", "", 0, ::HPlayer );

		ListenKeys(1);

		if ( bShowMsg )
			MsgHint("Seeing keyframe #" + m_nSelectedKeyframe);
	}
	else
	{
		__CompileFOV();

		// if selected, unselect
		if ( m_nSelectedKeyframe != -1 )
			SelectKeyframe(0);

		m_hKeySprite.__KeyValueFromInt( "effects", EF.ON );
		m_hCam.SetFov(0,0.1);
		::EntFireByHandle( m_hCam, "Disable", "", 0, ::HPlayer );
		// ListenKeys(0);

		ListenMouse(1);

		if ( bShowMsg )
		{
			Msg("Stopped seeing keyframe\n");
			::VS.HideHudHint( m_hHudHint, ::HPlayer );
		};
	};

	PlaySound(SND_BUTTON);
}

// constant values
local VEC_MINS = Vector(-8,-8,-8),
      VEC_MAXS = Vector(8,8,8);
local DebugDrawBox = ::DebugDrawBox,
      DebugDrawLine = ::DebugDrawLine,
      EntFireByHandle = ::EntFireByHandle;

// Think UI
VS.OnTimer( m_hThinkEdit, function() : (flShowTime,VEC_MINS,VEC_MAXS,DebugDrawBox,DebugDrawLine,EntFireByHandle)
{
	local HPlayer = ::HPlayer;
	local keys = m_data_pos_kf;

	if ( keys.len() )
	{
		local szHold = "";

		// not selected any keyframe
		if ( m_nSelectedKeyframe == -1 )
		{
			local nCurr = keys.len()-1;
			local fThreshold = 0.9;
			local vEyePos = HPlayer.EyePosition();
			local vEyeDir = ::HPlayerEye.GetForwardVector();

			foreach( i, v in keys )
			{
				local dir = v - vEyePos;
				dir.Norm();
				local dot = vEyeDir.Dot(dir);

				if ( dot > fThreshold )
				{
					nCurr = i;
					fThreshold = dot;
				};

				if ( m_bShowKeys )
					DebugDrawBox( v, VEC_MINS, VEC_MAXS, 255, 0, 0, 0, flShowTime );
			}

			m_nCurrKeyframe = nCurr;
		}
		else if ( m_bShowKeys )
		{
			szHold = " (HOLD)";

			foreach( i, v in keys )
				DebugDrawBox( v, VEC_MINS, VEC_MAXS, 255, 0, 0, 0, flShowTime );
		};;

		// show fov
		foreach( v in m_data_fov_kf ) if ( v[0] == m_nCurrKeyframe )
			m_hGameText2.__KeyValueFromString( "message", "FOV: " + v[1] );

		m_hGameText.__KeyValueFromString( "message", "KEY: " + m_nCurrKeyframe + szHold );
		EntFireByHandle( m_hGameText, "Display", "", 0, HPlayer );
		EntFireByHandle( m_hGameText2, "Display", "", 0, HPlayer );
		EntFireByHandle( m_hGameText2, "SetText", "", 0, HPlayer );

		local vKeyPos = keys[m_nCurrKeyframe];

		// selected keyframe
		DebugDrawBox( vKeyPos, VEC_MINS, VEC_MAXS, 255, 138, 0, 255, flShowTime );
		m_hKeySprite.SetOrigin( vKeyPos );

//		if ( bMoveMode )
//		{
//			m_hKeySprite.SetOrigin(Vector());
//			hHelperTranslate.SetOrigin(vKeyPos);
//
//			local ORIG = HPlayer.EyePosition();
//			local tr = VS.TraceDir(ORIG, HPlayerEye.GetForwardVector()).Ray();
//
//			local origX = vKeyPos; //+ Vector(32,0,0);
//			local minsX = Vector(-54,-3,-3);
//			local maxsX = Vector(54,3,3);
//
//			if ( VS.IsBoxIntersectingRay(origX, minsX, maxsX, tr, 0.5) )
//			{
//				Hint("X")
//
//				DebugDrawLine(vKeyPos, vKeyPos - Vector(-128,0,0), 255, 255, 255, true, flShowTime);
//				DebugDrawBox(origX, minsX, maxsX, 255, 0, 0, 154, flShowTime);
//			}
//			else
//			{
//				local origY = vKeyPos; //+ Vector(0,32,0);
//				local minsY = Vector(-3,-54,-3);
//				local maxsY = Vector(3,54,3);
//
//				if ( VS.IsBoxIntersectingRay(origY, minsY, maxsY, tr, 0.5) )
//				{
//					Hint("Y")
//
//					DebugDrawLine(vKeyPos, vKeyPos - Vector(0,-128,0), 255, 255, 255, true, flShowTime);
//					DebugDrawBox(origY, minsY, maxsY, 0, 255, 0, 154, flShowTime);
//				}
//				else
//				{
//					local origZ = vKeyPos; //+ Vector(0,0,32);
//					local minsZ = Vector(-3,-3,-54);
//					local maxsZ = Vector(3,3,54);
//
//					if ( VS.IsBoxIntersectingRay(origZ, minsZ, maxsZ, tr, 0.5) )
//					{
//						Hint("Z")
//
//						DebugDrawLine(vKeyPos, vKeyPos + Vector(0,0,128),  255, 255, 255, true, flShowTime);
//						DebugDrawBox(origZ, minsZ, maxsZ, 0, 0, 255, 127, flShowTime);
//					};
//				};
//			};
//		};
	};

	if ( m_bShowPath )
	{
		local pos = m_data_pos_comp;
		local ang = m_data_ang_comp;
		local res = m_nDrawResolution;
		local len = pos.len()-res;
		local ToVector = ::VS.AngleVectors;

		for ( local i = 0; i < len; i+=res )
		{
			local pt = pos[i];
			DebugDrawLine( pt, pt + ToVector(ang[i]) * 16, 255, 128, 255, true, flShowTime );
			DebugDrawLine( pt, pos[i+res], 138, 255, 0, true, flShowTime );
		}
	};
},this );

//--------------------------------------------------------------

// kf_copy
// Set player pos/ang to the current keyframe
function CopyKeyframe()
{
	if ( !m_data_pos_kf.len() )
		return MsgFail("No keyframes found.");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to copy.");

	if ( m_bSeeing )
		return MsgFail("Cannot copy while seeing!");

	local pos = m_data_pos_kf[m_nCurrKeyframe];
	local dir = m_data_dir_kf[m_nCurrKeyframe];

	local dt = HPlayer.EyePosition() - HPlayer.GetOrigin();
	HPlayer.SetOrigin( VS.VectorSubtract( pos, dt ) );
	HPlayer.SetForwardVector( dir );

	MsgHint("Copied keyframe #" + m_nCurrKeyframe);
	PlaySound(SND_BUTTON);
}

// kf_replace
function ReplaceKeyframe()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!");

	if ( !m_data_pos_kf.len() )
		return MsgFail("No keyframes found.");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to insert keyframes.");

	if ( m_bSeeing )
		return MsgFail("Cannot replace while seeing!");

	// undolast_replace
	m_list_last_replace = [ m_nCurrKeyframe,
	                        m_data_pos_kf[m_nCurrKeyframe],
	                        m_data_dir_kf[m_nCurrKeyframe],
	                        m_data_quat_kf[m_nCurrKeyframe] ];

	local pos = ::HPlayer.EyePosition();
	local dir = ::HPlayerEye.GetForwardVector();

	m_data_pos_kf[m_nCurrKeyframe] = pos;
	m_data_dir_kf[m_nCurrKeyframe] = dir;
	m_data_quat_kf[m_nCurrKeyframe] = ::VS.AngleQuaternion( ::HPlayerEye.GetAngles(), ::Quaternion() );

	::DebugDrawLine( pos, pos + dir * 64, 138, 255, 0, true, 7 );
	::DebugDrawBox( pos, ::Vector(-4,-4,-4), ::Vector(4,4,4), 138, 255, 0, 127, 7 );

	MsgHint("Replaced keyframe #" + m_nCurrKeyframe);
	PlaySound(SND_BUTTON);
}

// kf_insert
function InsertKeyframe()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!");

	if ( !m_data_pos_kf.len() )
		return MsgFail("No keyframes found.");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to insert keyframes.");

	if ( m_bSeeing )
		return MsgFail("Cannot insert while seeing!");

	local pos = ::HPlayer.EyePosition();
	local dir = ::HPlayerEye.GetForwardVector();

	local i = m_nCurrKeyframe + 1;

	m_data_pos_kf.insert( i, pos );
	m_data_dir_kf.insert( i, dir );
	m_data_quat_kf.insert( i, ::VS.AngleQuaternion( ::HPlayerEye.GetAngles(), ::Quaternion() ) );

	::DebugDrawLine( pos, pos + dir * 64, 138, 255, 0, true, 7 );
	::DebugDrawBox( pos, ::Vector(-4,-4,-4), ::Vector(4,4,4), 138, 255, 0, 127, 7 );

	MsgHint("Inserted keyframe #" + i);
	PlaySound(SND_BUTTON);
}

// kf_remove
function RemoveKeyframe():(MAX_COORD_VEC)
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!");

	if ( !m_data_pos_kf.len() )
		return MsgFail("No keyframes found.");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to remove keyframes.");

	// unsee
	if ( m_bSeeing )
		SeeKeyframe(1);

	// undolast_remove
	m_list_last_remove = [ m_nCurrKeyframe,
	                       m_data_pos_kf.remove(m_nCurrKeyframe),
	                       m_data_dir_kf.remove(m_nCurrKeyframe),
	                       m_data_quat_kf.remove(m_nCurrKeyframe) ];

	foreach( i,v in m_data_fov_kf ) if ( v[0] == m_nCurrKeyframe )
	{
		m_list_last_remove.append( m_data_fov_kf.remove(i) );

		__CompileFOV();
	};

	if ( !m_data_pos_kf.len() )
	{
		MsgHint("Removed all keyframes.");

		// current
		m_nCurrKeyframe = 0;

		// unselect
		m_nSelectedKeyframe = -1;

		// cheap way to hide the sprite
		m_hKeySprite.SetOrigin(MAX_COORD_VEC);
	}
	else
	{
		MsgHint("Removed keyframe #" + m_nCurrKeyframe);

		// if out of bounds, reset
		if ( !(m_nCurrKeyframe in m_data_pos_kf) )
		{
			m_nCurrKeyframe = 0;
			m_nSelectedKeyframe = -1;
		};
	};

	PlaySound(SND_BUTTON);
}

// undolast
function UndoLast( t )
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!");

	switch ( t )
	{
		// replace undo
		case 0:
		{
			if ( !m_list_last_replace.len() )
				return MsgFail("No replaced keyframe found.");

			local i = m_list_last_replace[0];

			m_data_pos_kf[i] = m_list_last_replace[1];
			m_data_dir_kf[i] = m_list_last_replace[2];
			m_data_quat_kf[i] = m_list_last_replace[3];

			m_list_last_replace.clear();

			MsgHint("Undone replace #" + i);
		}
		// remove undo
		case 1:
		{
			if ( !m_list_last_remove.len() )
				return MsgFail("No removed keyframe found.");

			local i = m_list_last_remove[0];

			m_data_pos_kf.insert( i, m_list_last_remove[1] );
			m_data_dir_kf.insert( i, m_list_last_remove[2] );
			m_data_quat_kf.insert( i, m_list_last_remove[3] );

			if ( m_list_last_remove.len() > 4 )
				m_data_fov_kf.append( m_list_last_remove[4] );

			if ( m_list_last_remove.len() > 5 )
				Error("[ERROR] Assertion failed. Duplicated FOV data.");

			m_list_last_remove.clear();

			MsgHint("Undone remove #" + i);
		}
	}

	PlaySound(SND_BUTTON);
}

// kf_removefov
function RemoveFOV()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!");

	if ( !m_data_pos_kf.len() )
		return MsgFail("No keyframes found.");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to remove FOV data.");

	// refresh
	if ( m_bSeeing )
		m_hCam.SetFov(0,0.1);

	foreach( i,v in m_data_fov_kf ) if ( v[0] == m_nCurrKeyframe )
		m_data_fov_kf.remove(i);

	__CompileFOV();

	MsgHint("Removed FOV data at keyframe #" + m_nCurrKeyframe);
	PlaySound(SND_BUTTON);
}

// kf_add
function AddKeyframe()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!");

	if ( m_bSeeing )
		return MsgFail("Cannot add new keyframe while seeing!");

	local pos = ::HPlayer.EyePosition();
	local dir = ::HPlayerEye.GetForwardVector();

	m_data_pos_kf.append( pos );
	m_data_dir_kf.append( dir );
	m_data_quat_kf.append( ::VS.AngleQuaternion( ::HPlayerEye.GetAngles(), ::Quaternion() ) );

	::DebugDrawLine( pos, pos + dir * 64, 138, 255, 0, true, 7 );
	::DebugDrawBox( pos, Vector(-4,-4,-4), Vector(4,4,4), 138, 255, 0, 127, 7 );

	MsgHint("Added keyframe #" + (m_data_pos_kf.len()-1));
	PlaySound(SND_BUTTON);
}

// kf_clear
function RemoveAllKeyframes():(MAX_COORD_VEC)
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!");

	if ( !m_data_pos_kf.len() )
		return MsgFail("No keyframes found.");

	// unsee
	if ( m_bSeeing )
		SeeKeyframe(1);

	// unselect
	m_nSelectedKeyframe = -1;

	// current
	m_nCurrKeyframe = 0;

	MsgHint("Removed " + m_data_pos_kf.len() + " keyframes.");

	m_data_pos_kf.clear();
	m_data_dir_kf.clear();
	m_data_quat_kf.clear();
	m_data_fov_kf.clear();

	// undolast
	m_list_last_replace.clear();
	m_list_last_remove.clear();

	// cheap way to hide the sprite
	m_hKeySprite.SetOrigin(MAX_COORD_VEC);

	PlaySound(SND_BUTTON);
}

// kf_mode_ang
function SetInterpMode(i)
{
	if ( m_bCompiling )
		return MsgFail("Cannot change algorithm while compiling!");

	switch(i)
	{
		case 0:
			m_bInterpModeAng = !m_bInterpModeAng;
			Msg("Now using the " + ( m_bInterpModeAng ? "default" : "stabilised" ) + " angle algorithm.\n");
			break;
	}

	PlaySound(SND_BUTTON);
}

//--------------------------------------------------------------

// kf_compile
function Compile():(MAX_COORD_VEC,FRAMETIME,flShowTime)
{
	if ( m_bCompiling )
		return MsgFail("Compilation in progress...");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot compile while in playback!");

	if ( !m_data_pos_kf.len() )
		return MsgFail("No keyframes found.");

	if ( m_data_pos_kf.len() < 4 )
		return MsgFail("Not enough keyframes to compile. (Required minimum amount: 4)");

	if ( m_data_pos_kf.len() != m_data_dir_kf.len() || m_data_dir_kf.len() != m_data_quat_kf.len() )
		return Error("[ERROR] Assertion failed: Corrupted keyframe data! [p" + m_data_pos_kf.len() + ",a" + m_data_dir_kf.len() + ",q" + m_data_quat_kf.len() + "]");

	m_bCompiling = true;

	// stop seeing
	SeeKeyframe(1);

	// temporarily disable edit mode
	m_hThinkEdit.__KeyValueFromFloat( "nextthink", -1.0 );
	::SendToConsole("clear_debug_overlays");
	// DrawOverlay(2);
	m_hKeySprite.SetOrigin(MAX_COORD_VEC);

	Msg("\n");
	Msg("Preparing...\n");
	Msg("Keyframe count           : " + m_data_pos_kf.len() + "\n");
	Msg("Resolution               : " + m_flInterpResolution + "\n");
	Msg("Time between 2 keyframes : " + (FRAMETIME/m_flInterpResolution) + "s\n");
	Msg("Angle algorithm          : " + (m_bInterpModeAng ? "default" : "stabilised") + "\n\n");
	PlaySound(SND_BUTTON);

	return::VS.EventQueue.AddEvent( _Compile.__Compile, flShowTime + ::FrameTime(), _Compile );
}

// TODO: Implement consistent speed
function _Compile::__Compile():(FRAMETIME)
{
	// an alternative to inserting would be calculating the future length of
	// the compiled data, and creating that sized empty arrays, and accessing those indices
	// but I'm fine with inserting
	m_data_pos_comp.clear();
	m_data_ang_comp.clear();
	m_data_pos_comp.resize( m_data_pos_kf.len() );
	m_data_ang_comp.resize( m_data_dir_kf.len() );

	RTIME = FRAMETIME;
	_STP = 10;
	if ( m_flInterpResolution <= 0.025 )
	{
		_STP = 2;
		RTIME *= 2;
	};
	_CLI = 0;
	__STP = floor(1.0/m_flInterpResolution);
	_IDX = 0;
	_CMX = clamp( _STP, 0, __STP );

	m_nDrawResolution = __STP.tointeger() / 10;
	m_nDrawResolution = max( m_nDrawResolution, 1 );

	Msg("Compiling (1/3) ");
	return::VS.EventQueue.AddEvent( __SplineOrigin, RTIME, this );
}

function _Compile::__SplineOrigin():(s_aStrLoading)
{
	if ( !(_IDX % 25) )
		Msg(".");

	s_nIdxLoading %= 0x1F;
	Hint( s_aStrLoading[++s_nIdxLoading] );

	local Spline = Catmull_Rom_Spline,
	      kf = m_data_pos_kf,
	      len = kf.len()-3,
	      comp = m_data_pos_comp,
	      Vector = ::Vector;

	for ( local i,j = _IDX, f = m_flInterpResolution * _IDX; j < _CMX; ++j, f += m_flInterpResolution )
		for ( i = 0; i < len; ++i )
			comp.insert((j+2)+(i*(j+2)),Spline(kf[i],kf[i+1],kf[i+2],kf[i+3],f,Vector()));

	_IDX += _STP;
	_CMX = ::clamp( _CMX + _STP, 0, __STP );

	// complete
	if ( _IDX >= _CMX )
	{
		Msg("\n");
		m_data_pos_comp.pop();
		m_data_pos_comp.pop();
		m_data_pos_comp.remove(0);

		// next process
		_IDX = 0;
		_CMX = ::clamp( _STP, 0, __STP );

		Msg("Compiling (2/3) ");
		return __SplineAngles();
	};

	return::VS.EventQueue.AddEvent( __SplineOrigin, RTIME, this );
}

function _Compile::__SplineAngles():(s_aStrLoading)
{
	if ( !(_IDX % 25) )
		Msg(".");

	s_nIdxLoading %= 0x1F;
	Hint( s_aStrLoading[++s_nIdxLoading] );

	if ( m_bInterpModeAng )
	{
		local Norm = QAngleNormalize,
		      ToQAngle = QuaternionAngles,
		      Spline = Catmull_Rom_SplineQ,
		      kf = m_data_quat_kf,
		      len = kf.len()-3,
		      comp = m_data_ang_comp,
		      Vector = ::Vector,
		      Quaternion = ::Quaternion;

		for ( local i,j = _IDX, f = m_flInterpResolution * _IDX; j < _CMX; ++j, f += m_flInterpResolution )
			for ( i = 0; i < len; ++i )
				comp.insert((j+2)+(i*(j+2)),Norm(ToQAngle(Spline(kf[i],kf[i+1],kf[i+2],kf[i+3],f,Quaternion()),Vector())));
	}
	else
	{
		local Norm = QAngleNormalize,
		      ToQAngle = VectorAngles,
		      Spline = Catmull_Rom_Spline,
		      kf = m_data_dir_kf,
		      len = kf.len()-3,
		      comp = m_data_ang_comp,
		      Vector = ::Vector;

		for ( local i,j = _IDX, f = m_flInterpResolution * _IDX; j < _CMX; ++j, f += m_flInterpResolution )
			for ( i = 0; i < len; ++i )
				comp.insert((j+2)+(i*(j+2)),Norm(ToQAngle(Spline(kf[i],kf[i+1],kf[i+2],kf[i+3],f,Vector()))));
	};

	_IDX += _STP;
	_CMX = ::clamp( _CMX + _STP, 0, __STP );

	// complete
	if ( _IDX >= _CMX )
	{
		Msg("\n");
		m_data_ang_comp.pop();
		m_data_ang_comp.pop();
		m_data_ang_comp.remove(0);

		// next process
		_IDX = 0;
		_CMX = ::clamp( _STP, 0, __STP );

		Msg("Compiling (3/3) ");
		return __Clear();
	};

	return::VS.EventQueue.AddEvent( __SplineAngles, RTIME, this );
}

function _Compile::__Clear():(s_aStrLoading)
{
	if ( !(_CLI % 175) )
		Msg(".");

	if ( !(_CLI % 50) )
	{
		s_nIdxLoading %= 0x1F;
		Hint( s_aStrLoading[++s_nIdxLoading] );
	};

	// don't do this because a large data may cause issues. delay recursion instead
	// for ( local i = m_data_pos_comp.len(); i >= _CLI; --i )
	for ( local i = _CLI; i < m_data_pos_comp.len(); ++i )
		if ( m_data_pos_comp[i] == null )
		{
			m_data_pos_comp.remove(i);
			m_data_ang_comp.remove(i);
			_CLI = i;

			return::VS.EventQueue.AddEvent( __Clear, RTIME, this );
		};

	return::VS.EventQueue.AddEvent( function()
	{
		::Msg(".");
		__CompileFOV();
		::VS.EventQueue.AddEvent( __Finish, RTIME, this );

	}, RTIME, this );
}

function _Compile::__Finish():(FRAMETIME)
{
	RTIME = null;
	_CLI = null;
	_STP = null;
	_IDX = null;
	_CMX = null;

	// complete
	m_bCompiling = false;
	m_hThinkEdit.__KeyValueFromFloat( "nextthink", m_bInEditMode ? 1.0 : -1.0 );
	// DrawOverlay( m_bInEditMode ? 1 : 0 );
	Msg("\n\n\n");
	Msg("Compiled keyframes: " + m_data_pos_comp.len() * FRAMETIME + " seconds\n\n");
	Msg("* Play the compiled data  kf_play\n");
	Msg("* Toggle edit mode        kf_edit\n");
	Msg("* Save the compiled data  kf_save\n");
	Msg("* Save the keyframes      kf_savekeys\n\n");
	Hint("Compilation complete!");
	PlaySound(SND_BUTTON);
}

function _Compile::__CompileFOV():(FRAMETIME)
{
	local _f = m_data_fov_kf;

	if ( !_f.len() )
	{
		m_data_fov_comp.clear();
		return;
	};

	_f.sort(sort);

	// FOV data at keyframe 0 is invalid
	if ( _f[0][0] == 0 ) _f.remove(0);

	if ( !_f.len() ) return;

	// if keyframe 1 doesn't have an FOV value, set to 90
	if ( _f[0][0] != 1 ) _f.insert(0,[1,90,0]);

	m_data_fov_comp.clear();
	m_data_fov_comp.resize(_f.len()-1);

	local i  = -1,
	      l  = _f.len()-1;
	local t  = FRAMETIME/m_flInterpResolution;
	local _v = m_data_fov_comp;

	while( l>++i )
	{
		local v = _f[i],
		      c = _f[i+1];

		local d = (c[0]-v[0]) * t;

		_v[i] = [ (v[0]-1)*__STP, c[1], d ];
	}

	// keyframe 1
	if ( _f[0][0] == 1 )
		_v.insert(0,[-__STP,_f[0][1],0]);

	// to be safe
	// this shouldn't be necessary
	_v.sort(sort);
}

//--------------------------------------------------------------

// kf_save_precise
function ToggleSaveMode()
{
	m_bSavePrecise = !m_bSavePrecise;

	if ( m_bSavePrecise )
	{
		Msg("Toggled do save precise\n");
	}
	else
	{
		Msg("Toggled do NOT save precise\n");
	};
}

// (0)kf_save, (1)kf_savekeys
function Save( i = 0 ) : ( szMapName )
{
	if ( m_bCompiling )
		return MsgFail("Cannot save while compiling!");

	if ( !i )
	{
		if ( !m_data_pos_comp.len() )
			return MsgFail("No compiled data found.");
	}
	else
	{
		if ( !m_data_pos_kf.len() )
			return MsgFail("No keyframes found.");
	};

	// DrawOverlay(2);

	_Save.m_iSaveType = i;
	_Save.LOG = ::VS.Log.L.weakref();

	::VS.Log.Clear();
	::VS.Log.file_prefix = "scripts/vscripts/kf_data";
	::VS.Log.enabled = true;
	::VS.Log.export = true;
	::VS.Log.filter = "L ";

	_Save.LOG.append( "l" + ( m_iSaveType ? "k" : "" ) + "_" + szMapName + " <-{pos=[" );

	_Save.data_pos_save = m_iSaveType ? m_data_pos_kf.weakref() : m_data_pos_comp.weakref();
	_Save.data_ang_save = m_iSaveType ? m_data_dir_kf.weakref() : m_data_ang_comp.weakref();

	_Save._LIM = _Save.data_pos_save.len();
	_Save._STP = 1450;
	_Save._IDX = 0;
	_Save._CMX = ::clamp( _Save._STP, 0, _Save._LIM );

	local f = ::format;
	_Save.ToString = m_bSavePrecise ?
		function(v):(f)
		{
			return "w" in v ?
				f("Q(%.9f,%.9f,%.9f,%.9f)",v.x,v.y,v.z,v.w):
				f("V(%.9f,%.9f,%.9f)",v.x,v.y,v.z);
		}
	:
		function(v):(f)
		{
			return "w" in v ?
				"Q(" + v.x + "," + v.y + "," + v.z + "," + v.w + ")":
				"V(" + v.x + "," + v.y + "," + v.z + ")";
		};

	return _Save.__pos();
}

// save run
function _Save::__Finish()
{
	// FIXME
	::VS.IsDedicatedServer = function() return false;

	local file = ::VS.Log.Run();
	Msg( ( m_iSaveType ? "Keyframe" : "Path" ) + " data is exported: /csgo/" + file + ".log\n\n" );

	LOG = null;
	data_pos_save = null;
	data_ang_save = null;
	_LIM = null;
	_STP = null;
	_IDX = null;
	_CMX = null;

	::PrecacheScriptSound("Survival.TabletUpgradeSuccess");
	PlaySound("Survival.TabletUpgradeSuccess");

	// DrawOverlay(m_bInEditMode?1:0);
}

// save pos
function _Save::__pos():(FRAMETIME)
{
	for ( local i = _IDX; i < _CMX; i++ )
		LOG.append( ToString(data_pos_save[i]) );

	_IDX += _STP;
	_CMX = ::clamp( _CMX + _STP, 0, _LIM );

	if ( _IDX >= _CMX )
	{
		LOG.append("]ang=[");
		_IDX = 0;
		_CMX = ::clamp(_STP, 0, _LIM );
		return __ang();
	};

	return::VS.EventQueue.AddEvent( __pos, FRAMETIME, this );
}

// save ang, quat, fov
function _Save::__ang():(FRAMETIME)
{
	for ( local i = _IDX; i < _CMX; i++ )
		LOG.append( ToString(data_ang_save[i]) );

	_IDX += _STP;
	_CMX = ::clamp( _CMX + _STP, 0, _LIM );

	if ( _IDX >= _CMX )
	{
		LOG.pop();
		LOG.append( ToString(data_ang_save[data_ang_save.len()-1]) + "]" );

		local kf;

		// saving keys?
		if ( m_iSaveType )
		{
			local l = m_data_quat_kf.len();

			LOG.append("quat=[");

			for ( local i = 0; i < l; i++ )
				LOG.append( ToString(m_data_quat_kf[i]) );

			LOG.append("]");

			kf = m_data_fov_kf;
		}
		else
		{
			kf = m_data_fov_comp;
		};

		// save fov
		if ( kf.len() )
		{
			LOG.append("fov=[");

			foreach( a in kf )
			{
				LOG.append("[");

				foreach( v in a )
				{
					LOG.append(v);
					LOG.append(",");
				}

				LOG.pop();
				LOG.append("]");
				LOG.append(",");
			}

			LOG.pop();
			LOG.append("]");
		};

		LOG.append("}\n");

		return __Finish();
	};

	return::VS.EventQueue.AddEvent( __ang, FRAMETIME, this );
}

VS.OnTimer( m_hThinkSet, function()
{
	cam.SetOrigin(pos[idx]);
	local a = ang[idx];
	cam.SetAngles(a.x,a.y,a.z);

	foreach( x in fov ) if ( x[0] == idx )
	{
		cam.SetFov(x[1],x[2]);
		break;
	};

	if ( lim <=++ idx )
		::_KF_.Stop();
},null,true );

// kf_play
function Play()
{
	if ( m_bCompiling )
		return MsgFail("Cannot start playback while compiling!");

	if ( m_bPlaybackPending )
		return MsgFail("Playback has not started yet!");

	if ( m_bInPlayback )
		return MsgFail("Playback is already running.");

	// unsee
	if ( m_bSeeing )
		SeeKeyframe(1);

	if ( !m_data_pos_comp.len() )
		return MsgFail("No compiled data found.");

	if ( m_data_pos_comp.len() != m_data_ang_comp.len() )
		return Error("Corrupted data! [" + m_data_pos_comp.len() + "," + m_data_ang_comp.len() + "]");

	if ( ::developer() > 1 )
	{
		Msg("Setting developer level to 1\n");
		::SendToConsole("developer 1");
	};

	local s = m_hThinkSet.GetScriptScope();
	s.lim = s.pos.len();
	s.idx = 0;

	// initiate cam
	if ( s.fov.len() )
		if ( s.fov[0][0] == -__STP )
			m_hCam.SetFov(s.fov[0][1],0);;

	m_hCam.SetOrigin( s.pos[0] );
	SetAngles( s.ang[0] );
	::EntFireByHandle( m_hCam, "Enable", "", 0, ::HPlayer );
	::EntFireByHandle( m_hThinkSet, "Disable" );

	MsgHint("Starting in 3...");
	PlaySound("UI.CounterBeep");

	::VS.EventQueue.AddEvent( MsgHint,   1.0, [this, "Starting in 2..."] );
	::VS.EventQueue.AddEvent( PlaySound, 1.0, [this, "UI.CounterBeep"]   );

	::VS.EventQueue.AddEvent( MsgHint,   2.0, [this, "Starting in 1..."] );
	::VS.EventQueue.AddEvent( PlaySound, 2.0, [this, "UI.CounterBeep"]   );

	::HPlayer.SetHealth(1337);
	::VS.HideHudHint( m_hHudHint, ::HPlayer, 3.0 );

	m_bPlaybackPending = true;
	::VS.EventQueue.AddEvent( Play_, 3.0 );
}

function Play_()
{
	m_bPlaybackPending = false;
	m_bInPlayback = true;
	Msg("Playback has started...\n\n");
	::EntFireByHandle( m_hThinkSet, "Enable" );
}

// kf_stop
function Stop():(FRAMETIME)
{
	if ( !m_bInPlayback )
		return MsgFail("Playback is not running.");

	m_bInPlayback = false;

	::EntFireByHandle( m_hCam, "Disable", "", 0, ::HPlayer );
	::EntFireByHandle( m_hThinkSet, "Disable" );

	m_hCam.SetFov(0,0);

	Msg("Playback has ended. ( " + m_data_pos_comp.len() * FRAMETIME + " seconds )\n");
	PlaySound("UI.RankDown");
}

//--------------------------------------------------------------

function SetInterpResolution(f):(FRAMETIME)
{
	if ( m_bCompiling )
		return MsgFail("Cannot change resolution while compiling!");

	f = f.tofloat();

	if ( f < 0.001 || f > 0.5 )
		return MsgFail("Input out of range [0.001, 0.5]");

	m_flInterpResolution = f;
	__STP = floor(1.0/m_flInterpResolution);
	Msg("Interpolation resolution set to " + m_flInterpResolution + "\n");
	Msg("Time between 2 keyframes: " + (FRAMETIME/m_flInterpResolution) + " second(s)\n");
	PlaySound(SND_BUTTON);
}

function SetFOV(x)
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!");

	if ( !m_data_pos_kf.len() )
		return MsgFail("No keyframes found.");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to add new FOV data.");

	PlaySound(SND_BUTTON);

	x = x.tofloat();

	// refresh
	if ( m_bSeeing )
		m_hCam.SetFov(x,0.25);

	local q = [ m_nCurrKeyframe, x, 0 ];

	foreach( i,v in m_data_fov_kf ) if ( v[0] == m_nCurrKeyframe )
	{
		m_data_fov_kf[i] = q;
		break;
	};

	__CompileFOV();

	MsgHint("Set keyframe #" + m_nCurrKeyframe + " FOV to " + x);
}

function SetRoll(v)
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to use camera roll.");

	v = ::VS.AngleNormalize( v.tofloat() );

	local a = QuaternionAngles( m_data_quat_kf[m_nCurrKeyframe] );

	a.z = v;

	m_data_quat_kf[m_nCurrKeyframe] = ::VS.AngleQuaternion( a,::Quaternion() );

	// refresh
	if ( m_bSeeing )
	{
		if ( m_nSelectedKeyframe == -1 )
			return Error("[ERROR] Assertion failed. Seeing while no keyframe is selected.");

		SetAngles( QuaternionAngles( m_data_quat_kf[m_nSelectedKeyframe] ) );
	};

	MsgHint("Set keyframe #" + m_nCurrKeyframe + " roll to " + v);
	PlaySound(SND_BUTTON);
}

function Trim( flInputLen, bDirection = 1 ) : ( FRAMETIME )
{
	if ( m_bCompiling )
		return MsgFail("Cannot trim while compiling!");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot trim while in playback!");

	if ( !m_data_pos_comp.len() )
		return MsgFail("No compiled data found.");

	flInputLen = max( 0, flInputLen.tofloat() );

	local flCurrLen = m_data_pos_comp.len() * FRAMETIME;

	if ( flInputLen > flCurrLen )
		return MsgFail("Trim value larger than current length!");

	local nFramesToRemove = ( m_data_pos_comp.len() - ( flInputLen / FRAMETIME ) ).tointeger();
	if ( nFramesToRemove <= 0 )
		return MsgFail("No data to trim.");

	m_bTrimDirection = !!bDirection;

	if ( m_bTrimDirection )
	{
		for ( local i = nFramesToRemove; i--; )
		{
			m_data_last_trim_pos.append( m_data_pos_comp.pop() );
			m_data_last_trim_ang.append( m_data_ang_comp.pop() );
		}

		m_data_last_trim_pos.reverse();
		m_data_last_trim_ang.reverse();
	}
	else
	{
		for ( local i = nFramesToRemove; i--; )
		{
			m_data_last_trim_pos.append( m_data_pos_comp.remove(0) );
			m_data_last_trim_ang.append( m_data_ang_comp.remove(0) );
		}
	};

	Msg(format( "Trimmed: %f -> %f\n", flCurrLen, m_data_pos_comp.len()*FRAMETIME ));
}

function UndoLastTrim() : ( FRAMETIME )
{
	if ( m_bCompiling )
		return MsgFail("Cannot undo trim while compiling!");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot undo trim while in playback!");

	if ( !m_data_last_trim_pos.len() )
		return MsgFail("No trimmed data found.");

	local flCurrLen = m_data_pos_comp.len() * FRAMETIME;

	if ( m_bTrimDirection )
	{
		for ( local i = 0; i < m_data_last_trim_pos.len(); ++i )
		{
			m_data_pos_comp.append( m_data_last_trim_pos[i] );
			m_data_ang_comp.append( m_data_last_trim_ang[i] );
		}
	}
	else
	{
		for ( local i = 0; i < m_data_last_trim_pos.len(); ++i )
		{
			m_data_pos_comp.insert( i, m_data_last_trim_pos[i] );
			m_data_ang_comp.insert( i, m_data_last_trim_ang[i] );
		}
	};

	m_data_last_trim_pos.clear();
	m_data_last_trim_ang.clear();

	Msg(format( "Undone trim: %f -> %f\n", flCurrLen, m_data_pos_comp.len()*FRAMETIME ));
}

__CompileFOV <- _Compile.__CompileFOV.bindenv(_Compile);

// global bindings for easy use with 'script kf_XX()'
::kf_roll <- SetRoll.bindenv(this);
::kf_fov <- SetFOV.bindenv(this);
::kf_res <- SetInterpResolution.bindenv(this);
::kf_load <- LoadData.bindenv(this);
::kf_trim <- Trim.bindenv(this);

//--------------------------------------------------------------

function PostSpawn()
{
	if ( ::HPlayer.GetTeam() != 2 && ::HPlayer.GetTeam() != 3 )
		::HPlayer.SetTeam(2);

	PlaySound("Player.DrownStart");
	::HPlayer.SetHealth(1337);

	// key listener
	::EntFireByHandle( m_hListener, "Activate", "", 0, ::HPlayer );

	ListenMouse(1);

	for ( local i = 18; i--; ) ::Chat(" ");
	::Chat(::txt.blue+" --------------------------------");
	::Chat("");
	::Chat(::txt.lightgreen + "[Keyframes Script v"+_VER_+"]");
	::Chat(::txt.white+"kf_cmd" + ::txt.orange + " : Print all commands");
	::Chat("");
	::Chat(::txt.blue+" --------------------------------");

	// print after Steamworks Msg
	if ( ::GetDeveloperLevel() > 0 )
	{
		::VS.EventQueue.AddEvent( SendToConsole, 0.75, [null, "clear;script _KF_.WelcomeMsg()"] );
	}
	else
	{
		WelcomeMsg();
	};

	SendToConsole("drop;drop;drop;drop;drop");

	delete PostSpawn;
}

function WelcomeMsg()
{
	Msg("\n");
	PrintCmd();

	if ( !VS.IsInteger( 128.0 / VS.GetTickrate() ) )
	{
		Msg(format( "[!] Invalid tickrate (%.1f)! Only 128 and 64 tickrates are supported.\n",VS.GetTickrate() ));
		Chat(format( "%s[!] %sInvalid tickrate ( %s%.1f%s )! Only 128 and 64 tickrates are supported.", txt.red, txt.white, txt.yellow, VS.GetTickrate(), txt.white ));
	};

	delete WelcomeMsg;
}

// kf_cmd
function PrintCmd()
{
	Msg("\n");
	Msg("   [v"+_VER_+"]     github.com/samisalreadytaken/keyframes\n");
	Msg("\n");
	Msg("kf_add                : Add new keyframe\n");
	Msg("kf_remove             : Remove the selected keyframe\n");
	Msg("kf_remove_undo        : Undo last remove action\n");
	Msg("kf_removefov          : Remove the FOV data from the selected keyframe\n");
	Msg("kf_clear              : Remove all keyframes\n");
	Msg("kf_insert             : Insert new keyframe after the selected keyframe\n");
	Msg("kf_replace            : Replace the selected keyframe\n");
	Msg("kf_replace_undo       : Undo last replace action\n");
	Msg("kf_copy               : Set player pos/ang to the current keyframe\n");
	Msg("                      :\n");
	Msg("kf_compile            : Compile the keyframe data\n");
	Msg("kf_play               : Play the compiled data\n");
	Msg("kf_stop               : Stop playback\n");
	Msg("kf_save               : Save the compiled data\n");
	Msg("kf_savekeys           : Save the keyframe data\n");
	Msg("                      :\n");
	Msg("kf_mode_ang           : Toggle stabilised angles algorithm\n");
	Msg("                      :\n");
	Msg("kf_edit               : Toggle edit mode\n");
	Msg("kf_select             : In edit mode, hold the current selection\n");
	Msg("kf_see                : In edit mode, see the current selection\n");
	Msg("kf_next               : While holding a keyframe, select the next one\n");
	Msg("kf_prev               : While holding a keyframe, select the previous one\n");
	Msg("kf_showkeys           : In edit mode, toggle showing keyframes\n");
	Msg("kf_showpath           : In edit mode, toggle showing the path\n");
	Msg("                      :\n");
	Msg("script kf_fov(val)    : Set FOV data on the selected keyframe\n");
	Msg("script kf_roll(val)   : Set camera roll on the selected keyframe\n");
	Msg("script kf_res(val)    : Set interpolation resolution\n");
	Msg("                      :\n");
	Msg("script kf_load(input) : Load new data from file\n");
	Msg("script kf_trim(val)   : Trim compiled data to specified length\n");
	Msg("kf_trim_undo          : Undo last trim action\n");
	Msg("                      :\n");
	Msg("kf_cmd                : List all commands\n");
	Msg("\n");
	Msg("--- --- --- --- --- ---\n");
	Msg("\n");
	Msg("MOUSE1                : kf_add\n");
	Msg("MOUSE2                : kf_remove\n");
	Msg("E                     : kf_see\n");
	Msg("A / D                 : (In see mode) Set camera roll\n");
	Msg("W / S                 : (In see mode) Set camera FOV\n");
	Msg("MOUSE1                : (In see mode) kf_next\n");
	Msg("MOUSE2                : (In see mode) kf_prev\n");
	Msg("\n");
}

}.call(_KF_);
