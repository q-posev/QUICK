#include "util.fh"
!
!	Angles.f90
!	new_quick
!
!	Created by Yipu Miao on 2/23/11.
!	Copyright 2011 University of Florida. All rights reserved.
!

!-----------------------------------------------------------
! BNDANG
!-----------------------------------------------------------
! Return bond ang
!-----------------------------------------------------------
SUBROUTINE BNDANG(I,IA,IB,ANGLE)
  use allmod
  IMPLICIT DOUBLE PRECISION (A-H,O-Z)


  ! COMPUTES THE ANGLE IN RADIANS FORMED BY ATOMS I-IA-IB.  RETURNED
  ! IN ANGLE.


  ! FORM THE BOND VECTORS WITH VERTEX IA.

  X1 = XYZ(1,I) - XYZ(1,IA)
  Y1 = XYZ(2,I) - XYZ(2,IA)
  Z1 = XYZ(3,I) - XYZ(3,IA)
  X2 = XYZ(1,IB) - XYZ(1,IA)
  Y2 = XYZ(2,IB) - XYZ(2,IA)
  Z2 = XYZ(3,IB) - XYZ(3,IA)
  VNORM1 = DSQRT(X1*X1 + Y1*Y1 + Z1*Z1)
  VNORM2 = DSQRT(X2*X2 + Y2*Y2 + Z2*Z2)
  COSINE = (X1*X2 + Y1*Y2 + Z1*Z2)/(VNORM1*VNORM2)
  if(ABS(COSINE) > 1.0D0) COSINE = SIGN(1.0D0,COSINE)
  ANGLE = ACOS(COSINE)
  RETURN
end SUBROUTINE BNDANG




!-----------------------------------------------------------
! DIHEDR
!-----------------------------------------------------------
! Return dihedral angel
! $Id: dihedr.f90,v 1.1.1.1 2007/01/26 20:22:34 ayers Exp $
!------------------------------------------------------------------------
SUBROUTINE DIHEDR(XYZ,I,IA,IB,IC,DIH)

  ! DETERMINES THE I-IA-IB-IC DIHEDRAL ANGLE IN RADIANS.  THE
  ! ANGLE DIH IS POSITIVE IF IC IS LOCATED CLOCKWISE FROM I WHEN
  ! VIEWING FROM IA THROUGH IB.

  IMPLICIT DOUBLE PRECISION (A-H,O-Z)
  DIMENSION XYZ(3,*)

  ! SHIFT IA-I AND IB-IC BOND VECTORS TO A COMMON ORIGIN.

  AIIX = XYZ(1,I) - XYZ(1,IA)
  AIIY = XYZ(2,I) - XYZ(2,IA)
  AIIZ = XYZ(3,I) - XYZ(3,IA)
  BCX = XYZ(1,IC) - XYZ(1,IB)
  BCY = XYZ(2,IC) - XYZ(2,IB)
  BCZ = XYZ(3,IC) - XYZ(3,IB)

  ! FORM THE IA-IB BOND AXIS VECTOR.

  ABX = XYZ(1,IB) - XYZ(1,IA)
  ABY = XYZ(2,IB) - XYZ(2,IA)
  ABZ = XYZ(3,IB) - XYZ(3,IA)

  ! REMOVE FROM (AIIX,AIIY,AIIZ) AND (BCX,BCY,BCZ) ANY PROJECTION ALONG
  ! THE (ABX,ABY,ABZ) AXIS.

  DOT1 = AIIX*ABX + AIIY*ABY + AIIZ*ABZ
  ABSQR = ABX**2 + ABY**2 + ABZ**2
  PROJ1 = DOT1/ABSQR
  AIIX = AIIX - PROJ1*ABX
  AIIY = AIIY - PROJ1*ABY
  AIIZ = AIIZ - PROJ1*ABZ
  DOT2 = BCX*ABX + BCY*ABY + BCZ*ABZ
  PROJ2 = DOT2/ABSQR
  BCX = BCX - PROJ2*ABX
  BCY = BCY - PROJ2*ABY
  BCZ = BCZ - PROJ2*ABZ

  ! COMPUTE THE CROSS-PRODUCT (AIIX,AIIY,AIIZ) X (BCX,BCY,BCZ).  STORE
  ! IT IN THE VECTOR (AIBCX,AIBCY,AIBCZ).

  AIBCX = AIIY*BCZ - AIIZ*BCY
  AIBCY = AIIZ*BCX - AIIX*BCZ
  AIBCZ = AIIX*BCY - AIIY*BCX

  ! IF (AIBCX,AIBCY,AIBCZ) POINTS IN THE SAME DIRECTION AS
  ! (ABX,ABY,ABZ) then IC IS LOCATED CLOCKWISE FROM I WHEN
  ! VIEWED FROM IA TOWARD IB.  THUS, IN MOVING ALONG THE PATH
  ! I-IA-IB-IC, A CLOCKWISE OR POSITIVE ANGLE IS OBSERVED.
  ! TO DETERMINE WHETHER THESE VECTORS POINT IN THE SAME OR
  ! OPPOSITE DIRECTIONS, COMPUTE THEIR DOT PRODUCT.

  DOT3 = AIBCX*ABX + AIBCY*ABY + AIBCZ*ABZ
  DIREC = SIGN(1.0D0,DOT3)

  ! COMPUTE THE DIHEDRAL ANGLE DIH.

  DOT4 = AIIX*BCX + AIIY*BCY + AIIZ*BCZ
  AILENG = SQRT(AIIX**2 + AIIY**2 + AIIZ**2)
  BCLENG = SQRT(BCX**2 + BCY**2 + BCZ**2)
  if(ABS(AILENG*BCLENG) < 1.0D-5)then
     COSINE = 1.0D0
  else
     COSINE = DOT4/(AILENG*BCLENG)
  endif
  COSINE = MAX(-1.0D0,COSINE)
  COSINE = MIN(1.0D0,COSINE)
  DIH = ACOS(COSINE)*DIREC
  RETURN
end SUBROUTINE DIHEDR
