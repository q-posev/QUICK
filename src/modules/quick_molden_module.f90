!---------------------------------------------------------------------!
! Created by Madu Manathunga on 07/14/2022                            !
!                                                                     !
! Copyright (C) 2020-2021 Merz lab                                    !
! Copyright (C) 2020-2021 Götz lab                                    !
!                                                                     !
! This Source Code Form is subject to the terms of the Mozilla Public !
! License, v. 2.0. If a copy of the MPL was not distributed with this !
! file, You can obtain one at http://mozilla.org/MPL/2.0/.            !
!_____________________________________________________________________!

#include "util.fh"

module quick_molden_module

    implicit none
    private

    public :: quick_molden
    public :: initializeExport, finalizeExport, exportCoordinates, exportBasis, exportMO

    type quick_molden_type
      integer :: iMoldenFile

      ! number of scf iterations to converge
      integer, dimension(:), allocatable :: nscf_snapshots

      ! scf energy during each iteration
      double precision,dimension(:,:),allocatable :: e_snapshots

      ! geometry during optimization
      double precision,dimension(:,:,:),allocatable :: xyz_snapshots

      ! counter to keep track of number of snapshots
      integer :: iexport_snapshot

    end type quick_molden_type

    type (quick_molden_type),save:: quick_molden

    interface initializeExport
        module procedure initialize_molden
    end interface initializeExport

    interface finalizeExport
        module procedure finalize_molden
    end interface finalizeExport

    interface exportCoordinates
        module procedure write_coordinates
    end interface exportCoordinates

    interface exportBasis
        module procedure write_basis_info
    end interface exportBasis

    interface exportMO
        module procedure write_mo
    end interface exportMO
contains

subroutine write_coordinates(self, ierr)

    use quick_molspec_module, only: quick_molspec, xyz, natom
    use quick_constants_module, only : symbol, BOHRS_TO_A
    implicit none
    type (quick_molden_type), intent(in) :: self
    integer, intent(out) :: ierr
    integer :: i, j

    ! write atomic labels and coordinates
    write(self%iMoldenFile, '("[Atoms] (Ang)")')
    do i=1,natom
        write(self%iMoldenFile,'(2x,A2,4x,I5,4x,I3,4x,F10.4,4x,F10.4,4x,F10.4)') &
        symbol(quick_molspec%iattype(i)), i, quick_molspec%iattype(i), (xyz(j,i)*BOHRS_TO_A,j=1,3)
    enddo

end subroutine write_coordinates

subroutine write_basis_info(self, ierr)

    use quick_basis_module, only: quick_basis, nshell, nbasis, aexp, dcoeff, ncontract
    use quick_molspec_module, only: natom
    implicit none
    type (quick_molden_type), intent(in) :: self
    integer, intent(out) :: ierr
    integer :: iatom, ishell, ibas, iprim, nprim, j

    ! write basis function information
    write(self%iMoldenFile, '("[GTO] (AU)")')
    do iatom=1, natom
        write(self%iMoldenFile, '(2x, I5)') iatom

        do ishell=1, nshell
            if(quick_basis%katom(ishell) .eq. iatom) then
                nprim = quick_basis%kprim(ishell)
                if(quick_basis%ktype(ishell) .eq. 1) then
                    write(self%iMoldenFile, '(2x, "s", 4x, I2)') nprim
                elseif(quick_basis%ktype(ishell) .eq. 3) then
                    write(self%iMoldenFile, '(2x, "p", 4x, I2)') nprim
                elseif(quick_basis%ktype(ishell) .eq. 4) then
                    write(self%iMoldenFile, '(2x, "sp", 4x, I2)') nprim
                elseif(quick_basis%ktype(ishell) .eq. 6) then
                    write(self%iMoldenFile, '(2x, "d", 4x, I2)') nprim
                elseif(quick_basis%ktype(ishell) .eq. 10) then
                    write(self%iMoldenFile, '(2x, "f", 4x, I2)') nprim
                endif
                 
                if(quick_basis%ktype(ishell) .eq. 4) then
                    do iprim=1, nprim
                        write(self%iMoldenFile, '(2x, E14.8, 2x, E14.8, 2x, E14.8)') &
                        aexp(iprim, quick_basis%ksumtype(ishell)), (dcoeff(iprim,quick_basis%ksumtype(ishell)+j), j=0,1)
                    enddo                    

                else
                    do iprim=1, nprim
                        write(self%iMoldenFile, '(2x, E14.8, 2x, E14.8)') &
                        aexp(iprim, quick_basis%ksumtype(ishell)), dcoeff(iprim,quick_basis%ksumtype(ishell))
                    enddo
                endif
            endif
        enddo
    enddo

end subroutine write_basis_info

subroutine write_mo(self, ierr)

    use quick_basis_module, only: quick_basis, nbasis
    use quick_calculated_module, only: quick_qm_struct
    use quick_scratch_module
    implicit none
    type (quick_molden_type), intent(in) :: self
    integer, intent(out) :: ierr    
    integer :: i, j, k
    double precision :: holdij

    ! calculate occupation numbers
    do i=1,nbasis
        do j=1,nbasis
            holdij = 0.0d0
            do k=1,nbasis
                holdij = holdij + quick_qm_struct%dense(k,i)*quick_qm_struct%s(k,j)
            enddo
            quick_scratch%hold(i,j) = holdij
        enddo
    enddo

#if defined(CUDA) || defined(CUDA_MPIV)
           call cublas_DGEMM ('n', 'n', nbasis, nbasis, nbasis, 1.0d0, quick_qm_struct%dense, &
                 nbasis, quick_qm_struct%s, nbasis, 0.0d0, quick_scratch%hold,nbasis)
#else
           call DGEMM ('n', 'n', nbasis, nbasis, nbasis, 1.0d0, quick_qm_struct%dense, &
                 nbasis, quick_qm_struct%s, nbasis, 0.0d0, quick_scratch%hold,nbasis)
#endif

    write(self%iMoldenFile, '("[MO]")')

    do i=1, nbasis
        write(self%iMoldenFile, '(2x, "Sym= a", I5)') i
        write(self%iMoldenFile, '(2x, "Ene= ", E16.10)') quick_qm_struct%E(i)
        write(self%iMoldenFile, '(2x, "Spin= Alpha" )') 

        ! write orbital occupation numbers
        write(self%iMoldenFile, '(2x, "Occup= ", F10.4)') quick_scratch%hold(i,i) 

        ! write molecular orbital coefficients        
        do j=1, nbasis
            write(self%iMoldenFile, '(2x, I5, 2x, E16.10)') j, quick_qm_struct%co(j,i)
        enddo
    enddo

end subroutine write_mo

subroutine initialize_molden(self, ierr)
    
    use quick_files_module, only : iMoldenFile, moldenFileName
    use quick_method_module, only: quick_method
    use quick_molspec_module, only: natom
    implicit none
    type (quick_molden_type), intent(inout) :: self
    integer, intent(out) :: ierr
    integer :: dimy

    self%iMoldenFile = iMoldenFile
    self%iexport_snapshot=0
    dimy = 1
    if(quick_method%opt) dimy = quick_method%iopt

    ! allocate memory
    if(.not. allocated(self%nscf_snapshots)) allocate(self%nscf_snapshots(quick_method%iscf))
    if(.not. allocated(self%e_snapshots)) allocate(self%e_snapshots(quick_method%iscf, dimy))
    if(.not. allocated(self%xyz_snapshots)) allocate(self%xyz_snapshots(3, natom, dimy))

    ! open file
    call quick_open(self%iMoldenFile,moldenFileName,'U','F','R',.false.,ierr)

    write(self%iMoldenFile, '("[Molden Format]")')

end subroutine initialize_molden

subroutine finalize_molden(self, ierr)

    implicit none
    type (quick_molden_type), intent(inout) :: self
    integer, intent(out) :: ierr

    ! deallocate memory
    if(allocated(self%nscf_snapshots)) deallocate(self%nscf_snapshots)
    if(allocated(self%e_snapshots)) deallocate(self%e_snapshots)
    if(allocated(self%xyz_snapshots)) deallocate(self%xyz_snapshots)

    ! close file
    close(self%iMoldenFile)

end subroutine finalize_molden

end module quick_molden_module
