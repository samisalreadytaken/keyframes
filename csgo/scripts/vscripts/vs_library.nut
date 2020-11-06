//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//- v2.39.6 -------------------------------------------------------------
local _=::getroottable();if("VS"in _&&typeof::VS=="table"&&"MAX_COORD_FLOAT"in _&&!::VS._reload)return;;local __=function(){}local _f=__.getinfos().src;_f=_f.slice(0,_f.find(".nut"));__=function():(_f){if(_f!="vs_library")::print("Loading vs_library...\n");local PORTAL2="CPortal_Player"in::getroottable()&&"TurnOnPotatos"in::CPortal_Player&&::CPortal_Player.TurnOnPotatos.getinfos().native,EVENTS=!!::Entities.FindByClassname(null,"logic_eventlistener");::VS<-{version="vs_library v2.39.6",_reload=false}if(::print.getinfos().native)::Msg<-::print;if(::EntFireByHandle.getinfos().native)::DoEntFireByInstanceHandle<-::EntFireByHandle;local ROOT=getroottable();::CONST<-getconsttable();::MAX_COORD_FLOAT<-16384.0;::MAX_TRACE_LENGTH<-56755.84086241;::DEG2RAD<-0.01745329;::RAD2DEG<-57.29577951;::collectgarbage();local _VEC=Vector(),Entities=::Entities,AddEvent=::DoEntFireByInstanceHandle,Vector=::Vector,RandomFloat=::RandomFloat,DebugDrawBox=::DebugDrawBox,DoUniqueString=::DoUniqueString,Time=::Time,Fmt=::format,sin=::sin,cos=::cos,atan2=::atan2,exp=::exp,pow=::pow,log=::log,compile=::compilestring;::max<-function(a,b)return a>b?a:b;::min<-function(a,b)return a<b?a:b;::clamp<-function(v,i,x){if(x<i)return x;else if(v<i)return i;else if(v>x)return x;else return v}function VS::IsInteger(f)return f.tointeger()==f;function VS::IsLookingAt(S,T,D,cos){local t=T-S;t.Norm();return t.Dot(D)>=cos}function VS::PointOnLineNearestPoint(S,E,P){local v1=E-S,d=v1.Dot(P-S)/v1.LengthSqr();if(d<0.0)return S;else if(d>1.0)return E;else return S+v1*d}function VS::GetAngle(f,t):(Vector,atan2){local d=f-t,p=57.29577951*atan2(d.z,d.Length2D()),y=57.29577951*(atan2(d.y,d.x)+3.14159265);return Vector(p,y,0.0)}function VS::GetAngle2D(f,t):(atan2){local d=t-f,y=57.29577951*atan2(d.y,d.x);return y}function VS::VectorVectors(F,R,U):(Vector){if(!F.x&&!F.y){R.x=0.0;R.y=-1.0;R.z=0.0;U.x=-F.z;U.y=0.0;U.z=0.0}else{local R=F.Cross(Vector(0.0,0.0,1.0));R.x=R.x;R.y=R.y;R.z=R.z;R.Norm();local U=R.Cross(F);U.x=U.x;U.y=U.y;U.z=U.z;U.Norm()}}function VS::AngleVectors(A,F=_VEC,R=null,U=null):(sin,cos){local sr,cr,rr,yr=0.01745329*A.y,sy=sin(yr),cy=cos(yr),pr=0.01745329*A.x,sp=sin(pr),cp=cos(pr);if(A.z){rr=0.01745329*A.z;sr=sin(rr);cr=cos(rr)}else{sr=0.0;cr=1.0};if(F){F.x=cp*cy;F.y=cp*sy;F.z=-sp};if(R){R.x=(-1.0*sr*sp*cy+-1.0*cr*-sy);R.y=(-1.0*sr*sp*sy+-1.0*cr*cy);R.z=-1.0*sr*cp};if(U){U.x=(cr*sp*cy+-sr*-sy);U.y=(cr*sp*sy+-sr*cy);U.z=cr*cp};return F}function VS::VectorAngles(F):(Vector,atan2,sqrt){local t,y,p;if(!F.y&&!F.x){y=0.0;if(F.z>0.0)p=270.0;else p=90.0}else{y=57.29577951*atan2(F.y,F.x);if(y<0.0)y+=360.0;t=sqrt(F.x*F.x+F.y*F.y);p=57.29577951*atan2(-F.z,t);if(p<0.0)p+=360.0};return Vector(p,y,0.0)}function VS::VectorYawRotate(I,Y,O=_VEC):(sin,cos){local r=0.01745329*Y,sy=sin(r),cy=cos(r);O.x=I.x*cy-I.y*sy;O.y=I.x*sy+I.y*cy;O.z=I.z;return O}function VS::YawToVector(y):(Vector,sin,cos){local a=0.01745329*y;return Vector(cos(a),sin(a),0.0)}function VS::VecToYaw(v):(atan2){if(!v.y&&!v.x)return 0.0;local y=57.29577951*atan2(v.y,v.x);if(y<0.0)y+=360.0;return y}function VS::VecToPitch(v):(atan2){if(!v.y&&!v.x){if(v.z<0.0)return 180.0;else return -180.0};return 57.29577951*atan2(-v.z,v.Length2D())}function VS::VectorIsZero(v)return !v.x&&!v.y&&!v.z;function VS::VectorsAreEqual(a,b,t=0.0){local x=a.x-b.x;if(x<0.0)x=-x;local y=a.y-b.y;if(y<0.0)y=-y;local z=a.z-b.z;if(z<0.0)z=-z;return(x<=t&&y<=t&&z<=t)}function VS::AnglesAreEqual(a,b,t=0.0){local d=a-b;d%=360.0;if(d>180.0)d-=360.0;else if(d<(-180.0))d+=360.0;;if(d<0.0)d=-d;return d<=t}function VS::CloseEnough(a,b,e){local d=a-b;if(d<0.0)d=-d;return d<=e}function VS::Approach(t,v,s){local dt=t-v;if(dt>s)v+=s;else if(dt<(-s))v-=s;else v=t;;return v}function VS::ApproachAngle(t,v,s){t%=360.0;if(t>180.0)t-=360.0;else if(t<(-180.0))t+=360.0;;v%=360.0;if(v>180.0)v-=360.0;else if(v<(-180.0))v+=360.0;;local dt=t-v;dt%=360.0;if(dt>180.0)dt-=360.0;else if(dt<(-180.0))dt+=360.0;;if(s<0.0)s=-s;if(dt>s)v+=s;else if(dt<(-s))v-=s;else v=t;;return v}function VS::AngleDiff(D,S){local df=D-S;df%=360.0;if(df>180.0)df-=360.0;else if(df<(-180.0))df+=360.0;;return df}function VS::AngleNormalize(A){A%=360.0;if(A>180.0)A-=360.0;else if(A<(-180.0))A+=360.0;;return A}function VS::QAngleNormalize(A){A.x%=360.0;if(A.x>180.0)A.x-=360.0;else if(A.x<(-180.0))A.x+=360.0;;A.y%=360.0;if(A.y>180.0)A.y-=360.0;else if(A.y<(-180.0))A.y+=360.0;;A.z%=360.0;if(A.z>180.0)A.z-=360.0;else if(A.z<(-180.0))A.z+=360.0;;return A}function VS::SnapDirectionToAxis(D,E=0.002){local p=1.0-E;if((D.x<0.0?-D.x:D.x)>p){if(D.x<0.0)D.x=-1.0;else D.x=1.0;D.y=0.0;D.z=0.0;return D};if((D.y<0.0?-D.y:D.y)>p){if(D.y<0.0)D.y=-1.0;else D.y=1.0;D.z=0.0;D.x=0.0;return D};if((D.z<0.0?-D.z:D.z)>p){if(D.z<0.0)D.z=-1.0;else D.z=1.0;D.x=0.0;D.y=0.0;return D}}function VS::VectorCopy(S,D){D.x=S.x;D.y=S.y;D.z=S.z;return D}function VS::VectorMin(a,b,o=_VEC){o.x=a.x<b.x?a.x:b.x;o.y=a.y<b.y?a.y:b.y;o.z=a.z<b.z?a.z:b.z;return o}function VS::VectorMax(a,b,o=_VEC){o.x=a.x>b.x?a.x:b.x;o.y=a.y>b.y?a.y:b.y;o.z=a.z>b.z?a.z:b.z;return o}function VS::VectorAbs(v){if(v.x<0.0)v.x=-v.x;if(v.y<0.0)v.y=-v.y;if(v.z<0.0)v.z=-v.z;return v}function VS::VectorAdd(a,b,o=_VEC){o.x=a.x+b.x;o.y=a.y+b.y;o.z=a.z+b.z;return o}function VS::VectorSubtract(a,b,o=_VEC){o.x=a.x-b.x;o.y=a.y-b.y;o.z=a.z-b.z;return o}function VS::VectorMultiply(a,b,o=_VEC){o.x=a.x*b;o.y=a.y*b;o.z=a.z*b;return o}function VS::VectorMultiply2(a,b,o=_VEC){o.x=a.x*b.x;o.y=a.y*b.y;o.z=a.z*b.z;return o}function VS::VectorDivide(a,b,o=_VEC){local d=1.0/b;o.x=a.x*d;o.y=a.y*d;o.z=a.z*d;return o}function VS::VectorDivide2(a,b,o=_VEC){o.x=a.x/b.x;o.y=a.y/b.y;o.z=a.z/b.z;return o}function VS::ComputeVolume(is,xs){local dt=xs-is;return dt.Dot(dt)}function VS::RandomVector(i=-RAND_MAX,x=RAND_MAX):(Vector,RandomFloat)return Vector(RandomFloat(i,x),RandomFloat(i,x),RandomFloat(i,x));function VS::CalcSqrDistanceToAABB(N,X,pt){local dt,ds=0.0;if(pt.x<N.x){dt=(N.x-pt.x);ds+=dt*dt}else if(pt.x>X.x){dt=(pt.x-X.x);ds+=dt*dt};;if(pt.y<N.y){dt=(N.y-pt.y);ds+=dt*dt}else if(pt.y>X.y){dt=(pt.y-X.y);ds+=dt*dt};;if(pt.z<N.z){dt=(N.z-pt.z);ds+=dt*dt}else if(pt.z>X.z){dt=(pt.z-X.z);ds+=dt*dt};;return ds}function VS::CalcClosestPointOnAABB(i,x,p,o=_VEC){o.x=(p.x<i.x)?i.x:(x.x<p.x)?x.x:p.x;o.y=(p.y<i.y)?i.y:(x.y<p.y)?x.y:p.y;o.z=(p.z<i.z)?i.z:(x.z<p.z)?x.z:p.z;return o}function VS::ExponentialDecay(dO,dT,dt):(log,exp)return exp(log(dO)/dT*dt);function VS::ExponentialDecay2(hl,dt):(exp)return exp(-0.69314718/hl*dt);function VS::ExponentialDecayIntegral(dO,dT,dt):(log,pow)return(pow(dO,dt/dT)*dT-dT)/log(dO);function VS::SimpleSpline(v){local q=v*v;return(3.0*q-2.0*q*v)}function VS::SimpleSplineRemapVal(v,A,B,C,D){if(A==B)return v>=B?D:C;local cV=(v-A)/(B-A);local vS=cV*cV;return C+(D-C)*(3.0*vS-2.0*vS*cV)}function VS::SimpleSplineRemapValClamped(v,A,B,C,D){if(A==B)return v>=B?D:C;local cV=(v-A)/(B-A);cV=(cV<0.0)?0.0:(1.0<cV)?1.0:cV;local vS=cV*cV;return C+(D-C)*(3.0*vS-2.0*vS*cV)}function VS::RemapVal(v,A,B,C,D){if(A==B)return v>=B?D:C;return C+(D-C)*(v-A)/(B-A)}function VS::RemapValClamped(v,A,B,C,D){if(A==B)return v>=B?D:C;local cV=(v-A)/(B-A);cV=(cV<0.0)?0.0:(1.0<cV)?1.0:cV;return C+(D-C)*cV}function VS::Bias(x,ba):(log,pow){local la=-1.0,e=0.0;if(la!=ba)e=log(ba)*-1.4427;return pow(x,e)}local Bias=::VS.Bias;function VS::Gain(x,ba):(Bias){if(x<0.5)return 0.5*Bias(2.0*x,1.0-ba);else return 1.0-0.5*Bias(2.0-2.0*x,1.0-ba)}function VS::SmoothCurve(x):(cos)return(1.0-cos(x*3.14159265))*0.5;function VS::MovePeak(x,k){if(x<k)return x*0.5/k;else return 0.5+0.5*(x-k)/(1.0-k)}local MovePeak=::VS.MovePeak,Gain=::VS.Gain;function VS::SmoothCurve_Tweak(x,k,p):(MovePeak,Gain,cos){local mp=MovePeak(x,k);local sh=Gain(mp,p);return(1.0-cos(sh*3.14159265))*0.5}function VS::Lerp(A,B,f)return A+(B-A)*f;function VS::FLerp(f1,f2,i1,i2,x)return f1+(f2-f1)*(x-i1)/(i2-i1);function VS::VectorLerp(v1,v2,f,o=_VEC){o.x=v1.x+(v2.x-v1.x)*f;o.y=v1.y+(v2.y-v1.y)*f;o.z=v1.z+(v2.z-v1.z)*f;return o}function VS::IsPointInBox(v,i,x)return(v.x>=i.x&&v.x<=x.x&&v.y>=i.y&&v.y<=x.y&&v.z>=i.z&&v.z<=x.z);function VS::IsBoxIntersectingBox(a,b,c,d){if((a.x>d.x)||(b.x<c.x))return false;else if((a.y>d.y)||(b.y<c.y))return false;else if((a.z>d.z)||(b.z<c.z))return false;else return true}::Ent<-function(s,i=null):(Entities)return Entities.FindByName(i,s);::Entc<-function(s,i=null):(Entities)return Entities.FindByClassname(i,s);::VecToString<-function(V,P="Vector(",S=",",X=")")return P+V.x+S+V.y+S+V.z+X;function VS::DrawEntityBBox(t,e,r=255,g=138,b=0,a=0):(DebugDrawBox)return DebugDrawBox(e.GetOrigin(),e.GetBoundingMins(),e.GetBoundingMaxs(),r,g,b,a,t);local Trace=::TraceLine;class::VS.TraceLine{constructor(A=null,B=null,E=null):(Vector,Trace){if(!A){local v=Vector();startpos=v;endpos=v;ignore=E;fraction=1.0;return};startpos=A;endpos=B;ignore=E;fraction=Trace(startpos,endpos,ignore)}function _cmp(d){if(fraction<d.fraction)return -1;if(fraction>d.fraction)return 1;return 0}function _add(d){return fraction+d.fraction}function _sub(d){return fraction-d.fraction}function _mul(d){return fraction*d.fraction}function _div(d){return fraction/d.fraction}function _modulo(d){return fraction%d.fraction}function _unm(){return -fraction}function _typeof(){return"trace_t"}startpos=null;endpos=null;ignore=null;fraction=0.0;hitpos=null;normal=null;m_Delta=null;m_IsSwept=null;m_Extents=null;m_IsRay=null;m_StartOffset=null;m_Start=null}local CTrace=::VS.TraceLine;function VS::TraceDir(v1,d,f=MAX_TRACE_LENGTH,e=null):(CTrace)return CTrace(v1,v1+(d*f),e);function VS::TraceLine::DidHit()return fraction<1.0;function VS::TraceLine::GetEnt(r){return GetEntByClassname("*",r)}function VS::TraceLine::GetEntByName(n,r):(Entities){if(!hitpos)GetPos();return Entities.FindByNameNearest(n,hitpos,r)}function VS::TraceLine::GetEntByClassname(n,r):(Entities){if(!hitpos)GetPos();return Entities.FindByClassnameNearest(n,hitpos,r)}function VS::TraceLine::GetPos(){if(!hitpos){if(DidHit())hitpos=startpos+(endpos-startpos)*fraction;else hitpos=endpos};return hitpos}function VS::TraceLine::GetDist()return(startpos-GetPos()).Length();function VS::TraceLine::GetDistSqr()return(startpos-GetPos()).LengthSqr();local TraceDir=::VS.TraceDir;function VS::TraceLine::GetNormal():(Vector,TraceDir){if(!normal){local u=Vector(0.0,0.0,0.5),d=endpos-startpos;d.Norm();GetPos();normal=(hitpos-TraceDir(startpos+d.Cross(u),d).GetPos()).Cross(hitpos-TraceDir(startpos+u,d).GetPos());normal.Norm()};return normal}function VS::TraceLine::Ray(N=::Vector(),X=::Vector()){m_Delta=endpos-startpos;m_IsSwept=m_Delta.LengthSqr()!=0.0;m_Extents=(X-N)*0.5;m_IsRay=m_Extents.LengthSqr()<1.e-6;m_StartOffset=(N+X)*0.5;m_Start=startpos+m_StartOffset;m_StartOffset*=-1.0;return this}function VS::UniqueString():(DoUniqueString){local s=DoUniqueString("");return s.slice(0,s.len()-1)}function VS::arrayFind(a,l){foreach(i,v in a)if(v==l)return i}function VS::arrayApply(a,f){foreach(i,v in a)a[i]=f(v)}local array=::array;function VS::arrayMap(a,f):(array){local n=array(a.len());foreach(i,v in a)n[i]=f(v);return n}local M=::print;function VS::DumpScope(I,A=false,D=true,G=true,n=0):(M){local w=Entities.First().GetScriptScope(),_=["Assert","Document","PrintHelp","RetrieveNativeSignature","UniqueString","IncludeScript","Entities","CSimpleCallChainer","CCallChainer","LateBinder","__ReplaceClosures","__DumpScope","printl","VSquirrel_OnCreateScope","VSquirrel_OnReleaseScope","PrecacheCallChain","OnPostSpawnCallChain","DispatchOnPostSpawn","DispatchPrecache","OnPostSpawn","PostSpawn","Precache","PreSpawnInstance","__EntityMakerResult","__FinishSpawn","__ExecutePreSpawn","EntFireByHandle","EntFire","RAND_MAX","_version_","_intsize_","PI","_charsize_","_floatsize_","self","__vname","__vrefs","_xa9b2dfB7ffe","VS","Chat","ChatTeam","txt","PrecacheModel","PrecacheScriptSound","delay","OnGameEvent_player_spawn","OnGameEvent_player_connect","VecToString","HPlayer","Ent","Entc","Quaternion","matrix3x4","max","min","clamp","MAX_COORD_FLOAT","MAX_TRACE_LENGTH","DEG2RAD","RAD2DEG","CONST"],d=function(c):(M)for(local i=c;i--;)M("   ");if(G)M(" ------------------------------\n");if(I){foreach(e,a in I){local t=typeof a,p=false;if(!A){switch(t){case"native function":p=true;break;case"class":foreach(k,v in a)if(typeof v=="native function"){p=true;break};break;case"table":if(w&&(a==w))p=true;break}if(!p){foreach(k in _)if(e==k){p=true;break}}}else if(e=="VS"||e=="Documentation"){p=true};;if(!p){d(n);M(e);switch(t){case"table":M("(TABLE) : "+a.len());if(!D)break;M("\n");d(n);M("{\n");DumpScope(a,A,D,false,n+1);d(n);M("}");break;case"array":M("(ARRAY) : "+a.len());if(!D)break;M("\n");d(n);M("[\n");DumpScope(a,A,D,false,n+1);d(n);M("]");break;case"string":M(" = \""+a+"\"");break;case"Vector":M(" = "+::VecToString(a));break;default:M(" = "+a)}M("\n")}}}else M("(NULL)\n");if(G)M(" ------------------------------\n")}function VS::ArrayToTable(a){local t={}foreach(i,v in a)t[v]<-i;return t}function VS::GetStackInfo(D=false,P=false){::print(" --- STACKINFO ----------------\n");local s,j=2;while(s=::getstackinfos(j++)){if(s.func=="pcall"&&s.src=="NATIVE")break;::print(" ("+(j-1)+")\n");local w,m=s.locals;if("this"in m&&typeof m["this"]=="table"){if(m["this"]==::getroottable()){w="roottable"}else{if(w=GetVarName(m["this"])){m[w]<-delete m["this"]}}};if(w=="roottable")DumpScope(s,P,0,0);else DumpScope(s,P,D,0);if(w)::print("scope = \""+w+"\"\n")}::print(" --- STACKINFO ----------------\n")}local Stack=::getstackinfos;function VS::GetCaller():(Stack)return Stack(3).locals["this"];function VS::GetCallerFunc():(Stack)return Stack(3).func;function VS::GetTableDir(i){if(typeof i!="table")throw"Invalid input type '"+typeof i+"' ; expected: 'table'";local a=[];local r=_f627f40d21a6(a,i);if(r)r.append("roottable");else{r=a;r.clear();r.append("roottable")};r.reverse();return r}function VS::_f627f40d21a6(b,t,l=ROOT){foreach(v,u in l)if(typeof u=="table")if(v!="VS"&&v!="Documentation")if(u==t){b.append(v);return b}else{local r=_f627f40d21a6(b,t,u);if(r){b.append(v);return r}}}function VS::FindVarByName(S){if(typeof S!="string")throw"Invalid input type '"+typeof S+"' ; expected: 'string'";return _fb3k55Ir91t7(S)}function VS::_fb3k55Ir91t7(t,l=ROOT){if(t in l)return l[t];else foreach(v,u in l)if(typeof u=="table")if(v!="VS"&&v!="Documentation"){local r=_fb3k55Ir91t7(t,u);if(r)return r}}function VS::GetVarName(v){local t=typeof v;if(t=="function"||t=="native function")return v.getinfos().name;return _fb3k5S1r91t7(t,v)}function VS::_fb3k5S1r91t7(t,i,s=ROOT){foreach(k,v in s){if(v==i)return k;if(typeof v=="table")if(k!="VS"&&k!="Documentation"){local r=_fb3k5S1r91t7(t,i,v);if(r)return r}}}local World;{World=Entc("worldspawn");if(!World){Msg("ERROR: could not find worldspawn\n");World=VS.CreateEntity("soundent")}}::delay<-function(X,T=0.0,E=World,A=null,C=null):(AddEvent)return AddEvent(E,"RunScriptCode",""+X,T,A,C);{VS.EventQueue<-{m_flNextQueue=-1.0,m_flLastQueue=-1.0}local T=Time;local E=[null,null];E[1]=(-0x7FFFFFFF).tofloat();VS.EventQueue.Dump<-function():(E,T,Fmt){local g=function(i):(Fmt){if(i==null)return"(NULL)";local s=""+i;local t=s.find("0x");if(t==null)return s;return Fmt("(%s)",s.slice(t,s.len()-1))}Msg(Fmt("VS::EventQueue::Dump: %g : next(%g), last(%g)\n",T(),m_flNextQueue,m_flLastQueue));for(local ev=E;ev=ev[0];){Msg(Fmt("   (%.2f) func '%s', %s '%s', activator '%s', caller '%s'\n",ev[1],g(ev[3]),((typeof ev[4]=="array")&&ev[4].len())?"arg":"env",g(((typeof ev[4]=="array")&&ev[4].len())?ev[4][0]:ev[5]),g(ev[6]),g(ev[7])))}Msg("VS::EventQueue::Dump: end.\n")}.bindenv(VS.EventQueue);VS.EventQueue.Clear<-function():(E){local ev=E[0];while(ev){local n=ev[0];ev[0]=null;ev[2]=null;ev=n}E[0]=null;m_flNextQueue=-1.0;m_flLastQueue=-1.0}.bindenv(VS.EventQueue);VS.EventQueue.CancelEventsByInput<-function(f):(E){local ev=E;while(ev=ev[0]){if(f==ev[3]){ev[2][0]=ev[0];if(ev[0])ev[0][2]=ev[2]}}if(!E[0])m_flNextQueue=-1.0}.bindenv(VS.EventQueue);VS.EventQueue.RemoveEvent<-function(ev):(E){if(typeof ev=="weakref")ev=ev.ref();local pe=E;while(pe=pe[0]){if(ev==pe){ev[2][0]=ev[0];if(ev[0])ev[0][2]=ev[2];if(!E[0])m_flNextQueue=-1.0;return}}}.bindenv(VS.EventQueue);VS.EventQueue.AddEventInternal<-function(w,d,T):(World,AddEvent,E){local ev=E;while(ev[0]){if(w[1]<ev[0][1])break;ev=ev[0]}w[0]=ev[0];w[2]=ev;ev[0]=w;if(m_flLastQueue!=T){m_flLastQueue=T;if((m_flNextQueue==-1.0)||(d<m_flNextQueue)){AddEvent(World,"RunScriptCode","::VS.EventQueue.ServiceEvents()",0.0,w[6],w[7]);m_flNextQueue=d}};return w.weakref()}.bindenv(VS.EventQueue);local AddEventInternal=VS.EventQueue.AddEventInternal;VS.EventQueue.AddEvent<-function(f,d,v=null,a=null,c=null):(AddEventInternal,T,ROOT){local T=T();local w=[null,null,null,null,null,null,null,null];w[1]=T+d;w[3]=f;w[6]=a;w[7]=c;local t=typeof v;if(t=="table")w[5]=v;else if(t=="array")w[4]=v;else w[5]=ROOT;;return AddEventInternal(w,d,T)}.bindenv(VS.EventQueue);VS.EventQueue.ServiceEvents<-function():(World,AddEvent,E,T){local T=T();local ev=E;while(ev=ev[0]){local f=ev[1];if(f<=T){local f=ev[3];if(f){local p=ev[4];if(p)f.acall(p);else f.call(ev[5])};ev[2][0]=ev[0];if(ev[0])ev[0][2]=ev[2];ev=E}else{local n=f-T;m_flNextQueue=n;AddEvent(World,"RunScriptCode","::VS.EventQueue.ServiceEvents()",n,ev[6],ev[7]);return}}m_flNextQueue=-1.0}.bindenv(VS.EventQueue)}local f=1.0/::FrameTime();function VS::GetTickrate():(f){return f}if(!PORTAL2){function VS::IsDedicatedServer(){throw"not ready"}local TS=4.0;local TO=12.0;local _TO=TO+FrameTime()*4;::VS.flCanCheckForDedicatedAfterSec<-fabs(clamp(Time(),0,_TO)-_TO);::_VS_DS_Init<-function():(TS,TO){if(::_VS_DS_bInitDone){::VS.flCanCheckForDedicatedAfterSec=0.0;delete::_VS_DS_Init;delete::_VS_DS_IsListen;delete::_VS_DS_bInitDone;delete::_VS_DS_bExecOnce;return};local t=::Time();if(t>TS){::SendToConsole("script _VS_DS_IsListen()");if(t>TO){::VS.IsDedicatedServer=function()return true;::_VS_DS_bInitDone=true}};::VS.EventQueue.AddEvent(::_VS_DS_Init,0.1,this)}::_VS_DS_IsListen<-function(){::VS.IsDedicatedServer=function()return false;::_VS_DS_bInitDone=true}if(!("_VS_DS_bExecOnce"in ROOT)){::_VS_DS_bExecOnce<-true;::_VS_DS_bInitDone<-false};if(::_VS_DS_bExecOnce){local t=Time();if(t<TS){::VS.EventQueue.AddEvent(::_VS_DS_Init,TS-t,this)}else{::_VS_DS_Init()};::_VS_DS_bExecOnce=false}};if(!PORTAL2){local Chat=::ScriptPrintMessageChatAll;local ChatTeam=::ScriptPrintMessageChatTeam;::Chat<-function(s):(Chat)return Chat(" "+s);::ChatTeam<-function(i,s):(ChatTeam)return ChatTeam(i," "+s);::Alert<-::ScriptPrintMessageCenterAll;::AlertTeam<-::ScriptPrintMessageCenterTeam;::txt<-{invis="\x00",white="\x01",red="\x02",purple="\x03",green="\x04",lightgreen="\x05",limegreen="\x06",lightred="\x07",grey="\x08",yellow="\x09",lightblue="\x0a",blue="\x0b",darkblue="\x0c",darkgrey="\x0d",pink="\x0e",orangered="\x0f",orange="\x10"}};::EntFireByHandle<-function(t,a,v="",d=0.0,o=null,c=null):(AddEvent)return AddEvent(t,a+"",v+"",d,o,c);::PrecacheModel<-function(s):(World)World.PrecacheModel(s);::PrecacheScriptSound<-function(s):(World)World.PrecacheSoundScript(s);if(!PORTAL2){function VS::MakePersistent(e)return e.__KeyValueFromString("classname","soundent")}else{::VS.MakePersistent<-dummy};function VS::SetParent(c,p):(AddEvent){if(p)return AddEvent(c,"SetParent","!activator",0.0,p,null);return AddEvent(c,"ClearParent","",0.0,null,null)}function VS::ShowGameText(e,t,m=null,d=0.0):(AddEvent){if(m)e.__KeyValueFromString("message",""+m);return AddEvent(e,"Display","",d,t,null)}function VS::ShowHudHint(e,t,m=null,d=0.0):(AddEvent){if(m)e.__KeyValueFromString("message",""+m);return AddEvent(e,"ShowHudHint","",d,t,null)}function VS::HideHudHint(e,t,d=0.0):(AddEvent)return AddEvent(e,"HideHudHint","",d,t,null);function VS::CreateMeasure(g,n=null,p=false,e=true,s=1.0):(AddEvent){local r=e?n?n+"":"vs.ref_"+UniqueString():n?n+"":null;if(!r||!r.len())throw"Invalid targetname";local e=CreateEntity("logic_measure_movement",{measuretype=e?1:0,measurereference="",targetreference=r,target=r,measureretarget="",targetscale=s.tofloat(),targetname=e?r:null},p);AddEvent(e,"SetMeasureReference",r,0.0,null,null);AddEvent(e,"SetMeasureTarget",g,0.0,null,null);AddEvent(e,"Enable","",0.0,null,null);return e}function VS::SetMeasure(h,s):(AddEvent)return AddEvent(h,"SetMeasureTarget",s,0.0,null,null);function VS::CreateTimer(D,I,L=null,U=null,O=false,P=false):(AddEvent){local e=CreateEntity("logic_timer",null,P);if(I!=null){e.__KeyValueFromInt("UseRandomTime",0);e.__KeyValueFromFloat("RefireTime",I.tofloat())}else{e.__KeyValueFromFloat("LowerRandomBound",L.tofloat());e.__KeyValueFromFloat("UpperRandomBound",U.tofloat());e.__KeyValueFromInt("UseRandomTime",1);e.__KeyValueFromInt("spawnflags",O.tointeger())};AddEvent(e,D?"Disable":"Enable","",0.0,null,null);return e}function VS::Timer(D,I,F=null,s=null,E=false,P=false){if(I==null){::Msg("\nERROR:\nRefire time cannot be null in VS.Timer\nUse VS.CreateTimer for randomised fire times.\n");throw"NULL REFIRE TIME"};local h=CreateTimer(D,I,null,null,null,P);OnTimer(h,F,s?s:GetCaller(),E);return h}function VS::OnTimer(e,F,s=null,E=false)return AddOutput(e,"OnTimer",F,s?s:GetCaller(),E);function VS::AddOutput(e,O,F,s=null,E=false):(compile){if(!s)s=GetCaller();if(F){if(typeof F=="string"){if(F.find("(")!=null)F=compile(F);else F=s[F]}else if(typeof F!="function")throw"Invalid function type "+typeof F}else{F=null;E=true};e.ValidateScriptScope();local r=e.GetScriptScope();r[O]<-E?F:F.bindenv(s);e.ConnectOutput(O,O);return r}function VS::AddOutput2(E,O,F,S=null,I=false):(AddEvent,Fmt){if(E.GetScriptScope()||typeof F=="function")return AddOutput(E,O,F,S,I);if(typeof F!="string")throw"Invalid function type "+typeof F;if(!S)S=GetCaller();if(!I){if(!("self"in S)){throw"Invalid function path. Not an entity"};AddEvent(E,"AddOutput",Fmt("%s %s,RunScriptCode,%s",O,S.self.GetName(),F),0.0,S.self,E)}else{local n=E.GetName();if(!n.len()){n=UniqueString();SetName(E,n)};AddEvent(E,"AddOutput",Fmt("%s %s,RunScriptCode,%s",O,n,F),0.0,null,E)}}function VS::CreateEntity(s,k=null,p=false):(Entities){local e=Entities.CreateByClassname(s);if(typeof k=="table")foreach(k,v in k)SetKeyValue(e,k,v);if(p)MakePersistent(e);return e}function VS::SetKeyValue(e,k,v){switch(typeof v){case"bool":case"integer":return e.__KeyValueFromInt(k,v.tointeger());case"float":return e.__KeyValueFromFloat(k,v);case"string":return e.__KeyValueFromString(k,v);case"Vector":return e.__KeyValueFromVector(k,v);case"null":return true;default:throw"Invalid input type: "+typeof v}}function VS::SetName(e,s)return e.__KeyValueFromString("targetname",""+s);function VS::DumpEnt(I=null):(Entities,Fmt){if(!I){local e;while(e=Entities.Next(e)){local s=e.GetScriptScope();if(s)::Msg(Fmt("%s :: %s\n",""+e,s.__vname))}return};if(typeof I=="string"){local e;while(e=Entities.Next(e))if(""+e==I)I=e};if(typeof I=="instance"){if(I.IsValid()){local s=I.GetScriptScope();if(s){::Msg(Fmt("--- Script dump for entity %s\n",""+I));DumpScope(s,0,1,0,1);::Msg("--- End script dump\n")}else return::Msg(Fmt("Entity has no script scope! %s\n",""+I))}else return::Msg("Invalid entity!\n")}else if(I){local e;while(e=Entities.Next(e)){local s=e.GetScriptScope();if(s){::Msg(Fmt("\n--- Script dump for entity %s\n",""+e));DumpScope(s,0,1,0,1);::Msg("--- End script dump\n")}}}}if(!PORTAL2){function VS::GetPlayersAndBots():(Entities){local e,P=[],B=[];while(e=Entities.FindByClassname(e,"cs_bot"))B.append(e.weakref());e=null;while(e=Entities.FindByClassname(e,"player")){local s=e.GetScriptScope();if("networkid"in s&&s.networkid=="BOT")B.append(e.weakref());else P.append(e.weakref())}return[P,B]}function VS::GetAllPlayers():(Entities){local e,a=[];while(e=Entities.FindByClassname(e,"player"))a.append(e.weakref());e=null;while(e=Entities.FindByClassname(e,"cs_bot"))a.append(e.weakref());return a}function VS::DumpPlayers(d=false):(Fmt){local a=GetPlayersAndBots(),p=a[0],b=a[1];::Msg(Fmt("\n=======================================\n%d players found\n%d bots found\n",p.len(),b.len()));local c=function(y,x):(d,Fmt){foreach(e in x){local s=e.GetScriptScope();if(s)s=GetVarName(s);if(!s)s="null";::Msg(Fmt("%s - %s :: %s\n",y,""+e,s));if(d&&s!="null")DumpEnt(e)}}c("[BOT]   ",b);c("[PLAYER]",p);::Msg("=======================================\n")}};if(PORTAL2){function VS::GetLocalPlayer(){local e;if(::IsMultiplayer())e=::Entc("player");else{e=::GetPlayer();if(e!=::player)::Msg("GetLocalPlayer: Discrepancy detected!\n")};SetName(e,"localplayer");return e}}else{function VS::GetLocalPlayer(b=true){if(GetPlayersAndBots()[0].len()>1)::Msg("GetLocalPlayer: More than 1 player detected!\n");local e=::Entc("player");if(!e)return::Msg("GetLocalPlayer: No player found!\n");if(e!=GetPlayerByIndex(1))::Msg("GetLocalPlayer: Discrepancy detected!\n");SetName(e,"localplayer");if(b)::HPlayer<-e.weakref();return e}function VS::GetPlayerByIndex(i):(Entities){local e;while(e=Entities.FindByClassname(e,"player"))if(e.entindex()==i)return e;e=null;while(e=Entities.FindByClassname(e,"cs_bot"))if(e.entindex()==i)return e}};function VS::GetEntityByIndex(i,s="*"):(Entities){local e;while(e=Entities.FindByClassname(e,s))if(e.entindex()==i)return e}function VS::IsPointSized(h){local v=h.GetBoundingMaxs();return !v.x&&!v.y&&!v.z}function VS::FindEntityNearestFacing(O,F,T):(Entities){local bd=T,be,e=Entities.First();while(e=Entities.Next(e)){local v=e.GetBoundingMaxs();if(!v.x&&!v.y&&!v.z)continue;local de=e.GetOrigin()-O;de.Norm();local d=F.Dot(de);if(d>bd){bd=d;be=e}}return be}function VS::FindEntityClassNearestFacing(O,F,T,C):(Entities){local bd=T,be,e;while(e=Entities.FindByClassname(e,C)){local de=e.GetOrigin()-O;de.Norm();local d=F.Dot(de);if(d>bd){bd=d;be=e}}return be}function VS::FindEntityClassNearestFacingNearest(O,F,T,C,R):(Entities){local X,be,e;if(R)X=R*R;else X=3.22122e+09;while(e=Entities.FindByClassname(e,C)){local de=e.GetOrigin()-O;de.Norm();local d=F.Dot(de);if(d>T){local q=(e.GetOrigin()-O).LengthSqr();if(X>q){be=e;X=q}}}return be}if(!PORTAL2&&EVENTS){VS.Events<-delegate VS:{m_hProxy=null,m_flValidateTime=0.0,m_SV=null}if(!("_xa9b2dfB7ffe"in ROOT))::_xa9b2dfB7ffe<-array(64);if(!("OnGameEvent_player_spawn"in ROOT))::OnGameEvent_player_spawn<-dummy;if(!("OnGameEvent_player_connect"in ROOT))::OnGameEvent_player_connect<-dummy};if(!PORTAL2){function VS::GetPlayerByUserid(userid):(Entities){local e;while(e=Entities.FindByClassname(e,"player")){local s=e.GetScriptScope();if("userid"in s&&s.userid==userid)return e}e=null;while(e=Entities.FindByClassname(e,"cs_bot")){local s=e.GetScriptScope();if("userid"in s&&s.userid==userid)return e}}if(EVENTS){local gE=::_xa9b2dfB7ffe,th=::FrameTime()*2,ct=Time;function VS::Events::player_connect(ev):(gE,ct,th,Fmt){if(ev.networkid!=""){local x;foreach(i,v in gE)if(!gE[i]){x=i;break};if(x==null){for(local i=32;i<64;++i){gE[i-32]=gE[i];gE[i]=null}x=0;::Msg("player_connect: ERROR!!! Player data is not being processed\n")};gE[x]=ev;return::OnGameEvent_player_connect(ev)}else if(m_SV){local dt=ct()-m_flValidateTime;if(dt<=th){m_SV.userid<-ev.userid;if(!("name"in m_SV))m_SV.name<-"";if(!("networkid"in m_SV))m_SV.networkid<-""}else::Msg(Fmt("player_connect: Unexpected error! %g (%d)\n",dt,(0.5+(dt/::FrameTime())).tointeger()));m_SV=null;m_flValidateTime=0.0;return}}function VS::Events::player_spawn(ev):(gE){foreach(i,d in gE){if(!d)break;else if(d.userid==ev.userid){local p=GetPlayerByIndex(d.index+1);if(!p||!p.ValidateScriptScope()){::Msg("player_connect: Invalid player entity\n");break};local s=p.GetScriptScope();if("networkid"in s){::Msg("player_connect: BUG!!! Something has gone wrong. ");if(s.networkid==d.networkid){gE[i]=null;::Msg("Duplicated data!\n")}else::Msg("Conflicting data!\n");break};if(d.networkid=="")::Msg("player_connect: could not get event data\n");s.userid<-d.userid;s.name<-d.name;s.networkid<-d.networkid;gE[i]=null;break}}return::OnGameEvent_player_spawn(ev)}function VS::ForceValidateUserid(e):(AddEvent,ct,Fmt){if(!e||!e.IsValid()||e.GetClassname()!="player")return::Msg(Fmt("ForceValidateUserid: Invalid input: %s\n",""+E));if(!Events.m_hProxy)Events.m_hProxy=CreateEntity("info_game_event_proxy",{event_name="player_connect"},true).weakref();Events.m_flValidateTime=ct();e.ValidateScriptScope();Events.m_SV=e.GetScriptScope();AddEvent(Events.m_hProxy,"GenerateGameEvent","",0,e,null)}function VS::ValidateUseridAll(b=false){local f=::FrameTime(),d=EventQueue.AddEvent,i=0;foreach(v in GetAllPlayers())if(!("userid"in v.GetScriptScope())||b)d(ForceValidateUserid,i++*f,[this,v])}VS.Events.ForceValidateUserid<-VS.ForceValidateUserid.weakref();VS.Events.ValidateUseridAll<-VS.ValidateUseridAll.weakref()}};VS.Log<-{enabled=false,export=false,file_prefix="vs.log",filter="L",L=[]}local L=::VS.Log.L;if(PORTAL2){function VS::Log::Run(){if(!enabled)return;return _Start()}}else{function VS::Log::Run(){if(::VS.IsDedicatedServer())::Msg("!!! VS.Log unavailable on dedicated servers\n");if(!enabled)return;return _Start()}};local M=::Msg,D=::VS.EventQueue.AddEvent,ft=::FrameTime(),V=::developer,Cmd=::SendToConsole,k=::clamp;function VS::Log::_Print():(M,L,D,k){local t=filter,p=M,L=L;if(!export)for(local i=nC;i<nN;++i)p(L[i]);else for(local i=nC;i<nN;++i)p(t+L[i]);nC+=nD;nN=k(nN+nD,0,nL);if(nC>=nN){if(export)_Stop();nL=null;nD=null;nC=null;nN=null;return};return D(_Print,0.0,this)}function VS::Log::_Start():(Cmd,V,k,Fmt,ft){nL<-L.len();nD<-2000;nC<-0;nN<-k(nD,0,nL);if(export){local f=file_prefix[0]==':'?file_prefix.slice(1):Fmt("%s_%s",file_prefix,::VS.UniqueString());_d<-V();Cmd(Fmt("developer 0;con_filter_enable 1;con_filter_text_out\"%s\";con_filter_text\"\";con_logfile\"%s.log\";script VS.EventQueue.AddEvent(VS.Log._Print,%g,VS.Log)",filter,f,(ft*4.0)));return f}else Cmd("script VS.Log._Print(0)")}function VS::Log::_Stop():(Cmd)Cmd("con_logfile\"\";con_filter_text_out\"\";con_filter_text\"\";con_filter_enable 0;developer "+_d);function VS::Log::Add(s):(L)L.append(s);function VS::Log::Clear():(L)L.clear()}.call(_);
