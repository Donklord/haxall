//
// Copyright (c) 2016, SkyFoundry LLC
// Licensed under the Academic Free License version 3.0
//
// History:
//   15 Feb 2016  Brian Frank  Creation
//

using concurrent
using haystack
using folio
using hxStore

**
** IndexMgr is responsible for the in-memory index of Recs.
** All changes to Rec and their lookup tables are handled by
** the index actor.
**
internal const class IndexMgr : HxFolioMgr
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Constructro
  new make(HxFolio folio, Loader loader) : super(folio)
  {
    this.byId = loader.byId
  }

//////////////////////////////////////////////////////////////////////////
// Reads
//////////////////////////////////////////////////////////////////////////

  ** Number of records
  Int size()  { byId.size }

  ** Lookup Rec by id
  Rec? rec(Ref ref, Bool checked := true)
  {
    rec := byId.get(ref)
    if (rec != null) return rec
    if (ref.isRel && folio.idPrefix != null)
    {
      ref = ref.toAbs(folio.idPrefix)
      rec = byId.get(ref)
      if (rec != null) return rec
    }
    if (checked) throw UnknownRecErr(ref.id)
    return null
  }

  ** Lookup Rec.dict by id
  Dict? dict(Ref ref, Bool checked := true)
  {
    rec(ref, checked)?.dict
  }

//////////////////////////////////////////////////////////////////////////
// Background Updates
//////////////////////////////////////////////////////////////////////////

  private DateTime lastMod() { lastModRef.val }
  private const AtomicRef lastModRef := AtomicRef(DateTime.nowUtc)

  Future commit(Diff[] diffs) { send(Msg(MsgId.commit, diffs)) }

  override Obj? onReceive(Msg msg)
  {
    switch (msg.id)
    {
      case MsgId.commit: return onCommit(msg.a, msg.b, msg.c)
      default:           return super.onReceive(msg)
    }
  }

//////////////////////////////////////////////////////////////////////////
// Commit
//////////////////////////////////////////////////////////////////////////

  private CommitFolioRes onCommit(Diff[] diffs, [Ref:Ref]? newIds, Obj? cxInfo)
  {
    // all diffs are transient or peristent (checked ealier)
    persistent := !diffs.first.isTransient

    // generate a new unique mod
    newMod := DateTime.nowUtc(null)
    if (newMod <= lastMod) newMod = lastMod + 1ms

    // map each diffs to Commit instance
    newTicks := Duration.nowTicks
    Commit[] commits := diffs.map |d->Commit| { Commit(folio, d, newMod, newTicks, newIds, cxInfo) }

    // perform up-front verification
    commits.each |c| { c.verify }

    // apply to in-memory data models and lookup tables
    try
    {
      diffs = commits.map |c->Diff| { c.apply }
    }
    catch (Err e)
    {
      log.err("Commit failed", e)
      throw e
    }

    // update our lastMod if peristent batch of diffs
    if (persistent) lastModRef.val = newMod

    // if adding more than one rec at once, refresh ref dis
    if (newIds != null && newIds.size > 1) folio.disMgr.updateAll

    return CommitFolioRes(diffs)
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  internal const ConcurrentMap byId    // mutate only by Commit on this thread
}


