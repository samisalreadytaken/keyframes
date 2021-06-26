//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//-----------------------------------------------------------------------
if("VectorTransform"in VS)return;;const FLT_EPSILON=1.19209290E-07;;const FLT_MAX=1.E+37;;const FLT_MIN=1.E-37;;local vec3_origin=Vector();class::Quaternion{x=0.0;y=0.0;z=0.0;w=0.0;constructor(_x=0.0,_y=0.0,_z=0.0,_w=0.0){x=_x;y=_y;z=_z;w=_w}function IsValid(){return(x>-FLT_MAX&&x<FLT_MAX)&&(y>-FLT_MAX&&y<FLT_MAX)&&(z>-FLT_MAX&&z<FLT_MAX)&&(w>-FLT_MAX&&w<FLT_MAX)}}local Fmt=format;function Quaternion::_add(d):(Quaternion){return Quaternion(x+d.x,y+d.y,z+d.z,w+d.w)}function Quaternion::_sub(d):(Quaternion){return Quaternion(x-d.x,y-d.y,z-d.z,w-d.w)}function Quaternion::_mul(d):(Quaternion){return Quaternion(x*d,y*d,z*d,w*d)}function Quaternion::_div(d):(Quaternion){local f=1.0/d;return Quaternion(x*f,y*f,z*f,w*f)}function Quaternion::_unm():(Quaternion){return Quaternion(-x,-y,-z,-w)}function Quaternion::_typeof(){return"Quaternion"}function Quaternion::_tostring():(Fmt){return Fmt("Quaternion(%g, %g, %g, %g)",x,y,z,w)}class::matrix3x4_t{constructor(X=vec3_origin,Y=vec3_origin,Z=vec3_origin,T=vec3_origin){Init();m[0][0]=X.x;m[0][1]=Y.x;m[0][2]=Z.x;m[0][3]=T.x;m[1][0]=X.y;m[1][1]=Y.y;m[1][2]=Z.y;m[1][3]=T.y;m[2][0]=X.z;m[2][1]=Y.z;m[2][2]=Z.z;m[2][3]=T.z}function Init(){m=[[0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0]]}function _typeof(){return"matrix3x4_t"}m=null}function matrix3x4_t::_cloned(src){Init();::VS.MatrixCopy(src,this)}function matrix3x4_t::_tostring():(Fmt){local m=m;return Fmt("[ (%g, %g, %g), (%g, %g, %g), (%g, %g, %g), (%g, %g, %g) ]",m[0][0],m[0][1],m[0][2],m[1][0],m[1][1],m[1][2],m[2][0],m[2][1],m[2][2],m[0][3],m[1][3],m[2][3])}class::VMatrix extends matrix3x4_t{constructor(X=vec3_origin,Y=vec3_origin,Z=vec3_origin,T=vec3_origin){matrix3x4_t.constructor(X,Y,Z,T)}function Init(){matrix3x4_t.Init();m.resize(4);m[3]=[0.0,0.0,0.0,1.0]}function Identity(){m[0][0]=1.0;m[0][1]=0.0;m[0][2]=0.0;m[0][3]=0.0;m[1][0]=0.0;m[1][1]=1.0;m[1][2]=0.0;m[1][3]=0.0;m[2][0]=0.0;m[2][1]=0.0;m[2][2]=1.0;m[2][3]=0.0;m[3][0]=0.0;m[3][1]=0.0;m[3][2]=0.0;m[3][3]=1.0}function _typeof(){return"VMatrix"}}function VMatrix::_cloned(src){Init();::VS.MatrixCopy(src,this);src=src.m;m[3][0]=src[3][0];m[3][1]=src[3][1];m[3][2]=src[3][2];m[3][3]=src[3][3]}function VMatrix::_tostring():(Fmt){local m=m;return Fmt("[ (%g, %g, %g, %g), (%g, %g, %g, %g), (%g, %g, %g, %g), (%g, %g, %g, %g) ]",m[0][0],m[0][1],m[0][2],m[0][3],m[1][0],m[1][1],m[1][2],m[1][3],m[2][0],m[2][1],m[2][2],m[2][3],m[3][0],m[3][1],m[3][2],m[3][3])}local _VEC=Vector(),_QUAT=Quaternion(),VectorAdd=VS.VectorAdd,VectorSubtract=VS.VectorSubtract,Line=DebugDrawLine;function VS::InvRSquared(v):(max){return 1.0/max(1.0,v.LengthSqr())}function VS::a_swap(a1,i1,a2,i2){local t=a1[i1];a1[i1]=a2[i2];a2[i2]=t}local a_swap=VS.a_swap;function VS::MatrixRowDotProduct(in1,row,in2){in1=in1.m;return in1[row][0]*in2.x+in1[row][1]*in2.y+in1[row][2]*in2.z}function VS::MatrixColumnDotProduct(in1,col,in2){in1=in1.m;return in1[0][col]*in2.x+in1[1][col]*in2.y+in1[2][col]*in2.z}function VS::DotProductAbs(in1,in2):(fabs){return fabs(in1.x*in2.x)+fabs(in1.y*in2.y)+fabs(in1.z*in2.z)}function VS::VectorTransform(in1,in2,out=_VEC){in2=in2.m;local x=in1.x*in2[0][0]+in1.y*in2[0][1]+in1.z*in2[0][2]+in2[0][3],y=in1.x*in2[1][0]+in1.y*in2[1][1]+in1.z*in2[1][2]+in2[1][3],z=in1.x*in2[2][0]+in1.y*in2[2][1]+in1.z*in2[2][2]+in2[2][3];out.x=x;out.y=y;out.z=z;return out}function VS::VectorITransform(in1,in2,out=_VEC){in2=in2.m;local in1t0=in1.x-in2[0][3],in1t1=in1.y-in2[1][3],in1t2=in1.z-in2[2][3];local x=in1t0*in2[0][0]+in1t1*in2[1][0]+in1t2*in2[2][0],y=in1t0*in2[0][1]+in1t1*in2[1][1]+in1t2*in2[2][1],z=in1t0*in2[0][2]+in1t1*in2[1][2]+in1t2*in2[2][2];out.x=x;out.y=y;out.z=z;return out}local VectorITransform=VS.VectorITransform,VectorTransform=VS.VectorTransform;function VS::VectorRotate(in1,in2,out=_VEC){in2=in2.m;local x=in1.x*in2[0][0]+in1.y*in2[0][1]+in1.z*in2[0][2],y=in1.x*in2[1][0]+in1.y*in2[1][1]+in1.z*in2[1][2],z=in1.x*in2[2][0]+in1.y*in2[2][1]+in1.z*in2[2][2];out.x=x;out.y=y;out.z=z;return out}local VectorRotate=VS.VectorRotate;function VS::VectorRotate2(in1,in2,out=_VEC):(matrix3x4_t,VectorRotate){local mr=matrix3x4_t();AngleMatrix(in2,null,mr);VectorRotate(in1,mr,out);return out}function VS::VectorRotate3(in1,in2,out=_VEC):(Quaternion){local c=Quaternion();c.x=-in2.x;c.y=-in2.y;c.z=-in2.z;c.w=in2.w;local qv=Quaternion();qv.x=in2.y*in1.z-in2.z*in1.y+in2.w*in1.x;qv.y=-in2.x*in1.z+in2.z*in1.x+in2.w*in1.y;qv.z=in2.x*in1.y-in2.y*in1.x+in2.w*in1.z;qv.w=-in2.x*in1.x-in2.y*in1.y-in2.z*in1.z;out.x=qv.x*c.w+qv.y*c.z-qv.z*c.y+qv.w*c.x;out.y=-qv.x*c.z+qv.y*c.w+qv.z*c.x+qv.w*c.y;out.z=qv.x*c.y-qv.y*c.x+qv.z*c.w+qv.w*c.z;return out}function VS::VectorIRotate(in1,in2,out=_VEC){in2=in2.m;local x=in1.x*in2[0][0]+in1.y*in2[1][0]+in1.z*in2[2][0],y=in1.x*in2[0][1]+in1.y*in2[1][1]+in1.z*in2[2][1],z=in1.x*in2[0][2]+in1.y*in2[1][2]+in1.z*in2[2][2];out.x=x;out.y=y;out.z=z;return out}local VectorIRotate=VS.VectorIRotate,VectorVectors=VS.VectorVectors;function VS::VectorMatrix(f,mat):(Vector,VectorVectors){local r=Vector(),u=Vector();VectorVectors(f,r,u);mat=mat.m;mat[0][0]=f.x;mat[1][0]=f.y;mat[2][0]=f.z;mat[0][1]=-r.x;mat[1][1]=-r.y;mat[2][1]=-r.z;mat[0][2]=u.x;mat[1][2]=u.y;mat[2][2]=u.z}function VS::VectorMA(a,s,d,o=_VEC){o.x=a.x+s*d.x;o.y=a.y+s*d.y;o.z=a.z+s*d.z;return o}function VS::QuaternionsAreEqual(a,b,t=0.0):(fabs){return(fabs(a.x-b.x)<=t&&fabs(a.y-b.y)<=t&&fabs(a.z-b.z)<=t&&fabs(a.w-b.w)<=t)}function VS::QuaternionNormalize(q):(sqrt){local i,r=q.x*q.x+q.y*q.y+q.z*q.z+q.w*q.w;if(r){r=sqrt(r);i=1.0/r;q.w*=i;q.z*=i;q.y*=i;q.x*=i};return 0.0}function VS::QuaternionAlign(p,q,qt=_QUAT){local a=(p.x-q.x)*(p.x-q.x)+(p.y-q.y)*(p.y-q.y)+(p.z-q.z)*(p.z-q.z)+(p.w-q.w)*(p.w-q.w),b=(p.x+q.x)*(p.x+q.x)+(p.y+q.y)*(p.y+q.y)+(p.z+q.z)*(p.z+q.z)+(p.w+q.w)*(p.w+q.w);if(a>b){qt.x=-q.x;qt.y=-q.y;qt.z=-q.z;qt.w=-q.w}else if(qt!=q){qt.x=q.x;qt.y=q.y;qt.z=q.z;qt.w=q.w};;return qt}local QuaternionNormalize=VS.QuaternionNormalize;local QuaternionAlign=VS.QuaternionAlign;function VS::QuaternionMult(p,q,qt=_QUAT):(Quaternion,QuaternionAlign){if(p==qt){local p2=Quaternion(p.x,p.y,p.z,p.w);QuaternionMult(p2,q,qt);return qt};local q2=QuaternionAlign(p,q);qt.x=p.x*q2.w+p.y*q2.z-p.z*q2.y+p.w*q2.x;qt.y=-p.x*q2.z+p.y*q2.w+p.z*q2.x+p.w*q2.y;qt.z=p.x*q2.y-p.y*q2.x+p.z*q2.w+p.w*q2.z;qt.w=-p.x*q2.x-p.y*q2.y-p.z*q2.z+p.w*q2.w;return qt}local QuaternionMult=VS.QuaternionMult;function VS::QuaternionConjugate(p,q){q.x=-p.x;q.y=-p.y;q.z=-p.z;q.w=p.w}function VS::QuaternionMA(p,s,q,qt=_QUAT):(Quaternion,QuaternionNormalize,QuaternionMult){local q1=Quaternion();QuaternionScale(q,s,q1);local p1=QuaternionMult(p,q1);QuaternionNormalize(p1);qt.x=p1.x;qt.y=p1.y;qt.z=p1.z;qt.w=p1.w;return qt}function VS::QuaternionAdd(p,q,qt=_QUAT):(Quaternion,QuaternionAlign){local q2=QuaternionAlign(p,q);qt.x=p.x+q2.x;qt.y=p.y+q2.y;qt.z=p.z+q2.z;qt.w=p.w+q2.w;return qt}function VS::QuaternionDotProduct(p,q){return p.x*q.x+p.y*q.y+p.z*q.z+p.w*q.w}function VS::QuaternionInvert(p,q){q.x=-p.x;q.y=-p.y;q.z=-p.z;q.w=p.w;local sq=p.x*p.x+p.y*p.y+p.z*p.z+p.w*p.w;if(sq){local inv=1.0/sq;q.x*=inv;q.y*=inv;q.z*=inv;q.w*=inv;return};Assert(sq)}function VS::QuaternionBlendNoAlign(p,q,t,qt=_QUAT):(QuaternionNormalize){local sclp=1.0-t,sclq=t;qt.x=sclp*p.x+sclq*q.x;qt.y=sclp*p.y+sclq*q.y;qt.z=sclp*p.z+sclq*q.z;qt.w=sclp*p.w+sclq*q.w;QuaternionNormalize(qt);return qt}local QuaternionBlendNoAlign=VS.QuaternionBlendNoAlign;function VS::QuaternionBlend(p,q,t,qt=_QUAT):(Quaternion,QuaternionAlign){local q2=QuaternionAlign(p,q);QuaternionBlendNoAlign(p,q2,t,qt);return qt}function VS::QuaternionIdentityBlend(p,t,qt=_QUAT):(QuaternionNormalize){local sclp=1.0-t;qt.x=p.x*sclp;qt.y=p.y*sclp;qt.z=p.z*sclp;if(qt.w<0.0){qt.w=p.w*sclp-t}else{qt.w=p.w*sclp+t};QuaternionNormalize(qt);return qt}function VS::QuaternionSlerpNoAlign(p,q,t,qt=_QUAT):(sin,acos){local sp,sq,co=p.x*q.x+p.y*q.y+p.z*q.z+p.w*q.w;if(co>-0.999999){if(co<0.999999){local o=acos(co);local s=1.0/sin(o);sp=sin((1.0-t)*o)*s;sq=sin(t*o)*s}else{sp=1.0-t;sq=t};qt.x=sp*p.x+sq*q.x;qt.y=sp*p.y+sq*q.y;qt.z=sp*p.z+sq*q.z;qt.w=sp*p.w+sq*q.w}else{sp=sin((1.0-t)*1.5708);sq=sin(t*1.5708);qt.x=sp*p.x-sq*q.y;qt.y=sp*p.y+sq*q.x;qt.z=sp*p.z-sq*q.w;qt.w=sp*p.w+sq*q.z};return qt}local QuaternionSlerpNoAlign=VS.QuaternionSlerpNoAlign;function VS::QuaternionSlerp(p,q,t,qt=_QUAT):(Quaternion,QuaternionAlign,QuaternionSlerpNoAlign){local q2=QuaternionAlign(p,q);QuaternionSlerpNoAlign(p,q2,t,qt);return qt}function VS::QuaternionExp(p,q):(sqrt,sin,cos){local t=sqrt(p.x*q.x+p.y*q.y+p.z*q.z),c=cos(t);if(t>1.192092896e-7){local s=sin(t);local S=s/t;q.x=S*p.x;q.y=S*p.y;q.z=S*p.z}else{q.x=p.x;q.y=p.y;q.z=p.z};q.w=c}function VS::QuaternionLn(p,q):(acos,sin){if(p.w>0.99999||p.w<(-0.99999)){local T=acos(p.w);local S=T/sin(T);q.x=S*p.x;q.y=S*p.y;q.z=S*p.z}else{q.x=p.x;q.y=p.y;q.z=p.z};q.w=0.0}function VS::QuaternionSquad(Q0,Q1,Q2,Q3,T,out):(Quaternion){local aQ12x=Q1.x+Q2.x;local aQ12y=Q1.y+Q2.y;local aQ12z=Q1.z+Q2.z;local aQ12w=Q1.w+Q2.w;local LS12=aQ12x*aQ12x+aQ12y*aQ12y+aQ12z*aQ12z+aQ12w*aQ12w;local sQ12x=Q1.x-Q2.x;local sQ12y=Q1.y-Q2.y;local sQ12z=Q1.z-Q2.z;local sQ12w=Q1.w-Q2.w;local LD12=sQ12x*sQ12x+sQ12y*sQ12y+sQ12z*sQ12z+sQ12w*sQ12w;local SQ2;if(LS12<LD12){SQ2=Quaternion(-Q2.x,-Q2.y,-Q2.z,-Q2.w)}else{SQ2=Q2};local aQ01x=Q0.x+Q1.x;local aQ01y=Q0.y+Q1.y;local aQ01z=Q0.z+Q1.z;local aQ01w=Q0.w+Q1.w;local LS01=aQ01x*aQ01x+aQ01y*aQ01y+aQ01z*aQ01z+aQ01w*aQ01w;local sQ01x=Q0.x-Q1.x;local sQ01y=Q0.y-Q1.y;local sQ01z=Q0.z-Q1.z;local sQ01w=Q0.w-Q1.w;local LD01=sQ01x*sQ01x+sQ01y*sQ01y+sQ01z*sQ01z+sQ01w*sQ01w;local SQ0;if(LS01<LD01){SQ0=Quaternion(-Q0.x,-Q0.y,-Q0.z,-Q0.w)}else{SQ0=Q0};local aQ23x=Q2.x+Q3.x;local aQ23y=Q2.y+Q3.y;local aQ23z=Q2.z+Q3.z;local aQ23w=Q2.w+Q3.w;local LS23=aQ23x*aQ23x+aQ23y*aQ23y+aQ23z*aQ23z+aQ23w*aQ23w;local sQ23x=Q2.x-Q3.x;local sQ23y=Q2.y-Q3.y;local sQ23z=Q2.z-Q3.z;local sQ23w=Q2.w-Q3.w;local LD23=sQ23x*sQ23x+sQ23y*sQ23y+sQ23z*sQ23z+sQ23w*sQ23w;local SQ3;if(LS23<LD23){SQ3=Quaternion(-Q3.x,-Q3.y,-Q3.z,-Q3.w)}else{SQ3=Q3};local InvQ1=Quaternion();QuaternionInvert(Q1,InvQ1);local InvQ2=Quaternion();QuaternionInvert(Q2,InvQ2);local LnQ0=Quaternion();LnQ0.x=InvQ1.x*SQ0.w+InvQ1.y*SQ0.z-InvQ1.z*SQ0.y+InvQ1.w*SQ0.x;LnQ0.y=-InvQ1.x*SQ0.z+InvQ1.y*SQ0.w+InvQ1.z*SQ0.x+InvQ1.w*SQ0.y;LnQ0.z=InvQ1.x*SQ0.y-InvQ1.y*SQ0.x+InvQ1.z*SQ0.w+InvQ1.w*SQ0.z;LnQ0.w=-InvQ1.x*SQ0.x-InvQ1.y*SQ0.y-InvQ1.z*SQ0.z+InvQ1.w*SQ0.w;QuaternionLn(LnQ0,LnQ0);local LnQ2=Quaternion();LnQ2.x=InvQ1.x*SQ2.w+InvQ1.y*SQ2.z-InvQ1.z*SQ2.y+InvQ1.w*SQ2.x;LnQ2.y=-InvQ1.x*SQ2.z+InvQ1.y*SQ2.w+InvQ1.z*SQ2.x+InvQ1.w*SQ2.y;LnQ2.z=InvQ1.x*SQ2.y-InvQ1.y*SQ2.x+InvQ1.z*SQ2.w+InvQ1.w*SQ2.z;LnQ2.w=-InvQ1.x*SQ2.x-InvQ1.y*SQ2.y-InvQ1.z*SQ2.z+InvQ1.w*SQ2.w;QuaternionLn(LnQ2,LnQ2);local LnQ1=Quaternion();LnQ1.x=InvQ2.x*Q1.w+InvQ2.y*Q1.z-InvQ2.z*Q1.y+InvQ2.w*Q1.x;LnQ1.y=-InvQ2.x*Q1.z+InvQ2.y*Q1.w+InvQ2.z*Q1.x+InvQ2.w*Q1.y;LnQ1.z=InvQ2.x*Q1.y-InvQ2.y*Q1.x+InvQ2.z*Q1.w+InvQ2.w*Q1.z;LnQ1.w=-InvQ2.x*Q1.x-InvQ2.y*Q1.y-InvQ2.z*Q1.z+InvQ2.w*Q1.w;QuaternionLn(LnQ1,LnQ1);local LnQ3=Quaternion();LnQ3.x=InvQ2.x*SQ3.w+InvQ2.y*SQ3.z-InvQ2.z*SQ3.y+InvQ2.w*SQ3.x;LnQ3.y=-InvQ2.x*SQ3.z+InvQ2.y*SQ3.w+InvQ2.z*SQ3.x+InvQ2.w*SQ3.y;LnQ3.z=InvQ2.x*SQ3.y-InvQ2.y*SQ3.x+InvQ2.z*SQ3.w+InvQ2.w*SQ3.z;LnQ3.w=-InvQ2.x*SQ3.x-InvQ2.y*SQ3.y-InvQ2.z*SQ3.z+InvQ2.w*SQ3.w;QuaternionLn(LnQ3,LnQ3);local ExpQ02=Quaternion();ExpQ02.x=-0.25*(LnQ0.x+LnQ2.x);ExpQ02.y=-0.25*(LnQ0.y+LnQ2.y);ExpQ02.z=-0.25*(LnQ0.z+LnQ2.z);ExpQ02.w=-0.25*(LnQ0.w+LnQ2.w);QuaternionExp(ExpQ02,ExpQ02);local ExpQ13=Quaternion();ExpQ13.x=-0.25*(LnQ1.x+LnQ3.x);ExpQ13.y=-0.25*(LnQ1.y+LnQ3.y);ExpQ13.z=-0.25*(LnQ1.z+LnQ3.z);ExpQ13.w=-0.25*(LnQ1.w+LnQ3.w);QuaternionExp(ExpQ13,ExpQ13);local pA=Quaternion();pA.x=Q1.x*ExpQ02.w+Q1.y*ExpQ02.z-Q1.z*ExpQ02.y+Q1.w*ExpQ02.x;pA.y=-Q1.x*ExpQ02.z+Q1.y*ExpQ02.w+Q1.z*ExpQ02.x+Q1.w*ExpQ02.y;pA.z=Q1.x*ExpQ02.y-Q1.y*ExpQ02.x+Q1.z*ExpQ02.w+Q1.w*ExpQ02.z;pA.w=-Q1.x*ExpQ02.x-Q1.y*ExpQ02.y-Q1.z*ExpQ02.z+Q1.w*ExpQ02.w;local pB=Quaternion();pB.x=SQ2.x*ExpQ13.w+SQ2.y*ExpQ13.z-SQ2.z*ExpQ13.y+SQ2.w*ExpQ13.x;pB.y=-SQ2.x*ExpQ13.z+SQ2.y*ExpQ13.w+SQ2.z*ExpQ13.x+SQ2.w*ExpQ13.y;pB.z=SQ2.x*ExpQ13.y-SQ2.y*ExpQ13.x+SQ2.z*ExpQ13.w+SQ2.w*ExpQ13.z;pB.w=-SQ2.x*ExpQ13.x-SQ2.y*ExpQ13.y-SQ2.z*ExpQ13.z+SQ2.w*ExpQ13.w;local pC=SQ2;local Q0=Q1;local Q1=pA;local Q2=pB;local Q3=pC;local Q03=Quaternion();QuaternionSlerpNoAlign(Q0,Q3,T,Q03);local Q12=Quaternion();QuaternionSlerpNoAlign(Q1,Q2,T,Q12);T=(T-T*T)*2.0;QuaternionSlerpNoAlign(Q03,Q12,T,out)}function VS::QuaternionAverageExponential(q,c,S):(Quaternion){local st=S[0];if(c==1){q.x=st.x;q.y=st.y;q.z=st.z;q.w=st.w;return};local w=1.0/c,sum=Quaternion(),tmp=Quaternion();for(local i=0;i<c;++i){QuaternionAlign(st,S[i],tmp);QuaternionLn(tmp,tmp);sum.x+=tmp.x*w;sum.y+=tmp.y*w;sum.z+=tmp.z*w;sum.w+=tmp.w*w}QuaternionExp(sum,q)}function VS::QuaternionAngleDiff(p,q):(Quaternion,QuaternionMult,min,sqrt,asin){local i=Quaternion(),d=Quaternion();i.x=-q.x;i.y=-q.y;i.z=-q.z;i.w=q.w;QuaternionMult(p,i,d);local sa=min(1.0,sqrt(d.x*d.x+d.y*d.y+d.z*d.z));local ang=asin(sa)*114.591559026;return ang}function VS::QuaternionScale(p,t,q):(Vector,min,sqrt,sin,asin){local r;local qv=Vector(p.x,p.y,p.z);local s=sqrt(qv.Dot(qv));s=min(s,1.0);local ss=sin(asin(s)*t);t=ss/(s+FLT_EPSILON);VectorScale(qv,t,q);r=1.0-ss*ss;if(r<0.0)r=0.0;r=sqrt(r);if(p.w<0)q.w=-r;else q.w=r}function VS::RotationDeltaAxisAngle(sa,da,dx,dr):(Quaternion){local sq=Quaternion(),dq=Quaternion(),si=Quaternion(),o=Quaternion();AngleQuaternion(sa,sq);AngleQuaternion(da,dq);QuaternionScale(sq,-1,si);QuaternionMult(dq,si,o);QuaternionNormalize(o);QuaternionAxisAngle(o,dx,dr)}function VS::RotationDelta(s,d,o):(matrix3x4_t,Vector){local ms=matrix3x4_t(),mi=matrix3x4_t(),md=matrix3x4_t(),mx=matrix3x4_t();AngleMatrix(s,null,ms);AngleMatrix(d,null,md);MatrixInvert(ms,mi);ConcatTransforms(md,mi,mx);MatrixAngles(md,o)}function VS::MatrixAngles(mx,ang=_VEC,pos=null):(sqrt,atan2){mx=mx.m;if(pos){pos.x=mx[0][3];pos.y=mx[1][3];pos.z=mx[2][3]};local f0=mx[0][0];local f1=mx[1][0];local f2=mx[2][0];local left0=mx[0][1];local left1=mx[1][1];local left2=mx[2][1];local up0=null;local up1=null;local up2=mx[2][2];local xyDist=sqrt(f0*f0+f1*f1);if(xyDist>0.001){ang.y=57.29577951*atan2(f1,f0);ang.x=57.29577951*atan2(-f2,xyDist);ang.z=57.29577951*atan2(left2,up2)}else{ang.y=57.29577951*atan2(-left0,left1);ang.x=57.29577951*atan2(-f2,xyDist);ang.z=0};return ang}function VS::MatrixQuaternionFast(m,q):(sqrt){m=m.m;local t;if(m[2][2]<0.0){if(m[0][0]>m[1][1]){t=1.0+m[0][0]-m[1][1]-m[2][2];q.x=t;q.y=m[0][1]+m[1][0];q.z=m[0][2]+m[2][0];q.w=m[2][1]-m[1][2]}else{t=1.0-m[0][0]+m[1][1]-m[2][2];q.x=m[0][1]+m[1][0];q.y=t;q.z=m[2][1]+m[1][2];q.w=m[0][2]-m[2][0]}}else{if(m[0][0]<(-m[1][1])){t=1.0-m[0][0]-m[1][1]+m[2][2];q.x=m[0][2]+m[2][0];q.y=m[2][1]+m[1][2];q.z=t;q.w=m[1][0]-m[0][1]}else{t=1.0+m[0][0]+m[1][1]+m[2][2];q.x=m[2][1]-m[1][2];q.y=m[0][2]-m[2][0];q.z=m[1][0]-m[0][1];q.w=t}};local f=0.5/sqrt(t);q.x*=f;q.y*=f;q.z*=f;q.w*=f}local MatrixAngles=VS.MatrixAngles,MatrixQuaternionFast=VS.MatrixQuaternionFast;function VS::QuaternionMatrix(q,pos,mx){mx=mx.m;mx[0][0]=1.0-2.0*q.y*q.y-2.0*q.z*q.z;mx[1][0]=2.0*q.x*q.y+2.0*q.w*q.z;mx[2][0]=2.0*q.x*q.z-2.0*q.w*q.y;mx[0][1]=2.0*q.x*q.y-2.0*q.w*q.z;mx[1][1]=1.0-2.0*q.x*q.x-2.0*q.z*q.z;mx[2][1]=2.0*q.y*q.z+2.0*q.w*q.x;mx[0][2]=2.0*q.x*q.z+2.0*q.w*q.y;mx[1][2]=2.0*q.y*q.z-2.0*q.w*q.x;mx[2][2]=1.0-2.0*q.x*q.x-2.0*q.y*q.y;mx[0][3]=0.0;mx[1][3]=0.0;mx[2][3]=0.0;if(pos){mx[0][3]=pos.x;mx[1][3]=pos.y;mx[2][3]=pos.z}}function VS::QuaternionAngles2(q,ang=_VEC):(asin,atan2){local m11=(2.0*q.w*q.w)+(2.0*q.x*q.x)-1.0,m12=(2.0*q.x*q.y)+(2.0*q.w*q.z),m13=(2.0*q.x*q.z)-(2.0*q.w*q.y),m23=(2.0*q.y*q.z)+(2.0*q.w*q.x),m33=(2.0*q.w*q.w)+(2.0*q.z*q.z)-1.0;ang.y=57.29577951*atan2(m12,m11);ang.x=57.29577951*asin(-m13);ang.z=57.29577951*atan2(m23,m33);return ang}local QuaternionMatrix=VS.QuaternionMatrix;function VS::QuaternionAngles(q,ang=_VEC):(matrix3x4_t,QuaternionMatrix,MatrixAngles){local mx=matrix3x4_t();QuaternionMatrix(q,null,mx);MatrixAngles(mx,ang);return ang}function VS::QuaternionAxisAngle(q,axis):(acos){local ang=acos(q.w)*114.591559026;if(ang>180.0)ang-=360.0;axis.x=q.x;axis.y=q.y;axis.z=q.z;axis.Norm();return ang}function VS::AxisAngleQuaternion(axis,ang,q=_QUAT):(sin,cos){ang=ang*0.008726645;local sa=sin(ang),ca=cos(ang);q.x=axis.x*sa;q.y=axis.y*sa;q.z=axis.z*sa;q.w=ca;return q}function VS::AngleQuaternion(ang,out=_QUAT):(sin,cos){local ay=ang.y*0.008726645,ax=ang.x*0.008726645,az=ang.z*0.008726645;local sy=sin(ay),cy=cos(ay),sp=sin(ax),cp=cos(ax),sr=sin(az),cr=cos(az);local srXcp=sr*cp,crXsp=cr*sp;out.x=srXcp*cy-crXsp*sy;out.y=crXsp*cy+srXcp*sy;local crXcp=cr*cp,srXsp=sr*sp;out.z=crXcp*sy-srXsp*cy;out.w=crXcp*cy+srXsp*sy;return out}local AngleQuaternion=VS.AngleQuaternion;function VS::MatrixQuaternion(mat,q=_QUAT):(AngleQuaternion,MatrixAngles){local ang=MatrixAngles(mat);AngleQuaternion(ang,q);return q}function VS::BasisToQuaternion(vF,vR,vU,q=_QUAT):(matrix3x4_t,fabs,MatrixQuaternionFast){Assert(fabs(vF.LengthSqr()-1.0)<1.e-3);Assert(fabs(vR.LengthSqr()-1.0)<1.e-3);Assert(fabs(vU.LengthSqr()-1.0)<1.e-3);local vecLeft=vR*-1.0;local mat=matrix3x4_t(vF,vecLeft,vU);MatrixQuaternionFast(mat,q);return q}function VS::AngleMatrix(ang,pos,mx):(sin,cos){local ay=0.01745329*ang.y,ax=0.01745329*ang.x,az=0.01745329*ang.z;local sy=sin(ay),cy=cos(ay),sp=sin(ax),cp=cos(ax),sr=sin(az),cr=cos(az);mx=mx.m;mx[0][0]=cp*cy;mx[1][0]=cp*sy;mx[2][0]=-sp;local crcy=cr*cy,crsy=cr*sy,srcy=sr*cy,srsy=sr*sy;mx[0][1]=sp*srcy-crsy;mx[1][1]=sp*srsy+crcy;mx[2][1]=sr*cp;mx[0][2]=(sp*crcy+srsy);mx[1][2]=(sp*crsy-srcy);mx[2][2]=cr*cp;mx[0][3]=0.0;mx[1][3]=0.0;mx[2][3]=0.0;if(pos){mx[0][3]=pos.x;mx[1][3]=pos.y;mx[2][3]=pos.z}}function VS::AngleIMatrix(ang,pos,mx):(sin,cos,VectorRotate){local ay=0.01745329*ang.y,ax=0.01745329*ang.x,az=0.01745329*ang.z;local sy=sin(ay),cy=cos(ay),sp=sin(ax),cp=cos(ax),sr=sin(az),cr=cos(az);mx=mx.m;mx[0][0]=cp*cy;mx[0][1]=cp*sy;mx[0][2]=-sp;mx[1][0]=sr*sp*cy+cr*-sy;mx[1][1]=sr*sp*sy+cr*cy;mx[1][2]=sr*cp;mx[2][0]=(cr*sp*cy+-sr*-sy);mx[2][1]=(cr*sp*sy+-sr*cy);mx[2][2]=cr*cp;mx[0][3]=0.0;mx[1][3]=0.0;mx[2][3]=0.0;if(pos){local vt=VectorRotate(pos,mx)*-1.0;mx[0][3]=vt.x;mx[1][3]=vt.y;mx[2][3]=vt.z}}local AngleMatrix=VS.AngleMatrix,AngleIMatrix=VS.AngleIMatrix;function VS::MatrixVectors(mx,vF,vR,vU){mx=mx.m;vF.x=mx[0][0];vF.y=mx[1][0];vF.z=mx[2][0];vR.x=mx[0][1];vR.y=mx[1][1];vR.z=mx[2][1];vU.x=mx[0][2];vU.y=mx[1][2];vU.z=mx[2][2];vR.x*=-1.0;vR.y*=-1.0;vR.z*=-1.0}function VS::MatricesAreEqual(src1,src2,flTolerance):(fabs){src1=src1.m;src2=src2.m;for(local i=0;i<3;++i){for(local j=0;j<4;++j){if(fabs(src1[i][j]-src2[i][j])>flTolerance)return false}}return true}function VS::MatrixCopy(s,d){s=s.m;d=d.m;d[0][0]=s[0][0];d[0][1]=s[0][1];d[0][2]=s[0][2];d[0][3]=s[0][3];d[1][0]=s[1][0];d[1][1]=s[1][1];d[1][2]=s[1][2];d[1][3]=s[1][3];d[2][0]=s[2][0];d[2][1]=s[2][1];d[2][2]=s[2][2];d[2][3]=s[2][3]}function VS::MatrixInvert(in1,out):(a_swap){in1=in1.m;out=out.m;if(in1==out){a_swap(out[0],1,out[1],0);a_swap(out[0],2,out[2],0);a_swap(out[1],2,out[2],1)}else{out[0][0]=in1[0][0];out[0][1]=in1[1][0];out[0][2]=in1[2][0];out[1][0]=in1[0][1];out[1][1]=in1[1][1];out[1][2]=in1[2][1];out[2][0]=in1[0][2];out[2][1]=in1[1][2];out[2][2]=in1[2][2]};local tmp0=in1[0][3],tmp1=in1[1][3],tmp2=in1[2][3];out[0][3]=-(tmp0*out[0][0]+tmp1*out[0][1]+tmp2*out[0][2]);out[1][3]=-(tmp0*out[1][0]+tmp1*out[1][1]+tmp2*out[1][2]);out[2][3]=-(tmp0*out[2][0]+tmp1*out[2][1]+tmp2*out[2][2])}function VS::MatrixInverseGeneral(src,dst):(array,fabs){local iRow,i,j,iTemp,iTest,mul,fTest,fLargest,mat=array(4),rowMap=array(4,0),iLT,pOut,pRow,pSR;for(local i=4;i--;)mat[i]=array(8,0.0);src=src.m;for(i=0;i<4;i++){local pIn=src[i];pOut=mat[i];pOut[0]=pIn[0];pOut[1]=pIn[1];pOut[2]=pIn[2];pOut[3]=pIn[3];pOut[4]=0.0;pOut[5]=0.0;pOut[6]=0.0;pOut[7]=0.0;pOut[i+4]=1.0;rowMap[i]=i}for(iRow=0;iRow<4;iRow++){fLargest=0.00001;iLT=-1;for(iTest=iRow;iTest<4;iTest++){fTest=fabs(mat[rowMap[iTest]][iRow]);if(fTest>fLargest){iLT=iTest;fLargest=fTest}}if(iLT==-1)return false;iTemp=rowMap[iLT];rowMap[iLT]=rowMap[iRow];rowMap[iRow]=iTemp;pRow=mat[rowMap[iRow]];mul=1.0/pRow[iRow];pRow[0]*=mul;pRow[1]*=mul;pRow[2]*=mul;pRow[3]*=mul;pRow[4]*=mul;pRow[5]*=mul;pRow[6]*=mul;pRow[7]*=mul;pRow[iRow]=1.0;for(i=0;i<4;i++){if(i==iRow)continue;pSR=mat[rowMap[i]];mul=-pSR[iRow];pSR[0]+=pRow[0]*mul;pSR[1]+=pRow[1]*mul;pSR[2]+=pRow[2]*mul;pSR[3]+=pRow[3]*mul;pSR[4]+=pRow[4]*mul;pSR[5]+=pRow[5]*mul;pSR[6]+=pRow[6]*mul;pSR[7]+=pRow[7]*mul;pSR[iRow]=0.0}}dst=dst.m;for(i=0;i<4;i++){local pIn=mat[rowMap[i]];pOut=dst[i];pOut[0]=pIn[4];pOut[1]=pIn[5];pOut[2]=pIn[6];pOut[3]=pIn[7]}return true}function VS::MatrixInverseTR(src,dst){src=src.m;dst=dst.m;dst[0][0]=src[0][0];dst[0][1]=src[1][0];dst[0][2]=src[2][0];dst[1][0]=src[0][1];dst[1][1]=src[1][1];dst[1][2]=src[2][1];dst[2][0]=src[0][2];dst[2][1]=src[1][2];dst[2][2]=src[2][2];dst[0][3]=dst[0][0]*-src[0][3]-dst[0][1]*src[1][3]-dst[0][2]*src[2][3];dst[1][3]=dst[1][0]*-src[0][3]-dst[1][1]*src[1][3]-dst[1][2]*src[2][3];dst[2][3]=dst[2][0]*-src[0][3]-dst[2][1]*src[1][3]-dst[2][2]*src[2][3];dst[3][0]=dst[3][1]=dst[3][2]=0.0;dst[3][3]=1.0}function VS::MatrixGetColumn(in1,col,out=_VEC){in1=in1.m;out.x=in1[0][col];out.y=in1[1][col];out.z=in1[2][col];return out}function VS::MatrixSetColumn(in1,col,out){out=out.m;out[0][col]=in1.x;out[1][col]=in1.y;out[2][col]=in1.z}function VS::MatrixScaleBy(fl,out){out=out.m;out[0][0]*=fl;out[1][0]*=fl;out[2][0]*=fl;out[0][1]*=fl;out[1][1]*=fl;out[2][1]*=fl;out[0][2]*=fl;out[1][2]*=fl;out[2][2]*=fl}function VS::MatrixScaleByZero(out){out=out.m;out[0][0]=0.0;out[1][0]=0.0;out[2][0]=0.0;out[0][1]=0.0;out[1][1]=0.0;out[2][1]=0.0;out[0][2]=0.0;out[1][2]=0.0;out[2][2]=0.0}function VS::SetIdentityMatrix(mx){mx=mx.m;mx[0][0]=1.0;mx[0][1]=0.0;mx[0][2]=0.0;mx[0][3]=0.0;mx[1][0]=0.0;mx[1][1]=1.0;mx[1][2]=0.0;mx[1][3]=0.0;mx[2][0]=0.0;mx[2][1]=0.0;mx[2][2]=1.0;mx[2][3]=0.0}function VS::SetScaleMatrix(x,y,z,dst){dst=dst.m;dst[0][0]=x;dst[0][1]=0.0;dst[0][2]=0.0;dst[0][3]=0.0;dst[1][0]=0.0;dst[1][1]=y;dst[1][2]=0.0;dst[1][3]=0.0;dst[2][0]=0.0;dst[2][1]=0.0;dst[2][2]=z;dst[2][3]=0.0}function VS::ComputeCenterMatrix(ori,ang,mins,maxs,mx):(VectorRotate,AngleMatrix){local ctr=(mins+maxs)*0.5;AngleMatrix(ang,null,mx);local w=VectorRotate(ctr,mx)+ori;mx=mx.m;mx[0][3]=w.x;mx[1][3]=w.y;mx[2][3]=w.z}function VS::ComputeCenterIMatrix(ori,ang,mins,maxs,mx):(VectorRotate,AngleIMatrix){local ctr=(mins+maxs)*-0.5;AngleIMatrix(ang,null,mx);local lo=VectorRotate(ori,mx);ctr-=lo;mx=mx.m;mx[0][3]=ctr.x;mx[1][3]=ctr.y;mx[2][3]=ctr.z}function VS::ComputeAbsMatrix(in1,out):(fabs){in1=in1.m;out=out.m;out[0][0]=fabs(in1[0][0]);out[0][1]=fabs(in1[0][1]);out[0][2]=fabs(in1[0][2]);out[1][0]=fabs(in1[1][0]);out[1][1]=fabs(in1[1][1]);out[1][2]=fabs(in1[1][2]);out[2][0]=fabs(in1[2][0]);out[2][1]=fabs(in1[2][1]);out[2][2]=fabs(in1[2][2])}function VS::ConcatRotations(in1,in2,out){in1=in1.m;in2=in2.m;out=out.m;out[0][0]=in1[0][0]*in2[0][0]+in1[0][1]*in2[1][0]+in1[0][2]*in2[2][0];out[0][1]=in1[0][0]*in2[0][1]+in1[0][1]*in2[1][1]+in1[0][2]*in2[2][1];out[0][2]=in1[0][0]*in2[0][2]+in1[0][1]*in2[1][2]+in1[0][2]*in2[2][2];out[1][0]=in1[1][0]*in2[0][0]+in1[1][1]*in2[1][0]+in1[1][2]*in2[2][0];out[1][1]=in1[1][0]*in2[0][1]+in1[1][1]*in2[1][1]+in1[1][2]*in2[2][1];out[1][2]=in1[1][0]*in2[0][2]+in1[1][1]*in2[1][2]+in1[1][2]*in2[2][2];out[2][0]=in1[2][0]*in2[0][0]+in1[2][1]*in2[1][0]+in1[2][2]*in2[2][0];out[2][1]=in1[2][0]*in2[0][1]+in1[2][1]*in2[1][1]+in1[2][2]*in2[2][1];out[2][2]=in1[2][0]*in2[0][2]+in1[2][1]*in2[1][2]+in1[2][2]*in2[2][2]}function VS::ConcatTransforms(a,b,o){a=a.m;b=b.m;o=o.m;local m00=a[0][0]*b[0][0]+a[0][1]*b[1][0]+a[0][2]*b[2][0],m01=a[0][0]*b[0][1]+a[0][1]*b[1][1]+a[0][2]*b[2][1],m02=a[0][0]*b[0][2]+a[0][1]*b[1][2]+a[0][2]*b[2][2],m03=a[0][0]*b[0][3]+a[0][1]*b[1][3]+a[0][2]*b[2][3],m10=a[1][0]*b[0][0]+a[1][1]*b[1][0]+a[1][2]*b[2][0],m11=a[1][0]*b[0][1]+a[1][1]*b[1][1]+a[1][2]*b[2][1],m12=a[1][0]*b[0][2]+a[1][1]*b[1][2]+a[1][2]*b[2][2],m13=a[1][0]*b[0][3]+a[1][1]*b[1][3]+a[1][2]*b[2][3],m20=a[2][0]*b[0][0]+a[2][1]*b[1][0]+a[2][2]*b[2][0],m21=a[2][0]*b[0][1]+a[2][1]*b[1][1]+a[2][2]*b[2][1],m22=a[2][0]*b[0][2]+a[2][1]*b[1][2]+a[2][2]*b[2][2],m23=a[2][0]*b[0][3]+a[2][1]*b[1][3]+a[2][2]*b[2][3];o[0][0]=m00;o[0][1]=m01;o[0][2]=m02;o[0][3]=m03;o[1][0]=m10;o[1][1]=m11;o[1][2]=m12;o[1][3]=m13;o[2][0]=m20;o[2][1]=m21;o[2][2]=m22;o[2][3]=m23}function VS::MatrixMultiply(s1,s2,o){s1=s1.m;s2=s2.m;o=o.m;local m00=s1[0][0]*s2[0][0]+s1[0][1]*s2[1][0]+s1[0][2]*s2[2][0]+s1[0][3]*s2[3][0],m01=s1[0][0]*s2[0][1]+s1[0][1]*s2[1][1]+s1[0][2]*s2[2][1]+s1[0][3]*s2[3][1],m02=s1[0][0]*s2[0][2]+s1[0][1]*s2[1][2]+s1[0][2]*s2[2][2]+s1[0][3]*s2[3][2],m03=s1[0][0]*s2[0][3]+s1[0][1]*s2[1][3]+s1[0][2]*s2[2][3]+s1[0][3]*s2[3][3],m10=s1[1][0]*s2[0][0]+s1[1][1]*s2[1][0]+s1[1][2]*s2[2][0]+s1[1][3]*s2[3][0],m11=s1[1][0]*s2[0][1]+s1[1][1]*s2[1][1]+s1[1][2]*s2[2][1]+s1[1][3]*s2[3][1],m12=s1[1][0]*s2[0][2]+s1[1][1]*s2[1][2]+s1[1][2]*s2[2][2]+s1[1][3]*s2[3][2],m13=s1[1][0]*s2[0][3]+s1[1][1]*s2[1][3]+s1[1][2]*s2[2][3]+s1[1][3]*s2[3][3],m20=s1[2][0]*s2[0][0]+s1[2][1]*s2[1][0]+s1[2][2]*s2[2][0]+s1[2][3]*s2[3][0],m21=s1[2][0]*s2[0][1]+s1[2][1]*s2[1][1]+s1[2][2]*s2[2][1]+s1[2][3]*s2[3][1],m22=s1[2][0]*s2[0][2]+s1[2][1]*s2[1][2]+s1[2][2]*s2[2][2]+s1[2][3]*s2[3][2],m23=s1[2][0]*s2[0][3]+s1[2][1]*s2[1][3]+s1[2][2]*s2[2][3]+s1[2][3]*s2[3][3],m30=s1[3][0]*s2[0][0]+s1[3][1]*s2[1][0]+s1[3][2]*s2[2][0]+s1[3][3]*s2[3][0],m31=s1[3][0]*s2[0][1]+s1[3][1]*s2[1][1]+s1[3][2]*s2[2][1]+s1[3][3]*s2[3][1],m32=s1[3][0]*s2[0][2]+s1[3][1]*s2[1][2]+s1[3][2]*s2[2][2]+s1[3][3]*s2[3][2],m33=s1[3][0]*s2[0][3]+s1[3][1]*s2[1][3]+s1[3][2]*s2[2][3]+s1[3][3]*s2[3][3];o[0][0]=m00;o[0][1]=m01;o[0][2]=m02;o[0][3]=m03;o[1][0]=m10;o[1][1]=m11;o[1][2]=m12;o[1][3]=m13;o[2][0]=m20;o[2][1]=m21;o[2][2]=m22;o[2][3]=m23;o[3][0]=m30;o[3][1]=m31;o[3][2]=m32;o[3][3]=m33}function VS::MatrixBuildRotationAboutAxis(x,a,o):(sin,cos){local r=a*0.01745329;local s=sin(r),c=cos(r);local x2=x.x*x.x,y2=x.y*x.y,z2=x.z*x.z;o=o.m;o[0][0]=x2+(1.0-x2)*c;o[1][1]=y2+(1.0-y2)*c;o[2][2]=z2+(1.0-z2)*c;c=1.0-c;local xyc=x.x*x.y*c,yzc=x.y*x.z*c,xzc=x.z*x.x*c,xs=x.x*s,ys=x.y*s,zs=x.z*s;o[1][0]=xyc+zs;o[2][0]=xzc-ys;o[0][1]=xyc-zs;o[2][1]=yzc+xs;o[0][2]=xzc+ys;o[1][2]=yzc-xs;o[0][3]=o[1][3]=o[2][3]=0.0}function VS::MatrixBuildRotation(o,d0,d1):(Vector,fabs,acos){local a=d0.Dot(d1),x=Vector();if(a-1.0>-1.e-3){SetIdentityMatrix(o);return}else if(a+1.0<1.e-3){local idx="x";if(fabs(d1.y)<fabs(d1[idx]))idx="y";if(fabs(d1.z)<fabs(d1[idx]))idx="z";x[idx]=1.0;VectorMA(x,-(x.Dot(d1)),d1,x);x.Norm();a=180.0}else{x=d0.Cross(d1);x.Norm();a=acos(a)*57.29577951};;MatrixBuildRotationAboutAxis(x,a,o)}function VS::Vector3DMultiplyProjective(a,b,o){a=a.m;local i=1.0/(a[3][0]*b.x+a[3][1]*b.y+a[3][2]*b.z),x=i*(a[0][0]*b.x+a[0][1]*b.y+a[0][2]*b.z),y=i*(a[1][0]*b.x+a[1][1]*b.y+a[1][2]*b.z),z=i*(a[2][0]*b.x+a[2][1]*b.y+a[2][2]*b.z);o.x=x;o.y=y;o.z=z}function VS::Vector3DMultiplyPositionProjective(a,b,o){a=a.m;local i=1.0/(a[3][0]*b.x+a[3][1]*b.y+a[3][2]*b.z+a[3][3]),x=i*(a[0][0]*b.x+a[0][1]*b.y+a[0][2]*b.z+a[0][3]),y=i*(a[1][0]*b.x+a[1][1]*b.y+a[1][2]*b.z+a[1][3]),z=i*(a[2][0]*b.x+a[2][1]*b.y+a[2][2]*b.z+a[2][3]);o.x=x;o.y=y;o.z=z}function VS::TransformAABB(tr,vni,vxi,vno,vxo):(Vector,fabs,VectorAdd,VectorSubtract,VectorTransform){local lc=(vni+vxi)*0.5;local le=vxi-lc;local wc=VectorTransform(lc,tr);tr=tr.m;local we=Vector(fabs(le.x*tr[0][0])+fabs(le.y*tr[0][1])+fabs(le.z*tr[0][2]),fabs(le.x*tr[1][0])+fabs(le.y*tr[1][1])+fabs(le.z*tr[1][2]),fabs(le.x*tr[2][0])+fabs(le.y*tr[2][1])+fabs(le.z*tr[2][2]));VectorSubtract(wc,we,vno);VectorAdd(wc,we,vxo)}function VS::ITransformAABB(tr,vni,vxi,vno,vxo):(Vector,fabs,VectorAdd,VectorSubtract,VectorITransform){local wc=(vni+vxi)*0.5;local we=vxi-wc;local lc=VectorITransform(wc,tr);tr=tr.m;local le=Vector(fabs(we.x*tr[0][0])+fabs(we.y*tr[1][0])+fabs(we.z*tr[2][0]),fabs(we.x*tr[0][1])+fabs(we.y*tr[1][1])+fabs(we.z*tr[2][1]),fabs(we.x*tr[0][2])+fabs(we.y*tr[1][2])+fabs(we.z*tr[2][2]));VectorSubtract(lc,le,vno);VectorAdd(lc,le,vxo)}function VS::RotateAABB(tr,vni,vxi,vno,vxo):(Vector,fabs,VectorAdd,VectorSubtract,VectorRotate){local lc=(vni+vxi)*0.5;local le=vxi-lc;local nc=VectorRotate(lc,tr);tr=tr.m;local ne=Vector(fabs(le.x*tr[0][0])+fabs(le.y*tr[0][1])+fabs(le.z*tr[0][2]),fabs(le.x*tr[1][0])+fabs(le.y*tr[1][1])+fabs(le.z*tr[1][2]),fabs(le.x*tr[2][0])+fabs(le.y*tr[2][1])+fabs(le.z*tr[2][2]));VectorSubtract(nc,ne,vno);VectorAdd(nc,ne,vxo)}function VS::IRotateAABB(tr,vni,vxi,vno,vxo):(Vector,fabs,VectorAdd,VectorSubtract,VectorIRotate){local oc=(vni+vxi)*0.5;local oe=vxi-oc;local nc=VectorIRotate(oc,tr);tr=tr.m;local ne=Vector(fabs(oe.x*tr[0][0])+fabs(oe.y*tr[1][0])+fabs(oe.z*tr[2][0]),fabs(oe.x*tr[0][1])+fabs(oe.y*tr[1][1])+fabs(oe.z*tr[2][1]),fabs(oe.x*tr[0][2])+fabs(oe.y*tr[1][2])+fabs(oe.z*tr[2][2]));VectorSubtract(nc,ne,vno);VectorAdd(nc,ne,vxo)}function VS::GetBoxVertices(origin,angles,mins,maxs,pVerts):(matrix3x4_t,Vector,VectorAdd,VectorRotate){local v,r=matrix3x4_t();AngleMatrix(angles,null,r);v=pVerts[0];v.x=mins.x;v.y=mins.y;v.z=mins.z;VectorRotate(v,r,v);VectorAdd(v,origin,v);v=pVerts[1];v.x=maxs.x;v.y=mins.y;v.z=mins.z;VectorRotate(v,r,v);VectorAdd(v,origin,v);v=pVerts[2];v.x=mins.x;v.y=maxs.y;v.z=mins.z;VectorRotate(v,r,v);VectorAdd(v,origin,v);v=pVerts[3];v.x=maxs.x;v.y=maxs.y;v.z=mins.z;VectorRotate(v,r,v);VectorAdd(v,origin,v);v=pVerts[4];v.x=mins.x;v.y=mins.y;v.z=maxs.z;VectorRotate(v,r,v);VectorAdd(v,origin,v);v=pVerts[5];v.x=maxs.x;v.y=mins.y;v.z=maxs.z;VectorRotate(v,r,v);VectorAdd(v,origin,v);v=pVerts[6];v.x=mins.x;v.y=maxs.y;v.z=maxs.z;VectorRotate(v,r,v);VectorAdd(v,origin,v);v=pVerts[7];v.x=maxs.x;v.y=maxs.y;v.z=maxs.z;VectorRotate(v,r,v);VectorAdd(v,origin,v)}function VS::MatrixBuildPerspective(m,x,a,n,f):(tan){m=m.m;m[0][1]=m[0][3]=m[1][0]=m[1][3]=m[2][0]=m[2][1]=m[3][0]=m[3][1]=m[3][3]=0.0;local i=-0.5/tan(x*0.008726646),r=f/(n-f);m[0][0]=i;m[1][1]=i*a;m[0][2]=m[1][2]=0.5;m[2][2]=-r;m[3][2]=1.0;m[2][3]=n*r}function VS::ComputeViewMatrix(pWorldToView,origin,forward,left,up):(Vector,matrix3x4_t,VMatrix){local transform=matrix3x4_t();MatrixSetColumn(forward,0,transform);MatrixSetColumn(left,1,transform);MatrixSetColumn(up,2,transform);MatrixSetColumn(origin,3,transform);local matRotate=VMatrix();MatrixCopy(transform,matRotate);local matRotateZ=VMatrix();MatrixBuildRotationAboutAxis(Vector(0,0,1),-90,matRotateZ);MatrixMultiply(matRotate,matRotateZ,matRotate);local matRotateX=VMatrix();MatrixBuildRotationAboutAxis(Vector(1,0,0),90,matRotateX);MatrixMultiply(matRotate,matRotateX,matRotate);MatrixCopy(matRotate,transform);MatrixInvert(transform,transform);MatrixCopy(transform,pWorldToView)}function VS::ComputeCameraVariables(vecOrigin,pVecForward,pVecRight,pVecUp,mat){mat=mat.m;mat[0][0]=-pVecRight.x;mat[0][1]=-pVecRight.y;mat[0][2]=-pVecRight.z;mat[0][3]=pVecRight.Dot(vecOrigin);mat[1][0]=-pVecUp.x;mat[1][1]=-pVecUp.y;mat[1][2]=-pVecUp.z;mat[1][3]=pVecUp.Dot(vecOrigin);mat[2][0]=pVecForward.x;mat[2][1]=pVecForward.y;mat[2][2]=pVecForward.z;mat[2][3]=-pVecForward.Dot(vecOrigin);mat[3][0]=mat[3][1]=mat[3][2]=0.0;mat[3][3]=1.0}function VS::ScreenToWorld(x,y,origin,forward,right,up,fov,flAspect,zFar):(Vector,VMatrix){x+=0.25;y-=0.25;local vecScreen=Vector(2.0*x-1.0,1.0-2.0*y,1.0);local viewToProj=VMatrix();MatrixBuildPerspective(viewToProj,fov,flAspect,1.0,zFar);local worldToView=VMatrix();ComputeCameraVariables(origin,forward,right,up,worldToView);local worldToProj=viewToProj;MatrixMultiply(viewToProj,worldToView,worldToProj);local screenToWorld=worldToView;MatrixInverseGeneral(worldToProj,screenToWorld);local worldPos=Vector();Vector3DMultiplyPositionProjective(screenToWorld,vecScreen,worldPos);return worldPos}function VS::CalcFovY(flFovX,flAspect):(tan,atan){if(flFovX<1.0||flFovX>179.0)flFovX=90.0;local val=atan(tan(0.008726646*flFovX)/flAspect);val=114.591559026*val;return val}function VS::CalcFovX(flFovY,flAspect):(tan,atan){return 114.591559026*atan(tan(0.008726646*flFovY)*flAspect)}local iFD=function():(vec3_origin){local Line=DebugDrawLine,VMPP=VS.Vector3DMultiplyPositionProjective,MatrixInverseGeneral=VS.MatrixInverseGeneral,MatrixBuildPerspective=VS.MatrixBuildPerspective;local w0=Vector(),w1=Vector();local D=function(l0,l1,mat,r,g,b,z,t):(Vector,VMPP,Line,w0,w1){VMPP(mat,l0,w0);VMPP(mat,l1,w1);return Line(w0,w1,r,g,b,z,t)}local v000=vec3_origin,v001=Vector(0.0,0.0,1.0),v011=Vector(0.0,1.0,1.0),v010=Vector(0.0,1.0,0.0),v010=Vector(0.0,1.0,0.0),v100=Vector(1.0,0.0,0.0),v101=Vector(1.0,0.0,1.0),v111=Vector(1.0,1.0,1.0),v110=Vector(1.0,1.0,0.0),fr=[v000,v001,v001,v011,v011,v010,v010,v000,v100,v101,v101,v111,v111,v110,v110,v100,v000,v100,v001,v101,v011,v111,v010,v110],v2w=VMatrix();function VS::DrawFrustum(w2v,r,g,b,z,t):(MatrixInverseGeneral,D,fr,v2w){MatrixInverseGeneral(w2v,v2w);D(fr[0],fr[1],v2w,r,g,b,z,t);D(fr[2],fr[3],v2w,r,g,b,z,t);D(fr[4],fr[5],v2w,r,g,b,z,t);D(fr[6],fr[7],v2w,r,g,b,z,t);D(fr[8],fr[9],v2w,r,g,b,z,t);D(fr[10],fr[11],v2w,r,g,b,z,t);D(fr[12],fr[13],v2w,r,g,b,z,t);D(fr[14],fr[15],v2w,r,g,b,z,t);D(fr[16],fr[17],v2w,r,g,b,z,t);D(fr[18],fr[19],v2w,r,g,b,z,t);D(fr[20],fr[21],v2w,r,g,b,z,t);D(fr[22],fr[23],v2w,r,g,b,z,t)}local DrawFrustum=VS.DrawFrustum;function VS::DrawViewFrustum(vecOrigin,vecForward,vecRight,vecUp,flFovX,flAspect,zNear,zFar,r,g,b,z,t):(VMatrix,MatrixBuildPerspective,ComputeCameraVariables,MatrixMultiply,DrawFrustum){local mat=VMatrix();MatrixBuildPerspective(mat,flFovX,flAspect,zNear,zFar);local matInvCam=VMatrix();ComputeCameraVariables(vecOrigin,vecForward,vecRight,vecUp,matInvCam);MatrixMultiply(mat,matInvCam,mat);return DrawFrustum(mat,r,g,b,z,t)}}function VS::DrawFrustum(m,r,g,b,z,t):(iFD){iFD();return DrawFrustum(m,r,g,b,z,t)}function VS::DrawViewFrustum(vecOrigin,vecForward,vecRight,vecUp,flFovX,flAspect,zNear,zFar,r,g,b,z,t):(iFD){iFD();return DrawViewFrustum(vecOrigin,vecForward,vecRight,vecUp,flFovX,flAspect,zNear,zFar,r,g,b,z,t)}local iBD=function():(vec3_origin){local Box=DebugDrawBox,Line=DebugDrawLine,GetBoxVertices=VS.GetBoxVertices,VT=[Vector(),Vector(),Vector(),Vector(),Vector(),Vector(),Vector(),Vector()];function VS::DrawBoxAngles(origin,mins,maxs,angles,r,g,b,z,t):(VT,GetBoxVertices,Line){GetBoxVertices(origin,angles,mins,maxs,VT);local v0=VT[0],v1=VT[1],v2=VT[2],v3=VT[3],v4=VT[4],v5=VT[5],v6=VT[6],v7=VT[7];Line(v0,v1,r,g,b,z,t);Line(v0,v2,r,g,b,z,t);Line(v1,v3,r,g,b,z,t);Line(v2,v3,r,g,b,z,t);Line(v0,v4,r,g,b,z,t);Line(v1,v5,r,g,b,z,t);Line(v2,v6,r,g,b,z,t);Line(v3,v7,r,g,b,z,t);Line(v5,v7,r,g,b,z,t);Line(v5,v4,r,g,b,z,t);Line(v4,v6,r,g,b,z,t);Line(v7,v6,r,g,b,z,t)}function VS::DrawEntityBounds(ent,r,g,b,z,t):(Box){local origin=ent.GetOrigin(),angles=ent.GetAngles(),mins=ent.GetBoundingMins(),maxs=ent.GetBoundingMaxs();if(!angles.x&&!angles.y&&!angles.z)Box(origin,mins,maxs,r,g,b,0,t);else DrawBoxAngles(origin,mins,maxs,angles,r,g,b,z,t)}}function VS::DrawBoxAngles(origin,mins,maxs,angles,r,g,b,z,t):(iBD){iBD();return DrawBoxAngles(origin,mins,maxs,angles,r,g,b,z,t)}function VS::DrawEntityBounds(ent,r,g,b,z,t):(iBD){iBD();return DrawEntityBounds(ent,r,g,b,z,t)}function VS::DrawSphere(vCenter,flRadius,nTheta,nPhi,r,g,b,z,t):(array,Vector,sin,cos,Line){++nTheta;local pVerts=array(nPhi*nTheta),i,j,c=0;for(i=0;i<nPhi;++i)for(j=0;j<nTheta;++j){local u=j/(nTheta-1).tofloat(),v=i/(nPhi-1).tofloat();local theta=6.28318548*u,phi=3.14159265*v;local sp=flRadius*sin(phi);pVerts[c++]=Vector(vCenter.x+(sp*cos(theta)),vCenter.y+(sp*sin(theta)),vCenter.z+(flRadius*cos(phi)))}for(i=0;i<nPhi-1;++i)for(j=0;j<nTheta-1;++j){local idx=nTheta*i+j;Line(pVerts[idx],pVerts[idx+nTheta],r,g,b,z,t);Line(pVerts[idx],pVerts[idx+1],r,g,b,z,t)}}local iC=function(){local Line=DebugDrawLine,CVP=[[-0.01,-0.01,1.0],[0.51,0.0,0.86],[0.44,0.25,0.86],[0.25,0.44,0.86],[-0.01,0.51,0.86],[-0.26,0.44,0.86],[-0.45,0.25,0.86],[-0.51,0.0,0.86],[-0.45,-0.26,0.86],[-0.26,-0.45,0.86],[-0.01,-0.51,0.86],[0.25,-0.45,0.86],[0.44,-0.26,0.86],[0.86,0.0,0.51],[0.75,0.43,0.51],[0.43,0.75,0.51],[-0.01,0.86,0.51],[-0.44,0.75,0.51],[-0.76,0.43,0.51],[-0.87,0.0,0.51],[-0.76,-0.44,0.51],[-0.44,-0.76,0.51],[-0.01,-0.87,0.51],[0.43,-0.76,0.51],[0.75,-0.44,0.51],[1.0,0.0,0.01],[0.86,0.5,0.01],[0.49,0.86,0.01],[-0.01,1.0,0.01],[-0.51,0.86,0.01],[-0.87,0.5,0.01],[-1.0,0.0,0.01],[-0.87,-0.5,0.01],[-0.51,-0.87,0.01],[-0.01,-1.0,0.01],[0.49,-0.87,0.01],[0.86,-0.51,0.01],[1.0,0.0,-0.02],[0.86,0.5,-0.02],[0.49,0.86,-0.02],[-0.01,1.0,-0.02],[-0.51,0.86,-0.02],[-0.87,0.5,-0.02],[-1.0,0.0,-0.02],[-0.87,-0.5,-0.02],[-0.51,-0.87,-0.02],[-0.01,-1.0,-0.02],[0.49,-0.87,-0.02],[0.86,-0.51,-0.02],[0.86,0.0,-0.51],[0.75,0.43,-0.51],[0.43,0.75,-0.51],[-0.01,0.86,-0.51],[-0.44,0.75,-0.51],[-0.76,0.43,-0.51],[-0.87,0.0,-0.51],[-0.76,-0.44,-0.51],[-0.44,-0.76,-0.51],[-0.01,-0.87,-0.51],[0.43,-0.76,-0.51],[0.75,-0.44,-0.51],[0.51,0.0,-0.87],[0.44,0.25,-0.87],[0.25,0.44,-0.87],[-0.01,0.51,-0.87],[-0.26,0.44,-0.87],[-0.45,0.25,-0.87],[-0.51,0.0,-0.87],[-0.45,-0.26,-0.87],[-0.26,-0.45,-0.87],[-0.01,-0.51,-0.87],[0.25,-0.45,-0.87],[0.44,-0.26,-0.87],[0.0,0.0,-1.0]],CLI=[-1,14,0,4,16,28,40,52,64,73,70,58,46,34,22,10,-1,14,0,1,13,25,37,49,61,73,67,55,43,31,19,7,-1,12,61,62,63,64,65,66,67,68,69,70,71,72,-1,12,49,50,51,52,53,54,55,56,57,58,59,60,-1,12,37,38,39,40,41,42,43,44,45,46,47,48,-1,12,25,26,27,28,29,30,31,32,33,34,35,36,-1,12,13,14,15,16,17,18,19,20,21,22,23,24,-1,12,1,2,3,4,5,6,7,8,9,10,11,12,-1],CVT=array(74),MRS=matrix3x4_t();VectorMatrix(Vector(0,0,1),MRS);function VS::DrawCapsule(start,end,radius,r,g,b,z,t):(CVP,CLI,CVT,MRS,Line,Vector,matrix3x4_t){local vcn=start-end,vecLen=end-start;vcn.Norm();local mcs=matrix3x4_t();VectorMatrix(vcn,mcs);for(local i=0;i<74;++i){local v=Vector(CVP[i][0],CVP[i][1],CVP[i][2]);VectorRotate(v,MRS,v);VectorRotate(v,mcs,v);v*=radius;if(CVP[i][2]>0)v+=vecLen;CVT[i]=v+start}local i=0;while(i<117){local i0=CLI[i];if(i0==-1){i+=2;continue};local i1=CLI[++i];if(i1==-1){i+=2;if(i>116)break;continue};Line(CVT[i0],CVT[i1],r,g,b,z,t)}}}function VS::DrawCapsule(start,end,radius,r,g,b,z,t):(iC){iC();return DrawCapsule(start,end,radius,r,g,b,z,t)}
