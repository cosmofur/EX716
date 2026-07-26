# EX716 Assembler – Lesson 11: Heap Management Basics

In this lesson we introduce **dynamic memory management** with the EX716 heap system.  
Unlike the fixed stack, the heap allows you to **allocate, free, and reuse memory blocks at runtime**.  
This makes it possible to build flexible data structures like strings, tables, or event queues.

---

## 🎯 Goals

1. Understand how the EX716 heap manager organizes memory.
2. Learn the role of object headers in tracking allocations.
3. Explore the logic of the allocator (`HeapNewObject`).
4. Visualize how the heap grows and shrinks as objects are allocated and freed.

---

## 📦 Object Headers

Every allocated block carries a **3-byte object header** immediately *before* the usable data.

```text
ObjectID[-3] FLAG byte (0 = free, 1 = used)
ObjectID[-2] NEXT word (pointer to next object, or 0 if end of chain)
ObjectID[ 0] start of usable data
```

The heap itself also has a **4-byte heap header** before the first object. It stores the pointer to the first object and the total heap size.

This means an `ObjectID` is always the address of the **first usable byte** —  
but you can step backwards to read its flag or next-pointer.

---

## 🛠 Heap Manager API (beginner subset)

For now, we will use just four functions:

* **`HeapDefineMemory(Address, SizeInBytes):HeapID`**  
  Initializes a region of memory for heap use. Returns a `HeapID` (a pointer to the heap control block).

* **`HeapNewObject(HeapID, SizeInBytes):ObjectID`**  
  Allocates a new block of memory. Returns an `ObjectID` (pointer to the data portion).

* **`HeapDeleteObject(HeapID, ObjectID):Status`**  
  Frees a block of memory. Automatically runs defragmentation to merge adjacent free blocks.

* **`HeapListMap(HeapID)`**  
  Diagnostic tool. Prints all objects in the heap, showing which are in use, their sizes, and their “next object” pointers.

Two other useful helpers appear often in real programs:

* **`HeapResizeObject(HeapID, ObjectID, NewSizeInBytes):ObjectID`**  
  Attempts to grow or shrink an existing object.

* **`HeapAvailable(HeapID):FreeBytes`**  
  Reports free heap space.

---

## 🔎 Inside the Logic

At a high level, `HeapNewObject` works like this:

```text
1. Start at the first object in the chain.
2. While not at end of chain:
   a. If block is free AND size >= requested:
      - Use this block.
      - If leftover space is big enough, split it.
      - Mark block as used.
      - Return pointer.
   b. Else: move to next block.
3. If no block was big enough:
   a. Check if unused space remains at heap tail.
   b. If yes, create a new block there and return it.
   c. Otherwise fail with error code.

Error codes:
2 - request larger than heap size
3 - no room at heap tail
```

## 🖼 Visualizing the Heap

Let’s walk through a short demo:

```text
Initial:
[Heap Start] -> [Free 256 bytes] -> [End]

After allocating Obj1 (16 bytes):
[Obj1 16 used] -> [Free 240 bytes] -> [End]

After allocating Obj2 (32 bytes):
[Obj1 16 used] -> [Obj2 32 used] -> [Free 208 bytes] -> [End]

After deleting Obj1:
[Obj1 16 free] -> [Obj2 32 used] -> [Free 208 bytes] -> [End]
```

You can see how the headers keep the chain intact.

## 🧩 Helper Constants

Internally, the heap library uses constants to make header access clearer:

```asm
=OBJ_FLAG_LOC  3
=OBJ_NEXT_LOC  2
=OBJ_HEAD_SIZE 3
=HEAP_SIZE_LOC 2
=HEAP_FIRST_OBJ_LOC 0
=HEAP_HEAD_SIZE 4

# Fetch allocation flag
@PUSHI ObjectID
@SUB OBJ_FLAG_LOC
@PUSHS
@AND 0xff

# Fetch next-object pointer
@PUSHI ObjectID
@SUB OBJ_NEXT_LOC
@PUSHS
```

So when you see code testing `ObjectID - OBJ_FLAG_LOC`, it is checking whether this block is free or in use.

## 🐣 Demo Program: Heap Playground
Cut and paste this program into your assembler.
It defines a heap, allocates a few objects, frees one, and then inspects the result.

```asm
I common.mc
L heapmgr.ld     # provides HeapDefineMemory, HeapNewObject, HeapDeleteObject, HeapListMap


:DemoHeap
  @PUSHRETURN
  @Locals
  @Local MyHeap
  @Local Obj1
  @Local Obj2
  @Call(AA) HeapDefineMemory 0x8000 256
  @POPI MyHeap
  @PRT "Heap created at 0x8000 size 256" @PRTNL

  # Allocate 16-byte object
  @Call(VA) HeapNewObject MyHeap 16
  @POPI Obj1
  @PRT "Allocated Obj1 at:" @PRTHEXI Obj1 @PRTNL

  # Allocate 32-byte object
  @Call(VA) HeapNewObject MyHeap 32
  @POPI Obj2
  @PRT "Allocated Obj2 at:" @PRTHEXI Obj2 @PRTNL

  # Print heap state
  @Call(V) HeapListMap MyHeap

  # Free Obj1
  @Call(VV) HeapDeleteObject MyHeap Obj1
  @PRT "Freed Obj1" @PRTNL

  # Print heap state again
  @Call(V) HeapListMap MyHeap

  @EndLocals
  @POPRETURN
@RET
```

## 🖥 Example Output

```text
Heap created at 0x8000 size 256
Allocated Obj1 at: 0x8007
Allocated Obj2 at: 0x8018
Object: 0x8007 (X) Size(0x0010) Next ID->0x8018
Object: 0x8018 (X) Size(0x0020) Next ID->0000
Freed Obj1
Object: 0x8007 ( ) Size(0x0010) Next ID->0x8018
Object: 0x8018 (X) Size(0x0020) Next ID->0000
```

## ✍️ Exercises for Students
- Modify the demo to allocate three objects in a row (sizes 8, 24, 40). Use `HeapListMap` to observe how the heap grows.
- Free the middle object and then call `HeapDeleteObject`. What happens to the heap map?
- Try requesting an object larger than the heap can hold, such as 400 bytes. What error code do you get?
- Change the heap start address from `0x8000` to `0x9000` and rerun. Does anything change in the diagnostic output besides addresses?

## ✅ Summary

- The heap allows dynamic allocation of objects at runtime.
- Objects carry headers that track their status and link them together.
- The list map is your best friend for debugging heap state.


