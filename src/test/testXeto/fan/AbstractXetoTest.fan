//
// Copyright (c) 2023, Brian Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   1 Mar 2023  Brian Frank  Creation
//

using util
using xeto
using xeto::Dict
using xeto::Lib
using haystack
using xetoEnv

**
** AbstractXetoTest
**
@Js
class AbstractXetoTest : HaystackTest
{
  Void verifyAllEnvs(Str lib, |XetoEnv| f)
  {
    // first test local
    envRef = XetoEnv.cur
    verifyEq(env.isRemote, false)
    env.lib(lib)
    f(env)

    // test remote
    envRef = initRemote
    verifyEq(env.isRemote, true)

    // make sure sure lib is loaded
    env.libAsync(lib) |e, x|
    {
      if (e != null) throw e
      f(env)
    }
  }

  XetoEnv env()
  {
    if (envRef == null) envRef = XetoEnv.cur
    return envRef
  }

  private XetoEnv? envRef

  Lib compileLib(Str s) { env.compileLib(s) }

  Obj? compileData(Str s) { env.compileData(s) }

  static Dict nameDictEmpty() { MNameDict.empty }

  RemoteEnv initRemote()
  {
    local := XetoEnv.cur
    server := TestTransport.makeServer(local)
    client := TestTransport.makeClient(server)

    envRef = client.bootRemoteEnv

    verifyEq(env.names.maxCode, local.names.maxCode)
    verifyEq(env.names.toName(3), local.names.toName(3))
    verifyEq(env.names.toName(env.names.maxCode), local.names.toName(env.names.maxCode))

    return env
  }
}

**************************************************************************
** TestTransport
**************************************************************************

@Js
const class TestTransport : XetoTransport
{
  new makeServer(MEnv env) : super(env) {}

  new makeClient(TestTransport server) : super.makeClient() { this.server = server }

  const TestTransport? server

  RemoteEnv bootRemoteEnv()
  {
    buf := Buf()
    libs := server.env.registry.list.findAll { it.isLoaded }.map { it.get }
    XetoBinaryWriter(server, buf.out).writeBoot(libs)
    // echo("--- init remote bootstrap size = $buf.size bytes ---")
    return XetoBinaryReader(this, buf.flip.in).readBoot
  }

  override Void loadLib(Str name, |Err?, Lib?| f)
  {
    serverLib := server.env.lib(name, false)
    if (serverLib == null) { f(UnknownLibErr(name), null); return }

    buf := Buf()
    XetoBinaryWriter(server, buf.out).writeLib(serverLib)
    echo("   --- load lib $name size = $buf.size bytes ---")

    clientLib := XetoBinaryReader(this, buf.flip.in).readLib
    f(null, clientLib)
  }
}

