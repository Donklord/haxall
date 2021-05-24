//
// Copyright (c) 2021, SkyFoundry LLC
// Licensed under the Academic Free License version 3.0
//
// History:
//   24 May 2021  Brian Frank  Creation
//

using concurrent
using web

**
** HxLib plugin to add web serviciingapability
**
abstract const class HxLibWeb : WebMod
{
  ** Subclass constructor
  protected new make(HxLib lib) { this.libRef = lib }

  ** Runtime for parent library
  HxRuntime rt() { libRef.rt }

  ** Parent library.  Subclasses can override this method to be covariant.
  virtual HxLib lib() { libRef }
  private const HxLib libRef

  ** Is the unsupported no-up default instance
  @NoDoc virtual Bool isUnsupported() { false }

}

**************************************************************************
** UnsupportedHxLibWeb
**************************************************************************

internal const class UnsupportedHxLibWeb : HxLibWeb
{
  new make(HxLib lib) : super(lib) {}
  override Bool isUnsupported() { true }
}

