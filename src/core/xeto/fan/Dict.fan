//
// Copyright (c) 2023, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   16 Jan 2023  Brian Frank  Creation
//

**
** Dict is a map of name/value pairs.
** Create instances via `XetoEnv.dict`.
**
@Js
const mixin Dict
{

  ** Return if the there are no name/value pairs
  abstract Bool isEmpty()

  // Get the 'id' tag as a Ref or raise exception
  // We can't add this without breaking backward binary compatibility
  // abstract Ref id()

  ** Get the value for the given name or 'def' if name not mapped
  @Operator abstract Obj? get(Str name, Obj? def := null)

  ** Return true if this dictionary contains given name
  abstract Bool has(Str name)

  ** Return true if this dictionary does not contain given name
  abstract Bool missing(Str name)

  ** Iterate through the name/value pairs
  abstract Void each(|Obj val, Str name| f)

  ** Iterate through the name/value pairs until the given
  ** function returns non-null, then break the iteration and
  ** return resulting object.  Return null if function returns
  ** null for every name/value pair.
  abstract Obj? eachWhile(|Obj val, Str name->Obj?| f)

  ** Get the value mapped by the given name.  If it is not
  ** mapped to a non-null value, then throw an UnknownNameErr.
  override abstract Obj? trap(Str name, Obj?[]? args := null)

  ** Create a new instance of this dict with the same names,
  ** but apply the specified closure to generate new values.
  abstract This map(|Obj val, Str name->Obj| f)

}

