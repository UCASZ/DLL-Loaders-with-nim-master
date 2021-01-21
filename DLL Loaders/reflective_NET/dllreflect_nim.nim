import winim/clr

proc dllReflect(dllPath: string): void =
  echo "[*] Start reflecting... "
  let dll = load(dllPath)
  var popCalc = dll.GetType("aaa")
  #@popCalc.bbb() ## 方法一
  @popCalc.invoke("bbb", BindingFlags_InvokeMethod or BindingFlags_Default) ## 方法二
  echo "[+] Succeeded"
  
when isMainModule:
  dllReflect("C:/users/user/desktop/NET.dll")

# nim c -r dllreflect_nim.nim