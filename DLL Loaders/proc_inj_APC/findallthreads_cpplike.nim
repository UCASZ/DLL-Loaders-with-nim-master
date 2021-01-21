{.emit: """
#include <stdio.h>
#include <windows.h>
#include <tlhelp32.h>
#include <vector>
//#include <tchar.h>
using namespace std;

vector<DWORD>Array;
int i = 0;

int findAllThreads(DWORD dwProcessId, BOOL size)
{
	DWORD dwBufferLength = 1000;
	THREADENTRY32 te32 = { 0 };
	HANDLE hSnapshot = NULL;
	BOOL bRet = TRUE;

    if (size)
        return Array[i++];

	// 获取线程快照
	::RtlZeroMemory(&te32, sizeof(te32));
	te32.dwSize = sizeof(te32);
	hSnapshot = ::CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
	// 获取第一条线程快照信息
	bRet = ::Thread32First(hSnapshot, &te32);
	while (bRet){
		// 获取进程对应的线程ID
		if (te32.th32OwnerProcessID == dwProcessId){
			//_tprintf( TEXT("\n     THREAD ID      = 0x%08X"), te32.th32ThreadID );
            Array.push_back(te32.th32ThreadID);
		}
		// 遍历下一个线程快照信息
		bRet = ::Thread32Next(hSnapshot, &te32);
	}
    return Array.size();
}
""".}