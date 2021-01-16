//-----------------------------------------------------------------------
//------------------- Copyright (c) samisalreadytaken -------------------
//-----------------------------------------------------------------------
if("AngleQuaternion"in::VS)return;;const FLT_EPSILON=1.19209290E-07;;const FLT_MAX=1.E+37;;const FLT_MIN=1.E-37;;class::Quaternion{x=0.0;y=0.0;z=0.0;w=0.0;constructor(_x=0.0,_y=0.0,_z=0.0,_w=0.0){x=_x;y=_y;z=_z;w=_w}}local Fmt=::format,Quaternion=::Quaternion;function Quaternion::_add(d):(Quaternion){return Quaternion(x+d.x,y+d.y,z+d.z,w+d.w)}function Quaternion::_sub(d):(Quaternion){return Quaternion(x-d.x,y-d.y,z-d.z,w-d.w)}function Quaternion::_mul(d):(Quaternion){return Quaternion(x*d,y*d,z*d,w*d)}function Quaternion::_div(d):(Quaternion){return Quaternion(x/d,y/d,z/d,w/d)}function Quaternion::_unm():(Quaternion){return Quaternion(-x,-y,-z,-w)}function Quaternion::_typeof(){return"Quaternion"}function Quaternion::_tostring():(Fmt){return Fmt("Quaternion(%g,%g,%g,%g)",x,y,z,w)}local array=::array;class::matrix3x4{constructor(X=::Vector(),Y=::Vector(),Z=::Vector(),O=::Vector()){Init();m_flMatVal[0][0]=X.x;m_flMatVal[0][1]=Y.x;m_flMatVal[0][2]=Z.x;m_flMatVal[0][3]=O.x;m_flMatVal[1][0]=X.y;m_flMatVal[1][1]=Y.y;m_flMatVal[1][2]=Z.y;m_flMatVal[1][3]=O.y;m_flMatVal[2][0]=X.z;m_flMatVal[2][1]=Y.z;m_flMatVal[2][2]=Z.z;m_flMatVal[2][3]=O.z}function Init():(array){m_flMatVal=array(3);m_flMatVal[0]=array(4,0);m_flMatVal[1]=array(4,0);m_flMatVal[2]=array(4,0)}function _typeof(){return"matrix3x4_t"}function _tostring(){return"matrix3x4_t"}m_flMatVal=null}local _VEC=::Vector();local _QUAT=::Quaternion(),Vector=::Vector,matrix3x4=::matrix3x4,max=::max,min=::min,fabs=::fabs,sqrt=::sqrt,sin=::sin,cos=::cos,asin=::asin,acos=::acos,atan2=::atan2,VectorAdd=::VS.VectorAdd,VectorSubtract=::VS.VectorSubtract;function VS::InvRSquared(v):(max){return 1.0/max(1.0,v.LengthSqr())}function VS::a_swap(a1,i1,a2,i2){local t=a1[i1];a1[i1]=a2[i2];a2[i2]=t}local a_swap=::VS.a_swap;function VS::MatrixRowDotProduct(in1,row,in2){in1=in1.m_flMatVal;return in1[row][0]*in2.x+in1[row][1]*in2.y+in1[row][2]*in2.z}function VS::MatrixColumnDotProduct(in1,col,in2){in1=in1.m_flMatVal;return in1[0][col]*in2.x+in1[1][col]*in2.y+in1[2][col]*in2.z}function VS::DotProductAbs(in1,in2):(fabs){return fabs(in1.x*in2.x)+fabs(in1.y*in2.y)+fabs(in1.z*in2.z)}function VS::VectorTransform(in1,in2,out=_VEC){in2=in2.m_flMatVal;out.x=in1.x*in2[0][0]+in1.y*in2[0][1]+in1.z*in2[0][2]+in2[0][3];out.y=in1.x*in2[1][0]+in1.y*in2[1][1]+in1.z*in2[1][2]+in2[1][3];out.z=in1.x*in2[2][0]+in1.y*in2[2][1]+in1.z*in2[2][2]+in2[2][3];return out}function VS::VectorITransform(in1,in2,out=_VEC){in2=in2.m_flMatVal;local in1t0=in1.x-in2[0][3];local in1t1=in1.y-in2[1][3];local in1t2=in1.z-in2[2][3];out.x=in1t0*in2[0][0]+in1t1*in2[1][0]+in1t2*in2[2][0];out.y=in1t0*in2[0][1]+in1t1*in2[1][1]+in1t2*in2[2][1];out.z=in1t0*in2[0][2]+in1t1*in2[1][2]+in1t2*in2[2][2];return out}local VectorITransform=::VS.VectorITransform;local VectorTransform=::VS.VectorTransform;function VS::VectorRotate(in1,in2,out=_VEC){in2=in2.m_flMatVal;out.x=in1.x*in2[0][0]+in1.y*in2[0][1]+in1.z*in2[0][2];out.y=in1.x*in2[1][0]+in1.y*in2[1][1]+in1.z*in2[1][2];out.z=in1.x*in2[2][0]+in1.y*in2[2][1]+in1.z*in2[2][2];return out}local VectorRotate=::VS.VectorRotate;function VS::VectorRotate2(in1,in2,out=_VEC):(matrix3x4,VectorRotate){local matRotate=matrix3x4();AngleMatrix(in2,matRotate);VectorRotate(in1,matRotate,out);return out}function VS::VectorRotate3(in1,in2,out=_VEC):(Quaternion){local c=Quaternion();c.x=-in2.x;c.y=-in2.y;c.z=-in2.z;c.w=in2.w;local qv=Quaternion();qv.x=in2.y*in1.z-in2.z*in1.y+in2.w*in1.x;qv.y=-in2.x*in1.z+in2.z*in1.x+in2.w*in1.y;qv.z=in2.x*in1.y-in2.y*in1.x+in2.w*in1.z;qv.w=-in2.x*in1.x-in2.y*in1.y-in2.z*in1.z;out.x=qv.x*c.w+qv.y*c.z-qv.z*c.y+qv.w*c.x;out.y=-qv.x*c.z+qv.y*c.w+qv.z*c.x+qv.w*c.y;out.z=qv.x*c.y-qv.y*c.x+qv.z*c.w+qv.w*c.z;return out}function VS::VectorIRotate(in1,in2,out=_VEC){in2=in2.m_flMatVal;out.x=in1.x*in2[0][0]+in1.y*in2[1][0]+in1.z*in2[2][0];out.y=in1.x*in2[0][1]+in1.y*in2[1][1]+in1.z*in2[2][1];out.z=in1.x*in2[0][2]+in1.y*in2[1][2]+in1.z*in2[2][2];return out}local VectorIRotate=::VS.VectorIRotate;function VS::VectorMA(start,scale,direction,dest=_VEC){dest.x=start.x+scale*direction.x;dest.y=start.y+scale*direction.y;dest.z=start.z+scale*direction.z;return dest}function VS::VectorNegate(vec){vec.x=-vec.x;vec.y=-vec.y;vec.z=-vec.z;return vec}function VS::QuaternionsAreEqual(a,b,tolerance=0.0):(fabs){return(fabs(a.x-b.x)<=tolerance&&fabs(a.y-b.y)<=tolerance&&fabs(a.z-b.z)<=tolerance&&fabs(a.w-b.w)<=tolerance)}function VS::QuaternionNormalize(q):(sqrt){local i,r=q.x*q.x+q.y*q.y+q.z*q.z+q.w*q.w;if(r){r=sqrt(r);i=1.0/r;q.w*=i;q.z*=i;q.y*=i;q.x*=i};return r}function VS::QuaternionAlign(p,q,qt=_QUAT){local a=(p.x-q.x)*(p.x-q.x)+(p.y-q.y)*(p.y-q.y)+(p.z-q.z)*(p.z-q.z)+(p.w-q.w)*(p.w-q.w),b=(p.x+q.x)*(p.x+q.x)+(p.y+q.y)*(p.y+q.y)+(p.z+q.z)*(p.z+q.z)+(p.w+q.w)*(p.w+q.w);if(a>b){qt.x=-q.x;qt.y=-q.y;qt.z=-q.z;qt.w=-q.w}else if(qt!=q){qt.x=q.x;qt.y=q.y;qt.z=q.z;qt.w=q.w};;return qt}local QuaternionNormalize=::VS.QuaternionNormalize;local QuaternionAlign=::VS.QuaternionAlign;function VS::QuaternionMult(p,q,qt=_QUAT):(Quaternion,QuaternionAlign){if(p==qt){local p2=Quaternion(p.x,p.y,p.z,p.w);QuaternionMult(p2,q,qt);return qt};local q2=QuaternionAlign(p,q,Quaternion());qt.x=p.x*q2.w+p.y*q2.z-p.z*q2.y+p.w*q2.x;qt.y=-p.x*q2.z+p.y*q2.w+p.z*q2.x+p.w*q2.y;qt.z=p.x*q2.y-p.y*q2.x+p.z*q2.w+p.w*q2.z;qt.w=-p.x*q2.x-p.y*q2.y-p.z*q2.z+p.w*q2.w;return qt}local QuaternionMult=::VS.QuaternionMult;function VS::QuaternionConjugate(p,q){q.x=-p.x;q.y=-p.y;q.z=-p.z;q.w=p.w}function VS::QuaternionMA(p,s,q,qt=_QUAT):(Quaternion,QuaternionNormalize,QuaternionMult){local q1=q*s;local p1=QuaternionMult(p,q1,Quaternion());;QuaternionNormalize(p1);qt.x=p1.x;qt.y=p1.y;qt.z=p1.z;qt.w=p1.w;return qt}function VS::QuaternionAdd(p,q,qt=_QUAT):(Quaternion,QuaternionAlign){local q2=QuaternionAlign(p,q,Quaternion());qt.x=p.x+q2.x;qt.y=p.y+q2.y;qt.z=p.z+q2.z;qt.w=p.w+q2.w;return qt}function VS::QuaternionDotProduct(p,q){return p.x*q.x+p.y*q.y+p.z*q.z+p.w*q.w}function VS::QuaternionInvert(p,q){q.x=-p.x;q.y=-p.y;q.z=-p.z;q.w=p.w;local sq=p.x*p.x+p.y*p.y+p.z*p.z+p.w*p.w;if(sq){local inv=1.0/sq;q.x*=inv;q.y*=inv;q.z*=inv;q.w*=inv;return};Assert(sq)}function VS::QuaternionBlendNoAlign(p,q,t,qt=_QUAT):(QuaternionNormalize){local sclp=1.0-t,sclq=t;qt.x=sclp*p.x+sclq*q.x;qt.y=sclp*p.y+sclq*q.y;qt.z=sclp*p.z+sclq*q.z;qt.w=sclp*p.w+sclq*q.w;QuaternionNormalize(qt);return qt}local QuaternionBlendNoAlign=::VS.QuaternionBlendNoAlign;function VS::QuaternionBlend(p,q,t,qt=_QUAT):(Quaternion,QuaternionAlign){local q2=QuaternionAlign(p,q,Quaternion());QuaternionBlendNoAlign(p,q2,t,qt);return qt}function VS::QuaternionIdentityBlend(p,t,qt=_QUAT):(QuaternionNormalize){local sclp=1.0-t;qt.x=p.x*sclp;qt.y=p.y*sclp;qt.z=p.z*sclp;if(qt.w<0.0){qt.w=p.w*sclp-t}else{qt.w=p.w*sclp+t};QuaternionNormalize(qt);return qt}function VS::QuaternionSlerpNoAlign(p,q,t,qt=_QUAT):(sin,acos){local om,com,som,sclp,sclq;com=p.x*q.x+p.y*q.y+p.z*q.z+p.w*q.w;if((1.0+com)>0.000001){if((1.0-com)>0.000001){om=acos(com);som=sin(om);sclp=sin((1.0-t)*om)/som;sclq=sin(t*om)/som}else{sclp=1.0-t;sclq=t};qt.x=sclp*p.x+sclq*q.x;qt.y=sclp*p.y+sclq*q.y;qt.z=sclp*p.z+sclq*q.z;qt.w=sclp*p.w+sclq*q.w}else{sclp=sin((1.0-t)*1.5708);sclq=sin(t*1.5708);qt.x=sclp*p.x+sclq*qt.x;qt.y=sclp*p.y+sclq*qt.y;qt.z=sclp*p.z+sclq*qt.z;qt.w=q.z};return qt}local QuaternionSlerpNoAlign=::VS.QuaternionSlerpNoAlign;function VS::QuaternionSlerp(p,q,t,qt=_QUAT):(Quaternion,QuaternionAlign,QuaternionSlerpNoAlign){local q2=QuaternionAlign(p,q,Quaternion());QuaternionSlerpNoAlign(p,q2,t,qt);return qt}function VS::QuaternionAngleDiff(p,q):(Quaternion,QuaternionMult,min,sqrt,asin){local i=Quaternion(),d=Quaternion();i.x=-q.x;i.y=-q.y;i.z=-q.z;i.w=q.w;QuaternionMult(p,i,d);local sa=min(1.0,sqrt(d.x*d.x+d.y*d.y+d.z*d.z));local ang=asin(sa)*114.591559026;return ang}function VS::MatrixAngles(mx,ang=_VEC,pos=null):(sqrt,atan2){mx=mx.m_flMatVal;if(pos){pos.x=mx[0][3];pos.y=mx[1][3];pos.z=mx[2][3]};local f0=mx[0][0];local f1=mx[1][0];local f2=mx[2][0];local left0=mx[0][1];local left1=mx[1][1];local left2=mx[2][1];local up0=null;local up1=null;local up2=mx[2][2];local xyDist=sqrt(f0*f0+f1*f1);if(xyDist>0.001){ang.y=57.29577951*atan2(f1,f0);ang.x=57.29577951*atan2(-f2,xyDist);ang.z=57.29577951*atan2(left2,up2)}else{ang.y=57.29577951*atan2(-left0,left1);ang.x=57.29577951*atan2(-f2,xyDist);ang.z=0};return ang}function VS::MatrixAnglesQ(mx,q=_QUAT,pos=null):(QuaternionNormalize){mx=mx.m_flMatVal;if(pos){pos.x=mx[0][3];pos.y=mx[1][3];pos.z=mx[2][3]};local trace=mx[0][0]+mx[1][1]+mx[2][2]+1.0;if(trace>1.0+1.19209290E-07){q.x=(mx[2][1]-mx[1][2]);q.y=(mx[0][2]-mx[2][0]);q.z=(mx[1][0]-mx[0][1]);q.w=trace}else if(mx[0][0]>mx[1][1]&&mx[0][0]>mx[2][2]){trace=1.0+mx[0][0]-mx[1][1]-mx[2][2];q.x=trace;q.y=(mx[1][0]+mx[0][1]);q.z=(mx[0][2]+mx[2][0]);q.w=(mx[2][1]-mx[1][2])}else if(mx[1][1]>mx[2][2]){trace=1.0+mx[1][1]-mx[0][0]-mx[2][2];q.x=(mx[0][1]+mx[1][0]);q.y=trace;q.z=(mx[2][1]+mx[1][2]);q.w=(mx[0][2]-mx[2][0])}else{trace=1.0+mx[2][2]-mx[0][0]-mx[1][1];q.x=(mx[0][2]+mx[2][0]);q.y=(mx[2][1]+mx[1][2]);q.z=trace;q.w=(mx[1][0]-mx[0][1])};;;QuaternionNormalize(q);return q}local MatrixAngles=::VS.MatrixAngles;local MatrixAnglesQ=::VS.MatrixAnglesQ;function VS::QuaternionMatrix(q,mx,pos=null){mx=mx.m_flMatVal;mx[0][0]=1.0-2.0*q.y*q.y-2.0*q.z*q.z;mx[1][0]=2.0*q.x*q.y+2.0*q.w*q.z;mx[2][0]=2.0*q.x*q.z-2.0*q.w*q.y;mx[0][1]=2.0*q.x*q.y-2.0*q.w*q.z;mx[1][1]=1.0-2.0*q.x*q.x-2.0*q.z*q.z;mx[2][1]=2.0*q.y*q.z+2.0*q.w*q.x;mx[0][2]=2.0*q.x*q.z+2.0*q.w*q.y;mx[1][2]=2.0*q.y*q.z-2.0*q.w*q.x;mx[2][2]=1.0-2.0*q.x*q.x-2.0*q.y*q.y;mx[0][3]=0.0;mx[1][3]=0.0;mx[2][3]=0.0;if(pos){mx[0][3]=pos.x;mx[1][3]=pos.y;mx[2][3]=pos.z}}function VS::QuaternionAngles(q,ang=_VEC):(asin,atan2){local m11=(2.0*q.w*q.w)+(2.0*q.x*q.x)-1.0,m12=(2.0*q.x*q.y)+(2.0*q.w*q.z),m13=(2.0*q.x*q.z)-(2.0*q.w*q.y),m23=(2.0*q.y*q.z)+(2.0*q.w*q.x),m33=(2.0*q.w*q.w)+(2.0*q.z*q.z)-1.0;ang.y=57.29577951*atan2(m12,m11);ang.x=57.29577951*asin(-m13);ang.z=57.29577951*atan2(m23,m33);return ang}local QuaternionMatrix=::VS.QuaternionMatrix;function VS::QuaternionAngles2(q,ang=_VEC):(matrix3x4,QuaternionMatrix,MatrixAngles){local mx=matrix3x4();QuaternionMatrix(q,mx);MatrixAngles(mx,ang);return ang}function VS::QuaternionAxisAngle(q,axis):(acos){local ang=acos(q.w)*114.591559026;if(ang>180)ang-=360;axis.x=q.x;axis.y=q.y;axis.z=q.z;axis.Norm();return ang}function VS::AxisAngleQuaternion(axis,ang,q=_QUAT):(sin,cos){ang=ang*0.008726645;local sa=sin(ang),ca=cos(ang);q.x=axis.x*sa;q.y=axis.y*sa;q.z=axis.z*sa;q.w=ca;return q}function VS::AngleQuaternion(ang,outQuat=_QUAT):(sin,cos){local ay=ang.y*0.008726645,ax=ang.x*0.008726645,az=ang.z*0.008726645;local sy=sin(ay),cy=cos(ay),sp=sin(ax),cp=cos(ax),sr=sin(az),cr=cos(az);local srXcp=sr*cp,crXsp=cr*sp;outQuat.x=srXcp*cy-crXsp*sy;outQuat.y=crXsp*cy+srXcp*sy;local crXcp=cr*cp,srXsp=sr*sp;outQuat.z=crXcp*sy-srXsp*cy;outQuat.w=crXcp*cy+srXsp*sy;return outQuat}local AngleQuaternion=::VS.AngleQuaternion;function VS::MatrixQuaternion(mat,q=_QUAT):(AngleQuaternion,MatrixAngles){local ang=MatrixAngles(mat);AngleQuaternion(ang,q);return q}function VS::BasisToQuaternion(vF,vR,vU,q=_QUAT):(matrix3x4,fabs,MatrixAnglesQ){Assert(fabs(vF.LengthSqr()-1.0)<1.e-3);Assert(fabs(vR.LengthSqr()-1.0)<1.e-3);Assert(fabs(vU.LengthSqr()-1.0)<1.e-3);local vecLeft=vR*-1.0;local mat=matrix3x4(vF,vecLeft,vU);MatrixAnglesQ(mat,q);return q}function VS::AngleMatrix(ang,mx,pos=null):(sin,cos){local ay=0.01745329*ang.y,ax=0.01745329*ang.x,az=0.01745329*ang.z;local sy=sin(ay),cy=cos(ay),sp=sin(ax),cp=cos(ax),sr=sin(az),cr=cos(az);mx=mx.m_flMatVal;mx[0][0]=cp*cy;mx[1][0]=cp*sy;mx[2][0]=-sp;local crcy=cr*cy,crsy=cr*sy,srcy=sr*cy,srsy=sr*sy;mx[0][1]=sp*srcy-crsy;mx[1][1]=sp*srsy+crcy;mx[2][1]=sr*cp;mx[0][2]=(sp*crcy+srsy);mx[1][2]=(sp*crsy-srcy);mx[2][2]=cr*cp;mx[0][3]=0.0;mx[1][3]=0.0;mx[2][3]=0.0;if(pos){mx[0][3]=pos.x;mx[1][3]=pos.y;mx[2][3]=pos.z}}function VS::AngleIMatrix(ang,mx,pos=null):(sin,cos,VectorRotate){local ay=0.01745329*ang.y,ax=0.01745329*ang.x,az=0.01745329*ang.z;local sy=sin(ay),cy=cos(ay),sp=sin(ax),cp=cos(ax),sr=sin(az),cr=cos(az);mx=mx.m_flMatVal;mx[0][0]=cp*cy;mx[0][1]=cp*sy;mx[0][2]=-sp;mx[1][0]=sr*sp*cy+cr*-sy;mx[1][1]=sr*sp*sy+cr*cy;mx[1][2]=sr*cp;mx[2][0]=(cr*sp*cy+-sr*-sy);mx[2][1]=(cr*sp*sy+-sr*cy);mx[2][2]=cr*cp;mx[0][3]=0.0;mx[1][3]=0.0;mx[2][3]=0.0;if(pos){local vecTranslation=VectorRotate(pos,mx)*-1.0;mx[0][3]=vecTranslation.x;mx[1][3]=vecTranslation.y;mx[2][3]=vecTranslation.z}}local AngleMatrix=::VS.AngleMatrix,AngleIMatrix=::VS.AngleIMatrix;function VS::MatrixVectors(mx,vF,vR,vU){mx=mx.m_flMatVal;vF.x=mx[0][0];vF.y=mx[1][0];vF.z=mx[2][0];vR.x=mx[0][1];vR.y=mx[1][1];vR.z=mx[2][1];vU.x=mx[0][2];vU.y=mx[1][2];vU.z=mx[2][2];vR.x=vR.x*-1.0;vR.y=vR.y*-1.0;vR.z=vR.z*-1.0}function VS::MatricesAreEqual(src1,src2,flTolerance):(fabs){src1=src1.m_flMatVal;src2=src2.m_flMatVal;for(local i=0;i<3;++i){for(local j=0;j<4;++j){if(fabs(src1[i][j]-src2[i][j])>flTolerance)return false}}return true}function VS::MatrixCopy(src,dst){for(local i=0;i<3;++i){for(local j=0;j<4;++j){dst[i][j]=src[i][j]}}return dst}function VS::MatrixInvert(in1,out):(a_swap){in1=in1.m_flMatVal;out=out.m_flMatVal;if(in1==out){a_swap(out[0],1,out[1],0);a_swap(out[0],2,out[2],0);a_swap(out[1],2,out[2],1)}else{out[0][0]=in1[0][0];out[0][1]=in1[1][0];out[0][2]=in1[2][0];out[1][0]=in1[0][1];out[1][1]=in1[1][1];out[1][2]=in1[2][1];out[2][0]=in1[0][2];out[2][1]=in1[1][2];out[2][2]=in1[2][2]};local tmp0=in1[0][3];local tmp1=in1[1][3];local tmp2=in1[2][3];out[0][3]=-(tmp0*out[0][0]+tmp1*out[0][1]+tmp2*out[0][2]);out[1][3]=-(tmp0*out[1][0]+tmp1*out[1][1]+tmp2*out[1][2]);out[2][3]=-(tmp0*out[2][0]+tmp1*out[2][1]+tmp2*out[2][2])}function VS::MatrixGetColumn(in1,col,out=_VEC){in1=in1.m_flMatVal;out.x=in1[0][col];out.y=in1[1][col];out.z=in1[2][col];return out}function VS::MatrixSetColumn(in1,col,out){out=out.m_flMatVal;out[0][col]=in1.x;out[1][col]=in1.y;out[2][col]=in1.z}function VS::MatrixScaleBy(fl,out){out=out.m_flMatVal;out[0][0]*=fl;out[1][0]*=fl;out[2][0]*=fl;out[0][1]*=fl;out[1][1]*=fl;out[2][1]*=fl;out[0][2]*=fl;out[1][2]*=fl;out[2][2]*=fl}function VS::MatrixScaleByZero(out){out=out.m_flMatVal;out[0][0]=0.0;out[1][0]=0.0;out[2][0]=0.0;out[0][1]=0.0;out[1][1]=0.0;out[2][1]=0.0;out[0][2]=0.0;out[1][2]=0.0;out[2][2]=0.0}function VS::SetIdentityMatrix(mx){mx=mx.m_flMatVal;mx[0][0]=1.0;mx[0][1]=0.0;mx[0][2]=0.0;mx[0][3]=0.0;mx[1][0]=0.0;mx[1][1]=1.0;mx[1][2]=0.0;mx[1][3]=0.0;mx[2][0]=0.0;mx[2][1]=0.0;mx[2][2]=1.0;mx[2][3]=0.0}function VS::SetScaleMatrix(x,y,z,dst){dst=dst.m_flMatVal;dst[0][0]=x;dst[0][1]=0.0;dst[0][2]=0.0;dst[0][3]=0.0;dst[1][0]=0.0;dst[1][1]=y;dst[1][2]=0.0;dst[1][3]=0.0;dst[2][0]=0.0;dst[2][1]=0.0;dst[2][2]=z;dst[2][3]=0.0}function VS::ComputeCenterMatrix(ori,ang,mins,maxs,mx):(VectorRotate,AngleMatrix){local ctr=(mins+maxs)*0.5;AngleMatrix(ang,mx);local worldCentroid=VectorRotate(ctr,mx)+ori;mx[0][3]=worldCentroid.x;mx[1][3]=worldCentroid.y;mx[2][3]=worldCentroid.z}function VS::ComputeCenterIMatrix(ori,ang,mins,maxs,mx):(VectorRotate,AngleIMatrix){local ctr=(mins+maxs)*-0.5;AngleIMatrix(ang,mx);local localOrigin=VectorRotate(ori,mx);ctr-=localOrigin;mx[0][3]=ctr.x;mx[1][3]=ctr.y;mx[2][3]=ctr.z}function VS::ComputeAbsMatrix(in1,out):(fabs){in1=in1.m_flMatVal;out=out.m_flMatVal;out[0][0]=fabs(in1[0][0]);out[0][1]=fabs(in1[0][1]);out[0][2]=fabs(in1[0][2]);out[1][0]=fabs(in1[1][0]);out[1][1]=fabs(in1[1][1]);out[1][2]=fabs(in1[1][2]);out[2][0]=fabs(in1[2][0]);out[2][1]=fabs(in1[2][1]);out[2][2]=fabs(in1[2][2])}function VS::ConcatRotations(in1,in2,out){in1=in1.m_flMatVal;in2=in2.m_flMatVal;out=out.m_flMatVal;out[0][0]=in1[0][0]*in2[0][0]+in1[0][1]*in2[1][0]+in1[0][2]*in2[2][0];out[0][1]=in1[0][0]*in2[0][1]+in1[0][1]*in2[1][1]+in1[0][2]*in2[2][1];out[0][2]=in1[0][0]*in2[0][2]+in1[0][1]*in2[1][2]+in1[0][2]*in2[2][2];out[1][0]=in1[1][0]*in2[0][0]+in1[1][1]*in2[1][0]+in1[1][2]*in2[2][0];out[1][1]=in1[1][0]*in2[0][1]+in1[1][1]*in2[1][1]+in1[1][2]*in2[2][1];out[1][2]=in1[1][0]*in2[0][2]+in1[1][1]*in2[1][2]+in1[1][2]*in2[2][2];out[2][0]=in1[2][0]*in2[0][0]+in1[2][1]*in2[1][0]+in1[2][2]*in2[2][0];out[2][1]=in1[2][0]*in2[0][1]+in1[2][1]*in2[1][1]+in1[2][2]*in2[2][1];out[2][2]=in1[2][0]*in2[0][2]+in1[2][1]*in2[1][2]+in1[2][2]*in2[2][2]}function VS::ConcatTransforms(in1,in2,out){in1=in1.m_flMatVal;in2=in2.m_flMatVal;local rowA0=in1[0];local rowA1=in1[1];local rowA2=in1[2];local rowB0=in2[0];local rowB1=in2[1];local rowB2=in2[2];local out00=(rowA0[0]*rowB0[0]+rowA0[1]*rowB1[0]+rowA0[2]*rowB2[0])+(rowA0[0]&0);local out01=(rowA0[0]*rowB0[1]+rowA0[1]*rowB1[1]+rowA0[2]*rowB2[1])+(rowA0[1]&0);local out02=(rowA0[0]*rowB0[2]+rowA0[1]*rowB1[2]+rowA0[2]*rowB2[2])+(rowA0[2]&0);local out03=(rowA0[0]*rowB0[3]+rowA0[1]*rowB1[3]+rowA0[2]*rowB2[3])+(rowA0[3]&0xFFFFFFFF);local out10=(rowA1[0]*rowB0[0]+rowA1[1]*rowB1[0]+rowA1[2]*rowB2[0])+(rowA1[0]&0);local out11=(rowA1[0]*rowB0[1]+rowA1[1]*rowB1[1]+rowA1[2]*rowB2[1])+(rowA1[1]&0);local out12=(rowA1[0]*rowB0[2]+rowA1[1]*rowB1[2]+rowA1[2]*rowB2[2])+(rowA1[2]&0);local out13=(rowA1[0]*rowB0[3]+rowA1[1]*rowB1[3]+rowA1[2]*rowB2[3])+(rowA1[3]&0xFFFFFFFF);local out20=(rowA2[0]*rowB0[0]+rowA2[1]*rowB1[0]+rowA2[2]*rowB2[0])+(rowA2[0]&0);local out21=(rowA2[0]*rowB0[1]+rowA2[1]*rowB1[1]+rowA2[2]*rowB2[1])+(rowA2[1]&0);local out22=(rowA2[0]*rowB0[2]+rowA2[1]*rowB1[2]+rowA2[2]*rowB2[2])+(rowA2[2]&0);local out23=(rowA2[0]*rowB0[3]+rowA2[1]*rowB1[3]+rowA2[2]*rowB2[3])+(rowA2[3]&0xFFFFFFFF);out=out.m_flMatVal;out[0][0]=out00;out[0][1]=out01;out[0][2]=out02;out[0][3]=out03;out[1][0]=out10;out[1][1]=out11;out[1][2]=out12;out[1][3]=out13;out[2][0]=out20;out[2][1]=out21;out[2][2]=out22;out[2][3]=out23}function VS::MatrixBuildRotationAboutAxis(xr,ad,dst):(sin,cos){local rad=ad*0.01745329;local fSin=sin(rad),fCos=cos(rad);local xxq=xr[0]*xr[0],yyq=xr[1]*xr[1],zzq=xr[2]*xr[2];dst=dst.m_flMatVal;dst[0][0]=xxq+(1-xxq)*fCos;dst[1][0]=xr[0]*xr[1]*(1-fCos)+xr[2]*fSin;dst[2][0]=xr[2]*xr[0]*(1-fCos)-xr[1]*fSin;dst[0][1]=xr[0]*xr[1]*(1-fCos)-xr[2]*fSin;dst[1][1]=yyq+(1-yyq)*fCos;dst[2][1]=xr[1]*xr[2]*(1-fCos)+xr[0]*fSin;dst[0][2]=xr[2]*xr[0]*(1-fCos)+xr[1]*fSin;dst[1][2]=xr[1]*xr[2]*(1-fCos)-xr[0]*fSin;dst[2][2]=zzq+(1-zzq)*fCos;dst[0][3]=0;dst[1][3]=0;dst[2][3]=0}function VS::TransformAABB(tr,vni,vxi,vno,vxo):(Vector,fabs,VectorAdd,VectorSubtract,VectorTransform){local lc=(vni+vxi)*0.5;local le=vxi-lc;local wc=VectorTransform(lc,tr);tr=tr.m_flMatVal;local we=Vector(fabs(le.x*tr[0][0])+fabs(le.y*tr[0][1])+fabs(le.z*tr[0][2]),fabs(le.x*tr[1][0])+fabs(le.y*tr[1][1])+fabs(le.z*tr[1][2]),fabs(le.x*tr[2][0])+fabs(le.y*tr[2][1])+fabs(le.z*tr[2][2]));VectorSubtract(wc,we,vno);VectorAdd(wc,we,vxo)}function VS::ITransformAABB(tr,vni,vxi,vno,vxo):(Vector,fabs,VectorAdd,VectorSubtract,VectorITransform){local wc=(vni+vxi)*0.5;local we=vxi-wc;local lc=VectorITransform(wc,tr);tr=tr.m_flMatVal;local le=Vector(fabs(we.x*tr[0][0])+fabs(we.y*tr[1][0])+fabs(we.z*tr[2][0]),fabs(we.x*tr[0][1])+fabs(we.y*tr[1][1])+fabs(we.z*tr[2][1]),fabs(we.x*tr[0][2])+fabs(we.y*tr[1][2])+fabs(we.z*tr[2][2]));VectorSubtract(lc,le,vno);VectorAdd(lc,le,vxo)}function VS::RotateAABB(tr,vni,vxi,vno,vxo):(Vector,fabs,VectorAdd,VectorSubtract,VectorRotate){local lc=(vni+vxi)*0.5;local le=vxi-lc;local nc=VectorRotate(lc,tr);tr=tr.m_flMatVal;local ne=Vector(fabs(le.x*tr[0][0])+fabs(le.y*tr[0][1])+fabs(le.z*tr[0][2]),fabs(le.x*tr[1][0])+fabs(le.y*tr[1][1])+fabs(le.z*tr[1][2]),fabs(le.x*tr[2][0])+fabs(le.y*tr[2][1])+fabs(le.z*tr[2][2]));VectorSubtract(nc,ne,vno);VectorAdd(nc,ne,vxo)}function VS::IRotateAABB(tr,vni,vxi,vno,vxo):(Vector,fabs,VectorAdd,VectorSubtract,VectorIRotate){local oc=(vni+vxi)*0.5;local oe=vxi-oc;local nc=VectorIRotate(oc,tr);tr=tr.m_flMatVal;local ne=Vector(fabs(oe.x*tr[0][0])+fabs(oe.y*tr[1][0])+fabs(oe.z*tr[2][0]),fabs(oe.x*tr[0][1])+fabs(oe.y*tr[1][1])+fabs(oe.z*tr[2][1]),fabs(oe.x*tr[0][2])+fabs(oe.y*tr[1][2])+fabs(oe.z*tr[2][2]));VectorSubtract(nc,ne,vno);VectorAdd(nc,ne,vxo)}
