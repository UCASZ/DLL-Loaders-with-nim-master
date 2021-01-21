import dynlib

type
  PopCalc = proc(): void {.nimcall.}

proc execDll(path:string) =
  echo "[*] Start executing the function in dll ... "
  let lib = loadLib(path)
  if lib != nil:
    var pAddr = lib.symAddr("popCalc")
    if pAddr != nil:
      var popCalc = cast[PopCalc](pAddr)
      popCalc()
      echo "[+] Succeeded"
    unloadLib(lib)

when isMainModule:
  execDll("C:/users/user/desktop/new_malicious.dll") 

# nim c -r exec.nim