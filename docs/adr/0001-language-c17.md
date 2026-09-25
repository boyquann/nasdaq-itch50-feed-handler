## Why C rather than any other language?
### Context
The decision to use C as the language came down to the language surface. Nothing happens that I did not write: no hidden copies, no implicit allocations, no templates. It is easier to predict exactly what machine code will be generated, and it compiles fast.
### Options Considered
The obvious alternative was C++ and, no doubt, C++ wins against C based on merit for this particular work. Feed Handlers are full of integers that are meaningfully different, such as prices, share counts, order references, locate codes, nanosecond timestamps, etc., and  C's type system **typedef** is only an alias. ```typedef uint32_t price_t``` and ```typedef uint32_t shares_t``` are practically the same type to the compiler, meaning that passing shares where a price belongs will compile silently but fail at runtime. C++ would allow the wrapping of each one into distinct types (Price, Shares, OrderRef) with no runtime overhead at all, so mixing them up shows up as a compile error. The reason this work is not written in C++ comes down to a lack of fluency in the language at this present time.

### Decision
C is the chosen language for this work

## Why C17 rather than earlier versions like C99, C11 or C23?
### Context
Choosing C17 came down to ensuring C11 features this work depends on are accessible. Features such as ```<stdatomic.h>``` and ```_Atomic``` for the SPSC ring, ```alignas``` for the cache-line separation of ```head``` and ```tail```, and ```_Static_assert``` to lock the order record at 32 bytes.

### Options Considered
C99 has none of those features, and this work does not require any feature from C23. C17 trumps C11 because C17 is the revised version of C11.

### Decision
C17 is the clear choice.

## Consequences
- All system work is visible and explicit
- This work proves nothing about the C++ standard library, RAII, templates, or move semantics.
