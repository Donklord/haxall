//
// Copyright (c) 2023, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   10 Apr 2023  Brian Frank  Creation
//

using util
using xeto
using xetoEnv

**
** InheritMeta computes the effective meta for all the specs
**
internal class InheritMeta : Step
{
  override Void run()
  {
    if (isData) return
    lib.tops.each |spec| { inherit(spec) }
    bombIfErr
  }

  private Void inherit(ASpec spec)
  {
    // if already processed skip
    if (spec.cmetaRef != null) return

    // process this spec
    spec.cmetaRef = computeMeta(spec)

    // compute arguments
    spec.argsRef = computeArgs(spec)

    // recurse children slots
    if (spec.slots != null) spec.slots.each |slot| { inherit(slot) }
  }

  private Dict computeMeta(ASpec spec)
  {
    own := spec.metaOwn

    // if base is null this is sys::Obj; otherwise recursively process base
    base := spec.base
    if (spec.base == null) return own
    if (base.isAst) inherit(base)

    // walk thru base tags and map tags we inherit
    acc := Str:Obj[:]
    acc.ordered = true
    baseSize := 0
    base.cmeta.each |v, n|
    {
      baseSize++
      if (isMetaInherited(base, n)) acc[n] = v
    }

    // if we inherited all of the base tags and
    // I have none of my own, then reuse base meta
    if (acc.size == baseSize && own.isEmpty && spec.val == null)
      return base.cmeta

    // merge in my own tags
    if (!own.isEmpty)
    {
      own.each |v, n|
      {
        if (v === env.none && spec.qname != "sys::None")
          acc.remove(n)
        else
          acc[n] = v
      }
    }

    return MNameDict(env.names.dictMap(acc))
  }

  static Bool isMetaInherited(CSpec base, Str name)
  {
    // we need to make this use reflection at some point
    if (name == "abstract") return false
    if (name == "sealed") return false
    if (name == "val") return !base.isEnum
    return true
  }

  private MSpecArgs computeArgs(ASpec spec)
  {
    of := spec.metaGet("of")
    if (of != null)
    {
      if (of.nodeType != ANodeType.specRef)
        err("Invalid value for 'of' meta, not a spec", of.loc)
      else
        return MSpecArgsOf(of.asm)
    }

    ofs := spec.metaGet("ofs") as ADict
    if (ofs != null)
    {
      acc := Spec[,]
      acc.capacity = ofs.size
      ofs.each |ASpecRef ref| { acc.add(ref.asm) }
      return MSpecArgsOfs(acc)
    }

    if (spec.base != null) return spec.base.args

    return MSpecArgs.nil
  }

}