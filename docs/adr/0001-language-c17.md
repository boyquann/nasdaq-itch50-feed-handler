Why C rather than any other language?
The decision of using C as the language came down to is the language surface. Nothing happens that I did not write: no hidden copies, no implcit allocations, no templates. It is easier to predict exactly what machine code will be generated and it compiles fast.
The obvious alternatives was C++ and no doubt, C++ wins against C based on merit for this particular work. Feed Handlers are full of integers that are meaningfully different, such as, prices, share counts, order references, locate codes, nanosecond timestamps..etc, and  C's type system **typedef** is only an alias. 'typedef uint32_t price_t' and typedef uint32_t shares_t' are practically the same type to the compiler, meaning that passing shares where a price belongs will compile silently but fail in runtime. C++ would allow the wrapping of each one into distinct types (Price, Shares, OrderRef) with no runtime overhead at all so mixing them up shows up as a compile error. The reason this work is not written in C++ comes down to lack of fluency in the language at this present time.

Why C17 rather than over versions like C99, C11 or C23?
Choosing C17 came down to making sure C11 features that this work depends on are accessible. Features such as '<stdatomic.h>' and '_Atomic' for SPSC ring, alignas for the cache-line seperation of 'head' and 'tail', _Static_assert to lock the order record at 32 bytes.

C99 has none of those features and this work does not require any feature from C23. C17 trumps C11 because C17 is the revised version of C11.
