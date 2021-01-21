using System;
using System.Reflection;
public class TestClass
{
    public static void Main(string[] args)
    {
        string dllPath = "C:/users/user/desktop/NET.dll";
        Assembly asm = Assembly.LoadFile(dllPath);
        //Console.WriteLine(asm.CodeBase);
        Type t = asm.GetType("aaa");
        object instance = Activator.CreateInstance(t);
        
        //MethodInfo method = t.GetMethod("bbb");  // 注释的两条和下面的那条未注释的等价
        //object result = method.Invoke(instance, null); 
        object result = instance.GetType().GetMethod("bbb").Invoke(instance, null);
    }
}

// C:\Windows\Microsoft.NET\Framework\v2.0.50727\csc.exe -out:NET_REFLECT.exe dllreflect_cs.cs
// C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe -out:NET_REFLECT.exe dllreflect_cs.cs