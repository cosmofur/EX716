---

# Lesson10 – Heap Management Basics

In this lesson we introduce **dynamic memory management** with the EX716 heap system. Unlike the fixed stack, the heap allows you to **allocate, free, and reuse memory blocks at runtime**. This makes it possible to build flexible data structures like strings, tables, or event queues.

The heap manager works by keeping **headers** before each allocated object. These headers track:

* Whether the block is free or in use
* The pointer to the next block
* The size of the current block (derived by looking at the next one)

---

## Heap Manager API (beginner subset)

We will start with just four functions:

* **`HeapDefineMemory(Address, SizeInBytes):HeapID`**
  Initializes a region of memory for heap use. Returns a `HeapID` (a pointer to the heap control block).

* **`HeapNewObject(HeapID, SizeInBytes):ObjectID`**
  Allocates a new block of memory. Returns an `ObjectID` (pointer to the data portion).

* **`HeapDeleteObject(HeapID, ObjectID):Status`**
  Frees a block of memory. Automatically runs defragmentation to merge adjacent free blocks.

* **`HeapListMap(HeapID)`**
  Diagnostic tool. Prints all objects in the heap, showing which are in use `(X)` or free `( )`, their sizes, and their “next object” pointers.

Later lessons will add:

* **`HeapResizeObject`**, **`HeapAppend`**, and **GetObjectRealSize** for advanced use.

---

## Demo Program: Heap Playground

Cut and paste this program into your assembler. It defines a heap, allocates a few objects, frees one, and then inspects the result.

```asm
I common.mc
L heapmgr.ld     # provides HeapDefineMemory, HeapNewObject, HeapDeleteObject, HeapListMap

@LocalVar MyHeap  01
@LocalVar Obj1    02
@LocalVar Obj2    03

:DemoHeap
  @PUSH 0x8000 @PUSH 256
  @CALL HeapDefineMemory
  @POPI MyHeap
  @PRT "Heap created at 0x8000 size 256" @PRTNL

  # Allocate 16-byte object
  @PUSHI MyHeap @PUSH 16
  @CALL HeapNewObject
  @POPI Obj1
  @PRT "Allocated Obj1 at:" @PRTHEXI Obj1 @PRTNL

  # Allocate 32-byte object
  @PUSHI MyHeap @PUSH 32
  @CALL HeapNewObject
  @POPI Obj2
  @PRT "Allocated Obj2 at:" @PRTHEXI Obj2 @PRTNL

  # Print heap state
  @PUSHI MyHeap
  @CALL HeapListMap

  # Free Obj1
  @PUSHI MyHeap @PUSHI Obj1
  @CALL HeapDeleteObject
  @PRT "Freed Obj1" @PRTNL

  # Print heap state again
  @PUSHI MyHeap
  @CALL HeapListMap

@RET
```

---

## Example Output

```
Heap created at 0x8000 size 256
Allocated Obj1 at: 0x8007
Allocated Obj2 at: 0x8018
Object: 0x8007 (X) Size(0x0010) Next ID->0x8018
Object: 0x8018 (X) Size(0x0020) Next ID->0000
Freed Obj1
Object: 0x8007 ( ) Size(0x0010) Next ID->0x8018
Object: 0x8018 (X) Size(0x0020) Next ID->0000
```

---

## Exercises for Students

1. Modify the demo to allocate three objects in a row (sizes 8, 24, 40).
   Use `HeapListMap` to observe how the heap grows.

2. Free the middle object and then call `HeapDeleteObject`.
   What happens to the heap map?

3. Try requesting an object larger than the heap can hold (e.g. 400 bytes).
   What error code do you get?

4. Change the heap start address from `0x8000` to `0x9000` and rerun.
   Does anything change in the diagnostic output besides addresses?

---

## Summary

* The heap allows **dynamic allocation** of objects at runtime.
* Objects carry **headers** that track their status and link them together.
* The **list map** is your best friend for debugging heap state.
* Later lessons will add resizing and appending, which build on this foundation.

---

