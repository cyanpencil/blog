+++
date = "1970-01-01T01:00:00+01:00"
draft = true
title = "r2 API usage. ITrace, a practical case"
slug = "r2-api-usage-itrace-a-practical-case"
aliases = [
	"r2-api-usage-itrace-a-practical-case"
]
+++
In this article we'll explain some of the *r_anal* features through the creation of a small tool that we will call "itrace", which is mainly focused on tracing/hooking of imports execution based on *LD_PRELOAD* + global hooking. This presentation was done at the *rooted'10* con, so you can give a look at the [slides]( http://radare.org/get/r2ted.pdf ) if you want a quick summary and [source]( http://radare.org/get/itrace_update.tar.gz ) to test it.

Imagine the following scenario, we have a binary and we want to trigger an event each time that an import is called. Obviously, we could hook all the imports and exec whatever we want preloading a library coded by us with *LD_PRELOAD*, but this aproximation has a very big problem: the imports used by each target binary will change, so we would need to code a library adapted to each binary every time.

What we want is a generic way for patching the binary and a simple & quick way for coding our "hijacked lib". Ok, so now that we know what we want and the troubles behind it, we can go ahead with a soulution.

The main idea is to patch all import entries but one in the PLT, doing all of them to call a "hook handler" located in the init routine. This handler will call the non-patched import, that is exactly the same that we have not patched in the PLT (to avoid an infinite loop). And is precisely this one, the hijacked function implemented in our LD_PRELOADed lib.

Lets sum up:


1. Analyze entrypoint
    1. Get init address
2. Patch all plt entries but hijacked import to call our hook handler
3. Write Hook code into init
    1. Push interesting parameters
    2. Call hijacked import
    3. Fix stack
    4. Jump to the first PLT entry
4. LD_PRELOAD library containing hijacked import


The first thing we have to do is to load the binary with *r_bin*:
```
if (!r_bin_load (bin, file, R_FALSE)) {
    fprintf (stderr, "Cannot open file '%s'\n", file);
    return 1;
}
```
Now that the info has been extracted from the headers we get the base address for future calculations of VA's from VADDR's:

```
baddr = r_bin_get_baddr (bin);
```
quite easy, huh? :) Ok, to find out where is the entrypoing and the
libc_start_main stub we use the *r_bin* API:

```
/* Entrypoint Offset & VA */
if ((entry = r_list_get_n (r_bin_get_entries (bin), 0)) != NULL) {
    entry_va = baddr + entry->vaddr;
    entry_off = entry->paddr;
}
if (entry_va == -1 || entry_off == -1) {
    fprintf (stderr, "Error: Cannot find entrypoint\n");
    return 1;
}

/* libc_start_main VA */
r_list_foreach (r_bin_get_imports (bin), iter, imp)
    if (!strcmp (imp->name, "__libc_start_main")) {
        libc_main_va = baddr + imp->vaddr;
        break;
    }
if (libc_main_va == -1) {
    fprintf (stderr, "Error: Cannot find __libc_start_main\n");
    return 1;
}
```

Maybe, you are wondering why we need to know the VA of libc_start_main... We said that we wanted to inject the hook handler overwriting the init routine of the target binary, so we need to discover where is init.

If we closely look at the entrypoint of a binary compiled with gcc:
```
0x08048340    31ed          xor ebp, ebp
0x08048342    5e            pop esi
0x08048343    89e1          mov ecx, esp
0x08048345    83e4f0        and esp, 0xfffffff0
0x08048348    50            push eax
0x08048349    54            push esp
0x0804834a    52            push edx
0x0804834b    6840840408    push dword 0x8048440 ; libc_csu_fini
0x08048350    6850840408    push dword 0x8048450 ; libc_csu_init
0x08048355    51            push ecx
0x08048356    56            push esi
0x08048357    68f4830408    push dword 0x80483f4 ; main
0x0804835c    e8abffffff    call dword imp.__libc_start_main
```
*libc_csu_init* is pushed at 0x08048350 for passing its pointer as argument to *libc_start_main*, which is who will call it before executing main. The algorithm for getting the init address is fairly easy, we will analyze each opcode of the entrypoint storing the immediate values of "PUSH imm" into an array, and when we find a call to libc_start_main (that's why we need its VA) we will extract the address from our array of imm values.

```
/* Configure r_anal */
r_anal_use (anal, "x86");
r_anal_set_bits (anal, 32);

/* Analyze entrypoint a get init va */
bytes = malloc (MAX_ENTRY_SZ);
r_buf_read_at (bin->curarch.buf, entry_off, bytes, MAX_ENTRY_SZ);
while (i < MAX_ENTRY_SZ) {
    if ((oplen = r_anal_op (anal, aop, entry_va+i, bytes+i, MAX_ENTRY_SZ-i)) == 0)
        break;
    i += oplen;
    if (aop->type == R_ANAL_OP_TYPE_PUSH) {
        args[j++] = aop->value;
    } else if (aop->type == R_ANAL_OP_TYPE_CALL) {
        if (aop->jump == libc_main_va && j > 2) {
            init_va = args[j-2];
            init_off = init_va - baddr;
        }
    } else if (aop->type == R_ANAL_OP_TYPE_RET) {
        entry_sz = i;
        break;
    }
}
free (bytes);
if (entry_sz == -1 || init_va == -1 || init_off == -1) {
    fprintf (stderr, "Error: Cannot analyze entrypoint\n");
    return 1;
}
```

At this point, we can patch each import entry but the selected one to call the handler.

```
/* Configure r_asm */
r_asm_use (a, "x86.olly");
r_asm_set_bits (a, 32);

/* Patch imports */
bytes = malloc (PUSH_SZ);
r_list_foreach (r_bin_get_imports (bin), iter, imp)
    if (!strcmp (imp->name, import)) {
        import_va = baddr + imp->vaddr;
    } else if (!strcmp (imp->type, "FUNC")) {
        r_asm_set_pc (a, baddr + imp->vaddr + PUSH_SZ);
        code = r_str_dup_printf ("call 0x%08llx", init_va + RET_SZ);
        acode = r_asm_massemble(a, code);
        r_buf_read_at (bin->curarch.buf,
                imp->paddr + PUSH_OFF, bytes, PUSH_SZ);
        r_buf_write_at (bin->curarch.buf,
                imp->paddr, bytes, PUSH_SZ);
        r_buf_write_at (bin->curarch.buf,
                imp->paddr + PUSH_SZ, acode->buf, acode->len);
        free (code);
    }
free (bytes);
if (import_va == -1) {
    fprintf (stderr, "Error: Cannot find import '%s'\n", import);
    return 1;
}
```

Finally, we write the handler at init. We assemble it with *r_asm* and then it is written with *r_buf*, the handler code is explained in the comments:

```
/* Get the plt VA */
r_list_foreach (r_bin_get_sections (bin), iter, scn)
    if (!strcmp (scn->name, ".plt")) {
        plt_va = baddr + scn->vaddr;
        break;
    }
if (plt_va == -1) {
    fprintf (stderr, "Error: Cannot find plt\n");
    return 1;
}

/* Assemble hook handler and write it to init */
r_asm_set_pc (a, init_va);
code = r_str_dup_printf (
        /* return when it is called from libc_start_main */
        "ret;"
        /* calulate the address of the import which is calling it */
        "pop eax;"
        "sub eax, 0xa;"
        /* pass the import address as arg to the hijacked function */
        "push eax;"
        /* pass a "magic" to recognize that this is a detour */
        "push 0x1337;"
        /* call the hijacked import */
        "call 0x%08llx;"
        /* Fix the stack */
        "add esp, 8;"
        "jmp 0x%08llx", import_va, plt_va);  /* jmp to the first plt entry */
acode = r_asm_massemble(a, code);
r_buf_write_at (bin->curarch.buf, init_off, acode->buf, acode->len);
free (code);
```
And...
```
r_bin_wr_output (bin, "a.out");
```
... we write everything to disk. Done! :D 

Let's try it with a little example, we have the following test program:

```
#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv) {
    int i;

    for (i = 0; i < 10; i++) {
        puts ("ROOTED!");
        sleep (1);
    }

    return 0;
}
```

We will hijack the sleep import, so we write the following lib:

```
#include <dlfcn.h>
#include <stdio.h>

#ifndef RTLD_NEXT
#define RTLD_NEXT ((void *)-1)
#endif

int sleep(unsigned int seconds, unsigned int addr, unsigned int imp) {
    static int (*__realsleep)(unsigned int seconds) = NULL;
    __realsleep = dlsym (RTLD_NEXT, "sleep");

    if (seconds == 0x1337) {
        printf ("Fake sleep call from import 0x%x @ 0x%x\n", imp, addr);
        return 0;
    }
    return __realsleep (seconds);
}
```

I think, it is self-explanatory, we will hijack the sleep and when the first arg is our "magic word" (you chan check in the handler that it is *0x1337*), we know that the call come from a detour and we execute whatever we want.

Of course, we can add as many args as we want. In fact, one of them is the import address, so we could execute different actions depending on the called import.

Ok, lets build it and see what happens:
```
$ gcc -o test -m32 test.c
$ gcc -o itrace `pkg-config --cflags --libs r_asm r_bin r_anal r_util` itrace.c
$ gcc -o preload.so -shared -fPIC -Wall -ldl -m32 preload.c
$ ./itrace test sleep
$ chmod 755 a.out
$ LD_PRELOAD=./preload.so ./a.out 
Fake sleep call from import 0x8 @ 0x804830c
Fake sleep call from import 0x18 @ 0x804832c
ROOTED!
Fake sleep call from import 0x18 @ 0x804832c
ROOTED!
Fake sleep call from import 0x18 @ 0x804832c
ROOTED!
Fake sleep call from import 0x18 @ 0x804832c
ROOTED!
^C
```

Enjoy! :D