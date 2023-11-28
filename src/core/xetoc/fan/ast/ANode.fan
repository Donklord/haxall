//
// Copyright (c) 2023, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   3 Jul 2023  Brian Frank  Creation
//

using util
using xeto

**
** Base class for all AST nodes
**
internal abstract class ANode
{
   ** Constructor
  new make(FileLoc loc) { this.loc = loc }

  ** Source code location for reporting compiler errors
  const FileLoc loc

  ** Return node type enum
  abstract ANodeType nodeType()

  ** Recursively walk thru the AST tree.   Children nodes are
  ** processed first, then this node itself is processed.
  abstract Void walk(|ANode| f)

  ** Assembled value - raise exception if not assembled yet
  abstract Obj asm()

  ** Debug dump
  virtual Void dump(OutStream out := Env.cur.out, Str indent := "")
  {
    out.print(toStr)
  }
}

**************************************************************************
** ANodeType
**************************************************************************

enum class ANodeType
{
  lib,
  dataDoc,
  spec,
  scalar,
  dict,
  instance,
  specRef,
  dataRef
}