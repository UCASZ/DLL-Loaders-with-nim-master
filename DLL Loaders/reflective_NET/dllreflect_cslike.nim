import winim/clr

const code = """
  using System;
  using System.Reflection;
  public class TestClass
  {
      public static void myFunc(string dllPath)
      {
          Assembly asm = Assembly.LoadFile(dllPath);
          Type t = asm.GetType("aaa");
          MethodInfo method = t.GetMethod("bbb");
          object instance = Activator.CreateInstance(t);
          object result = method.Invoke(instance, null);
      }
  }
"""

proc csembed_reflection(dllPath: string): void = 
  echo "[*] Compiling the C# code "
  var res = compile(code)
  if res.Errors.Count != 0:
    for error in res.Errors:
      echo error
  
  echo "[*] Invoking a static method."
  var TestClass = res.CompiledAssembly.new("TestClass")
  TestClass.myFunc(dllPath)
  echo "[+] Succeeded"

when isMainModule:
  let dllPath = "C:/users/user/desktop/NET.dll"
  csembed_reflection(dllPath)

# nim c -r dllreflect_cslike.nim