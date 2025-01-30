//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//                       github.com/samisalreadytaken
//-----------------------------------------------------------------------
local VERSION = "1.3.2";


//
// mapbase compatibility
//
// Apart from the regex replacement (from vs_math), missing global aliases and vs_library functions below,
// changes to the code below include:
//
// - Replacing CBaseEntity::SetAngles() with SetEntityAngles() (mapbase takes Vector, CSGO takes x,y,z)
// - Replacing timer entity "nextthink" toggle with CBaseEntity::AcceptInput() (to suppress debug build assertions)
// - Removal of m_bDuckFixup (HL2 player view does not change while in noclip and crouched)
// - Change to kViewOffset and kCrouchViewOffset (HL2 offsets differ from CSGO)
// - Replacing IsDucking() hull size check with +duck command hook (button check is not good beacuse it's often not cancelled while in noclip)
// - Removal of 'threaded' funcs - letting the game freeze during compilation
// - Minor changes to _Save::Write() to support save/load
//

	IncludeScript("vs_math");

	local matrix3x4_t = VS.matrix3x4_t;
	local Quaternion = VS.Quaternion;
	local VMatrix = VS.VMatrix;
	local Ray_t = VS.Ray_t;
	local FrameTime = IntervalPerTick;

	DebugDrawLine <- debugoverlay.Line.bindenv(debugoverlay);
	DebugDrawBox <- debugoverlay.Box.bindenv(debugoverlay);
	DebugDrawBoxAngles <- debugoverlay.BoxAngles.bindenv(debugoverlay);
	PrecacheScriptSound <- function(s) { return Entities.First().PrecacheSoundScript(s); }
	GetDeveloperLevel <- developer <- function() { return Convars.GetInt("developer"); }
	Assert <- assert;

	function SetEntityAngles( p, v )
	{
		return p.SetAngles( v );
	}

	VS.EventQueue <-
	{
		m_Events = {}

		CancelEventsByInput = function( fn )
		{
			if ( fn in m_Events )
			{
				local id = m_Events[fn];
				player.SetContextThink( id, null, 0.0 );
			}
		}

		AddEvent = function( fn, delay, env )
		{
			local id = DoUniqueString("");
			m_Events[fn] <- id;

			if ( typeof env == "array" )
			{
				player.SetContextThink( id, function(self){ fn.acall(env) }, delay );
			}
			else
			{
				player.SetContextThink( id, function(self){ fn.call(env) }, delay );
			}
		}
	}

	class VS.TraceLine
	{
		endpos = null;
		normal = null;
		constructor( start, end, ent, mask )
		{
			local tr = TraceLineComplex( start, end, ent, mask, 0 );
			endpos = tr.EndPos();
			normal = tr.Plane().normal;
			tr.Destroy();
		}
		function GetPos() { return endpos; }
		function GetNormal() { return normal; }
	}

	function VS::CreateEntity( sz, kv, _ = null )
	{
		if ( !kv )
			kv = {};
		return SpawnEntityFromTable( sz, kv );
	}

	function VS::CreateTimer( bDisabled, flInterval, flLower = null, flUpper = null, bOscillator = false, bMakePersistent = false )
	{
		local ent = CreateEntity( "logic_timer", null, bMakePersistent );
		if ( flInterval != null )
		{
			ent.__KeyValueFromInt( "UseRandomTime", 0 );
			ent.__KeyValueFromFloat( "RefireTime", flInterval.tofloat() );
		}
		else Assert(0);
		EntFireByHandle( ent, bDisabled ? "Disable" : "Enable", "", 0.0, null, null );
		return ent;
	}

	function VS::OnTimer( hEnt, Func, scope )
	{
		Assert( typeof Func == "function" );

		hEnt.ValidateScriptScope();
		hEnt.GetScriptScope()["OnTimer"] <- Func.bindenv( scope );
		return hEnt.ConnectOutput( "OnTimer", "OnTimer" );
	}

	function VS::SetInputCallback( player, cmd, fn, ctx )
	{
		Convars.RegisterCommand( cmd, function(...) { fn(null); return true; }, "", 0 );
	}

	local s_ExtendedPlayer;
	function VS::ToExtendedPlayer( pl )
	{
		if ( s_ExtendedPlayer )
			return s_ExtendedPlayer;

		s_ExtendedPlayer =
		{
			self = pl
			EyeForward = pl.GetEyeForward.bindenv(pl)
			EyeRight = pl.GetEyeRight.bindenv(pl)
			EyeUp = pl.GetEyeUp.bindenv(pl)
		}

		foreach ( k, v in pl.getclass() )
			s_ExtendedPlayer[k] <- v.bindenv(pl);

		s_ExtendedPlayer.SetAngles = function(x,y,z){ return SetAngles(::Vector(x,y,z)) }.bindenv(pl);

		return s_ExtendedPlayer;
	}

	ToExtendedPlayer <- VS.ToExtendedPlayer;
	VS.GetPlayerByIndex <- EntIndexToHScript;

	// default binds
	Convars.RegisterCommand( "phys_swap", function(...){ SendToConsole("+kf_g;-kf_g") }, "", 0 )
	Convars.RegisterCommand( "+reload", function(...){ SendToConsole("+kf_r") }, "", 0 )
	Convars.RegisterCommand( "-reload", function(...){ SendToConsole("-kf_r") }, "", 0 )
	Convars.RegisterCommand( "impulse", function(...)
	{
		if ( vargv[1] == "100" )
		{
			SendToConsole("+kf_f;-kf_f")
			return;
		}
		return true;
	}, "", 0 )

	Convars.RegisterCommand( "+duck", function(...) { _KF_.in_duck = true }, "", 0 )
	Convars.RegisterCommand( "-duck", function(...) { _KF_.in_duck = false }, "", 0 )

//
//--------------------------------------------------------------
//--------------------------------------------------------------
//

if ( !("_KF_" in getroottable()) )
	::_KF_ <- { version = "" };;

_KF_.version = VERSION;

local _ = function(){

//
// Wrappers to make sq3 port simpler
//

function SetDelegate( _this, _that )
{
	return _this.setdelegate(_that);
}

function GetDelegate( _this )
{
	return _this.getdelegate();
}

function SetThinkEnabled( ent, state )
{
	return ent.AcceptInput( state ? "Enable" : "Disable", "", null, null );
}

//--------------------------------------------------------------

print("loading... (1)\n");

const KF_CB_CONTEXT = "KEYFRAMES";;

// prevent OOB access `closure->_defaultparams[(uint32)-1]`
const KF_NOPARAM = 0xfffffac7;


const MOVETYPE_NOCLIP = 8;
const MOVETYPE_OBSERVER = 10;
const MOVETYPE_NONE = 0;

const KF_SAMPLE_COUNT_DEFAULT = 100;


const KF_INTERP_CATMULL_ROM			= 0;;
const KF_INTERP_CATMULL_ROM_NORM	= 1;;
const KF_INTERP_CATMULL_ROM_DIR		= 2;;
const KF_INTERP_LINEAR				= 3;;
const KF_INTERP_LINEAR_BLEND		= 4;;
const KF_INTERP_D3DX				= 5;;
const KF_INTERP_BSPLINE				= 6;;
const KF_INTERP_SIMPLE_CUBIC		= 7;;

const KF_INTERP_COUNT				= 8;;


const kViewOffset = 64.0;
const kCrouchViewOffset = 32.0;

if ( !("vec3_origin" in this) || !VS.VectorIsZero(vec3_origin) )
{
	vec3_origin <- Vector();
	//vec3_invalid <- ConstVector( FLT_MAX, FLT_MAX, FLT_MAX );
}

if ( !("player" in this) )
{
	player <- null;

	g_FrameTime <- 1.0 / 64.0;
	g_szMapName <- split( GetMapName(), "/" ).top().tolower();

	SND_BUTTON					<- "UIPanorama.container_countdown";
	SND_EXPORT_SUCCESS			<- "Survival.TabletUpgradeSuccess";
	SND_ERROR					<- "Bot.Stuck2";
	SND_FAILURE					<- "UIPanorama.buymenu_failure";
	SND_TICKER					<- "UIPanorama.store_item_rollover";
	SND_FILE_LOAD_SUCCESS		<- "Player.PickupGrenade";
	SND_MANIPULATOR_MOVED		<- "UI.StickerSelect";
	SND_MANIPULATOR_MOUSEOVER	<- "UI.PageScroll";
	SND_COUNTDOWN_BEEP			<- "UI.CounterBeep";
	SND_PLAY_END				<- "UI.RankDown";
	SND_SPAWN					<- "Player.DrownStart";

	m_KeyInputDown <- {}
	m_KeyInputUp <- {}

	// HACKHACK: Instead of rewriting the whole script to support multiple elements, this
	// flag is used to separate actions from targeting the camera keyframes and other elements (i.e. lights).
	m_bCameraTimeline <- true;

	m_Elements <- [];
	m_nCurElement <- -1;
	g_nShadowLightCount <- 0;

	m_KeyFrames <- [];
	m_PathData <- "";
	m_PathList <- {}
	m_TrimData <- null;
	m_pSaveData <- null;
	m_pLoadData <- null;
	m_pLoadInput <- null;
	m_szLoadInputName <- null;
	m_pUndoLoad <- null;
	m_pUndoTransform <- null;

	m_szCurPath <- null;

	m_nSaveType <- 0;
	m_nLoadType <- 0;
	m_nLoadVer <- 0;
	m_bSaveInProgress <- false;
	m_bLoadInProgress <- false;

	m_LoadedData <- {}
	m_FileBuffer <-
	{
		// for b/w compat
		V = Vector,
		Q = Quaternion
	}

	m_UndoStack <- [];
	m_nUndoLevel <- 0;
	m_nMaxUndoDepth <- 256;

	m_bDirty <- false;
	m_bCompiling <- false;
	m_bInPlayback <- false;
	m_bInEditMode <- !KF_OBSERVER_MODE;
	m_bPlaybackPending <- false;
	m_bPlaybackLoop <- false;
	m_bTrimDirection <- true;
	m_bSmoothExponential <- false;
	m_pSquadErrors <- null;
	m_AnglesRestore <- null;
	m_OriginRestore <- null;
	m_bPositionRestore <- !KF_OBSERVER_MODE;

	m_PathSelection <- [0,0];
	m_nCurPathSelection <- 0;
	m_fPathSelection <- 0;

	m_nInterpolatorAngle <- null;
	m_nInterpolatorOrigin <- null;
	m_szInterpDescAngle <- null;
	m_szInterpDescOrigin <- null;

	m_bAutoFillBoundaries <- false;

	{
		m_nMouseOver <- 0;
		m_bGizmoEnabled <- false;
		m_bMouse1Down <- false;
		m_bMouse2Down <- false;
		m_bMouseForceUp <- false;
		m_nManipulatorSelection <- 0;
		m_nManipulatorMode <- 0;
		m_nPrevManipulatorMode <- 0;
		m_bGlobalTransform <- false;
		m_bDuckFixup <- false;

		m_vecLastForwardFrame <- null;
		m_vecCameraOffset <- null; // camera fixup for crouched player state
		m_vecTranslationOffset <- null;
		m_vecLastKeyOrigin <- Vector(); // for translation diff display
		m_vecLastForward <- null;
		m_vecInitialForward <- null;
		m_vecCameraPivotPoint <- null;

		m_vecLastViewAngles <- null;
		m_matLastTransform <- null;
	}

	m_vecLastForward <- null;
	m_vecLastViewAngles <- null;

	m_nSelectedKeyframe <- -1;
	m_nCurKeyframe <- -1;
	m_nPlaybackIdx <- -1;
	m_nPlaybackTarget <- -1;

	m_bPreview <- false;
	m_flPreviewFrac <- 0.0;

	m_bShowPath <- true;
	m_bShowKeys <- true;
	m_bSeeing <- false;
	m_bReplaceOnClick <- false;
	m_bInsertOnClick <- false;

	m_bCameraGuides <- false;
	m_flWindowAspectRatio <- 16.0 / 9.0;

	in_duck <- false;
	in_moveup <- false;
	in_movedown <- false;
	in_forward <- false;
	in_back <- false;
	// in_moveleft <- false;
	// in_moveright <- false;
	// in_zoom <- false;
	in_rotate <- false;
	in_pan <- false;

	m_flLastFOV <- 90;
	m_vecLastAngles <- null;

	m_nAnimKeyframeTime <- 0.0;
	m_nAnimKeyframeIdx <- -1;
	m_nAnimPathIdx <- 0;

	m_pLerpTransform <- null;
	m_flLerpTransformAnim <- null;

	m_pLerpFrustum <- null;
	m_hLerpKeyframe <- null;
	m_flLerpKeyAnim <- null;

	m_nPathInitialFOV <- 0;

	m_bObserver <- KF_OBSERVER_MODE;
	m_nMoveTypeRoam <- -1;

	print <- print;
	m_pszMsgBuf <- [];

	function _MsgBuf(s)
	{
		return m_pszMsgBuf.append( s );
	}

	function MsgFlush()
	{
		foreach ( s in m_pszMsgBuf )
			print( s );
		return m_pszMsgBuf.clear();
	}

	Fmt <- format;
	clamp <- clamp;
	EntFireByHandle <- EntFireByHandle;
	DrawLine <- DebugDrawLine;
	DrawBox <- DebugDrawBox;
	DrawBoxAngles <- DebugDrawBoxAngles;
};

local __tickinterval = FrameTime();
local s_flDisplayTime = __tickinterval * 6;

if ( !("m_hThinkCam" in this) )
{
	m_hView <- VS.CreateEntity( "point_viewcontrol", { spawnflags = (1<<3)|(1<<7) } ).weakref();

	m_hThinkCam <- VS.CreateTimer( false, g_FrameTime, null, null, false, true ).weakref();
	VS.EventQueue.AddEvent( SetThinkEnabled, __tickinterval+0.001, [ null, m_hThinkCam, false ] );
}

// Don't create all the entities if this is loaded from exclusive observer script
if ( KF_OBSERVER_MODE && !("m_hThinkEdit" in this) )
{
	m_hThinkEdit <- null;
	m_hThinkAnim <- null;
	m_hThinkFrame <- null;
	m_hGameText <- null;
	m_hGameText2 <- null;
	m_hGameText3 <- null;
	m_hHudHint <- null;
}
else if ( !("m_hThinkEdit" in this) || !m_hThinkEdit )
{
	m_hThinkEdit <- VS.CreateTimer( true, s_flDisplayTime-__tickinterval, null, null, false, true ).weakref();
	m_hThinkAnim <- VS.CreateTimer( true, __tickinterval*10.0, null, null, false, true ).weakref();
	m_hThinkFrame <- VS.CreateTimer( true, __tickinterval, null, null, false, true ).weakref();

	m_hGameText <- VS.CreateEntity("game_text",
	{
		channel = 5,
		color = Vector(255,120,0),
		holdtime = s_flDisplayTime,
		x = 0.475,
		y = 0.725
	},true).weakref();

	m_hGameText2 <- VS.CreateEntity("game_text",
	{
		channel = 6,
		color = Vector(255,120,0),
		holdtime = s_flDisplayTime,
		x = 0.575,
		y = 0.485
	},true).weakref();

	m_hGameText3 <- VS.CreateEntity("game_text",
	{
		channel = 4,
		color = Vector(255,120,0),
		holdtime = s_flDisplayTime,
		x = 0.575,
		y = 0.505
	},true).weakref();

	m_hHudHint <- VS.CreateEntity("env_hudhint",null,true).weakref();

	PrecacheScriptSound( SND_EXPORT_SUCCESS );
}

local g_FrameTime = g_FrameTime;

// load materials
if ( !KF_OBSERVER_MODE ) {
DrawLine( vec3_origin, vec3_origin, 0, 0, 0, true, 1 );
DrawBox( vec3_origin, vec3_origin, Vector(1,1,1), 0, 0, 0, 254, 1 );
}

//--------------------------------------------------------------
//--------------------------------------------------------------


function CameraSetAngles(v)
{
	return SetEntityAngles( m_hView, v );
}

function CameraSetForward(v)
{
	if ( m_bObserver )
		return player.SetForwardVector(v);

	return m_hView.SetForwardVector(v);
}

function CameraSetOrigin(v)
{
	// NOTE: Observer origin/angles is not interpolated when manually set
	// Setting velocity works only after the frame it was set in, which is not good
	// as camera origin needs to be controlled every frame.
	if ( m_bObserver )
		return player.SetAbsOrigin(v);

	return m_hView.SetAbsOrigin(v);
}

function CameraSetFov( n, f )
{
	return m_hView.SetFov( n, f );
}

function CameraSetEnabled( b )
{
	// Viewcontrol doesn't disable on observers
	if ( m_bObserver )
		return;

	return EntFireByHandle( m_hView, b ? "Enable" : "Disable", "", 0.0, player.self );
}

function CameraSetThinkEnabled( b )
{
	// Sets next think because IO is too slow
	return SetThinkEnabled( m_hThinkCam, b );
}


function _PlaySound(s)
{
	return player.EmitSound(s);
}

if ( "CSGOHUD_VERSION" in CONST )
{
	local event =
	{
		userid = 0,
		hintmessage = null
	}

	local DoHideHint = function( player )
	{
		event.userid = player.GetUserID();
		event.hintmessage = null;
		FireGameEvent( "player_hintmessage", event );
	}

	function _Hint(s)
	{
		event.userid = player.GetUserID();
		event.hintmessage = s;
		return FireGameEvent( "player_hintmessage", event );
	}

	function _HideHudHint( t = 0.0 )
	{
		player.SetContextThink( "_HideHudHint"+t, DoHideHint, t );
	}
}
else
{
	function _Hint(s)
	{
		m_hHudHint.__KeyValueFromString( "message", s );
		return EntFireByHandle( m_hHudHint, "ShowHudHint", "", 0.0, player.self );
	}

	function _HideHudHint( t = 0.0 )
	{
		return EntFireByHandle( m_hHudHint, "HideHudHint", "", t, player.self );
	}
}

PlaySound <- dummy;
Hint <- dummy;
HideHudHint <- dummy;
Msg <- _MsgBuf;

function Error(s)
{
	Msg(s);
	return PlaySound( SND_ERROR );
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

	return PlaySound( SND_FAILURE );
}

function MsgHint(s)
{
	Msg(s);
	return Hint(s);
}

function IsDucking()
{
	return in_duck;
}

function SetViewOrigin( vec )
{
	local origin = player.GetOrigin();

	origin.x = vec.x;
	origin.y = vec.y;
	origin.z = vec.z - ( MainViewOrigin().z - origin.z );

	return player.SetAbsOrigin( origin );
}

function SetViewAngles( vec )
{
	return player.SetAngles( vec.x, vec.y, vec.z );
}

// set angles no roll
function SetViewAngles2D( vec )
{
	return player.SetAngles( vec.x, vec.y, 0.0 );
}

function SetViewForward( vec )
{
	return player.SetForwardVector( vec );
}

function MainViewOrigin()
{
	if ( m_bObserver )
		return player.GetOrigin();

	// CSGO view render origin is offset from the eye position (origin+viewoffset)
	// Using GetAbsOrigin instead of EyePosition to reliably get the actual player position while in-camera view.
	local viewOrigin = player.GetOrigin();

	if ( IsDucking() )
	{
		viewOrigin.z += kCrouchViewOffset;
	}
	else
	{
		viewOrigin.z += kViewOffset;
	}

	return viewOrigin;
}

function MainViewAngles()
{
	return player.EyeAngles();
}

function MainViewForward()
{
	return player.EyeForward();
}

function MainViewRight()
{
	return player.EyeRight();
}

function MainViewUp()
{
	return player.EyeUp();
}

function CurrentViewOrigin()
{
	if ( m_bObserver )
		return player.GetOrigin();

	// NOTE: View entity origin/angles are slightly offset, return keyframe angles.
	if ( m_bSeeing )
	{
		// Return position on the spline
		if ( (m_nInterpolatorOrigin == KF_INTERP_BSPLINE) &&
			((m_nCurKeyframe+2) in m_KeyFrames) && ((m_nCurKeyframe-1) in m_KeyFrames))
		{
			local tmp = Vector();
			SplineOrigin( m_nCurKeyframe, 0.0, tmp );
			return tmp;
		}

		return m_KeyFrames[ m_nCurKeyframe ].origin;
	}

	if ( m_bPreview )
		return m_hView.GetOrigin();

	if ( m_bInPlayback || m_bPlaybackPending )
		return m_PathData[ m_nPlaybackIdx ].origin;

	return MainViewOrigin();
}

function CurrentViewAngles()
{
	if ( m_bObserver )
		return player.EyeAngles();

	// NOTE: View entity origin/angles are slightly offset, return keyframe angles.
	if ( m_bSeeing )
	{
		if ( in_pan || in_rotate )
			return m_vecLastAngles;

		return m_KeyFrames[ m_nCurKeyframe ].angles;
	}

	if ( m_bPreview )
		return m_hView.GetAngles();

	if ( m_bInPlayback || m_bPlaybackPending )
		return m_PathData[ m_nPlaybackIdx ].angles;

	if ( m_nManipulatorSelection && m_vecLastViewAngles )
		return m_vecLastViewAngles;

	return MainViewAngles();
}


class frame_t
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

class keyframe_t //extends frame_t
{
	origin = null;		// Vector
	angles = null;		// QAngle
	forward = null;		// Vector
	right = null;		// Vector
	up = null;			// Vector
	transform = null;	// matrix3x4_t
	fov = null;			// int
	_fovx = null;		// float
	samplecount = 0;	// int
	frametime = 0.0;	// float

	constructor()
	{
		samplecount = KF_SAMPLE_COUNT_DEFAULT;
		frametime = KF_SAMPLE_COUNT_DEFAULT * g_FrameTime;

		m_Transform = transform = matrix3x4_t();
		origin = Vector();
		angles = Vector();
		forward = Vector();
		right = Vector();
		up = Vector();
		SetFov( null );
	}

	function SetOrigin( input )
	{
		VS.VectorCopy( input, origin );
		return VS.MatrixSetColumn( origin, 3, transform );
	}

	function SetAngles( input )
	{
		VS.VectorCopy( input, angles );
		VS.AngleMatrix( angles, origin, transform );
		return VS.MatrixVectors( transform, forward, right, up );
	}

	function SetQuaternion( input )
	{
		VS.QuaternionMatrix( input, origin, transform );
		VS.MatrixAngles( transform, angles );
		return VS.MatrixVectors( transform, forward, right, up );
	}

	function SetForward( input )
	{
		VS.VectorMatrix( input, transform );
		VS.MatrixAngles( transform, angles );
		return VS.MatrixVectors( transform, forward, right, up );
	}

	function GetQuaternion()
	{
		local q = Quaternion();
		VS.MatrixQuaternion( transform, q );
		return q;
	}

	function UpdateFromMatrix()
	{
		VS.MatrixAngles( transform, angles, origin );
		return VS.MatrixVectors( transform, forward, right, up );
	}

	function SetFov( val, rate = null )
	{
		if ( val )
		{
			fov = val.tointeger();
			_fovx = VS.CalcFovX( fov.tofloat(), 16./9. * 0.75 );
		}
		else
		{
			fov = null;
			_fovx = VS.CalcFovX( 90.0, 16./9. * 0.75 );
		}
	}

	function DrawFrustum1( r, g, b, time )
	{
		return VS.DrawViewFrustum(
			origin,
			forward,
			right,
			up,
			_fovx,
			1.777778,
			7.0,
			32.0,
			r, g, b, false,
			time );
	}

	function DrawFrustum()
	{
		local viewMatrix = VMatrix();
		VS.WorldToScreenMatrix( viewMatrix, origin, forward, right, up, _fovx, 1.77778, 7.0, 512.0 );
		VS.MatrixInverseGeneral( viewMatrix, viewMatrix );

		local farTopLeft = Vector( -1, 1, 1 );
		local farTopRight = Vector( 1, 1, 1 );
		local farBottomLeft = Vector( -1, -1, 1 );
		local farBottomRight = Vector( 1, -1, 1 );

		local nearTopLeft = Vector( -1, 1, 0 );
		local nearTopRight = Vector( 1, 1, 0 );
		local nearBottomLeft = Vector( -1, -1, 0 );
		local nearBottomRight = Vector( 1, -1, 0 );

		VS.Vector3DMultiplyPositionProjective( viewMatrix, farTopLeft, farTopLeft );
		VS.Vector3DMultiplyPositionProjective( viewMatrix, farTopRight, farTopRight );
		VS.Vector3DMultiplyPositionProjective( viewMatrix, farBottomLeft, farBottomLeft );
		VS.Vector3DMultiplyPositionProjective( viewMatrix, farBottomRight, farBottomRight );

		VS.Vector3DMultiplyPositionProjective( viewMatrix, nearTopLeft, nearTopLeft );
		VS.Vector3DMultiplyPositionProjective( viewMatrix, nearTopRight, nearTopRight );
		VS.Vector3DMultiplyPositionProjective( viewMatrix, nearBottomLeft, nearBottomLeft );
		VS.Vector3DMultiplyPositionProjective( viewMatrix, nearBottomRight, nearBottomRight );

		DebugDrawLine( origin, farTopLeft, 255, 255, 255, false, -1 );
		DebugDrawLine( origin, farTopRight, 255, 255, 255, false, -1 );
		DebugDrawLine( origin, farBottomLeft, 255, 255, 255, false, -1 );
		DebugDrawLine( origin, farBottomRight, 255, 255, 255, false, -1 );

		DebugDrawLine( nearTopLeft, nearBottomLeft, 94, 124, 138, false, -1 );
		DebugDrawLine( nearTopRight, nearBottomRight, 94, 124, 138, false, -1 );
		DebugDrawLine( nearTopLeft, nearTopRight, 94, 124, 138, false, -1 );
		DebugDrawLine( nearBottomLeft, nearBottomRight, 94, 124, 138, false, -1 );

		DebugDrawLine( farTopLeft, farBottomLeft, 118, 144, 102, false, -1 );
		DebugDrawLine( farTopRight, farBottomRight, 118, 144, 102, false, -1 );
		DebugDrawLine( farTopLeft, farTopRight, 118, 144, 102, false, -1 );
		return DebugDrawLine( farBottomLeft, farBottomRight, 118, 144, 102, false, -1 );
	}

	function Copy( src )
	{
		VS.MatrixCopy( src.transform, transform );

		VS.MatrixAngles( transform, angles, origin );
		VS.MatrixVectors( transform, forward, right, up );

		SetFov( src.fov );

		frametime = src.frametime;
		samplecount = src.samplecount;
	}

	function _cloned( src )
	{
		constructor();
		Copy(src);
	}

	// ------------------------------------------------

	m_Transform = null;				// matrix3x4_t
	m_vecTransformPivot = null;		// Vector

	function SetPosition( vec )
	{
		return SetOrigin( vec );
	}
}

class CUndoElement
{
	constructor( szDesc = "<unknown>" )
	{
		m_szDesc = szDesc;
	}

	function Undo() { Assert(0) }
	function Redo() { Assert(0) }
	function Desc() { return m_szDesc }

	function CanRedo() { return true; }

	m_szDesc = "";
	Fmt = Fmt;
	Base = this;
}


//--------------------------------------------------------------
//--------------------------------------------------------------


function IN_KeyDown( cChar )
{
	return m_KeyInputDown[cChar]();
}

function IN_KeyUp( cChar )
{
	return m_KeyInputUp[cChar]();
}

m_KeyInputDown['Q'] <- function()
{
	// hold and move the mouse to set keyframe roll
	if ( m_bSeeing && !in_pan )
	{
		in_rotate = true;

		m_vecLastForward = MainViewForward();
		m_vecLastViewAngles = MainViewAngles();
		m_vecLastAngles = m_KeyFrames[ m_nCurKeyframe ].angles * 1;

		return;
	}
}.bindenv(this);

m_KeyInputUp['Q'] <- function()
{
	if ( m_bSeeing && in_rotate )
	{
		in_rotate = false;

		if ( m_KeyFrames[ m_nCurKeyframe ].angles.z != m_vecLastAngles.z )
		{
			local pUndo = CUndoKeyframeRoll();
			PushUndo( pUndo );
			pUndo.m_nKeyIndex = m_nCurKeyframe;
			pUndo.m_vecAnglesOld = m_KeyFrames[ m_nCurKeyframe ].angles * 1;
			pUndo.m_vecAnglesNew = m_vecLastAngles * 1;

			// save last set data
			m_KeyFrames[ m_nCurKeyframe ].SetAngles( m_vecLastAngles );

			SetViewForward( m_vecLastForward );
			m_vecLastForward = null;
			m_vecLastViewAngles = null;

			m_bDirty = true;

			return;
		}
	}
}.bindenv(this);

m_KeyInputDown['R'] <- function()
{
	// hold and move the mouse to set keyframe angles without replace mode, preserving roll and fov
	if ( m_bSeeing && !in_rotate )
	{
		in_pan = true;

		m_vecLastForward = MainViewForward();
		m_vecLastViewAngles = MainViewAngles();
		m_vecLastAngles = m_KeyFrames[ m_nCurKeyframe ].angles * 1;

		return;
	}

	// toggle manipulator mode
	if ( m_bGizmoEnabled )
	{
		GizmoToggleManipulationModes();
		PlaySound( SND_BUTTON );

		return;
	}
}.bindenv(this);

m_KeyInputUp['R'] <- function()
{
	if ( m_bSeeing && in_pan )
	{
		in_pan = false;

		if ( !VS.VectorsAreEqual( m_KeyFrames[ m_nCurKeyframe ].angles, m_vecLastAngles, 1.e-3 ) )
		{
			local pUndo = CUndoKeyframePan();
			PushUndo( pUndo );
			pUndo.m_nKeyIndex = m_nCurKeyframe;
			pUndo.m_vecAnglesOld = m_KeyFrames[ m_nCurKeyframe ].angles * 1;
			pUndo.m_vecAnglesNew = m_vecLastAngles * 1;

			// save last set data
			m_KeyFrames[ m_nCurKeyframe ].SetAngles( m_vecLastAngles );

			SetViewForward( m_vecLastForward );
			m_vecLastForward = null;
			m_vecLastViewAngles = null;

			m_bDirty = true;

			return;
		}
	}

	if ( m_bSeeing || !m_bGizmoEnabled )
		return ReplaceKeyframe();

}.bindenv(this);

m_KeyInputDown['T'] <- function()
{
	if ( m_bSeeing || !m_bGizmoEnabled )
		return InsertKeyframe();

	// toggle axis space
	if ( m_bGizmoEnabled )
	{
		if ( m_nManipulatorSelection )
			return;

		m_bGlobalTransform = !m_bGlobalTransform;
		PlaySound( SND_BUTTON );
		Msg(Fmt( "Transform axis %s\n", m_bGlobalTransform ? "global" : "local" ));

		return;
	}
}.bindenv(this);

m_KeyInputDown['F'] <- function()
{
	if ( m_bGizmoEnabled )
		return SelectKeyframe();

	return SelectPath();
}.bindenv(this);

m_KeyInputDown['G'] <- function()
{
	return ShowGizmo();
}.bindenv(this);

m_KeyInputDown['H'] <- function()
{
	PlaySound( SND_BUTTON );
	return PrintUndoStack();
}.bindenv(this);

m_KeyInputDown['Z'] <- function()
{
	return Undo();
}.bindenv(this);

m_KeyInputDown['X'] <- function()
{
	return Redo();
}.bindenv(this);

m_KeyInputDown['C'] <- function()
{
	in_moveup = true;
}.bindenv(this);

m_KeyInputUp['C'] <- function()
{
	in_moveup = false;
}.bindenv(this);

m_KeyInputDown['V'] <- function()
{
	in_movedown = true;
}.bindenv(this);

m_KeyInputUp['V'] <- function()
{
	in_movedown = false;
}.bindenv(this);


//--------------------------------------------------------------
//--------------------------------------------------------------


function OnUsePressed(...)
{
	if ( m_bCameraTimeline )
		SeeKeyframe(0,1);

	// in_zoom =
	in_rotate =
	in_pan =
	in_forward =
	in_back =
	// in_moveleft =
	// in_moveright =
	false;
}

function OnForwardPressed(...)
{
	if ( m_bSeeing )
	{
		in_forward = true;

		m_flLastFOV = GetInterpolatedKeyframeFOV( m_nCurKeyframe );

		// NOTE: In some unknown conditions movetype seems to be noclip while m_bSeeing is true
		// enforce this state here again
		player.SetMoveType( MOVETYPE_NONE );

		return;
	}
}

function OnForwardReleased(...)
{
	if ( m_bSeeing )
	{
		in_forward = false;

		local key = m_KeyFrames[ m_nCurKeyframe ];
		if ( (key.fov ? key.fov : 90) != m_flLastFOV )
		{
			local pUndo = CUndoKeyframeFOV();
			PushUndo( pUndo );
			pUndo.m_nKeyIndex = m_nCurKeyframe;
			pUndo.m_nFovOld = GetInterpolatedKeyframeFOV( m_nCurKeyframe );
			pUndo.m_nFovNew = m_flLastFOV;

			key.SetFov( m_flLastFOV );

			m_bDirty = true;
		}

		return;
	}
}

function OnBackPressed(...)
{
	if ( m_bSeeing )
	{
		in_back = true;

		m_flLastFOV = GetInterpolatedKeyframeFOV( m_nCurKeyframe );

		// NOTE: In some unknown conditions movetype seems to be noclip while m_bSeeing is true
		// enforce this state here again
		player.SetMoveType( MOVETYPE_NONE );

		return;
	}
}

function OnBackReleased(...)
{
	if ( m_bSeeing )
	{
		in_back = false;

		local key = m_KeyFrames[ m_nCurKeyframe ];
		if ( (key.fov ? key.fov : 90) != m_flLastFOV )
		{
			local pUndo = CUndoKeyframeFOV();
			PushUndo( pUndo );
			pUndo.m_nKeyIndex = m_nCurKeyframe;
			pUndo.m_nFovOld = GetInterpolatedKeyframeFOV( m_nCurKeyframe );
			pUndo.m_nFovNew = m_flLastFOV;

			key.SetFov( m_flLastFOV );

			m_bDirty = true;
		}

		return;
	}
}

function OnMouse1Pressed(...)
{
	if ( in_pan || in_rotate )
		return;

	if ( m_bSeeing )
		return NextKeyframe();

	if ( m_bReplaceOnClick )
		return ReplaceKeyframe(1);

	if ( m_bInsertOnClick )
		return InsertKeyframe(1);

	if ( m_bGizmoEnabled )
		return GizmoOnMouse1Pressed();

	if ( m_fPathSelection != 0 )
		return SelectPath(1);

	if ( m_bCameraTimeline )
		return AddKeyframe();
}

function OnMouse1Released(...)
{
	if ( m_bGizmoEnabled )
		return GizmoOnMouse1Released();

	if ( m_bSeeing )
		return;
}

function OnMouse2Pressed(...)
{
	if ( in_pan || in_rotate )
		return;

	if ( m_bReplaceOnClick || m_bInsertOnClick )
	{
		m_bReplaceOnClick = false;
		m_bInsertOnClick = false;
		m_nSelectedKeyframe = -1;

		MsgHint("Cancelled\n");
		return PlaySound( SND_BUTTON );
	};

	if ( m_fPathSelection != 0 )
	{
		m_PathSelection[0] = m_PathSelection[1] = 0;
		m_fPathSelection = 0;
		MsgHint( "Cleared path selection.\n" );
		return PlaySound( SND_BUTTON );
	};

	if ( m_bSeeing )
		return PrevKeyframe();

	if ( m_bGizmoEnabled )
		return GizmoOnMouse2Pressed();

	if ( m_bCameraTimeline )
		return RemoveKeyframe();

	if ( m_nCurElement >= 0 )
	{
		local elem = m_Elements[ m_nCurElement ];
		Msg(Fmt( "removed %s\n", elem.Desc() ));
		elem.Destroy();
		m_Elements.remove( m_nCurElement );
		m_nSelectedKeyframe = -1;
		m_nCurElement = -1;
	}
}

function OnMouse2Released(...)
{
	if ( m_bGizmoEnabled )
		return GizmoOnMouse2Released();
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
	return PlaySound( SND_BUTTON );
}

// kf_edit
function SetEditMode( state = null, msg = true )
{
	if ( KF_OBSERVER_MODE )
		return;

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
		EntFireByHandle( m_hThinkEdit, "Enable" );
		EntFireByHandle( m_hThinkAnim, "Enable" );
		EntFireByHandle( m_hThinkFrame, "Enable" );

		if (msg)
			Msg("Edit mode enabled.\n");
	}
	// off
	else
	{
		// unsee
		if ( m_bSeeing )
			SeeKeyframe(1);

		EntFireByHandle( m_hThinkEdit, "Disable" );
		EntFireByHandle( m_hThinkAnim, "Disable" );
		EntFireByHandle( m_hThinkFrame, "Disable" );
		EntFireByHandle( m_hGameText2, "SetText", "" );
		EntFireByHandle( m_hGameText3, "SetText", "" );

		if (msg)
			Msg("Edit mode disabled.\n");
	};

	SendToConsole("clear_debug_overlays");

	if (msg)
		return PlaySound( SND_BUTTON );
}

function SetEditModeTemp( state )
{
	if ( KF_OBSERVER_MODE )
		return;

	SetThinkEnabled( m_hThinkEdit, state );
	SetThinkEnabled( m_hThinkAnim, state );
	SetThinkEnabled( m_hThinkFrame, state );
}

// kf_select_path
function SelectPath( bClick = 0 )
{
	if ( !m_bInEditMode )
		return MsgFail("Cannot select while edit mode is disabled.\n");

	if ( !m_PathData.len() )
		return MsgFail("No path to select.\n");

	if ( !bClick )
	{
		if ( m_fPathSelection == 0 )
		{
			m_fPathSelection = 1;
			MsgHint( "Select path begin...\n" );
		}
		else
		{
			m_fPathSelection = 0;
			MsgHint( "Cancelled\n" );
		};

		return PlaySound( SND_BUTTON );
	};

	if ( m_fPathSelection == 1 )
	{
		m_PathSelection[0] = m_nCurPathSelection;
		m_nAnimPathIdx = 0;

		Msg(Fmt( " [%d ->\n", m_PathSelection[0] ));

		MsgHint( "Select path end...\n" );
		m_fPathSelection = 2;
	}
	else if ( m_fPathSelection == 2 )
	{
		m_PathSelection[1] = m_nCurPathSelection;
		m_nAnimPathIdx = 0;

		// normalise
		if ( m_PathSelection[0] > m_PathSelection[1] )
		{
			local t = m_PathSelection[1];
			m_PathSelection[1] = m_PathSelection[0];
			m_PathSelection[0] = t;
		};

		if ( m_PathSelection[0] == 0 )
		{
			m_PathSelection[0] = 1;
		};

		if ( m_PathSelection[1] == 0 )
		{
			m_PathSelection[1] = 2;
		};

		if ( m_PathSelection[0] == m_PathSelection[1] )
		{
			m_PathSelection[1]++;
		};

		MsgHint( "Selected path" );
		Msg(Fmt( " [%d -> %d]\n", m_PathSelection[0], m_PathSelection[1] ));
		m_fPathSelection = 0;
	};;

	return PlaySound( SND_BUTTON );
}

// kf_select
function SelectKeyframe()
{
	if ( !m_bInEditMode )
		return MsgFail("Cannot select while edit mode is disabled.\n");

	if ( m_bCameraTimeline )
	{
		if ( m_nSelectedKeyframe == -1 )
		{
			m_nSelectedKeyframe = m_nCurKeyframe;
		}
		else
		{
			// unsee silently
			if ( m_bSeeing )
				SeeKeyframe(1);

			m_nSelectedKeyframe = -1;
		};
	}
	else
	{
		if ( m_nSelectedKeyframe == -1 )
		{
			m_nSelectedKeyframe = m_nCurElement;
			Msg(Fmt( "select %s\n", m_Elements[m_nCurElement].Desc() ));
		}
		else
		{
			Msg(Fmt( "unselect %s\n", m_Elements[m_nCurElement].Desc() ));
			m_nSelectedKeyframe = -1;
		}
	}

	return PlaySound( SND_BUTTON );
}

// kf_next
function NextKeyframe()
{
	if ( m_nSelectedKeyframe == -1 )
		return MsgFail("Keyframe selection is required to use kf_next\n");

	local t = (m_nSelectedKeyframe+1) % m_KeyFrames.len();
	local b = m_bSeeing;		// hold current state

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
		return MsgFail("Keyframe selection is required to use kf_prev\n");

	local n = m_nSelectedKeyframe-1;

	if ( n < 0 )
		n += m_KeyFrames.len();

	local t = n % m_KeyFrames.len();
	local b = m_bSeeing;		// hold current state

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

		player.SetMoveType( m_nMoveTypeRoam );

		return;
	};

	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot use see while in playback!\n");

	if ( !m_bInEditMode )
		return MsgFail("Cannot see while edit mode is disabled.\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	local state = !m_bSeeing;

	if ( state )
	{
		if ( m_nCurKeyframe == -1 )
			return;

		if ( m_nSelectedKeyframe == -1 )
			m_nSelectedKeyframe = m_nCurKeyframe;

		local key = m_KeyFrames[ m_nCurKeyframe ];

		// set fov to selected
		// interpolate if it has inherited fov
		local fov = GetInterpolatedKeyframeFOV( m_nCurKeyframe );
		if ( fov != 90.0 )
			CameraSetFov( fov, 0.1 );

		// Set position on the spline
		if ( m_nInterpolatorOrigin == KF_INTERP_BSPLINE &&
			((m_nCurKeyframe+2) in m_KeyFrames) && ((m_nCurKeyframe-1) in m_KeyFrames))
		{
			local tmp = Vector();
			SplineOrigin( m_nCurKeyframe, 0.0, tmp );
			CameraSetOrigin( tmp );
		}
		else
		{
			CameraSetOrigin( key.origin );
		}

		CameraSetAngles( key.angles );

		CameraSetEnabled( true );

		player.SetVelocity( vec3_origin );
		player.SetMoveType( MOVETYPE_NONE );

		if ( bShowMsg )
			Msg(Fmt( "Seeing keyframe #%d\n", m_nCurKeyframe ));
	}
	else
	{
		CompileFOV();

		m_nSelectedKeyframe = -1;

		CameraSetFov( 0, 0.1 );
		CameraSetEnabled( false );

		player.SetMoveType( m_nMoveTypeRoam );

		if ( bShowMsg )
			Msg(Fmt( "Stopped seeing keyframe #%d\n", m_nCurKeyframe ));
	}

	m_bSeeing = state;

	return PlaySound( SND_BUTTON );
}

function UpdateCamera()
{
	if ( m_bSeeing )
	{
		local key = m_KeyFrames[ m_nCurKeyframe ];
		local fov = GetInterpolatedKeyframeFOV( m_nCurKeyframe );
		CameraSetFov( fov, 0.1 );
		CameraSetOrigin( key.origin );
		return CameraSetAngles( key.angles );
	}
}


local vCapsuleUp = Vector();

function EditModeThink()
{
	if ( m_bObserver )
	{
		local viewOrigin = MainViewOrigin();
		local viewForward = MainViewForward();
		local viewAngles = CurrentViewAngles();
		local ToVector = VS.AngleVectors;
		local res = 10;

		local szCur;
		local flThreshold = 0.9;

		foreach ( szName, pPath in m_PathList )
		{
			pPath = pPath.frames;
			local len = pPath.len() - res;
			if ( len > 0 )
			{
				// Draw the first frame
				// Check if the player is looking at it
				{
					local pt = pPath[0].origin;
					local dir = pt - viewOrigin;
					local dist = dir.Norm();
					local dot = viewForward.Dot(dir);

					if ( dot > flThreshold )
					{
						szCur = szName;
						flThreshold = dot;
					}

					DrawRectRotated( pt, dist / 128.0, 192, 96, 192, 255, s_flDisplayTime, viewAngles );
				}

				// Draw the path
				for ( local i = 0; i < len; i+=res )
				{
					local pt = pPath[i].origin;

					DrawLine( pt, pPath[ i + res ].origin, 128, 255, 0, true, s_flDisplayTime );

					// draw angles if close enough, for perf
					local dist = ( pt - viewOrigin ).LengthSqr();
					if ( dist < 2.3593e+6 )	// 1536
					{
						DrawLine( pt, pt + ToVector( pPath[i].angles ) * 16, 255, 128, 255, true, s_flDisplayTime );
					}
				}
			}
		}

		m_szCurPath = szCur;

		if ( szCur )
		{
			// Draw the selection (again)
			local pt = m_PathList[szCur].frames[0].origin;
			local dist = ( pt - viewOrigin ).Length();
			DrawRectRotated( pt, dist / 64.0, 0, 192, 255, 255, s_flDisplayTime, viewAngles );

			m_hGameText.__KeyValueFromString( "message", szCur );
			EntFireByHandle( m_hGameText, "Display", "", 0, player.self );
		}

		return;
	}

	if ( !m_bCameraTimeline )
	{
		local viewOrigin = MainViewOrigin();
		local viewForward = MainViewForward();
		local viewAngles = CurrentViewAngles();

		if ( (m_nSelectedKeyframe == -1) && !m_nManipulatorSelection )
		{
			local nCur;
			local flThreshold = 0.9;
			local flBestDist = 1.e+37;

			foreach( i, elem in m_Elements )
			{
				local dir = elem.m_vecPosition - viewOrigin;
				local dist = dir.Norm();
				local dot = viewForward.Dot(dir);

				if ( dot > flThreshold )
				{
					nCur = i;
					flThreshold = dot;
				}
			}

			if ( nCur != null )
				m_nCurElement = nCur;
		}

		foreach( i, elem in m_Elements )
		{
			local dist = ( elem.m_vecPosition - viewOrigin ).Length();

			if ( i == m_nCurElement )
			{
				DrawRectRotated( elem.m_vecPosition, dist / 96.0, 0, 192, 255, 255, s_flDisplayTime, viewAngles );
			}
			else
			{
				DrawRectRotated( elem.m_vecPosition, dist / 128.0, 192, 96, 192, 255, s_flDisplayTime, viewAngles );
			}
		}

		return;
	}

	local count = m_KeyFrames.len();
	local viewOrigin = CurrentViewOrigin();
	local viewForward = MainViewForward();
	local nNearestKey;

	if ( count )
	{
		local viewAngles = CurrentViewAngles();
		local curkey;

		if ( !m_bInPlayback && !m_nManipulatorSelection )
		{
			local nCur = m_nCurKeyframe;
			local bSelected = m_nSelectedKeyframe != -1;

			// not selected any keyframe
			if ( !bSelected )
			{
				local flThreshold = 0.9;
				local flBestDist = 1.e+37;

				foreach( i, key in m_KeyFrames )
				{
					local dir = key.origin - viewOrigin;
					local dist = dir.Norm();
					local dot = viewForward.Dot(dir);

					if ( dot > flThreshold )
					{
						nCur = i;
						flThreshold = dot;
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
			}

			if ( nCur != -1 )
			{
				curkey = m_KeyFrames[ nCur ];

				if ( bSelected )
				{
					m_hGameText.__KeyValueFromString( "message", Fmt("KEY: %d (HOLD)", nCur) );
				}
				else
				{
					m_hGameText.__KeyValueFromString( "message", "KEY: " + nCur );
				}

				EntFireByHandle( m_hGameText, "Display", "", 0, player.self );

				if ( curkey.fov )
				{
					m_hGameText2.__KeyValueFromString( "message", "FOV: " + curkey.fov );
					EntFireByHandle( m_hGameText2, "Display", "", 0, player.self );
					EntFireByHandle( m_hGameText2, "SetText", "" );
				}

				if ( curkey.samplecount != KF_SAMPLE_COUNT_DEFAULT )
				{
					m_hGameText3.__KeyValueFromString( "message", "frametime: " + curkey.frametime );
					EntFireByHandle( m_hGameText3, "Display", "", 0, player.self );
					EntFireByHandle( m_hGameText3, "SetText", "" );
				}
			}
		}

		if ( m_bShowKeys && ( 0 in m_KeyFrames ) )
		{
			// draw current keyframe - if not seeing and not in playback
			if ( !m_bSeeing && curkey && !m_bGizmoEnabled )
			{
				local dist = ( curkey.origin - viewOrigin ).Length();
				if ( dist < 768.0 )
				{
					curkey.DrawFrustum1( 255, 255, 255, s_flDisplayTime );
				}

				if ( m_nSelectedKeyframe == -1 )
				{
					DrawRectRotated( curkey.origin, dist / 96.0, 0, 192, 255, 255, s_flDisplayTime, viewAngles );
				}
				else
				{
					DrawRectRotated( curkey.origin, dist / 96.0, 255, 255, 255, 255, s_flDisplayTime, viewAngles );
				}
			}

			local vecStart = m_KeyFrames[0].origin;

			// draw the rest
			foreach( i, key in m_KeyFrames )
			{
				DrawLine( vecStart, key.origin, 128, 128, 128, true, s_flDisplayTime );
				vecStart = key.origin;

				if ( i == m_nCurKeyframe )
					continue;

				local dist = ( key.origin - viewOrigin ).Length();
				if ( dist < 320.0 )
				{
					key.DrawFrustum1( 144, 144, 144, s_flDisplayTime );
				}

				if ( i != m_nAnimKeyframeIdx )
				{
					DrawRectRotated( key.origin, dist / 128.0, 192, 96, 192, 255, s_flDisplayTime, viewAngles );
				}
			}
		};
	};

	if ( m_bShowPath )
	{
		local pPath = m_PathData;
		// NOTE: When sampling rate was global and static, draw resolution could be precalculated.
		// This becomes complicated when keys can have variable amount of samples.
		local res = 10;
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
				if ( dist < 2.3593e+6 )	// 1536
				{
					DrawLine( pt, pt + ToVector( pPath[i].angles ) * 16, 255, 128, 255, true, s_flDisplayTime );
				};
			}

			local bounds = false;
			local offset = 0;

			if ( m_PathSelection[0] )
			{
				bounds = true;
				VS.DrawSphere( m_PathData[ m_PathSelection[0] ].origin, 8.0, 6, 6, 255, 196, 0, true, s_flDisplayTime );
			};

			if ( m_PathSelection[1] )
			{
				bounds = true;
				VS.DrawSphere( m_PathData[ m_PathSelection[1] ].origin, 8.0, 6, 6, 255, 196, 0, true, s_flDisplayTime );
			};

			if ( bounds )
			{
				res = 2;

				if ( m_PathSelection[1] )
				{
					len = m_PathSelection[1] - m_PathSelection[0];
				}
				else
				{
					// in process of choosing the second point
					len = len - m_PathSelection[0];
				}

				offset = m_PathSelection[0];
			};

			m_nAnimPathIdx = (m_nAnimPathIdx + res) % len;
			local frame = pPath[ offset + m_nAnimPathIdx ];
			local origin = frame.origin;

			VS.AngleVectors( frame.angles, null, null, vCapsuleUp );
			VS.VectorScale( vCapsuleUp, 8.0, vCapsuleUp );
			VS.DrawCapsule( origin - vCapsuleUp, origin + vCapsuleUp, 2, 10, 255, 0, true, s_flDisplayTime );

			// Path selection:
			// Find the frame on path the player is looking at around the nearest keyframe
			if ( m_fPathSelection != 0 )
			{
				if ( nNearestKey < 2 )
					nNearestKey = 2;
				else if ( nNearestKey > (count-4) )
					nNearestKey = count-4;;

				// Get frame count up to this point
				local i = GetSampleCount( 1, nNearestKey-1 );

				local end = i +
					m_KeyFrames[nNearestKey-1].samplecount +
					m_KeyFrames[nNearestKey].samplecount +
					m_KeyFrames[nNearestKey+1].samplecount;

				local nSelect = 0;
				local flThreshold = 0.9;

				do
				{
					// This key might be out of the existing path range
					if ( !(i in m_PathData) )
						break;

					local dir = m_PathData[i].origin - viewOrigin;
					dir.Norm();
					local dot = viewForward.Dot( dir );

					if ( dot > flThreshold )
					{
						flThreshold = dot;
						nSelect = i;
					};
				} while ( ++i < end );

				m_nCurPathSelection = nSelect;

				VS.DrawSphere( m_PathData[nSelect].origin, 8.0, 6, 6, 255, 255, 0, true, s_flDisplayTime );
			}
		};
	};
}


function AnimThink()
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
				local viewAngles = CurrentViewAngles();
				local dist = ( key.origin - CurrentViewOrigin() ).Length();

				local s = dist / 128.0;
				DrawRectRotated( key.origin, s, 0, 164, 0, 255, 0.35, viewAngles );
				DrawRectRotated( key.origin, s*1.25, 10, 255, 0, 0, 0.175, viewAngles );
			}
			else if ( m_bSeeing )
			{
				local mat = VMatrix();
				VS.WorldToScreenMatrix(
					mat,
					key.origin,
					key.forward,
					key.right,
					key.up,
					key._fovx, 1.77778, 7.0, 1024.0 );
				VS.MatrixInverseGeneral( mat, mat );

				local worldPos = VS.ScreenToWorld( 0.666666, 0.333333, mat );

				local s = key._fovx * 0.25;
				DrawRectRotated( worldPos, s, 0, 164, 0, 96, 0.25, key.angles );
				DrawRectRotated( worldPos, s, 0, 164, 0, 64, 0.5, key.angles );
			};;
		};
	};
}

// TODO: use SetThink
function FrameThink()
{
	if ( m_bGizmoEnabled && !m_bSeeing && !m_bInPlayback && !m_bPlaybackPending )
	{
		local elem;

		if ( m_bCameraTimeline )
		{
			if ( m_nCurKeyframe < 0 )
				return;

			elem = m_KeyFrames[ m_nCurKeyframe ];
		}
		else
		{
			if ( m_nCurElement < 0 )
				return;

			elem = m_Elements[ m_nCurElement ];
		}

		ManipulatorThink( elem, MainViewOrigin(), MainViewForward(), MainViewAngles() );
		elem.DrawFrustum();
	}
	else if ( m_bSeeing )
	{
		if ( m_bCameraGuides )
		{
			local key = m_KeyFrames[ m_nCurKeyframe ];

			local viewAngles = CurrentViewAngles();
			local viewOrigin = CurrentViewOrigin();
			local fov = GetInterpolatedKeyframeFOV( m_nCurKeyframe );

			local fw = Vector(), rt = Vector(), up = Vector();
			VS.AngleVectors( viewAngles, fw, rt, up );

			local mat = VMatrix();
			VS.WorldToScreenMatrix(
				mat,
				viewOrigin,
				fw,
				rt,
				up,
				VS.CalcFovX( fov, m_flWindowAspectRatio * 0.75 ),
				m_flWindowAspectRatio,
				7.0,
				3000.0 ); // farz needs to be far enough
			VS.MatrixInverseGeneral( mat, mat );

			local horz00 = VS.ScreenToWorld( 0.0, 0.666666, mat ) * 1;
			local horz01 = VS.ScreenToWorld( 1.0, 0.666666, mat );
			DrawLine( horz00, horz01, 200, 200, 200, true, -1 );

			local horz10 = VS.ScreenToWorld( 0.0, 0.333333, mat ) * 1;
			local horz11 = VS.ScreenToWorld( 1.0, 0.333333, mat );
			DrawLine( horz10, horz11, 200, 200, 200, true, -1 );

			local vert00 = VS.ScreenToWorld( 0.666666, 0.0, mat ) * 1;
			local vert01 = VS.ScreenToWorld( 0.666666, 1.0, mat );
			DrawLine( vert00, vert01, 200, 200, 200, true, -1 );

			local vert10 = VS.ScreenToWorld( 0.333333, 0.0, mat ) * 1;
			local vert11 = VS.ScreenToWorld( 0.333333, 1.0, mat );
			DrawLine( vert10, vert11, 200, 200, 200, true, -1 );

			// draw the centre of the screen
			DrawRectFilled( viewOrigin+fw*8.0, 0.075 * fov / 90.0, 200, 200, 200, 0, -1, viewAngles );
		}

		if ( in_rotate )
		{
			local viewAngles = MainViewAngles();
			local dy = viewAngles.y - m_vecLastViewAngles.y;
			if ( dy )
			{
				m_vecLastViewAngles = viewAngles;

				m_vecLastAngles.z = VS.AngleNormalize( m_vecLastAngles.z - dy );
				CameraSetAngles( m_vecLastAngles );
			}
		}
		else if ( in_pan )
		{
			local viewAngles = MainViewAngles();
			local dx = viewAngles.x - m_vecLastViewAngles.x;
			local dy = viewAngles.y - m_vecLastViewAngles.y;
			if ( dx || dy )
			{
				m_vecLastViewAngles = viewAngles;

				// relative rotation
				local q0 = Quaternion(), q1 = Quaternion();
				VS.AngleQuaternion( m_vecLastAngles, q0 );
				VS.AngleQuaternion( Vector( dx, dy ), q1 );
				VS.QuaternionMult( q0, q1, q1 );
				VS.QuaternionAngles( q1, m_vecLastAngles );

				CameraSetAngles( m_vecLastAngles );
			}
		}

		if ( in_forward || in_back )
		{
			local dt = 0.0;

			if ( in_forward )
			{
				dt = -0.5;
			}
			else if ( in_back )
			{
				dt = 0.5;
			}

			m_flLastFOV = clamp( m_flLastFOV + dt, 1, 179 );
			CameraSetFov( m_flLastFOV, g_FrameTime );
		}

		if ( in_moveup || in_movedown )
		{
			local key = m_KeyFrames[ m_nCurKeyframe ];

			if ( in_moveup )
			{
				key.SetOrigin( key.origin + key.up * 4.0 );
			}
			else if ( in_movedown )
			{
				key.SetOrigin( key.origin - key.up * 4.0 );
			}

			CameraSetOrigin( key.origin );
		}
	}

	if ( !m_bSeeing )
	{
		if ( in_moveup )
		{
			local u = 48.0;
			if ( IsDucking() )
			{
				u = 36.0;
			}

			local v = player.GetVelocity() + MainViewUp() * u;
			player.SetVelocity( v );
		}
		else if ( in_movedown )
		{
			local u = 48.0;
			if ( IsDucking() )
			{
				u = 36.0;
			}

			local v = player.GetVelocity() - MainViewUp() * u;
			player.SetVelocity( v );
		}
	}

	// indicate the camera is in a special state
	if ( m_bReplaceOnClick || m_bInsertOnClick )
	{
		local mat = VMatrix();
		VS.WorldToScreenMatrix(
			mat,
			MainViewOrigin(),
			MainViewForward(),
			MainViewRight(),
			MainViewUp(),
			106.26, 1.77778, 1.0, 16.0 );
		VS.MatrixInverseGeneral( mat, mat );

		local worldPos = VS.ScreenToWorld( 0.5, 0.63, mat );
		local angles = MainViewAngles();

		local maxs = Vector( 0.0, 5.0, 0.25 );
		local mins = Vector( 0.0, -5.0, -0.25 );

		local alpha = VS.SmoothCurve( Time() ) * 255;
		DrawBoxAngles( worldPos, mins, maxs, angles, 255, 120, 0, alpha, -1 );
	};

	// animate frustum
	if ( m_pLerpFrustum )
	{
		m_flLerpKeyAnim += 0.01;

		local out = KeyframeLerp( m_pLerpFrustum[0], m_pLerpFrustum[1], VS.SmoothCurve( m_flLerpKeyAnim ) );
		out.DrawFrustum1( 155, 100, 155, 0.075 );

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

	local qt = VS.QuaternionSlerp( in1.GetQuaternion(), in2.GetQuaternion(), frac );
	out.SetQuaternion( qt ); // update transform matrix

	if ( in1._fovx != in2._fovx )
	{
		local t = VS.Lerp( in1._fovx, in2._fovx, frac );
		out.SetFov( t );
	}

	return out;
}


//--------------------------------------------------------------
//--------------------------------------------------------------


g_v100 <- Vector(1,0,0);
g_v010 <- Vector(0,1,0);
g_v001 <- Vector(0,0,1);

local vAxisMin = Vector();
local vAxisMax = Vector( FLT_MAX, FLT_MAX, FLT_MAX );

local vPlaneMin = Vector();
local vPlaneMax = Vector();

local vRectMin = Vector();
local vRectMax = Vector();

function DrawGrid( pos, right, up )
{
	// TODO: snap to grid
	local scale = 32.0;
	local count = 8;
	local size = scale * count;

	local offset = right * size;

	for ( local i = -count; i <= count; ++i )
	{
		local v0 = pos + up * (i * scale);
		DrawLine( v0+offset, v0-offset, 128, 128, 128, true, -1 );
	}

	offset = up * size;

	for ( local i = -count; i <= count; ++i )
	{
		local v0 = pos + right * (i * scale);
		DrawLine( v0+offset, v0-offset, 128, 128, 128, true, -1 );
	}
}

//         w
// P----------------
// |||||||||||t     |  h
// -----------------
//
function DrawProgressBar( pos, flPercent, w, h, r, g, b, viewAngles )
{
	vRectMax.x = vRectMin.x = vRectMax.y = vRectMax.z = 0.0;
	vRectMin.y = w;
	vRectMin.z = -h;

	if ( flPercent < 0.01 )
		return VS.DrawBoxAngles( pos, vRectMin, vRectMax, viewAngles, r, g, b, true, -1 );

	if ( flPercent > 0.99 )
	{
		vRectMin.y *= flPercent;
		return DrawBoxAngles( pos, vRectMin, vRectMax, viewAngles, r, g, b, 255, -1 );
	}

	// ignore Z for outline
	VS.DrawBoxAngles( pos, vRectMin, vRectMax, viewAngles, r, g, b, true, -1 );

	vRectMin.y *= flPercent;
	return DrawBoxAngles( pos, vRectMin, vRectMax, viewAngles, r, g, b, 255, -1 );
}

function DrawRectFilled( pos, s, r, g, b, a, t, viewAngles )
{
	if ( s != vRectMax.z )
	{
		vRectMin.y = vRectMin.z = -s;
		vRectMax.y = vRectMax.z = s;
	}

	return DrawBoxAngles( pos, vRectMin, vRectMax, viewAngles, r, g, b, a, t );
}

function DrawRectRotated( pos, s, r, g, b, a, t, viewAngles )
{
	if ( s != vRectMax.z )
	{
		vRectMin.y = vRectMin.z = -s;
		vRectMax.y = vRectMax.z = s;
	}

	local angles = viewAngles * 1;
	angles.z += 45.0;

	return DrawBoxAngles( pos, vRectMin, vRectMax, angles, r, g, b, a, t );
}

function DrawRectOutlined( pos, s, r, g, b, a, t, viewAngles )
{
	local thickness = s * 0.25;
	local gap = s - thickness * 2.;

	vRectMin.x = vRectMax.x = 0.0;

	// left
	vRectMin.y = gap;		vRectMax.y = s;
	vRectMin.z = -s;		vRectMax.z = s;
	DrawBoxAngles( pos, vRectMin, vRectMax, viewAngles, r, g, b, a, t );

	// right
	vRectMin.y = -gap;		vRectMax.y = -s;
	vRectMin.z = -s;		vRectMax.z = s;
	DrawBoxAngles( pos, vRectMin, vRectMax, viewAngles, r, g, b, a, t );

	// bottom
	vRectMin.y = gap;		vRectMax.y = -s + gap;
	vRectMin.z = -s;		vRectMax.z = -gap;
	DrawBoxAngles( pos, vRectMin, vRectMax, viewAngles, r, g, b, a, t );

	// top
	vRectMin.y = -gap;		vRectMax.y = gap;
	vRectMin.z = gap;		vRectMax.z = s;
	return DrawBoxAngles( pos, vRectMin, vRectMax, viewAngles, r, g, b, a, t );
}

function DrawCircle( pos, radius, r, g, b, z, t, vecRight, vecUp )
{
	local segment = 24;
	local step = PI * 2.0 / segment;

	local vecStart = pos + vecUp * radius;
	local vecPos = vecStart;

	while ( segment-- )
	{
		local s = sin( step * segment ) * radius;
		local c = cos( step * segment ) * radius;

		local vecLastPos = vecPos;
		vecPos = pos + vecUp * c + vecRight * s;

		DrawLine( vecLastPos, vecPos, r, g, b, z, t );
	}
}

//
// Draw the whole circle, but only colour the half in the direction of the camera
//
function DrawCircleHalfBright( pos, radius, r, g, b, z, t, vecNormal, viewForward )
{
	local vecUp = viewForward.Cross( vecNormal );
	vecUp.Norm();

	local vecRight = vecUp.Cross( vecNormal );

	local maxSegment = 24;
	local halfSegment = 12;
	local segment = 0;
	local step = PI * 2.0 / maxSegment;

	local vecStart = pos + vecUp * radius;
	local vecPos = vecStart;

	for ( ; segment <= halfSegment; ++segment )
	{
		local s = sin( step * segment ) * radius;
		local c = cos( step * segment ) * radius;

		local vecLastPos = vecPos;
		vecPos = pos + vecUp * c + vecRight * s;

		DrawLine( vecLastPos, vecPos, r, g, b, z, t );
	}

	for ( ; segment <= maxSegment; ++segment )
	{
		local s = sin( step * segment ) * radius;
		local c = cos( step * segment ) * radius;

		local vecLastPos = vecPos;
		vecPos = pos + vecUp * c + vecRight * s;

		DrawLine( vecLastPos, vecPos, 128, 128, 128, z, t );
	}
}

// Assumes origin is at top left of the rectangle
function IntersectRayWithRect( rayStart, rayDelta, vecOrigin, vecNormal, vecRight, vecUp, w, h )
{
	// VS.IntersectRayWithPlane
	local t = ( vecOrigin.Dot( vecNormal ) - rayStart.Dot( vecNormal ) ) / rayDelta.Dot( vecNormal );
	local vecEndPos = rayStart + rayDelta * t;

	local x = vecEndPos.Dot( vecRight );
	local y = vecEndPos.Dot( vecUp );

	local xo = vecOrigin.Dot( vecRight );
	local yo = vecOrigin.Dot( vecUp );

	if ( x < xo && y < yo && (x > xo-w) && (y > yo-h) )
		return t;

	return 0.0;
}

function IsRayIntersectingCircle( rayStart, rayDelta, vecCentre, vecNormal, flRadius )
{
	// VS.IntersectRayWithPlane
	local t = ( vecCentre.Dot( vecNormal ) - rayStart.Dot( vecNormal ) ) / rayDelta.Dot( vecNormal );
	local vecEndPos = rayStart + rayDelta * t;
	local flDist = ( vecEndPos - vecCentre ).Length();
	return ( flDist < flRadius );
}

function IsRayIntersectingCircleSlice( rayStart, rayDelta, vecCentre, vecNormal, flRadius, flThickness )
{
	// VS.IntersectRayWithPlane
	local t = ( vecCentre.Dot( vecNormal ) - rayStart.Dot( vecNormal ) ) / rayDelta.Dot( vecNormal );
	local vecEndPos = rayStart + rayDelta * t;
	local flDist = ( vecEndPos - vecCentre ).Length();
	return ( flDist < (flRadius+flThickness) && flDist > (flRadius-flThickness) );
}

function IsRayIntersectingCircleSliceFront( rayStart, rayDelta, vecCentre, vecNormal, flRadius, flThickness )
{
	// VS.IntersectRayWithPlane
	local t = ( vecCentre.Dot( vecNormal ) - rayStart.Dot( vecNormal ) ) / rayDelta.Dot( vecNormal );
	local vecEndPos = rayStart + rayDelta * t;

	// Only collide with the half circle on the ray's side
	local flDistRay = ( vecCentre - rayStart ).LengthSqr();
	local flDistRay2 = ( vecEndPos - rayStart ).LengthSqr();
	if ( flDistRay2 > flDistRay )
		return false;

	local flDist = ( vecEndPos - vecCentre ).Length();
	return ( flDist < (flRadius+flThickness) && flDist > (flRadius-flThickness) );
}

local IntersectRayWithRect = IntersectRayWithRect;


const KF_TRANSFORM_TRANSLATE = 1;
const KF_TRANSFORM_ROTATE = 2;
const KF_TRANSFORM_SCREEN = 3;
const KF_TRANSFORM_MODE_COUNT = 3;

const KF_TRANSFORM_PLANE_SCREEN = 16; // screen rotation
const KF_TRANSFORM_PLANE_Z = 32;
const KF_TRANSFORM_PLANE_X = 64;
const KF_TRANSFORM_PLANE_Y = 128;
const KF_TRANSFORM_PLANE_XY = 256;
const KF_TRANSFORM_PLANE_YZ = 512;
const KF_TRANSFORM_PLANE_XZ = 1024;
const KF_TRANSFORM_PLANE_XYZ = 2048; // screen translation
const KF_TRANSFORM_PLANE_FREE = 4096;
const KF_TRANSFORM_PLANE_PIVOT = 8192;
const KF_TRANSFORM_CUSTOM = 16384;



function Manipulator_IsIntersectingAxis( viewOrigin, viewForward, vecOrigin, vecAxis, flScaleX1, flScaleX2 )
{
	// Ray v ray intersection behaves like a cylinder.
	// This makes generalising axis aligned and non-aligned intersections simpler.

	local ts = [ 0.0, 0.0 ];
	VS.IntersectRayWithRay( viewOrigin, viewForward, vecOrigin, vecAxis, ts );

	local t = ts[0], s = ts[1];
	if ( t < 0.0 || s < 0.0 )
		return false;

	local vecS = vecOrigin + vecAxis * s;
	if ( (vecS - vecOrigin).Length() > flScaleX1 )
		return false;

	local vecT = viewOrigin + viewForward * t;
	return ( (vecS - vecT).Length() < flScaleX2 );
}

function Manipulator_IsIntersectingPlane( viewOrigin, viewForward, vecOrigin, vecAxis, vecHorz, vecVert, flScaleXY1, flScaleXY2 )
{
	// Circular intersection is much cheaper than box intersection at angle.
	// Translation planes are already small enough for this to not be a problem.

	local t = VS.IntersectRayWithPlane( viewOrigin, viewForward, vecAxis, vecAxis.Dot( vecOrigin ) );
	local v = viewOrigin + viewForward * t;

	vecOrigin += ( vecHorz + vecVert ) * ( flScaleXY1 + flScaleXY2 );

	return ( vecOrigin - v ).Length() < flScaleXY2;
}

function Manipulator_DrawAxis( vecOrigin, vecAxis, r, g, b, flScaleX1, flScaleX2, iAxis )

{
	if ( m_bGlobalTransform )
	{
		switch ( iAxis )
		{
			case 'x':
				vAxisMin.y = vAxisMin.z = -( vAxisMax.y = vAxisMax.z = flScaleX2 );
				vAxisMax.x = flScaleX1;
				break;

			case 'y':
				vAxisMin.x = vAxisMin.z = -( vAxisMax.x = vAxisMax.z = flScaleX2 );
				vAxisMax.y = flScaleX1;
				break;

			case 'z':
				vAxisMin.x = vAxisMin.y = -( vAxisMax.x = vAxisMax.y = flScaleX2 );
				vAxisMax.z = flScaleX1;
				break;
		}

		return DrawBox( vecOrigin, vAxisMin, vAxisMax, r, g, b, 255, -1 );
	}
	else
	{
		local vAxisAng = VS.VectorAngles( vecAxis );

		vAxisMin.z = vAxisMin.y = -( vAxisMax.z = vAxisMax.y = flScaleX2 );
		vAxisMax.x = flScaleX1;

		return DrawBoxAngles( vecOrigin, vAxisMin, vAxisMax, vAxisAng, r, g, b, 255, -1 );
	}
}

function Manipulator_DrawPlane( vecOrigin, vecAxis, vecHorz, vecVert, r, g, b, flScaleXY1, flScaleXY2, iAxis )

{
	if ( m_bGlobalTransform )
	{
		flScaleXY2 = flScaleXY2 * 2.0 + flScaleXY1;

		switch ( iAxis )
		{
			case 'x':
				vPlaneMin.x = 0.0; vPlaneMin.y = vPlaneMin.z = flScaleXY1;
				vPlaneMax.x = 0.0; vPlaneMax.y = vPlaneMax.z = flScaleXY2;
				break;

			case 'y':
				vPlaneMin.y = 0.0; vPlaneMin.x = vPlaneMin.z = flScaleXY1;
				vPlaneMax.y = 0.0; vPlaneMax.x = vPlaneMax.z = flScaleXY2;
				break;

			case 'z':
				vPlaneMin.z = 0.0; vPlaneMin.x = vPlaneMin.y = flScaleXY1;
				vPlaneMax.z = 0.0; vPlaneMax.x = vPlaneMax.y = flScaleXY2;
				break;
		}

		return DrawBox( vecOrigin, vPlaneMin, vPlaneMax, r, g, b, 255, -1 );
	}
	else
	{
		local vAxisAng = VS.VectorAngles( vecAxis );
		// get roll
		vAxisAng.z = atan2( -vecHorz.z, vecVert.z ) * RAD2DEG;

		vecOrigin += ( vecHorz + vecVert ) * ( flScaleXY1 + flScaleXY2 );

		vPlaneMin.x = vPlaneMax.x = 0.0;
		vPlaneMin.y = vPlaneMin.z = -( vPlaneMax.y = vPlaneMax.z = flScaleXY2 );

		return DrawBoxAngles( vecOrigin, vPlaneMin, vPlaneMax, vAxisAng, r, g, b, 255, -1 );
	}
}
/*
	class CEntityManipulable
	{
		m_Transform = null;
		m_vecTransformPivot = null;

		m_hEntity = null;

		constructor( hEntity )
		{
			m_Transform = matrix3x4_t();
			m_hEntity = hEntity;
			VS.AngleMatrix( hEntity.GetAbsAngles(), hEntity.GetAbsOrigin(), m_Transform );
		}

		function SetPosition( newPosition )
		{
			VS.MatrixSetColumn( newPosition, 3, m_Transform );
			m_hEntity.SetAbsOrigin( newPosition );
		}

		function UpdateFromMatrix()
		{
			local origin = Vector();
			local angles = Vector();
			VS.MatrixAngles( m_Transform, angles, origin );

			m_hEntity.SetAbsOrigin( origin );
			m_hEntity.SetAngles( angles.x, angles.y, angles.z );
		}
	}
*/


function ManipulatorThink( element, viewOrigin, viewForward, viewAngles )
{
	local pTransform = element.m_Transform;
	local vecPosition = VS.MatrixGetColumn( pTransform, 3 ) * 1;
	local vecTransformPivot = element.m_vecTransformPivot;

	local vecOrigin, originToView, vecAxisForward, vecAxisLeft, vecAxisUp, vecCursor;

	if ( m_bGlobalTransform )
	{
		vecAxisForward = g_v100;
		vecAxisLeft = g_v010;
		vecAxisUp = g_v001;

		//Assert( VS.VectorsAreEqual( vecAxisForward, Vector(1,0,0) ) );
		//Assert( VS.VectorsAreEqual( vecAxisLeft, Vector(0,1,0) ) );
		//Assert( VS.VectorsAreEqual( vecAxisUp, Vector(0,0,1) ) );
	}
	else
	{
		vecAxisForward = VS.MatrixGetColumn( pTransform, 0 ) * 1;
		vecAxisLeft = VS.MatrixGetColumn( pTransform, 1 ) * 1;
		vecAxisUp = VS.MatrixGetColumn( pTransform, 2 ) * 1;

		//Assert( VS.CloseEnough( vecAxisForward.Length(), 1.0, 1.e-5 ) );
		//Assert( VS.CloseEnough( vecAxisLeft.Length(), 1.0, 1.e-5 ) );
		//Assert( VS.CloseEnough( vecAxisUp.Length(), 1.0, 1.e-5 ) );
	}

	if ( vecTransformPivot )
	{
		vecOrigin = vecTransformPivot;
	}
	else
	{
		vecOrigin = vecPosition;
	}

	local rayDelta = viewForward * MAX_TRACE_LENGTH;
	local originToView = viewOrigin - vecOrigin;

	local flScale = originToView.Length() / 128.0;
	local flScaleR1 = 18.0 * flScale; // screen plane rotation handle radius
	local flScaleX1 = 16.0 * flScale; // box length
	local flScaleX2 = 0.5 * flScale; // box thickness
	local flScaleXY1 = 4.0 * flScale; // plane distance from the origin
	local flScaleXY2 = 2.0 * flScale; // plane half size (radius)
	local flScale2 = 2.0 * flScale; // rotation handle intersection thickness & screen plane translation box radius

	local nSelection = m_nManipulatorSelection;

	if ( !IsDucking() )
	{
		// stopped ducking
		if ( m_vecCameraOffset )
		{
			CameraSetEnabled(0);
			m_vecCameraOffset = null;

			// if duck was let go before mouse while rotating,
			// remember this for when duck is held again without releasing mouse
			if ( m_bMouse1Down )
			{
				m_bMouse1Down = false;
				m_bMouseForceUp = true;
			}
		}

		// if not ducking and dont have a selection
		if ( !nSelection )
		{
			local t = 0.0;

			//
			// Translation handles
			//

			if ( m_nManipulatorMode == KF_TRANSFORM_TRANSLATE )
			{
				// Draw transform origin
				if ( vecTransformPivot )
				{
					local flScaleToCentre = (viewOrigin - vecPosition).Length() / 128.0;
					DrawRectRotated( vecPosition, flScaleToCentre, 0, 192, 255, 255, -1, viewAngles );
				}

				//
				// test screen plane translation
				//
				if ( VS.IsRayIntersectingSphere( viewOrigin, rayDelta, vecOrigin, flScale2 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_XYZ;
					t = VS.IntersectRayWithPlane( originToView, rayDelta, viewForward * -1, 0.0 );
					DrawRectFilled( vecOrigin, flScale2, 255, 255, 0, 255, -1, viewAngles );
				}
				else
				{
					DrawRectFilled( vecOrigin, flScale2, 0, 255, 255, 255, -1, viewAngles );
				}

				//
				// test Z
				//
				if ( !nSelection &&
					Manipulator_IsIntersectingAxis( viewOrigin, viewForward, vecOrigin, vecAxisUp, flScaleX1, flScaleX2 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_Z;
					t = VS.IntersectRayWithPlane( originToView, viewForward, vecAxisForward, 0.0 );
					Manipulator_DrawAxis( vecOrigin, vecAxisUp, 255, 255, 0, flScaleX1, flScaleX2, 'z' );
				}
				else
				{
					Manipulator_DrawAxis( vecOrigin, vecAxisUp, 0, 0, 255, flScaleX1, flScaleX2, 'z' );
				}

				//
				// test Y
				//
				if ( !nSelection &&
					Manipulator_IsIntersectingAxis( viewOrigin, viewForward, vecOrigin, vecAxisLeft, flScaleX1, flScaleX2 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_Y;
					t = VS.IntersectRayWithPlane( originToView, viewForward, vecAxisForward, 0.0 );
					Manipulator_DrawAxis( vecOrigin, vecAxisLeft, 255, 255, 0, flScaleX1, flScaleX2, 'y' );
				}
				else
				{
					Manipulator_DrawAxis( vecOrigin, vecAxisLeft, 0, 255, 0, flScaleX1, flScaleX2, 'y' );
				}

				//
				// test X
				//
				if ( !nSelection &&
					Manipulator_IsIntersectingAxis( viewOrigin, viewForward, vecOrigin, vecAxisForward, flScaleX1, flScaleX2 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_X;
					t = VS.IntersectRayWithPlane( originToView, viewForward, vecAxisLeft, 0.0 );
					Manipulator_DrawAxis( vecOrigin, vecAxisForward, 255, 255, 0, flScaleX1, flScaleX2, 'x' );
				}
				else
				{
					Manipulator_DrawAxis( vecOrigin, vecAxisForward, 255, 0, 0, flScaleX1, flScaleX2, 'x' );
				}

				//
				// test XY
				//
				if ( !nSelection &&
					Manipulator_IsIntersectingPlane( viewOrigin, viewForward, vecOrigin, vecAxisUp, vecAxisLeft, vecAxisForward, flScaleXY1, flScaleXY2 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_XY;
					t = VS.IntersectRayWithPlane( originToView, viewForward, vecAxisUp, 0.0 );
					Manipulator_DrawPlane( vecOrigin, vecAxisUp, vecAxisLeft, vecAxisForward, 255, 255, 0, flScaleXY1, flScaleXY2, 'z' );
				}
				else
				{
					Manipulator_DrawPlane( vecOrigin, vecAxisUp, vecAxisLeft, vecAxisForward, 0, 0, 255, flScaleXY1, flScaleXY2, 'z' );
				}

				//
				// test YZ
				//
				if ( !nSelection &&
					Manipulator_IsIntersectingPlane( viewOrigin, viewForward, vecOrigin, vecAxisForward, vecAxisUp, vecAxisLeft, flScaleXY1, flScaleXY2 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_YZ;
					t = VS.IntersectRayWithPlane( originToView, viewForward, vecAxisForward, 0.0 );
					Manipulator_DrawPlane( vecOrigin, vecAxisForward, vecAxisUp, vecAxisLeft, 255, 255, 0, flScaleXY1, flScaleXY2, 'x' );
				}
				else
				{
					Manipulator_DrawPlane( vecOrigin, vecAxisForward, vecAxisUp, vecAxisLeft, 255, 0, 0, flScaleXY1, flScaleXY2, 'x' );
				}

				//
				// test XZ
				//
				if ( !nSelection &&
					Manipulator_IsIntersectingPlane( viewOrigin, viewForward, vecOrigin, vecAxisLeft, vecAxisForward, vecAxisUp, flScaleXY1, flScaleXY2 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_XZ;
					t = VS.IntersectRayWithPlane( originToView, viewForward, vecAxisLeft, 0.0 );
					Manipulator_DrawPlane( vecOrigin, vecAxisLeft, vecAxisForward, vecAxisUp, 255, 255, 0, flScaleXY1, flScaleXY2, 'y' );
				}
				else
				{
					Manipulator_DrawPlane( vecOrigin, vecAxisLeft, vecAxisForward, vecAxisUp, 0, 255, 0, flScaleXY1, flScaleXY2, 'y' );
				}
			}

			//
			// Rotation handles
			//

			else if ( m_nManipulatorMode == KF_TRANSFORM_ROTATE )
			{
				// Draw transform origin
				local flScaleToCentre = (viewOrigin - vecPosition).Length() / 128.0;
				DrawRectRotated( vecPosition, flScaleToCentre, 0, 192, 255, 255, -1, viewAngles );

				// Draw the half circle using view->origin vector instead of view forward for situations when
				// view ray is in the opposite direction (when the camera is closely aligned with a local axis).
				local invDeltaOrigin = originToView * -1;

				//
				// test screen plane rotation
				//
				if ( IsRayIntersectingCircleSlice( viewOrigin, rayDelta, vecOrigin, originToView, flScaleR1, flScale2 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_SCREEN;

					local vecDeltaUp = Vector(), vecDeltaRight = Vector();
					VS.VectorVectors( originToView, vecDeltaRight, vecDeltaUp );

					DrawCircle( vecOrigin, flScaleR1, 255, 255, 0, true, -1, vecDeltaRight, vecDeltaUp );
				}
				else
				{
					local vecDeltaUp = Vector(), vecDeltaRight = Vector();
					VS.VectorVectors( originToView, vecDeltaRight, vecDeltaUp );

					DrawCircle( vecOrigin, flScaleR1, 0, 255, 255, true, -1, vecDeltaRight, vecDeltaUp );
				}

				//
				// test Z
				//
				if ( !nSelection &&
					IsRayIntersectingCircleSliceFront( viewOrigin, rayDelta, vecOrigin, vecAxisUp, flScaleX1, flScale2 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_Z;
					DrawCircle( vecOrigin, flScaleX1, 255, 255, 0, true, -1, vecAxisForward, vecAxisLeft );
				}
				else
				{
					DrawCircleHalfBright( vecOrigin, flScaleX1, 0, 0, 255, true, -1, vecAxisUp, invDeltaOrigin );
				}

				//
				// test Y
				//
				if ( !nSelection &&
					IsRayIntersectingCircleSliceFront( viewOrigin, rayDelta, vecOrigin, vecAxisLeft, flScaleX1, flScale2 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_Y;
					DrawCircle( vecOrigin, flScaleX1, 255, 255, 0, true, -1, vecAxisForward, vecAxisUp );
				}
				else
				{
					DrawCircleHalfBright( vecOrigin, flScaleX1, 0, 255, 0, true, -1, vecAxisLeft, invDeltaOrigin );
				}

				//
				// test X
				//
				if ( !nSelection &&
					IsRayIntersectingCircleSliceFront( viewOrigin, rayDelta, vecOrigin, vecAxisForward, flScaleX1, flScale2 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_X;
					DrawCircle( vecOrigin, flScaleX1, 255, 255, 0, true, -1, vecAxisLeft, vecAxisUp );
				}
				else
				{
					DrawCircleHalfBright( vecOrigin, flScaleX1, 255, 0, 0, true, -1, vecAxisForward, invDeltaOrigin );
				}

				//
				// free orbit
				//
				if ( !nSelection && VS.IsRayIntersectingSphere( viewOrigin, rayDelta, vecOrigin, flScaleX1 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_FREE;
					DrawRectFilled( vecOrigin, flScaleX1, 255, 255, 0, 25, -1, viewAngles );
				}
			}

			//
			// Screen
			//

			else if ( m_nManipulatorMode == KF_TRANSFORM_SCREEN )
			{
				// Draw transform origin
				if ( vecTransformPivot )
				{
					local flScaleToCentre = (viewOrigin - vecPosition).Length() / 128.0;
					DrawRectRotated( vecPosition, flScaleToCentre, 0, 192, 255, 255, -1, viewAngles );
				}

				local vecDeltaUp = Vector(), vecDeltaRight = Vector();
				VS.VectorVectors( originToView, vecDeltaRight, vecDeltaUp );

				//
				// pivot handle
				//

				// Don't intersect the pivot handle if this is quick rotation (holding right click in translation manipulator)
				if ( !m_nPrevManipulatorMode )
				{
					local vecPivotHandleOrigin = vecOrigin + vecDeltaRight * (flScaleR1 + flScale2);

					if ( IsRayIntersectingCircle( viewOrigin, rayDelta, vecPivotHandleOrigin, originToView, flScale2 ) )
					{
						nSelection = KF_TRANSFORM_PLANE_PIVOT;
						DrawRectFilled( vecPivotHandleOrigin, flScale2, 255, 156, 0, 255, -1, viewAngles );
					}
					else
					{
						DrawRectFilled( vecPivotHandleOrigin, flScale2, 255, 156, 0, 25, -1, viewAngles );
					}
				}

				//
				// screen plane translation
				//
				if ( !nSelection &&
					VS.IsRayIntersectingSphere( viewOrigin, rayDelta, vecOrigin, flScale2 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_XYZ;
					DrawRectFilled( vecOrigin, flScale2, 255, 255, 0, 255, -1, viewAngles );
				}
				else
				{
					DrawRectFilled( vecOrigin, flScale2, 255, 255, 0, 25, -1, viewAngles );
				}

				//
				// screen plane rotation
				//
				if ( !nSelection &&
					IsRayIntersectingCircleSlice( viewOrigin, rayDelta, vecOrigin, originToView, flScaleR1, flScale2 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_SCREEN;
					DrawCircle( vecOrigin, flScaleR1, 255, 156, 0, true, -1, vecDeltaRight, vecDeltaUp );
				}
				else
				{
					DrawCircle( vecOrigin, flScaleR1, 188, 114, 0, true, -1, vecDeltaRight, vecDeltaUp );
				}

				//
				// free orbit
				//
				if ( !nSelection && VS.IsRayIntersectingSphere( viewOrigin, rayDelta, vecOrigin, flScaleX1 ) )
				{
					nSelection = KF_TRANSFORM_PLANE_FREE;
					DrawCircle( vecOrigin, flScaleX1, 255, 156, 0, true, -1, vecDeltaRight, vecDeltaUp );
				}
				else
				{
					DrawCircle( vecOrigin, flScaleX1, 188, 114, 0, true, -1, vecDeltaRight, vecDeltaUp );
				}
			}

			if ( !nSelection && ("Manip_IsIntersecting" in element) )
			{
				if ( t = element.Manip_IsIntersecting( vecOrigin, viewOrigin, rayDelta, originToView, flScale ) )
				{
					nSelection = KF_TRANSFORM_CUSTOM;
				}
			}

			// default to fixed distance
			if ( !t )
			{
				flScale = 12.0; // reset scale
				t = 1024.0;
			}

			vecCursor = viewOrigin + viewForward * t;

			if ( nSelection )
			{
				if ( m_bMouse1Down )
				{
					m_nManipulatorSelection = nSelection;

					if ( m_nManipulatorMode == KF_TRANSFORM_TRANSLATE )
					{
						m_vecTranslationOffset = vecCursor - vecOrigin;
						VS.VectorCopy( vecOrigin, m_vecLastKeyOrigin );

						// Screen plane translation
						if ( nSelection & KF_TRANSFORM_PLANE_XYZ )
						{
							m_vecLastForward = viewForward;
							m_vecLastViewAngles = viewAngles;

							CameraSetOrigin( viewOrigin );
							CameraSetAngles( viewAngles );
							CameraSetEnabled( 1 );
						}
					}
					else if ( m_nManipulatorMode == KF_TRANSFORM_ROTATE || m_nManipulatorMode == KF_TRANSFORM_SCREEN )
					{
						m_matLastTransform = clone pTransform;

						// TODO: Reset player angles and transform view ray into camera space?

						m_vecInitialForward = viewForward;
						m_vecLastForward = viewForward;
						m_vecLastViewAngles = viewAngles;

						CameraSetOrigin( viewOrigin );
						CameraSetAngles( viewAngles );
						CameraSetEnabled( 1 );

						// if the pivot is held, snap view to the centre of the gizmo after the camera is enabled
						if ( nSelection & KF_TRANSFORM_PLANE_PIVOT )
						{
							VS.VectorSubtract( vecOrigin, viewOrigin, viewForward );
							viewForward.Norm();
							SetViewForward( viewForward );
						}
					}

					if ( nSelection == KF_TRANSFORM_CUSTOM )
					{
						// is the camera already activated for a manipulator mode?
						if ( !m_vecLastViewAngles )
						{
							m_vecLastViewAngles = viewAngles;

							CameraSetOrigin( viewOrigin );
							CameraSetAngles( viewAngles );
							CameraSetEnabled( 1 );
						}
					}

					player.SetMoveType( MOVETYPE_NONE );
					player.SetVelocity( vec3_origin );
				}
				else if ( m_nMouseOver != nSelection )
				{
					m_nMouseOver = nSelection;
					PlaySound( SND_MANIPULATOR_MOUSEOVER );
				}
			}
			else if ( m_nMouseOver )
			{
				m_nMouseOver = 0;
			}
		}
		// if not ducking and have a selection
		else
		{
			if ( nSelection == KF_TRANSFORM_CUSTOM )
			{
				element.Manip_Manipulating( vecOrigin, viewOrigin, rayDelta, originToView, flScale )
			}
			else if ( m_nManipulatorMode == KF_TRANSFORM_TRANSLATE )
			{
				local originToViewNorm = originToView * 1;
				originToViewNorm.Norm();

				// Draw transform origin
				if ( vecTransformPivot )
				{
					local flScaleToCentre = (viewOrigin - vecPosition).Length() / 128.0;
					DrawRectRotated( vecPosition, flScaleToCentre, 255, 255, 255, 255, -1, viewAngles );
				}

				if ( nSelection & KF_TRANSFORM_PLANE_XYZ )
				{
					local t = VS.IntersectRayWithPlane( originToView, rayDelta, m_vecLastForward * -1, 0.0 );
					vecCursor = viewOrigin + rayDelta * t;

					local vecTranslation = vecCursor - vecOrigin;

					VS.VectorAdd( vecPosition, vecTranslation, vecPosition );

					if ( vecTransformPivot )
						VS.VectorAdd( vecTransformPivot, vecTranslation, vecTransformPivot );

					element.SetPosition( vecPosition );

					DrawRectFilled( vecOrigin, flScale2, 255, 255, 0, 255, -1, viewAngles );

					// Draw screen plane
					local vecLastRight = Vector(), vecLastUp = Vector();
					VS.VectorVectors( m_vecLastForward, vecLastRight, vecLastUp );
					DrawGrid( vecOrigin, vecLastRight, vecLastUp );
				}
				else
				{
					DrawRectFilled( vecOrigin, flScale2, 0, 255, 255, 255, -1, viewAngles );
				}

				//
				// Z
				//
				if ( nSelection & KF_TRANSFORM_PLANE_Z )
				{
					local t = VS.IntersectRayWithPlane( originToView, rayDelta, vecAxisForward, 0.0 );
					vecCursor = viewOrigin + rayDelta * t;

					local vecTranslation = vecCursor - m_vecTranslationOffset - vecOrigin;

					if ( m_bGlobalTransform )
					{
						vecTranslation.x = vecTranslation.y = 0.0;
					}
					else
					{
						VS.VectorMA( vecTranslation, -vecTranslation.Dot(vecAxisForward), vecAxisForward, vecTranslation );
						VS.VectorMA( vecTranslation, -vecTranslation.Dot(vecAxisLeft), vecAxisLeft, vecTranslation );
					}

					VS.VectorAdd( vecPosition, vecTranslation, vecPosition );

					if ( vecTransformPivot )
						VS.VectorAdd( vecTransformPivot, vecTranslation, vecTransformPivot );

					// Not updating the gizmo origin will delay the correct drawing 1 frame, and that's fine.
					//if ( vecTransformPivot )
					//	VS.VectorAdd( vecPosition, vecTransformOffset, vecOrigin );

					element.SetPosition( vecPosition );

					Manipulator_DrawAxis( vecOrigin, vecAxisUp, 255, 255, 0, flScaleX1, flScaleX2, 'z' );

					local d1 = fabs( originToViewNorm.Dot( vecAxisLeft ) );
					local d2 = fabs( originToViewNorm.Dot( vecAxisForward ) );

					if ( d1 < d2 )
					{
						DrawGrid( vecOrigin, vecAxisLeft, vecAxisUp );
					}
					else
					{
						DrawGrid( vecOrigin, vecAxisForward, vecAxisUp );
					}
				}
				else
				{
					Manipulator_DrawAxis( vecOrigin, vecAxisUp, 0, 0, 255, flScaleX1, flScaleX2, 'z' );
				}

				//
				// Y
				//
				if ( nSelection & KF_TRANSFORM_PLANE_Y )
				{
					local t = VS.IntersectRayWithPlane( originToView, rayDelta, vecAxisForward, 0.0 );
					vecCursor = viewOrigin + rayDelta * t;

					local vecTranslation = vecCursor - m_vecTranslationOffset - vecOrigin;

					if ( m_bGlobalTransform )
					{
						vecTranslation.x = vecTranslation.z = 0.0;
					}
					else
					{
						VS.VectorMA( vecTranslation, -vecTranslation.Dot(vecAxisForward), vecAxisForward, vecTranslation );
						VS.VectorMA( vecTranslation, -vecTranslation.Dot(vecAxisUp), vecAxisUp, vecTranslation );
					}

					VS.VectorAdd( vecPosition, vecTranslation, vecPosition );

					if ( vecTransformPivot )
						VS.VectorAdd( vecTransformPivot, vecTranslation, vecTransformPivot );

					element.SetPosition( vecPosition );

					Manipulator_DrawAxis( vecOrigin, vecAxisLeft, 255, 255, 0, flScaleX1, flScaleX2, 'y' );

					local d1 = fabs( originToViewNorm.Dot( vecAxisForward ) );
					local d2 = fabs( originToViewNorm.Dot( vecAxisUp ) );

					if ( d1 < d2 )
					{
						DrawGrid( vecOrigin, vecAxisForward, vecAxisLeft );
					}
					else
					{
						DrawGrid( vecOrigin, vecAxisUp, vecAxisLeft );
					}
				}
				else
				{
					Manipulator_DrawAxis( vecOrigin, vecAxisLeft, 0, 255, 0, flScaleX1, flScaleX2, 'y' );
				}

				//
				// X
				//
				if ( nSelection & KF_TRANSFORM_PLANE_X )
				{
					local t = VS.IntersectRayWithPlane( originToView, rayDelta, vecAxisLeft, 0.0 );
					vecCursor = viewOrigin + rayDelta * t;

					local vecTranslation = vecCursor - m_vecTranslationOffset - vecOrigin;

					if ( m_bGlobalTransform )
					{
						vecTranslation.y = vecTranslation.z = 0.0;
					}
					else
					{
						VS.VectorMA( vecTranslation, -vecTranslation.Dot(vecAxisLeft), vecAxisLeft, vecTranslation );
						VS.VectorMA( vecTranslation, -vecTranslation.Dot(vecAxisUp), vecAxisUp, vecTranslation );
					}

					VS.VectorAdd( vecPosition, vecTranslation, vecPosition );

					if ( vecTransformPivot )
						VS.VectorAdd( vecTransformPivot, vecTranslation, vecTransformPivot );

					element.SetPosition( vecPosition );

					Manipulator_DrawAxis( vecOrigin, vecAxisForward, 255, 255, 0, flScaleX1, flScaleX2, 'x' );

					local d1 = fabs( originToViewNorm.Dot( vecAxisUp ) );
					local d2 = fabs( originToViewNorm.Dot( vecAxisLeft ) );

					if ( d1 < d2 )
					{
						DrawGrid( vecOrigin, vecAxisUp, vecAxisForward );
					}
					else
					{
						DrawGrid( vecOrigin, vecAxisLeft, vecAxisForward );
					}
				}
				else
				{
					Manipulator_DrawAxis( vecOrigin, vecAxisForward, 255, 0, 0, flScaleX1, flScaleX2, 'x' );
				}

				//
				// XY
				//
				if ( nSelection & KF_TRANSFORM_PLANE_XY )
				{
					local t = VS.IntersectRayWithPlane( originToView, rayDelta, vecAxisUp, 0.0 );
					vecCursor = viewOrigin + rayDelta * t;

					local vecTranslation = vecCursor - m_vecTranslationOffset - vecOrigin;

					if ( m_bGlobalTransform )
					{
						vecTranslation.z = 0.0;
					}
					else
					{
						VS.VectorMA( vecTranslation, -vecTranslation.Dot(vecAxisUp), vecAxisUp, vecTranslation );
					}

					VS.VectorAdd( vecPosition, vecTranslation, vecPosition );

					if ( vecTransformPivot )
						VS.VectorAdd( vecTransformPivot, vecTranslation, vecTransformPivot );

					element.SetPosition( vecPosition );

					Manipulator_DrawPlane( vecOrigin, vecAxisUp, vecAxisLeft, vecAxisForward, 255, 255, 0, flScaleXY1, flScaleXY2, 'z' );
					DrawGrid( vecOrigin, vecAxisForward, vecAxisLeft );
				}
				else
				{
					Manipulator_DrawPlane( vecOrigin, vecAxisUp, vecAxisLeft, vecAxisForward, 0, 0, 255, flScaleXY1, flScaleXY2, 'z' );
				}

				//
				// YZ
				//
				if ( nSelection & KF_TRANSFORM_PLANE_YZ )
				{
					local t = VS.IntersectRayWithPlane( originToView, rayDelta, vecAxisForward, 0.0 );
					vecCursor = viewOrigin + rayDelta * t;

					local vecTranslation = vecCursor - m_vecTranslationOffset - vecOrigin;

					if ( m_bGlobalTransform )
					{
						vecTranslation.x = 0.0;
					}
					else
					{
						VS.VectorMA( vecTranslation, -vecTranslation.Dot(vecAxisForward), vecAxisForward, vecTranslation );
					}

					VS.VectorAdd( vecPosition, vecTranslation, vecPosition );

					if ( vecTransformPivot )
						VS.VectorAdd( vecTransformPivot, vecTranslation, vecTransformPivot );

					element.SetPosition( vecPosition );

					Manipulator_DrawPlane( vecOrigin, vecAxisForward, vecAxisUp, vecAxisLeft, 255, 255, 0, flScaleXY1, flScaleXY2, 'x' );
					DrawGrid( vecOrigin, vecAxisUp, vecAxisLeft );
				}
				else
				{
					Manipulator_DrawPlane( vecOrigin, vecAxisForward, vecAxisUp, vecAxisLeft, 255, 0, 0, flScaleXY1, flScaleXY2, 'x' );
				}

				//
				// XZ
				//
				if ( nSelection & KF_TRANSFORM_PLANE_XZ )
				{
					local t = VS.IntersectRayWithPlane( originToView, rayDelta, vecAxisLeft, 0.0 );
					vecCursor = viewOrigin + rayDelta * t;

					local vecTranslation = vecCursor - m_vecTranslationOffset - vecOrigin;

					if ( m_bGlobalTransform )
					{
						vecTranslation.y = 0.0;
					}
					else
					{
						VS.VectorMA( vecTranslation, -vecTranslation.Dot(vecAxisLeft), vecAxisLeft, vecTranslation );
					}

					VS.VectorAdd( vecPosition, vecTranslation, vecPosition );

					if ( vecTransformPivot )
						VS.VectorAdd( vecTransformPivot, vecTranslation, vecTransformPivot );

					element.SetPosition( vecPosition );

					Manipulator_DrawPlane( vecOrigin, vecAxisLeft, vecAxisForward, vecAxisUp, 255, 255, 0, flScaleXY1, flScaleXY2, 'y' );
					DrawGrid( vecOrigin, vecAxisUp, vecAxisForward );
				}
				else
				{
					Manipulator_DrawPlane( vecOrigin, vecAxisLeft, vecAxisForward, vecAxisUp, 0, 255, 0, flScaleXY1, flScaleXY2, 'y' );
				}

				// show translation diff
				DrawRectFilled( m_vecLastKeyOrigin, 2.0, 255, 255, 255, 64, -1, viewAngles );
				DrawLine( m_vecLastKeyOrigin, vecOrigin, 255, 255, 255, true, -1 );
			}
			else if ( m_nManipulatorMode == KF_TRANSFORM_ROTATE )
			{
				// reached pitch limit?
				if ( VS.CloseEnough( fabs( viewAngles.x ), 89.0, 2.0 ) )
				{
					SetViewAngles( vec3_origin );
				}

				local vecNormal;
				local r, g, b;

				if ( nSelection & KF_TRANSFORM_PLANE_SCREEN || nSelection & KF_TRANSFORM_PLANE_FREE )
				{
					vecNormal = originToView;
				}
				else if ( nSelection & KF_TRANSFORM_PLANE_X )
				{
					vecNormal = vecAxisForward;
					r = 255; g = b = 0;
				}
				else if ( nSelection & KF_TRANSFORM_PLANE_Y )
				{
					vecNormal = vecAxisLeft;
					g = 255; r = b = 0;
				}
				else if ( nSelection & KF_TRANSFORM_PLANE_Z )
				{
					vecNormal = vecAxisUp;
					b = 255; r = g = 0;
				}

				if ( vecNormal )
				{
					local rayInitialDelta = m_vecInitialForward * MAX_TRACE_LENGTH;
					local rayLastDelta = m_vecLastForward * MAX_TRACE_LENGTH;
					m_vecLastForward = viewForward;

					// Spherical rotation
					// Rotates the transform from initial frame to current mouse position
					if ( nSelection & KF_TRANSFORM_PLANE_FREE )
					{
						local tr = [ 0.0, 0.0 ];
						VS.IntersectInfiniteRayWithSphere( viewOrigin, rayInitialDelta, vecOrigin, flScaleX1, tr );
						local vecInitialIntersection = viewOrigin + rayInitialDelta * tr[0];

						// If no intersection, get the projection of the sphere (centre) onto the ray
						if ( !VS.IntersectInfiniteRayWithSphere( viewOrigin, rayLastDelta, vecOrigin, flScaleX1, tr ) )
							tr[0] = rayLastDelta.Dot( originToView * -1 ) / (MAX_TRACE_LENGTH*MAX_TRACE_LENGTH);
						local vecPrevIntersection = viewOrigin + rayLastDelta * tr[0];

						if ( !VS.IntersectInfiniteRayWithSphere( viewOrigin, rayDelta, vecOrigin, flScaleX1, tr ) )
							tr[0] = rayDelta.Dot( originToView * -1 ) / (MAX_TRACE_LENGTH*MAX_TRACE_LENGTH);
						local vecCurIntersection = viewOrigin + rayDelta * tr[0];

						local vecInitialDelta = vecInitialIntersection - vecOrigin;
						local vecPrevDelta = vecPrevIntersection - vecOrigin;
						local vecCurDelta = vecCurIntersection - vecOrigin;
						vecInitialDelta.Norm();
						vecPrevDelta.Norm();
						vecCurDelta.Norm();

						local dot = vecPrevDelta.Dot( vecCurDelta );
						if ( dot < 0.999999 )
						{
							vecNormal = vecInitialDelta.Cross( vecCurDelta );
							vecNormal.Norm();
							local flAngle = acos( vecInitialDelta.Dot( vecCurDelta ) ) * RAD2DEG;
							local rot = matrix3x4_t();
							VS.MatrixBuildRotationAboutAxis( vecNormal, flAngle, rot );

							if ( vecTransformPivot )
							{
								local tmp = clone m_matLastTransform;
								VS.MatrixSetColumn( VS.MatrixGetColumn( m_matLastTransform, 3 ) - vecTransformPivot, 3, tmp );
								VS.ConcatTransforms( rot, tmp, pTransform );
								VS.MatrixSetColumn( VS.MatrixGetColumn( pTransform, 3 ) + vecTransformPivot, 3, pTransform );
							}
							else
							{
								VS.ConcatRotations( rot, m_matLastTransform, pTransform );
							}

							element.UpdateFromMatrix();
						}

						// rotation diff
						DrawLine( vecOrigin, vecOrigin + vecInitialDelta * flScaleX1, 255, 255, 0, true, -1 );
						DrawLine( vecOrigin, vecOrigin + vecCurDelta * flScaleX1, 255, 255, 0, true, -1 );

						// handles
						DrawCircleHalfBright( vecOrigin, flScaleX1, 255, 0, 0, true, -1, vecAxisForward, m_vecInitialForward );
						DrawCircleHalfBright( vecOrigin, flScaleX1, 0, 255, 0, true, -1, vecAxisLeft, m_vecInitialForward );
						DrawCircleHalfBright( vecOrigin, flScaleX1, 0, 0, 255, true, -1, vecAxisUp, m_vecInitialForward );

						local vecDeltaUp = Vector(), vecDeltaRight = Vector();
						VS.VectorVectors( originToView, vecDeltaRight, vecDeltaUp );

						DrawCircle( vecOrigin, flScaleR1, 0, 255, 255, true, -1, vecDeltaRight, vecDeltaUp );

						vecCursor = vecCurIntersection;
					}
					// Circular rotation
					// Rotates the transform from last frame to current mouse position
					else
					{
						vecNormal.Norm();

						local flDist = vecNormal.Dot( vecOrigin );

						local t = VS.IntersectRayWithPlane( viewOrigin, rayInitialDelta, vecNormal, flDist );
						local vecInitialIntersection = viewOrigin + rayInitialDelta * t;

						t = VS.IntersectRayWithPlane( viewOrigin, rayLastDelta, vecNormal, flDist );
						local vecPrevIntersection = viewOrigin + rayLastDelta * t;

						t = VS.IntersectRayWithPlane( viewOrigin, rayDelta, vecNormal, flDist );
						local vecCurIntersection = viewOrigin + rayDelta * t;

						local vecInitialDelta = vecInitialIntersection - vecOrigin;
						local vecPrevDelta = vecPrevIntersection - vecOrigin;
						local vecCurDelta = vecCurIntersection - vecOrigin;
						vecInitialDelta.Norm();
						vecPrevDelta.Norm();
						vecCurDelta.Norm();

						local dot = vecPrevDelta.Dot( vecCurDelta );
						if ( dot < 0.999999 )
						{
							local flAngle = acos( dot ) * RAD2DEG;
							local vecRelativeRight = vecPrevDelta.Cross( vecNormal );
							local flSign = vecCurDelta.Dot( vecRelativeRight );
							if ( flSign > 0.0 )
								flAngle = -flAngle;

							local rot = matrix3x4_t();
							VS.MatrixBuildRotationAboutAxis( vecNormal, flAngle, rot );

							if ( vecTransformPivot )
							{
								VS.MatrixSetColumn( VS.MatrixGetColumn( pTransform, 3 ) - vecTransformPivot, 3, pTransform );
								VS.ConcatTransforms( rot, pTransform, pTransform );
								VS.MatrixSetColumn( VS.MatrixGetColumn( pTransform, 3 ) + vecTransformPivot, 3, pTransform );
							}
							else
							{
								VS.ConcatRotations( rot, pTransform, pTransform );
							}

							element.UpdateFromMatrix();

							if ( !m_bGlobalTransform )
							{
								// Update axes post-rotation to prevent visual distortion in draw code
								VS.MatrixGetColumn( pTransform, 0, vecAxisForward );
								VS.MatrixGetColumn( pTransform, 1, vecAxisLeft );
								VS.MatrixGetColumn( pTransform, 2, vecAxisUp );
							}
						}

						// rotation diff
						if ( nSelection & KF_TRANSFORM_PLANE_SCREEN )
						{
							// Special case for outermost rotation handle because it has a different scale than others
							DrawLine( vecOrigin, vecOrigin + vecInitialDelta * flScaleR1, 255, 255, 0, true, -1 );
							DrawLine( vecOrigin, vecOrigin + vecCurDelta * flScaleR1, 255, 255, 0, true, -1 );
						}
						else
						{
							DrawLine( vecOrigin, vecOrigin + vecInitialDelta * flScaleX1, 255, 255, 0, true, -1 );
							DrawLine( vecOrigin, vecOrigin + vecCurDelta * flScaleX1, 255, 255, 0, true, -1 );
						}

						// handles
						// draw the current rotation handle in full circle
						local vecDeltaUp = Vector(), vecDeltaRight = Vector();
						VS.VectorVectors( originToView, vecDeltaRight, vecDeltaUp );

						if ( r == 255 )
						{
							// swept axis
							// DrawLine( vecOrigin + vecNormal * -MAX_COORD_FLOAT, vecOrigin + vecNormal * MAX_COORD_FLOAT, r, g, b, true, -1 );

							DrawCircle( vecOrigin, flScaleX1, 255, 255, 0, true, -1, vecAxisLeft, vecAxisUp );
							DrawCircleHalfBright( vecOrigin, flScaleX1, 0, 255, 0, true, -1, vecAxisLeft, m_vecInitialForward );
							DrawCircleHalfBright( vecOrigin, flScaleX1, 0, 0, 255, true, -1, vecAxisUp, m_vecInitialForward );

							DrawCircle( vecOrigin, flScaleR1, 0, 255, 255, true, -1, vecDeltaRight, vecDeltaUp );
						}
						else if ( g == 255 )
						{
							// swept axis
							// DrawLine( vecOrigin + vecNormal * -MAX_COORD_FLOAT, vecOrigin + vecNormal * MAX_COORD_FLOAT, r, g, b, true, -1 );

							DrawCircleHalfBright( vecOrigin, flScaleX1, 255, 0, 0, true, -1, vecAxisForward, m_vecInitialForward );
							DrawCircle( vecOrigin, flScaleX1, 255, 255, 0, true, -1, vecAxisForward, vecAxisUp );
							DrawCircleHalfBright( vecOrigin, flScaleX1, 0, 0, 255, true, -1, vecAxisUp, m_vecInitialForward );

							DrawCircle( vecOrigin, flScaleR1, 0, 255, 255, true, -1, vecDeltaRight, vecDeltaUp );
						}
						else if ( b == 255 )
						{
							// swept axis
							// DrawLine( vecOrigin + vecNormal * -MAX_COORD_FLOAT, vecOrigin + vecNormal * MAX_COORD_FLOAT, r, g, b, true, -1 );

							DrawCircleHalfBright( vecOrigin, flScaleX1, 255, 0, 0, true, -1, vecAxisForward, m_vecInitialForward );
							DrawCircleHalfBright( vecOrigin, flScaleX1, 0, 255, 0, true, -1, vecAxisLeft, m_vecInitialForward );
							DrawCircle( vecOrigin, flScaleX1, 255, 255, 0, true, -1, vecAxisForward, vecAxisLeft );

							DrawCircle( vecOrigin, flScaleR1, 0, 255, 255, true, -1, vecDeltaRight, vecDeltaUp );
						}
						else
						{
							DrawCircleHalfBright( vecOrigin, flScaleX1, 255, 0, 0, true, -1, vecAxisForward, m_vecInitialForward );
							DrawCircleHalfBright( vecOrigin, flScaleX1, 0, 255, 0, true, -1, vecAxisLeft, m_vecInitialForward );
							DrawCircleHalfBright( vecOrigin, flScaleX1, 0, 0, 255, true, -1, vecAxisUp, m_vecInitialForward );

							DrawCircle( vecOrigin, flScaleR1, 255, 255, 0, true, -1, vecDeltaRight, vecDeltaUp );
						}

						vecCursor = vecCurIntersection;
					}
				}
			}
			else if ( m_nManipulatorMode == KF_TRANSFORM_SCREEN )
			{
				// reached pitch limit?
				if ( VS.CloseEnough( fabs( viewAngles.x ), 89.0, 2.0 ) )
				{
					SetViewAngles( vec3_origin );
				}

				local vecDeltaUp = Vector(), vecDeltaRight = Vector();
				VS.VectorVectors( originToView, vecDeltaRight, vecDeltaUp );

				if ( nSelection & KF_TRANSFORM_PLANE_XYZ )
				{
					local t = VS.IntersectRayWithPlane( originToView, rayDelta, m_vecLastForward * -1, 0.0 );
					local vecTranslation = (viewOrigin + rayDelta * t) - vecOrigin;

					VS.VectorAdd( vecPosition, vecTranslation, vecPosition );

					if ( vecTransformPivot )
						VS.VectorAdd( vecTransformPivot, vecTranslation, vecTransformPivot );

					element.SetPosition( vecPosition );

					// don't draw anything but the transform origin
					local flScaleToCentre = (viewOrigin - vecPosition).Length() / 128.0;
					DrawRectRotated( vecPosition, flScaleToCentre, 255, 255, 255, 255, -1, viewAngles );
				}

				if ( nSelection & KF_TRANSFORM_PLANE_PIVOT )
				{
					// move the gizmo on screen plane
					local t = VS.IntersectRayWithPlane( originToView, rayDelta, m_vecLastForward * -1, 0.0 );
					local vecTranslation = viewOrigin + rayDelta * t;

					// This is absolute instead of relative to be able to keep the pivot point in the same place while rotating.
					element.m_vecTransformPivot = vecTranslation;

					vecOrigin = vecTranslation;

					DrawCircle( vecOrigin, flScaleX1, 188, 114, 0, true, -1, vecDeltaRight, vecDeltaUp );
					DrawCircle( vecOrigin, flScaleR1, 188, 114, 0, true, -1, vecDeltaRight, vecDeltaUp );
				}

				if ( nSelection & (KF_TRANSFORM_PLANE_SCREEN | KF_TRANSFORM_PLANE_FREE) )
				{
					local vecNormal = originToView;

					local rayInitialDelta = m_vecInitialForward * MAX_TRACE_LENGTH;
					local rayLastDelta = m_vecLastForward * MAX_TRACE_LENGTH;
					m_vecLastForward = viewForward;

					// Spherical rotation
					// Rotates the transform from initial frame to current mouse position
					if ( nSelection & KF_TRANSFORM_PLANE_FREE )
					{
						local tr = [ 0.0, 0.0 ];
						VS.IntersectInfiniteRayWithSphere( viewOrigin, rayInitialDelta, vecOrigin, flScaleX1, tr );
						local vecInitialIntersection = viewOrigin + rayInitialDelta * tr[0];

						// If no intersection, get the projection of the sphere (centre) onto the ray
						if ( !VS.IntersectInfiniteRayWithSphere( viewOrigin, rayLastDelta, vecOrigin, flScaleX1, tr ) )
							tr[0] = rayLastDelta.Dot( originToView * -1 ) / (MAX_TRACE_LENGTH*MAX_TRACE_LENGTH);
						local vecPrevIntersection = viewOrigin + rayLastDelta * tr[0];

						if ( !VS.IntersectInfiniteRayWithSphere( viewOrigin, rayDelta, vecOrigin, flScaleX1, tr ) )
							tr[0] = rayDelta.Dot( originToView * -1 ) / (MAX_TRACE_LENGTH*MAX_TRACE_LENGTH);
						local vecCurIntersection = viewOrigin + rayDelta * tr[0];

						local vecInitialDelta = vecInitialIntersection - vecOrigin;
						local vecPrevDelta = vecPrevIntersection - vecOrigin;
						local vecCurDelta = vecCurIntersection - vecOrigin;
						vecInitialDelta.Norm();
						vecPrevDelta.Norm();
						local flCurDist = vecCurDelta.Norm();

						local dot = vecPrevDelta.Dot( vecCurDelta );
						if ( dot < 0.999999 )
						{
							vecNormal = vecInitialDelta.Cross( vecCurDelta );
							vecNormal.Norm();
							local flAngle = acos( vecInitialDelta.Dot( vecCurDelta ) ) * RAD2DEG;
							local rot = matrix3x4_t();
							VS.MatrixBuildRotationAboutAxis( vecNormal, flAngle, rot );

							if ( vecTransformPivot )
							{
								local tmp = clone m_matLastTransform;
								VS.MatrixSetColumn( VS.MatrixGetColumn( m_matLastTransform, 3 ) - vecTransformPivot, 3, tmp );
								VS.ConcatTransforms( rot, tmp, pTransform );
								VS.MatrixSetColumn( VS.MatrixGetColumn( pTransform, 3 ) + vecTransformPivot, 3, pTransform );
							}
							else
							{
								VS.ConcatRotations( rot, m_matLastTransform, pTransform );
							}

							element.UpdateFromMatrix();
						}

						// rotation diff
						DrawLine( vecOrigin, vecOrigin + vecInitialDelta * flScaleX1, 255, 255, 0, true, -1 );
						DrawLine( vecOrigin, vecOrigin + vecCurDelta * flCurDist, 255, 255, 0, true, -1 );

						DrawCircle( vecOrigin, flScaleR1, 255, 156, 0, true, -1, vecDeltaRight, vecDeltaUp );

						vecCursor = vecCurIntersection;
					}
					// Circular rotation
					// Rotates the transform from last frame to current mouse position
					else
					{
						vecNormal.Norm();

						local flDist = vecNormal.Dot( vecOrigin );

						local t = VS.IntersectRayWithPlane( viewOrigin, rayInitialDelta, vecNormal, flDist );
						local vecInitialIntersection = viewOrigin + rayInitialDelta * t;

						t = VS.IntersectRayWithPlane( viewOrigin, rayLastDelta, vecNormal, flDist );
						local vecPrevIntersection = viewOrigin + rayLastDelta * t;

						t = VS.IntersectRayWithPlane( viewOrigin, rayDelta, vecNormal, flDist );
						local vecCurIntersection = viewOrigin + rayDelta * t;

						local vecInitialDelta = vecInitialIntersection - vecOrigin;
						local vecPrevDelta = vecPrevIntersection - vecOrigin;
						local vecCurDelta = vecCurIntersection - vecOrigin;
						vecInitialDelta.Norm();
						vecPrevDelta.Norm();
						vecCurDelta.Norm();

						local dot = vecPrevDelta.Dot( vecCurDelta );
						if ( dot < 0.999999 )
						{
							local flAngle = acos( dot ) * RAD2DEG;
							local vecRelativeRight = vecPrevDelta.Cross( vecNormal );
							local flSign = vecCurDelta.Dot( vecRelativeRight );
							if ( flSign > 0.0 )
								flAngle = -flAngle;

							local rot = matrix3x4_t();
							VS.MatrixBuildRotationAboutAxis( vecNormal, flAngle, rot );

							if ( vecTransformPivot )
							{
								VS.MatrixSetColumn( VS.MatrixGetColumn( pTransform, 3 ) - vecTransformPivot, 3, pTransform );
								VS.ConcatTransforms( rot, pTransform, pTransform );
								VS.MatrixSetColumn( VS.MatrixGetColumn( pTransform, 3 ) + vecTransformPivot, 3, pTransform );
							}
							else
							{
								VS.ConcatRotations( rot, pTransform, pTransform );
							}

							element.UpdateFromMatrix();

							if ( !m_bGlobalTransform )
							{
								// Update axes post-rotation to prevent visual distortion in draw code
								VS.MatrixGetColumn( pTransform, 0, vecAxisForward );
								VS.MatrixGetColumn( pTransform, 1, vecAxisLeft );
								VS.MatrixGetColumn( pTransform, 2, vecAxisUp );
							}
						}

						// rotation diff
						DrawLine( vecOrigin, vecOrigin + vecInitialDelta * flScaleR1, 255, 255, 0, true, -1 );
						DrawLine( vecOrigin, vecOrigin + vecCurDelta * flScaleR1, 255, 255, 0, true, -1 );

						DrawCircle( vecOrigin, flScaleR1, 255, 156, 0, true, -1, vecDeltaRight, vecDeltaUp );

						vecCursor = vecCurIntersection;
					}
				}
			}
		}

		if ( 0 && m_bDuckFixup )
		{
			local v = player.GetOrigin();
			v.z -= 9.017594;
			player.SetOrigin( v );
			m_bDuckFixup = false;
		}
	}
	// ducking with no selection, rotate camera around cursor
	else if ( !nSelection )
	{
		if ( 0 && !m_bDuckFixup )
		{
			local v = player.GetOrigin();
			v.z += 9.017594;
			player.SetOrigin( v );
			m_bDuckFixup = true;
		}

		if ( m_bMouseForceUp )
		{
			m_bMouse1Down = true;
			m_bMouseForceUp = false;
		}

		// Draw current manipulator
		switch ( m_nManipulatorMode )
		{
			case KF_TRANSFORM_TRANSLATE:
			{
				DrawRectFilled( vecOrigin, flScale2, 0, 255, 255, 255, -1, viewAngles );

				Manipulator_DrawAxis( vecOrigin, vecAxisUp, 0, 0, 255, flScaleX1, flScaleX2, 'z' );
				Manipulator_DrawAxis( vecOrigin, vecAxisLeft, 0, 255, 0, flScaleX1, flScaleX2, 'y' );
				Manipulator_DrawAxis( vecOrigin, vecAxisForward, 255, 0, 0, flScaleX1, flScaleX2, 'x' );

				Manipulator_DrawPlane( vecOrigin, vecAxisUp, vecAxisLeft, vecAxisForward, 0, 0, 255, flScaleXY1, flScaleXY2, 'z' );
				Manipulator_DrawPlane( vecOrigin, vecAxisLeft, vecAxisForward, vecAxisUp, 0, 255, 0, flScaleXY1, flScaleXY2, 'y' );
				Manipulator_DrawPlane( vecOrigin, vecAxisForward, vecAxisUp, vecAxisLeft, 255, 0, 0, flScaleXY1, flScaleXY2, 'x' );

				break;
			}
			case KF_TRANSFORM_ROTATE:
			{
				local vecDeltaUp = Vector(), vecDeltaRight = Vector();
				VS.VectorVectors( originToView, vecDeltaRight, vecDeltaUp );

				DrawCircle( vecOrigin, flScaleR1, 0, 255, 255, true, -1, vecDeltaRight, vecDeltaUp );

				DrawCircleHalfBright( vecOrigin, flScaleX1, 255, 0, 0, true, -1, vecAxisForward, viewForward );
				DrawCircleHalfBright( vecOrigin, flScaleX1, 0, 255, 0, true, -1, vecAxisLeft, viewForward );
				DrawCircleHalfBright( vecOrigin, flScaleX1, 0, 0, 255, true, -1, vecAxisUp, viewForward );

				break;
			}
			case KF_TRANSFORM_SCREEN:
			{
				local vecDeltaUp = Vector(), vecDeltaRight = Vector();
				VS.VectorVectors( originToView, vecDeltaRight, vecDeltaUp );

				DrawCircle( vecOrigin, flScaleX1, 188, 114, 0, true, -1, vecDeltaRight, vecDeltaUp );
				DrawCircle( vecOrigin, flScaleR1, 188, 114, 0, true, -1, vecDeltaRight, vecDeltaUp );

				break;
			}
		}

		// If player is not looking at the current key, trace against the world for pivot point
		if ( !VS.IsRayIntersectingSphere( viewOrigin, rayDelta, vecOrigin, flScaleR1 ) )
		{
			local tr = VS.TraceLine( viewOrigin, viewOrigin + rayDelta, player.self, MASK_SOLID );
			vecCursor = tr.GetPos();

			// did the trace hit outside the world?
			if ( !( IsValidCoord( vecCursor.x ) && IsValidCoord( vecCursor.y ) && IsValidCoord( vecCursor.z ) ) )
			{
				vecCursor = vecOrigin;
			}
		}
		else
		{
			local t = VS.IntersectRayWithPlane( originToView, viewForward, viewForward*-1, 0.0 );
			vecCursor = viewOrigin + viewForward * t;
		}

		if ( m_bMouse1Down )
		{
			if ( !m_vecCameraOffset )
			{
				CameraSetEnabled(1);
				CameraSetOrigin( viewOrigin );
				CameraSetForward( viewForward );

				m_vecCameraPivotPoint = vecCursor;

				m_vecCameraOffset = viewOrigin - vecCursor;
				m_vecLastForwardFrame = viewForward;
			}
			else
			{
				local deltaForward = viewForward - m_vecLastForwardFrame;

				if ( !VS.VectorIsZero( deltaForward ) )
				{
					local pos = m_vecCameraPivotPoint - viewForward * m_vecCameraOffset.Length();
					CameraSetOrigin( pos );
					CameraSetForward( viewForward );

					pos.z -= kCrouchViewOffset;
					player.SetOrigin( pos );
				}

				m_vecLastForwardFrame = viewForward;
			}
		}
		else if ( m_vecCameraOffset )
		{
			CameraSetEnabled(0);
			m_vecCameraOffset = null;
		}
	}
	// ducking while translating
	else if ( nSelection & KF_TRANSFORM_PLANE_XYZ )
	{
		if ( 0 && !m_bDuckFixup )
		{
			local v = player.GetOrigin();
			v.z += 9.017594;
			player.SetOrigin( v );
			m_bDuckFixup = true;
		}

		// Snap to trace
		local tr = VS.TraceLine( viewOrigin, viewOrigin + rayDelta, player.self, MASK_SOLID );

		// Stick out of the wall
		local endpos = tr.GetPos();
		VS.VectorMA( endpos, 1.0, tr.GetNormal(), endpos );

		// Use the trace end if it landed inside the world
		if ( IsValidCoord( endpos.x ) && IsValidCoord( endpos.y ) && IsValidCoord( endpos.z ) )
		{
			vecOrigin = endpos;
		}

		if ( vecTransformPivot )
		{
			local vecTranslation = vecTransformPivot - vecPosition;
			VS.VectorCopy( vecOrigin, vecTransformPivot );
			element.SetPosition( vecOrigin - vecTranslation );
		}
		else
		{
			element.SetPosition( vecOrigin );
		}

		// Draw current manipulator
		switch ( m_nManipulatorMode )
		{
			case KF_TRANSFORM_TRANSLATE:
			{
				DrawRectFilled( vecOrigin, flScale2, 0, 255, 255, 255, -1, viewAngles );

				Manipulator_DrawAxis( vecOrigin, vecAxisUp, 0, 0, 255, flScaleX1, flScaleX2, 'z' );
				Manipulator_DrawAxis( vecOrigin, vecAxisLeft, 0, 255, 0, flScaleX1, flScaleX2, 'y' );
				Manipulator_DrawAxis( vecOrigin, vecAxisForward, 255, 0, 0, flScaleX1, flScaleX2, 'x' );

				Manipulator_DrawPlane( vecOrigin, vecAxisUp, vecAxisLeft, vecAxisForward, 0, 0, 255, flScaleXY1, flScaleXY2, 'z' );
				Manipulator_DrawPlane( vecOrigin, vecAxisLeft, vecAxisForward, vecAxisUp, 0, 255, 0, flScaleXY1, flScaleXY2, 'y' );
				Manipulator_DrawPlane( vecOrigin, vecAxisForward, vecAxisUp, vecAxisLeft, 255, 0, 0, flScaleXY1, flScaleXY2, 'x' );

				break;
			}
			case KF_TRANSFORM_SCREEN:
			{
				local vecDeltaUp = Vector(), vecDeltaRight = Vector();
				VS.VectorVectors( originToView, vecDeltaRight, vecDeltaUp );

				DrawCircle( vecOrigin, flScaleX1, 188, 114, 0, true, -1, vecDeltaRight, vecDeltaUp );
				DrawCircle( vecOrigin, flScaleR1, 188, 114, 0, true, -1, vecDeltaRight, vecDeltaUp );
				DrawRectFilled( vecOrigin, flScale2, 255, 156, 0, 25, -1, viewAngles );

				break;
			}
		}
	}
	// ducking while choosing a pivot
	else if ( nSelection & KF_TRANSFORM_PLANE_PIVOT )
	{
		if ( 0 && !m_bDuckFixup )
		{
			local v = player.GetOrigin();
			v.z += 9.017594;
			player.SetOrigin( v );
			m_bDuckFixup = true;
		}

		// snap to world
		local tr = VS.TraceLine( viewOrigin, viewOrigin + rayDelta, player.self, MASK_SOLID );
		vecOrigin = tr.GetPos();

		//Assert( vecTransformPivot );

		VS.VectorCopy( vecOrigin, vecTransformPivot );

		local vecNormal = tr.GetNormal();
		local vecRight = Vector(), vecUp = Vector();
		VS.VectorVectors( vecNormal, vecRight, vecUp );

		local vecDeltaUp = Vector(), vecDeltaRight = Vector();
		VS.VectorVectors( originToView, vecDeltaRight, vecDeltaUp );

		DrawCircle( vecOrigin, 16.0, 255, 255, 0, true, -1, vecRight, vecUp );
		DrawLine( vecOrigin, VS.VectorMA( vecOrigin, 32.0, vecNormal ), 255, 255, 0, true, -1 );

		DrawCircle( vecOrigin, flScaleX1, 188, 114, 0, true, -1, vecDeltaRight, vecDeltaUp );
		DrawCircle( vecOrigin, flScaleR1, 188, 114, 0, true, -1, vecDeltaRight, vecDeltaUp );
	}
	// ducking while rotating
	else
	{
		vecCursor = vecOrigin;
	}

	// draw cursor
	if ( vecCursor )
		return DrawRectFilled( vecCursor, flScale * 0.5, 255, 255, 255, 196, -1, viewAngles );
}


function GizmoToggleManipulationModes()
{
	m_nManipulatorMode = ( m_nManipulatorMode % KF_TRANSFORM_MODE_COUNT ) + 1;
}


class CUndoTransform extends CUndoElement
{
	function Undo()
	{
		VS.MatrixCopy( m_xformOld, m_pList[ m_nKeyIndex ].m_Transform );
		m_pList[ m_nKeyIndex ].UpdateFromMatrix();

		if ( Base.m_nCurKeyframe == m_nKeyIndex && Base.m_bSeeing )
		{
			Base.UpdateCamera();
		}
	}

	function Redo()
	{
		VS.MatrixCopy( m_xformNew, m_pList[ m_nKeyIndex ].m_Transform );
		m_pList[ m_nKeyIndex ].UpdateFromMatrix();

		if ( Base.m_nCurKeyframe == m_nKeyIndex && Base.m_bSeeing )
		{
			Base.UpdateCamera();
		}
	}

	function Desc()
	{
		local mode = "<ERROR>", type = "<ERROR>";

		switch ( m_nMode )
		{
			case KF_TRANSFORM_TRANSLATE:	mode = "Translate"; break;
			case KF_TRANSFORM_ROTATE:		mode = "Rotate"; break;
			case KF_TRANSFORM_SCREEN:
				switch ( m_nType )
				{
					case KF_TRANSFORM_PLANE_FREE:
					case KF_TRANSFORM_PLANE_SCREEN:	mode = "Rotate"; break;
					case KF_TRANSFORM_PLANE_XYZ:	mode = "Translate"; break;
				}
			default: mode += m_nMode;
		}

		switch ( m_nType )
		{
			case KF_TRANSFORM_PLANE_XYZ:
			case KF_TRANSFORM_PLANE_SCREEN:	type = "Screen"; break;
			case KF_TRANSFORM_PLANE_FREE:	type = "Free"; break;
			case KF_TRANSFORM_PLANE_X:		type = "X Axis"; break;
			case KF_TRANSFORM_PLANE_Y:		type = "Y Axis"; break;
			case KF_TRANSFORM_PLANE_Z:		type = "Z Axis"; break;
			case KF_TRANSFORM_PLANE_XY:		type = "XY Plane"; break;
			case KF_TRANSFORM_PLANE_YZ:		type = "YZ Plane"; break;
			case KF_TRANSFORM_PLANE_XZ:		type = "XZ Plane"; break;
			default: type += m_nType;
		}

		return Fmt( "%s (%s) #%d", mode, type, m_nKeyIndex );
	}

	m_pList = null;

	m_nKeyIndex = null;
	m_xformOld = null;
	m_xformNew = null;
	m_nMode = null;
	m_nType = null;
}

function GizmoOnMouse2Pressed()
{
	m_bMouse2Down = true;

	if ( m_nManipulatorMode == KF_TRANSFORM_SCREEN )
	{
		if ( m_bCameraTimeline )
		{
			if ( m_nCurKeyframe != -1 )
				m_KeyFrames[m_nCurKeyframe].m_vecTransformPivot = null;
		}
		else
		{
			if ( m_nCurElement != -1 )
				m_Elements[m_nCurElement].m_vecTransformPivot = null;
		}
	}

	// hold Mouse2 to rotate in translation mode
	if ( m_nManipulatorMode != KF_TRANSFORM_ROTATE && m_nManipulatorMode != KF_TRANSFORM_SCREEN )
	{
		m_nPrevManipulatorMode = m_nManipulatorMode;
		m_nManipulatorMode = KF_TRANSFORM_SCREEN;
		GizmoOnMouse1Pressed();
	}
}

function GizmoOnMouse2Released()
{
	m_bMouse2Down = false;

	if ( m_nPrevManipulatorMode )
	{
		GizmoOnMouse1Released();
		m_nManipulatorMode = m_nPrevManipulatorMode;
		m_nPrevManipulatorMode = 0;
	}
}

function GizmoOnMouse1Pressed()
{
	local nKeyIdx, pList;
	if ( m_bCameraTimeline )
	{
		nKeyIdx = m_nCurKeyframe;
		pList = m_KeyFrames.weakref();
	}
	else
	{
		nKeyIdx = m_nCurElement;
		pList = m_Elements.weakref();
	}

	// if there is an element to transform
	if ( nKeyIdx != -1 )
	{
		local pUndo = m_pUndoTransform = CUndoTransform();

		pUndo.m_pList = pList;
		pUndo.m_nKeyIndex = nKeyIdx;

		pUndo.m_xformOld = clone pUndo.m_pList[ pUndo.m_nKeyIndex ].m_Transform;
	}

	m_bMouse1Down = true;
}

function GizmoOnMouse1Released()
{
	if ( m_nManipulatorSelection && m_pUndoTransform &&
		m_nManipulatorSelection != KF_TRANSFORM_PLANE_PIVOT && // ignore for pivot change
		m_nManipulatorSelection != KF_TRANSFORM_CUSTOM ) // ignore for custom settings
	{
		m_pUndoTransform.m_xformNew = clone m_pUndoTransform.m_pList[ m_pUndoTransform.m_nKeyIndex ].m_Transform;
		m_pUndoTransform.m_nMode = m_nManipulatorMode;
		m_pUndoTransform.m_nType = m_nManipulatorSelection;
		PushUndo( m_pUndoTransform );
	}

	m_pUndoTransform = null;

	m_bMouse1Down = false;
	m_bMouseForceUp = false;

	player.SetMoveType( m_nMoveTypeRoam );

	if ( m_nManipulatorSelection )
	{
		PlaySound( SND_MANIPULATOR_MOVED );

		if ( m_vecLastViewAngles )
		{
			CameraSetEnabled( 0 );
			SetViewAngles( m_vecLastViewAngles );
			m_vecLastViewAngles = null;
		}

		m_nManipulatorSelection = 0;
		m_bDirty = true;

		//
		// Compile path around the current key frame for live feedback
		//

		// FIXME
		if ( m_bAutoFillBoundaries )
			return;

		local max = m_KeyFrames.len()-2;
		if ( max < 0 )
			return;

		local cur = m_nCurKeyframe;
		if ( cur < 2 )
			cur = 2;
		else if ( cur > max )
			cur = max;;

		// Get the frame count up to this point
		local offset = GetSampleCount( 1, cur-1 );

		// Copied from CompilePath
		for ( local nKeyIdx = cur-1; nKeyIdx <= cur; ++nKeyIdx )
		{
			if ( !( ( nKeyIdx + 2 ) in m_KeyFrames ) )
				break;

			local key = m_KeyFrames[nKeyIdx];

			local nSampleFrame = 0;

			local flCurTime = 0.0;
			local flKeyFrameTime = key.frametime;

			for ( ; flCurTime < flKeyFrameTime; flCurTime += g_FrameTime, ++nSampleFrame )
			{
				local i = offset + nSampleFrame;

				// This key might be out of the existing path range
				if ( !(i in m_PathData) )
					return;

				local t = flCurTime / flKeyFrameTime;

				local org = Vector();
				local ang = Vector();
				SplineOrigin( nKeyIdx, t, org );
				SplineAngles( nKeyIdx, t, ang );

				local frame = m_PathData[ i ];
				frame.origin = org;
				frame.angles = ang;
			}

			if ( nSampleFrame != (flKeyFrameTime / g_FrameTime).tointeger() )
			{
				Msg(Fmt( "\nERROR: Compiled frame count does not match keyframe sample count value! %d, %d\n",
					nSampleFrame,
					(key.frametime / g_FrameTime).tointeger() ));
			}

			offset += nSampleFrame;
		}
	};
}

function ShowGizmo( i = null )
{
	if ( i == null )
		i = !m_bGizmoEnabled;

	m_bGizmoEnabled = !!i;

	Msg("3D manipulator " + m_bGizmoEnabled.tointeger() + "\n");

	if ( m_bGizmoEnabled )
	{
		SetThinkEnabled( m_hThinkAnim, false );
		m_nAnimKeyframeIdx = -1;
	}
	else
	{
		SetThinkEnabled( m_hThinkAnim, true );
	};

	return PlaySound( SND_BUTTON );
}


//--------------------------------------------------------------
//--------------------------------------------------------------


class CBaseElement
{
	m_Transform = null;
	m_vecPosition = null;
	m_vecTransformPivot = null;

	constructor()
	{
		m_Transform = matrix3x4_t();
		VS.SetIdentityMatrix( m_Transform );
		m_vecPosition = Vector();
	}

	function Create()
	{
		Assert(0)
	}

	function Destroy()
	{
		Assert(0)
	}

	function SetParams( params )
	{
		Assert(0)
	}

	function SetPosition( vec )
	{
		Assert(0)
	}

	function SetRotation( ang )
	{
		Assert(0)
	}

	function UpdateFromMatrix()
	{
		Assert(0)
	}

	static function GetTotalCountFromSerialisedBuffer( buf )
	{
		Assert(0)
	}

	function Serialise()
	{
		Assert(0)
	}

	function Unserialise( buf, idx )
	{
		Assert(0)
	}

	function Desc()
	{
		return "";
	}

	function _tostring()
	{
		return Desc();
	}

	function _typeof()
	{
		return "CBaseElement";
	}

	DrawFrustum = dummy;
	Fmt = Fmt;
}


//
// Basic light element
//

const kLightSliderVertOffset = 12.0;
const kLightSliderWidth = 24.0;
const kLightSliderHeight = 2.5;
const kLightSliderGap = 1.5;

const kLightSlider_fov = 1;
const kLightSlider_brightness = 2;
const kLightSlider_nearz = 4;
const kLightSlider_farz = 8;
const kLightSlider_r = 16;
const kLightSlider_g = 32;
const kLightSlider_b = 64;

const kLightSlider_rgb_min = 0.0;
const kLightSlider_rgb_max = 255.0;

const kLightSlider_fov_min = 1.0;
const kLightSlider_fov_max = 179.0;

const kLightSlider_brightness_min = 0.0;
const kLightSlider_brightness_max = 100.0;

const kLightSlider_zplane_min = 1.0;
const kLightSlider_zplane_max = 2048.0;


class CLight extends CBaseElement
{
	m_hEntity = null;
	m_flFarZ = 750.0;
	m_flNearZ = 4.0;
	m_flFov = 45.0;
	m_clr = 0xffffffff;
	m_flBrightness = 2.0;
	m_iStyle = 0;
	m_bEnableShadows = false;

	function Create()
	{
		m_hEntity = VS.CreateEntity( "env_projectedtexture",
		{
			fov = m_flFov,
			brightness = m_flBrightness,
			nearz = m_flNearZ,
			farz = m_flFarZ,
			colortransitiontime = 64.0,
			spawnflags = 1
		} );

		EntFireByHandle( m_hEntity, "AlwaysUpdateOn" );
	}

	function Destroy()
	{
		if ( m_bEnableShadows )
		{
			_KF_.g_nShadowLightCount--;
			m_bEnableShadows = false;
		}

		m_hEntity.Destroy();
		m_hEntity = null;
	}

	function SetParams( params )
	{
		if ( "fov" in params )
		{
			m_flFov = params.fov.tofloat();
			m_hEntity.__KeyValueFromFloat( "lightfov", params.fov );
		}

		if ( "color" in params )
		{
			local r = 255, g = 255, b = 255, a = 255;

			switch ( typeof params.color )
			{
			case "Vector":
				r = params.color.x.tointeger();
				g = params.color.y.tointeger();
				b = params.color.z.tointeger();
				break;

			case "string":
				local tmp = split( params.color, " " );
				r = tmp[0].tointeger();
				g = tmp[1].tointeger();
				b = tmp[2].tointeger();
				if ( 3 in tmp )
					a = tmp[3].tointeger();
				break;

			default:
				Msg("invalid color parameter <"+(typeof params.color)+">\n");
			}

			m_clr = (r << 24) | (g << 16) | (b << 8) | (a);

			m_hEntity.__KeyValueFromString( "lightcolor", Fmt( "%d %d %d %d", r, g, b, a ) );
		}

		if ( "nearz" in params )
		{
			m_flNearZ = params.nearz.tofloat();
			m_hEntity.__KeyValueFromFloat( "nearz", params.nearz );
		}

		if ( "farz" in params )
		{
			m_flFarZ = params.farz.tofloat();
			m_hEntity.__KeyValueFromFloat( "farz", params.farz );
		}

		if ( "brightness" in params )
		{
			m_flBrightness = params.brightness.tofloat();
			m_hEntity.__KeyValueFromFloat( "brightnessscale", params.brightness );
		}

		if ( "enableshadows" in params )
		{
			if ( params.enableshadows && _KF_.g_nShadowLightCount > 0 )
			{
				Msg( "There exists a shadow casting light, disable it first to enable shadows on another.\n" );
			}
			else
			{
				if ( params.enableshadows && !m_bEnableShadows )
				{
					_KF_.g_nShadowLightCount++;
				}
				else if ( !params.enableshadows && m_bEnableShadows )
				{
					_KF_.g_nShadowLightCount--;
				}

				m_bEnableShadows = !!params.enableshadows;
				m_hEntity.__KeyValueFromInt( "enableshadows", params.enableshadows );
			}
		}

		//if ( "ambient" in params )
		//{
		//	m_flAmbient = params.ambient.tofloat();
		//	m_hEntity.__KeyValueFromFloat( "ambient", params.ambient );
		//}

		//if ( "projection_size" in params )
		//{
		//	m_flProjectionSize = params.projection_size.tofloat();
		//	m_hEntity.__KeyValueFromFloat( "projection_size", params.projection_size );
		//}

		if ( "style" in params )
		{
			m_iStyle = params.style;
			m_hEntity.__KeyValueFromInt( "style", params.style );
		}

		//if ( "defaultstyle" in params )
		//{
		//	m_iDefaultStyle = params.defaultstyle;
		//	m_hEntity.__KeyValueFromInt( "defaultstyle", params.defaultstyle );
		//}

		//if ( "pattern" in params )
		//{
		//	m_szPattern = params.pattern;
		//	m_hEntity.__KeyValueFromString( "pattern", params.pattern );
		//}

		if ( "shadowquality" in params )
		{
			m_hEntity.__KeyValueFromInt( "shadowquality", params.shadowquality );
		}

		if ( "texturename" in params )
		{
			m_hEntity.__KeyValueFromString( "texturename", params.texturename );
		}
	}

	function SetPosition( vec )
	{
		VS.VectorCopy( vec, m_vecPosition );
		VS.MatrixSetColumn( vec, 3, m_Transform );
		m_hEntity.SetAbsOrigin( vec );
	}

	function SetRotation( ang )
	{
		VS.AngleMatrix( ang, m_vecPosition, m_Transform );
		SetEntityAngles( m_hEntity, ang );
	}

	function UpdateFromMatrix()
	{
		local angles = Vector();
		VS.MatrixAngles( m_Transform, angles, m_vecPosition );

		m_hEntity.SetAbsOrigin( m_vecPosition );
		SetEntityAngles( m_hEntity, angles );
	}

	function DrawFrustum()
	{
		local forward = VS.MatrixGetColumn( m_Transform, 0 ) * 1;
		local right = VS.MatrixGetColumn( m_Transform, 1 ) * 1;
		local up = VS.MatrixGetColumn( m_Transform, 2 ) * 1;

		return VS.DrawViewFrustum(
			m_vecPosition,
			forward,
			right,
			up,
			m_flFov,
			1.0,
			m_flNearZ,
			m_flFarZ,
			255, 255, 255, false,
			-1 );
	}

	static function GetTotalCountFromSerialisedBuffer( buf )
	{
		return buf.len() / 12;
	}

	function Serialise()
	{
		local angles = Vector();
		VS.MatrixAngles( m_Transform, angles, m_vecPosition );

		return Fmt( "\t\t%f,%f,%f,%f,%f,%f,0x%02x%02x%02x%02x,%f,%f,%f,%f,%i,\n",
			m_vecPosition.x, m_vecPosition.y, m_vecPosition.z,
			angles.x, angles.y, angles.z,
			(m_clr >> 24) & 0xff, (m_clr >> 16) & 0xff, (m_clr >> 8) & 0xff, (m_clr) & 0xff,
			m_flBrightness,
			m_flFov,
			m_flNearZ,
			m_flFarZ,
			m_iStyle );
	}

	function Unserialise( buf, idx )
	{
		if ( !m_hEntity )
			Create();

		m_vecPosition.x = buf[ idx++ ];
		m_vecPosition.y = buf[ idx++ ];
		m_vecPosition.z = buf[ idx++ ];

		local angles = Vector();
		angles.x = buf[ idx++ ];
		angles.y = buf[ idx++ ];
		angles.z = buf[ idx++ ];

		m_clr = buf[ idx++ ];
		m_flBrightness = buf[ idx++ ];
		m_flFov = buf[ idx++ ];
		m_flNearZ = buf[ idx++ ];
		m_flFarZ = buf[ idx++ ];
		m_iStyle = buf[ idx++ ];

		m_hEntity.__KeyValueFromString( "lightcolor",
			Fmt( "%d %d %d %d", (m_clr >> 24) & 0xff, (m_clr >> 16) & 0xff, (m_clr >> 8) & 0xff, (m_clr) & 0xff ) );
		m_hEntity.__KeyValueFromFloat( "brightnessscale", m_flBrightness );
		m_hEntity.__KeyValueFromFloat( "lightfov", m_flFov );
		m_hEntity.__KeyValueFromFloat( "nearz", m_flNearZ );
		m_hEntity.__KeyValueFromFloat( "farz", m_flFarZ );
		m_hEntity.__KeyValueFromFloat( "style", m_iStyle );

		VS.AngleMatrix( angles, m_vecPosition, m_Transform );
		UpdateFromMatrix();

		return idx;
	}

	function Desc()
	{
		return Fmt( "[%i] light", m_hEntity.entindex() );
	}

	function _typeof()
	{
		return "CLight";
	}

	m_nManipulatorSelection = 0;
	m_flLastPosition = 0.0;
	m_flInitialPosition = 0.0;

	DrawBoxAngles = DrawBoxAngles;
	DrawProgressBar = DrawProgressBar;
}


//
// Slider manipulator
//
// TODO: Refactor this, too much duplicate code!
// Keeping it like this for now just to have something working.
//

function CLight::Manip_IsIntersecting( vecOrigin, viewOrigin, rayDelta, originToView, flScale )

{
	local kLightSliderVertOffset = flScale * kLightSliderVertOffset;
	local kLightSliderWidth = flScale * kLightSliderWidth;
	local kLightSliderHeight = flScale * kLightSliderHeight;
	local kLightSliderGap = flScale * kLightSliderGap;

	local vecDeltaUp = Vector(), vecDeltaRight = Vector(), deltaAngles = Vector();
	VS.VectorVectors( originToView, vecDeltaRight, vecDeltaUp );
	VS.VectorAngles( originToView, deltaAngles );

	local vecNormal = originToView;
	vecNormal.Norm();

	local t = 0.0;

	vecOrigin -= vecDeltaRight * (flScale * 24.0) - vecDeltaUp * kLightSliderVertOffset;

	if ( t = IntersectRayWithRect( viewOrigin, rayDelta, vecOrigin, vecNormal, vecDeltaRight, vecDeltaUp, kLightSliderWidth, kLightSliderHeight ) )
	{
		m_nManipulatorSelection = kLightSlider_brightness;
		m_flLastPosition = ( vecOrigin.Dot( vecDeltaRight ) - (viewOrigin + rayDelta * t).Dot( vecDeltaRight ) ) / kLightSliderWidth;
		m_flInitialPosition = VS.RemapValClamped( m_flBrightness, kLightSlider_brightness_min, kLightSlider_brightness_max, 0.0, 1.0 );

		DrawProgressBar( vecOrigin, VS.RemapValClamped( m_flBrightness, kLightSlider_brightness_min, kLightSlider_brightness_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 250, 250, 250, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( m_flBrightness, kLightSlider_brightness_min, kLightSlider_brightness_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 100, 100, 100, deltaAngles );
	}

	vecOrigin -= vecDeltaUp * (kLightSliderHeight + kLightSliderGap);

	if ( !t && (t = IntersectRayWithRect( viewOrigin, rayDelta, vecOrigin, vecNormal, vecDeltaRight, vecDeltaUp, kLightSliderWidth, kLightSliderHeight )) )
	{
		m_nManipulatorSelection = kLightSlider_fov;
		m_flLastPosition = ( vecOrigin.Dot( vecDeltaRight ) - (viewOrigin + rayDelta * t).Dot( vecDeltaRight ) ) / kLightSliderWidth;
		m_flInitialPosition = VS.RemapValClamped( m_flFov, kLightSlider_fov_min, kLightSlider_fov_max, 0.0, 1.0 );

		DrawProgressBar( vecOrigin, VS.RemapValClamped( m_flFov, kLightSlider_fov_min, kLightSlider_fov_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 250, 250, 250, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( m_flFov, kLightSlider_fov_min, kLightSlider_fov_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 100, 100, 100, deltaAngles );
	}

	vecOrigin -= vecDeltaUp * (kLightSliderHeight + kLightSliderGap);

	if ( !t && (t = IntersectRayWithRect( viewOrigin, rayDelta, vecOrigin, vecNormal, vecDeltaRight, vecDeltaUp, kLightSliderWidth, kLightSliderHeight )) )
	{
		m_nManipulatorSelection = kLightSlider_nearz;
		m_flLastPosition = ( vecOrigin.Dot( vecDeltaRight ) - (viewOrigin + rayDelta * t).Dot( vecDeltaRight ) ) / kLightSliderWidth;
		m_flInitialPosition = VS.RemapValClamped( m_flNearZ, kLightSlider_zplane_min, kLightSlider_zplane_max, 0.0, 1.0 );

		DrawProgressBar( vecOrigin, VS.RemapValClamped( m_flNearZ, kLightSlider_zplane_min, kLightSlider_zplane_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 250, 250, 250, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( m_flNearZ, kLightSlider_zplane_min, kLightSlider_zplane_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 100, 100, 100, deltaAngles );
	}

	vecOrigin -= vecDeltaUp * (kLightSliderHeight + kLightSliderGap);

	if ( !t && (t = IntersectRayWithRect( viewOrigin, rayDelta, vecOrigin, vecNormal, vecDeltaRight, vecDeltaUp, kLightSliderWidth, kLightSliderHeight )) )
	{
		m_nManipulatorSelection = kLightSlider_farz;
		m_flLastPosition = ( vecOrigin.Dot( vecDeltaRight ) - (viewOrigin + rayDelta * t).Dot( vecDeltaRight ) ) / kLightSliderWidth;
		m_flInitialPosition = VS.RemapValClamped( m_flFarZ, kLightSlider_zplane_min, kLightSlider_zplane_max, 0.0, 1.0 );

		DrawProgressBar( vecOrigin, VS.RemapValClamped( m_flFarZ, kLightSlider_zplane_min, kLightSlider_zplane_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 250, 250, 250, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( m_flFarZ, kLightSlider_zplane_min, kLightSlider_zplane_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 100, 100, 100, deltaAngles );
	}

	vecOrigin -= vecDeltaUp * (kLightSliderHeight + kLightSliderGap);

	if ( !t && (t = IntersectRayWithRect( viewOrigin, rayDelta, vecOrigin, vecNormal, vecDeltaRight, vecDeltaUp, kLightSliderWidth, kLightSliderHeight )) )
	{
		m_nManipulatorSelection = kLightSlider_r;
		m_flLastPosition = ( vecOrigin.Dot( vecDeltaRight ) - (viewOrigin + rayDelta * t).Dot( vecDeltaRight ) ) / kLightSliderWidth;
		m_flInitialPosition = VS.RemapValClamped( (m_clr >> 24) & 0xff, kLightSlider_rgb_min, kLightSlider_rgb_max, 0.0, 1.0 );

		DrawProgressBar( vecOrigin, VS.RemapValClamped( (m_clr >> 24) & 0xff, kLightSlider_rgb_min, kLightSlider_rgb_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 250, 10, 10, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( (m_clr >> 24) & 0xff, kLightSlider_rgb_min, kLightSlider_rgb_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 100, 10, 10, deltaAngles );
	}

	vecOrigin -= vecDeltaUp * (kLightSliderHeight + kLightSliderGap);

	if ( !t && (t = IntersectRayWithRect( viewOrigin, rayDelta, vecOrigin, vecNormal, vecDeltaRight, vecDeltaUp, kLightSliderWidth, kLightSliderHeight )) )
	{
		m_nManipulatorSelection = kLightSlider_g;
		m_flLastPosition = ( vecOrigin.Dot( vecDeltaRight ) - (viewOrigin + rayDelta * t).Dot( vecDeltaRight ) ) / kLightSliderWidth;
		m_flInitialPosition = VS.RemapValClamped( (m_clr >> 16) & 0xff, kLightSlider_rgb_min, kLightSlider_rgb_max, 0.0, 1.0 );

		DrawProgressBar( vecOrigin, VS.RemapValClamped( (m_clr >> 16) & 0xff, kLightSlider_rgb_min, kLightSlider_rgb_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 10, 250, 10, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( (m_clr >> 16) & 0xff, kLightSlider_rgb_min, kLightSlider_rgb_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 10, 100, 10, deltaAngles );
	}

	vecOrigin -= vecDeltaUp * (kLightSliderHeight + kLightSliderGap);

	if ( !t && (t = IntersectRayWithRect( viewOrigin, rayDelta, vecOrigin, vecNormal, vecDeltaRight, vecDeltaUp, kLightSliderWidth, kLightSliderHeight )) )
	{
		m_nManipulatorSelection = kLightSlider_b;
		m_flLastPosition = ( vecOrigin.Dot( vecDeltaRight ) - (viewOrigin + rayDelta * t).Dot( vecDeltaRight ) ) / kLightSliderWidth;
		m_flInitialPosition = VS.RemapValClamped( (m_clr >> 8) & 0xff, kLightSlider_rgb_min, kLightSlider_rgb_max, 0.0, 1.0 );

		DrawProgressBar( vecOrigin, VS.RemapValClamped( (m_clr >> 8) & 0xff, kLightSlider_rgb_min, kLightSlider_rgb_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 10, 10, 250, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( (m_clr >> 8) & 0xff, kLightSlider_rgb_min, kLightSlider_rgb_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 10, 10, 100, deltaAngles );
	}

	return t * MAX_TRACE_LENGTH;
}


function CLight::Manip_Manipulating( vecOrigin, viewOrigin, rayDelta, originToView, flScale )
{
	local kLightSliderVertOffset = flScale * kLightSliderVertOffset;
	local kLightSliderWidth = flScale * kLightSliderWidth;
	local kLightSliderHeight = flScale * kLightSliderHeight;
	local kLightSliderGap = flScale * kLightSliderGap;

	local nSelection = m_nManipulatorSelection;

	local vecDeltaUp = Vector(), vecDeltaRight = Vector(), deltaAngles = Vector();
	VS.VectorVectors( originToView, vecDeltaRight, vecDeltaUp );
	VS.VectorAngles( originToView, deltaAngles );

	local vecNormal = originToView*1;
	vecNormal.Norm();

	vecOrigin -= vecDeltaRight * (flScale * 24.0) - vecDeltaUp * kLightSliderVertOffset;

	if ( nSelection == kLightSlider_brightness )
	{
		local t = VS.IntersectRayWithPlane( viewOrigin, rayDelta, vecNormal, vecNormal.Dot( vecOrigin ) );
		local vecEndPos = viewOrigin + rayDelta * t;
		local flPercent = ( vecOrigin.Dot( vecDeltaRight ) - vecEndPos.Dot( vecDeltaRight ) ) / kLightSliderWidth;
		flPercent = clamp( m_flInitialPosition + flPercent - m_flLastPosition, 0.0, 1.0 );

		m_flBrightness = flPercent * (kLightSlider_brightness_max-kLightSlider_brightness_min) + kLightSlider_brightness_min;
		m_hEntity.__KeyValueFromFloat( "brightnessscale", m_flBrightness );

		DrawProgressBar( vecOrigin, flPercent, kLightSliderWidth, kLightSliderHeight, 250, 250, 250, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( m_flBrightness, kLightSlider_brightness_min, kLightSlider_brightness_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 100, 100, 100, deltaAngles );
	}

	vecOrigin -= vecDeltaUp * (kLightSliderHeight + kLightSliderGap);

	if ( nSelection == kLightSlider_fov )
	{
		local t = VS.IntersectRayWithPlane( viewOrigin, rayDelta, vecNormal, vecNormal.Dot( vecOrigin ) );
		local vecEndPos = viewOrigin + rayDelta * t;
		local flPercent = ( vecOrigin.Dot( vecDeltaRight ) - vecEndPos.Dot( vecDeltaRight ) ) / kLightSliderWidth;
		flPercent = clamp( m_flInitialPosition + flPercent - m_flLastPosition, 0.0, 1.0 );

		m_flFov = flPercent * (kLightSlider_fov_max-kLightSlider_fov_min) + kLightSlider_fov_min;
		m_hEntity.__KeyValueFromFloat( "lightfov", m_flFov );

		DrawProgressBar( vecOrigin, flPercent, kLightSliderWidth, kLightSliderHeight, 250, 250, 250, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( m_flFov, kLightSlider_fov_min, kLightSlider_fov_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 100, 100, 100, deltaAngles );
	}

	vecOrigin -= vecDeltaUp * (kLightSliderHeight + kLightSliderGap);

	if ( nSelection == kLightSlider_nearz )
	{
		local t = VS.IntersectRayWithPlane( viewOrigin, rayDelta, vecNormal, vecNormal.Dot( vecOrigin ) );
		local vecEndPos = viewOrigin + rayDelta * t;
		local flPercent = ( vecOrigin.Dot( vecDeltaRight ) - vecEndPos.Dot( vecDeltaRight ) ) / kLightSliderWidth;
		flPercent = clamp( m_flInitialPosition + flPercent - m_flLastPosition, 0.0, 1.0 );

		m_flNearZ = flPercent * (kLightSlider_zplane_max-kLightSlider_zplane_min) + kLightSlider_zplane_min;

		if ( m_flFarZ < m_flNearZ )
			m_flNearZ = m_flFarZ-1.0;

		m_hEntity.__KeyValueFromFloat( "nearz", m_flNearZ );

		DrawProgressBar( vecOrigin, flPercent, kLightSliderWidth, kLightSliderHeight, 250, 250, 250, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( m_flNearZ, kLightSlider_zplane_min, kLightSlider_zplane_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 100, 100, 100, deltaAngles );
	}

	vecOrigin -= vecDeltaUp * (kLightSliderHeight + kLightSliderGap);

	if ( nSelection == kLightSlider_farz )
	{
		local t = VS.IntersectRayWithPlane( viewOrigin, rayDelta, vecNormal, vecNormal.Dot( vecOrigin ) );
		local vecEndPos = viewOrigin + rayDelta * t;
		local flPercent = ( vecOrigin.Dot( vecDeltaRight ) - vecEndPos.Dot( vecDeltaRight ) ) / kLightSliderWidth;
		flPercent = clamp( m_flInitialPosition + flPercent - m_flLastPosition, 0.0, 1.0 );

		m_flFarZ = flPercent * (kLightSlider_zplane_max-kLightSlider_zplane_min) + kLightSlider_zplane_min;

		if ( m_flFarZ < m_flNearZ )
			m_flFarZ = m_flNearZ+1.0;

		m_hEntity.__KeyValueFromFloat( "farz", m_flFarZ );

		DrawProgressBar( vecOrigin, flPercent, kLightSliderWidth, kLightSliderHeight, 250, 250, 250, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( m_flFarZ, kLightSlider_zplane_min, kLightSlider_zplane_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 100, 100, 100, deltaAngles );
	}

	vecOrigin -= vecDeltaUp * (kLightSliderHeight + kLightSliderGap);

	if ( nSelection == kLightSlider_r )
	{
		local t = VS.IntersectRayWithPlane( viewOrigin, rayDelta, vecNormal, vecNormal.Dot( vecOrigin ) );
		local vecEndPos = viewOrigin + rayDelta * t;
		local flPercent = ( vecOrigin.Dot( vecDeltaRight ) - vecEndPos.Dot( vecDeltaRight ) ) / kLightSliderWidth;
		flPercent = clamp( m_flInitialPosition + flPercent - m_flLastPosition, 0.0, 1.0 );

		local r = flPercent * (kLightSlider_rgb_max-kLightSlider_rgb_min) + kLightSlider_rgb_min;
		m_clr = ( 0x00ffffff & m_clr ) | ( r.tointeger() << 24 );
		m_hEntity.__KeyValueFromString( "lightcolor", Fmt( "%d %d %d %d", m_clr >> 24, (m_clr >> 16) & 0xff, (m_clr >> 8) & 0xff, (m_clr) & 0xff ) );

		DrawProgressBar( vecOrigin, flPercent, kLightSliderWidth, kLightSliderHeight, 250, 10, 10, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( (m_clr >> 24) & 0xff, kLightSlider_rgb_min, kLightSlider_rgb_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 100, 10, 10, deltaAngles );
	}

	vecOrigin -= vecDeltaUp * (kLightSliderHeight + kLightSliderGap);

	if ( nSelection == kLightSlider_g )
	{
		local t = VS.IntersectRayWithPlane( viewOrigin, rayDelta, vecNormal, vecNormal.Dot( vecOrigin ) );
		local vecEndPos = viewOrigin + rayDelta * t;
		local flPercent = ( vecOrigin.Dot( vecDeltaRight ) - vecEndPos.Dot( vecDeltaRight ) ) / kLightSliderWidth;
		flPercent = clamp( m_flInitialPosition + flPercent - m_flLastPosition, 0.0, 1.0 );

		local g = flPercent * (kLightSlider_rgb_max-kLightSlider_rgb_min) + kLightSlider_rgb_min;
		m_clr = ( 0xff00ffff & m_clr ) | ( g.tointeger() << 16 );
		m_hEntity.__KeyValueFromString( "lightcolor", Fmt( "%d %d %d %d", m_clr >> 24, (m_clr >> 16) & 0xff, (m_clr >> 8) & 0xff, (m_clr) & 0xff ) );

		DrawProgressBar( vecOrigin, flPercent, kLightSliderWidth, kLightSliderHeight, 10, 250, 10, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( (m_clr >> 16) & 0xff, kLightSlider_rgb_min, kLightSlider_rgb_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 10, 100, 10, deltaAngles );
	}

	vecOrigin -= vecDeltaUp * (kLightSliderHeight + kLightSliderGap);

	if ( nSelection == kLightSlider_b )
	{
		local t = VS.IntersectRayWithPlane( viewOrigin, rayDelta, vecNormal, vecNormal.Dot( vecOrigin ) );
		local vecEndPos = viewOrigin + rayDelta * t;
		local flPercent = ( vecOrigin.Dot( vecDeltaRight ) - vecEndPos.Dot( vecDeltaRight ) ) / kLightSliderWidth;
		flPercent = clamp( m_flInitialPosition + flPercent - m_flLastPosition, 0.0, 1.0 );

		local b = flPercent * (kLightSlider_rgb_max-kLightSlider_rgb_min) + kLightSlider_rgb_min;
		m_clr = ( 0xffff00ff & m_clr ) | ( b.tointeger() << 8 );
		m_hEntity.__KeyValueFromString( "lightcolor", Fmt( "%d %d %d %d", m_clr >> 24, (m_clr >> 16) & 0xff, (m_clr >> 8) & 0xff, (m_clr) & 0xff ) );

		DrawProgressBar( vecOrigin, flPercent, kLightSliderWidth, kLightSliderHeight, 10, 10, 250, deltaAngles );
	}
	else
	{
		DrawProgressBar( vecOrigin, VS.RemapValClamped( (m_clr >> 8) & 0xff, kLightSlider_rgb_min, kLightSlider_rgb_max, 0.0, 1.0 ), kLightSliderWidth, kLightSliderHeight, 10, 10, 100, deltaAngles );
	}
}


//--------------------------------------------------------------
//--------------------------------------------------------------


function CreateLight()
{
	local light = CLight();
	m_Elements.append( light );

	light.Create();

	light.SetPosition( CurrentViewOrigin() );
	light.SetRotation( CurrentViewAngles() );

	Msg(Fmt( "create %s\n", light.Desc() ));

	return PlaySound( SND_BUTTON );
}

function SetElementParamaters( params )
{
	if ( m_bCameraTimeline )
		return;

	if ( m_nCurElement == -1 )
		return;

	local elem = m_Elements[ m_nCurElement ];
	elem.SetParams( params );

	Msg( "Set parameters of " + elem.Desc() + "\n" );

	return PlaySound( SND_BUTTON );
}

function DuplicateElement()
{
	if ( m_bCameraTimeline )
		return;

	if ( m_nCurElement == -1 )
		return;

	local elem = m_Elements[ m_nCurElement ];

	// NOTE: This is not very efficient
	local buf = compilestring( Fmt( "return [%s]", elem.Serialise().slice( 0, -2 ) ) )();
	local dupe = this[typeof elem]();
	dupe.Unserialise( buf, 0 );
	m_Elements.append( dupe );

	Msg(Fmt( "Duplicated %s (%s)\n", elem.Desc(), dupe.Desc() ));

	return PlaySound( SND_BUTTON );
}


function ClearLights()
{
	for ( local i = m_Elements.len(); i--; )
	{
		local elem = m_Elements[i];
		if ( typeof elem == "CLight" )
		{
			elem.Destroy();
			m_Elements.remove(i);
		}
	}

	m_nSelectedKeyframe = -1;
	m_nCurElement = -1;
}


// kf_elements
function ToggleElementSpace()
{
	m_bCameraTimeline = !m_bCameraTimeline;

	m_nSelectedKeyframe = -1;
	m_nCurElement = -1;
	m_nCurKeyframe = -1;

	if ( m_bSeeing )
		SeeKeyframe( 1, 0 );
}

// kf_guides
function ToggleCameraGuides()
{
	m_bCameraGuides = !m_bCameraGuides;

	Msg(Fmt( "camera guides %d\n", m_bCameraGuides.tointeger() ));

	return PlaySound( SND_BUTTON );
}

function SetWindowResolution( w, h )
{
	w = w.tofloat();
	h = h.tofloat();

	m_flWindowAspectRatio = w / h;

	Msg(Fmt( "Set resolution to %gx%g\n", w, h ));
}


//--------------------------------------------------------------
//--------------------------------------------------------------


function PushUndo( pUndoElem )
{
	local nStackLen = m_UndoStack.len();

	// truncate future
	// check range to reduce unnecessary shrink reallocations
	if ( m_nUndoLevel < nStackLen )
		m_UndoStack.resize( m_nUndoLevel );

	if ( nStackLen >= m_nMaxUndoDepth )
	{
		m_nUndoLevel--;
		m_UndoStack.remove(0);
	};

	m_UndoStack.append( pUndoElem );
	m_nUndoLevel++;
}

// kf_undo
function Undo()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_UndoStack.len() || m_nUndoLevel <= 0 || m_pUndoTransform || m_pUndoLoad )
		return MsgFail("cannot undo\n");

	m_nUndoLevel--;
	local undo = m_UndoStack[ m_nUndoLevel ];
	undo.Undo();

	// Truncate if there are no more redos
	if ( !undo.CanRedo() )
	{
		m_UndoStack.resize( m_nUndoLevel );
	};

	Msg(Fmt( "Undo: %s\n", undo.Desc() ));

	PrintUndoStack( 1 );

	m_bDirty = true;

	return PlaySound( SND_BUTTON );
}

// kf_redo
function Redo()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_UndoStack.len() || m_nUndoLevel > m_UndoStack.len() - 1 || m_pUndoTransform || m_pUndoLoad )
		return MsgFail("cannot redo\n");

	local undo = m_UndoStack[ m_nUndoLevel ];
	m_nUndoLevel++;
	undo.Redo();

	Msg(Fmt( "Redo: %s\n", undo.Desc() ));

	PrintUndoStack( 1 );

	m_bDirty = true;

	return PlaySound( SND_BUTTON );
}

// kf_undo_history
function PrintUndoStack( halfDepth = 8 )
{
	local v = m_nUndoLevel - 1;
	local c = m_UndoStack.len() - 1;

	local i = v - halfDepth;
	local j = v + halfDepth;

	// lower limit
	if ( i < 0 )
	{
		i = 0;
		j = halfDepth*2;
	};

	// upper limit
	if ( j > c )
	{
		j = c;
		i = j - halfDepth*2;

		// less than 16 actions
		if ( i < 0 )
			i = 0;
	};

	local lower = i > 0, upper = j < c;

	Msg( "+-------------------------------+\n" );
	Msg(Fmt( "| Action history    [%3d / %3d] |\n", v, c ));

	if ( lower )
	{
		Msg( "|         ^\n" );
	}
	else
	{
		Msg( "+-------------------------------+\n" );
	}

	for ( ; i <= j; ++i )
	{
		if ( i == v ) // head
		{
			Msg(Fmt( "|===> %3d : %s\n", i, m_UndoStack[i].Desc() ));
		}
		else
		{
			Msg(Fmt( "|     %3d : %s\n", i, m_UndoStack[i].Desc() ));
		}
	}

	if ( upper )
	{
		Msg( "|         v\n" );
	}
	else
	{
		Msg( "+-------------------------------+\n" );
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
		return MsgFail("Cannot copy while edit mode is disabled.\n");

	if ( m_bSeeing )
		return MsgFail("Cannot copy while seeing!\n");

	local key = m_KeyFrames[ m_nCurKeyframe ];

	SetViewOrigin( key.origin );
	SetViewForward( key.forward );

	MsgHint(Fmt( "Copied keyframe #%d\n", m_nCurKeyframe ));
	return PlaySound( SND_BUTTON );
}

function StopReplaceLerp()
{
	m_pLerpFrustum = null;
	m_hLerpKeyframe = null;
	m_flLerpKeyAnim = null;
}


class CUndoReplaceKeyframe extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].Copy( m_pOldFrame );

		if ( Base.m_nCurKeyframe == m_nKeyIndex && Base.m_bSeeing )
		{
			Base.UpdateCamera();
		}
	}

	function Redo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].Copy( m_pNewFrame );

		if ( Base.m_nCurKeyframe == m_nKeyIndex && Base.m_bSeeing )
		{
			Base.UpdateCamera();
		}
	}

	function Desc()
	{
		return "replace #" + m_nKeyIndex;
	}

	m_nKeyIndex = null;
	m_pOldFrame = null;
	m_pNewFrame = null;
}

// kf_replace
function ReplaceKeyframe( bClick = 0 )
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("Cannot insert keyframe while edit mode is disabled.\n");

	// Unsee and activate click to replace at current position
	if ( m_bSeeing )
	{
		SeeKeyframe( 1, 0 );

		// copy
		local key = m_KeyFrames[ m_nCurKeyframe ];
		SetViewOrigin( key.origin );
		SetViewForward( key.forward );
	};

	if ( !bClick )
	{
		if ( m_nSelectedKeyframe == -1 )
		{
			m_bReplaceOnClick = true;
			m_nSelectedKeyframe = m_nCurKeyframe;

			MsgHint(Fmt( "Left click to replace keyframe #%d...\n", m_nCurKeyframe ));
			return PlaySound( SND_BUTTON );
		};

		// Cancel if mouse was not clicked
		if ( m_bReplaceOnClick )
			return OnMouse2Pressed();
	};

	m_bReplaceOnClick = false;
	m_nSelectedKeyframe = -1;

	local key = m_KeyFrames[ m_nCurKeyframe ];
	local keyCopy = clone key;

	m_pLerpFrustum = [ keyCopy, key ];
	m_hLerpKeyframe = keyframe_t();
	m_flLerpKeyAnim = 0.0;

	VS.EventQueue.CancelEventsByInput( StopReplaceLerp );
	// animate it 5 times
	VS.EventQueue.AddEvent( StopReplaceLerp, 5 * 100 * FrameTime(), this );

	local pos = MainViewOrigin();
	local ang = MainViewAngles();
	local dir = MainViewForward();

	key.SetAngles( ang );
	key.SetOrigin( pos );
	key.SetFov( null );

	local pUndo = CUndoReplaceKeyframe();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = m_nCurKeyframe;
	pUndo.m_pOldFrame = keyCopy;
	pUndo.m_pNewFrame = clone key;

	m_bDirty = true;

	if ( !m_bInEditMode )
	{
		DrawLine( pos, pos + dir * 64, 127, 255, 0, true, 7.0 );
		DrawBoxAngles( pos, Vector(-4,-4,-4), Vector(4,4,4), ang, 127, 255, 0, 127, 7.0 );
	};

	MsgHint(Fmt( "Replaced keyframe #%d\n", m_nCurKeyframe ));
	return PlaySound( SND_BUTTON );
}


class CUndoInsertKeyframe extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames.remove( m_nKeyIndex );

		// Reset selection
		if ( Base.m_nCurKeyframe == m_nKeyIndex || Base.m_nSelectedKeyframe == -1 )
		{
			if ( Base.m_bSeeing )
				Base.SeeKeyframe( 1, 0 );

			Base.m_nCurKeyframe = -1;
			Base.m_nSelectedKeyframe = -1;
		}
	}

	function Redo()
	{
		Base.m_KeyFrames.insert( m_nKeyIndex, m_pNewFrame );
	}

	function Desc()
	{
		return "insert #" + m_nKeyIndex;
	}

	m_nKeyIndex = null;
	m_pNewFrame = null;
}

// kf_insert
function InsertKeyframe( bClick = 0 )
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("Cannot insert keyframe while edit mode is disabled.\n");

	// Unsee and activate click to insert at current position
	if ( m_bSeeing )
	{
		SeeKeyframe( 1, 0 );

		// copy
		local key = m_KeyFrames[ m_nCurKeyframe ];
		SetViewOrigin( key.origin );
		SetViewForward( key.forward );
	};

	if ( !bClick )
	{
		if ( m_nSelectedKeyframe == -1 )
		{
			m_bInsertOnClick = true;
			m_nSelectedKeyframe = m_nCurKeyframe;

			MsgHint(Fmt( "Left click to insert keyframe at #%d...\n", m_nCurKeyframe ));
			PlaySound( SND_BUTTON );
			return;
		};

		// Cancel if mouse was not clicked
		if ( m_bInsertOnClick )
		{
			OnMouse2Pressed();
			return;
		};
	};

	m_bInsertOnClick = false;
	m_nSelectedKeyframe = -1;

	local pos = MainViewOrigin();
	local ang = MainViewAngles();
	local dir = MainViewForward();

	local key = keyframe_t();
	key.SetOrigin( pos );
	key.SetAngles( ang );
	m_KeyFrames.insert( m_nCurKeyframe, key );

	local pUndo = CUndoInsertKeyframe();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = m_nCurKeyframe;
	pUndo.m_pNewFrame = clone key;

	m_bDirty = true;

	if ( !m_bInEditMode )
	{
		DrawLine( pos, pos + dir * 64, 127, 255, 0, true, 7.0 );
		DrawBoxAngles( pos, Vector(-4,-4,-4), Vector(4,4,4), ang, 127, 255, 0, 127, 7.0 );
	};

	MsgHint(Fmt( "Inserted keyframe #%d\n", m_nCurKeyframe ));
	return PlaySound( SND_BUTTON );
}


class CUndoRemoveKeyframe extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames.insert( m_nKeyIndex, m_pOldFrame );
	}

	function Redo()
	{
		Base.m_KeyFrames.remove( m_nKeyIndex );

		// Reset selection
		if ( Base.m_nCurKeyframe == m_nKeyIndex || Base.m_nSelectedKeyframe == -1 )
		{
			if ( Base.m_bSeeing )
				Base.SeeKeyframe( 1, 0 );

			Base.m_nCurKeyframe = -1;
			Base.m_nSelectedKeyframe = -1;
		}

		Base.CheckAnyKeysLeft();
	}

	function Desc()
	{
		return "remove #" + m_nKeyIndex;
	}

	m_nKeyIndex = null;
	m_pOldFrame = null;
}

// kf_remove
function RemoveKeyframe()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("Cannot remove keyframe while edit mode is disabled.\n");

	if ( m_nCurKeyframe == -1 )
		return;

	// unsee
	if ( m_bSeeing )
		SeeKeyframe(1);

	local key = m_KeyFrames.remove( m_nCurKeyframe );

	local pUndo = CUndoRemoveKeyframe();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = m_nCurKeyframe;
	pUndo.m_pOldFrame = clone key;

	if ( !m_KeyFrames.len() )
	{
		MsgHint("Removed all keyframes.\n");

		CheckAnyKeysLeft();
	}
	else
	{
		MsgHint(Fmt( "Removed keyframe #%d\n", m_nCurKeyframe ));

		// Removed the last key, move current selection to one before
		if ( !(m_nCurKeyframe in m_KeyFrames) )
		{
			--m_nCurKeyframe;
			m_nSelectedKeyframe = -1;
		};
	};

	m_bDirty = true;

	return PlaySound( SND_BUTTON );
}


class CUndoRemoveFOV extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].SetFov( m_nFov );

		if ( Base.m_nCurKeyframe == m_nKeyIndex && Base.m_bSeeing )
		{
			Base.UpdateCamera();
		}
	}

	function Redo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].SetFov( null );

		if ( Base.m_nCurKeyframe == m_nKeyIndex && Base.m_bSeeing )
		{
			Base.UpdateCamera();
		}
	}

	function Desc()
	{
		return "remove fov #" + m_nKeyIndex;
	}

	m_nKeyIndex = null;
	m_nFov = null;
}

// kf_removefov
function RemoveFOV()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_bInEditMode )
		return MsgFail("Cannot remove FOV data while edit mode is disabled.\n");

	local key = m_KeyFrames[ m_nCurKeyframe ];
	if ( !key.fov )
		return MsgFail(Fmt( "No FOV data on keyframe #%d found.\n", m_nCurKeyframe ));

	local pUndo = CUndoRemoveFOV();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = m_nCurKeyframe;
	pUndo.m_nFov = key.fov;

	key.SetFov( null );

	CompileFOV();

	// refresh
	if ( m_bSeeing )
	{
		local fov = GetInterpolatedKeyframeFOV( m_nCurKeyframe );
		CameraSetFov( fov, 0.1 );
	}

	MsgHint(Fmt( "Removed FOV data at keyframe #%d\n", m_nCurKeyframe ));
	return PlaySound( SND_BUTTON );
}


class CUndoAddKeyframe extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames.pop();

		// Reset selection
		if ( (Base.m_nCurKeyframe == Base.m_KeyFrames.len()) || (Base.m_nSelectedKeyframe == -1) )
		{
			if ( Base.m_bSeeing )
				Base.SeeKeyframe( 1, 0 );

			Base.m_nCurKeyframe = -1;
			Base.m_nSelectedKeyframe = -1;
		}

		Base.CheckAnyKeysLeft();
	}

	function Redo()
	{
		Base.m_KeyFrames.append( m_pNewFrame );
	}

	m_pNewFrame = null;
}

// kf_add
function AddKeyframe()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( m_bSeeing )
		return MsgFail("Cannot add new keyframe while seeing!\n");

	local pos = MainViewOrigin();
	local ang = MainViewAngles();
	local dir = MainViewForward();

	local key = keyframe_t();
	key.SetOrigin( pos );
	key.SetAngles( ang );
	m_KeyFrames.append( key );

	local pUndo = CUndoAddKeyframe( "add #" + (m_KeyFrames.len()-1) );
	PushUndo( pUndo );
	pUndo.m_pNewFrame = clone key;

	m_bDirty = true;

	if ( !m_bInEditMode )
	{
		DrawLine( pos, pos + dir * 64, 127, 255, 0, true, 7.0 );
		DrawBoxAngles( pos, Vector(-4,-4,-4), Vector(4,4,4), ang, 127, 255, 0, 127, 7.0 );
	};

	MsgHint(Fmt( "Added keyframe #%d\n", (m_KeyFrames.len()-1) ));
	return PlaySound( SND_BUTTON );
}


class CUndoRemoveAllKeyframes extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames.resize( m_pFrames.len() );

		foreach( i, v in m_pFrames )
		{
			Base.m_KeyFrames[i] = clone v;
		}
	}

	function Redo()
	{
		Base.m_KeyFrames.clear();
		Base.CheckAnyKeysLeft();
	}

	function Desc()
	{
		return "clear";
	}

	function Clone()
	{
		m_pFrames = clone Base.m_KeyFrames;

		foreach ( i, v in Base.m_KeyFrames )
		{
			m_pFrames[i] = clone v;
		}
	}

	m_pFrames = null;
}

// kf_clear
function RemoveAllKeyframes()
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	// unsee
	if ( m_bSeeing )
		SeeKeyframe(1);

	local pUndo = CUndoRemoveAllKeyframes();
	PushUndo( pUndo );
	pUndo.Clone();

	MsgHint(Fmt( "Removed %d keyframes.\n", m_KeyFrames.len() ));

	m_KeyFrames.clear();

	CheckAnyKeysLeft();

	m_bDirty = true;

	return PlaySound( SND_BUTTON );
}

// Reset things
function CheckAnyKeysLeft()
{
	if ( !(0 in m_KeyFrames) )
	{
		m_nCurKeyframe = -1;
		m_nSelectedKeyframe = -1;
	};
}



// origin interpolator
local g_InterpolatorMap = array( KF_INTERP_COUNT );
g_InterpolatorMap[ KF_INTERP_CATMULL_ROM ]			= CONST.INTERPOLATE.CATMULL_ROM;
g_InterpolatorMap[ KF_INTERP_CATMULL_ROM_NORM ]		= CONST.INTERPOLATE.CATMULL_ROM_NORMALIZE;
g_InterpolatorMap[ KF_INTERP_LINEAR ]				= CONST.INTERPOLATE.LINEAR_INTERP;
g_InterpolatorMap[ KF_INTERP_BSPLINE ]				= CONST.INTERPOLATE.BSPLINE;
g_InterpolatorMap[ KF_INTERP_SIMPLE_CUBIC ]			= CONST.INTERPOLATE.SIMPLE_CUBIC;



// kf_mode_angles
function SetAngleInterp( i = null )
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

		default:
			return SetAngleInterp( m_nInterpolatorAngle + 1 );
	}

	return PlaySound( SND_BUTTON );
}

// kf_mode_origin
function SetOriginInterp( i = null )
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

		default:
			return SetOriginInterp( m_nInterpolatorOrigin + 1 );
	}

	return PlaySound( SND_BUTTON );
}


class CUndoSetFrameTime extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].frametime = m_flFrameTimeOld;
		Base.m_KeyFrames[ m_nKeyIndex ].samplecount = ( m_flFrameTimeOld / Base.g_FrameTime ).tointeger();
	}

	function Redo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].frametime = m_flFrameTimeNew;
		Base.m_KeyFrames[ m_nKeyIndex ].samplecount = ( m_flFrameTimeNew / Base.g_FrameTime ).tointeger();
	}

	function Desc()
	{
		return Fmt( "frametime #%i : [%f] -> [%f]", m_nKeyIndex, m_flFrameTimeOld, m_flFrameTimeNew );
	}

	m_nKeyIndex = null;
	m_flFrameTimeNew = null;
	m_flFrameTimeOld = null;
}

//
// Sets how many samples to take until the next keyframe.
//
// kf_samplecount
//
function SetSampleCount( nSampleCount = KF_NOPARAM, nKey = -1 )
{
	if ( nSampleCount == KF_NOPARAM )
		throw "wrong number of parameters";

	if ( m_bCompiling || m_bPreview )
		return MsgFail("Cannot change sampling rate while compiling!\n");

	if ( nKey == -1 )
		nKey = m_nCurKeyframe;

	if ( nKey == -1 )
		return MsgFail("No keyframe is selected\n");

	nSampleCount = nSampleCount.tointeger();

	if ( nSampleCount < 0 )
		return MsgFail("Invalid input "+nSampleCount+"\n");

	if ( nSampleCount == 0 )
		nSampleCount = KF_SAMPLE_COUNT_DEFAULT;

	local flTime = g_FrameTime * nSampleCount;

	local key = m_KeyFrames[ nKey ];

	local pUndo = CUndoSetFrameTime();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = nKey;
	pUndo.m_flFrameTimeNew = flTime;
	pUndo.m_flFrameTimeOld = key.frametime;

	if ( key.samplecount != nSampleCount )
	{
		key.frametime = flTime;
		key.samplecount = nSampleCount;
		m_bDirty = true;
	};

	Msg(Fmt( "Interpolation sample count on keyframe #%d is set to: %d (%fs)\n", nKey, nSampleCount, flTime ));
	return PlaySound( SND_BUTTON );
}

//
// Sets the time it takes to travel until the next keyframe.
//
// kf_frametime
//
function SetFrameTime( flTime = KF_NOPARAM, nKey = -1 )
{
	if ( flTime == KF_NOPARAM )
		throw "wrong number of parameters";

	if ( m_bCompiling || m_bPreview )
		return MsgFail("Cannot change sampling rate while compiling!\n");

	if ( nKey == -1 )
		nKey = m_nCurKeyframe;

	if ( nKey == -1 )
		return MsgFail("No keyframe is selected\n");

	flTime = flTime.tofloat();

	if ( flTime < 0.0 )
		return MsgFail("Invalid input "+flTime+"\n");

	if ( flTime == 0.0 )
		flTime = g_FrameTime * KF_SAMPLE_COUNT_DEFAULT;

	local nSampleCount = ( flTime / g_FrameTime ).tointeger();

	// How long it will take on this server. Precision depends on the server tickrate and g_FrameTime.
	flTime = g_FrameTime * nSampleCount;

	local key = m_KeyFrames[ nKey ];

	local pUndo = CUndoSetFrameTime();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = nKey;
	pUndo.m_flFrameTimeNew = flTime;
	pUndo.m_flFrameTimeOld = key.frametime;

	if ( key.samplecount != nSampleCount )
	{
		key.frametime = flTime;
		key.samplecount = nSampleCount;
		m_bDirty = true;
	};

	Msg(Fmt( "Interpolation sample count on keyframe #%d is set to: %d (%fs)\n", nKey, nSampleCount, flTime ));
	return PlaySound( SND_BUTTON );
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
	return PlaySound( SND_BUTTON );
}

//--------------------------------------------------------------

//
// Gets the frame count in the specified key range
//
function GetSampleCount( first, last )
{
	if ( !(first in m_KeyFrames && last in m_KeyFrames) )
		throw "out of range";

	local c = 0;
	for ( ; first < last; ++first )
		c += (m_KeyFrames[first].frametime / g_FrameTime).tointeger();
	return c;
}

// kf_compile
function Compile()
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

	Msg("\n");
	Msg("Preparing...\n");
	PlaySound( SND_BUTTON );

	CreateThread( StartCompile, this );
	return StartThread();
}


// Supports only 1 active thread at once
// Usage:
//	CreateThread( ThreadFunc, this );
//	StartThread( <optional parameters> );
//
// Can be called inside the thread:
//	ThreadSleep( <duration> );
//
{
	_thread <- null;
	_env <- null;

	function CreateThread( func, env = null )
	{
		_thread = func;
		_env = env;
	}

	function StartThread( ... )
	{
		switch ( vargv.len() )
		{
			case 0: return _thread.call( _env );
			case 1: return _thread.call( _env, vargv[0] );
			case 2: return _thread.call( _env, vargv[0], vargv[1] );
			case 3: return _thread.call( _env, vargv[0], vargv[1], vargv[2] );
			case 4: return _thread.call( _env, vargv[0], vargv[1], vargv[2], vargv[3] );
		}
	}

	function ThreadSleep( duration )
	{
		//if ( duration > 0.0 )
		//{
		//	suspend( VS.EventQueue.AddEvent( ThreadResume, duration, this ) );
		//}
		//else if ( duration == -1 )
		//{
		//	suspend();
		//}
	}

	function ThreadResume()
	{
		//if ( _thread.getstatus() == "suspended" )
		//{
		//	_thread.wakeup();
		//}
	}

	function ThreadIsSuspended()
	{
		//return _thread.getstatus() == "suspended";
	}
}


function FillBoundariesRevert()
{
	// end
	m_KeyFrames.remove( m_KeyFrames.len() - 1 );

	// start
	m_KeyFrames.remove( 0 );
}

function FillBoundaries()
{
	local key, tmp0, tmp1;

	// end
	key = m_KeyFrames.top();
	tmp1 = keyframe_t();
	tmp1.Copy( key );
	m_KeyFrames.append( tmp1 );

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
function StartCompile()
{
	if ( m_bAutoFillBoundaries )
		FillBoundaries();

	// Calculate total frame count
	local size = GetSampleCount( 1, m_KeyFrames.len() - 2 );

	// init path
	m_PathData = array( size );
	for ( local i = size; i--; )
	{
		m_PathData[i] = frame_t();
	}

	Msg(Fmt( "Keyframe count  : %d\n", m_KeyFrames.len() ));
	Msg(Fmt( "Frame count     : %d\n", size ));
	Msg(Fmt( "Angle interp    : %s\n", m_szInterpDescAngle ));
	Msg(Fmt( "Origin interp   : %s\n", m_szInterpDescOrigin ));

	if ( m_bAutoFillBoundaries )
		Msg(Fmt( "Fill boundaries : %d\n", m_bAutoFillBoundaries.tointeger() ));

	Msg("\nCompiling");

	return CompilePath();
}

function SplineOrigin( i, frac, out )
{
	return VS.Interpolator_CurveInterpolate( g_InterpolatorMap[ m_nInterpolatorOrigin ],
		m_KeyFrames[i-1].origin,
		m_KeyFrames[i].origin,
		m_KeyFrames[i+1].origin,
		m_KeyFrames[i+2].origin,
		frac,
		out );
}

function SplineAngles( i, frac, out )
{
	switch ( m_nInterpolatorAngle )
	{
		case KF_INTERP_D3DX:
		{
			local spline = Quaternion();

			local q0 = m_KeyFrames[i-1].GetQuaternion();
			local q1 = m_KeyFrames[i].GetQuaternion();
			local q2 = m_KeyFrames[i+1].GetQuaternion();
			local q3 = m_KeyFrames[i+2].GetQuaternion();

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
				return VS.QuaternionAngles( spline, out );
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
					m_pSquadErrors.append( i );
				};;

				return VS.VectorCopy( m_KeyFrames[i+1].angles, out );
			};

			return;
		}
		case KF_INTERP_LINEAR_BLEND:
		case KF_INTERP_LINEAR:
		{
			local spline = Quaternion();
			VS.QuaternionSlerp(
				m_KeyFrames[i].GetQuaternion(),
				m_KeyFrames[i+1].GetQuaternion(),
				frac,
				spline );
			return VS.QuaternionAngles( spline, out );
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
			return VS.VectorAngles( out, out );
		}
		// case KF_INTERP_AFX:
	}
}

function CompilePath()
{
	local len = m_KeyFrames.len()-3;
	local offset = 0;

	for ( local nKeyIdx = 1; nKeyIdx <= len; ++nKeyIdx )
	{
		local key = m_KeyFrames[nKeyIdx];

		local nSampleFrame = 0;

		local flCurTime = 0.0;
		local flKeyFrameTime = key.frametime;

		for ( ; flCurTime < flKeyFrameTime; flCurTime += g_FrameTime, ++nSampleFrame )
		{
			local t = flCurTime / flKeyFrameTime;

			local org = Vector();
			local ang = Vector();
			SplineOrigin( nKeyIdx, t, org );
			SplineAngles( nKeyIdx, t, ang );

			local frame = m_PathData[ offset + nSampleFrame ];
			frame.origin = org;
			frame.angles = ang;
		}

		if ( nSampleFrame != (flKeyFrameTime / g_FrameTime).tointeger() )
		{
			Msg(Fmt( "\nERROR: Compiled frame count does not match keyframe sample count value! %d, %d\n",
				nSampleFrame,
				(key.frametime / g_FrameTime).tointeger() ));
		}

		offset += nSampleFrame;

		// Sleeping on every other section of sampling is a good trade off between
		// decreased compilation time and game strain.
		// 3+ completely halts the game, which is undesirable however short the duration.
		if ( !(nKeyIdx % 2) )
		{
			Msg(".");
			ThreadSleep( g_FrameTime );
		};
	}

	if ( m_nInterpolatorAngle == KF_INTERP_LINEAR_BLEND )
	{
		Msg("|");
		// smooth twice?
		DoSmoothAngles( 10 );
		ThreadSleep( g_FrameTime );
		DoSmoothAngles( 10 );
	};

	CompileFOV();

	ThreadSleep( g_FrameTime );

	return FinishCompile();
}

function FinishCompile()
{
	if ( m_bAutoFillBoundaries )
		FillBoundariesRevert();

	// Assert compilation
	local c = m_PathData.len();
	for ( local i = 0; i < c; i++ )
	{
		if ( !m_PathData[i] || !m_PathData[i].origin )
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
			Msg(Fmt( "  %d", i+1 ));
		Msg("\n");

		m_pSquadErrors = null;
	};

	if ( m_PathSelection[1] >= m_PathData.len() )
	{
		m_PathSelection[0] = m_PathSelection[1] = 0;
	};

	m_bCompiling = false;
	SetEditModeTemp( m_bInEditMode );

	Msg("\nCompilation complete.\n");
	Msg(Fmt( "Animation length: %g seconds\n\n", m_PathData.len() * g_FrameTime ));
	return PlaySound( SND_BUTTON );
}

function CompileFOV()
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
	if ( !m_KeyFrames[1].fov )
	{
		m_KeyFrames[1].SetFov( 90 );

		m_nPathInitialFOV = 0;
	}
	else
	{
		// HACKHACK: save the initial FOV separately, export it on its own field
		m_nPathInitialFOV = m_KeyFrames[1].fov.tointeger();
	};

	local i = 0, c = m_KeyFrames.len()-1;

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

			// time to move between previous and current fov keys
			local rate = GetSampleCount( i, j ) * g_FrameTime;

			// frame to start fov lerping
			local frame = GetSampleCount( 1, i );

			// not ready to compile
			if ( !(frame in m_PathData) )
				break;

			local pt = m_PathData[ frame ];
			pt.fov = f1.fov;
			pt.fov_rate = rate;

			break;
		}
	}
}

function DoSmoothAngles( r )
{
	// These differences save seconds in especially large data sets.
	local nSleepRate;

	if ( m_bSmoothExponential )
	{
		nSleepRate = 5200 / r;
	}
	else
	{
		// Quaternion alignment in QuaternionBlend slows this down significantly.
		nSleepRate = 4200 / r;
	};

	local i, c;

	if ( m_PathSelection[0] && m_PathSelection[1] )
	{
		i = m_PathSelection[0];
		c = m_PathSelection[1];
	}
	else
	{
		i = 0;
		c = m_PathData.len();
	};

	local stack = [];
	for ( ; i < c; i++ )
	{
		if ( !(i % nSleepRate) )
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
function SmoothAnglesStack( stack )
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

function DoSmoothOrigin( r )
{
	local nSleepRate = 4200 / r;

	local i, c;

	if ( m_PathSelection[0] && m_PathSelection[1] )
	{
		i = m_PathSelection[0] + r;
		c = m_PathSelection[1] - r;
	}
	else
	{
		i = r;
		c = m_PathData.len() - r;
	};

	local stack = [];
	for ( ; i < c; i++ )
	{
		if ( !(i % nSleepRate) )
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
function SmoothOriginStack( stack )
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


function GetInterpolatedKeyframeFOV( nCur )
{
	{
		local curkey = m_KeyFrames[ nCur ];
		if ( curkey.fov )
			return curkey.fov;
	}

	local nPrevFov, nPrevIdx, nNextFov, nNextIdx;

	for ( local i = nCur; i >= 0; --i )
	{
		local prev = m_KeyFrames[i];
		if ( prev.fov )
		{
			nPrevIdx = i;
			nPrevFov = prev.fov;
			break;
		}
	}

	for ( local i = nCur, c = m_KeyFrames.len(); i < c; ++i )
	{
		local next = m_KeyFrames[i];
		if ( next.fov )
		{
			nNextIdx = i;
			nNextFov = next.fov;
			break;
		}
	}

	if ( nPrevFov )
	{
		if ( nNextFov )
		{
			local flTotalMoveTime = GetSampleCount( nPrevIdx, nNextIdx ) * g_FrameTime;
			local flCurMoveTime = GetSampleCount( nPrevIdx, nCur ) * g_FrameTime;
			local flFov = VS.SimpleSplineRemapValClamped( flCurMoveTime, 0.0, flTotalMoveTime, nPrevFov, nNextFov );

			return flFov;
		}

		return nPrevFov;
	}

	return 90.0;
}


function StopTransformLerp()
{
	m_pLerpTransform = null;
	m_flLerpTransformAnim = null;
}


class CUndoTransformKeyframes extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames.resize( m_pFramesOld.len() );

		foreach( i, v in m_pFramesOld )
		{
			Base.m_KeyFrames[i] = clone v;
		}
	}

	function Redo()
	{
		Base.m_KeyFrames.resize( m_pFramesNew.len() );

		foreach( i, v in m_pFramesNew )
		{
			Base.m_KeyFrames[i] = clone v;
		}
	}

	function Desc()
	{
		return "transform";
	}

	function ClonePre()
	{
		m_pFramesOld = clone Base.m_KeyFrames;

		foreach ( i, v in Base.m_KeyFrames )
		{
			m_pFramesOld[i] = clone v;
		}
	}

	function ClonePost()
	{
		m_pFramesNew = clone Base.m_KeyFrames;

		foreach ( i, v in Base.m_KeyFrames )
		{
			m_pFramesNew[i] = clone v;
		}
	}

	m_pFramesOld = null;
	m_pFramesNew = null;
}

//
// void TransformKeyframes( Vector offset )
// void TransformKeyframes( Vector|null offset, Vector angles )
// void TransformKeyframes( int pivot, Vector offset, Vector angles )
//
function TransformKeyframes( p1 = null, p2 = null, p3 = null )
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	local vecPivot, vecOffset, vecAngle;
	local t1 = typeof p1, t2 = typeof p2, t3 = typeof p3;

	//
	// void TransformKeyframes( Vector offset )
	//
	if ( t1 == "Vector" && t2 == "null" && t3 == "null" )
	{
		vecPivot = vec3_origin;
		vecOffset = p1;
		vecAngle = vec3_origin;
	};

	//
	// void TransformKeyframes( null, Vector angles )
	//
	if ( t1 == "null" && t2 == "Vector" && t3 == "null" )
	{
		t1 = "Vector";
		p1 = vec3_origin;
	};

	//
	// void TransformKeyframes( Vector offset, Vector angles )
	//
	if ( t1 == "Vector" && t2 == "Vector" && t3 == "null" )
	{
		// p2 -> p3
		t3 = t2;
		p3 = p2;

		// p1 -> p2
		t2 = t1;
		p2 = p1;

		// pivot average
		t1 = "integer";
		p1 = -1;
	};

	//
	// void TransformKeyframes( int pivot, null, Vector angles )
	//
	if ( t1 == "integer" && t2 == "null" && t3 == "Vector" )
	{
		t2 = "Vector";
		p2 = vec3_origin;
	};

	//
	// void TransformKeyframes( int pivot, Vector offset, Vector angles )
	//
	if ( t1 == "integer" && t2 == "Vector" && t3 == "Vector" )
	{
		vecOffset = p2;
		vecAngle = p3;

		local pivot = p1;

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
	};

	if (	typeof vecPivot != "Vector"		||
			typeof vecOffset != "Vector"	||
			typeof vecAngle != "Vector"		)
	{
		return MsgFail("Invalid parameters\n");
	};

	local pUndo = CUndoTransformKeyframes();
	PushUndo( pUndo );
	pUndo.ClonePre();

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

		key.UpdateFromMatrix();
	}

	pUndo.ClonePost();

	m_bDirty = true;

	VS.EventQueue.CancelEventsByInput( StopTransformLerp );
	// animate it 5 times
	local t = 5 * 100 * FrameTime();
	VS.EventQueue.AddEvent( StopTransformLerp, t, this );

	DrawBox( vecPivot, Vector(-4,-4,-4), Vector(4,4,4), 255, 255, 255,255, t );
	PlaySound( SND_BUTTON );
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
function SmoothOrigin( r = 4 )
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
	PlaySound( SND_BUTTON );

	local msg;
	if ( m_PathSelection[0] && m_PathSelection[1] )
	{
		msg = Fmt( "\nSmooth origin done. [%d -> %d]\n", m_PathSelection[0], m_PathSelection[1] );
	}
	else
	{
		msg = "\nSmooth origin done.\n";
	};

	CreateThread( ThreadHelper, this );
	StartThread( DoSmoothOrigin, r, msg );
}

// kf_smooth_angles
// kf_smooth_angles_exp
function SmoothAngles( exp = 0, r = 10 )
{
	if ( m_bCompiling )
		return MsgFail("Cannot smooth path while compiling!\n");

	if ( m_bInPlayback || m_bPlaybackPending )
		return MsgFail("Cannot smooth angles while in playback!\n");

	if ( !m_PathData.len() )
		return MsgFail("No path found.\n");

	r = r.tointeger();

	Msg(Fmt( "Smoothing angles... (%d) %s\n", r, m_bDirty ? " (dirty)" : "" ));
	PlaySound( SND_BUTTON );

	local msg;
	if ( m_PathSelection[0] && m_PathSelection[1] )
	{
		msg = Fmt( "\nSmooth angles done. [%d -> %d]", m_PathSelection[0], m_PathSelection[1] );
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

	CreateThread( ThreadHelper, this );
	StartThread( DoSmoothAngles, r, msg, !!exp );
}


//--------------------------------------------------------------
//--------------------------------------------------------------

//--------------------------------------------------------------
// Save/load

{
	function IsValidCoord( f )
	{
		return ( f <= MAX_COORD_FLOAT ) && ( f >= -MAX_COORD_FLOAT );
	}

	function WriteCoord( v )
	{
		if ( VS.CloseEnough( v, 0.0, 1.e-5 ) )
			v = 0.0;

		return Fmt( "%f", v );
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
		return Fmt( "\t\t%d,%s,%s,%s,%s,%s,%s,\n", n,
			tx, ty, tz,
			rx, ry, rz );
	}
	else
	{
		return Fmt( "\t\t%d,%s,%s,%s,%s,%s,%s,%d,%s,\n", (n | 0x01),
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

// Complete rework
// PATCH: field init_fov
// PATCH: field lights
const KF_SAVE_V2				= 2;;

// Current version
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
		MsgFail("No data type to save specified.\n");
		Msg("   Save compiled animation data with 'kf_savepath'\n");
		Msg("   Save keyframe data with 'kf_savekeys'\n\n");
		return;
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

	//VS.Log.file_prefix = "scripts/vscripts/kf_data";
	//VS.Log.export = true;
	//VS.Log.filter = "L ";

	Msg( "Saving, please wait...\n" );

	CreateThread( SaveProcess, this );
	StartThread();
}

function SaveProcess()
{
	ThreadSleep( g_FrameTime );

	//VS.Log.Clear();

	ThreadSleep( g_FrameTime );

	SaveWrite();

	VS.Log.Run( function( file )
	{
		m_bSaveInProgress = false;
		PlaySound( SND_EXPORT_SUCCESS );

		if ( m_nSaveType == KF_DATA_TYPE_PATH )
		{
			Msg(Fmt( "Exported animation data: /csgo/%s.log\n\n", file ));
		}
		else if ( m_nSaveType == KF_DATA_TYPE_KEYFRAMES )
		{
			Msg(Fmt( "Exported keyframe data: /csgo/%s.log\n\n", file ));
		}
	}, this );
}

function SaveWrite()
{
	local pszSaveData = "";

	local Add = function(s) { pszSaveData += s; } //VS.Log.Add;

	// header ---

	local header = array(6);
	header[2] = g_szMapName;
	header[3] = KF_SAVE_VERSION;
	header[4] = m_nSaveType;
	header[5] = m_pSaveData.len();

	local bNameFix = ( g_szMapName[0] >= '0' && g_szMapName[0] <= '9' ) ||
		( g_szMapName.find("-") != null ) || ( g_szMapName.find("+") != null );

	if ( m_nSaveType == KF_DATA_TYPE_PATH )
	{
		if ( bNameFix )
		{
			header[1] = "this[\"l_%s\"] <- { version = %i, type = %i, framecount = %i,\n\tframes =\n\t[\n";
		}
		else
		{
			header[1] = "l_%s <- { version = %i, type = %i, framecount = %i,\n\tframes =\n\t[\n";
		}
	}
	else if ( m_nSaveType == KF_DATA_TYPE_KEYFRAMES )
	{
		if ( bNameFix )
		{
			header[1] = "this[\"lk_%s\"] <- { version = %i, type = %i, framecount = %i,\n\tframes =\n\t[\n";
		}
		else
		{
			header[1] = "lk_%s <- { version = %i, type = %i, framecount = %i,\n\tframes =\n\t[\n";
		}
	};;

	Add( Fmt.acall(header) );

	// body ---

	local c = m_pSaveData.len();

	for ( local i = 0; i < c; i++ )
	{
		Add( WriteFrame( m_pSaveData[i] ) );

		if ( !(i % 256) )
		{
			ThreadSleep( g_FrameTime );
		};
	}

	ThreadSleep( g_FrameTime );

	// strip trailing separator ",\n"
	// Add( VS.Log.Pop().slice( 0, -2 ) + "\n\t]" );
	Add( pszSaveData.slice( 0, -2 ) + "\n\t]" );

	// NOTE: Only lights for now!
	if ( m_Elements.len() )
	{
		Add( ",\n\tlights =\n\t[\n" );
		foreach ( elem in m_Elements )
		{
			Add( elem.Serialise() );
		}

		ThreadSleep( g_FrameTime );

		// strip trailing separator ",\n"
		// Add( VS.Log.Pop().slice( 0, -2 ) + "\n\t]" );
		Add( pszSaveData.slice( 0, -2 ) + "\n\t]" );
	}

	// HACKHACK
	if ( m_nPathInitialFOV )
	{
		Add( ",\n\tinit_fov = " + m_nPathInitialFOV );
	}

	// tail ---
	Add( "\n}\n\0" );

	local filename = "kf_data_" + DoUniqueString("") + ".nut";

	if ( !StringToFile( filename, pszSaveData ) )
	{
		Msg("save error\n");
	}
	else
	{
		Msg("saved to " + filename + "\n");
	}

	m_bSaveInProgress = false;
}


//--------------------------------------------------------------
//--------------------------------------------------------------


if ( !GetDelegate( m_FileBuffer ) )
{
	local m_LoadedData = m_LoadedData;
	local meta =
	{
		_newslot = function( k, v )
		{
			if ( ( k in m_LoadedData ) && m_LoadedData[k] )
			{
				// TODO: compare?
				k = k + "_01";
				_KF_.Msg( "Conflicting data name, renaming to: " + k + "\n" );
			}

			m_LoadedData.rawset( k, v );

			_KF_.Msg(_KF_.Fmt( "~ Found: \"%s\"\n", k ));
		}
	}
	SetDelegate( meta, m_FileBuffer );
};

function LoadFile( msg = true )
{
	if ( m_bLoadInProgress )
		return Msg( "A load is already in progress...\n" );

	if (msg)
	{
		Msg("Loading file...\n")
	};

	try
	{
		DoIncludeScript( "keyframes_data", m_FileBuffer );
	}
	catch(e)
	{
		return Error("Failed to load keyframes_data.nut file!\n");
	}

	if (msg)
	{
		Msg("...done.\n");
		PlaySound( SND_FILE_LOAD_SUCCESS );
	}

	if ( m_LoadedData.len() )
	{
		CreateThread( LoadFileData, this );
		StartThread();
	}
}

function LoadFileData()
{
	m_bLoadInProgress = true;
	SetEditModeTemp( false );

	foreach ( szInput, pInput in m_LoadedData )
	{
		ThreadSleep( 0.1 );
		LoadData( szInput, pInput );
	}

	m_LoadedData.clear();

	if ( m_PathData && m_PathData.len() )
	{
		Msg( "Overwriting existing path\n" );
	}

	m_PathData = "";
	m_bLoadInProgress = false;
	return SetEditModeTemp( m_bInEditMode );
}

function LoadFileError()
{
	Msg("Use 'kf_loadfile' to reload the keyframes_data.nut file.\n");
	PlaySound( SND_FAILURE );
}


class CUndoLoad extends CUndoTransformKeyframes
{
	function Undo()
	{
		Base.CUndoTransformKeyframes.Undo();
		Base.CheckAnyKeysLeft();
	}

	function Desc()
	{
		return "load keyframes";
	}
}

function LoadData( szInput, pInput )
{
	if ( m_bCompiling )
		return MsgFail("Cannot load file while compiling!\n");

	Msg(Fmt( "\nPreparing to load: \"%s\"\n", szInput ));

	local datasize, framecount;

	if ( "version" in pInput )
	{
		m_nLoadVer = pInput.version;
		m_nLoadType = pInput.type;
		datasize = pInput.frames.len();
		framecount = pInput.framecount;
	}
	else
	{
		m_nLoadVer = KF_SAVE_V1;
	};

	if ( m_nLoadVer == KF_SAVE_V1 )
	{
		if ( !("pos" in pInput) || !("ang" in pInput) )
			return MsgFail("Invalid input.\n");

		if ( !pInput.pos.len() || !pInput.ang.len() )
			return MsgFail("Empty input.\n");

		if ( "anq" in pInput )
			pInput.quat <- delete pInput.anq;

		if ( "quat" in pInput )
		{
			if ( pInput.pos.len() != pInput.quat.len() )
				return Error("[ERROR] Corrupted data!\n");

			m_nLoadType = KF_DATA_TYPE_KEYFRAMES;
		}
		else
		{
			if ( pInput.pos.len() != pInput.ang.len() )
				return Error("[ERROR] Corrupted data!\n");

			m_nLoadType = KF_DATA_TYPE_PATH;
		};

		datasize = pInput.pos.len();
		framecount = datasize;
	};

	// data from the future?
	if ( m_nLoadVer > KF_SAVE_VERSION || m_nLoadVer < KF_SAVE_V1 )
		return MsgFail(Fmt( "Unrecognised data version! [%i]\n", m_nLoadVer ));

	if ( m_nLoadType != KF_DATA_TYPE_KEYFRAMES && m_nLoadType != KF_DATA_TYPE_PATH )
		return MsgFail(Fmt( "Invalid data type! [%i]\n", m_nLoadType ));

	if ( m_nLoadType == KF_DATA_TYPE_KEYFRAMES )
	{
		local pUndo = m_pUndoLoad = CUndoLoad();
		pUndo.ClonePre();

		// HACKHACK: Only allow 1 set of editable keyframes while allowing any number of paths
		m_pLoadData = m_KeyFrames.weakref();
		m_pLoadData.clear();
		m_pLoadData.resize( framecount );
	}
	else if ( m_nLoadType == KF_DATA_TYPE_PATH )
	{
		m_pLoadData = array( framecount );
	}

	m_szLoadInputName = szInput;
	m_pLoadInput = pInput.weakref();

	// HACKHACK
	if ( ("init_fov" in pInput) && (typeof pInput.init_fov == "integer") )
	{
		m_nPathInitialFOV = pInput.init_fov.tointeger();
	}

	local lightcount = 0;

	if ( "lights" in pInput )
	{
		lightcount = CLight.GetTotalCountFromSerialisedBuffer( pInput.lights );
	}

	if ( m_nLoadVer != KF_SAVE_VERSION )
		Msg(Fmt( "\tversion     : %i\n", m_nLoadVer ));

	Msg(Fmt( "\ttype        : %i\n", m_nLoadType ));
	Msg(Fmt( "\tframe count : %i\n", framecount ));

	if ( lightcount )
		Msg(Fmt( "\tlight count : %i\n", lightcount ));

	Msg("[.");

	switch ( m_nLoadVer )
	{
		case KF_SAVE_V2:
			return LoadInternalV2();
		case KF_SAVE_V1:
			return LoadInternalV1();
		default:
			Assert(0);
	}
}

local NewFrame = function()
{
	switch ( m_nLoadType )
	{
		case KF_DATA_TYPE_KEYFRAMES:
			return keyframe_t();

		case KF_DATA_TYPE_PATH:
			return frame_t();
	}
}

function LoadInternalV2()
{
	local data = m_pLoadInput.frames;
	local c = data.len();
	local frame = 0;

	for ( local i = 0; i < c; )
	{
		local p = NewFrame();
		m_pLoadData[ frame++ ] = p;
		i = ReadFrame( p, data, i );

		if ( !(i % 10000) )
		{
			Msg(".");
			ThreadSleep( g_FrameTime );
		}
	}

	ThreadSleep( g_FrameTime );

	if ( "lights" in m_pLoadInput )
	{
		ClearLights();

		local data = m_pLoadInput.lights;
		local c = data.len();

		for ( local i = 0; i < c; )
		{
			local p = CLight();
			m_Elements.append( p );
			i = p.Unserialise( data, i );

			if ( !(i % 10000) )
			{
				Msg(".");
				ThreadSleep( g_FrameTime );
			}
		}
	}

	return LoadFinishInternal();
}

function LoadInternalV1()
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
	}

	local c = m_pLoadInput.pos.len();

	for ( local i = 0; i < c; ++i )
	{
		local org = m_pLoadInput.pos[i];
		local rot = m_pLoadInput[rotGet][i];

		local p = NewFrame();
		m_pLoadData[i] = p;

		p.SetOrigin( org );
		p[rotSet]( rot );

		if ( !(i % 10000) )
		{
			Msg(".");
			ThreadSleep( g_FrameTime );
		}
	}

	ThreadSleep( g_FrameTime );

	if ( "fov" in m_pLoadInput )
	{
		foreach( i, a in m_pLoadInput.fov )
		{
			local idx = a[0];
			if ( !( idx in m_pLoadData ) )
			{
				Msg("Corrupted FOV data: invalid index!\n");
				continue;
			}
			m_pLoadData[idx].SetFov( a[1], a[2] );
		}
	}

	ThreadSleep( g_FrameTime );

	return LoadFinishInternal();
}

function LoadFinishInternal()
{
	// Assert
	local c = m_pLoadData.len();
	for ( local i = 0; i < c; i++ )
	{
		if ( !m_pLoadData[i] )
		{
			Msg("\nNULL POINT! ["+i+" / "+c+"]\n");
			Msg("Corrupt data?\n");
			m_pLoadData.resize( i-1 );
			break;
		};
	}

	if ( m_nLoadType & KF_DATA_TYPE_PATH )
	{
		// No longer dirty
		m_bDirty = false;

		m_PathList[ m_szLoadInputName ] <- { frames = m_pLoadData, init_fov = m_nPathInitialFOV };
	}

	Msg(Fmt( "]\nLoading complete:  \"%s\" ( %s )\n",
		m_szLoadInputName,
		(
			( m_nLoadType & KF_DATA_TYPE_PATH ) ?
			( m_pLoadData.len() * g_FrameTime ) + " seconds" :
			m_pLoadData.len() + " keyframes"
		)
	));

	m_pLoadData = null;
	m_pLoadInput = null;
	m_szLoadInputName = null;

	if ( m_pUndoLoad )
	{
		m_pUndoLoad.ClonePost();
		PushUndo( m_pUndoLoad );
		m_pUndoLoad = null;
	};

	return PlaySound( SND_BUTTON );
}


//--------------------------------------------------------------
//--------------------------------------------------------------


function CameraThink()
{
	if ( !m_bPreview )
	{
		local pt = m_PathData[m_nPlaybackIdx];
		CameraSetOrigin( pt.origin );

		local ang = pt.angles;
		CameraSetAngles( ang );

		// NOTE: This is here for external effects that may use player angles (such as flashbangs)
		if ( !m_bObserver )
			SetViewAngles2D( ang );

		if ( pt.fov )
			CameraSetFov( pt.fov, pt.fov_rate );

		if ( m_nPlaybackTarget <= ++m_nPlaybackIdx )
		{
			if ( m_bPlaybackLoop )
			{
				if ( m_PathSelection[0] && m_PathSelection[1] )
				{
					m_nPlaybackIdx = m_PathSelection[0];
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
		SplineOrigin( m_nPlaybackIdx, m_flPreviewFrac, pos );
		SplineAngles( m_nPlaybackIdx, m_flPreviewFrac, ang );

		CameraSetOrigin( pos );
		CameraSetAngles( ang );

		// HACKHACK: set player angles as well to get the correct angle in CurrentViewAngles in edit mode
		if ( !m_bObserver )
			SetViewAngles2D( ang );

		local key = m_KeyFrames[ m_nPlaybackIdx ];

		m_flPreviewFrac += 1.0 / key.samplecount + FLT_EPSILON;

		if ( m_flPreviewFrac >= 1.0 )
		{
			m_flPreviewFrac = 0.0;

			if ( m_nPlaybackTarget <= ++m_nPlaybackIdx )
				return Stop();
		};
	};
}

// kf_play()
function PlayPath( szName = KF_NOPARAM, bLoop = false )
{
	if ( szName == KF_NOPARAM )
		throw "wrong number of parameters";

	if ( m_bCompiling )
		return MsgFail("Cannot start playback while compiling!\n");

	if ( m_bPlaybackPending )
		return MsgFail("Playback has not started yet!\n");

	if ( m_bInPlayback )
		return MsgFail("Playback is already running.\n");

	if ( !( szName in m_PathList ) )
		return MsgFail(Fmt( "Could not find path '%s'\n", szName ));

	// unsee
	if ( m_bSeeing )
		SeeKeyframe(1);

	if ( developer() > 1 )
	{
		Msg("Setting developer level to 1\n");
		SendToConsole("developer 1");
	}

	m_bPlaybackLoop = bLoop;
	m_bPreview = false;

	if ( !m_bObserver )
		m_AnglesRestore = MainViewAngles();

	if ( m_bObserver && m_bPositionRestore )
		m_OriginRestore = MainViewOrigin();

	if ( m_bPlaybackLoop )
	{
		Msg("loop\n");
	}

	m_PathData = m_PathList[szName].frames.weakref();

	m_nPlaybackTarget = m_PathData.len();
	m_nPlaybackIdx = 0;

	CameraSetFov( m_PathList[szName].init_fov, 0.0 );

	local firstpt = m_PathData[m_nPlaybackIdx];

	// HACKHACK: set player angles as well to get the correct angle in CurrentViewAngles in edit mode
	SetViewAngles2D( firstpt.angles );

	CameraSetOrigin( firstpt.origin );
	CameraSetAngles( firstpt.angles );

	CameraSetEnabled( true );
	CameraSetThinkEnabled( false );

	local t = 0.0;

	if ( !m_bObserver )
	{
		MsgHint("Starting in 3...\n");
		PlaySound( SND_COUNTDOWN_BEEP );
		t = 1.0;

		VS.EventQueue.AddEvent( MsgHint,   t, [this, "Starting in 2...\n"] );
		VS.EventQueue.AddEvent( PlaySound, t, [this, SND_COUNTDOWN_BEEP]   );

		t += 1.0;

		VS.EventQueue.AddEvent( MsgHint,   t, [this, "Starting in 1...\n"] );
		VS.EventQueue.AddEvent( PlaySound, t, [this, SND_COUNTDOWN_BEEP]   );

		t += 1.0;

		HideHudHint( t );

		player.SetHealth( 1337 );
	}

	m_bPlaybackPending = true;
	VS.EventQueue.AddEvent( _Play, t, this );
}


const KF_PLAY_DEFAULT = 0;;
const KF_PLAY_LOOP = 2;;
const KF_PLAY_PREVIEW = 1;;

// kf_play
function Play( type = KF_PLAY_DEFAULT )
{
	if ( m_bCompiling )
		return MsgFail("Cannot start playback while compiling!\n");

	if ( m_bPlaybackPending )
		return MsgFail("Playback has not started yet!\n");

	if ( m_bInPlayback )
		return MsgFail("Playback is already running.\n");

	if ( m_bObserver && ( m_szCurPath in m_PathList ) )
	{
		m_PathData = m_PathList[ m_szCurPath ].frames.weakref();
	}

	// unsee
	if ( m_bSeeing )
		SeeKeyframe(1);

	if ( ((type == KF_PLAY_DEFAULT) || (type == KF_PLAY_LOOP)) && !m_PathData.len() )
		return MsgFail("No compiled data found.\n");

	if ( (type == KF_PLAY_PREVIEW) && !m_KeyFrames.len() )
		return MsgFail("No keyframe data found.\n");

	if ( developer() > 1 )
	{
		Msg("Setting developer level to 1\n");
		SendToConsole("developer 1");
	};

	if ( ((type == KF_PLAY_DEFAULT) || (type == KF_PLAY_LOOP)) && m_bDirty )
	{
		Msg("Playing back outdated animation; compile to see changes, or use kf_preview\n");
	};

	m_bPlaybackLoop = ( type == KF_PLAY_LOOP );
	m_bPreview = ( type == KF_PLAY_PREVIEW );

	if ( !m_bObserver )
		m_AnglesRestore = MainViewAngles();

	if ( m_bObserver && m_bPositionRestore )
		m_OriginRestore = MainViewOrigin();

	if ( m_bPlaybackLoop )
	{
		Msg("loop\n");
	};

	if ( (type == KF_PLAY_DEFAULT) || (type == KF_PLAY_LOOP) )
	{
		if ( m_PathSelection[0] && m_PathSelection[1] )
		{
			m_nPlaybackTarget = m_PathSelection[1];
			m_nPlaybackIdx = m_PathSelection[0];

			Msg(Fmt( "selection [%d -> %d]\n", m_PathSelection[0], m_PathSelection[1] ));
		}
		else
		{
			m_nPlaybackTarget = m_PathData.len();
			m_nPlaybackIdx = 0;

			CameraSetFov( m_nPathInitialFOV, 0.0 );
		};

		local firstpt = m_PathData[m_nPlaybackIdx];

		// HACKHACK: set player angles as well to get the correct angle in CurrentViewAngles in edit mode
		SetViewAngles2D( firstpt.angles );

		CameraSetOrigin( firstpt.origin );
		CameraSetAngles( firstpt.angles );
	}
	else
	{
		Msg("preview mode\n");

		if ( m_bAutoFillBoundaries )
			FillBoundaries();

		m_nPlaybackTarget = m_KeyFrames.len() - 2;
		m_nPlaybackIdx = 1;
		m_flPreviewFrac = 0.0;

		local pos = Vector();
		local ang = Vector();
		SplineOrigin( m_nPlaybackIdx, m_flPreviewFrac, pos );
		SplineAngles( m_nPlaybackIdx, m_flPreviewFrac, ang );

		// HACKHACK: set player angles as well to get the correct angle in CurrentViewAngles in edit mode
		SetViewAngles2D( ang );

		CameraSetOrigin( pos );
		CameraSetAngles( ang );
	};

	CameraSetEnabled( true );
	CameraSetThinkEnabled( false );

	local t = 0.0;

	if ( !m_bObserver )
	{
		// Count down from 2 in preview mode
		if ( !m_bPreview )
		{
			MsgHint("Starting in 3...\n");
			PlaySound( SND_COUNTDOWN_BEEP );
			t = 1.0;
		}

		VS.EventQueue.AddEvent( MsgHint,   t, [this, "Starting in 2...\n"] );
		VS.EventQueue.AddEvent( PlaySound, t, [this, SND_COUNTDOWN_BEEP]   );

		t += 1.0;

		VS.EventQueue.AddEvent( MsgHint,   t, [this, "Starting in 1...\n"] );
		VS.EventQueue.AddEvent( PlaySound, t, [this, SND_COUNTDOWN_BEEP]   );

		t += 1.0;

		HideHudHint( t );

		player.SetHealth( 1337 );
	}

	m_bPlaybackPending = true;
	VS.EventQueue.AddEvent( _Play, t, this );
}

function _Play()
{
	m_bPlaybackPending = false;
	m_bInPlayback = true;
	CameraSetThinkEnabled( true );
	return Msg("Playback has started.\n");
}

// kf_stop
function Stop()
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
	{
		return MsgFail("Playback is not running.\n");
	};;

	if ( m_bPreview )
	{
		Msg("Preview has ended.\n");

		if ( m_bAutoFillBoundaries )
			FillBoundariesRevert();
	}
	else
	{
		Msg("Playback has ended.\n");
	};

	m_bInPlayback = false;
	m_bPreview = false;

	CameraSetEnabled( false );
	CameraSetThinkEnabled( false );

	CameraSetFov(0,0);

	if ( !m_bObserver )
	{
		VS.EventQueue.AddEvent( SetViewAngles2D, 0.025, [ this, m_AnglesRestore ] );
		m_AnglesRestore = null;
	}

	if ( m_bObserver )
	{
		if ( m_bPositionRestore )
		{
			VS.EventQueue.AddEvent( SetViewOrigin, 0.025, [ this, m_OriginRestore ] );
			m_OriginRestore = null;
		}

		// Reset view roll
		SetViewAngles2D( MainViewAngles() );
	}

	SetEditModeTemp( m_bInEditMode );

	return PlaySound( SND_PLAY_END );
}


//--------------------------------------------------------------


class CUndoKeyframeFOV extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].SetFov( m_nFovOld );

		if ( Base.m_nCurKeyframe == m_nKeyIndex && Base.m_bSeeing )
		{
			Base.UpdateCamera();
		}
	}

	function Redo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].SetFov( m_nFovNew );

		if ( Base.m_nCurKeyframe == m_nKeyIndex && Base.m_bSeeing )
		{
			Base.UpdateCamera();
		}
	}

	function Desc()
	{
		return Fmt( "fov #%i : [%i] -> [%i]", m_nKeyIndex, m_nFovOld, m_nFovNew );
	}

	m_nKeyIndex = null;
	m_nFovOld = null;
	m_nFovNew = null;
}

function SetKeyframeFOV( input )
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_KeyFrames.len() )
		return MsgFail("No keyframes found.\n");

	if ( !m_bInEditMode )
		return MsgFail("Cannot add FOV data while edit mode is disabled.\n");

	input = input.tointeger();

	// refresh
	if ( m_bSeeing )
		CameraSetFov( input, 0.25 );

	local key = m_KeyFrames[ m_nCurKeyframe ];

	local pUndo = CUndoKeyframeFOV();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = m_nCurKeyframe;
	pUndo.m_nFovOld = GetInterpolatedKeyframeFOV( m_nCurKeyframe );
	pUndo.m_nFovNew = input;

	key.SetFov( input );

	CompileFOV();

	MsgHint(Fmt( "Set keyframe #%d FOV to %d\n", m_nCurKeyframe, input ));
	return PlaySound( SND_BUTTON );
}


class CUndoKeyframeAngles extends CUndoElement
{
	function Undo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].SetAngles( m_vecAnglesOld );

		if ( Base.m_nCurKeyframe == m_nKeyIndex && Base.m_bSeeing )
		{
			Base.UpdateCamera();
		}
	}

	function Redo()
	{
		Base.m_KeyFrames[ m_nKeyIndex ].SetAngles( m_vecAnglesNew );

		if ( Base.m_nCurKeyframe == m_nKeyIndex && Base.m_bSeeing )
		{
			Base.UpdateCamera();
		}
	}

	function Desc()
	{
		return Fmt( "angles #%i", m_nKeyIndex );
	}

	m_nKeyIndex = null;
	m_vecAnglesOld = null;
	m_vecAnglesNew = null;
}

class CUndoKeyframePan extends CUndoKeyframeAngles
{
	function Desc()
	{
		return Fmt( "pan #%i", m_nKeyIndex );
	}
}

class CUndoKeyframeRoll extends CUndoKeyframeAngles
{
	function Desc()
	{
		return Fmt( "roll #%i", m_nKeyIndex );
	}
}

function SetKeyframeRoll( input )
{
	if ( m_bCompiling )
		return MsgFail("Cannot modify keyframes while compiling!\n");

	if ( !m_bInEditMode )
		return MsgFail("Cannot set camera roll while edit mode is disabled.\n");

	input = VS.AngleNormalize( input.tofloat() );

	local key = m_KeyFrames[ m_nCurKeyframe ];

	local pUndo = CUndoKeyframeRoll();
	PushUndo( pUndo );
	pUndo.m_nKeyIndex = m_nCurKeyframe;
	pUndo.m_vecAnglesOld = key.angles * 1;

	key.angles.z = input;
	key.SetAngles( key.angles );

	pUndo.m_vecAnglesNew = key.angles * 1;

	// refresh
	if ( m_bSeeing )
	{
		if ( m_nSelectedKeyframe == -1 )
			return Error("[ERROR] Assertion failed. Seeing while no keyframe is selected.\n");

		CameraSetAngles( key.angles );
	};

	MsgHint(Fmt( "Set keyframe #%d roll to %g\n", m_nCurKeyframe, input ));
	return PlaySound( SND_BUTTON );
}

function Trim( flInputLen = KF_NOPARAM, bDirection = 1 )
{
	if ( flInputLen == KF_NOPARAM )
		throw "wrong number of parameters";

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
			m_TrimData.append( m_PathData.pop() );
		}

		m_TrimData.reverse();
	}
	else
	{
		for ( local i = nFramesToRemove; i--; )
		{
			m_TrimData.append( m_PathData.remove(0) );
		}
	};

	Msg(Fmt( "Trimmed: %g -> %g\n", flCurLen, m_PathData.len() * g_FrameTime ));
	return PlaySound( SND_BUTTON );
}

function UndoTrim()
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
			m_PathData.append( m_TrimData[i] );
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
	return PlaySound( SND_BUTTON );
}

//--------------------------------------------------------------
//--------------------------------------------------------------

// kf_positionrestore
function SetPositionRestore( state = null )
{
	if ( m_bPlaybackPending || m_bInPlayback )
		return MsgFail("Cannot set position restore while in playback\n");

	if ( state == null )
		state = !m_bPositionRestore;

	m_bPositionRestore = !!state;

	Msg(Fmt( "Post-playback position restore: %i\n", m_bPositionRestore.tointeger() ));
	return PlaySound( SND_BUTTON );
}

// kf_observer
function SetObserver( state )
{
	if ( m_bPlaybackPending || m_bInPlayback )
		return MsgFail("Cannot set observer state while in playback\n");

	m_bObserver = !!state;

	if ( state )
	{
		PlaySound = dummy;
		Hint = dummy;
		HideHudHint = dummy;

		m_nMoveTypeRoam = MOVETYPE_OBSERVER;

		if ( m_bInEditMode )
		{
			SetThinkEnabled( m_hThinkAnim, false );
			SetThinkEnabled( m_hThinkFrame, false );
		}

		if ( player )
		{
			VS.SetInputCallback( player, null, null, null );

			if ( player.GetTeam() != 1 )
				player.SetTeam(1);

			player.SetMoveType( m_nMoveTypeRoam );
		}
	}
	else
	{
		PlaySound = _PlaySound;
		Hint = _Hint;
		HideHudHint = _HideHudHint;

		m_nMoveTypeRoam = MOVETYPE_NOCLIP;

		SetEditMode( m_bInEditMode );
		m_szCurPath = null;

		if ( player )
		{
			VS.SetInputCallback( player, "+use", OnUsePressed.bindenv(this), KF_CB_CONTEXT );
			VS.SetInputCallback( player, "+forward", OnForwardPressed.bindenv(this), KF_CB_CONTEXT );
			VS.SetInputCallback( player, "-forward", OnForwardReleased.bindenv(this), KF_CB_CONTEXT );
			VS.SetInputCallback( player, "+back", OnBackPressed.bindenv(this), KF_CB_CONTEXT );
			VS.SetInputCallback( player, "-back", OnBackReleased.bindenv(this), KF_CB_CONTEXT );
			VS.SetInputCallback( player, "+attack", OnMouse1Pressed.bindenv(this), KF_CB_CONTEXT );
			VS.SetInputCallback( player, "-attack", OnMouse1Released.bindenv(this), KF_CB_CONTEXT );
			VS.SetInputCallback( player, "+attack2", OnMouse2Pressed.bindenv(this), KF_CB_CONTEXT );
			VS.SetInputCallback( player, "-attack2", OnMouse2Released.bindenv(this), KF_CB_CONTEXT );

			if ( player.GetTeam() != 2 && player.GetTeam() != 3 )
				player.SetTeam(2);

			player.SetHealth( 1337 );
			player.SetMoveType( m_nMoveTypeRoam );

			PlaySound( SND_BUTTON );

			SendToConsole("drop;drop;drop;drop;drop");
		}
	}
}

function SetPlayer( i )
{
	if ( m_bCompiling )
		return print( "Cannot set player while compiling\n" );

	if ( m_bInPlayback || m_bPlaybackPending )
		return print( "Cannot set player while in playback\n" );

	if ( i == -1 )
	{
		print( "Set controller player using: script kf_setplayer( index )\n" );
		return;
	}

	// Disable on current player
	if ( player && player.entindex() != i )
	{
		VS.SetInputCallback( player, null, null, null );

		if ( m_bSeeing )
			SeeKeyframe( 1, 0 );

		switch ( player.GetTeam() )
		{
			case 1:
				player.SetMoveType( MOVETYPE_OBSERVER );
				break;
			case 2:
			case 3:
				player.SetMoveType( 2 );
				break;
		}

		print(Fmt( "Disabled on player %i\n", player.entindex() ));

		player = null;
	}

	if ( i == 0 )
	{
		player = null;

		// HACKHACK: temporarily disallow playing sound
		local t = PlaySound;
		PlaySound = dummy;

		SetEditModeTemp( false ); // so that existing think doesn't fail
		SetEditMode( false );

		PlaySound = t;
		return;
	}

	local pl = ToExtendedPlayer( VS.GetPlayerByIndex( i ) );
	if ( !pl )
	{
		print(Fmt( "ERROR: Player (%i) is not found!\n", i ));
		return;
	}

	if ( m_bObserver && pl.GetTeam() != 1 )
	{
		print(Fmt( "WARNING: Player (%i) is not spectator (observer mode is enabled), NOT proceeding!\n", i ));
		return;
	}

	player = pl;

	if ( m_bSeeing )
		SeeKeyframe( 1, 0 );

	if ( !m_bPlaybackPending && !m_bInPlayback )
	{
		// init
		local t = m_bObserver;
		m_bObserver = false;
		CameraSetEnabled( true );
		CameraSetEnabled( false );
		m_bObserver = t;
	}

	return SetObserver( m_bObserver );
}

function PostSpawnMsg()
{
	Msg = print;
	Msg("\n");
	PrintHelp();

	local tr = 1.0/FrameTime();

	if ( !VS.IsInteger( 128.0 / tr ) )
	{
		Msg(Fmt( "[!] Invalid tickrate (%g)! Only 128 and 64 tickrates are supported.\n\n", tr ));
	}
	else
	{
		Msg(Fmt( "Server tickrate: %g\n\n", tr ));
	};

	if ( !player )
	{
		Msg( "[!] No controller player is found, set using: script kf_setplayer( index )\n\n" );
	}

	MsgFlush();
	Msg("\n");
	LoadFile(false);
}

// kf_help
function PrintHelp()
{
	Msg("\n");
	Msg(Fmt( "   [v%s]     github.com/samisalreadytaken/keyframes\n", version ));
	Msg("\n");
	Msg("kf_add                  : Add new keyframe\n");
	Msg("kf_remove               : Remove the selected keyframe\n");
	Msg("kf_removefov            : Remove the FOV data from the selected keyframe\n");
	Msg("kf_clear                : Remove all keyframes\n");
	Msg("kf_insert               : Insert new keyframe before the selected keyframe\n");
	Msg("kf_replace              : Replace the current keyframe\n");
	Msg("kf_copy                 : Set player pos/ang to the current keyframe\n");
	Msg("kf_undo                 : Undo last action\n");
	Msg("kf_redo                 : Redo last action\n");
	Msg("kf_undo_history         : Show action history\n");
	Msg("                        :\n");
	Msg("kf_compile              : Compile the keyframe data\n");
	Msg("kf_smooth_angles        : Smooth compiled animation angles\n");
	Msg("kf_smooth_angles_exp    : Smooth compiled animation angles exponentially\n");
	Msg("kf_smooth_origin        : Smooth compiled animation origin\n");
	Msg("kf_play                 : Play the compiled data\n");
	Msg("kf_play_loop            : Play the compiled data looped\n");
	Msg("kf_preview              : Play the keyframe data without compiling\n");
	Msg("kf_stop                 : Stop playback\n");
	Msg("script kf_play(name)    : Play named path\n");
	Msg("kf_savepath             : Export the compiled data\n");
	Msg("kf_savekeys             : Export the keyframe data\n");
	Msg("                        :\n");
	Msg("kf_mode_angles          : Cycle through angle interpolation types\n");
	Msg("kf_mode_origin          : Cycle through position interpolation types\n");
	Msg("kf_auto_fill_boundaries : Duplicate the first and last keyframes in compilation\n");
	Msg("                        :\n");
	Msg("kf_edit                 : Toggle edit mode\n");
	Msg("kf_manipulator          : Toggle 3D manipulator\n");
	Msg("kf_select               : Select and hold current keyframe\n");
	Msg("kf_select_path          : In edit mode, select animation path\n");
	Msg("kf_see                  : In edit mode, see the current selection\n");
	Msg("kf_next                 : While holding a keyframe, select the next one\n");
	Msg("kf_prev                 : While holding a keyframe, select the previous one\n");
	Msg("kf_showkeys             : In edit mode, toggle showing keyframes\n");
	Msg("kf_showpath             : In edit mode, toggle showing the animation path\n");
	Msg("                        :\n");
	Msg("kf_guides               : Toggle camera guides\n");
	Msg("kf_elements             : Toggle between element selection and camera animation\n");
	Msg("kf_createlight          : Create a light\n");
	Msg("script kf_setparams({}) : Set current element parameters\n");
	Msg("kf_duplicate            : Duplicate current element in place\n");
	Msg("                        :\n");
	Msg("script kf_fov(val)      : Set FOV data on the selected keyframe\n");
	Msg("script kf_roll(val)     : Set camera roll on the selected keyframe\n");
	Msg("script kf_frametime(val): Sets the time it takes to travel until the next keyframe\n");
	Msg("script kf_samplecount(val): Sets how many samples to take until the next keyframe\n");
	Msg("                        :\n");
	Msg("script kf_transform()   : Rotate all keyframes around key with optional translation offset (idx,offset,rotation)\n");
	Msg("                        :\n");
	Msg("kf_loadfile             : Load data file\n");
	Msg("script kf_trim(val)     : Trim compiled animation path to specified length\n");
	Msg("kf_trim_undo            : Undo last trim action\n");
	Msg("                        :\n");
	Msg("kf_observeron           : Turn on observer mode\n");
	Msg("kf_observeroff          : Turn off observer mode\n");
	Msg("script kf_setplayer(idx): Set controller player by index\n");
	Msg("                        :\n");
	Msg("kf_help                 : List all commands\n");
	Msg("\n");
	Msg("--- --- --- --- --- ---\n");
	Msg("\n");
}

// init entities and some variables
VS.EventQueue.AddEvent( function()
{
	print("loading... (2)\n");

	SetPlayer( KF_PLAYER_INDEX );

	if ( !KF_OBSERVER_MODE )
	{
		VS.OnTimer( m_hThinkEdit, EditModeThink, this );
		VS.OnTimer( m_hThinkAnim, AnimThink, this );
		VS.OnTimer( m_hThinkFrame, FrameThink, this );
	}

	VS.OnTimer( m_hThinkCam, CameraThink, this );

	if ( m_nInterpolatorAngle == null )
	{
		m_nInterpolatorAngle = KF_INTERP_D3DX;
		m_nInterpolatorOrigin = KF_INTERP_CATMULL_ROM;
	}

	if ( m_nManipulatorMode == 0 )
	{
		m_nManipulatorMode = KF_TRANSFORM_TRANSLATE;
	}

	SetAngleInterp( m_nInterpolatorAngle );
	SetOriginInterp( m_nInterpolatorOrigin );

	if ( player )
		SetEditMode( m_bInEditMode );

	if ( KF_OBSERVER_MODE || ( KF_PLAYER_INDEX != 1 ) )
	{
		VS.EventQueue.AddEvent( PostSpawnMsg, 0.05, this );
	}
	// print after Steamworks Msg
	else if ( GetDeveloperLevel() > 0 )
	{
		VS.EventQueue.AddEvent( SendToConsole, 0.75, [null, "clear;script _KF_.PostSpawnMsg()"] );
	}
	else
	{
		SendToConsole("clear;script _KF_.PostSpawnMsg()");
	}

	return PlaySound( SND_SPAWN );
}, 0.05, this );

//--------------------------------------------------------------
/*
:%s/SendToConsole(\"alias \(.\{-}\)\\"script _KF_\.\(.\{-}\)\\"\");/Convars.RegisterCommand( \"\1\", function(...) { \2; }.bindenv(this), \"\", 0 );/
:%s/SendToConsole(\"alias \(.\{-}\)\");/Convars.RegisterCommand( \"\1\", dummy, \"\", 0 );/
*/
Convars.RegisterCommand( "kf_add", function(...) { AddKeyframe(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_remove", function(...) { RemoveKeyframe(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_clear", function(...) { RemoveAllKeyframes(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_insert", function(...) { InsertKeyframe(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_copy", function(...) { CopyKeyframe(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_replace", function(...) { ReplaceKeyframe(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_removefov", function(...) { RemoveFOV(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_undo", function(...) { Undo(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_redo", function(...) { Redo(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_undo_history", function(...) { PrintUndoStack(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_compile", function(...) { Compile(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_smooth_angles", function(...) { SmoothAngles(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_smooth_angles_exp", function(...) { SmoothAngles(1); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_smooth_origin", function(...) { SmoothOrigin(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_play", function(...) { Play(KF_PLAY_DEFAULT); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_play_loop", function(...) { Play(KF_PLAY_LOOP); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_preview", function(...) { Play(KF_PLAY_PREVIEW); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_stop", function(...) { Stop(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_savepath", function(...) { Save(KF_DATA_TYPE_PATH); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_savekeys", function(...) { Save(KF_DATA_TYPE_KEYFRAMES); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_mode_angles", function(...) { SetAngleInterp(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_mode_origin", function(...) { SetOriginInterp(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_auto_fill_boundaries", function(...) { SetAutoFillBoundaries(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_edit", function(...) { SetEditMode(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_manipulator", function(...) { ShowGizmo(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_select", function(...) { SelectKeyframe(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_select_path", function(...) { SelectPath(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_see", function(...) { SeeKeyframe(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_next", function(...) { NextKeyframe(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_prev", function(...) { PrevKeyframe(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_showkeys", function(...) { ShowToggle(0); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_showpath", function(...) { ShowToggle(1); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_trim_undo", function(...) { UndoTrim(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_help", function(...) { PrintHelp(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_loadfile", function(...) { LoadFile(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "+kf_moveup", function(...) { IN_Move(1); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "+kf_movedown", function(...) { IN_Move(2); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "-kf_moveup", function(...) { IN_Move(0); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "-kf_movedown", function(...) { IN_Move(0); }.bindenv(this), "", 0 );

Convars.RegisterCommand( "kf_guides", function(...) { ToggleCameraGuides(); }.bindenv(this), "", 0 );

Convars.RegisterCommand( "kf_createlight", function(...) { CreateLight(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_duplicate", function(...) { DuplicateElement(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_elements", function(...) { ToggleElementSpace(); }.bindenv(this), "", 0 );

Convars.RegisterCommand( "kf_positionrestore", function(...) { SetPositionRestore(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_observeron", function(...) { SetObserver(1); }.bindenv(this), "", 0 );
if ( !KF_OBSERVER_MODE )
	Convars.RegisterCommand( "kf_observeroff", function(...) { SetObserver(0); }.bindenv(this), "", 0 );

Convars.RegisterCommand( "+kf_q", function(...) { IN_KeyDown('Q'); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "-kf_q", function(...) { IN_KeyUp('Q'); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "+kf_r", function(...) { IN_KeyDown('R'); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "-kf_r", function(...) { IN_KeyUp('R'); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "+kf_t", function(...) { IN_KeyDown('T'); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "-kf_t", dummy, "", 0 );
Convars.RegisterCommand( "+kf_f", function(...) { IN_KeyDown('F'); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "-kf_f", dummy, "", 0 );
Convars.RegisterCommand( "+kf_g", function(...) { IN_KeyDown('G'); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "-kf_g", dummy, "", 0 );
Convars.RegisterCommand( "+kf_h", function(...) { IN_KeyDown('H'); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "-kf_h", dummy, "", 0 );
Convars.RegisterCommand( "+kf_z", function(...) { IN_KeyDown('Z'); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "-kf_z", dummy, "", 0 );
Convars.RegisterCommand( "+kf_x", function(...) { IN_KeyDown('X'); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "-kf_x", dummy, "", 0 );
Convars.RegisterCommand( "+kf_c", function(...) { IN_KeyDown('C'); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "-kf_c", function(...) { IN_KeyUp('C'); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "+kf_v", function(...) { IN_KeyDown('V'); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "-kf_v", function(...) { IN_KeyUp('V'); }.bindenv(this), "", 0 );

// deprecated
Convars.RegisterCommand( "kf_save", function(...) { Save(); }.bindenv(this), "", 0 );
Convars.RegisterCommand( "kf_load", function(...) { LoadFileError(); }.bindenv(this), "", 0 );
//--------------------------------------------------------------

// global bindings for easy use with 'script kf_XX()'
::kf_roll <- SetKeyframeRoll.bindenv(this);
::kf_fov <- SetKeyframeFOV.bindenv(this);
::kf_samplecount <- SetSampleCount.bindenv(this);
::kf_frametime <- SetFrameTime.bindenv(this);
::kf_trim <- Trim.bindenv(this);
::kf_transform <- TransformKeyframes.bindenv(this);
::kf_play <- PlayPath.bindenv(this);
::kf_setplayer <- SetPlayer.bindenv(this);

::kf_setparams <- SetElementParamaters.bindenv(this);
::kf_windowresolution <- SetWindowResolution.bindenv(this);

}.call(_KF_);
