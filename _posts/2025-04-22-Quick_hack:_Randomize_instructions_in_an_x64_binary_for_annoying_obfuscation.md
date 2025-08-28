---
layout: default
title:  "Quick hacks: Randomize order of instructions in an x64 binary for annoying obfuscation"
date:   Tue 22 Apr 2025 03:35:12 PM CEST 
---

# Randomize the order of instructions in an x64 binary for annoying obfuscation

Welcome, dear reader, to the new episode of: "quick hacks", where we show off
hacks you can pull off yourself in less than 24 hours.

Abandon all hope of code quality, organized results, or deep understanding of what's going on: this is
just the fastest way I found to get what I wanted. Similar in spirit to a ctf writeup, more or less.


## backstory

I wanted to make a cursed rev challenge for LakeCTF finals 2025 :)

## cursed obfuscation

This is the code we want to end up with:

![]({{site.baseurl}}/assets/2025-04-22_15:37:37.png)

`sp-analysis failed`: yeah, that's exactly what we want to see. This was a ~400 lines C code that generated
1600 out-of-order functions.

## How to do it?

We're going to use an old friend of mine, [retrowrite](https://github.com/hexhive/retrowrite).
It's a binary rewriter that generates symbolized assembly. We can just edit the assembly, adding instructions
wherever we want, as assembly labels will take care of resolving references correctly.

Retrowrite supports instrumentation passes, and it's very easy to write them.
This is the instrumentation pass I wrote to randomize the order of functions:


```python
from librw_x64.container import (DataCell, InstrumentedInstruction, DataSection, Function)
class Instrument():
    def __init__(self, rewriter):
        self.rewriter = rewriter

    def do_instrument(self):
        for faddr, fn in self.rewriter.container.functions.items():
            for idx, instruction in enumerate(fn.cache):
                if idx < len(fn.cache) - 1:
                    next_instruction_addr = fn.cache[idx + 1].address
                    enter_lbl = "make_it_cursed_%x" % (instruction.address)

                    instrumentation = f"""
                    jmp .L{next_instruction_addr:x}
                    """.strip()
                    comment = "{}: ".format(str(instruction))
                    instruction.instrument_after(InstrumentedInstruction(instrumentation, enter_lbl, comment))
            # now randomize everything except the first and last instruction
            to_randomize = fn.cache[1:-1]
            random.shuffle(to_randomize)
            fn.cache[1:-1] = to_randomize
```

Basically, we are adding a `jmp` instruction *after* each instruction, pointing to whatever label `next_instruction` has. 

Then, we just `random.shuffle` all instructions (well except the first one and the last one). You can probably get away with randomizing the last one too. 

It's very impressive how easy it is to implement this thanks to Retrowrite and symbolized assembly.

## Not enough

Unfortunately, most decompilers will figure control flow out anyway and decompile correctly. 
The easiest way to break all their assumptions is to substitute jumps with calls. However, we'll also need
to fix the stack here and there:


```python
from librw_x64.container import (DataCell, InstrumentedInstruction, DataSection, Function)

class Instrument():
	def __init__(self, rewriter):
		self.rewriter = rewriter
	def do_instrument(self):
		for faddr, fn in self.rewriter.container.functions.items():
			if len(fn.cache) < 4: continue
			for idx, instruction in enumerate(fn.cache):
				if idx < len(fn.cache) - 2:
					next_instruction_addr = fn.cache[idx + 1].address
					enter_lbl = "make_it_cursed_%x" % (instruction.address)

					instrumentation = f"""
					leaq -0x2000(%rsp), %rsp
					call .LCR{next_instruction_addr:x}
					""".strip()
					comment = "{}: ".format(str(instruction))
					instruction.instrument_after(InstrumentedInstruction(instrumentation, enter_lbl, comment))
				if idx > 0:
					enter_lbl = "fix_stack_%x" % (instruction.address)
					instrumentation = f"""
					jmp .LCF{instruction.address:x}
					.LCR{instruction.address:x}:
					leaq 0x2008(%rsp), %rsp
					.LCF{instruction.address:x}:
					""".strip()
					comment = "{}: ".format(str(instruction))
					instruction.instrument_before(InstrumentedInstruction(instrumentation, enter_lbl, comment))

			# the stack should now be fixed
			# now we can randomize everything except the first and last instruction
			instructions = fn.cache[1:-1]
			random.shuffle(instructions)
			fn.cache[1:-1] = instructions
```

This is slightly more complex. We need to instrument before each instruction to fix the stack shenanigans that
the `call` instruction is going to cause.
We move the stack by 0x2008 each time as the compiler might use the stack space for local variables we don't want
to overwrite with our return address :)

Finally, we add a `jmp .LCF` to avoid re-adjusting the stack in case we got here from somewhere else than a call
(e.g., a conditional jmp).



---

<br>

If you liked this hack, make sure to hit me up and meet me at next year's camp
(WHY 2025). I might do a talk about this :D

If you are interested in Retrowrite, I did a talk at CCC explaining how it works
(the arm64 part), you can find it [here](https://media.ccc.de/v/37c3-12254-armore_pushing_love_back_into_binaries)

The x64 part is showcased in another CCC talk by nspace (Matteo Rizzo) and gannimo (Mathias Payer) that 
can be found [here](https://media.ccc.de/v/36c3-10880-no_source_no_problem_high_speed_binary_fuzzing)
