//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//- v1.2.4 --------------------------------------------------------------
IncludeScript("vs_library");
IncludeScript("vs_library/vs_math2");
IncludeScript("vs_library/vs_interp");
IncludeScript("vs_library/vs_collision");

if ( !("_KF_" in getroottable()) )
	::_KF_ <- { version = "1.2.4" };;

local _ = function(){

SendToConsole("alias kf_add\"script _KF_.AddKeyframe()\"");
SendToConsole("alias kf_remove\"script _KF_.RemoveKeyframe()\"");
SendToConsole("alias kf_clear\"script _KF_.RemoveAllKeyframes()\"");
SendToConsole("alias kf_insert\"script _KF_.InsertKeyframe()\"");
SendToConsole("alias kf_copy\"script _KF_.CopyKeyframe()\"");
SendToConsole("alias kf_replace\"script _KF_.ReplaceKeyframe()\"");
SendToConsole("alias kf_removefov\"script _KF_.RemoveFOV()\"");
SendToConsole("alias kf_undo\"script _KF_.Undo()\"");
SendToConsole("alias kf_redo\"script _KF_.Redo()\"");
SendToConsole("alias kf_undo_history\"script _KF_.PrintUndoStack()\"");
SendToConsole("alias kf_compile\"script _KF_.Compile()\"");
SendToConsole("alias kf_smooth_angles\"script _KF_.SmoothAngles()\"");
SendToConsole("alias kf_smooth_angles_exp\"script _KF_.SmoothAngles(1)\"");
SendToConsole("alias kf_smooth_origin\"script _KF_.SmoothOrigin()\"");
SendToConsole("alias kf_play\"script _KF_.Play()\"");
SendToConsole("alias kf_play_loop\"script _KF_.Play(2)\"");
SendToConsole("alias kf_preview\"script _KF_.Play(1)\"");
SendToConsole("alias kf_stop\"script _KF_.Stop()\"");
SendToConsole("alias kf_savepath\"script _KF_.Save(KF_DATA_TYPE_PATH)\"");
SendToConsole("alias kf_savekeys\"script _KF_.Save(KF_DATA_TYPE_KEYFRAMES)\"");
SendToConsole("alias kf_mode_angles\"script _KF_.SetAngleInterp()\"");
SendToConsole("alias kf_mode_origin\"script _KF_.SetOriginInterp()\"");
SendToConsole("alias kf_auto_fill_boundaries\"script _KF_.SetAutoFillBoundaries()\"");
SendToConsole("alias kf_edit\"script _KF_.SetEditMode()\"");
SendToConsole("alias kf_translate\"script _KF_.ShowGizmo()\"");
SendToConsole("alias kf_select_path\"script _KF_.SelectPath()\"");
SendToConsole("alias kf_see\"script _KF_.SeeKeyframe()\"");
SendToConsole("alias kf_next\"script _KF_.NextKeyframe()\"");
SendToConsole("alias kf_prev\"script _KF_.PrevKeyframe()\"");
SendToConsole("alias kf_showkeys\"script _KF_.ShowToggle(0)\"");
SendToConsole("alias kf_showpath\"script _KF_.ShowToggle(1)\"");
SendToConsole("alias kf_trim_undo\"script _KF_.UndoTrim()\"");
SendToConsole("alias kf_cmd\"script _KF_.PrintCmd()\"");
SendToConsole("alias kf_loadfile\"script _KF_.LoadFile()\"");

// deprecated
SendToConsole("alias kf_select\"script _KF_.SelectKeyframe()\"");
SendToConsole("alias kf_save\"script _KF_.Save()\"");
SendToConsole("alias kf_load\"script _KF_.LoadFileError()\"");
_VER_ <- version;

//--------------------------------------------------------------

SendToConsole("clear;script _KF_.PostSpawn()");

VS.GetLocalPlayer();

const KF_FLT_EPS = 1.e-3;

local vec3_origin = Vector();
local g_FrameTime = 0.015625;
local s_flDisplayTime = FrameTime() * 6;
local MAX_COORD_VEC = Vector(MAX_COORD_FLOAT-1,MAX_COORD_FLOAT-1,MAX_COORD_FLOAT-1);
local HELPER_EF =
{
	ON  = (1<<4)|(1<<6)|(1<<3)|0,
	OFF = (1<<4)|(1<<6)|(1<<3)|(1<<5)
}

if ( !("_Process" in this) )
{
	SND_BUTTON <- "UIPanorama.container_countdown";
	SND_EXPORT_SUCCESS <- "Survival.TabletUpgradeSuccess";

	_Process <- delegate this : {}

	_Save <- delegate this :
	{
		Add = VS.Log.Add.weakref()
	}

	_Load <- delegate this : {}

	m_KeyFrames <- [];
	m_PathData <- [];
	m_TrimData <- null;
	m_pSaveData <- null;
	m_pLoadData <- null;
	m_pLoadInput <- null;

	m_nSaveType <- 0;
	m_nLoadType <- 0;
	m_nLoadVer <- 0;
	m_bSaveInProgress <- false;

	m_LoadedDatas <- {}
	m_FileBuffer <-
	{
		// for b/w compat
		V = Vector,
		Q = Quaternion
	}

	m_UndoStack <- [];
	m_nUndoLevel <- 0;

	m_bDirty <- false;
	m_bCompiling <- false;
	m_bInPlayback <- false;
	m_bInEditMode <- true;
	m_bPlaybackPending <- false;
	m_bPlaybackLoop <- false;
	m_bTrimDirection <- true;
	m_bSmoothExponential <- false;
	m_pSquadErrors <- null;
	m_AnglesRestore <- null;

	m_Selection <- [0,0];
	m_nCurPathSelection <- 0;
	m_fPathSelection <- 0;

	m_nInterpolatorAngle <- 0;
	m_nInterpolatorOrigin <- 0;
	m_szInterpDescAngle <- null;
	m_szInterpDescOrigin <- null;

	m_bAutoFillBoundaries <- false;
	m_flSampleRate <- 0.01; // KF_INTERP_SAMPLE_RATE_DEFAULT
	m_nSampleCount <- 0;

	m_nMouseOver <- 0;
	m_bGizmoEnabled <- false;
	m_bMouseDown <- false;
	m_bMouseForceUp <- false;
	m_nTranslation <- 0;
	m_bDuckFixup <- false;

	m_vecLastForwardFrame <- null;
	m_vecCameraOffset <- null;
	m_vecOffset <- null;
	m_vecLastKeyOrigin <- Vector();
	m_vecLastOrigin <- null;
	m_vecLastDeltaOrigin <- null;
	m_vecLastForward <- null;
	m_vecLastUp <- null;
	m_vecLastRight <- null;

	m_nDrawResolution <- 1;
	m_nSelectedKeyframe <- -1;
	m_nCurKeyframe <- 0;
	m_nPlaybackIdx <- -1;
	m_nPlaybackTarget <- -1;

	m_bPreview <- false;
	m_flPreviewFrac <- 0.0;

	m_bShowPath <- true;
	m_bShowKeys <- true;
	m_bSeeing <- false;
	m_bReplaceOnClick <- false;
	m_bInsertOnClick <- false;

	in_roll_1 <- false;
	in_roll_0 <- false;
	in_fov_1 <- false;
	in_fov_0 <- false;
	m_iFOV <- 90;
	m_vecRollLastAngle <- null;

	m_nAnimKeyframeTime <- 0.0;
	m_nAnimKeyframeIdx <- -1;
	m_nAnimPathIdx <- 0;

	m_pLerpTransform <- null;
	m_flLerpTransformAnim <- null;

	m_pLerpFrustum <- null;
	m_hLerpKeyframe <- null;
	m_flLerpKeyAnim <- null;

	AddEvent <- VS.EventQueue.AddEvent.weakref();
	Msg <- print;
	Fmt <- format;
	clamp <- clamp;
	EntFireByHandle <- EntFireByHandle;
	DrawLine <- DebugDrawLine;
	DrawBox <- DebugDrawBox;
	DrawBoxAnglesFilled <- DebugDrawBoxAngles;
};

if ( !("HPlayerEye" in getroottable()) )
	::HPlayerEye <- VS.CreateMeasure( HPlayer.GetName(), null, true );

if ( !("m_hThinkCam" in this) )
{
	g_szMapName <- split( GetMapName(), "/" ).top();

	player <- HPlayer;
	playerEye <- HPlayerEye;

	m_hThinkCam <- VS.Timer( true, g_FrameTime, null, null, false, true ).weakref();

	m_hThinkEdit <- VS.Timer( true, s_flDisplayTime-FrameTime(), null, null, false, true ).weakref();

	m_hThinkAnim <- VS.Timer( true, 0.5-FrameTime(), null, null, false, true ).weakref();

	m_hThinkKeys <- VS.Timer( true, FrameTime()*2.5, null, null, false, true ).weakref();

	m_hThinkFrame <- null;

	m_hGameText <- VS.CreateEntity("game_text",
	{
		channel = 5,
		color = Vector(255,120,0),
		holdtime = s_flDisplayTime,
		x = 0.475,
		y = 0.5625
	},true).weakref();

	m_hGameText2 <- VS.CreateEntity("game_text",
	{
		channel = 6,
		color = Vector(255,120,0),
		holdtime = s_flDisplayTime,
		x = 0.575,
		y = 0.485
	},true).weakref();

//	m_hGameText3 <- VS.CreateEntity("game_text",
//	{
//		channel = 4,
//		color = Vector(255,120,0),
//		holdtime = s_flDisplayTime,
//		x = 0.575,
//		y = 0.505
//	},true).weakref();

	m_hHudHint <- VS.CreateEntity("env_hudhint",null,true).weakref();

	m_hCam <- VS.CreateEntity("point_viewcontrol",{ spawnflags = 1<<3 }).weakref();

	m_hListener <- VS.CreateEntity("game_ui",{ spawnflags = 1<<7, fieldofview = -1.0 },true).weakref();

	PrecacheModel("keyframes/kf_circle_orange.vmt");

	m_hKeySprite <- VS.CreateEntity("env_sprite",
	{
		rendermode = 8,
		glowproxysize = 64.0, // MAX_GLOW_PROXY_SIZE
		effects = HELPER_EF.ON
	}, true).weakref();

	m_hKeySprite.__KeyValueFromInt( "effects", HELPER_EF.ON );

	m_hKeySprite.SetModel("keyframes/kf_circle_orange.vmt");

//--------------------------------------------------------

	PrecacheScriptSound( SND_EXPORT_SUCCESS );
};


// load materials
DrawLine( vec3_origin, vec3_origin, 0, 0, 0, true, 1 );
DrawBox( vec3_origin, vec3_origin, Vector(1,1,1), 0, 0, 0, 254, 1 );


//--------------------------------------------------------------
//--------------------------------------------------------------


function CameraSetAngles(v) : (m_hCam)
{
	return m_hCam.SetAngles(v.x,v.y,v.z);
}

function CameraSetForward(v) : (m_hCam)
{
	return m_hCam.SetForwardVector(v);
}

function CameraSetOrigin(v) : (m_hCam)
{
	return m_hCam.SetOrigin(v);
}

function CameraSetFov( n, f ) : (m_hCam)
{
	return m_hCam.SetFov( n, f );
}

function CameraSetEnabled( b ) : (m_hCam)
{
	return EntFireByHandle( m_hCam, b ? "Enable" : "Disable", "", 0.0, player );
}

function CameraSetThink( b )
{
	return EntFireByHandle( m_hThinkCam, b ? "Enable" : "Disable" );
}


function PlaySound(s)
{
	return player.EmitSound(s);
}

function Hint(s)
{
	m_hHudHint.__KeyValueFromString( "message", s );
	return EntFireByHandle( m_hHudHint, "ShowHudHint", "", 0.0, player );
}

function HideHudHint( t = 0.0 )
{
	return EntFireByHandle( m_hHudHint, "HideHudHint", "", t, player );
}

function Error(s)
{
	Msg(s);
	PlaySound("Bot.Stuck2");
}

function MsgFail(s)
{
	if ( !m_bCompiling )
	{
		Msg(s);
	}
	else
	{
		Msg("\n(\n\t");
		Msg(s);
		Msg(")");
	};

	// PlaySound("Player.WeaponSelected");
	PlaySound("UIPanorama.buymenu_failure");
}

function MsgHint(s)
{
	Msg(s);
	Hint(s);
}

function ArrayAppend( arr, val )
{
	arr.insert( arr.len(), val );
}


function SetHelperVisible( state ) : (HELPER_EF)
{
	if ( state )
	{
		m_hKeySprite.__KeyValueFromInt( "effects", HELPER_EF.ON );
	}
	else
	{
		m_hKeySprite.__KeyValueFromInt( "effects", HELPER_EF.OFF );
	};
}

function SetHelperOrigin( vec )
{
	m_hKeySprite.SetOrigin( vec );
}

function IsDucking()
{
	return player.GetBoundingMaxs().z != 72.0;
}

function MainViewOrigin()
{
	return player.EyePosition();
}

function MainViewAngles()
{
	return playerEye.GetAngles();
}

function MainViewForward()
{
	return playerEye.GetForwardVector();
}

function MainViewRight()
{
	return playerEye.GetLeftVector();
}

function MainViewUp()
{
	return playerEye.GetUpVector();
}

function CurrentViewOrigin()
{
	if ( m_bSeeing )
	{
		return m_KeyFrames[ m_nCurKeyframe ].origin;
	}
	else if ( m_bInPlayback && !m_bPreview )
	{
		return m_PathData[ m_nPlaybackIdx ].origin;
	}
	else
	{
		return player.EyePosition();
	}
}

function CurrentViewAngles()
{
	if ( m_bSeeing )
	{
		return m_KeyFrames[ m_nCurKeyframe ].angles;
	}
	else if ( m_bInPlayback && !m_bPreview )
	{
		return m_PathData[ m_nPlaybackIdx ].angles;
	}
	else
	{
		return playerEye.GetAngles();
	}
}

::MainViewOrigin	<- MainViewOrigin.bindenv(this);
::MainViewAngles	<- MainViewAngles.bindenv(this);
::MainViewForward	<- MainViewForward.bindenv(this);
::MainViewRight		<- MainViewRight.bindenv(this);
::MainViewUp		<- MainViewUp.bindenv(this);
::CurrentViewOrigin	<- CurrentViewOrigin.bindenv(this);
::CurrentViewAngles	<- CurrentViewAngles.bindenv(this);


class point_t
{
	origin = null;
	angles = null;
	fov = null;
	fov_rate = null;

	function SetOrigin( input )
	{
		origin = input;
	}

	function SetAngles( input )
	{
		angles = input;
	}

	function SetFov( val, rate )
	{
		fov = val;
		fov_rate = rate;
	}
}

class keyframe_t //extends point_t
{
	origin = null;
	angles = null;
	forward = null;
	right = null;
	up = null;
	orientation = null;
	transform = null;
	fov = null;
	_fovx = null;

	constructor()
	{
		transform = matrix3x4_t();
		Init();
	}

	function Init()
	{
		origin = Vector();
		angles = Vector();
		forward = Vector();
		right = Vector();
		up = Vector();
		orientation = Quaternion();
		SetFov( null );
	}

	function SetOrigin( input )
	{
		VS.VectorCopy( input, origin );
		VS.MatrixSetColumn( origin, 3, transform );
	}

	// QAngle
	function SetAngles( input )
	{
		VS.VectorCopy( input, angles );
		VS.AngleMatrix( angles, origin, transform );

		VS.AngleQuaternion( angles, orientation );

		VS.MatrixVectors( transform, forward, right, up );
	}

	// Quaternion
	function SetQuaternion( input )
	{
		VS.VectorCopy( input, orientation ); orientation.w = input.w;
		VS.QuaternionMatrix( orientation, origin, transform );

		VS.MatrixVectors( transform, forward, right, up );

		VS.MatrixAngles( transform, angles );
	}

	// Vector
	function SetForward( input )
	{
		VS.VectorCopy( input, forward );
		VS.VectorVectors( forward, right, up );

		VS.VectorAngles( forward, angles );

		VS.AngleQuaternion( angles, orientation );

		VS.MatrixSetColumn( forward, 0, transform );
		VS.MatrixSetColumn( right * -1, 1, transform );
		VS.MatrixSetColumn( up, 2, transform );
	}

	// from matrix
	function Update()
	{
		VS.MatrixGetColumn( transform, 3, origin );
		VS.MatrixAngles( transform, angles, origin );
		VS.MatrixVectors( transform, forward, right, up );
		VS.AngleQuaternion( angles, orientation );
	}

	function SetFov( val, rate = null )
	{
		if ( !val )
		{
			fov = null;
			_fovx = 90.0;
		}
		else
		{
			fov = val.tointeger();
			_fovx = fov.tofloat();
		};
	}

	function DrawFrustum( r, g, b, time )
	{
		// could just use a model
		return VS.DrawViewFrustum( origin,
			forward,
			right,
			up,
			_fovx,
			1.77778,
			4.0,
			32.0,
			r, g, b, false,
			time
		);
	}

	function Copy( src )
	{
		transform = clone src.transform;

		VS.MatrixGetColumn( transform, 3, origin );
		VS.MatrixVectors( transform, forward, right, up );
		VS.MatrixAngles( transform, angles );
		VS.MatrixQuaternionFast( transform, orientation );

		SetFov( src.fov );
	}

	function _cloned( src )
	{
		Init();
		Copy(src);
	}
}


//--------------------------------------------------------------

// see mode listen WASD
function ListenKeys(i)
{
	if (i)
	{
		ListenMouse(0);

		m_hListener.ConnectOutput("PressedMoveRight","PressedMoveRight");
		m_hListener.ConnectOutput("UnpressedMoveRight","UnpressedMoveRight");
		m_hListener.ConnectOutput("PressedMoveLeft","PressedMoveLeft");
		m_hListener.ConnectOutput("UnpressedMoveLeft","UnpressedMoveLeft");
		m_hListener.ConnectOutput("PressedForward","PressedForward");
		m_hListener.ConnectOutput("UnpressedForward","UnpressedForward");
		m_hListener.ConnectOutput("PressedBack","PressedBack");
		m_hListener.ConnectOutput("UnpressedBack","UnpressedBack");

		m_hListener.SetTeam( player.IsNoclipping().tointeger() );

		// freeze player
		player.__KeyValueFromInt( "movetype", 0 );
	}
	else
	{
		m_hListener.DisconnectOutput("PressedMoveRight","PressedMoveRight");
		m_hListener.DisconnectOutput("UnpressedMoveRight","UnpressedMoveRight");
		m_hListener.DisconnectOutput("PressedMoveLeft","PressedMoveLeft");
		m_hListener.DisconnectOutput("UnpressedMoveLeft","UnpressedMoveLeft");
		m_hListener.DisconnectOutput("PressedForward","PressedForward");
		m_hListener.DisconnectOutput("UnpressedForward","UnpressedForward");
		m_hListener.DisconnectOutput("PressedBack","PressedBack");
		m_hListener.DisconnectOutput("UnpressedBack","UnpressedBack");

		// just enable noclip
		player.__KeyValueFromInt( "movetype", 8 );
	};
}

// default listen MOUSE1, MOUSE2
function ListenMouse(i)
{
	if (i)
	{
		ListenKeys(0);

		VS.AddOutput( m_hListener, "PressedAttack",  OnMouse1Down );
		VS.AddOutput( m_hListener, "PressedAttack2", OnMouse2Down );
		VS.AddOutput( m_hListener, "UnpressedAttack",  OnMouse1Release );
		// VS.AddOutput( m_hListener, "UnpressedAttack2", OnMouse2Release );
	}
	else
	{
		// m_hListener.DisconnectOutput("PressedAttack","PressedAttack");
		// m_hListener.DisconnectOutput("PressedAttack2","PressedAttack2");
		m_hListener.DisconnectOutput("UnpressedAttack","UnpressedAttack");
		// m_hListener.DisconnectOutput("UnpressedAttack2","UnpressedAttack2");
	};
}

VS.AddOutput( m_hListener, "UnpressedAttack2", null );
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

	EntFireByHandle( m_hThinkKeys, "Disable" );
	in_fov_1 = false;
	in_fov_0 = false;
	in_roll_1 = false;
	in_roll_0 = false;

	EntFireByHandle( m_hListener, "Activate", "", 0, player )
}, this );

//--------------------------------------------------------------

local flRollIncr = 2.0;

// Think keys roll
function KEY_ThinkRoll() : (flRollIncr)
{
	if ( in_roll_1 )
	{
		m_vecRollLastAngle.z = clamp( floor( m_vecRollLastAngle.z + flRollIncr ), -180.0, 180.0 );
		CameraSetAngles( m_vecRollLastAngle );
		Hint( "Roll "+m_vecRollLastAngle.z );
	}
	else if ( in_roll_0 )
	{
		m_vecRollLastAngle.z = clamp( floor( m_vecRollLastAngle.z - flRollIncr ), -180.0, 180.0 );
		CameraSetAngles( m_vecRollLastAngle );
		Hint( "Roll "+m_vecRollLastAngle.z );
	};;

	PlaySound("UIPanorama.store_item_rollover");
}

local fFovRate = FrameTime()*6;

// Think keys fov
function KEY_ThinkFOV() : (fFovRate)
{
	if ( in_fov_1 )
	{
		m_iFOV = clamp( m_iFOV - 1, 1, 179 );
		Hint( "FOV "+m_iFOV );
		CameraSetFov( m_iFOV, fFovRate );
	}
	else if ( in_fov_0 )
	{
		m_iFOV = clamp( m_iFOV + 1, 1, 179 );
		Hint( "FOV "+m_iFOV );
		CameraSetFov( m_iFOV, fFovRate );
	};;

	PlaySound("UIPanorama.store_item_rollover");
}

// roll clockwise
function KEY_ROLL_1(i)
{
	if (i)
	{
		if ( !m_bSeeing )
			return MsgFail("You need to be in see mode to use the key controls.\n");

		VS.OnTimer( m_hThinkKeys, KEY_ThinkRoll );
		m_vecRollLastAngle = m_KeyFrames[ m_nCurKeyframe ].angles;

		in_roll_1 = true;
		EntFireByHandle( m_hThinkKeys, "Enable" );
	}
	else
	{
		if ( !m_bSeeing )
			return;

		in_roll_1 = false;
		EntFireByHandle( m_hThinkKeys, "Disable" );

		PushUndo( "roll" );

		// save last set data
		m_KeyFrames[ m_nCurKeyframe ].SetAngles( m_vecRollLastAngle );

		PushRedo( "roll" );

		m_bDirty = true;
	};
}

// roll counter-clockwise
function KEY_ROLL_0(i)
{
	if (i)
	{
		if ( !m_bSeeing )
			return MsgFail("You need to be in see mode to use the key controls.\n");

		VS.OnTimer( m_hThinkKeys, KEY_ThinkRoll );
		m_vecRollLastAngle = m_KeyFrames[ m_nCurKeyframe ].angles;

		in_roll_0 = true;
		EntFireByHandle( m_hThinkKeys, "Enable" );
	}
	else
	{
		if ( !m_bSeeing )
			return;

		in_roll_0 = false;
		EntFireByHandle( m_hThinkKeys, "Disable" );

		PushUndo( "roll" );

		// save last set data
		m_KeyFrames[ m_nCurKeyframe ].SetAngles( m_vecRollLastAngle );

		PushRedo( "roll" );

		m_bDirty = true;
	};
}

// fov in
function KEY_FOV_1(i)
{
	if (i)
	{
		if ( !m_bSeeing )
			return MsgFail("You need to be in see mode to use the key controls.\n");

		VS.OnTimer( m_hThinkKeys, KEY_ThinkFOV );
		m_iFOV = 90;
		in_fov_1 = true;
		EntFireByHandle( m_hThinkKeys, "Enable" );

		local key = m_KeyFrames[ m_nCurKeyframe ];
		if ( key.fov )
		{
			// get current fov value
			m_iFOV = key.fov;
		};
	}
	else
	{
		if ( !m_bSeeing )
			return;

		in_fov_1 = false;
		EntFireByHandle( m_hThinkKeys, "Disable" );

		local key = m_KeyFrames[ m_nCurKeyframe ];
		key.SetFov( m_iFOV );

		m_bDirty = true;
	};
}

// fov out
function KEY_FOV_0(i)
{
	if (i)
	{
		if ( !m_bSeeing )
			return MsgFail("You need to be in see mode to use the key controls.\n");

		VS.OnTimer( m_hThinkKeys, KEY_ThinkFOV );
		m_iFOV = 90;
		in_fov_0 = true;
		EntFireByHandle( m_hThinkKeys, "Enable" );

		local key = m_KeyFrames[ m_nCurKeyframe ];
		if ( key.fov )
		{
			// get current fov value
			m_iFOV = key.fov;
		};
	}
	else
	{
		if ( !m_bSeeing )
			return;

		in_fov_0 = false;
		EntFireByHandle( m_hThinkKeys, "Disable" );

		local key = m_KeyFrames[ m_nCurKeyframe ];
		key.SetFov( m_iFOV );

		m_bDirty = true;
	};
}

//--------------------------------------------------------------
//--------------------------------------------------------------

function OnMouse1Down()
{
	if ( m_bReplaceOnClick )
	{
		ReplaceKeyframe();
		ToggleFrameThink( false );
		return;
	};

	if ( m_bInsertOnClick )
	{
		InsertKeyframe();
		ToggleFrameThink( false );
		return;
	};

	if ( m_fPathSelection != 0 )
		return SelectPath();

	if ( m_bSeeing )
		return NextKeyframe();

	if ( m_bGizmoEnabled )
		return GizmoOnMouseDown();

	return AddKeyframe();
}

function OnMouse1Release()
{
	if ( m_bGizmoEnabled )
		return GizmoOnMouseRelease();
}

function OnMouse2Down()
{
	if ( m_bReplaceOnClick || m_bInsertOnClick )
	{
		m_bReplaceOnClick = false;
		m_bInsertOnClick = false;
		ToggleFrameThink( false );
		m_nSelectedKeyframe = -1;
		MsgHint("Cancelled\n");
		return;
	};

	if ( m_fPathSelection != 0 )
	{
		m_Selection[0] = m_Selection[1] = 0;
		m_fPathSelection = 0;
		MsgHint( "Cleared path selection.\n" );
		return;
	};

	if ( m_bSeeing )
		return PrevKeyframe();

	if ( m_bGizmoEnabled )
		return;

	return RemoveKeyframe();
}

//--------------------------------------------------------------
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
		EntFireByHandle( m_hThinkAnim, m_bShowKeys ? "Enable" : "Disable" );
		Msg( m_bShowKeys ? "Showing keyframes\n" : "Hiding keyframes\n" );
	};

	SendToConsole("clear_debug_overlays");
	PlaySound(SND_BUTTON);
}

// kf_edit
function SetEditMode( state = null, msg = true )
{
	if ( m_bCompiling )
		return MsgFail(Fmt( "Cannot %s edit mode while compiling!\n", (m_bInEditMode?"disable":"enable") ));

	if ( state == null )
		state = !m_bInEditMode;

	m_bInEditMode = !!state;

	// on
	if ( m_bInEditMode )
	{
		if ( developer() > 1 )
		{
			Msg("Setting developer level to 1\n");
			SendToConsole("developer 1");
		};

		SendToConsole( "cl_drawhud 1" );
		SetHelperVisible( true );
		EntFireByHandle( m_hThinkEdit, "Enable" );
		EntFireByHandle( m_hThinkAnim, "Enable" );

		if (msg)
			Msg("Edit mode enabled.\n");
	}
	// off
	else
	{
		// unsee
		if ( m_bSeeing )
			SeeKeyframe(1);

		SetHelperVisible( false );
		EntFireByHandle( m_hThinkEdit, "Disable" );
		EntFireByHandle( m_hThinkAnim, "Disable" );
		EntFireByHandle( m_hGameText2, "SetText", "", 0, player );

		if (msg)
			Msg("Edit mode disabled.\n");
	};

	SendToConsole("clear_debug_overlays");

	if (msg)
		PlaySound(SND_BUTTON);
}

function SetEditModeTemp( state )
{
	if ( state )
	{
		m_hThinkEdit.__KeyValueFromFloat( "nextthink", 1 );
		m_hThinkAnim.__KeyValueFromFloat( "nextthink", 1 );
	}
	else
	{
		m_hThinkEdit.__KeyValueFromFloat( "nextthink", -1 );
		m_hThinkAnim.__KeyValueFromFloat( "nextthink", -1 );
	}
}

// kf_select_path
function SelectPath()
{
	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to select.\n");

	if ( m_fPathSelection == 0 )
	{
		MsgHint( "Select path begin...\n" );
		m_fPathSelection = 1;
	}
	else if ( m_fPathSelection == 1 )
	{
		m_Selection[0] = m_nCurPathSelection;

		MsgHint( "Select path end...\n" );
		m_fPathSelection = 2;
	}
	else if ( m_fPathSelection == 2 )
	{
		m_Selection[1] = m_nCurPathSelection;

		// normalise
		if ( m_Selection[0] > m_Selection[1] )
		{
			local t = m_Selection[1];
			m_Selection[1] = m_Selection[0];
			m_Selection[0] = t;
		};

		if ( m_Selection[0] == 0 )
		{
			m_Selection[0] = 1;
		};

		if ( m_Selection[1] == 0 )
		{
			m_Selection[1] = 2;
		};

		if ( m_Selection[0] == m_Selection[1] )
		{
			m_Selection[1]++;
		};

		MsgHint( "Selected path" );
		Msg(Fmt( " [%d -> %d]\n", m_Selection[0], m_Selection[1] ));
		m_fPathSelection = 0;
	};;;

	PlaySound(SND_BUTTON)
}

// kf_select
// TODO: remove - this doesn't have a purpose now
function SelectKeyframe( bShowMsg = 1 )
{
	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to select.\n");

	// ( m_nSelectedKeyframe != m_nCurKeyframe )
	if ( m_nSelectedKeyframe == -1 )
	{
		m_nSelectedKeyframe = m_nCurKeyframe;

		if ( bShowMsg )
			MsgHint(Fmt( "Selected keyframe #%d\n", m_nSelectedKeyframe ));
	}
	else
	{
		if ( bShowMsg )
			MsgHint(Fmt( "Unselected keyframe #%d\n", m_nSelectedKeyframe ));

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
		return MsgFail("You need to have a keyframe selected to use kf_next.\n");

	local t = (m_nSelectedKeyframe+1) % m_KeyFrames.len();
	local b = m_bSeeing;		// hold current value

	// unsee silently
	if (b) SeeKeyframe(1,0);

	m_nSelectedKeyframe = t;
	m_nCurKeyframe = t;

	// then see again
	if (b) SeeKeyframe(0,0);
}

// kf_prev
function PrevKeyframe()
{
	if ( m_nSelectedKeyframe == -1 )
		return MsgFail("You need to have a keyframe selected to use kf_prev.\n");

	local n = m_nSelectedKeyframe-1;

	if ( n < 0 )
		n += m_KeyFrames.len();

	local t = n % m_KeyFrames.len();
	local b = m_bSeeing;		// hold current value

	// unsee silently
	if (b) SeeKeyframe(1,0);

	m_nSelectedKeyframe = t;
	m_nCurKeyframe = t;

	// then see again
	if (b) SeeKeyframe(0,0);
}

// kf_see
// TODO: a better method?
function SeeKeyframe( bUnsafeUnsee = 0, bShowMsg = 1 )
{
	if ( bUnsafeUnsee )
	{
		m_bSeeing = false;
		if ( m_nSelectedKeyframe != -1 )
			m_nSelectedKeyframe = -1;
		CameraSetFov( 0, 0.1 );
		CameraSetEnabled( false );
		ListenMouse(1);
		SetHelperVisible( true );

		return;
	};

	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot use see while in playback!\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to use see.\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	m_bSeeing = !m_bSeeing;

	if ( m_bSeeing )
	{
		player.SetVelocity( Vector() );

		if ( m_nSelectedKeyframe == -1 )
			m_nSelectedKeyframe = m_nCurKeyframe;

		local key = m_KeyFrames[ m_nSelectedKeyframe ];

		// set fov and pos to selected
		if ( key.fov )
			CameraSetFov( key.fov, 0.25 );
		CameraSetOrigin( key.origin );
		CameraSetAngles( key.angles );

		CameraSetEnabled( true );

		ListenKeys(1);

		SetHelperVisible( false );

		if ( bShowMsg )
			MsgHint(Fmt( "Seeing keyframe #%d\n", m_nSelectedKeyframe ));
	}
	else
	{
		CompileFOV();

		if ( m_nSelectedKeyframe != -1 )
			m_nSelectedKeyframe = -1;

		CameraSetFov( 0, 0.1 );
		CameraSetEnabled( false );

		// ListenKeys(0);
		ListenMouse(1);

		SetHelperVisible( true );

		if ( bShowMsg )
		{
			Msg("Stopped seeing keyframe\n");
			HideHudHint();
		};
	};

	PlaySound(SND_BUTTON);
}


local s_vecMins = Vector();

// Edit mode think
VS.OnTimer( m_hThinkEdit, function() : ( s_flDisplayTime, s_vecMins )
{
	local count = m_KeyFrames.len();
	local viewOrigin = MainViewOrigin();
	local viewForward = MainViewForward();
	local nNearestKey;

	if ( count )
	{
		local viewAngles = CurrentViewAngles();
		local curkey;

		if ( !m_bInPlayback )
		{
			local bSelected = m_nSelectedKeyframe != -1;

			// not selected any keyframe
			if ( !bSelected )
			{
				local nCur = count - 1;
				local fThreshold = 0.9;
				local flBestDist = 1.e+37;

				foreach( i, key in m_KeyFrames )
				{
					local dir = key.origin - viewOrigin;
					local dist = dir.Norm();
					local dot = viewForward.Dot(dir);

					if ( dot > fThreshold )
					{
						nCur = i;
						fThreshold = dot;
					};

					if ( m_fPathSelection != 0 )
					{
						if ( dist < flBestDist )
						{
							flBestDist = dist;
							nNearestKey = i;
						};
					};
				}

				m_nCurKeyframe = nCur;
			};

			curkey = m_KeyFrames[ m_nCurKeyframe ];

			if ( curkey.fov )
			{
				m_hGameText2.__KeyValueFromString( "message", "FOV: " + curkey.fov );
			};

			if ( bSelected )
			{
				m_hGameText.__KeyValueFromString( "message", Fmt("KEY: %d (HOLD)", m_nCurKeyframe) );
			}
			else
			{
				m_hGameText.__KeyValueFromString( "message", "KEY: " + m_nCurKeyframe );
			};

			EntFireByHandle( m_hGameText, "Display", "", 0, player );
			EntFireByHandle( m_hGameText2, "Display", "", 0, player );
			EntFireByHandle( m_hGameText2, "SetText", "", 0, player );

			SetHelperOrigin( curkey.origin );
		};

		if ( m_bShowKeys )
		{
			// draw current keyframe - if not seeing and not in playback
			if ( !m_bSeeing && curkey )
			{
				if ( !m_bGizmoEnabled )
				{
					local dist = ( curkey.origin - viewOrigin ).Length();
					local s;
					if ( dist < 768.0 )
					{
						s = dist / 128.0;
						curkey.DrawFrustum( 255, 200, 255, s_flDisplayTime );
					}
					else
					{
						s = dist / 72.0;
					};

					DrawRectFilled( curkey.origin, s, 255, 120, 0, 255, s_flDisplayTime, viewAngles );
				};
			};

			// draw the rest
			foreach( i, key in m_KeyFrames )
			{
				if ( i == m_nCurKeyframe )
					continue;

				local dist = ( key.origin - viewOrigin ).Length();
				if ( dist < 768.0 )
				{
					key.DrawFrustum( 255, 200, 255, s_flDisplayTime );

					DrawRectFilled( key.origin, dist / 128.0, 255, 0, 0, 255, s_flDisplayTime, viewAngles );
				}
				else
				{
					if ( i != m_nAnimKeyframeIdx )
						DrawRectFilled( key.origin, 8.0, 255, 0, 0, 255, s_flDisplayTime, viewAngles );
				};
			}
		};
	};

	if ( m_bShowPath )
	{
		local pPath = m_PathData;
		local res = m_nDrawResolution;
		local len = pPath.len() - res;
		local ToVector = VS.AngleVectors;

		if ( len > 0 )
		{
			local r = m_bDirty ? 255 : 128;

			for ( local i = 0; i < len; i+=res )
			{
				local pt = pPath[i].origin;

				DrawLine( pt, pPath[ i + res ].origin, r, 255, 0, true, s_flDisplayTime );

				// draw angles if close enough, for perf
				local dist = ( pt - viewOrigin ).LengthSqr();
				if ( dist < 2.3593e+6 )
				{
					DrawLine( pt, pt + ToVector( pPath[i].angles ) * 16, 255, 128, 255, true, s_flDisplayTime );
				};
			}

			local bounds = true;
			local offset = 0;

			if ( m_Selection[0] )
			{
				VS.DrawSphere( m_PathData[ m_Selection[0] ].origin, 8.0, 6, 6, 255, 196, 0, true, s_flDisplayTime );
			}
			else bounds = false;

			if ( m_Selection[1] )
			{
				VS.DrawSphere( m_PathData[ m_Selection[1] ].origin, 8.0, 6, 6, 255, 196, 0, true, s_flDisplayTime );
			}
			else bounds = false;

			if ( bounds )
			{
				res = 2;
				len = m_Selection[1] - m_Selection[0];
				offset = m_Selection[0];
			};

			m_nAnimPathIdx = (m_nAnimPathIdx + res) % len;
			local origin = pPath[ offset + m_nAnimPathIdx ].origin;
			s_vecMins.x = s_vecMins.y = 0.0; s_vecMins.z = 16.0;
			VS.DrawCapsule( origin - s_vecMins, origin + s_vecMins, 8, 0,255,255,true, s_flDisplayTime );

			// Path selection:
			// Find the path player is looking at around the nearest keyframe
			if ( m_fPathSelection != 0 )
			{
				if ( nNearestKey < 2 )
					nNearestKey = 2;
				else if ( nNearestKey > (count-3) )
					nNearestKey = count-3;;

				local end = nNearestKey * m_nSampleCount;
				local i = (nNearestKey-2) * m_nSampleCount;
				local nSelect = 0;
				local fThreshold = 0.9;

				while ( i < end )
				{
					local dir = m_PathData[i].origin - viewOrigin;
					dir.Norm();
					local dot = viewForward.Dot( dir );

					if ( dot > fThreshold )
					{
						fThreshold = dot;
						nSelect = i;
					};
					++i;
				}

				m_nCurPathSelection = nSelect;

				VS.DrawSphere( m_PathData[nSelect].origin, 8.0, 6, 6, 255, 255, 0, true, s_flDisplayTime );
			}
		};
	};
}, this );


VS.OnTimer( m_hThinkAnim, function()
{
	if ( m_bShowKeys )
	{
		local count = m_KeyFrames.len();
		if ( count )
		{
			++m_nAnimKeyframeIdx;
			m_nAnimKeyframeIdx %= count;

			local key = m_KeyFrames[ m_nAnimKeyframeIdx ];

			if ( m_nAnimKeyframeIdx != m_nSelectedKeyframe )
			{
				local dist = ( key.origin - CurrentViewOrigin() ).Length();
				if ( dist < 768.0 )
				{
					local s = dist / 128.0;

					DrawRectFilled( key.origin, s, 155, 255, 255, 255, 0.7, CurrentViewAngles() );
				}
				else
				{
					DrawRectFilled( key.origin, 8.0, 155, 255, 255, 255, 0.7, CurrentViewAngles() );
				}
			}
			else if ( m_bSeeing )
			{
				local worldPos = VS.ScreenToWorld( 0.65, 0.35,
					key.origin,
					key.forward,
					key.right,
					key.up,
					90.0, 1.77778, 16 );

				DrawRectFilled( worldPos, 0.5, 155, 255, 255, 96, 0.25, key.angles );
				DrawRectFilled( worldPos, 0.5, 155, 255, 255, 64, 0.5, key.angles );
			};;
		};
	};

}, this );


// TODO: use SetThink
local FrameThink = function()
{
	if ( m_bGizmoEnabled )
		ManipulatorThink( m_KeyFrames[ m_nCurKeyframe ], MainViewOrigin(), MainViewForward(), MainViewAngles() );

	// indicate the camera is in a special state
	// TODO: use an overlay
	if ( m_bReplaceOnClick || m_bInsertOnClick )
	{
		local worldPos = VS.ScreenToWorld( 0.5, 0.63,
			MainViewOrigin(),
			MainViewForward(),
			MainViewRight(),
			MainViewUp(),
			90.0, 1.77778, 16 );

		local angles = MainViewAngles();

		local maxs = Vector( 0.0, 5.0, 0.25 );
		local mins = Vector( 0.0, -5.0, -0.25 );

		local alpha = VS.SmoothCurve( Time() ) * 255;
		DrawBoxAnglesFilled( worldPos, mins, maxs, angles, 255, 120, 0, alpha, -1 );
	};

	// animate frustum
	if ( m_pLerpFrustum )
	{
		m_flLerpKeyAnim += 0.01;

		local out = KeyframeLerp( m_pLerpFrustum[0], m_pLerpFrustum[1], VS.SmoothCurve( m_flLerpKeyAnim ) );
		out.DrawFrustum( 155, 100, 155, 0.075 );

		if ( m_flLerpKeyAnim >= 1.0 )
		{
			m_flLerpKeyAnim = 0.0;
		};
	};

	// animate kf_transform
	if ( m_pLerpTransform )
	{
		local angles = MainViewAngles();

		local org = Vector();
		local c = m_pLerpTransform.len();
		for ( local i = 0; i < c; ++i )
		{
			VS.VectorLerp(
				m_pLerpTransform[i],
				m_KeyFrames[i].origin,
				VS.SmoothCurve( m_flLerpTransformAnim ),
				org );
			DrawRectFilled( org, 5, 155, 100, 155, 255, 0.075, angles )
		}

		m_flLerpTransformAnim += 0.01;

		if ( m_flLerpTransformAnim >= 1.0 )
		{
			m_flLerpTransformAnim = 0.0;
		};
	};
}

// write into static output
function KeyframeLerp( in1, in2, frac )
{
	local out = m_hLerpKeyframe;
	VS.VectorLerp( in1.origin, in2.origin, frac, out.origin );
	VS.QuaternionSlerp( in1.orientation, in2.orientation, frac, out.orientation );
	out.SetQuaternion( out.orientation ); // update transform matrix

	if ( in1._fovx != in2._fovx )
	{
		out.SetFov( VS.Lerp( in1._fovx, in2._fovx, frac ) );
	};

	return out;
}


function ValidateFrameThink() : (FrameThink)
{
	if ( !m_hThinkFrame )
	{
		m_hThinkFrame = VS.Timer( true, FrameTime(), null, null, false, true ).weakref();
		VS.OnTimer( m_hThinkFrame, FrameThink, this );
	};
}

function ToggleFrameThink( b )
{
	ValidateFrameThink();

	if ( b )
	{
		EntFireByHandle( m_hThinkFrame, "Enable" );
	}
	else
	{
		if ( !m_bInsertOnClick && !m_bReplaceOnClick && !m_pLerpFrustum && !m_pLerpTransform && !m_bGizmoEnabled )
		{
			EntFireByHandle( m_hThinkFrame, "Disable" );
		}
	}
}


//--------------------------------------------------------------
//--------------------------------------------------------------


g_v100 <- Vector(1,0,0);
g_v010 <- Vector(0,1,0);
g_v001 <- Vector(0,0,1);

local vAxisMin = Vector( -1, -1, -1 );
local vAxisMax = Vector( 32, 1, 1 );

local vPlaneMin = Vector();
local vPlaneMax = Vector();

local vRectMin = Vector();
local vRectMax = Vector();

function DrawRectFilled( pos, s, r, g, b, a, t, viewAngles ) : ( vRectMin, vRectMax )
{
	if ( s != vRectMax.z )
	{
		vRectMin.y = vRectMin.z = -s;
		vRectMax.y = vRectMax.z =  s;
	};
	return DrawBoxAnglesFilled( pos, vRectMin, vRectMax, viewAngles, r,g,b,a, t );
}

function DrawGrid( pos, up, right, time )
{
	pos += up * 64.0 - right * 80.0;
	for ( local i = 0; i <= 8; ++i )
	{
		pos += right * 16.0;
		local v1 = pos - up * 128.0;
		DrawLine( pos, v1, 100, 140, 220, true, time );
	}
	for ( local i = 0; i <= 8; ++i )
	{
		local v1 = pos - right * 128.0;
		DrawLine( pos, v1, 100, 140, 220, true, time );
		pos -= up * 16.0;
	}
}


// Very basic screen plane, axis and plane translation manipulator.
// FIXME: Because of the drawing order parts of the axes lag behind while moving

function ManipulatorThink( key, viewOrigin, viewForward, viewAngles )
	: ( vAxisMin, vAxisMax, vPlaneMin, vPlaneMax )
{
	local vecCursor;

	if ( !IsDucking() )
	{
		// stopped ducking
		if ( m_vecCameraOffset )
		{
			CameraSetEnabled(0);
			m_vecCameraOffset = null;
			m_nSelectedKeyframe = -1;

			// if duck was let go before mouse while rotating,
			// remember this for when duck is held again without releasing mouse
			if ( m_bMouseDown )
			{
				m_bMouseDown = false;
				m_bMouseForceUp = true;
			};
		};

		// if not ducking and dont have a selection (axis or plane)
		if ( !m_nTranslation )
		{
			key.DrawFrustum( 255, 200, 255, -1 );

			local deltaOrigin = viewOrigin - key.origin;
			local t;

			local rayDelta = viewForward * 2048.0;
			local nSelection;

			// Screen plane translation
			if ( VS.IsRayIntersectingSphere( viewOrigin, rayDelta, key.origin, 6.0 ) )
			{
				nSelection = 1;
				DrawRectFilled( key.origin, 4, 0,255,255,255, -1, viewAngles );
			}
			else
			{
				DrawRectFilled( key.origin, 4, 255,120,0,255, -1, viewAngles );
			};


			// Local camera axes looking down +z

			// test Z
			vAxisMax.x = vAxisMax.y = 1.0; vAxisMax.z = 32.0;

			if ( !nSelection && VS.IsBoxIntersectingRay( key.origin + vAxisMin, key.origin + vAxisMax, viewOrigin, rayDelta ) )
			{
				nSelection = 2;
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, g_v010, 0.0 );
				DrawBox( key.origin, vAxisMin, vAxisMax, 120,120,255,255, -1 );
			}
			else
			{
				DrawBox( key.origin, vAxisMin, vAxisMax, 0,0,255,255, -1 );
			};


			// test X
			vAxisMax.z = vAxisMax.y = 1.0; vAxisMax.x = 32.0;

			if ( !nSelection && VS.IsBoxIntersectingRay( key.origin + vAxisMin, key.origin + vAxisMax, viewOrigin, rayDelta ) )
			{
				nSelection = 3;
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, g_v001, 0.0 );
				DrawBox( key.origin, vAxisMin, vAxisMax, 255,120,120,255, -1 );
			}
			else
			{
				DrawBox( key.origin, vAxisMin, vAxisMax, 255,0,0,255, -1 );
			};


			// test Y
			vAxisMax.x = vAxisMax.z = 1.0; vAxisMax.y = 32.0;

			if ( !nSelection && VS.IsBoxIntersectingRay( key.origin + vAxisMin, key.origin + vAxisMax, viewOrigin, rayDelta ) )
			{
				nSelection = 4;
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, g_v001, 0.0 );
				DrawBox( key.origin, vAxisMin, vAxisMax, 180,255,120,255, -1 );
			}
			else
			{
				DrawBox( key.origin, vAxisMin, vAxisMax, 0,255,0,255, -1 );
			};


			// test XY
			vPlaneMin.z = 0.0; vPlaneMin.x = vPlaneMin.y = 11.0;
			vPlaneMax.z = 0.0; vPlaneMax.x = vPlaneMax.y = 20.0;

			if ( !nSelection && VS.IsBoxIntersectingRay( key.origin + vPlaneMin, key.origin + vPlaneMax, viewOrigin, rayDelta ) )
			{
				nSelection = 5;
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, g_v001, 0.0 );
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 120,120,255,255, -1 );
			}
			else
			{
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 0,0,255,255, -1 );
			};


			// test YZ
			vPlaneMin.x = 0.0; vPlaneMin.y = vPlaneMin.z = 11.0;
			vPlaneMax.x = 0.0; vPlaneMax.y = vPlaneMax.z = 20.0;

			if ( !nSelection && VS.IsBoxIntersectingRay( key.origin + vPlaneMin, key.origin + vPlaneMax, viewOrigin, rayDelta ) )
			{
				nSelection = 6;
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, g_v100, 0.0 );
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 255,120,120,255, -1 );
			}
			else
			{
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 255,0,0,255, -1 );
			};


			// test XZ
			vPlaneMin.y = 0.0; vPlaneMin.x = vPlaneMin.z = 11.0;
			vPlaneMax.y = 0.0; vPlaneMax.x = vPlaneMax.z = 20.0;

			if ( !nSelection && VS.IsBoxIntersectingRay( key.origin + vPlaneMin, key.origin + vPlaneMax, viewOrigin, rayDelta ) )
			{
				nSelection = 7;
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, g_v010, 0.0 );
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 180,255,180,255, -1 );
			}
			else
			{
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 0,255,0,255, -1 );
			};


			// default to screen plane
			if ( !t )
				t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, viewForward*-1, 0.0 );
			vecCursor = viewOrigin + viewForward * t;

			if ( nSelection )
			{
				if ( m_bMouseDown )
				{
					m_nTranslation = nSelection;
					m_nSelectedKeyframe = m_nCurKeyframe;

					m_vecOffset = vecCursor - key.origin;
					VS.VectorCopy( key.origin, m_vecLastKeyOrigin );
					m_vecLastDeltaOrigin = deltaOrigin;
					m_vecLastOrigin = viewOrigin;
					m_vecLastForward = viewForward;
					m_vecLastUp = MainViewUp();
					m_vecLastRight = MainViewRight();

					// HACKHACK: can't be bothered to find a proper solution to moving view angles while translating
					// so just freeze the player in place so the planes don't mess up
					player.__KeyValueFromInt( "movetype", 0 );
				}
				else if ( m_nMouseOver != nSelection )
				{
					m_nMouseOver = nSelection;
					PlaySound( "UI.PageScroll" );
				};;
			}
			else if ( m_nMouseOver )
			{
				m_nMouseOver = 0;
			};;
		}
		// if not ducking and have a selection (axis or plane)
		else
		{
			local nSelection = m_nTranslation;
			// Assert( nSelection, "m_nTranslation == 0" );


			if ( nSelection == 1 )
			{
				local t = VS.IntersectRayWithPlane( m_vecLastDeltaOrigin, viewForward, m_vecLastForward*-1, 0.0 );
				if ( t > 1024.0 )	t = 1024.0;
				else if ( t < 0.0 )	t = 0.0;;
				vecCursor = m_vecLastOrigin + viewForward * t;

				key.SetOrigin( vecCursor - m_vecOffset );

				DrawRectFilled( key.origin, 4, 255,255,0,255, -1, viewAngles );
				DrawGrid( key.origin, m_vecLastUp, m_vecLastRight, -1 );
			}
			else
			{
				DrawRectFilled( key.origin, 4, 255,120,0,255, -1, viewAngles );
			};


			// Z
			vAxisMax.x = vAxisMax.y = 1.0; vAxisMax.z = 32.0;

			if ( nSelection == 2 )
			{
				local t = VS.IntersectRayWithPlane( m_vecLastDeltaOrigin, viewForward, g_v010, 0.0 );
				if ( t > 1024.0 )	t = 1024.0;
				else if ( t < 0.0 )	t = 0.0;;
				vecCursor = m_vecLastOrigin + viewForward * t;

				key.origin.z = vecCursor.z - m_vecOffset.z;
				key.SetOrigin( key.origin );

				DrawBox( key.origin, vAxisMin, vAxisMax, 255,255,0,255, -1 );
				DrawGrid( key.origin, g_v001, g_v100, -1 );
			}
			else
			{
				DrawBox( key.origin, vAxisMin, vAxisMax, 0,0,255,255, -1 );
			};


			// X
			vAxisMax.z = vAxisMax.y = 1.0; vAxisMax.x = 32.0;

			if ( nSelection == 3 )
			{
				local t = VS.IntersectRayWithPlane( m_vecLastDeltaOrigin, viewForward, g_v001, 0.0 );
				if ( t > 1024.0 )	t = 1024.0;
				else if ( t < 0.0 )	t = 0.0;;
				vecCursor = m_vecLastOrigin + viewForward * t;

				key.origin.x = vecCursor.x - m_vecOffset.x;
				key.SetOrigin( key.origin );

				DrawBox( key.origin, vAxisMin, vAxisMax, 255,255,0,255, -1 );
				DrawGrid( key.origin, g_v100, g_v010, -1 );
			}
			else
			{
				DrawBox( key.origin, vAxisMin, vAxisMax, 255,0,0,255, -1 );
			};


			// Y
			vAxisMax.x = vAxisMax.z = 1.0; vAxisMax.y = 32.0;

			if ( nSelection == 4 )
			{
				local t = VS.IntersectRayWithPlane( m_vecLastDeltaOrigin, viewForward, g_v001, 0.0 );
				if ( t > 1024.0 )	t = 1024.0;
				else if ( t < 0.0 )	t = 0.0;;
				vecCursor = m_vecLastOrigin + viewForward * t;

				key.origin.y = vecCursor.y - m_vecOffset.y;
				key.SetOrigin( key.origin );

				DrawBox( key.origin, vAxisMin, vAxisMax, 255,255,0,255, -1 );
				DrawGrid( key.origin, g_v010, g_v100, -1 );
			}
			else
			{
				DrawBox( key.origin, vAxisMin, vAxisMax, 0,255,0,255, -1 );
			};


			// XY
			vPlaneMin.z = 0.0; vPlaneMin.x = vPlaneMin.y = 11.0;
			vPlaneMax.z = 0.0; vPlaneMax.x = vPlaneMax.y = 20.0;

			if ( nSelection == 5 )
			{
				local t = VS.IntersectRayWithPlane( m_vecLastDeltaOrigin, viewForward, g_v001, 0.0 );
				if ( t > 1024.0 )	t = 1024.0;
				else if ( t < 0.0 )	t = 0.0;;
				vecCursor = m_vecLastOrigin + viewForward * t;

				key.origin.x = vecCursor.x - m_vecOffset.x;
				key.origin.y = vecCursor.y - m_vecOffset.y;
				key.SetOrigin( key.origin );

				DrawBox( key.origin, vPlaneMin, vPlaneMax, 255,255,0,255, -1 );
				DrawGrid( key.origin, g_v010, g_v100, -1 );
			}
			else
			{
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 0,0,255,255, -1 );
			};


			// YZ
			vPlaneMin.x = 0.0; vPlaneMin.y = vPlaneMin.z = 11.0;
			vPlaneMax.x = 0.0; vPlaneMax.y = vPlaneMax.z = 20.0;

			if ( nSelection == 6 )
			{
				local t = VS.IntersectRayWithPlane( m_vecLastDeltaOrigin, viewForward, g_v100, 0.0 );
				if ( t > 1024.0 )	t = 1024.0;
				else if ( t < 0.0 )	t = 0.0;;
				vecCursor = m_vecLastOrigin + viewForward * t;

				key.origin.y = vecCursor.y - m_vecOffset.y;
				key.origin.z = vecCursor.z - m_vecOffset.z;
				key.SetOrigin( key.origin );

				DrawBox( key.origin, vPlaneMin, vPlaneMax, 255,255,0,255, -1 );
				DrawGrid( key.origin, g_v010, g_v001, -1 );
			}
			else
			{
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 255,0,0,255, -1 );
			};


			// XZ
			vPlaneMin.y = 0.0; vPlaneMin.x = vPlaneMin.z = 11.0;
			vPlaneMax.y = 0.0; vPlaneMax.x = vPlaneMax.z = 20.0;

			if ( nSelection == 7 )
			{
				local t = VS.IntersectRayWithPlane( m_vecLastDeltaOrigin, viewForward, g_v010, 0.0 );
				if ( t > 1024.0 )	t = 1024.0;
				else if ( t < 0.0 )	t = 0.0;;
				vecCursor = m_vecLastOrigin + viewForward * t;

				key.origin.x = vecCursor.x - m_vecOffset.x;
				key.origin.z = vecCursor.z - m_vecOffset.z;
				key.SetOrigin( key.origin );

				DrawBox( key.origin, vPlaneMin, vPlaneMax, 255,255,0,255, -1 );
				DrawGrid( key.origin, g_v100, g_v001, -1 );
			}
			else
			{
				DrawBox( key.origin, vPlaneMin, vPlaneMax, 0,255,0,255, -1 );
			};


			vAxisMax.x = 0.0; vAxisMax.y = vAxisMax.z = 2.0;
			DrawBoxAnglesFilled( m_vecLastKeyOrigin, vAxisMax*-1, vAxisMax, viewAngles, 255,255,255,64, -1 );
			DrawLine( m_vecLastKeyOrigin, key.origin, 255,255,255,true, -1 );
		};

		if ( m_bDuckFixup )
		{
			local v = player.GetOrigin();
			v.z -= 9.017594;
			player.SetOrigin( v );
			m_bDuckFixup = false;
		};
	}
	// ducking, rotate camera around cursor
	else if ( !m_nTranslation )
	{
		if ( !m_bDuckFixup )
		{
			local v = player.GetOrigin();
			v.z += 9.017594;
			player.SetOrigin( v );
			m_bDuckFixup = true;
		};

		if ( m_bMouseForceUp )
		{
			m_bMouseDown = true;
			m_bMouseForceUp = false;
		};

		key.DrawFrustum( 255, 200, 255, -1 );

		vecCursor = key.origin;
		// local deltaOrigin = viewOrigin - key.origin;
		// local t = VS.IntersectRayWithPlane( deltaOrigin, viewForward, viewForward*-1, 0.0 );
		// vecCursor = viewOrigin + viewForward * t;

		if ( m_bMouseDown )
		{
			if ( !m_vecCameraOffset )
			{
				CameraSetEnabled(1);
				CameraSetOrigin( viewOrigin );
				CameraSetForward( viewForward );

				// m_vecPivotPoint = vecCursor;

				m_nSelectedKeyframe = m_nCurKeyframe;
				m_vecCameraOffset = viewOrigin - vecCursor;
				m_vecLastForwardFrame = viewForward;
			}
			else
			{
				local deltaForward = viewForward - m_vecLastForwardFrame;

				if ( !VS.VectorIsZero( deltaForward ) )
				{
					// m_vecPivotPoint
					local pos = vecCursor - viewForward * m_vecCameraOffset.Length();
					CameraSetOrigin( pos );
					CameraSetForward( viewForward );

					pos.z -= 46.0;
					player.SetOrigin( pos );
				};

				m_vecLastForwardFrame = viewForward;
			};
		}
		else if ( m_vecCameraOffset )
		{
			CameraSetEnabled(0);
			m_vecCameraOffset = null;
			m_nSelectedKeyframe = -1;
		};;
	}
	// ducking while translating
	else
	{
		vecCursor = key.origin;
	};;

	// draw cursor
	DrawRectFilled( vecCursor, 2, 255,255,255,255, -1, viewAngles );
}

function GizmoOnMouseDown()
{
	// PushUndo( "translation" );

	m_bMouseDown = true;
}

function GizmoOnMouseRelease()
{
	// PushRedo( "translation" );

	m_bMouseDown = false;
	m_bMouseForceUp = false;
	player.__KeyValueFromInt( "movetype", 8 );

	if ( m_nTranslation )
	{
		PlaySound( "UI.StickerSelect" );
		m_nSelectedKeyframe = -1;
		m_nTranslation = 0;
		m_bDirty = true;

		// compile path around key
		local max = m_KeyFrames.len()-2;

		// is there enough path frames?
		if ( (((max-2)* m_nSampleCount) + m_nSampleCount - 1) in m_PathData )
		{
			local cur = m_nCurKeyframe;
			if ( cur <= 1 )
				cur = 2;
			else if ( cur >= max )
				cur = max-1;;

			for ( local w,t,nSampleFrame,nKey = cur-1; nKey < cur+1; ++nKey )
			{
				w = (nKey-1) * m_nSampleCount;
				for ( nSampleFrame = 0, t = 0.0; 1.0 - t > KF_FLT_EPS; ++nSampleFrame, t += m_flSampleRate )
				{
					local org = Vector();
					local ang = Vector();
					_Process.SplineOrigin( nKey, t, org );
					_Process.SplineAngles( nKey, t, ang );
					m_PathData[ w + nSampleFrame ].origin = org;
					m_PathData[ w + nSampleFrame ].angles = ang;
				}
			}
		};
	};
}

function ShowGizmo( i = null )
{
	if ( i == null )
		i = !m_bGizmoEnabled;

	if ( i && !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	m_bGizmoEnabled = !!i;
	ToggleFrameThink( m_bGizmoEnabled );

	Msg("Translation manipulator " + m_bGizmoEnabled.tointeger() + "\n");

	if ( m_bGizmoEnabled )
	{
		m_hThinkAnim.__KeyValueFromFloat( "nextthink", -1 );
		m_nAnimKeyframeIdx = -1;
	}
	else
	{
		m_hThinkAnim.__KeyValueFromFloat( "nextthink", 1 );
	};

	PlaySound( SND_BUTTON );
}


//--------------------------------------------------------------
//--------------------------------------------------------------


// Keyframe states (transform matrices) are saved before the action with PushUndo,
// and after the action with PushRedo.
// Undo/Redo moves along the stack and applies these saved states.
//
// Alternatively use the older method of saving actions to be undone/redone, which would be more efficient.

class CUndoElem
{
	// matrix3x4_t[]
	undo = null;
	undo_desc = null;
	redo = null;
	redo_desc = null;

	function Push( type, desc, pKeyFrames )
	{
		this[type + "_desc"] = desc;

		local c = pKeyFrames.len();
		this[type] = array( c );

		for ( local i = 0; i < c; ++i )
		{
			if ( !pKeyFrames[i] )
			{
				// in case something has gone wrong
				pKeyFrames.resize(i);
				this[type].resize(i);
				return;
			};
			this[type][i] = clone pKeyFrames[i].transform;
		}
	}

	function Apply( type, pKeyFrames ) : (keyframe_t)
	{
		local c = this[type].len();

		pKeyFrames.resize(c);

		for ( local i = 0; i < c; ++i )
		{
			if ( !pKeyFrames[i] )
			{
				pKeyFrames[i] = keyframe_t();
			};
			pKeyFrames[i].transform = null;
			pKeyFrames[i].transform = clone this[type][i];
			pKeyFrames[i].Update();
		}
	}
}

function PushUndo( desc )
{
	// truncate future
	m_UndoStack.resize( m_nUndoLevel );

	if ( m_UndoStack.len() >= 16 )
	{
		m_nUndoLevel--;
		m_UndoStack.remove(0);
	};

	local undo = CUndoElem();
	undo.Push( "undo", desc, m_KeyFrames );
	m_UndoStack.append( undo );
	m_nUndoLevel++;
}

function PushRedo( desc )
{
	local undo = m_UndoStack[ m_nUndoLevel - 1 ];
	undo.Push( "redo", desc, m_KeyFrames );
}

function Undo()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_UndoStack.len() || m_nUndoLevel <= 0 )
		return MsgFail("cannot undo\n");

	m_nUndoLevel--;
	local undo = m_UndoStack[ m_nUndoLevel ];
	undo.Apply( "undo", m_KeyFrames );

	Msg(Fmt( "Undo: %s\n", undo.undo_desc ));

	m_bDirty = true;

	PlaySound(SND_BUTTON);
}

function Redo()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_UndoStack.len() || m_nUndoLevel > m_UndoStack.len() - 1 )
		return MsgFail("cannot redo\n");

	local undo = m_UndoStack[ m_nUndoLevel ];
	m_nUndoLevel++;
	undo.Apply( "redo", m_KeyFrames );

	Msg(Fmt( "Redo: %s\n", undo.redo_desc ));

	m_bDirty = true;

	PlaySound(SND_BUTTON);
}

function PrintUndoStack()
{
	local c = m_UndoStack.len();
	local level = m_nUndoLevel-1;
	Msg(Fmt( "Undo stack	:	[%d / %d]\n", level, c-1 ));

	for ( local i = 0; i < c; ++i )
	{
		if ( i == level )
		{
			Msg(Fmt( "\t%2d : %s\t<-- HEAD\n", i, m_UndoStack[i].undo_desc ));
		}
		else
		{
			Msg(Fmt( "\t%2d : %s\n", i, m_UndoStack[i].undo_desc ));
		}
	}
}


//--------------------------------------------------------------
//--------------------------------------------------------------


// kf_copy
// Set player pos/ang to the current keyframe
function CopyKeyframe()
{
	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to copy.\n");

	if ( m_bSeeing )
		return MsgFail("Cannot copy while seeing!\n");

	local key = m_KeyFrames[ m_nCurKeyframe ];

	local pos = Vector();
	VS.VectorCopy( key.origin, pos );
	pos.z -= 64.0;

	player.SetOrigin( pos );
	player.SetForwardVector( key.forward );

	MsgHint(Fmt( "Copied keyframe #%d\n", m_nCurKeyframe ));
	PlaySound(SND_BUTTON);
}

function StopReplaceLerp()
{
	m_pLerpFrustum = null;
	m_hLerpKeyframe = null;
	m_flLerpKeyAnim = null;
	ToggleFrameThink( false );
}

// kf_replace
function ReplaceKeyframe()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to insert keyframes.\n");

	// replace while not selected - activate click to replace
	if ( m_nSelectedKeyframe == -1 )
	{
		m_bReplaceOnClick = true;
		ToggleFrameThink( true );
		m_nSelectedKeyframe = m_nCurKeyframe;

		MsgHint(Fmt( "Left click to replace keyframe #%d...\n", m_nCurKeyframe ));
		PlaySound(SND_BUTTON);
		return;
	};

	// replace while seeing - copy and activate click to replace
	if ( m_bSeeing )
	{
		m_bReplaceOnClick = true;
		ToggleFrameThink( true );

		// unsee and keep selected keyframe
		local curkey = m_nSelectedKeyframe;
		SeeKeyframe( 1, 0 );
		m_nSelectedKeyframe = curkey;

		local pos = Vector();
		local key = m_KeyFrames[ m_nCurKeyframe ];
		VS.VectorCopy( key.origin, pos );
		pos.z -= 64.0;

		player.SetOrigin( pos );
		player.SetForwardVector( key.forward );

		MsgHint(Fmt( "Left click to replace keyframe #%d...\n", m_nCurKeyframe ));
		PlaySound(SND_BUTTON);
		return;
	};

	m_bReplaceOnClick = false;
	m_nSelectedKeyframe = -1;

	PushUndo( "replace" );

	local key = m_KeyFrames[ m_nCurKeyframe ];
	local copykey = clone key;

	m_pLerpFrustum = [ copykey, key ];
	m_hLerpKeyframe = keyframe_t();
	m_flLerpKeyAnim = 0.0;

	ToggleFrameThink( true );

	VS.EventQueue.CancelEventsByInput( StopReplaceLerp );
	// animate it 5 times
	VS.EventQueue.AddEvent( StopReplaceLerp, 5 * 100 * FrameTime(), this );

	local pos = MainViewOrigin();
	local ang = MainViewAngles();
	local dir = MainViewForward();

	key.SetAngles( ang );
	key.SetOrigin( pos );
	key.SetFov( null );

	PushRedo( "replace" );

	m_bDirty = true;

	DrawLine( pos, pos + dir * 64, 127, 255, 0, true, 1.5 );
	DrawBoxAnglesFilled( pos, Vector(-4,-4,-4), Vector(4,4,4), ang, 127, 255, 0, 127, 1.5 );

	MsgHint(Fmt( "Replaced keyframe #%d\n", m_nCurKeyframe ));
	PlaySound(SND_BUTTON);
}

// kf_insert
function InsertKeyframe()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to insert keyframes.\n");

	if ( m_bSeeing )
		return MsgFail("Cannot insert while seeing!\n");

	if ( m_nSelectedKeyframe == -1 )
	{
		m_bInsertOnClick = true;
		ToggleFrameThink( true );
		m_nSelectedKeyframe = m_nCurKeyframe;

		MsgHint(Fmt( "Left click to insert keyframe at #%d...\n", m_nCurKeyframe ));
		PlaySound(SND_BUTTON);
		return;
	};

	m_bInsertOnClick = false;
	m_nSelectedKeyframe = -1;

	local pos = MainViewOrigin();
	local ang = MainViewAngles();
	local dir = MainViewForward();

	PushUndo( "insert" );

	local key = keyframe_t();
	key.SetOrigin( pos );
	key.SetAngles( ang );
	m_KeyFrames.insert( m_nCurKeyframe, key );

	PushRedo( "insert" );

	m_bDirty = true;

	DrawLine( pos, pos + dir * 64, 127, 255, 0, true, 1.5 );
	DrawBoxAnglesFilled( pos, Vector(-4,-4,-4), Vector(4,4,4), ang, 127, 255, 0, 127, 1.5 );

	MsgHint(Fmt( "Inserted keyframe #%d\n", m_nCurKeyframe ));
	PlaySound(SND_BUTTON);
}

// kf_remove
function RemoveKeyframe() : (MAX_COORD_VEC)
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to remove keyframes.\n");

	// unsee
	if ( m_bSeeing )
		SeeKeyframe(1);

	PushUndo( "remove" );

	local key = m_KeyFrames.remove( m_nCurKeyframe );

	PushRedo( "remove" );

	if ( !m_KeyFrames.len() )
	{
		MsgHint("Removed all keyframes.\n");

		// current
		m_nCurKeyframe = 0;

		// unselect
		m_nSelectedKeyframe = -1;

		m_bGizmoEnabled = false;
		ToggleFrameThink( false );

		// cheap way to hide the sprite
		SetHelperOrigin( MAX_COORD_VEC );
	}
	else
	{
		MsgHint(Fmt( "Removed keyframe #%d\n", m_nCurKeyframe ));

		// if out of bounds, reset
		if ( !(m_nCurKeyframe in m_KeyFrames) )
		{
			m_nCurKeyframe = 0;
			m_nSelectedKeyframe = -1;
		};
	};

	m_bDirty = true;

	PlaySound(SND_BUTTON);
}

// kf_removefov
function RemoveFOV()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to remove FOV data.\n");

	// refresh
	if ( m_bSeeing )
		CameraSetFov( 0, 0.1 );

	local key = m_KeyFrames[ m_nCurKeyframe ];
	if ( !key.fov )
		return MsgFail(Fmt( "No FOV data on keyframe #%d found.\n", m_nCurKeyframe ));

	key.SetFov( null );

	CompileFOV();

	MsgHint(Fmt( "Removed FOV data at keyframe #%d\n", m_nCurKeyframe ));
	PlaySound(SND_BUTTON);
}

// kf_add
function AddKeyframe()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( m_bSeeing )
		return MsgFail("Cannot add new keyframe while seeing!\n");

	PushUndo( "add" );

	local pos = MainViewOrigin();
	local ang = MainViewAngles();
	local dir = MainViewForward();

	local key = keyframe_t();
	key.SetOrigin( pos );
	key.SetAngles( ang );
	ArrayAppend( m_KeyFrames, key );

	PushRedo( "add" );

	m_bDirty = true;

	local t = m_bInEditMode ? 1.5 : 7.0;
	DrawLine( pos, pos + dir * 64, 127, 255, 0, true, t );
	DrawBoxAnglesFilled( pos, Vector(-4,-4,-4), Vector(4,4,4), ang, 127, 255, 0, 127, t );

	MsgHint(Fmt( "Added keyframe #%d\n", (m_KeyFrames.len()-1) ));
	PlaySound(SND_BUTTON);
}

// kf_clear
function RemoveAllKeyframes():(MAX_COORD_VEC)
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	// unsee
	if ( m_bSeeing )
		SeeKeyframe(1);

	PushUndo( "clear" );

	// unselect
	m_nSelectedKeyframe = -1;

	// current
	m_nCurKeyframe = 0;

	MsgHint(Fmt( "Removed %d keyframes.\n", m_KeyFrames.len() ));

	m_KeyFrames.clear();

	PushRedo( "clear" );

	m_bDirty = true;

	m_bGizmoEnabled = false;
	ToggleFrameThink( false );

	// cheap way to hide the sprite
	SetHelperOrigin( MAX_COORD_VEC );

	PlaySound(SND_BUTTON);
}


const KF_INTERP_DEFAULT				= 0;;
const KF_INTERP_CATMULL_ROM			= 1;;
const KF_INTERP_CATMULL_ROM_NORM	= 2;;
const KF_INTERP_CATMULL_ROM_DIR		= 3;;
const KF_INTERP_LINEAR				= 4;;
const KF_INTERP_LINEAR_BLEND		= 5;;
const KF_INTERP_D3DX				= 6;;
const KF_INTERP_BSPLINE				= 7;;
const KF_INTERP_SIMPLE_CUBIC		= 8;;

local KF_INTERP_COUNT				= 9;

// origin interpolator
local g_InterpolatorMap = array( KF_INTERP_COUNT );
g_InterpolatorMap[ KF_INTERP_DEFAULT ]				= CONST.INTERPOLATE.CATMULL_ROM;
g_InterpolatorMap[ KF_INTERP_CATMULL_ROM ]			= CONST.INTERPOLATE.CATMULL_ROM;
g_InterpolatorMap[ KF_INTERP_CATMULL_ROM_NORM ]		= CONST.INTERPOLATE.CATMULL_ROM_NORMALIZE;
g_InterpolatorMap[ KF_INTERP_LINEAR ]				= CONST.INTERPOLATE.LINEAR_INTERP;
g_InterpolatorMap[ KF_INTERP_BSPLINE ]				= CONST.INTERPOLATE.BSPLINE;
g_InterpolatorMap[ KF_INTERP_SIMPLE_CUBIC ]			= CONST.INTERPOLATE.SIMPLE_CUBIC;



// kf_mode_angles
function SetAngleInterp( i = null ) : (KF_INTERP_COUNT)
{
	if ( m_bCompiling )
		return MsgFail("Cannot change algorithm while compiling!\n");

	if ( i == null )
	{
		i = (m_nInterpolatorAngle + 1) % 6;
	};

	m_nInterpolatorAngle = i;
	switch (m_nInterpolatorAngle)
	{
		case KF_INTERP_DEFAULT:
			m_nInterpolatorAngle = KF_INTERP_D3DX;

		case KF_INTERP_D3DX:
			m_szInterpDescAngle = "KF_INTERP_D3DX";
			Msg(Fmt( "angle interp: KF_INTERP_D3DX\n" ));
			break;

		case KF_INTERP_LINEAR_BLEND:
			m_szInterpDescAngle = "KF_INTERP_LINEAR_BLEND";
			Msg(Fmt( "angle interp: KF_INTERP_LINEAR_BLEND\n" ));
			break;

		case KF_INTERP_LINEAR:
			m_szInterpDescAngle = "KF_INTERP_LINEAR";
			Msg(Fmt( "angle interp: KF_INTERP_LINEAR\n" ));
			break;

		case KF_INTERP_CATMULL_ROM_DIR:
			m_szInterpDescAngle = "KF_INTERP_CATMULL_ROM_DIR";
			Msg(Fmt( "angle interp: KF_INTERP_CATMULL_ROM_DIR\n" ));
			break;

		case KF_INTERP_COUNT:
			return SetAngleInterp( KF_INTERP_D3DX );

		default:
			return SetAngleInterp( m_nInterpolatorAngle + 1 );
	}

	PlaySound(SND_BUTTON);
}

// kf_mode_origin
function SetOriginInterp( i = null )  : ( KF_INTERP_COUNT )
{
	if ( m_bCompiling )
		return MsgFail("Cannot change algorithm while compiling!\n");

	if ( i == null )
	{
		i = (m_nInterpolatorOrigin + 1) % KF_INTERP_COUNT;
	};

	m_nInterpolatorOrigin = i;
	switch (m_nInterpolatorOrigin)
	{
		case KF_INTERP_DEFAULT:
			m_nInterpolatorOrigin = KF_INTERP_CATMULL_ROM;

		case KF_INTERP_CATMULL_ROM:
			m_szInterpDescOrigin = "KF_INTERP_CATMULL_ROM";
			Msg(Fmt( "origin interp: KF_INTERP_CATMULL_ROM\n" ));
			break;

		case KF_INTERP_CATMULL_ROM_NORM:
			m_szInterpDescOrigin = "KF_INTERP_CATMULL_ROM_NORM";
			Msg(Fmt( "origin interp: KF_INTERP_CATMULL_ROM_NORM\n" ));
			break;

		case KF_INTERP_LINEAR:
			m_szInterpDescOrigin = "KF_INTERP_LINEAR";
			Msg(Fmt( "origin interp: KF_INTERP_LINEAR\n" ));
			break;

		case KF_INTERP_BSPLINE:
			m_szInterpDescOrigin = "KF_INTERP_BSPLINE";
			Msg(Fmt( "origin interp: KF_INTERP_BSPLINE\n" ));
			break;

		case KF_INTERP_SIMPLE_CUBIC:
			m_szInterpDescOrigin = "KF_INTERP_SIMPLE_CUBIC";
			Msg(Fmt( "origin interp: KF_INTERP_SIMPLE_CUBIC\n" ));
			break;

		case KF_INTERP_COUNT:
			return SetOriginInterp( KF_INTERP_CATMULL_ROM );

		default:
			return SetOriginInterp( m_nInterpolatorOrigin + 1 );
	}

	PlaySound(SND_BUTTON);
}


function SetSamplingRate( f )
{
	if ( m_bCompiling || m_bPreview )
		return MsgFail("Cannot change sampling rate while compiling!\n");

	if ( f == 0 )
	{
		f = 0.01; // KF_INTERP_SAMPLE_RATE_DEFAULT
	};

	f = f.tofloat();

	if ( f < 0.001 || f > 0.5 )
		return MsgFail("Input out of range [0.001, 0.5]\n");

	if ( m_flSampleRate != f )
		m_bDirty = true;

	m_flSampleRate = f;

	Msg(Fmt( "Interpolation sampling rate set to: %f\n", f ));
	PlaySound(SND_BUTTON);
}


// kf_auto_fill_boundaries
function SetAutoFillBoundaries( i = null )
{
	if ( m_bCompiling || m_bPreview )
		return MsgFail("Cannot change algorithm while compiling!\n");

	if ( i == null )
		i = !m_bAutoFillBoundaries;

	m_bAutoFillBoundaries = !!i;

	Msg(Fmt( "Auto fill boundaries : %d\n", m_bAutoFillBoundaries.tointeger() ));
	PlaySound(SND_BUTTON);
}

//--------------------------------------------------------------

// kf_compile
function Compile() : ( MAX_COORD_VEC, g_FrameTime )
{
	if ( m_bCompiling )
		return MsgFail("Compilation in progress...\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot compile while in playback!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( m_KeyFrames.len() < ( m_bAutoFillBoundaries ? 2 : 4 ) )
		return MsgFail(Fmt( "Not enough keyframes to compile. (Required minimum amount: %d)\n",
			( m_bAutoFillBoundaries ? 2 : 4 ) ));

	m_bCompiling = true;
	m_bDirty = false;
	m_pSquadErrors = null;

	// stop seeing
	SeeKeyframe(1);

	SetEditModeTemp( false );
	SendToConsole("clear_debug_overlays");
	SetHelperOrigin( MAX_COORD_VEC );

	Msg("\n");
	Msg("Preparing...\n");
	PlaySound(SND_BUTTON);

	return AddEvent( _Process.StartCompile, 0.1, _Process );
}


// Supports only 1 active thread at once
{
	_Process._thread <- null;

	function _Process::CreateThread( func, env = null ) : (newthread)
	{
		if ( _thread && (_thread.getstatus() != "idle") )
			Assert( 0, "Tried to create a thread while one was already running" );

		_thread = newthread( func.bindenv( env ? env : VS.GetCaller() ) );
	}

	function _Process::StartThread( ... )
	{
		switch ( vargc )
		{
			case 0: return _thread.call();
			case 1: return _thread.call( vargv[0] );
			case 2: return _thread.call( vargv[0], vargv[1] );
			case 3: return _thread.call( vargv[0], vargv[1], vargv[2] );
			case 4: return _thread.call( vargv[0], vargv[1], vargv[2], vargv[3] );
		}
	}

	function _Process::ThreadSleep( duration ) : (suspend)
	{
		suspend( AddEvent( ThreadResume, duration, this ) );
	}

	function _Process::ThreadResume()
	{
		if ( _thread.getstatus() == "suspended" )
		{
			_thread.wakeup();
		}
	}

	function _Process::ThreadIsSuspended()
	{
		return _thread.getstatus() == "suspended";
	}
}


function _Process::FillBoundariesRevert()
{
	// end
	m_KeyFrames.remove( m_KeyFrames.len() - 1 );

	// start
	m_KeyFrames.remove( 0 );
}

function _Process::FillBoundaries()
{
	local key, tmp0, tmp1;

	// end
	key = m_KeyFrames.top();
	tmp1 = keyframe_t();
	tmp1.Copy( key );
	ArrayAppend( m_KeyFrames, tmp1 );

	// start
	key = m_KeyFrames[0];
	tmp0 = keyframe_t();
	tmp0.Copy( key );
	m_KeyFrames.insert( 0, tmp0 );

	if ( m_nInterpolatorAngle == KF_INTERP_D3DX )
	{
		// HACKHACK: interpolator cannot interpolate identical angles
		tmp0.angles.x += 0.05;
		tmp0.angles.y += 0.05;
		tmp0.angles.z += 0.05;

		tmp1.angles.x += 0.05;
		tmp1.angles.y += 0.05;
		tmp1.angles.z += 0.05;

		tmp0.SetAngles( tmp0.angles );
		tmp1.SetAngles( tmp1.angles );
	};
}

// TODO: Implement consistent speed
function _Process::StartCompile() : ( g_FrameTime )
{
	if ( m_bAutoFillBoundaries )
	{
		FillBoundaries();
	};

	m_nSampleCount = ( (1.0 / m_flSampleRate) + KF_FLT_EPS ).tointeger();
	m_nDrawResolution = max( m_nSampleCount / 10, 1 );

	local count = m_KeyFrames.len() - 3;
	local size = count * m_nSampleCount;

	// init path
	m_PathData.clear();
	m_PathData.resize( size );
	for ( local i = 0; i < size; ++i )
	{
		m_PathData[i] = point_t();
	}

	Msg(Fmt( "Keyframe count  : %d\n", m_KeyFrames.len() ));
	Msg(Fmt( "Frame count     : %d\n", size ));
	Msg(Fmt( "Sample count    : %d\n", m_nSampleCount ));
	Msg(Fmt( "Sample rate     : %f\n", m_flSampleRate ));
	Msg(Fmt( "Angle interp    : %s\n", m_szInterpDescAngle ));
	Msg(Fmt( "Origin interp   : %s\n", m_szInterpDescOrigin ));
	Msg(Fmt( "Fill boundaries : %d\n\n", m_bAutoFillBoundaries.tointeger() ));

	Msg("Compiling");

	CreateThread( CompilePath );
	return AddEvent( StartThread, g_FrameTime, this );
}

function _Process::SplineOrigin( i, frac, out ) : ( g_InterpolatorMap )
{
	VS.Interpolator_CurveInterpolate( g_InterpolatorMap[ m_nInterpolatorOrigin ],
		m_KeyFrames[i-1].origin,
		m_KeyFrames[i].origin,
		m_KeyFrames[i+1].origin,
		m_KeyFrames[i+2].origin,
		frac,
		out );
}

function _Process::SplineAngles( i, frac, out )
{
	switch ( m_nInterpolatorAngle )
	{
		case KF_INTERP_D3DX:
		{
			local spline = Quaternion();

			local q0 = m_KeyFrames[i-1].orientation;
			local q1 = m_KeyFrames[i].orientation;
			local q2 = m_KeyFrames[i+1].orientation;
			local q3 = m_KeyFrames[i+2].orientation;

			local p1 = Quaternion();
			local p2 = Quaternion();
			local p3 = Quaternion();

			VS.QuaternionAlign( q0, q1, p1 );
			VS.QuaternionAlign( q1, q2, p2 );
			VS.QuaternionAlign( q2, q3, p3 );

			VS.QuaternionSquad(
				q0,
				p1,
				p2,
				p3,
				frac,
				spline );

			if ( spline.IsValid() )
			{
				VS.QuaternionAngles( spline, out );
			}
			// FIXME
			else
			{
				if ( !m_pSquadErrors )
				{
					m_pSquadErrors = [i];
				}
				else if ( m_pSquadErrors.top() != i )
				{
					ArrayAppend( m_pSquadErrors, i );
				};;

				VS.VectorCopy( m_KeyFrames[i+1].angles, out );
			};
			return;
		}
		case KF_INTERP_LINEAR_BLEND:
		case KF_INTERP_LINEAR:
		{
			local spline = Quaternion();
			VS.QuaternionSlerp(
				m_KeyFrames[i].orientation,
				m_KeyFrames[i+1].orientation,
				frac,
				spline );
			VS.QuaternionAngles( spline, out );
			return;
		}
		case KF_INTERP_CATMULL_ROM_DIR:
		{
			VS.Catmull_Rom_Spline(
				m_KeyFrames[i-1].forward,
				m_KeyFrames[i].forward,
				m_KeyFrames[i+1].forward,
				m_KeyFrames[i+2].forward,
				frac,
				out );
			VS.VectorAngles( out, out );
			return;
		}
		// TODO:
		// case KF_INTERP_AFX:
	}
}

function _Process::CompilePath() : ( g_FrameTime )
{
	local len = m_KeyFrames.len()-2;

	for ( local w,t,nSampleFrame,nKey = 1; nKey < len; ++nKey )
	{
		w = (nKey-1) * m_nSampleCount;
		for ( nSampleFrame = 0, t = 0.0; 1.0 - t > KF_FLT_EPS; ++nSampleFrame, t += m_flSampleRate )
		{
			local org = Vector();
			local ang = Vector();
			SplineOrigin( nKey, t, org );
			SplineAngles( nKey, t, ang );
			m_PathData[ w + nSampleFrame ].origin = org;
			m_PathData[ w + nSampleFrame ].angles = ang;
		}

		Msg(".");

		ThreadSleep( g_FrameTime );
	}

	if ( m_nInterpolatorAngle == KF_INTERP_LINEAR_BLEND )
	{
		Msg("|");
		// smooth twice?
		SmoothAngles( 10 );
		ThreadSleep( 0.1 );
		SmoothAngles( 10 );
		ThreadSleep( 0.1 );
	};

	CompileFOV();
	return AddEvent( FinishCompile, g_FrameTime, this );
}

function _Process::FinishCompile() : (g_FrameTime)
{
	if ( m_bAutoFillBoundaries )
	{
		FillBoundariesRevert();
	};

	// Assert compilation
	local c = m_PathData.len();
	for ( local i = 0; i < c; i++ )
	{
		if ( !m_PathData[i] )
		{
			Msg("\nNULL POINT! ["+i+" / "+c+"]\n");
			m_PathData.resize( i-1 );
			break;
		};
	}

	if ( m_pSquadErrors )
	{
		Msg( "\n\nERROR: Angle interp errors at keyframes:" );
		foreach( i in m_pSquadErrors )
			Msg(Fmt( "  %d-%d", i, i+1 ));
		Msg("\n");

		m_pSquadErrors = null;
	};

	if ( m_Selection[1] >= m_PathData.len() )
	{
		m_Selection[0] = m_Selection[1] = 0;
	};

	m_bCompiling = false;
	SetEditModeTemp( m_bInEditMode );

	Msg("\nCompilation complete.\n");
	Msg(Fmt( "Path length: %g seconds\n\n", m_PathData.len() * g_FrameTime ));
	PlaySound(SND_BUTTON);
}

function _Process::CompileFOV() : (g_FrameTime)
{
	// Compile only if there was no change to keyframes
	if ( m_bDirty )
		return;

	if ( !m_KeyFrames.len() )
		return;

	if ( !m_PathData.len() )
		return;

	// FOV data at keyframe 0 is invalid
	if ( m_KeyFrames[0].fov )
		m_KeyFrames[0].SetFov( 0 );

	// if keyframe 1 does not have an FOV value, set to 90
	// NOTE: this sets keyframe 0 as well when m_bAutoFillBoundaries is true
	if ( !m_KeyFrames[1].fov )
		m_KeyFrames[1].SetFov( 90 );

	local i = 0, c = m_KeyFrames.len()-1;
	local t = g_FrameTime / m_flSampleRate;

	while ( ++i < c )
	{
		// first fov key
		local f0 = m_KeyFrames[i];
		if ( !f0.fov )
			continue;

		// next fov key
		for ( local j = i+1; j < c; ++j )
		{
			local f1 = m_KeyFrames[j];
			if ( !f1.fov )
				continue;

			local rate = (j - i) * t;
			local frame = (i - 1) * m_nSampleCount;

			// not ready to compile
			if ( frame >= m_PathData.len() )
				break;

			local pt = m_PathData[ frame ];
			pt.fov = f1.fov;
			pt.fov_rate = rate;

			break;
		}
	}
}

function _Process::SmoothAngles( r ) : (g_FrameTime)
{
	local i, c;

	if ( m_Selection[0] && m_Selection[1] )
	{
		i = m_Selection[0];
		c = m_Selection[1];
	}
	else
	{
		i = 0;
		c = m_PathData.len();
	};

	local stack = [];
	for ( ; i < c; i++ )
	{
		if ( !(i % m_nSampleCount) )
		{
			Msg(".");
			ThreadSleep( g_FrameTime );
		};

		if ( stack.len() > r )
		{
			stack.remove(0);
		};

		local pt = m_PathData[i];

		local q = Quaternion();
		VS.AngleQuaternion( pt.angles, q );

		stack.append(q);

		local s = SmoothAnglesStack( stack );
		VS.QuaternionAngles( s, pt.angles );
	}
}

// Blend stack
function _Process::SmoothAnglesStack( stack )
{
	local c = stack.len();
	if ( !c )
		MsgFail("stack empty.\n");

	local out = Quaternion();

	if ( m_bSmoothExponential )
	{
		VS.QuaternionAverageExponential( out, c, stack )
	}
	else
	{
		local w = 1.0 / c;
		for ( local i = 0; i < c; i++ )
		{
			local t = stack[i];
			VS.QuaternionBlend( out, t, w, out );
		}
	};
	return out;
}

function _Process::SmoothOrigin( r ) : (g_FrameTime)
{
	local i, c;

	if ( m_Selection[0] && m_Selection[1] )
	{
		i = m_Selection[0] + r;
		c = m_Selection[1] - r;
	}
	else
	{
		i = r;
		c = m_PathData.len() - r;
	};

	local stack = [];
	for ( ; i < c; i++ )
	{
		if ( !(i % m_nSampleCount) )
		{
			Msg(".");
			ThreadSleep( g_FrameTime );
		};

		stack.clear();

		for ( local j = -r; j <= r; j++ )
		{
			stack.append( m_PathData[ i + j ].origin );
		}

		local s = SmoothOriginStack( stack );
		m_PathData[i].origin = s;
	}
}

// Blend stack
function _Process::SmoothOriginStack( stack )
{
	local c = stack.len();
	if ( !c )
		MsgFail("stack empty.\n");

	local w = 1.0 / c.tofloat();
	local out = Vector();

	for ( local i = 0; i < c; ++i )
	{
		local t = stack[i];
		VS.VectorAdd( out, t, out );
	}

	VS.VectorScale( out, w, out );

	return out;
}

function StopTransformLerp()
{
	m_pLerpTransform = null;
	m_flLerpTransformAnim = null;
	ToggleFrameThink( false );
}

function TransformKeyframes( pivot, vecOffset, vecAngle ) : (array, vec3_origin)
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	local vecPivot;

	if ( typeof pivot == "integer" )
	{
		// view origin
		if ( pivot == -2 )
		{
			vecPivot = Vector();
			VS.VectorCopy( CurrentViewOrigin(), vecPivot );
		}
		// average
		else if ( pivot == -1 )
		{
			local sum = Vector();
			local c = m_KeyFrames.len();
			for ( local i = 0; i < c; ++i )
			{
				VS.VectorAdd( m_KeyFrames[i].origin, sum, sum );
			}
			vecPivot = sum * ( 1.0 / c.tofloat() );
		}
		// keyframe index
		else
		{
			local c = m_KeyFrames.len();
			if ( (c < 0) || (pivot >= c) )
				return MsgFail("Invalid keyframe index.\n");

			vecPivot = Vector();
			VS.VectorCopy( m_KeyFrames[pivot].origin, vecPivot );
		};;
	}
	else
	{
		vecPivot = pivot;
	};

	if ( !vecOffset )
	{
		vecOffset = vec3_origin;
	};

	if ( !vecAngle )
	{
		vecAngle = vec3_origin;
	};

	if ( !(vecPivot instanceof Vector) ||
		!(vecOffset instanceof Vector) ||
		!(vecAngle instanceof Vector) )
		return MsgFail("Invalid input\n");

	PushUndo( "transform" );

	local matRotate = matrix3x4_t();
	VS.AngleMatrix( vecAngle, null, matRotate );

	local c = m_KeyFrames.len();

	m_pLerpTransform = array(c);
	m_flLerpTransformAnim = 0.0;

	for ( local i = 0; i < c; ++i )
	{
		local key = m_KeyFrames[i];

		local v = Vector();
		VS.VectorCopy( key.origin, v );
		m_pLerpTransform[i] = v;

		VS.MatrixSetColumn( key.origin - vecPivot, 3, key.transform );
		local tmp = clone key.transform;
		VS.ConcatTransforms( matRotate, tmp, key.transform );
		VS.MatrixGetColumn( key.transform, 3, key.origin );
		VS.MatrixSetColumn( key.origin + vecPivot + vecOffset, 3, key.transform );

		key.Update();
	}

	PushRedo( "transform" );

	m_bDirty = true;

	ToggleFrameThink( true );
	VS.EventQueue.CancelEventsByInput( StopTransformLerp );
	// animate it 5 times
	local t = 5 * 100 * FrameTime();
	VS.EventQueue.AddEvent( StopTransformLerp, t, this );

	DrawBox( vecPivot, Vector(-4,-4,-4), Vector(4,4,4), 255,255,255,255, t );
	PlaySound(SND_BUTTON);
}


local ThreadHelper = function( func, param, msg, exp = false )
{
	m_bCompiling = true;
	local t = m_bSmoothExponential;
	m_bSmoothExponential = exp;
	func( param );
	m_bSmoothExponential = t;
	Msg( msg );
	m_bCompiling = false;
}

// kf_smooth_origin
function SmoothOrigin( r = 4 ) : (ThreadHelper)
{
	if ( m_bCompiling )
		return MsgFail("Cannot smooth path while compiling!\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot smooth path while in playback!\n");

	if ( !m_PathData.len() )
		return MsgFail("No path found.\n");

	r = r.tointeger() / 2;

	if ( r < 2 )
		return MsgFail("Invalid input.\n");

	Msg(Fmt( "Smoothing origins... (%d) %s\n", r, m_bDirty ? " (dirty)" : "" ));
	PlaySound(SND_BUTTON);

	local msg;
	if ( m_Selection[0] && m_Selection[1] )
	{
		msg = Fmt( "\nSmooth origin done. [%d -> %d]\n", m_Selection[0], m_Selection[1] );
	}
	else
	{
		msg = "\nSmooth origin done.\n";
	};

	_Process.CreateThread( ThreadHelper, _Process );
	_Process.StartThread( _Process.SmoothOrigin, r, msg );
}

// kf_smooth_angles
// kf_smooth_angles_exp
function SmoothAngles( exp = 0, r = 10 ) : (ThreadHelper)
{
	if ( m_bCompiling )
		return MsgFail("Cannot smooth path while compiling!\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot smooth angles while in playback!\n");

	if ( !m_PathData.len() )
		return MsgFail("No path found.\n");

	r = r.tointeger();

	Msg(Fmt( "Smoothing angles... (%d) %s\n", r, m_bDirty ? " (dirty)" : "" ));
	PlaySound(SND_BUTTON);

	local msg;
	if ( m_Selection[0] && m_Selection[1] )
	{
		msg = Fmt( "\nSmooth angles done. [%d -> %d]", m_Selection[0], m_Selection[1] );
	}
	else
	{
		msg = "\nSmooth angles done.";
	};

	if ( exp )
	{
		msg += " (exponential)\n";
	}
	else
	{
		msg += "\n";
	};

	_Process.CreateThread( ThreadHelper, _Process );
	_Process.StartThread( _Process.SmoothAngles, r, msg, !!exp );
}


//--------------------------------------------------------------
//--------------------------------------------------------------

//--------------------------------------------------------------
// Save/load


//
// TODO:
//
{
	function IsValidCoord( f )
	{
		return ( f <= MAX_COORD_FLOAT ) && ( f >= -MAX_COORD_FLOAT );
	}

	function WriteCoord( v )
	{
		if ( VS.CloseEnough( v, 0.0, 1.e-5 ) )
		{
			return "0.00";
		}
		else
		{
			return Fmt( "%f", v );
		};
	}

	function ReadCoord( v )
	{
		return v;
	}
}

function WriteFrame( outKey )
{
	local origin = outKey.origin;
	local angles = outKey.angles;

	local tx = WriteCoord( origin.x );
	local ty = WriteCoord( origin.y );
	local tz = WriteCoord( origin.z );

	local rx = WriteCoord( angles.x );
	local ry = WriteCoord( angles.y );
	local rz = WriteCoord( angles.z );

	local n = 0x00;

	local fov = outKey.fov;
	if ( !fov )
	{
		return Fmt( "\t%d,%s,%s,%s,%s,%s,%s,\n", n,
			tx, ty, tz,
			rx, ry, rz );
	}
	else
	{
		return Fmt( "\t%d,%s,%s,%s,%s,%s,%s,%d,%s,\n", (n | 0x01),
			tx, ty, tz,
			rx, ry, rz,
			fov,
			("fov_rate" in outKey ? WriteCoord(outKey.fov_rate) : "0") );
	};
}

// returns index of next block to read
function ReadFrame( inKey, data, idx )
{
	local n = data[idx++];

	local tx = ReadCoord( data[idx]   );
	local ty = ReadCoord( data[idx+1] );
	local tz = ReadCoord( data[idx+2] );

	local rx = ReadCoord( data[idx+3] );
	local ry = ReadCoord( data[idx+4] );
	local rz = ReadCoord( data[idx+5] );

	inKey.SetOrigin( Vector( tx, ty, tz ) );
	inKey.SetAngles( Vector( rx, ry, rz ) );

	if ( n & 0x01 )
	{
		inKey.SetFov( data[idx+6], ReadCoord( data[idx+7] ) );
		return idx + 8;
	};
	return idx + 6;
}


const KF_DATA_TYPE_KEYFRAMES	= 1;;
const KF_DATA_TYPE_PATH			= 2;;

const KF_SAVE_V1				= 1;;
const KF_SAVE_V2				= 2;;

const KF_SAVE_VERSION			= 2;;

// kf_save, kf_savepath, kf_savekeys
function Save( i = null )
{
	if ( m_bCompiling )
		return MsgFail("Cannot save while compiling!\n");

	if ( m_bSaveInProgress )
		return MsgFail("A save is in progress!\n");

	if ( i == null )
	{
		Msg("No data type to save specified, defaulting to path data.\n");
		Msg("   Save compiled path data with 'kf_savepath'\n");
		Msg("   Save keyframe data with 'kf_savekeys'\n\n");
		i = KF_DATA_TYPE_PATH;
	};

	if ( i == KF_DATA_TYPE_PATH )
	{
		m_pSaveData = m_PathData.weakref();
	}
	else if ( i == KF_DATA_TYPE_KEYFRAMES )
	{
		m_pSaveData = m_KeyFrames.weakref();
	}
	else
	{
		return Error("Invalid save type\n");
	};;

	if ( !m_pSaveData.len() )
	{
		m_pSaveData = null;
		return MsgFail("Empty save data.\n");
	};

	m_nSaveType = i;
	m_bSaveInProgress = true;

	VS.Log.file_prefix = "scripts/vscripts/kf_data";
	VS.Log.enabled = true;
	VS.Log.export = true;
	VS.Log.filter = "L ";

	_Process.CreateThread( _Save.Process, _Save );
	_Process.StartThread();
}

function _Save::Process()
{
	_Process.ThreadSleep( 0.01 );

	VS.Log.Clear();

	Write();
	EndWrite();
}

function _Save::Write() : (g_FrameTime, g_szMapName)
{
	// header ---

	local header = array(6);
	header[2] = g_szMapName;
	header[3] = KF_SAVE_VERSION;
	header[4] = m_nSaveType;
	header[5] = m_pSaveData.len();

	if ( m_nSaveType == KF_DATA_TYPE_PATH )
	{
		header[1] = "l_%s <- { version = %i, type = %i, framecount = %i, frames =\n[\n";
	}
	else if ( m_nSaveType == KF_DATA_TYPE_KEYFRAMES )
	{
		header[1] = "lk_%s <- { version = %i, type = %i, framecount = %i, frames =\n[\n";
	};;

	Add( Fmt.acall(header) );

	// body ---

	local c = m_pSaveData.len();
	local sl = 0;

	for ( local i = 0; i < c; i++ )
	{
		Add( WriteFrame( m_pSaveData[i] ) );

		if ( ++sl >= 100 )
		{
			sl = 0;
			_Process.ThreadSleep( g_FrameTime );
		};
	}

	_Process.ThreadSleep( g_FrameTime );

	// tail ---

	// strip trailing separator ",\n"
	Add( VS.Log.Pop().slice( 0, -2 ) + "\n] }\n" );
}

function _Save::EndWrite()
{
	local file = VS.Log.Run( null, function()
	{
		m_bSaveInProgress = false;
		PlaySound( SND_EXPORT_SUCCESS );
	} );

	if ( file )
	{
		if ( m_nSaveType == KF_DATA_TYPE_PATH )
		{
			Msg(Fmt( "Path data is exported: /csgo/%s.log\n\n", file ));
		}
		else if ( m_nSaveType == KF_DATA_TYPE_KEYFRAMES )
		{
			Msg(Fmt( "Keyframe data is exported: /csgo/%s.log\n\n", file ));
		};;
	};
}


//--------------------------------------------------------------
//--------------------------------------------------------------


if ( !m_FileBuffer.parent )
{
	local m_LoadedDatas = m_LoadedDatas;
	local root = getroottable();
	local meta =
	{
		_newslot = function( k, v ) : ( root, m_LoadedDatas )
		{
			m_LoadedDatas.rawset( k, v );
			if ( k in root && root[k] )
			{
				// TODO: compare?
				k = k + "_01";
				Msg( "Conflicting data name, renaming to : " + k + "\n" );
			};
			root[k] <- v.weakref();
			Msg("\t~ Loaded: " + k + "\n");
		}
	}
	delegate meta : m_FileBuffer;
};

function LoadFile( msg = true )
{
	if (msg)
	{
		Msg("Loading file...\n")
	};

	try( DoIncludeScript( "keyframes_data", m_FileBuffer ) )
	catch(e)
	{
		return Error("Failed to load keyframes_data.nut file!\n");
	}

	if (msg)
	{
		Msg("...done.\n");
		PlaySound("Player.PickupGrenade");
	}
}

function LoadFileError()
{
	Msg("Use 'kf_loadfile' to reload the keyframes_data.nut file.\n");
	Msg("Use 'script kf_load( name )' to load a named data from the data file.\n");
	PlaySound("UIPanorama.buymenu_failure");
}


// TODO: cleanup
function _Load::LoadData( input = null ) : ( g_FrameTime, g_szMapName )
{
	if ( m_bCompiling )
		return MsgFail("Cannot load file while compiling!\n");

	// load prefix_mapname data by default
	if ( input == null )
	{
		input = "lk_" + g_szMapName;

		if ( !( input in m_LoadedDatas ) && !( input in getroottable() ) )
		{
			input = "l_" + g_szMapName;
		};
	};

	// convert string input to handle
	if ( typeof input == "string" )
	{
		if ( input in getroottable() )
		{
			input = getroottable()[input];
		}
		else if ( input in m_LoadedDatas )
		{
			input = m_LoadedDatas[input];
		}
		else
		{
			return MsgFail(Fmt( "Invalid input '%s' (does not exist)\n", input ));
		};;
	};

	if ( typeof input != "table" )
		return MsgFail("Invalid input. (invalid type <"+typeof input+">)\n");

	local datasize, framecount;

	if ( "version" in input )
	{
		m_nLoadVer = input.version;
		m_nLoadType = input.type;
		datasize = input.frames.len();
		framecount = input.framecount;
	}
	else
	{
		m_nLoadVer = KF_SAVE_V1;
	};

	if ( m_nLoadVer == KF_SAVE_V1 )
	{
		if ( !("pos" in input) || !("ang" in input) )
			return MsgFail("Invalid input.\n");

		if ( !input.pos.len() || !input.ang.len() )
			return MsgFail("Empty input.\n");

		if ( "anq" in input )
		{
			input.quat <- delete input.anq;
		};

		if ( "quat" in input )
		{
			if ( input.pos.len() != input.quat.len() )
				return Error("[ERROR] Corrupted data!\n");

			m_nLoadType = KF_DATA_TYPE_KEYFRAMES;
		}
		else
		{
			if ( input.pos.len() != input.ang.len() )
				return Error("[ERROR] Corrupted data!\n");

			m_nLoadType = KF_DATA_TYPE_PATH;
		};

		datasize = input.pos.len();
		framecount = datasize;
	};

	// data from the future?
	if ( m_nLoadVer > KF_SAVE_VERSION || m_nLoadVer < KF_SAVE_V1 )
		return MsgFail("Unrecognised data version!\n");

	if ( m_nLoadType == KF_DATA_TYPE_KEYFRAMES )
	{
		m_pLoadData = m_KeyFrames.weakref();
	}
	else if ( m_nLoadType == KF_DATA_TYPE_PATH )
	{
		m_pLoadData = m_PathData.weakref();
	}
	else
	{
		return MsgFail("Invalid data type!\n");
	};;


	PushUndo( "load" );

	m_pLoadData.clear();
	m_pLoadData.resize( framecount );
	m_pLoadInput = input.weakref();


	Msg("Preparing to load...\n");
	PlaySound(SND_BUTTON);
	Msg("\tversion     : " + m_nLoadVer + "\n");
	Msg("\ttype        : " + m_nLoadType + "\n");
	Msg("\tframe count : " + framecount + "\n");
	Msg("\tdata size   : " + datasize + "\n");

	Msg("Loading");

	SetEditModeTemp( false );

	_Process.CreateThread( LoadInternal, this );
	_Process.StartThread();
}


local NewFrame = function()
{
	if ( m_nLoadType == KF_DATA_TYPE_KEYFRAMES )
	{
		return keyframe_t();
	}
	else if ( m_nLoadType == KF_DATA_TYPE_PATH )
	{
		return point_t();
	}
}

function _Load::LoadInternal() : ( g_FrameTime, NewFrame )
{
	Msg(".");
	local sl = 0;

	if ( m_nLoadVer == KF_SAVE_V2 )
	{
		local data = m_pLoadInput.frames;
		local c = data.len();
		local frame = 0;

		for ( local i = 0; i < c; )
		{
			local p = NewFrame();
			m_pLoadData[ frame++ ] = p;
			i = ReadFrame( p, data, i );

			if ( ++sl >= 100 )
			{
				Msg(".");
				sl = 0;
				_Process.ThreadSleep( g_FrameTime );
			};
		}

		_Process.ThreadSleep( g_FrameTime );

		return LoadFinishInternal();
	}

	else if ( m_nLoadVer == KF_SAVE_V1 )
	{
		local rotGet, rotSet;

		if ( m_nLoadType == KF_DATA_TYPE_KEYFRAMES )
		{
			rotGet = "quat";
			rotSet = "SetQuaternion";
		}
		else if ( m_nLoadType == KF_DATA_TYPE_PATH )
		{
			rotGet = "ang";
			rotSet = "SetAngles";
		};;

		local c = m_pLoadInput.pos.len();

		for ( local i = 0; i < c; ++i )
		{
			local org = m_pLoadInput.pos[i];
			local rot = m_pLoadInput[rotGet][i];

			local p = NewFrame();
			m_pLoadData[i] = p;

			p.SetOrigin( org );
			p[rotSet]( rot );

			if ( ++sl >= 100 )
			{
				Msg(".");
				sl = 0;
				_Process.ThreadSleep( g_FrameTime );
			};
		}

		_Process.ThreadSleep( g_FrameTime );

		if ( "fov" in m_pLoadInput )
		{
			foreach( i, a in m_pLoadInput.fov )
			{
				local idx = a[0];
				if ( !( idx in m_pLoadData ) )
				{
					Msg("Corrupted FOV data: invalid index!\n");
					continue;
				};
				m_pLoadData[idx].SetFov( a[1], a[2] );
			}
		};

		_Process.ThreadSleep( g_FrameTime );

		return LoadFinishInternal();
	}
	else
	{
		Assert(0, "V");
	};;
}

function LoadFinishInternal() : ( g_FrameTime )
{
	// Assert
	local c = m_pLoadData.len();
	for ( local i = 0; i < c; i++ )
	{
		if ( !m_pLoadData[i] )
		{
			Msg("\n\nNULL POINT! ["+i+" / "+c+"]\n");
			Msg("Corrupt data?\n");
			m_pLoadData.resize( i-1 );
			break;
		};
	}

	local szInput = VS.GetVarName( m_pLoadInput );

	PlaySound(SND_BUTTON);
	Msg(Fmt( "\nLoading complete! \"%s\" ( %s )\n",
		szInput,
		(
			( m_nLoadType & KF_DATA_TYPE_PATH ) ?
			m_PathData.len() * g_FrameTime + " seconds" :
			m_KeyFrames.len() + " keyframes"
		)
	));

	if ( szInput in m_LoadedDatas )
		delete m_LoadedDatas[szInput];

	if ( szInput in getroottable() )
		delete getroottable()[szInput];;

	PushRedo( "load" );

	SetEditModeTemp( m_bInEditMode );
}


//--------------------------------------------------------------
//--------------------------------------------------------------


VS.OnTimer( m_hThinkCam, function() : ( m_hCam, m_PathData )
{
	if ( !m_bPreview )
	{
		local pt = m_PathData[m_nPlaybackIdx];
		m_hCam.SetOrigin( pt.origin );

		local a = pt.angles;
		m_hCam.SetAngles( a.x, a.y, a.z );

		// NOTE: This is here for external effects that may use player angles (such as flashbangs)
		player.SetAngles( a.x, a.y, 0 );

		if ( pt.fov )
			m_hCam.SetFov( pt.fov, pt.fov_rate );

		if ( m_nPlaybackTarget <= ++m_nPlaybackIdx )
		{
			if ( m_bPlaybackLoop )
			{
				if ( m_Selection[0] && m_Selection[0] )
				{
					m_nPlaybackIdx = m_Selection[0];
				}
				else
				{
					m_nPlaybackIdx = 0;
				};
			}
			else
			{
				return Stop();
			};
		};
	}
	else
	{
		local pos = Vector();
		local ang = Vector();
		_Process.SplineOrigin( m_nPlaybackIdx, m_flPreviewFrac, pos );
		_Process.SplineAngles( m_nPlaybackIdx, m_flPreviewFrac, ang );

		// local fr = ((m_nPlaybackIdx-1) * m_nSampleCount) + ( (m_flPreviewFrac / m_flSampleRate) + KF_FLT_EPS ).tointeger();

		m_hCam.SetOrigin( pos );
		m_hCam.SetAngles( ang.x, ang.y, ang.z );

		// HACKHACK: set player angles as well to get the correct angle in CurrentViewAngles in edit mode
		player.SetAngles( ang.x, ang.y, 0 );

		m_flPreviewFrac += m_flSampleRate;

		if ( 1.0 - m_flPreviewFrac <= KF_FLT_EPS )
		{
			m_flPreviewFrac = 0.0;

			if ( m_nPlaybackTarget <= ++m_nPlaybackIdx )
				return Stop();
		};
	};

}, this );


// 0 : kf_play
// 2 : kf_play_loop
// 1 : kf_preview
function Play( type = 0 )
{
	if ( m_bCompiling )
		return MsgFail("Cannot start playback while compiling!\n");

	if ( m_bPlaybackPending )
		return MsgFail("Playback has not started yet!\n");

	if ( m_bInPlayback )
		return MsgFail("Playback is already running.\n");

	// unsee
	if ( m_bSeeing )
		SeeKeyframe(1);

	if ( ((type == 0) || (type == 2)) && !m_PathData.len() )
		return MsgFail("No compiled data found.\n");

	if ( (type == 1) && !m_KeyFrames.len() )
		return MsgFail("No keyframe data found.\n");

	if ( developer() > 1 )
	{
		Msg("Setting developer level to 1\n");
		SendToConsole("developer 1");
	};

	if ( ((type == 0) || (type == 2)) && m_bDirty )
	{
		Msg("Playing back outdated path; compile to see changes, or use kf_preview\n");
	};

	m_bPlaybackLoop = type == 2;
	m_bPreview = type == 1;
	local ang;

	if ( m_bPlaybackLoop )
	{
		Msg("loop\n");
	};

	if ( (type == 0) || (type == 2) )
	{
		if ( m_Selection[0] && m_Selection[0] )
		{
			m_nPlaybackTarget = m_Selection[1];
			m_nPlaybackIdx = m_Selection[0];

			Msg(Fmt( "selection [%d -> %d]\n", m_Selection[0], m_Selection[1] ));
		}
		else
		{
			m_nPlaybackTarget = m_PathData.len();
			m_nPlaybackIdx = 0;

			local firstkey = m_KeyFrames[1];
			if ( firstkey.fov )
				CameraSetFov( firstkey.fov, 0 );
		};

		local firstpt = m_PathData[m_nPlaybackIdx];
		CameraSetOrigin( firstpt.origin );
		CameraSetAngles( firstpt.angles );

		ang = firstpt.angles;
	}
	else
	{
		Msg("preview mode\n");

		if ( m_bAutoFillBoundaries )
		{
			_Process.FillBoundaries();
		};

		m_nPlaybackTarget = m_KeyFrames.len() - 2;
		m_nPlaybackIdx = 1;
		m_flPreviewFrac = 0.0;

		local pos = Vector();
		ang = Vector();
		_Process.SplineOrigin( m_nPlaybackIdx, m_flPreviewFrac, pos );
		_Process.SplineAngles( m_nPlaybackIdx, m_flPreviewFrac, ang );

		CameraSetOrigin( pos );
		CameraSetAngles( ang );
	};

	// HACKHACK: set player angles as well to get the correct angle in CurrentViewAngles in edit mode
	local curang = MainViewAngles();
	m_AnglesRestore = [ player, curang.x, curang.y, 0 ];
	player.SetAngles( ang.x, ang.y, 0 );

	CameraSetEnabled( true );
	CameraSetThink( false );

	MsgHint("Starting in 3...\n");
	PlaySound("UI.CounterBeep");

	AddEvent( MsgHint,   1.0, [this, "Starting in 2...\n"] );
	AddEvent( PlaySound, 1.0, [this, "UI.CounterBeep"]   );

	AddEvent( MsgHint,   2.0, [this, "Starting in 1...\n"] );
	AddEvent( PlaySound, 2.0, [this, "UI.CounterBeep"]   );

	player.SetHealth(1337);
	HideHudHint( 3.0 );

	m_bPlaybackPending = true;
	AddEvent( _Play, 3.0, this );
}

function _Play()
{
	m_bPlaybackPending = false;
	m_bInPlayback = true;
	Msg("Playback has started...\n\n");
	CameraSetThink( true );
}

// kf_stop
function Stop() : (g_FrameTime)
{
	if ( m_bPlaybackPending )
	{
		m_bPlaybackPending = false;
		VS.EventQueue.CancelEventsByInput( _Play );
		VS.EventQueue.CancelEventsByInput( MsgHint );
		VS.EventQueue.CancelEventsByInput( PlaySound );
		HideHudHint();
	}
	else if ( !m_bInPlayback )
		return MsgFail("Playback is not running.\n");;

	if ( !m_bPreview )
	{
		Msg(Fmt( "Playback has ended.\n" ));
	}
	else
	{
		Msg("Preview has ended.\n");
	};

	if ( m_bPreview )
	{
		if ( m_bAutoFillBoundaries )
		{
			_Process.FillBoundariesRevert();
		};
	};

	m_bInPlayback = false;
	m_bPreview = false;

	CameraSetEnabled( false );
	CameraSetThink( false );

	CameraSetFov(0,0);

	VS.EventQueue.AddEvent( CBaseEntity.SetAngles, 0.025, m_AnglesRestore );

	SetEditModeTemp( m_bInEditMode );

	PlaySound("UI.RankDown");
}


//--------------------------------------------------------------


function SetKeyframeFOV( input )
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to add new FOV data.\n");

	input = input.tointeger();

	// refresh
	if ( m_bSeeing )
		CameraSetFov( input, 0.25 );

	local key = m_KeyFrames[ m_nCurKeyframe ];
	key.SetFov( input );

	CompileFOV();

	MsgHint(Fmt( "Set keyframe #%d FOV to %d\n", m_nCurKeyframe, input ));
	PlaySound(SND_BUTTON);
}

function SetKeyframeRoll( input )
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_bInEditMode )
		return MsgFail("You need to be in edit mode to use camera roll.\n");

	PushUndo( "roll" );

	input = VS.AngleNormalize( input.tofloat() );

	local key = m_KeyFrames[ m_nCurKeyframe ];
	key.angles.z = input;
	key.SetAngles( key.angles );

	PushRedo( "roll" );

	// refresh
	if ( m_bSeeing )
	{
		if ( m_nSelectedKeyframe == -1 )
			return Error("[ERROR] Assertion failed. Seeing while no keyframe is selected.\n");

		CameraSetAngles( key.angles );
	};

	MsgHint(Fmt( "Set keyframe #%d roll to %g\n", m_nCurKeyframe, input ));
	PlaySound(SND_BUTTON);
}

function Trim( flInputLen, bDirection = 1 ) : ( g_FrameTime )
{
	if ( m_bCompiling )
		return MsgFail("Cannot trim while compiling!\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot trim while in playback!\n");

	if ( !m_PathData.len() )
		return MsgFail("No compiled data found.\n");

	flInputLen = max( 0, flInputLen.tofloat() );

	local flCurLen = m_PathData.len() * g_FrameTime;

	if ( flInputLen > flCurLen )
		return MsgFail("Trim value larger than current length!\n");

	local nFramesToRemove = ( m_PathData.len() - ( flInputLen / g_FrameTime ) ).tointeger();
	if ( nFramesToRemove <= 0 )
		return MsgFail("No data to trim.\n");

	if ( !m_TrimData )
	{
		m_TrimData = [];
	};

	m_bTrimDirection = !!bDirection;

	if ( m_bTrimDirection )
	{
		for ( local i = nFramesToRemove; i--; )
		{
			ArrayAppend( m_TrimData, m_PathData.pop() );
		}

		m_TrimData.reverse();
	}
	else
	{
		for ( local i = nFramesToRemove; i--; )
		{
			ArrayAppend( m_TrimData, m_PathData.remove(0) );
		}
	};

	Msg(Fmt( "Trimmed: %g -> %g\n", flCurLen, m_PathData.len() * g_FrameTime ));
	PlaySound(SND_BUTTON);
}

function UndoTrim() : ( g_FrameTime )
{
	if ( m_bCompiling )
		return MsgFail("Cannot undo trim while compiling!\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot undo trim while in playback!\n");

	if ( !m_TrimData || !m_TrimData.len() )
		return MsgFail("No trimmed data found.\n");

	local flCurLen = m_PathData.len() * g_FrameTime;

	if ( m_bTrimDirection )
	{
		for ( local i = 0; i < m_TrimData.len(); ++i )
		{
			ArrayAppend( m_PathData, m_TrimData[i] );
		}
	}
	else
	{
		for ( local i = 0; i < m_TrimData.len(); ++i )
		{
			m_PathData.insert( i, m_TrimData[i] );
		}
	};

	m_TrimData.clear();

	Msg(Fmt( "Undone trim: %g -> %g\n", flCurLen, m_PathData.len() * g_FrameTime ));
	PlaySound(SND_BUTTON);
}

CompileFOV <- _Process.CompileFOV.bindenv(_Process);

// global bindings for easy use with 'script kf_XX()'
::kf_roll <- SetKeyframeRoll.bindenv(this);
::kf_fov <- SetKeyframeFOV.bindenv(this);
::kf_res <- SetSamplingRate.bindenv(this);
::kf_load <- _Load.LoadData.bindenv(_Load);
::kf_trim <- Trim.bindenv(this);
::kf_transform <- TransformKeyframes.bindenv(this);


//--------------------------------------------------------------
//--------------------------------------------------------------


function PostSpawn() : (MAX_COORD_VEC)
{
	if ( player.GetTeam() != 2 && player.GetTeam() != 3 )
		player.SetTeam(2);

	PlaySound("Player.DrownStart");
	player.SetHealth(1337);

	// key listener
	EntFireByHandle( m_hListener, "Activate", "", 0, player );

	ListenMouse(1);
	SetAngleInterp( m_nInterpolatorAngle );
	SetOriginInterp( m_nInterpolatorOrigin );
	SetEditMode( m_bInEditMode );
	SetHelperOrigin( MAX_COORD_VEC );

	for ( local i = 18; i--; ) Chat(" ");
	Chat(txt.blue+" --------------------------------");
	Chat("");
	Chat(Fmt( "%s[Keyframes Script v%s]", txt.lightgreen, _VER_ ));
	Chat(Fmt( "%skf_cmd%s : Print all commands", txt.white, txt.orange ));
	Chat("");
	Chat(txt.blue+" --------------------------------");

	// print after Steamworks Msg
	if ( GetDeveloperLevel() > 0 )
	{
		AddEvent( SendToConsole, 0.75, [null, "clear;script _KF_.WelcomeMsg()"] );
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

	local tr = 1.0/FrameTime();

	if ( !VS.IsInteger( 128.0 / tr ) )
	{
		Msg(Fmt( "[!] Invalid tickrate (%g)! Only 128 and 64 tickrates are supported.\n", tr ));
		Chat(Fmt( "%s[!] %sInvalid tickrate ( %s%g%s )! Only 128 and 64 tickrates are supported.", txt.red, txt.white, txt.yellow, tr, txt.white ));
	};

	delete WelcomeMsg;

	LoadFile(false);
}

// kf_cmd
function PrintCmd()
{
	Msg("\n");
	Msg(Fmt( "   [v%s]     github.com/samisalreadytaken/keyframes\n", _VER_ ));
	Msg("\n");
	Msg("kf_add                  : Add new keyframe\n");
	Msg("kf_remove               : Remove the selected keyframe\n");
	Msg("kf_removefov            : Remove the FOV data from the selected keyframe\n");
	Msg("kf_clear                : Remove all keyframes\n");
	Msg("kf_insert               : Insert new keyframe before the selected keyframe\n");
	Msg("kf_replace              : Replace the current keyframe\n");
	Msg("kf_copy                 : Set player pos/ang to the current keyframe\n");
	Msg("kf_undo                 : Undo last keyframe modify action\n");
	Msg("kf_redo                 : Redo	\n");
	Msg("kf_undo_history         : Show undo history\n");
	Msg("                        :\n");
	Msg("kf_compile              : Compile the keyframe data\n");
	Msg("kf_smooth_angles        : Smooth compiled path angles\n");
	Msg("kf_smooth_angles_exp    : Smooth compiled path angles exponentially\n");
	Msg("kf_smooth_origin        : Smooth compiled path origin\n");
	Msg("kf_play                 : Play the compiled data\n");
	Msg("kf_play_loop            : Play the compiled data looped\n");
	Msg("kf_preview              : Play the keyframe data without compiling\n");
	Msg("kf_stop                 : Stop playback\n");
	Msg("kf_savepath             : Export the compiled data\n");
	Msg("kf_savekeys             : Export the keyframe data\n");
	Msg("                        :\n");
	Msg("kf_mode_angles          : Cycle through angle interpolation types\n");
	Msg("kf_mode_origin          : Cycle through position interpolation types\n");
	Msg("kf_auto_fill_boundaries : Duplicate the first and last keyframes in compilation\n");
	Msg("                        :\n");
	Msg("kf_edit                 : Toggle edit mode\n");
	Msg("kf_translate            : Toggle 3D translation manipulator\n");
	Msg("kf_select_path          : In edit mode, select path\n");
	Msg("kf_see                  : In edit mode, see the current selection\n");
	Msg("kf_next                 : While holding a keyframe, select the next one\n");
	Msg("kf_prev                 : While holding a keyframe, select the previous one\n");
	Msg("kf_showkeys             : In edit mode, toggle showing keyframes\n");
	Msg("kf_showpath             : In edit mode, toggle showing the path\n");
	Msg("                        :\n");
	Msg("script kf_fov(val)      : Set FOV data on the selected keyframe\n");
	Msg("script kf_roll(val)     : Set camera roll on the selected keyframe\n");
	Msg("script kf_res(val)      : Set interpolation sampling rate\n");
	Msg("                        :\n");
	Msg("script kf_transform()   : Rotate all keyframes around key with optional translation offset (idx,offset,rotation)\n");
	Msg("                        :\n");
	Msg("kf_loadfile             : Load data file\n");
	Msg("script kf_load(input)   : Load new data from file\n");
	Msg("script kf_trim(val)     : Trim compiled path to specified length\n");
	Msg("kf_trim_undo            : Undo last trim action\n");
	Msg("                        :\n");
	Msg("kf_cmd                  : List all commands\n");
	Msg("\n");
	Msg("--- --- --- --- --- ---\n");
	Msg("\n");
	Msg("MOUSE1                  : kf_add\n");
	Msg("MOUSE2                  : kf_remove\n");
	Msg("E                       : kf_see\n");
	Msg("A / D                   : (In see mode) Set camera roll\n");
	Msg("W / S                   : (In see mode) Set camera FOV\n");
	Msg("MOUSE1                  : (In see mode) kf_next\n");
	Msg("MOUSE2                  : (In see mode) kf_prev\n");
	Msg("\n");
}

}.call(_KF_);
