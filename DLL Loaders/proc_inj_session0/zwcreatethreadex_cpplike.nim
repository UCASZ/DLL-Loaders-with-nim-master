### zwcreatethreadex_cpplike.nim内容
{.emit:"""
#include <Windows.h>
#include <stdio.h>

#ifdef _WIN64
typedef DWORD(WINAPI* typedef_ZwCreateThreadEx)(
	PHANDLE ThreadHandle,
	ACCESS_MASK DesiredAccess,
	LPVOID ObjectAttributes,
	HANDLE ProcessHandle,
	LPTHREAD_START_ROUTINE lpStartAddress,
	LPVOID lpParameter,
	ULONG CreateThreadFlags,
	SIZE_T ZeroBits,
	SIZE_T StackSize,
	SIZE_T MaximumStackSize,
	LPVOID pUnkown);
#else
typedef DWORD(WINAPI* typedef_ZwCreateThreadEx)(
	PHANDLE ThreadHandle,
	ACCESS_MASK DesiredAccess,
	LPVOID ObjectAttributes,
	HANDLE ProcessHandle,
	LPTHREAD_START_ROUTINE lpStartAddress,
	LPVOID lpParameter,
	BOOL CreateSuspended,
	DWORD dwStackSize,
	DWORD dw1,
	DWORD dw2,
	LPVOID pUnkown);
#endif

// myFunc实质上就是找到并调用ZwCreateThreadEx函数
void myFunc(HANDLE PHandle, LPTHREAD_START_ROUTINE covPFuncProcAddr, LPVOID pDllAddr){
    HANDLE hNtModule = GetModuleHandleA("ntdll.dll");
    PHANDLE hRemoteThread;
    typedef_ZwCreateThreadEx ZwCreateThreadEx = GetProcAddress(hNtModule, "ZwCreateThreadEx");
    ZwCreateThreadEx(hRemoteThread, PROCESS_ALL_ACCESS, NULL, PHandle, covPFuncProcAddr, pDllAddr, 0, 0, 0, 0, NULL);
}
""".}