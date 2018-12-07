
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax,%cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 79 11 f0       	mov    $0xf0117970,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 ff 37 00 00       	call   f0103867 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 a2 04 00 00       	call   f010050f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 00 3d 10 f0 	movl   $0xf0103d00,(%esp)
f010007c:	e8 86 2c 00 00       	call   f0102d07 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 19 11 00 00       	call   f010119f <mem_init>
	
	// Test the stack backtrace function (lab 1 only)

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 b0 07 00 00       	call   f0100842 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 79 11 f0 00 	cmpl   $0x0,0xf0117960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 79 11 f0    	mov    %esi,0xf0117960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 1b 3d 10 f0 	movl   $0xf0103d1b,(%esp)
f01000c8:	e8 3a 2c 00 00       	call   f0102d07 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 fb 2b 00 00       	call   f0102cd4 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 73 4c 10 f0 	movl   $0xf0104c73,(%esp)
f01000e0:	e8 22 2c 00 00       	call   f0102d07 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 51 07 00 00       	call   f0100842 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 33 3d 10 f0 	movl   $0xf0103d33,(%esp)
f0100112:	e8 f0 2b 00 00       	call   f0102d07 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 ae 2b 00 00       	call   f0102cd4 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 73 4c 10 f0 	movl   $0xf0104c73,(%esp)
f010012d:	e8 d5 2b 00 00       	call   f0102d07 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100148:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100149:	a8 01                	test   $0x1,%al
f010014b:	74 08                	je     f0100155 <serial_proc_data+0x15>
f010014d:	b2 f8                	mov    $0xf8,%dl
f010014f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100150:	0f b6 c0             	movzbl %al,%eax
f0100153:	eb 05                	jmp    f010015a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100155:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010015a:	5d                   	pop    %ebp
f010015b:	c3                   	ret    

f010015c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010015c:	55                   	push   %ebp
f010015d:	89 e5                	mov    %esp,%ebp
f010015f:	53                   	push   %ebx
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100165:	eb 2a                	jmp    f0100191 <cons_intr+0x35>
		if (c == 0)
f0100167:	85 d2                	test   %edx,%edx
f0100169:	74 26                	je     f0100191 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010016b:	a1 24 75 11 f0       	mov    0xf0117524,%eax
f0100170:	8d 48 01             	lea    0x1(%eax),%ecx
f0100173:	89 0d 24 75 11 f0    	mov    %ecx,0xf0117524
f0100179:	88 90 20 73 11 f0    	mov    %dl,-0xfee8ce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010017f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100185:	75 0a                	jne    f0100191 <cons_intr+0x35>
			cons.wpos = 0;
f0100187:	c7 05 24 75 11 f0 00 	movl   $0x0,0xf0117524
f010018e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100191:	ff d3                	call   *%ebx
f0100193:	89 c2                	mov    %eax,%edx
f0100195:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100198:	75 cd                	jne    f0100167 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010019a:	83 c4 04             	add    $0x4,%esp
f010019d:	5b                   	pop    %ebx
f010019e:	5d                   	pop    %ebp
f010019f:	c3                   	ret    

f01001a0 <kbd_proc_data>:
f01001a0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001a5:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	0f 84 f7 00 00 00    	je     f01002a5 <kbd_proc_data+0x105>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001ae:	a8 20                	test   $0x20,%al
f01001b0:	0f 85 f5 00 00 00    	jne    f01002ab <kbd_proc_data+0x10b>
f01001b6:	b2 60                	mov    $0x60,%dl
f01001b8:	ec                   	in     (%dx),%al
f01001b9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001bb:	3c e0                	cmp    $0xe0,%al
f01001bd:	75 0d                	jne    f01001cc <kbd_proc_data+0x2c>
		// E0 escape character
		shift |= E0ESC;
f01001bf:	83 0d 00 73 11 f0 40 	orl    $0x40,0xf0117300
		return 0;
f01001c6:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001cb:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001cc:	55                   	push   %ebp
f01001cd:	89 e5                	mov    %esp,%ebp
f01001cf:	53                   	push   %ebx
f01001d0:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001d3:	84 c0                	test   %al,%al
f01001d5:	79 37                	jns    f010020e <kbd_proc_data+0x6e>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001d7:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f01001dd:	89 cb                	mov    %ecx,%ebx
f01001df:	83 e3 40             	and    $0x40,%ebx
f01001e2:	83 e0 7f             	and    $0x7f,%eax
f01001e5:	85 db                	test   %ebx,%ebx
f01001e7:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001ea:	0f b6 d2             	movzbl %dl,%edx
f01001ed:	0f b6 82 a0 3e 10 f0 	movzbl -0xfefc160(%edx),%eax
f01001f4:	83 c8 40             	or     $0x40,%eax
f01001f7:	0f b6 c0             	movzbl %al,%eax
f01001fa:	f7 d0                	not    %eax
f01001fc:	21 c1                	and    %eax,%ecx
f01001fe:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
		return 0;
f0100204:	b8 00 00 00 00       	mov    $0x0,%eax
f0100209:	e9 a3 00 00 00       	jmp    f01002b1 <kbd_proc_data+0x111>
	} else if (shift & E0ESC) {
f010020e:	8b 0d 00 73 11 f0    	mov    0xf0117300,%ecx
f0100214:	f6 c1 40             	test   $0x40,%cl
f0100217:	74 0e                	je     f0100227 <kbd_proc_data+0x87>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100219:	83 c8 80             	or     $0xffffff80,%eax
f010021c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010021e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100221:	89 0d 00 73 11 f0    	mov    %ecx,0xf0117300
	}

	shift |= shiftcode[data];
f0100227:	0f b6 d2             	movzbl %dl,%edx
f010022a:	0f b6 82 a0 3e 10 f0 	movzbl -0xfefc160(%edx),%eax
f0100231:	0b 05 00 73 11 f0    	or     0xf0117300,%eax
	shift ^= togglecode[data];
f0100237:	0f b6 8a a0 3d 10 f0 	movzbl -0xfefc260(%edx),%ecx
f010023e:	31 c8                	xor    %ecx,%eax
f0100240:	a3 00 73 11 f0       	mov    %eax,0xf0117300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100245:	89 c1                	mov    %eax,%ecx
f0100247:	83 e1 03             	and    $0x3,%ecx
f010024a:	8b 0c 8d 80 3d 10 f0 	mov    -0xfefc280(,%ecx,4),%ecx
f0100251:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100255:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100258:	a8 08                	test   $0x8,%al
f010025a:	74 1b                	je     f0100277 <kbd_proc_data+0xd7>
		if ('a' <= c && c <= 'z')
f010025c:	89 da                	mov    %ebx,%edx
f010025e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100261:	83 f9 19             	cmp    $0x19,%ecx
f0100264:	77 05                	ja     f010026b <kbd_proc_data+0xcb>
			c += 'A' - 'a';
f0100266:	83 eb 20             	sub    $0x20,%ebx
f0100269:	eb 0c                	jmp    f0100277 <kbd_proc_data+0xd7>
		else if ('A' <= c && c <= 'Z')
f010026b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010026e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100271:	83 fa 19             	cmp    $0x19,%edx
f0100274:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100277:	f7 d0                	not    %eax
f0100279:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010027b:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010027d:	f6 c2 06             	test   $0x6,%dl
f0100280:	75 2f                	jne    f01002b1 <kbd_proc_data+0x111>
f0100282:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100288:	75 27                	jne    f01002b1 <kbd_proc_data+0x111>
		cprintf("Rebooting!\n");
f010028a:	c7 04 24 4d 3d 10 f0 	movl   $0xf0103d4d,(%esp)
f0100291:	e8 71 2a 00 00       	call   f0102d07 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100296:	ba 92 00 00 00       	mov    $0x92,%edx
f010029b:	b8 03 00 00 00       	mov    $0x3,%eax
f01002a0:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002a1:	89 d8                	mov    %ebx,%eax
f01002a3:	eb 0c                	jmp    f01002b1 <kbd_proc_data+0x111>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002a5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002aa:	c3                   	ret    
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002b0:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002b1:	83 c4 14             	add    $0x14,%esp
f01002b4:	5b                   	pop    %ebx
f01002b5:	5d                   	pop    %ebp
f01002b6:	c3                   	ret    

f01002b7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002b7:	55                   	push   %ebp
f01002b8:	89 e5                	mov    %esp,%ebp
f01002ba:	57                   	push   %edi
f01002bb:	56                   	push   %esi
f01002bc:	53                   	push   %ebx
f01002bd:	83 ec 1c             	sub    $0x1c,%esp
f01002c0:	89 c7                	mov    %eax,%edi
f01002c2:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002cc:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002d1:	eb 06                	jmp    f01002d9 <cons_putc+0x22>
f01002d3:	89 ca                	mov    %ecx,%edx
f01002d5:	ec                   	in     (%dx),%al
f01002d6:	ec                   	in     (%dx),%al
f01002d7:	ec                   	in     (%dx),%al
f01002d8:	ec                   	in     (%dx),%al
f01002d9:	89 f2                	mov    %esi,%edx
f01002db:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002dc:	a8 20                	test   $0x20,%al
f01002de:	75 05                	jne    f01002e5 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002e0:	83 eb 01             	sub    $0x1,%ebx
f01002e3:	75 ee                	jne    f01002d3 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002e5:	89 f8                	mov    %edi,%eax
f01002e7:	0f b6 c0             	movzbl %al,%eax
f01002ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ed:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002f2:	ee                   	out    %al,(%dx)
f01002f3:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f8:	be 79 03 00 00       	mov    $0x379,%esi
f01002fd:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100302:	eb 06                	jmp    f010030a <cons_putc+0x53>
f0100304:	89 ca                	mov    %ecx,%edx
f0100306:	ec                   	in     (%dx),%al
f0100307:	ec                   	in     (%dx),%al
f0100308:	ec                   	in     (%dx),%al
f0100309:	ec                   	in     (%dx),%al
f010030a:	89 f2                	mov    %esi,%edx
f010030c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010030d:	84 c0                	test   %al,%al
f010030f:	78 05                	js     f0100316 <cons_putc+0x5f>
f0100311:	83 eb 01             	sub    $0x1,%ebx
f0100314:	75 ee                	jne    f0100304 <cons_putc+0x4d>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100316:	ba 78 03 00 00       	mov    $0x378,%edx
f010031b:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010031f:	ee                   	out    %al,(%dx)
f0100320:	b2 7a                	mov    $0x7a,%dl
f0100322:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100327:	ee                   	out    %al,(%dx)
f0100328:	b8 08 00 00 00       	mov    $0x8,%eax
f010032d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010032e:	89 fa                	mov    %edi,%edx
f0100330:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100336:	89 f8                	mov    %edi,%eax
f0100338:	80 cc 07             	or     $0x7,%ah
f010033b:	85 d2                	test   %edx,%edx
f010033d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100340:	89 f8                	mov    %edi,%eax
f0100342:	0f b6 c0             	movzbl %al,%eax
f0100345:	83 f8 09             	cmp    $0x9,%eax
f0100348:	74 78                	je     f01003c2 <cons_putc+0x10b>
f010034a:	83 f8 09             	cmp    $0x9,%eax
f010034d:	7f 0a                	jg     f0100359 <cons_putc+0xa2>
f010034f:	83 f8 08             	cmp    $0x8,%eax
f0100352:	74 18                	je     f010036c <cons_putc+0xb5>
f0100354:	e9 9d 00 00 00       	jmp    f01003f6 <cons_putc+0x13f>
f0100359:	83 f8 0a             	cmp    $0xa,%eax
f010035c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100360:	74 3a                	je     f010039c <cons_putc+0xe5>
f0100362:	83 f8 0d             	cmp    $0xd,%eax
f0100365:	74 3d                	je     f01003a4 <cons_putc+0xed>
f0100367:	e9 8a 00 00 00       	jmp    f01003f6 <cons_putc+0x13f>
	case '\b':
		if (crt_pos > 0) {
f010036c:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f0100373:	66 85 c0             	test   %ax,%ax
f0100376:	0f 84 e5 00 00 00    	je     f0100461 <cons_putc+0x1aa>
			crt_pos--;
f010037c:	83 e8 01             	sub    $0x1,%eax
f010037f:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100385:	0f b7 c0             	movzwl %ax,%eax
f0100388:	66 81 e7 00 ff       	and    $0xff00,%di
f010038d:	83 cf 20             	or     $0x20,%edi
f0100390:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100396:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010039a:	eb 78                	jmp    f0100414 <cons_putc+0x15d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010039c:	66 83 05 28 75 11 f0 	addw   $0x50,0xf0117528
f01003a3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003a4:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003ab:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003b1:	c1 e8 16             	shr    $0x16,%eax
f01003b4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003b7:	c1 e0 04             	shl    $0x4,%eax
f01003ba:	66 a3 28 75 11 f0    	mov    %ax,0xf0117528
f01003c0:	eb 52                	jmp    f0100414 <cons_putc+0x15d>
		break;
	case '\t':
		cons_putc(' ');
f01003c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c7:	e8 eb fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d1:	e8 e1 fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003d6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003db:	e8 d7 fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e5:	e8 cd fe ff ff       	call   f01002b7 <cons_putc>
		cons_putc(' ');
f01003ea:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ef:	e8 c3 fe ff ff       	call   f01002b7 <cons_putc>
f01003f4:	eb 1e                	jmp    f0100414 <cons_putc+0x15d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003f6:	0f b7 05 28 75 11 f0 	movzwl 0xf0117528,%eax
f01003fd:	8d 50 01             	lea    0x1(%eax),%edx
f0100400:	66 89 15 28 75 11 f0 	mov    %dx,0xf0117528
f0100407:	0f b7 c0             	movzwl %ax,%eax
f010040a:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
f0100410:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100414:	66 81 3d 28 75 11 f0 	cmpw   $0x7cf,0xf0117528
f010041b:	cf 07 
f010041d:	76 42                	jbe    f0100461 <cons_putc+0x1aa>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010041f:	a1 2c 75 11 f0       	mov    0xf011752c,%eax
f0100424:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010042b:	00 
f010042c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100432:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100436:	89 04 24             	mov    %eax,(%esp)
f0100439:	e8 76 34 00 00       	call   f01038b4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010043e:	8b 15 2c 75 11 f0    	mov    0xf011752c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100444:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100449:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010044f:	83 c0 01             	add    $0x1,%eax
f0100452:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100457:	75 f0                	jne    f0100449 <cons_putc+0x192>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100459:	66 83 2d 28 75 11 f0 	subw   $0x50,0xf0117528
f0100460:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100461:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100467:	b8 0e 00 00 00       	mov    $0xe,%eax
f010046c:	89 ca                	mov    %ecx,%edx
f010046e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010046f:	0f b7 1d 28 75 11 f0 	movzwl 0xf0117528,%ebx
f0100476:	8d 71 01             	lea    0x1(%ecx),%esi
f0100479:	89 d8                	mov    %ebx,%eax
f010047b:	66 c1 e8 08          	shr    $0x8,%ax
f010047f:	89 f2                	mov    %esi,%edx
f0100481:	ee                   	out    %al,(%dx)
f0100482:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100487:	89 ca                	mov    %ecx,%edx
f0100489:	ee                   	out    %al,(%dx)
f010048a:	89 d8                	mov    %ebx,%eax
f010048c:	89 f2                	mov    %esi,%edx
f010048e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010048f:	83 c4 1c             	add    $0x1c,%esp
f0100492:	5b                   	pop    %ebx
f0100493:	5e                   	pop    %esi
f0100494:	5f                   	pop    %edi
f0100495:	5d                   	pop    %ebp
f0100496:	c3                   	ret    

f0100497 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100497:	80 3d 34 75 11 f0 00 	cmpb   $0x0,0xf0117534
f010049e:	74 11                	je     f01004b1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004a0:	55                   	push   %ebp
f01004a1:	89 e5                	mov    %esp,%ebp
f01004a3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004a6:	b8 40 01 10 f0       	mov    $0xf0100140,%eax
f01004ab:	e8 ac fc ff ff       	call   f010015c <cons_intr>
}
f01004b0:	c9                   	leave  
f01004b1:	f3 c3                	repz ret 

f01004b3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b3:	55                   	push   %ebp
f01004b4:	89 e5                	mov    %esp,%ebp
f01004b6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b9:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004be:	e8 99 fc ff ff       	call   f010015c <cons_intr>
}
f01004c3:	c9                   	leave  
f01004c4:	c3                   	ret    

f01004c5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c5:	55                   	push   %ebp
f01004c6:	89 e5                	mov    %esp,%ebp
f01004c8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004cb:	e8 c7 ff ff ff       	call   f0100497 <serial_intr>
	kbd_intr();
f01004d0:	e8 de ff ff ff       	call   f01004b3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d5:	a1 20 75 11 f0       	mov    0xf0117520,%eax
f01004da:	3b 05 24 75 11 f0    	cmp    0xf0117524,%eax
f01004e0:	74 26                	je     f0100508 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004e2:	8d 50 01             	lea    0x1(%eax),%edx
f01004e5:	89 15 20 75 11 f0    	mov    %edx,0xf0117520
f01004eb:	0f b6 88 20 73 11 f0 	movzbl -0xfee8ce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004f2:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004f4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004fa:	75 11                	jne    f010050d <cons_getc+0x48>
			cons.rpos = 0;
f01004fc:	c7 05 20 75 11 f0 00 	movl   $0x0,0xf0117520
f0100503:	00 00 00 
f0100506:	eb 05                	jmp    f010050d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100508:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010050d:	c9                   	leave  
f010050e:	c3                   	ret    

f010050f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010050f:	55                   	push   %ebp
f0100510:	89 e5                	mov    %esp,%ebp
f0100512:	57                   	push   %edi
f0100513:	56                   	push   %esi
f0100514:	53                   	push   %ebx
f0100515:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100518:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010051f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100526:	5a a5 
	if (*cp != 0xA55A) {
f0100528:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010052f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100533:	74 11                	je     f0100546 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100535:	c7 05 30 75 11 f0 b4 	movl   $0x3b4,0xf0117530
f010053c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010053f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100544:	eb 16                	jmp    f010055c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100546:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010054d:	c7 05 30 75 11 f0 d4 	movl   $0x3d4,0xf0117530
f0100554:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100557:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010055c:	8b 0d 30 75 11 f0    	mov    0xf0117530,%ecx
f0100562:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100567:	89 ca                	mov    %ecx,%edx
f0100569:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010056a:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056d:	89 da                	mov    %ebx,%edx
f010056f:	ec                   	in     (%dx),%al
f0100570:	0f b6 f0             	movzbl %al,%esi
f0100573:	c1 e6 08             	shl    $0x8,%esi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100576:	b8 0f 00 00 00       	mov    $0xf,%eax
f010057b:	89 ca                	mov    %ecx,%edx
f010057d:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057e:	89 da                	mov    %ebx,%edx
f0100580:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100581:	89 3d 2c 75 11 f0    	mov    %edi,0xf011752c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100587:	0f b6 d8             	movzbl %al,%ebx
f010058a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010058c:	66 89 35 28 75 11 f0 	mov    %si,0xf0117528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100593:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100598:	b8 00 00 00 00       	mov    $0x0,%eax
f010059d:	89 f2                	mov    %esi,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	b2 fb                	mov    $0xfb,%dl
f01005a2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005a7:	ee                   	out    %al,(%dx)
f01005a8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005ad:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	b2 f9                	mov    $0xf9,%dl
f01005b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 fb                	mov    $0xfb,%dl
f01005bf:	b8 03 00 00 00       	mov    $0x3,%eax
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 fc                	mov    $0xfc,%dl
f01005c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b2 f9                	mov    $0xf9,%dl
f01005cf:	b8 01 00 00 00       	mov    $0x1,%eax
f01005d4:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d5:	b2 fd                	mov    $0xfd,%dl
f01005d7:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d8:	3c ff                	cmp    $0xff,%al
f01005da:	0f 95 c1             	setne  %cl
f01005dd:	88 0d 34 75 11 f0    	mov    %cl,0xf0117534
f01005e3:	89 f2                	mov    %esi,%edx
f01005e5:	ec                   	in     (%dx),%al
f01005e6:	89 da                	mov    %ebx,%edx
f01005e8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e9:	84 c9                	test   %cl,%cl
f01005eb:	75 0c                	jne    f01005f9 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005ed:	c7 04 24 59 3d 10 f0 	movl   $0xf0103d59,(%esp)
f01005f4:	e8 0e 27 00 00       	call   f0102d07 <cprintf>
}
f01005f9:	83 c4 1c             	add    $0x1c,%esp
f01005fc:	5b                   	pop    %ebx
f01005fd:	5e                   	pop    %esi
f01005fe:	5f                   	pop    %edi
f01005ff:	5d                   	pop    %ebp
f0100600:	c3                   	ret    

f0100601 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100601:	55                   	push   %ebp
f0100602:	89 e5                	mov    %esp,%ebp
f0100604:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100607:	8b 45 08             	mov    0x8(%ebp),%eax
f010060a:	e8 a8 fc ff ff       	call   f01002b7 <cons_putc>
}
f010060f:	c9                   	leave  
f0100610:	c3                   	ret    

f0100611 <getchar>:

int
getchar(void)
{
f0100611:	55                   	push   %ebp
f0100612:	89 e5                	mov    %esp,%ebp
f0100614:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100617:	e8 a9 fe ff ff       	call   f01004c5 <cons_getc>
f010061c:	85 c0                	test   %eax,%eax
f010061e:	74 f7                	je     f0100617 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100620:	c9                   	leave  
f0100621:	c3                   	ret    

f0100622 <iscons>:

int
iscons(int fdnum)
{
f0100622:	55                   	push   %ebp
f0100623:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100625:	b8 01 00 00 00       	mov    $0x1,%eax
f010062a:	5d                   	pop    %ebp
f010062b:	c3                   	ret    
f010062c:	66 90                	xchg   %ax,%ax
f010062e:	66 90                	xchg   %ax,%ax

f0100630 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
f0100633:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100636:	c7 44 24 08 a0 3f 10 	movl   $0xf0103fa0,0x8(%esp)
f010063d:	f0 
f010063e:	c7 44 24 04 be 3f 10 	movl   $0xf0103fbe,0x4(%esp)
f0100645:	f0 
f0100646:	c7 04 24 c3 3f 10 f0 	movl   $0xf0103fc3,(%esp)
f010064d:	e8 b5 26 00 00       	call   f0102d07 <cprintf>
f0100652:	c7 44 24 08 80 40 10 	movl   $0xf0104080,0x8(%esp)
f0100659:	f0 
f010065a:	c7 44 24 04 cc 3f 10 	movl   $0xf0103fcc,0x4(%esp)
f0100661:	f0 
f0100662:	c7 04 24 c3 3f 10 f0 	movl   $0xf0103fc3,(%esp)
f0100669:	e8 99 26 00 00       	call   f0102d07 <cprintf>
f010066e:	c7 44 24 08 a8 40 10 	movl   $0xf01040a8,0x8(%esp)
f0100675:	f0 
f0100676:	c7 44 24 04 d5 3f 10 	movl   $0xf0103fd5,0x4(%esp)
f010067d:	f0 
f010067e:	c7 04 24 c3 3f 10 f0 	movl   $0xf0103fc3,(%esp)
f0100685:	e8 7d 26 00 00       	call   f0102d07 <cprintf>
	return 0;
}
f010068a:	b8 00 00 00 00       	mov    $0x0,%eax
f010068f:	c9                   	leave  
f0100690:	c3                   	ret    

f0100691 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100691:	55                   	push   %ebp
f0100692:	89 e5                	mov    %esp,%ebp
f0100694:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100697:	c7 04 24 df 3f 10 f0 	movl   $0xf0103fdf,(%esp)
f010069e:	e8 64 26 00 00       	call   f0102d07 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006aa:	00 
f01006ab:	c7 04 24 c8 40 10 f0 	movl   $0xf01040c8,(%esp)
f01006b2:	e8 50 26 00 00       	call   f0102d07 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006be:	00 
f01006bf:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c6:	f0 
f01006c7:	c7 04 24 f0 40 10 f0 	movl   $0xf01040f0,(%esp)
f01006ce:	e8 34 26 00 00       	call   f0102d07 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d3:	c7 44 24 08 f7 3c 10 	movl   $0x103cf7,0x8(%esp)
f01006da:	00 
f01006db:	c7 44 24 04 f7 3c 10 	movl   $0xf0103cf7,0x4(%esp)
f01006e2:	f0 
f01006e3:	c7 04 24 14 41 10 f0 	movl   $0xf0104114,(%esp)
f01006ea:	e8 18 26 00 00       	call   f0102d07 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ef:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f01006f6:	00 
f01006f7:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f01006fe:	f0 
f01006ff:	c7 04 24 38 41 10 f0 	movl   $0xf0104138,(%esp)
f0100706:	e8 fc 25 00 00       	call   f0102d07 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070b:	c7 44 24 08 70 79 11 	movl   $0x117970,0x8(%esp)
f0100712:	00 
f0100713:	c7 44 24 04 70 79 11 	movl   $0xf0117970,0x4(%esp)
f010071a:	f0 
f010071b:	c7 04 24 5c 41 10 f0 	movl   $0xf010415c,(%esp)
f0100722:	e8 e0 25 00 00       	call   f0102d07 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100727:	b8 6f 7d 11 f0       	mov    $0xf0117d6f,%eax
f010072c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100731:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100736:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010073c:	85 c0                	test   %eax,%eax
f010073e:	0f 48 c2             	cmovs  %edx,%eax
f0100741:	c1 f8 0a             	sar    $0xa,%eax
f0100744:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100748:	c7 04 24 80 41 10 f0 	movl   $0xf0104180,(%esp)
f010074f:	e8 b3 25 00 00       	call   f0102d07 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100754:	b8 00 00 00 00       	mov    $0x0,%eax
f0100759:	c9                   	leave  
f010075a:	c3                   	ret    

f010075b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010075b:	55                   	push   %ebp
f010075c:	89 e5                	mov    %esp,%ebp
f010075e:	57                   	push   %edi
f010075f:	56                   	push   %esi
f0100760:	53                   	push   %ebx
f0100761:	83 ec 4c             	sub    $0x4c,%esp
	/*
	 parameter "argc" indicates numbers of paras passed by the command-line;  parameter "argv" indicates specific paras accordingly.
	*/
	struct Eipdebuginfo info;

	cprintf("Stack backtrace:\n");
f0100764:	c7 04 24 f8 3f 10 f0 	movl   $0xf0103ff8,(%esp)
f010076b:	e8 97 25 00 00       	call   f0102d07 <cprintf>
	uint32_t *ebp = (uint32_t*)read_ebp();	
f0100770:	89 eb                	mov    %ebp,%ebx
		cprintf("%08.x ", *(ebp+3));
		cprintf("%08.x ", *(ebp+4));
		cprintf("%08.x ", *(ebp+5));
		cprintf("%08.x\n", *(ebp+6));

		debuginfo_eip(eip, &info);
f0100772:	8d 7d d0             	lea    -0x30(%ebp),%edi
	*/
	struct Eipdebuginfo info;

	cprintf("Stack backtrace:\n");
	uint32_t *ebp = (uint32_t*)read_ebp();	
	while(ebp) {
f0100775:	e9 b3 00 00 00       	jmp    f010082d <mon_backtrace+0xd2>
		uint32_t eip = ebp[1];
f010077a:	8b 73 04             	mov    0x4(%ebx),%esi
		cprintf("  ebp %x  eip %x  args ", ebp, eip);
f010077d:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100781:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100785:	c7 04 24 0a 40 10 f0 	movl   $0xf010400a,(%esp)
f010078c:	e8 76 25 00 00       	call   f0102d07 <cprintf>

		cprintf("%08.x ", *(ebp+2));
f0100791:	8b 43 08             	mov    0x8(%ebx),%eax
f0100794:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100798:	c7 04 24 22 40 10 f0 	movl   $0xf0104022,(%esp)
f010079f:	e8 63 25 00 00       	call   f0102d07 <cprintf>
		cprintf("%08.x ", *(ebp+3));
f01007a4:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ab:	c7 04 24 22 40 10 f0 	movl   $0xf0104022,(%esp)
f01007b2:	e8 50 25 00 00       	call   f0102d07 <cprintf>
		cprintf("%08.x ", *(ebp+4));
f01007b7:	8b 43 10             	mov    0x10(%ebx),%eax
f01007ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007be:	c7 04 24 22 40 10 f0 	movl   $0xf0104022,(%esp)
f01007c5:	e8 3d 25 00 00       	call   f0102d07 <cprintf>
		cprintf("%08.x ", *(ebp+5));
f01007ca:	8b 43 14             	mov    0x14(%ebx),%eax
f01007cd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d1:	c7 04 24 22 40 10 f0 	movl   $0xf0104022,(%esp)
f01007d8:	e8 2a 25 00 00       	call   f0102d07 <cprintf>
		cprintf("%08.x\n", *(ebp+6));
f01007dd:	8b 43 18             	mov    0x18(%ebx),%eax
f01007e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e4:	c7 04 24 29 40 10 f0 	movl   $0xf0104029,(%esp)
f01007eb:	e8 17 25 00 00       	call   f0102d07 <cprintf>

		debuginfo_eip(eip, &info);
f01007f0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007f4:	89 34 24             	mov    %esi,(%esp)
f01007f7:	e8 02 26 00 00       	call   f0102dfe <debuginfo_eip>
		cprintf("\t%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, info.eip_fn_addr);	
f01007fc:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01007ff:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100803:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100806:	89 44 24 10          	mov    %eax,0x10(%esp)
f010080a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010080d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100811:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100814:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100818:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010081b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010081f:	c7 04 24 30 40 10 f0 	movl   $0xf0104030,(%esp)
f0100826:	e8 dc 24 00 00       	call   f0102d07 <cprintf>

		ebp = (uint32_t*)*(ebp);		
f010082b:	8b 1b                	mov    (%ebx),%ebx
	*/
	struct Eipdebuginfo info;

	cprintf("Stack backtrace:\n");
	uint32_t *ebp = (uint32_t*)read_ebp();	
	while(ebp) {
f010082d:	85 db                	test   %ebx,%ebx
f010082f:	0f 85 45 ff ff ff    	jne    f010077a <mon_backtrace+0x1f>

		ebp = (uint32_t*)*(ebp);		
	}

	return 0;
}
f0100835:	b8 00 00 00 00       	mov    $0x0,%eax
f010083a:	83 c4 4c             	add    $0x4c,%esp
f010083d:	5b                   	pop    %ebx
f010083e:	5e                   	pop    %esi
f010083f:	5f                   	pop    %edi
f0100840:	5d                   	pop    %ebp
f0100841:	c3                   	ret    

f0100842 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100842:	55                   	push   %ebp
f0100843:	89 e5                	mov    %esp,%ebp
f0100845:	57                   	push   %edi
f0100846:	56                   	push   %esi
f0100847:	53                   	push   %ebx
f0100848:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010084b:	c7 04 24 ac 41 10 f0 	movl   $0xf01041ac,(%esp)
f0100852:	e8 b0 24 00 00       	call   f0102d07 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100857:	c7 04 24 d0 41 10 f0 	movl   $0xf01041d0,(%esp)
f010085e:	e8 a4 24 00 00       	call   f0102d07 <cprintf>

	
	while (1) {
		buf = readline("K> ");
f0100863:	c7 04 24 41 40 10 f0 	movl   $0xf0104041,(%esp)
f010086a:	e8 a1 2d 00 00       	call   f0103610 <readline>
f010086f:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100871:	85 c0                	test   %eax,%eax
f0100873:	74 ee                	je     f0100863 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100875:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010087c:	be 00 00 00 00       	mov    $0x0,%esi
f0100881:	eb 0a                	jmp    f010088d <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100883:	c6 03 00             	movb   $0x0,(%ebx)
f0100886:	89 f7                	mov    %esi,%edi
f0100888:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010088b:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010088d:	0f b6 03             	movzbl (%ebx),%eax
f0100890:	84 c0                	test   %al,%al
f0100892:	74 63                	je     f01008f7 <monitor+0xb5>
f0100894:	0f be c0             	movsbl %al,%eax
f0100897:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089b:	c7 04 24 45 40 10 f0 	movl   $0xf0104045,(%esp)
f01008a2:	e8 83 2f 00 00       	call   f010382a <strchr>
f01008a7:	85 c0                	test   %eax,%eax
f01008a9:	75 d8                	jne    f0100883 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008ab:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008ae:	74 47                	je     f01008f7 <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008b0:	83 fe 0f             	cmp    $0xf,%esi
f01008b3:	75 16                	jne    f01008cb <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008b5:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008bc:	00 
f01008bd:	c7 04 24 4a 40 10 f0 	movl   $0xf010404a,(%esp)
f01008c4:	e8 3e 24 00 00       	call   f0102d07 <cprintf>
f01008c9:	eb 98                	jmp    f0100863 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008cb:	8d 7e 01             	lea    0x1(%esi),%edi
f01008ce:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008d2:	eb 03                	jmp    f01008d7 <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008d4:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d7:	0f b6 03             	movzbl (%ebx),%eax
f01008da:	84 c0                	test   %al,%al
f01008dc:	74 ad                	je     f010088b <monitor+0x49>
f01008de:	0f be c0             	movsbl %al,%eax
f01008e1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e5:	c7 04 24 45 40 10 f0 	movl   $0xf0104045,(%esp)
f01008ec:	e8 39 2f 00 00       	call   f010382a <strchr>
f01008f1:	85 c0                	test   %eax,%eax
f01008f3:	74 df                	je     f01008d4 <monitor+0x92>
f01008f5:	eb 94                	jmp    f010088b <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f01008f7:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008fe:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008ff:	85 f6                	test   %esi,%esi
f0100901:	0f 84 5c ff ff ff    	je     f0100863 <monitor+0x21>
f0100907:	bb 00 00 00 00       	mov    $0x0,%ebx
f010090c:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010090f:	8b 04 85 00 42 10 f0 	mov    -0xfefbe00(,%eax,4),%eax
f0100916:	89 44 24 04          	mov    %eax,0x4(%esp)
f010091a:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010091d:	89 04 24             	mov    %eax,(%esp)
f0100920:	e8 a7 2e 00 00       	call   f01037cc <strcmp>
f0100925:	85 c0                	test   %eax,%eax
f0100927:	75 24                	jne    f010094d <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f0100929:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010092c:	8b 55 08             	mov    0x8(%ebp),%edx
f010092f:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100933:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100936:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010093a:	89 34 24             	mov    %esi,(%esp)
f010093d:	ff 14 85 08 42 10 f0 	call   *-0xfefbdf8(,%eax,4)

	
	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100944:	85 c0                	test   %eax,%eax
f0100946:	78 25                	js     f010096d <monitor+0x12b>
f0100948:	e9 16 ff ff ff       	jmp    f0100863 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f010094d:	83 c3 01             	add    $0x1,%ebx
f0100950:	83 fb 03             	cmp    $0x3,%ebx
f0100953:	75 b7                	jne    f010090c <monitor+0xca>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100955:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100958:	89 44 24 04          	mov    %eax,0x4(%esp)
f010095c:	c7 04 24 67 40 10 f0 	movl   $0xf0104067,(%esp)
f0100963:	e8 9f 23 00 00       	call   f0102d07 <cprintf>
f0100968:	e9 f6 fe ff ff       	jmp    f0100863 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010096d:	83 c4 5c             	add    $0x5c,%esp
f0100970:	5b                   	pop    %ebx
f0100971:	5e                   	pop    %esi
f0100972:	5f                   	pop    %edi
f0100973:	5d                   	pop    %ebp
f0100974:	c3                   	ret    
f0100975:	66 90                	xchg   %ax,%ax
f0100977:	66 90                	xchg   %ax,%ax
f0100979:	66 90                	xchg   %ax,%ax
f010097b:	66 90                	xchg   %ax,%ax
f010097d:	66 90                	xchg   %ax,%ax
f010097f:	90                   	nop

f0100980 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100980:	55                   	push   %ebp
f0100981:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100983:	83 3d 38 75 11 f0 00 	cmpl   $0x0,0xf0117538
f010098a:	75 11                	jne    f010099d <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010098c:	ba 6f 89 11 f0       	mov    $0xf011896f,%edx
f0100991:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100997:	89 15 38 75 11 f0    	mov    %edx,0xf0117538
//	cprintf("Next memory at %x\n", ROUNDUP((char *) (nextfree+n), PGSIZE));
	if (n != 0) {
		char *next = nextfree;
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
		return next;
	} else return nextfree;
f010099d:	8b 15 38 75 11 f0    	mov    0xf0117538,%edx
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
//	cprintf("boot_alloc memory at %x\n", nextfree);
//	cprintf("Next memory at %x\n", ROUNDUP((char *) (nextfree+n), PGSIZE));
	if (n != 0) {
f01009a3:	85 c0                	test   %eax,%eax
f01009a5:	74 11                	je     f01009b8 <boot_alloc+0x38>
		char *next = nextfree;
		nextfree = ROUNDUP((char *) (nextfree+n), PGSIZE);
f01009a7:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f01009ae:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009b3:	a3 38 75 11 f0       	mov    %eax,0xf0117538
		return next;
	} else return nextfree;

	return NULL;
}
f01009b8:	89 d0                	mov    %edx,%eax
f01009ba:	5d                   	pop    %ebp
f01009bb:	c3                   	ret    

f01009bc <page2kva>:
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009bc:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01009c2:	c1 f8 03             	sar    $0x3,%eax
f01009c5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009c8:	89 c2                	mov    %eax,%edx
f01009ca:	c1 ea 0c             	shr    $0xc,%edx
f01009cd:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f01009d3:	72 26                	jb     f01009fb <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f01009d5:	55                   	push   %ebp
f01009d6:	89 e5                	mov    %esp,%ebp
f01009d8:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009db:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009df:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f01009e6:	f0 
f01009e7:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01009ee:	00 
f01009ef:	c7 04 24 9c 49 10 f0 	movl   $0xf010499c,(%esp)
f01009f6:	e8 99 f6 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01009fb:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100a00:	c3                   	ret    

f0100a01 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a01:	89 d1                	mov    %edx,%ecx
f0100a03:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a06:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a09:	a8 01                	test   $0x1,%al
f0100a0b:	74 5d                	je     f0100a6a <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a0d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a12:	89 c1                	mov    %eax,%ecx
f0100a14:	c1 e9 0c             	shr    $0xc,%ecx
f0100a17:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0100a1d:	72 26                	jb     f0100a45 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a1f:	55                   	push   %ebp
f0100a20:	89 e5                	mov    %esp,%ebp
f0100a22:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a25:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a29:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0100a30:	f0 
f0100a31:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f0100a38:	00 
f0100a39:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0100a40:	e8 4f f6 ff ff       	call   f0100094 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a45:	c1 ea 0c             	shr    $0xc,%edx
f0100a48:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a4e:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a55:	89 c2                	mov    %eax,%edx
f0100a57:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a5a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a5f:	85 d2                	test   %edx,%edx
f0100a61:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a66:	0f 44 c2             	cmove  %edx,%eax
f0100a69:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a6f:	c3                   	ret    

f0100a70 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a70:	55                   	push   %ebp
f0100a71:	89 e5                	mov    %esp,%ebp
f0100a73:	57                   	push   %edi
f0100a74:	56                   	push   %esi
f0100a75:	53                   	push   %ebx
f0100a76:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a79:	84 c0                	test   %al,%al
f0100a7b:	0f 85 15 03 00 00    	jne    f0100d96 <check_page_free_list+0x326>
f0100a81:	e9 22 03 00 00       	jmp    f0100da8 <check_page_free_list+0x338>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a86:	c7 44 24 08 48 42 10 	movl   $0xf0104248,0x8(%esp)
f0100a8d:	f0 
f0100a8e:	c7 44 24 04 16 02 00 	movl   $0x216,0x4(%esp)
f0100a95:	00 
f0100a96:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0100a9d:	e8 f2 f5 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100aa2:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100aa5:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100aa8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100aab:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100aae:	89 c2                	mov    %eax,%edx
f0100ab0:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ab6:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100abc:	0f 95 c2             	setne  %dl
f0100abf:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ac2:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ac6:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ac8:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100acc:	8b 00                	mov    (%eax),%eax
f0100ace:	85 c0                	test   %eax,%eax
f0100ad0:	75 dc                	jne    f0100aae <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ad2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ad5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100adb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ade:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100ae1:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ae3:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ae6:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100aeb:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100af0:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100af6:	eb 63                	jmp    f0100b5b <check_page_free_list+0xeb>
f0100af8:	89 d8                	mov    %ebx,%eax
f0100afa:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100b00:	c1 f8 03             	sar    $0x3,%eax
f0100b03:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b06:	89 c2                	mov    %eax,%edx
f0100b08:	c1 ea 16             	shr    $0x16,%edx
f0100b0b:	39 f2                	cmp    %esi,%edx
f0100b0d:	73 4a                	jae    f0100b59 <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b0f:	89 c2                	mov    %eax,%edx
f0100b11:	c1 ea 0c             	shr    $0xc,%edx
f0100b14:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100b1a:	72 20                	jb     f0100b3c <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b1c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b20:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0100b27:	f0 
f0100b28:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b2f:	00 
f0100b30:	c7 04 24 9c 49 10 f0 	movl   $0xf010499c,(%esp)
f0100b37:	e8 58 f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b3c:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b43:	00 
f0100b44:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b4b:	00 
	return (void *)(pa + KERNBASE);
f0100b4c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b51:	89 04 24             	mov    %eax,(%esp)
f0100b54:	e8 0e 2d 00 00       	call   f0103867 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b59:	8b 1b                	mov    (%ebx),%ebx
f0100b5b:	85 db                	test   %ebx,%ebx
f0100b5d:	75 99                	jne    f0100af8 <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b5f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b64:	e8 17 fe ff ff       	call   f0100980 <boot_alloc>
f0100b69:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b6c:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b72:	8b 0d 6c 79 11 f0    	mov    0xf011796c,%ecx
		assert(pp < pages + npages);
f0100b78:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0100b7d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100b80:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100b83:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b86:	89 4d d0             	mov    %ecx,-0x30(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b89:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b8e:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b91:	e9 97 01 00 00       	jmp    f0100d2d <check_page_free_list+0x2bd>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b96:	39 ca                	cmp    %ecx,%edx
f0100b98:	73 24                	jae    f0100bbe <check_page_free_list+0x14e>
f0100b9a:	c7 44 24 0c b6 49 10 	movl   $0xf01049b6,0xc(%esp)
f0100ba1:	f0 
f0100ba2:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0100ba9:	f0 
f0100baa:	c7 44 24 04 30 02 00 	movl   $0x230,0x4(%esp)
f0100bb1:	00 
f0100bb2:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0100bb9:	e8 d6 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100bbe:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bc1:	72 24                	jb     f0100be7 <check_page_free_list+0x177>
f0100bc3:	c7 44 24 0c d7 49 10 	movl   $0xf01049d7,0xc(%esp)
f0100bca:	f0 
f0100bcb:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0100bd2:	f0 
f0100bd3:	c7 44 24 04 31 02 00 	movl   $0x231,0x4(%esp)
f0100bda:	00 
f0100bdb:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0100be2:	e8 ad f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100be7:	89 d0                	mov    %edx,%eax
f0100be9:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bec:	a8 07                	test   $0x7,%al
f0100bee:	74 24                	je     f0100c14 <check_page_free_list+0x1a4>
f0100bf0:	c7 44 24 0c 6c 42 10 	movl   $0xf010426c,0xc(%esp)
f0100bf7:	f0 
f0100bf8:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0100bff:	f0 
f0100c00:	c7 44 24 04 32 02 00 	movl   $0x232,0x4(%esp)
f0100c07:	00 
f0100c08:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0100c0f:	e8 80 f4 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c14:	c1 f8 03             	sar    $0x3,%eax
f0100c17:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c1a:	85 c0                	test   %eax,%eax
f0100c1c:	75 24                	jne    f0100c42 <check_page_free_list+0x1d2>
f0100c1e:	c7 44 24 0c eb 49 10 	movl   $0xf01049eb,0xc(%esp)
f0100c25:	f0 
f0100c26:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0100c2d:	f0 
f0100c2e:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
f0100c35:	00 
f0100c36:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0100c3d:	e8 52 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c42:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c47:	75 24                	jne    f0100c6d <check_page_free_list+0x1fd>
f0100c49:	c7 44 24 0c fc 49 10 	movl   $0xf01049fc,0xc(%esp)
f0100c50:	f0 
f0100c51:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0100c58:	f0 
f0100c59:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
f0100c60:	00 
f0100c61:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0100c68:	e8 27 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c6d:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c72:	75 24                	jne    f0100c98 <check_page_free_list+0x228>
f0100c74:	c7 44 24 0c a0 42 10 	movl   $0xf01042a0,0xc(%esp)
f0100c7b:	f0 
f0100c7c:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0100c83:	f0 
f0100c84:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
f0100c8b:	00 
f0100c8c:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0100c93:	e8 fc f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c98:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c9d:	75 24                	jne    f0100cc3 <check_page_free_list+0x253>
f0100c9f:	c7 44 24 0c 15 4a 10 	movl   $0xf0104a15,0xc(%esp)
f0100ca6:	f0 
f0100ca7:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0100cae:	f0 
f0100caf:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f0100cb6:	00 
f0100cb7:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0100cbe:	e8 d1 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cc3:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cc8:	76 58                	jbe    f0100d22 <check_page_free_list+0x2b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cca:	89 c3                	mov    %eax,%ebx
f0100ccc:	c1 eb 0c             	shr    $0xc,%ebx
f0100ccf:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100cd2:	77 20                	ja     f0100cf4 <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cd4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cd8:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0100cdf:	f0 
f0100ce0:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100ce7:	00 
f0100ce8:	c7 04 24 9c 49 10 f0 	movl   $0xf010499c,(%esp)
f0100cef:	e8 a0 f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100cf4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cf9:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100cfc:	76 2a                	jbe    f0100d28 <check_page_free_list+0x2b8>
f0100cfe:	c7 44 24 0c c4 42 10 	movl   $0xf01042c4,0xc(%esp)
f0100d05:	f0 
f0100d06:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0100d0d:	f0 
f0100d0e:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
f0100d15:	00 
f0100d16:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0100d1d:	e8 72 f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d22:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d26:	eb 03                	jmp    f0100d2b <check_page_free_list+0x2bb>
		else
			++nfree_extmem;
f0100d28:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d2b:	8b 12                	mov    (%edx),%edx
f0100d2d:	85 d2                	test   %edx,%edx
f0100d2f:	0f 85 61 fe ff ff    	jne    f0100b96 <check_page_free_list+0x126>
f0100d35:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d38:	85 db                	test   %ebx,%ebx
f0100d3a:	7f 24                	jg     f0100d60 <check_page_free_list+0x2f0>
f0100d3c:	c7 44 24 0c 2f 4a 10 	movl   $0xf0104a2f,0xc(%esp)
f0100d43:	f0 
f0100d44:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0100d4b:	f0 
f0100d4c:	c7 44 24 04 41 02 00 	movl   $0x241,0x4(%esp)
f0100d53:	00 
f0100d54:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0100d5b:	e8 34 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d60:	85 ff                	test   %edi,%edi
f0100d62:	7f 24                	jg     f0100d88 <check_page_free_list+0x318>
f0100d64:	c7 44 24 0c 41 4a 10 	movl   $0xf0104a41,0xc(%esp)
f0100d6b:	f0 
f0100d6c:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0100d73:	f0 
f0100d74:	c7 44 24 04 42 02 00 	movl   $0x242,0x4(%esp)
f0100d7b:	00 
f0100d7c:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0100d83:	e8 0c f3 ff ff       	call   f0100094 <_panic>
	cprintf("check_page_free_list done\n");
f0100d88:	c7 04 24 52 4a 10 f0 	movl   $0xf0104a52,(%esp)
f0100d8f:	e8 73 1f 00 00       	call   f0102d07 <cprintf>
f0100d94:	eb 29                	jmp    f0100dbf <check_page_free_list+0x34f>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100d96:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0100d9b:	85 c0                	test   %eax,%eax
f0100d9d:	0f 85 ff fc ff ff    	jne    f0100aa2 <check_page_free_list+0x32>
f0100da3:	e9 de fc ff ff       	jmp    f0100a86 <check_page_free_list+0x16>
f0100da8:	83 3d 3c 75 11 f0 00 	cmpl   $0x0,0xf011753c
f0100daf:	0f 84 d1 fc ff ff    	je     f0100a86 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100db5:	be 00 04 00 00       	mov    $0x400,%esi
f0100dba:	e9 31 fd ff ff       	jmp    f0100af0 <check_page_free_list+0x80>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list done\n");
}
f0100dbf:	83 c4 4c             	add    $0x4c,%esp
f0100dc2:	5b                   	pop    %ebx
f0100dc3:	5e                   	pop    %esi
f0100dc4:	5f                   	pop    %edi
f0100dc5:	5d                   	pop    %ebp
f0100dc6:	c3                   	ret    

f0100dc7 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100dc7:	55                   	push   %ebp
f0100dc8:	89 e5                	mov    %esp,%ebp
f0100dca:	56                   	push   %esi
f0100dcb:	53                   	push   %ebx
	// 
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f0100dcc:	8b 35 40 75 11 f0    	mov    0xf0117540,%esi
f0100dd2:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100dd8:	b8 01 00 00 00       	mov    $0x1,%eax
f0100ddd:	eb 22                	jmp    f0100e01 <page_init+0x3a>
f0100ddf:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100de6:	89 d1                	mov    %edx,%ecx
f0100de8:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100dee:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100df4:	89 19                	mov    %ebx,(%ecx)
	// 
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f0100df6:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100df9:	03 15 6c 79 11 f0    	add    0xf011796c,%edx
f0100dff:	89 d3                	mov    %edx,%ebx
	// 
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 1; i < npages_basemem; i++) {
f0100e01:	39 f0                	cmp    %esi,%eax
f0100e03:	72 da                	jb     f0100ddf <page_init+0x18>
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	int med = (int)ROUNDUP(((char*)pages) + (sizeof(struct PageInfo) * npages) - 0xf0000000, PGSIZE)/PGSIZE;
f0100e05:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0100e0a:	8b 15 64 79 11 f0    	mov    0xf0117964,%edx
f0100e10:	8d 84 d0 ff 0f 00 10 	lea    0x10000fff(%eax,%edx,8),%eax
f0100e17:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100e1c:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100e22:	85 c0                	test   %eax,%eax
f0100e24:	0f 48 c2             	cmovs  %edx,%eax
f0100e27:	c1 f8 0c             	sar    $0xc,%eax
	//cprintf("pageinfo size: %d\n", sizeof(struct PageInfo));
//	cprintf("%x\n", ((char*)pages) + (sizeof(struct PageInfo) * npages));
//	cprintf("med=%d\n", med);
	for (i = med; i < npages; i++) {
f0100e2a:	89 c2                	mov    %eax,%edx
f0100e2c:	c1 e0 03             	shl    $0x3,%eax
f0100e2f:	eb 1e                	jmp    f0100e4f <page_init+0x88>
		pages[i].pp_ref = 0;
f0100e31:	89 c1                	mov    %eax,%ecx
f0100e33:	03 0d 6c 79 11 f0    	add    0xf011796c,%ecx
f0100e39:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100e3f:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100e41:	89 c3                	mov    %eax,%ebx
f0100e43:	03 1d 6c 79 11 f0    	add    0xf011796c,%ebx
	}
	int med = (int)ROUNDUP(((char*)pages) + (sizeof(struct PageInfo) * npages) - 0xf0000000, PGSIZE)/PGSIZE;
	//cprintf("pageinfo size: %d\n", sizeof(struct PageInfo));
//	cprintf("%x\n", ((char*)pages) + (sizeof(struct PageInfo) * npages));
//	cprintf("med=%d\n", med);
	for (i = med; i < npages; i++) {
f0100e49:	83 c2 01             	add    $0x1,%edx
f0100e4c:	83 c0 08             	add    $0x8,%eax
f0100e4f:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100e55:	72 da                	jb     f0100e31 <page_init+0x6a>
f0100e57:	89 1d 3c 75 11 f0    	mov    %ebx,0xf011753c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100e5d:	5b                   	pop    %ebx
f0100e5e:	5e                   	pop    %esi
f0100e5f:	5d                   	pop    %ebp
f0100e60:	c3                   	ret    

f0100e61 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100e61:	55                   	push   %ebp
f0100e62:	89 e5                	mov    %esp,%ebp
f0100e64:	53                   	push   %ebx
f0100e65:	83 ec 14             	sub    $0x14,%esp
	if (page_free_list) {
f0100e68:	8b 1d 3c 75 11 f0    	mov    0xf011753c,%ebx
f0100e6e:	85 db                	test   %ebx,%ebx
f0100e70:	74 69                	je     f0100edb <page_alloc+0x7a>
		struct PageInfo *ret = page_free_list;
		page_free_list = page_free_list->pp_link;
f0100e72:	8b 03                	mov    (%ebx),%eax
f0100e74:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
		if (alloc_flags & ALLOC_ZERO) 
			memset(page2kva(ret), 0, PGSIZE);
		return ret;
f0100e79:	89 d8                	mov    %ebx,%eax
page_alloc(int alloc_flags)
{
	if (page_free_list) {
		struct PageInfo *ret = page_free_list;
		page_free_list = page_free_list->pp_link;
		if (alloc_flags & ALLOC_ZERO) 
f0100e7b:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e7f:	74 5f                	je     f0100ee0 <page_alloc+0x7f>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e81:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100e87:	c1 f8 03             	sar    $0x3,%eax
f0100e8a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e8d:	89 c2                	mov    %eax,%edx
f0100e8f:	c1 ea 0c             	shr    $0xc,%edx
f0100e92:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100e98:	72 20                	jb     f0100eba <page_alloc+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e9a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e9e:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0100ea5:	f0 
f0100ea6:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100ead:	00 
f0100eae:	c7 04 24 9c 49 10 f0 	movl   $0xf010499c,(%esp)
f0100eb5:	e8 da f1 ff ff       	call   f0100094 <_panic>
			memset(page2kva(ret), 0, PGSIZE);
f0100eba:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100ec1:	00 
f0100ec2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100ec9:	00 
	return (void *)(pa + KERNBASE);
f0100eca:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ecf:	89 04 24             	mov    %eax,(%esp)
f0100ed2:	e8 90 29 00 00       	call   f0103867 <memset>
		return ret;
f0100ed7:	89 d8                	mov    %ebx,%eax
f0100ed9:	eb 05                	jmp    f0100ee0 <page_alloc+0x7f>
	}
	return NULL;
f0100edb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ee0:	83 c4 14             	add    $0x14,%esp
f0100ee3:	5b                   	pop    %ebx
f0100ee4:	5d                   	pop    %ebp
f0100ee5:	c3                   	ret    

f0100ee6 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100ee6:	55                   	push   %ebp
f0100ee7:	89 e5                	mov    %esp,%ebp
f0100ee9:	8b 45 08             	mov    0x8(%ebp),%eax
	pp->pp_link = page_free_list;
f0100eec:	8b 15 3c 75 11 f0    	mov    0xf011753c,%edx
f0100ef2:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100ef4:	a3 3c 75 11 f0       	mov    %eax,0xf011753c
}
f0100ef9:	5d                   	pop    %ebp
f0100efa:	c3                   	ret    

f0100efb <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100efb:	55                   	push   %ebp
f0100efc:	89 e5                	mov    %esp,%ebp
f0100efe:	83 ec 04             	sub    $0x4,%esp
f0100f01:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f04:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100f08:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100f0b:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f0f:	66 85 d2             	test   %dx,%dx
f0100f12:	75 08                	jne    f0100f1c <page_decref+0x21>
		page_free(pp);
f0100f14:	89 04 24             	mov    %eax,(%esp)
f0100f17:	e8 ca ff ff ff       	call   f0100ee6 <page_free>
}
f0100f1c:	c9                   	leave  
f0100f1d:	c3                   	ret    

f0100f1e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f1e:	55                   	push   %ebp
f0100f1f:	89 e5                	mov    %esp,%ebp
f0100f21:	56                   	push   %esi
f0100f22:	53                   	push   %ebx
f0100f23:	83 ec 10             	sub    $0x10,%esp
f0100f26:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	int dindex = PDX(va), tindex = PTX(va);
f0100f29:	89 de                	mov    %ebx,%esi
f0100f2b:	c1 ee 0c             	shr    $0xc,%esi
f0100f2e:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100f34:	c1 eb 16             	shr    $0x16,%ebx
	//dir index, table index
	if (!(pgdir[dindex] & PTE_P)) {	//if pde not exist
f0100f37:	c1 e3 02             	shl    $0x2,%ebx
f0100f3a:	03 5d 08             	add    0x8(%ebp),%ebx
f0100f3d:	f6 03 01             	testb  $0x1,(%ebx)
f0100f40:	75 2c                	jne    f0100f6e <pgdir_walk+0x50>
		if (create) {
f0100f42:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100f46:	74 63                	je     f0100fab <pgdir_walk+0x8d>
			struct PageInfo *pg = page_alloc(ALLOC_ZERO);	//alloc a zero page
f0100f48:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100f4f:	e8 0d ff ff ff       	call   f0100e61 <page_alloc>
			if (!pg) return NULL;	//allocation fails
f0100f54:	85 c0                	test   %eax,%eax
f0100f56:	74 5a                	je     f0100fb2 <pgdir_walk+0x94>
			pg->pp_ref++;
f0100f58:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f5d:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0100f63:	c1 f8 03             	sar    $0x3,%eax
f0100f66:	c1 e0 0c             	shl    $0xc,%eax
			pgdir[dindex] = page2pa(pg) | PTE_P | PTE_U | PTE_W;
f0100f69:	83 c8 07             	or     $0x7,%eax
f0100f6c:	89 03                	mov    %eax,(%ebx)
		} else return NULL;
	}
	pte_t *p = KADDR(PTE_ADDR(pgdir[dindex]));
f0100f6e:	8b 03                	mov    (%ebx),%eax
f0100f70:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f75:	89 c2                	mov    %eax,%edx
f0100f77:	c1 ea 0c             	shr    $0xc,%edx
f0100f7a:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0100f80:	72 20                	jb     f0100fa2 <pgdir_walk+0x84>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f82:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f86:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0100f8d:	f0 
f0100f8e:	c7 44 24 04 7a 01 00 	movl   $0x17a,0x4(%esp)
f0100f95:	00 
f0100f96:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0100f9d:	e8 f2 f0 ff ff       	call   f0100094 <_panic>
	// 		struct PageInfo *pg = page_alloc(ALLOC_ZERO);	//alloc a zero page
	// 		pg->pp_ref++;
	// 		p[tindex] = page2pa(pg) | PTE_P;
	// 	} else return NULL;

	return p+tindex;
f0100fa2:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0100fa9:	eb 0c                	jmp    f0100fb7 <pgdir_walk+0x99>
		if (create) {
			struct PageInfo *pg = page_alloc(ALLOC_ZERO);	//alloc a zero page
			if (!pg) return NULL;	//allocation fails
			pg->pp_ref++;
			pgdir[dindex] = page2pa(pg) | PTE_P | PTE_U | PTE_W;
		} else return NULL;
f0100fab:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fb0:	eb 05                	jmp    f0100fb7 <pgdir_walk+0x99>
	int dindex = PDX(va), tindex = PTX(va);
	//dir index, table index
	if (!(pgdir[dindex] & PTE_P)) {	//if pde not exist
		if (create) {
			struct PageInfo *pg = page_alloc(ALLOC_ZERO);	//alloc a zero page
			if (!pg) return NULL;	//allocation fails
f0100fb2:	b8 00 00 00 00       	mov    $0x0,%eax
	// 		pg->pp_ref++;
	// 		p[tindex] = page2pa(pg) | PTE_P;
	// 	} else return NULL;

	return p+tindex;
}
f0100fb7:	83 c4 10             	add    $0x10,%esp
f0100fba:	5b                   	pop    %ebx
f0100fbb:	5e                   	pop    %esi
f0100fbc:	5d                   	pop    %ebp
f0100fbd:	c3                   	ret    

f0100fbe <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100fbe:	55                   	push   %ebp
f0100fbf:	89 e5                	mov    %esp,%ebp
f0100fc1:	57                   	push   %edi
f0100fc2:	56                   	push   %esi
f0100fc3:	53                   	push   %ebx
f0100fc4:	83 ec 2c             	sub    $0x2c,%esp
f0100fc7:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100fca:	89 d7                	mov    %edx,%edi
f0100fcc:	89 cb                	mov    %ecx,%ebx
	int i;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
f0100fce:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fd1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100fd5:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100fd9:	c7 04 24 0c 43 10 f0 	movl   $0xf010430c,(%esp)
f0100fe0:	e8 22 1d 00 00       	call   f0102d07 <cprintf>
	for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0100fe5:	c1 eb 0c             	shr    $0xc,%ebx
f0100fe8:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100feb:	89 fb                	mov    %edi,%ebx
f0100fed:	be 00 00 00 00       	mov    $0x0,%esi
f0100ff2:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ff5:	29 f8                	sub    %edi,%eax
f0100ff7:	89 45 e0             	mov    %eax,-0x20(%ebp)
		pte_t *pte = pgdir_walk(pgdir, (void *) va, 1);	//create
		if (!pte) panic("boot_map_region panic, out of memory");
		*pte = pa | perm | PTE_P;
f0100ffa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ffd:	83 c8 01             	or     $0x1,%eax
f0101000:	89 45 d8             	mov    %eax,-0x28(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0101003:	eb 45                	jmp    f010104a <boot_map_region+0x8c>
		pte_t *pte = pgdir_walk(pgdir, (void *) va, 1);	//create
f0101005:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010100c:	00 
f010100d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101011:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101014:	89 04 24             	mov    %eax,(%esp)
f0101017:	e8 02 ff ff ff       	call   f0100f1e <pgdir_walk>
		if (!pte) panic("boot_map_region panic, out of memory");
f010101c:	85 c0                	test   %eax,%eax
f010101e:	75 1c                	jne    f010103c <boot_map_region+0x7e>
f0101020:	c7 44 24 08 40 43 10 	movl   $0xf0104340,0x8(%esp)
f0101027:	f0 
f0101028:	c7 44 24 04 98 01 00 	movl   $0x198,0x4(%esp)
f010102f:	00 
f0101030:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101037:	e8 58 f0 ff ff       	call   f0100094 <_panic>
		*pte = pa | perm | PTE_P;
f010103c:	0b 7d d8             	or     -0x28(%ebp),%edi
f010103f:	89 38                	mov    %edi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int i;
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
	for (i = 0; i < size/PGSIZE; ++i, va += PGSIZE, pa += PGSIZE) {
f0101041:	83 c6 01             	add    $0x1,%esi
f0101044:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010104a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010104d:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
f0101050:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f0101053:	75 b0                	jne    f0101005 <boot_map_region+0x47>
		pte_t *pte = pgdir_walk(pgdir, (void *) va, 1);	//create
		if (!pte) panic("boot_map_region panic, out of memory");
		*pte = pa | perm | PTE_P;
	}
	cprintf("Virtual Address %x mapped to Physical Address %x\n", va, pa);
f0101055:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101059:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010105d:	c7 04 24 0c 43 10 f0 	movl   $0xf010430c,(%esp)
f0101064:	e8 9e 1c 00 00       	call   f0102d07 <cprintf>
}
f0101069:	83 c4 2c             	add    $0x2c,%esp
f010106c:	5b                   	pop    %ebx
f010106d:	5e                   	pop    %esi
f010106e:	5f                   	pop    %edi
f010106f:	5d                   	pop    %ebp
f0101070:	c3                   	ret    

f0101071 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101071:	55                   	push   %ebp
f0101072:	89 e5                	mov    %esp,%ebp
f0101074:	53                   	push   %ebx
f0101075:	83 ec 14             	sub    $0x14,%esp
f0101078:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pte = pgdir_walk(pgdir, va, 0);	//not create
f010107b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101082:	00 
f0101083:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101086:	89 44 24 04          	mov    %eax,0x4(%esp)
f010108a:	8b 45 08             	mov    0x8(%ebp),%eax
f010108d:	89 04 24             	mov    %eax,(%esp)
f0101090:	e8 89 fe ff ff       	call   f0100f1e <pgdir_walk>
	if (!pte || !(*pte & PTE_P)) return NULL;	//page not found
f0101095:	85 c0                	test   %eax,%eax
f0101097:	74 3f                	je     f01010d8 <page_lookup+0x67>
f0101099:	f6 00 01             	testb  $0x1,(%eax)
f010109c:	74 41                	je     f01010df <page_lookup+0x6e>
	if (pte_store)
f010109e:	85 db                	test   %ebx,%ebx
f01010a0:	74 02                	je     f01010a4 <page_lookup+0x33>
		*pte_store = pte;	//found and set
f01010a2:	89 03                	mov    %eax,(%ebx)
	return pa2page(PTE_ADDR(*pte));		
f01010a4:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010a6:	c1 e8 0c             	shr    $0xc,%eax
f01010a9:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f01010af:	72 1c                	jb     f01010cd <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f01010b1:	c7 44 24 08 68 43 10 	movl   $0xf0104368,0x8(%esp)
f01010b8:	f0 
f01010b9:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f01010c0:	00 
f01010c1:	c7 04 24 9c 49 10 f0 	movl   $0xf010499c,(%esp)
f01010c8:	e8 c7 ef ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f01010cd:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
f01010d3:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01010d6:	eb 0c                	jmp    f01010e4 <page_lookup+0x73>
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pte = pgdir_walk(pgdir, va, 0);	//not create
	if (!pte || !(*pte & PTE_P)) return NULL;	//page not found
f01010d8:	b8 00 00 00 00       	mov    $0x0,%eax
f01010dd:	eb 05                	jmp    f01010e4 <page_lookup+0x73>
f01010df:	b8 00 00 00 00       	mov    $0x0,%eax
	if (pte_store)
		*pte_store = pte;	//found and set
	return pa2page(PTE_ADDR(*pte));		
}
f01010e4:	83 c4 14             	add    $0x14,%esp
f01010e7:	5b                   	pop    %ebx
f01010e8:	5d                   	pop    %ebp
f01010e9:	c3                   	ret    

f01010ea <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01010ea:	55                   	push   %ebp
f01010eb:	89 e5                	mov    %esp,%ebp
f01010ed:	53                   	push   %ebx
f01010ee:	83 ec 24             	sub    $0x24,%esp
f01010f1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte;
	struct PageInfo *pg = page_lookup(pgdir, va, &pte);
f01010f4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01010f7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01010fb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0101102:	89 04 24             	mov    %eax,(%esp)
f0101105:	e8 67 ff ff ff       	call   f0101071 <page_lookup>
	if (!pg || !(*pte & PTE_P)) return;	//page not exist
f010110a:	85 c0                	test   %eax,%eax
f010110c:	74 1c                	je     f010112a <page_remove+0x40>
f010110e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101111:	f6 02 01             	testb  $0x1,(%edx)
f0101114:	74 14                	je     f010112a <page_remove+0x40>
//   - The ref count on the physical page should decrement.
//   - The physical page should be freed if the refcount reaches 0.
	page_decref(pg);
f0101116:	89 04 24             	mov    %eax,(%esp)
f0101119:	e8 dd fd ff ff       	call   f0100efb <page_decref>
//   - The pg table entry corresponding to 'va' should be set to 0.
	*pte = 0;
f010111e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101121:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101127:	0f 01 3b             	invlpg (%ebx)
//   - The TLB must be invalidated if you remove an entry from
//     the page table.
	tlb_invalidate(pgdir, va);
}
f010112a:	83 c4 24             	add    $0x24,%esp
f010112d:	5b                   	pop    %ebx
f010112e:	5d                   	pop    %ebp
f010112f:	c3                   	ret    

f0101130 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101130:	55                   	push   %ebp
f0101131:	89 e5                	mov    %esp,%ebp
f0101133:	57                   	push   %edi
f0101134:	56                   	push   %esi
f0101135:	53                   	push   %ebx
f0101136:	83 ec 1c             	sub    $0x1c,%esp
f0101139:	8b 75 0c             	mov    0xc(%ebp),%esi
f010113c:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte = pgdir_walk(pgdir, va, 1);	//create on demand
f010113f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101146:	00 
f0101147:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010114b:	8b 45 08             	mov    0x8(%ebp),%eax
f010114e:	89 04 24             	mov    %eax,(%esp)
f0101151:	e8 c8 fd ff ff       	call   f0100f1e <pgdir_walk>
f0101156:	89 c3                	mov    %eax,%ebx
	if (!pte) 	//page table not allocated
f0101158:	85 c0                	test   %eax,%eax
f010115a:	74 36                	je     f0101192 <page_insert+0x62>
		return -E_NO_MEM;	
	//increase ref count to avoid the corner case that pp is freed before it is inserted.
	pp->pp_ref++;	
f010115c:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	if (*pte & PTE_P) 	//page colides, tle is invalidated in page_remove
f0101161:	f6 00 01             	testb  $0x1,(%eax)
f0101164:	74 0f                	je     f0101175 <page_insert+0x45>
		page_remove(pgdir, va);
f0101166:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010116a:	8b 45 08             	mov    0x8(%ebp),%eax
f010116d:	89 04 24             	mov    %eax,(%esp)
f0101170:	e8 75 ff ff ff       	call   f01010ea <page_remove>
	*pte = page2pa(pp) | perm | PTE_P;
f0101175:	8b 45 14             	mov    0x14(%ebp),%eax
f0101178:	83 c8 01             	or     $0x1,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010117b:	2b 35 6c 79 11 f0    	sub    0xf011796c,%esi
f0101181:	c1 fe 03             	sar    $0x3,%esi
f0101184:	c1 e6 0c             	shl    $0xc,%esi
f0101187:	09 c6                	or     %eax,%esi
f0101189:	89 33                	mov    %esi,(%ebx)
	return 0;
f010118b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101190:	eb 05                	jmp    f0101197 <page_insert+0x67>
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *pte = pgdir_walk(pgdir, va, 1);	//create on demand
	if (!pte) 	//page table not allocated
		return -E_NO_MEM;	
f0101192:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	pp->pp_ref++;	
	if (*pte & PTE_P) 	//page colides, tle is invalidated in page_remove
		page_remove(pgdir, va);
	*pte = page2pa(pp) | perm | PTE_P;
	return 0;
}
f0101197:	83 c4 1c             	add    $0x1c,%esp
f010119a:	5b                   	pop    %ebx
f010119b:	5e                   	pop    %esi
f010119c:	5f                   	pop    %edi
f010119d:	5d                   	pop    %ebp
f010119e:	c3                   	ret    

f010119f <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010119f:	55                   	push   %ebp
f01011a0:	89 e5                	mov    %esp,%ebp
f01011a2:	57                   	push   %edi
f01011a3:	56                   	push   %esi
f01011a4:	53                   	push   %ebx
f01011a5:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01011a8:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f01011af:	e8 e3 1a 00 00       	call   f0102c97 <mc146818_read>
f01011b4:	89 c3                	mov    %eax,%ebx
f01011b6:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01011bd:	e8 d5 1a 00 00       	call   f0102c97 <mc146818_read>
f01011c2:	c1 e0 08             	shl    $0x8,%eax
f01011c5:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01011c7:	89 d8                	mov    %ebx,%eax
f01011c9:	c1 e0 0a             	shl    $0xa,%eax
f01011cc:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011d2:	85 c0                	test   %eax,%eax
f01011d4:	0f 48 c2             	cmovs  %edx,%eax
f01011d7:	c1 f8 0c             	sar    $0xc,%eax
f01011da:	a3 40 75 11 f0       	mov    %eax,0xf0117540
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01011df:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01011e6:	e8 ac 1a 00 00       	call   f0102c97 <mc146818_read>
f01011eb:	89 c3                	mov    %eax,%ebx
f01011ed:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01011f4:	e8 9e 1a 00 00       	call   f0102c97 <mc146818_read>
f01011f9:	c1 e0 08             	shl    $0x8,%eax
f01011fc:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01011fe:	89 d8                	mov    %ebx,%eax
f0101200:	c1 e0 0a             	shl    $0xa,%eax
f0101203:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101209:	85 c0                	test   %eax,%eax
f010120b:	0f 48 c2             	cmovs  %edx,%eax
f010120e:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101211:	85 c0                	test   %eax,%eax
f0101213:	74 0e                	je     f0101223 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101215:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010121b:	89 15 64 79 11 f0    	mov    %edx,0xf0117964
f0101221:	eb 0c                	jmp    f010122f <mem_init+0x90>
	else
		npages = npages_basemem;
f0101223:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
f0101229:	89 15 64 79 11 f0    	mov    %edx,0xf0117964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f010122f:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101232:	c1 e8 0a             	shr    $0xa,%eax
f0101235:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101239:	a1 40 75 11 f0       	mov    0xf0117540,%eax
f010123e:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101241:	c1 e8 0a             	shr    $0xa,%eax
f0101244:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0101248:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f010124d:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101250:	c1 e8 0a             	shr    $0xa,%eax
f0101253:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101257:	c7 04 24 88 43 10 f0 	movl   $0xf0104388,(%esp)
f010125e:	e8 a4 1a 00 00       	call   f0102d07 <cprintf>
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.

	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101263:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101268:	e8 13 f7 ff ff       	call   f0100980 <boot_alloc>
f010126d:	a3 68 79 11 f0       	mov    %eax,0xf0117968
	memset(kern_pgdir, 0, PGSIZE);
f0101272:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101279:	00 
f010127a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101281:	00 
f0101282:	89 04 24             	mov    %eax,(%esp)
f0101285:	e8 dd 25 00 00       	call   f0103867 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010128a:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010128f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101294:	77 20                	ja     f01012b6 <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101296:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010129a:	c7 44 24 08 c4 43 10 	movl   $0xf01043c4,0x8(%esp)
f01012a1:	f0 
f01012a2:	c7 44 24 04 93 00 00 	movl   $0x93,0x4(%esp)
f01012a9:	00 
f01012aa:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01012b1:	e8 de ed ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01012b6:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01012bc:	83 ca 05             	or     $0x5,%edx
f01012bf:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(sizeof(struct PageInfo) * npages);
f01012c5:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01012ca:	c1 e0 03             	shl    $0x3,%eax
f01012cd:	e8 ae f6 ff ff       	call   f0100980 <boot_alloc>
f01012d2:	a3 6c 79 11 f0       	mov    %eax,0xf011796c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01012d7:	e8 eb fa ff ff       	call   f0100dc7 <page_init>

	check_page_free_list(1);
f01012dc:	b8 01 00 00 00       	mov    $0x1,%eax
f01012e1:	e8 8a f7 ff ff       	call   f0100a70 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01012e6:	83 3d 6c 79 11 f0 00 	cmpl   $0x0,0xf011796c
f01012ed:	75 1c                	jne    f010130b <mem_init+0x16c>
		panic("'pages' is a null pointer!");
f01012ef:	c7 44 24 08 6d 4a 10 	movl   $0xf0104a6d,0x8(%esp)
f01012f6:	f0 
f01012f7:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f01012fe:	00 
f01012ff:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101306:	e8 89 ed ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010130b:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f0101310:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101315:	eb 05                	jmp    f010131c <mem_init+0x17d>
		++nfree;
f0101317:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010131a:	8b 00                	mov    (%eax),%eax
f010131c:	85 c0                	test   %eax,%eax
f010131e:	75 f7                	jne    f0101317 <mem_init+0x178>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101320:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101327:	e8 35 fb ff ff       	call   f0100e61 <page_alloc>
f010132c:	89 c7                	mov    %eax,%edi
f010132e:	85 c0                	test   %eax,%eax
f0101330:	75 24                	jne    f0101356 <mem_init+0x1b7>
f0101332:	c7 44 24 0c 88 4a 10 	movl   $0xf0104a88,0xc(%esp)
f0101339:	f0 
f010133a:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101341:	f0 
f0101342:	c7 44 24 04 5c 02 00 	movl   $0x25c,0x4(%esp)
f0101349:	00 
f010134a:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101351:	e8 3e ed ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101356:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010135d:	e8 ff fa ff ff       	call   f0100e61 <page_alloc>
f0101362:	89 c6                	mov    %eax,%esi
f0101364:	85 c0                	test   %eax,%eax
f0101366:	75 24                	jne    f010138c <mem_init+0x1ed>
f0101368:	c7 44 24 0c 9e 4a 10 	movl   $0xf0104a9e,0xc(%esp)
f010136f:	f0 
f0101370:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101377:	f0 
f0101378:	c7 44 24 04 5d 02 00 	movl   $0x25d,0x4(%esp)
f010137f:	00 
f0101380:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101387:	e8 08 ed ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010138c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101393:	e8 c9 fa ff ff       	call   f0100e61 <page_alloc>
f0101398:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010139b:	85 c0                	test   %eax,%eax
f010139d:	75 24                	jne    f01013c3 <mem_init+0x224>
f010139f:	c7 44 24 0c b4 4a 10 	movl   $0xf0104ab4,0xc(%esp)
f01013a6:	f0 
f01013a7:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01013ae:	f0 
f01013af:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f01013b6:	00 
f01013b7:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01013be:	e8 d1 ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013c3:	39 f7                	cmp    %esi,%edi
f01013c5:	75 24                	jne    f01013eb <mem_init+0x24c>
f01013c7:	c7 44 24 0c ca 4a 10 	movl   $0xf0104aca,0xc(%esp)
f01013ce:	f0 
f01013cf:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01013d6:	f0 
f01013d7:	c7 44 24 04 61 02 00 	movl   $0x261,0x4(%esp)
f01013de:	00 
f01013df:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01013e6:	e8 a9 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013eb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01013ee:	39 c6                	cmp    %eax,%esi
f01013f0:	74 04                	je     f01013f6 <mem_init+0x257>
f01013f2:	39 c7                	cmp    %eax,%edi
f01013f4:	75 24                	jne    f010141a <mem_init+0x27b>
f01013f6:	c7 44 24 0c e8 43 10 	movl   $0xf01043e8,0xc(%esp)
f01013fd:	f0 
f01013fe:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101405:	f0 
f0101406:	c7 44 24 04 62 02 00 	movl   $0x262,0x4(%esp)
f010140d:	00 
f010140e:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101415:	e8 7a ec ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010141a:	8b 15 6c 79 11 f0    	mov    0xf011796c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101420:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f0101425:	c1 e0 0c             	shl    $0xc,%eax
f0101428:	89 f9                	mov    %edi,%ecx
f010142a:	29 d1                	sub    %edx,%ecx
f010142c:	c1 f9 03             	sar    $0x3,%ecx
f010142f:	c1 e1 0c             	shl    $0xc,%ecx
f0101432:	39 c1                	cmp    %eax,%ecx
f0101434:	72 24                	jb     f010145a <mem_init+0x2bb>
f0101436:	c7 44 24 0c dc 4a 10 	movl   $0xf0104adc,0xc(%esp)
f010143d:	f0 
f010143e:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101445:	f0 
f0101446:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f010144d:	00 
f010144e:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101455:	e8 3a ec ff ff       	call   f0100094 <_panic>
f010145a:	89 f1                	mov    %esi,%ecx
f010145c:	29 d1                	sub    %edx,%ecx
f010145e:	c1 f9 03             	sar    $0x3,%ecx
f0101461:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101464:	39 c8                	cmp    %ecx,%eax
f0101466:	77 24                	ja     f010148c <mem_init+0x2ed>
f0101468:	c7 44 24 0c f9 4a 10 	movl   $0xf0104af9,0xc(%esp)
f010146f:	f0 
f0101470:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101477:	f0 
f0101478:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f010147f:	00 
f0101480:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101487:	e8 08 ec ff ff       	call   f0100094 <_panic>
f010148c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010148f:	29 d1                	sub    %edx,%ecx
f0101491:	89 ca                	mov    %ecx,%edx
f0101493:	c1 fa 03             	sar    $0x3,%edx
f0101496:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101499:	39 d0                	cmp    %edx,%eax
f010149b:	77 24                	ja     f01014c1 <mem_init+0x322>
f010149d:	c7 44 24 0c 16 4b 10 	movl   $0xf0104b16,0xc(%esp)
f01014a4:	f0 
f01014a5:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01014ac:	f0 
f01014ad:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f01014b4:	00 
f01014b5:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01014bc:	e8 d3 eb ff ff       	call   f0100094 <_panic>


	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014c1:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01014c6:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01014c9:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01014d0:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014d3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014da:	e8 82 f9 ff ff       	call   f0100e61 <page_alloc>
f01014df:	85 c0                	test   %eax,%eax
f01014e1:	74 24                	je     f0101507 <mem_init+0x368>
f01014e3:	c7 44 24 0c 33 4b 10 	movl   $0xf0104b33,0xc(%esp)
f01014ea:	f0 
f01014eb:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01014f2:	f0 
f01014f3:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f01014fa:	00 
f01014fb:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101502:	e8 8d eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101507:	89 3c 24             	mov    %edi,(%esp)
f010150a:	e8 d7 f9 ff ff       	call   f0100ee6 <page_free>
	page_free(pp1);
f010150f:	89 34 24             	mov    %esi,(%esp)
f0101512:	e8 cf f9 ff ff       	call   f0100ee6 <page_free>
	page_free(pp2);
f0101517:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010151a:	89 04 24             	mov    %eax,(%esp)
f010151d:	e8 c4 f9 ff ff       	call   f0100ee6 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101522:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101529:	e8 33 f9 ff ff       	call   f0100e61 <page_alloc>
f010152e:	89 c6                	mov    %eax,%esi
f0101530:	85 c0                	test   %eax,%eax
f0101532:	75 24                	jne    f0101558 <mem_init+0x3b9>
f0101534:	c7 44 24 0c 88 4a 10 	movl   $0xf0104a88,0xc(%esp)
f010153b:	f0 
f010153c:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101543:	f0 
f0101544:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
f010154b:	00 
f010154c:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101553:	e8 3c eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101558:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010155f:	e8 fd f8 ff ff       	call   f0100e61 <page_alloc>
f0101564:	89 c7                	mov    %eax,%edi
f0101566:	85 c0                	test   %eax,%eax
f0101568:	75 24                	jne    f010158e <mem_init+0x3ef>
f010156a:	c7 44 24 0c 9e 4a 10 	movl   $0xf0104a9e,0xc(%esp)
f0101571:	f0 
f0101572:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101579:	f0 
f010157a:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f0101581:	00 
f0101582:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101589:	e8 06 eb ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010158e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101595:	e8 c7 f8 ff ff       	call   f0100e61 <page_alloc>
f010159a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010159d:	85 c0                	test   %eax,%eax
f010159f:	75 24                	jne    f01015c5 <mem_init+0x426>
f01015a1:	c7 44 24 0c b4 4a 10 	movl   $0xf0104ab4,0xc(%esp)
f01015a8:	f0 
f01015a9:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01015b0:	f0 
f01015b1:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
f01015b8:	00 
f01015b9:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01015c0:	e8 cf ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015c5:	39 fe                	cmp    %edi,%esi
f01015c7:	75 24                	jne    f01015ed <mem_init+0x44e>
f01015c9:	c7 44 24 0c ca 4a 10 	movl   $0xf0104aca,0xc(%esp)
f01015d0:	f0 
f01015d1:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01015d8:	f0 
f01015d9:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f01015e0:	00 
f01015e1:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01015e8:	e8 a7 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015f0:	39 c7                	cmp    %eax,%edi
f01015f2:	74 04                	je     f01015f8 <mem_init+0x459>
f01015f4:	39 c6                	cmp    %eax,%esi
f01015f6:	75 24                	jne    f010161c <mem_init+0x47d>
f01015f8:	c7 44 24 0c e8 43 10 	movl   $0xf01043e8,0xc(%esp)
f01015ff:	f0 
f0101600:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101607:	f0 
f0101608:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f010160f:	00 
f0101610:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101617:	e8 78 ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f010161c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101623:	e8 39 f8 ff ff       	call   f0100e61 <page_alloc>
f0101628:	85 c0                	test   %eax,%eax
f010162a:	74 24                	je     f0101650 <mem_init+0x4b1>
f010162c:	c7 44 24 0c 33 4b 10 	movl   $0xf0104b33,0xc(%esp)
f0101633:	f0 
f0101634:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f010163b:	f0 
f010163c:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f0101643:	00 
f0101644:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010164b:	e8 44 ea ff ff       	call   f0100094 <_panic>
f0101650:	89 f0                	mov    %esi,%eax
f0101652:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101658:	c1 f8 03             	sar    $0x3,%eax
f010165b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010165e:	89 c2                	mov    %eax,%edx
f0101660:	c1 ea 0c             	shr    $0xc,%edx
f0101663:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101669:	72 20                	jb     f010168b <mem_init+0x4ec>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010166b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010166f:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0101676:	f0 
f0101677:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010167e:	00 
f010167f:	c7 04 24 9c 49 10 f0 	movl   $0xf010499c,(%esp)
f0101686:	e8 09 ea ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010168b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101692:	00 
f0101693:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010169a:	00 
	return (void *)(pa + KERNBASE);
f010169b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016a0:	89 04 24             	mov    %eax,(%esp)
f01016a3:	e8 bf 21 00 00       	call   f0103867 <memset>
	page_free(pp0);
f01016a8:	89 34 24             	mov    %esi,(%esp)
f01016ab:	e8 36 f8 ff ff       	call   f0100ee6 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016b0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016b7:	e8 a5 f7 ff ff       	call   f0100e61 <page_alloc>
f01016bc:	85 c0                	test   %eax,%eax
f01016be:	75 24                	jne    f01016e4 <mem_init+0x545>
f01016c0:	c7 44 24 0c 42 4b 10 	movl   $0xf0104b42,0xc(%esp)
f01016c7:	f0 
f01016c8:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01016cf:	f0 
f01016d0:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f01016d7:	00 
f01016d8:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01016df:	e8 b0 e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f01016e4:	39 c6                	cmp    %eax,%esi
f01016e6:	74 24                	je     f010170c <mem_init+0x56d>
f01016e8:	c7 44 24 0c 60 4b 10 	movl   $0xf0104b60,0xc(%esp)
f01016ef:	f0 
f01016f0:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01016f7:	f0 
f01016f8:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f01016ff:	00 
f0101700:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101707:	e8 88 e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010170c:	89 f0                	mov    %esi,%eax
f010170e:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f0101714:	c1 f8 03             	sar    $0x3,%eax
f0101717:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010171a:	89 c2                	mov    %eax,%edx
f010171c:	c1 ea 0c             	shr    $0xc,%edx
f010171f:	3b 15 64 79 11 f0    	cmp    0xf0117964,%edx
f0101725:	72 20                	jb     f0101747 <mem_init+0x5a8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101727:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010172b:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0101732:	f0 
f0101733:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010173a:	00 
f010173b:	c7 04 24 9c 49 10 f0 	movl   $0xf010499c,(%esp)
f0101742:	e8 4d e9 ff ff       	call   f0100094 <_panic>
f0101747:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f010174d:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101753:	80 38 00             	cmpb   $0x0,(%eax)
f0101756:	74 24                	je     f010177c <mem_init+0x5dd>
f0101758:	c7 44 24 0c 70 4b 10 	movl   $0xf0104b70,0xc(%esp)
f010175f:	f0 
f0101760:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101767:	f0 
f0101768:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
f010176f:	00 
f0101770:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101777:	e8 18 e9 ff ff       	call   f0100094 <_panic>
f010177c:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010177f:	39 d0                	cmp    %edx,%eax
f0101781:	75 d0                	jne    f0101753 <mem_init+0x5b4>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101783:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101786:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f010178b:	89 34 24             	mov    %esi,(%esp)
f010178e:	e8 53 f7 ff ff       	call   f0100ee6 <page_free>
	page_free(pp1);
f0101793:	89 3c 24             	mov    %edi,(%esp)
f0101796:	e8 4b f7 ff ff       	call   f0100ee6 <page_free>
	page_free(pp2);
f010179b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010179e:	89 04 24             	mov    %eax,(%esp)
f01017a1:	e8 40 f7 ff ff       	call   f0100ee6 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017a6:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01017ab:	eb 05                	jmp    f01017b2 <mem_init+0x613>
		--nfree;
f01017ad:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017b0:	8b 00                	mov    (%eax),%eax
f01017b2:	85 c0                	test   %eax,%eax
f01017b4:	75 f7                	jne    f01017ad <mem_init+0x60e>
		--nfree;
	assert(nfree == 0);
f01017b6:	85 db                	test   %ebx,%ebx
f01017b8:	74 24                	je     f01017de <mem_init+0x63f>
f01017ba:	c7 44 24 0c 7a 4b 10 	movl   $0xf0104b7a,0xc(%esp)
f01017c1:	f0 
f01017c2:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01017c9:	f0 
f01017ca:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f01017d1:	00 
f01017d2:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01017d9:	e8 b6 e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017de:	c7 04 24 08 44 10 f0 	movl   $0xf0104408,(%esp)
f01017e5:	e8 1d 15 00 00       	call   f0102d07 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017f1:	e8 6b f6 ff ff       	call   f0100e61 <page_alloc>
f01017f6:	89 c6                	mov    %eax,%esi
f01017f8:	85 c0                	test   %eax,%eax
f01017fa:	75 24                	jne    f0101820 <mem_init+0x681>
f01017fc:	c7 44 24 0c 88 4a 10 	movl   $0xf0104a88,0xc(%esp)
f0101803:	f0 
f0101804:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f010180b:	f0 
f010180c:	c7 44 24 04 e8 02 00 	movl   $0x2e8,0x4(%esp)
f0101813:	00 
f0101814:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010181b:	e8 74 e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101820:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101827:	e8 35 f6 ff ff       	call   f0100e61 <page_alloc>
f010182c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010182f:	85 c0                	test   %eax,%eax
f0101831:	75 24                	jne    f0101857 <mem_init+0x6b8>
f0101833:	c7 44 24 0c 9e 4a 10 	movl   $0xf0104a9e,0xc(%esp)
f010183a:	f0 
f010183b:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101842:	f0 
f0101843:	c7 44 24 04 e9 02 00 	movl   $0x2e9,0x4(%esp)
f010184a:	00 
f010184b:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101852:	e8 3d e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101857:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010185e:	e8 fe f5 ff ff       	call   f0100e61 <page_alloc>
f0101863:	89 c3                	mov    %eax,%ebx
f0101865:	85 c0                	test   %eax,%eax
f0101867:	75 24                	jne    f010188d <mem_init+0x6ee>
f0101869:	c7 44 24 0c b4 4a 10 	movl   $0xf0104ab4,0xc(%esp)
f0101870:	f0 
f0101871:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101878:	f0 
f0101879:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f0101880:	00 
f0101881:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101888:	e8 07 e8 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010188d:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101890:	75 24                	jne    f01018b6 <mem_init+0x717>
f0101892:	c7 44 24 0c ca 4a 10 	movl   $0xf0104aca,0xc(%esp)
f0101899:	f0 
f010189a:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01018a1:	f0 
f01018a2:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f01018a9:	00 
f01018aa:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01018b1:	e8 de e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018b6:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018b9:	74 04                	je     f01018bf <mem_init+0x720>
f01018bb:	39 c6                	cmp    %eax,%esi
f01018bd:	75 24                	jne    f01018e3 <mem_init+0x744>
f01018bf:	c7 44 24 0c e8 43 10 	movl   $0xf01043e8,0xc(%esp)
f01018c6:	f0 
f01018c7:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01018ce:	f0 
f01018cf:	c7 44 24 04 ee 02 00 	movl   $0x2ee,0x4(%esp)
f01018d6:	00 
f01018d7:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01018de:	e8 b1 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01018e3:	a1 3c 75 11 f0       	mov    0xf011753c,%eax
f01018e8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01018eb:	c7 05 3c 75 11 f0 00 	movl   $0x0,0xf011753c
f01018f2:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018f5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018fc:	e8 60 f5 ff ff       	call   f0100e61 <page_alloc>
f0101901:	85 c0                	test   %eax,%eax
f0101903:	74 24                	je     f0101929 <mem_init+0x78a>
f0101905:	c7 44 24 0c 33 4b 10 	movl   $0xf0104b33,0xc(%esp)
f010190c:	f0 
f010190d:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101914:	f0 
f0101915:	c7 44 24 04 f5 02 00 	movl   $0x2f5,0x4(%esp)
f010191c:	00 
f010191d:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101924:	e8 6b e7 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101929:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010192c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101930:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101937:	00 
f0101938:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010193d:	89 04 24             	mov    %eax,(%esp)
f0101940:	e8 2c f7 ff ff       	call   f0101071 <page_lookup>
f0101945:	85 c0                	test   %eax,%eax
f0101947:	74 24                	je     f010196d <mem_init+0x7ce>
f0101949:	c7 44 24 0c 28 44 10 	movl   $0xf0104428,0xc(%esp)
f0101950:	f0 
f0101951:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101958:	f0 
f0101959:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0101960:	00 
f0101961:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101968:	e8 27 e7 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010196d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101974:	00 
f0101975:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010197c:	00 
f010197d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101980:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101984:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101989:	89 04 24             	mov    %eax,(%esp)
f010198c:	e8 9f f7 ff ff       	call   f0101130 <page_insert>
f0101991:	85 c0                	test   %eax,%eax
f0101993:	78 24                	js     f01019b9 <mem_init+0x81a>
f0101995:	c7 44 24 0c 60 44 10 	movl   $0xf0104460,0xc(%esp)
f010199c:	f0 
f010199d:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01019a4:	f0 
f01019a5:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f01019ac:	00 
f01019ad:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01019b4:	e8 db e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019b9:	89 34 24             	mov    %esi,(%esp)
f01019bc:	e8 25 f5 ff ff       	call   f0100ee6 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019c1:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019c8:	00 
f01019c9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019d0:	00 
f01019d1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019d8:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01019dd:	89 04 24             	mov    %eax,(%esp)
f01019e0:	e8 4b f7 ff ff       	call   f0101130 <page_insert>
f01019e5:	85 c0                	test   %eax,%eax
f01019e7:	74 24                	je     f0101a0d <mem_init+0x86e>
f01019e9:	c7 44 24 0c 90 44 10 	movl   $0xf0104490,0xc(%esp)
f01019f0:	f0 
f01019f1:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01019f8:	f0 
f01019f9:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f0101a00:	00 
f0101a01:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101a08:	e8 87 e6 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a0d:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a13:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f0101a18:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a1b:	8b 17                	mov    (%edi),%edx
f0101a1d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a23:	89 f1                	mov    %esi,%ecx
f0101a25:	29 c1                	sub    %eax,%ecx
f0101a27:	89 c8                	mov    %ecx,%eax
f0101a29:	c1 f8 03             	sar    $0x3,%eax
f0101a2c:	c1 e0 0c             	shl    $0xc,%eax
f0101a2f:	39 c2                	cmp    %eax,%edx
f0101a31:	74 24                	je     f0101a57 <mem_init+0x8b8>
f0101a33:	c7 44 24 0c c0 44 10 	movl   $0xf01044c0,0xc(%esp)
f0101a3a:	f0 
f0101a3b:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101a42:	f0 
f0101a43:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
f0101a4a:	00 
f0101a4b:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101a52:	e8 3d e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a57:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a5c:	89 f8                	mov    %edi,%eax
f0101a5e:	e8 9e ef ff ff       	call   f0100a01 <check_va2pa>
f0101a63:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101a66:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101a69:	c1 fa 03             	sar    $0x3,%edx
f0101a6c:	c1 e2 0c             	shl    $0xc,%edx
f0101a6f:	39 d0                	cmp    %edx,%eax
f0101a71:	74 24                	je     f0101a97 <mem_init+0x8f8>
f0101a73:	c7 44 24 0c e8 44 10 	movl   $0xf01044e8,0xc(%esp)
f0101a7a:	f0 
f0101a7b:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101a82:	f0 
f0101a83:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
f0101a8a:	00 
f0101a8b:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101a92:	e8 fd e5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101a97:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a9a:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101a9f:	74 24                	je     f0101ac5 <mem_init+0x926>
f0101aa1:	c7 44 24 0c 85 4b 10 	movl   $0xf0104b85,0xc(%esp)
f0101aa8:	f0 
f0101aa9:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101ab0:	f0 
f0101ab1:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0101ab8:	00 
f0101ab9:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101ac0:	e8 cf e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101ac5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101aca:	74 24                	je     f0101af0 <mem_init+0x951>
f0101acc:	c7 44 24 0c 96 4b 10 	movl   $0xf0104b96,0xc(%esp)
f0101ad3:	f0 
f0101ad4:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101adb:	f0 
f0101adc:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101ae3:	00 
f0101ae4:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101aeb:	e8 a4 e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101af0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101af7:	00 
f0101af8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101aff:	00 
f0101b00:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101b04:	89 3c 24             	mov    %edi,(%esp)
f0101b07:	e8 24 f6 ff ff       	call   f0101130 <page_insert>
f0101b0c:	85 c0                	test   %eax,%eax
f0101b0e:	74 24                	je     f0101b34 <mem_init+0x995>
f0101b10:	c7 44 24 0c 18 45 10 	movl   $0xf0104518,0xc(%esp)
f0101b17:	f0 
f0101b18:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101b1f:	f0 
f0101b20:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0101b27:	00 
f0101b28:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101b2f:	e8 60 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b34:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b39:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101b3e:	e8 be ee ff ff       	call   f0100a01 <check_va2pa>
f0101b43:	89 da                	mov    %ebx,%edx
f0101b45:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101b4b:	c1 fa 03             	sar    $0x3,%edx
f0101b4e:	c1 e2 0c             	shl    $0xc,%edx
f0101b51:	39 d0                	cmp    %edx,%eax
f0101b53:	74 24                	je     f0101b79 <mem_init+0x9da>
f0101b55:	c7 44 24 0c 54 45 10 	movl   $0xf0104554,0xc(%esp)
f0101b5c:	f0 
f0101b5d:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101b64:	f0 
f0101b65:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0101b6c:	00 
f0101b6d:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101b74:	e8 1b e5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101b79:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b7e:	74 24                	je     f0101ba4 <mem_init+0xa05>
f0101b80:	c7 44 24 0c a7 4b 10 	movl   $0xf0104ba7,0xc(%esp)
f0101b87:	f0 
f0101b88:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101b8f:	f0 
f0101b90:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f0101b97:	00 
f0101b98:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101b9f:	e8 f0 e4 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ba4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bab:	e8 b1 f2 ff ff       	call   f0100e61 <page_alloc>
f0101bb0:	85 c0                	test   %eax,%eax
f0101bb2:	74 24                	je     f0101bd8 <mem_init+0xa39>
f0101bb4:	c7 44 24 0c 33 4b 10 	movl   $0xf0104b33,0xc(%esp)
f0101bbb:	f0 
f0101bbc:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101bc3:	f0 
f0101bc4:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0101bcb:	00 
f0101bcc:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101bd3:	e8 bc e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bd8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bdf:	00 
f0101be0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101be7:	00 
f0101be8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101bec:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101bf1:	89 04 24             	mov    %eax,(%esp)
f0101bf4:	e8 37 f5 ff ff       	call   f0101130 <page_insert>
f0101bf9:	85 c0                	test   %eax,%eax
f0101bfb:	74 24                	je     f0101c21 <mem_init+0xa82>
f0101bfd:	c7 44 24 0c 18 45 10 	movl   $0xf0104518,0xc(%esp)
f0101c04:	f0 
f0101c05:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101c0c:	f0 
f0101c0d:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101c14:	00 
f0101c15:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101c1c:	e8 73 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c21:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c26:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101c2b:	e8 d1 ed ff ff       	call   f0100a01 <check_va2pa>
f0101c30:	89 da                	mov    %ebx,%edx
f0101c32:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101c38:	c1 fa 03             	sar    $0x3,%edx
f0101c3b:	c1 e2 0c             	shl    $0xc,%edx
f0101c3e:	39 d0                	cmp    %edx,%eax
f0101c40:	74 24                	je     f0101c66 <mem_init+0xac7>
f0101c42:	c7 44 24 0c 54 45 10 	movl   $0xf0104554,0xc(%esp)
f0101c49:	f0 
f0101c4a:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101c51:	f0 
f0101c52:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0101c59:	00 
f0101c5a:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101c61:	e8 2e e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c66:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c6b:	74 24                	je     f0101c91 <mem_init+0xaf2>
f0101c6d:	c7 44 24 0c a7 4b 10 	movl   $0xf0104ba7,0xc(%esp)
f0101c74:	f0 
f0101c75:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101c7c:	f0 
f0101c7d:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f0101c84:	00 
f0101c85:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101c8c:	e8 03 e4 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c91:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c98:	e8 c4 f1 ff ff       	call   f0100e61 <page_alloc>
f0101c9d:	85 c0                	test   %eax,%eax
f0101c9f:	74 24                	je     f0101cc5 <mem_init+0xb26>
f0101ca1:	c7 44 24 0c 33 4b 10 	movl   $0xf0104b33,0xc(%esp)
f0101ca8:	f0 
f0101ca9:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101cb0:	f0 
f0101cb1:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0101cb8:	00 
f0101cb9:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101cc0:	e8 cf e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101cc5:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0101ccb:	8b 02                	mov    (%edx),%eax
f0101ccd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101cd2:	89 c1                	mov    %eax,%ecx
f0101cd4:	c1 e9 0c             	shr    $0xc,%ecx
f0101cd7:	3b 0d 64 79 11 f0    	cmp    0xf0117964,%ecx
f0101cdd:	72 20                	jb     f0101cff <mem_init+0xb60>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101cdf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101ce3:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0101cea:	f0 
f0101ceb:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101cf2:	00 
f0101cf3:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101cfa:	e8 95 e3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101cff:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d04:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d07:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d0e:	00 
f0101d0f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d16:	00 
f0101d17:	89 14 24             	mov    %edx,(%esp)
f0101d1a:	e8 ff f1 ff ff       	call   f0100f1e <pgdir_walk>
f0101d1f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d22:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d25:	39 d0                	cmp    %edx,%eax
f0101d27:	74 24                	je     f0101d4d <mem_init+0xbae>
f0101d29:	c7 44 24 0c 84 45 10 	movl   $0xf0104584,0xc(%esp)
f0101d30:	f0 
f0101d31:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101d38:	f0 
f0101d39:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f0101d40:	00 
f0101d41:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101d48:	e8 47 e3 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d4d:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101d54:	00 
f0101d55:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d5c:	00 
f0101d5d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d61:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101d66:	89 04 24             	mov    %eax,(%esp)
f0101d69:	e8 c2 f3 ff ff       	call   f0101130 <page_insert>
f0101d6e:	85 c0                	test   %eax,%eax
f0101d70:	74 24                	je     f0101d96 <mem_init+0xbf7>
f0101d72:	c7 44 24 0c c4 45 10 	movl   $0xf01045c4,0xc(%esp)
f0101d79:	f0 
f0101d7a:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101d81:	f0 
f0101d82:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101d89:	00 
f0101d8a:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101d91:	e8 fe e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d96:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0101d9c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101da1:	89 f8                	mov    %edi,%eax
f0101da3:	e8 59 ec ff ff       	call   f0100a01 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101da8:	89 da                	mov    %ebx,%edx
f0101daa:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0101db0:	c1 fa 03             	sar    $0x3,%edx
f0101db3:	c1 e2 0c             	shl    $0xc,%edx
f0101db6:	39 d0                	cmp    %edx,%eax
f0101db8:	74 24                	je     f0101dde <mem_init+0xc3f>
f0101dba:	c7 44 24 0c 54 45 10 	movl   $0xf0104554,0xc(%esp)
f0101dc1:	f0 
f0101dc2:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101dc9:	f0 
f0101dca:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0101dd1:	00 
f0101dd2:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101dd9:	e8 b6 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101dde:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101de3:	74 24                	je     f0101e09 <mem_init+0xc6a>
f0101de5:	c7 44 24 0c a7 4b 10 	movl   $0xf0104ba7,0xc(%esp)
f0101dec:	f0 
f0101ded:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101df4:	f0 
f0101df5:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0101dfc:	00 
f0101dfd:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101e04:	e8 8b e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e09:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e10:	00 
f0101e11:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e18:	00 
f0101e19:	89 3c 24             	mov    %edi,(%esp)
f0101e1c:	e8 fd f0 ff ff       	call   f0100f1e <pgdir_walk>
f0101e21:	f6 00 04             	testb  $0x4,(%eax)
f0101e24:	75 24                	jne    f0101e4a <mem_init+0xcab>
f0101e26:	c7 44 24 0c 04 46 10 	movl   $0xf0104604,0xc(%esp)
f0101e2d:	f0 
f0101e2e:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101e35:	f0 
f0101e36:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0101e3d:	00 
f0101e3e:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101e45:	e8 4a e2 ff ff       	call   f0100094 <_panic>
	cprintf("pp2 %x\n", pp2);
f0101e4a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e4e:	c7 04 24 b8 4b 10 f0 	movl   $0xf0104bb8,(%esp)
f0101e55:	e8 ad 0e 00 00       	call   f0102d07 <cprintf>
	cprintf("kern_pgdir %x\n", kern_pgdir);
f0101e5a:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101e5f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101e63:	c7 04 24 c0 4b 10 f0 	movl   $0xf0104bc0,(%esp)
f0101e6a:	e8 98 0e 00 00       	call   f0102d07 <cprintf>
	cprintf("kern_pgdir[0] is %x\n", kern_pgdir[0]);
f0101e6f:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101e74:	8b 00                	mov    (%eax),%eax
f0101e76:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101e7a:	c7 04 24 cf 4b 10 f0 	movl   $0xf0104bcf,(%esp)
f0101e81:	e8 81 0e 00 00       	call   f0102d07 <cprintf>
	assert(kern_pgdir[0] & PTE_U);
f0101e86:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101e8b:	f6 00 04             	testb  $0x4,(%eax)
f0101e8e:	75 24                	jne    f0101eb4 <mem_init+0xd15>
f0101e90:	c7 44 24 0c e4 4b 10 	movl   $0xf0104be4,0xc(%esp)
f0101e97:	f0 
f0101e98:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101e9f:	f0 
f0101ea0:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101ea7:	00 
f0101ea8:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101eaf:	e8 e0 e1 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101eb4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ebb:	00 
f0101ebc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ec3:	00 
f0101ec4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101ec8:	89 04 24             	mov    %eax,(%esp)
f0101ecb:	e8 60 f2 ff ff       	call   f0101130 <page_insert>
f0101ed0:	85 c0                	test   %eax,%eax
f0101ed2:	74 24                	je     f0101ef8 <mem_init+0xd59>
f0101ed4:	c7 44 24 0c 18 45 10 	movl   $0xf0104518,0xc(%esp)
f0101edb:	f0 
f0101edc:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101ee3:	f0 
f0101ee4:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101eeb:	00 
f0101eec:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101ef3:	e8 9c e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ef8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101eff:	00 
f0101f00:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f07:	00 
f0101f08:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f0d:	89 04 24             	mov    %eax,(%esp)
f0101f10:	e8 09 f0 ff ff       	call   f0100f1e <pgdir_walk>
f0101f15:	f6 00 02             	testb  $0x2,(%eax)
f0101f18:	75 24                	jne    f0101f3e <mem_init+0xd9f>
f0101f1a:	c7 44 24 0c 38 46 10 	movl   $0xf0104638,0xc(%esp)
f0101f21:	f0 
f0101f22:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101f29:	f0 
f0101f2a:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101f31:	00 
f0101f32:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101f39:	e8 56 e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f3e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f45:	00 
f0101f46:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f4d:	00 
f0101f4e:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f53:	89 04 24             	mov    %eax,(%esp)
f0101f56:	e8 c3 ef ff ff       	call   f0100f1e <pgdir_walk>
f0101f5b:	f6 00 04             	testb  $0x4,(%eax)
f0101f5e:	74 24                	je     f0101f84 <mem_init+0xde5>
f0101f60:	c7 44 24 0c 6c 46 10 	movl   $0xf010466c,0xc(%esp)
f0101f67:	f0 
f0101f68:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101f6f:	f0 
f0101f70:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101f77:	00 
f0101f78:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101f7f:	e8 10 e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f84:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f8b:	00 
f0101f8c:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101f93:	00 
f0101f94:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f98:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101f9d:	89 04 24             	mov    %eax,(%esp)
f0101fa0:	e8 8b f1 ff ff       	call   f0101130 <page_insert>
f0101fa5:	85 c0                	test   %eax,%eax
f0101fa7:	78 24                	js     f0101fcd <mem_init+0xe2e>
f0101fa9:	c7 44 24 0c a4 46 10 	movl   $0xf01046a4,0xc(%esp)
f0101fb0:	f0 
f0101fb1:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0101fb8:	f0 
f0101fb9:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101fc0:	00 
f0101fc1:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0101fc8:	e8 c7 e0 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101fcd:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fd4:	00 
f0101fd5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fdc:	00 
f0101fdd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fe0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101fe4:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0101fe9:	89 04 24             	mov    %eax,(%esp)
f0101fec:	e8 3f f1 ff ff       	call   f0101130 <page_insert>
f0101ff1:	85 c0                	test   %eax,%eax
f0101ff3:	74 24                	je     f0102019 <mem_init+0xe7a>
f0101ff5:	c7 44 24 0c dc 46 10 	movl   $0xf01046dc,0xc(%esp)
f0101ffc:	f0 
f0101ffd:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102004:	f0 
f0102005:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f010200c:	00 
f010200d:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102014:	e8 7b e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102019:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102020:	00 
f0102021:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102028:	00 
f0102029:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010202e:	89 04 24             	mov    %eax,(%esp)
f0102031:	e8 e8 ee ff ff       	call   f0100f1e <pgdir_walk>
f0102036:	f6 00 04             	testb  $0x4,(%eax)
f0102039:	74 24                	je     f010205f <mem_init+0xec0>
f010203b:	c7 44 24 0c 6c 46 10 	movl   $0xf010466c,0xc(%esp)
f0102042:	f0 
f0102043:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f010204a:	f0 
f010204b:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0102052:	00 
f0102053:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010205a:	e8 35 e0 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010205f:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0102065:	ba 00 00 00 00       	mov    $0x0,%edx
f010206a:	89 f8                	mov    %edi,%eax
f010206c:	e8 90 e9 ff ff       	call   f0100a01 <check_va2pa>
f0102071:	89 c1                	mov    %eax,%ecx
f0102073:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102076:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102079:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f010207f:	c1 f8 03             	sar    $0x3,%eax
f0102082:	c1 e0 0c             	shl    $0xc,%eax
f0102085:	39 c1                	cmp    %eax,%ecx
f0102087:	74 24                	je     f01020ad <mem_init+0xf0e>
f0102089:	c7 44 24 0c 18 47 10 	movl   $0xf0104718,0xc(%esp)
f0102090:	f0 
f0102091:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102098:	f0 
f0102099:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f01020a0:	00 
f01020a1:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01020a8:	e8 e7 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020ad:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020b2:	89 f8                	mov    %edi,%eax
f01020b4:	e8 48 e9 ff ff       	call   f0100a01 <check_va2pa>
f01020b9:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01020bc:	74 24                	je     f01020e2 <mem_init+0xf43>
f01020be:	c7 44 24 0c 44 47 10 	movl   $0xf0104744,0xc(%esp)
f01020c5:	f0 
f01020c6:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01020cd:	f0 
f01020ce:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f01020d5:	00 
f01020d6:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01020dd:	e8 b2 df ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01020e2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020e5:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f01020ea:	74 24                	je     f0102110 <mem_init+0xf71>
f01020ec:	c7 44 24 0c fa 4b 10 	movl   $0xf0104bfa,0xc(%esp)
f01020f3:	f0 
f01020f4:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01020fb:	f0 
f01020fc:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f0102103:	00 
f0102104:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010210b:	e8 84 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102110:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102115:	74 24                	je     f010213b <mem_init+0xf9c>
f0102117:	c7 44 24 0c 0b 4c 10 	movl   $0xf0104c0b,0xc(%esp)
f010211e:	f0 
f010211f:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102126:	f0 
f0102127:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f010212e:	00 
f010212f:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102136:	e8 59 df ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010213b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102142:	e8 1a ed ff ff       	call   f0100e61 <page_alloc>
f0102147:	85 c0                	test   %eax,%eax
f0102149:	74 04                	je     f010214f <mem_init+0xfb0>
f010214b:	39 c3                	cmp    %eax,%ebx
f010214d:	74 24                	je     f0102173 <mem_init+0xfd4>
f010214f:	c7 44 24 0c 74 47 10 	movl   $0xf0104774,0xc(%esp)
f0102156:	f0 
f0102157:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f010215e:	f0 
f010215f:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0102166:	00 
f0102167:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010216e:	e8 21 df ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102173:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010217a:	00 
f010217b:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102180:	89 04 24             	mov    %eax,(%esp)
f0102183:	e8 62 ef ff ff       	call   f01010ea <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102188:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f010218e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102193:	89 f8                	mov    %edi,%eax
f0102195:	e8 67 e8 ff ff       	call   f0100a01 <check_va2pa>
f010219a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010219d:	74 24                	je     f01021c3 <mem_init+0x1024>
f010219f:	c7 44 24 0c 98 47 10 	movl   $0xf0104798,0xc(%esp)
f01021a6:	f0 
f01021a7:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01021ae:	f0 
f01021af:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f01021b6:	00 
f01021b7:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01021be:	e8 d1 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01021c3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021c8:	89 f8                	mov    %edi,%eax
f01021ca:	e8 32 e8 ff ff       	call   f0100a01 <check_va2pa>
f01021cf:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01021d2:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01021d8:	c1 fa 03             	sar    $0x3,%edx
f01021db:	c1 e2 0c             	shl    $0xc,%edx
f01021de:	39 d0                	cmp    %edx,%eax
f01021e0:	74 24                	je     f0102206 <mem_init+0x1067>
f01021e2:	c7 44 24 0c 44 47 10 	movl   $0xf0104744,0xc(%esp)
f01021e9:	f0 
f01021ea:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01021f1:	f0 
f01021f2:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f01021f9:	00 
f01021fa:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102201:	e8 8e de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102206:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102209:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010220e:	74 24                	je     f0102234 <mem_init+0x1095>
f0102210:	c7 44 24 0c 85 4b 10 	movl   $0xf0104b85,0xc(%esp)
f0102217:	f0 
f0102218:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f010221f:	f0 
f0102220:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0102227:	00 
f0102228:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010222f:	e8 60 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102234:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102239:	74 24                	je     f010225f <mem_init+0x10c0>
f010223b:	c7 44 24 0c 0b 4c 10 	movl   $0xf0104c0b,0xc(%esp)
f0102242:	f0 
f0102243:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f010224a:	f0 
f010224b:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0102252:	00 
f0102253:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010225a:	e8 35 de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010225f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102266:	00 
f0102267:	89 3c 24             	mov    %edi,(%esp)
f010226a:	e8 7b ee ff ff       	call   f01010ea <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010226f:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi
f0102275:	ba 00 00 00 00       	mov    $0x0,%edx
f010227a:	89 f8                	mov    %edi,%eax
f010227c:	e8 80 e7 ff ff       	call   f0100a01 <check_va2pa>
f0102281:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102284:	74 24                	je     f01022aa <mem_init+0x110b>
f0102286:	c7 44 24 0c 98 47 10 	movl   $0xf0104798,0xc(%esp)
f010228d:	f0 
f010228e:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102295:	f0 
f0102296:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f010229d:	00 
f010229e:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01022a5:	e8 ea dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01022aa:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022af:	89 f8                	mov    %edi,%eax
f01022b1:	e8 4b e7 ff ff       	call   f0100a01 <check_va2pa>
f01022b6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022b9:	74 24                	je     f01022df <mem_init+0x1140>
f01022bb:	c7 44 24 0c bc 47 10 	movl   $0xf01047bc,0xc(%esp)
f01022c2:	f0 
f01022c3:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01022ca:	f0 
f01022cb:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f01022d2:	00 
f01022d3:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01022da:	e8 b5 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01022df:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022e2:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01022e7:	74 24                	je     f010230d <mem_init+0x116e>
f01022e9:	c7 44 24 0c 1c 4c 10 	movl   $0xf0104c1c,0xc(%esp)
f01022f0:	f0 
f01022f1:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01022f8:	f0 
f01022f9:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0102300:	00 
f0102301:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102308:	e8 87 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010230d:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102312:	74 24                	je     f0102338 <mem_init+0x1199>
f0102314:	c7 44 24 0c 0b 4c 10 	movl   $0xf0104c0b,0xc(%esp)
f010231b:	f0 
f010231c:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102323:	f0 
f0102324:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f010232b:	00 
f010232c:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102333:	e8 5c dd ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102338:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010233f:	e8 1d eb ff ff       	call   f0100e61 <page_alloc>
f0102344:	85 c0                	test   %eax,%eax
f0102346:	74 05                	je     f010234d <mem_init+0x11ae>
f0102348:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010234b:	74 24                	je     f0102371 <mem_init+0x11d2>
f010234d:	c7 44 24 0c e4 47 10 	movl   $0xf01047e4,0xc(%esp)
f0102354:	f0 
f0102355:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f010235c:	f0 
f010235d:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0102364:	00 
f0102365:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010236c:	e8 23 dd ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102371:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102378:	e8 e4 ea ff ff       	call   f0100e61 <page_alloc>
f010237d:	85 c0                	test   %eax,%eax
f010237f:	74 24                	je     f01023a5 <mem_init+0x1206>
f0102381:	c7 44 24 0c 33 4b 10 	movl   $0xf0104b33,0xc(%esp)
f0102388:	f0 
f0102389:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102390:	f0 
f0102391:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0102398:	00 
f0102399:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01023a0:	e8 ef dc ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01023a5:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01023aa:	8b 08                	mov    (%eax),%ecx
f01023ac:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01023b2:	89 f2                	mov    %esi,%edx
f01023b4:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f01023ba:	c1 fa 03             	sar    $0x3,%edx
f01023bd:	c1 e2 0c             	shl    $0xc,%edx
f01023c0:	39 d1                	cmp    %edx,%ecx
f01023c2:	74 24                	je     f01023e8 <mem_init+0x1249>
f01023c4:	c7 44 24 0c c0 44 10 	movl   $0xf01044c0,0xc(%esp)
f01023cb:	f0 
f01023cc:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01023d3:	f0 
f01023d4:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f01023db:	00 
f01023dc:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01023e3:	e8 ac dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01023e8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01023ee:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01023f3:	74 24                	je     f0102419 <mem_init+0x127a>
f01023f5:	c7 44 24 0c 96 4b 10 	movl   $0xf0104b96,0xc(%esp)
f01023fc:	f0 
f01023fd:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102404:	f0 
f0102405:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f010240c:	00 
f010240d:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102414:	e8 7b dc ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102419:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010241f:	89 34 24             	mov    %esi,(%esp)
f0102422:	e8 bf ea ff ff       	call   f0100ee6 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102427:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010242e:	00 
f010242f:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102436:	00 
f0102437:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f010243c:	89 04 24             	mov    %eax,(%esp)
f010243f:	e8 da ea ff ff       	call   f0100f1e <pgdir_walk>
f0102444:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102447:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010244a:	8b 15 68 79 11 f0    	mov    0xf0117968,%edx
f0102450:	8b 7a 04             	mov    0x4(%edx),%edi
f0102453:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102459:	8b 0d 64 79 11 f0    	mov    0xf0117964,%ecx
f010245f:	89 f8                	mov    %edi,%eax
f0102461:	c1 e8 0c             	shr    $0xc,%eax
f0102464:	39 c8                	cmp    %ecx,%eax
f0102466:	72 20                	jb     f0102488 <mem_init+0x12e9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102468:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010246c:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0102473:	f0 
f0102474:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f010247b:	00 
f010247c:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102483:	e8 0c dc ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102488:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f010248e:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102491:	74 24                	je     f01024b7 <mem_init+0x1318>
f0102493:	c7 44 24 0c 2d 4c 10 	movl   $0xf0104c2d,0xc(%esp)
f010249a:	f0 
f010249b:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01024a2:	f0 
f01024a3:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f01024aa:	00 
f01024ab:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01024b2:	e8 dd db ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01024b7:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01024be:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024c4:	89 f0                	mov    %esi,%eax
f01024c6:	2b 05 6c 79 11 f0    	sub    0xf011796c,%eax
f01024cc:	c1 f8 03             	sar    $0x3,%eax
f01024cf:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024d2:	89 c2                	mov    %eax,%edx
f01024d4:	c1 ea 0c             	shr    $0xc,%edx
f01024d7:	39 d1                	cmp    %edx,%ecx
f01024d9:	77 20                	ja     f01024fb <mem_init+0x135c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024db:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01024df:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f01024e6:	f0 
f01024e7:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01024ee:	00 
f01024ef:	c7 04 24 9c 49 10 f0 	movl   $0xf010499c,(%esp)
f01024f6:	e8 99 db ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01024fb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102502:	00 
f0102503:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010250a:	00 
	return (void *)(pa + KERNBASE);
f010250b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102510:	89 04 24             	mov    %eax,(%esp)
f0102513:	e8 4f 13 00 00       	call   f0103867 <memset>
	page_free(pp0);
f0102518:	89 34 24             	mov    %esi,(%esp)
f010251b:	e8 c6 e9 ff ff       	call   f0100ee6 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102520:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102527:	00 
f0102528:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010252f:	00 
f0102530:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102535:	89 04 24             	mov    %eax,(%esp)
f0102538:	e8 e1 e9 ff ff       	call   f0100f1e <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010253d:	89 f2                	mov    %esi,%edx
f010253f:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102545:	c1 fa 03             	sar    $0x3,%edx
f0102548:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010254b:	89 d0                	mov    %edx,%eax
f010254d:	c1 e8 0c             	shr    $0xc,%eax
f0102550:	3b 05 64 79 11 f0    	cmp    0xf0117964,%eax
f0102556:	72 20                	jb     f0102578 <mem_init+0x13d9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102558:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010255c:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f0102563:	f0 
f0102564:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010256b:	00 
f010256c:	c7 04 24 9c 49 10 f0 	movl   $0xf010499c,(%esp)
f0102573:	e8 1c db ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102578:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010257e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102581:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102587:	f6 00 01             	testb  $0x1,(%eax)
f010258a:	74 24                	je     f01025b0 <mem_init+0x1411>
f010258c:	c7 44 24 0c 45 4c 10 	movl   $0xf0104c45,0xc(%esp)
f0102593:	f0 
f0102594:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f010259b:	f0 
f010259c:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f01025a3:	00 
f01025a4:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01025ab:	e8 e4 da ff ff       	call   f0100094 <_panic>
f01025b0:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01025b3:	39 d0                	cmp    %edx,%eax
f01025b5:	75 d0                	jne    f0102587 <mem_init+0x13e8>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01025b7:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01025bc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01025c2:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f01025c8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01025cb:	a3 3c 75 11 f0       	mov    %eax,0xf011753c

	// free the pages we took
	page_free(pp0);
f01025d0:	89 34 24             	mov    %esi,(%esp)
f01025d3:	e8 0e e9 ff ff       	call   f0100ee6 <page_free>
	page_free(pp1);
f01025d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01025db:	89 04 24             	mov    %eax,(%esp)
f01025de:	e8 03 e9 ff ff       	call   f0100ee6 <page_free>
	page_free(pp2);
f01025e3:	89 1c 24             	mov    %ebx,(%esp)
f01025e6:	e8 fb e8 ff ff       	call   f0100ee6 <page_free>

	cprintf("check_page() succeeded!\n");
f01025eb:	c7 04 24 5c 4c 10 f0 	movl   $0xf0104c5c,(%esp)
f01025f2:	e8 10 07 00 00       	call   f0102d07 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, 
f01025f7:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025fc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102601:	77 20                	ja     f0102623 <mem_init+0x1484>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102603:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102607:	c7 44 24 08 c4 43 10 	movl   $0xf01043c4,0x8(%esp)
f010260e:	f0 
f010260f:	c7 44 24 04 bb 00 00 	movl   $0xbb,0x4(%esp)
f0102616:	00 
f0102617:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010261e:	e8 71 da ff ff       	call   f0100094 <_panic>
f0102623:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f010262a:	00 
	return (physaddr_t)kva - KERNBASE;
f010262b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102630:	89 04 24             	mov    %eax,(%esp)
f0102633:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102638:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010263d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102642:	e8 77 e9 ff ff       	call   f0100fbe <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102647:	bb 00 d0 10 f0       	mov    $0xf010d000,%ebx
f010264c:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102652:	77 20                	ja     f0102674 <mem_init+0x14d5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102654:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102658:	c7 44 24 08 c4 43 10 	movl   $0xf01043c4,0x8(%esp)
f010265f:	f0 
f0102660:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
f0102667:	00 
f0102668:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010266f:	e8 20 da ff ff       	call   f0100094 <_panic>
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, 
f0102674:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010267b:	00 
f010267c:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f0102683:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102688:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010268d:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102692:	e8 27 e9 ff ff       	call   f0100fbe <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_region(kern_pgdir, 
f0102697:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010269e:	00 
f010269f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01026a6:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01026ab:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01026b0:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f01026b5:	e8 04 e9 ff ff       	call   f0100fbe <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01026ba:	8b 3d 68 79 11 f0    	mov    0xf0117968,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01026c0:	a1 64 79 11 f0       	mov    0xf0117964,%eax
f01026c5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01026c8:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01026cf:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01026d4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026d7:	a1 6c 79 11 f0       	mov    0xf011796c,%eax
f01026dc:	89 45 cc             	mov    %eax,-0x34(%ebp)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026df:	89 45 c8             	mov    %eax,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f01026e2:	05 00 00 00 10       	add    $0x10000000,%eax
f01026e7:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01026ea:	be 00 00 00 00       	mov    $0x0,%esi
f01026ef:	eb 6d                	jmp    f010275e <mem_init+0x15bf>
f01026f1:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026f7:	89 f8                	mov    %edi,%eax
f01026f9:	e8 03 e3 ff ff       	call   f0100a01 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026fe:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102705:	77 23                	ja     f010272a <mem_init+0x158b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102707:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010270a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010270e:	c7 44 24 08 c4 43 10 	movl   $0xf01043c4,0x8(%esp)
f0102715:	f0 
f0102716:	c7 44 24 04 a8 02 00 	movl   $0x2a8,0x4(%esp)
f010271d:	00 
f010271e:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102725:	e8 6a d9 ff ff       	call   f0100094 <_panic>
f010272a:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f010272d:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102730:	39 c2                	cmp    %eax,%edx
f0102732:	74 24                	je     f0102758 <mem_init+0x15b9>
f0102734:	c7 44 24 0c 08 48 10 	movl   $0xf0104808,0xc(%esp)
f010273b:	f0 
f010273c:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102743:	f0 
f0102744:	c7 44 24 04 a8 02 00 	movl   $0x2a8,0x4(%esp)
f010274b:	00 
f010274c:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102753:	e8 3c d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102758:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010275e:	39 75 d0             	cmp    %esi,-0x30(%ebp)
f0102761:	77 8e                	ja     f01026f1 <mem_init+0x1552>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102763:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102766:	c1 e0 0c             	shl    $0xc,%eax
f0102769:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010276c:	be 00 00 00 00       	mov    $0x0,%esi
f0102771:	eb 3b                	jmp    f01027ae <mem_init+0x160f>
f0102773:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102779:	89 f8                	mov    %edi,%eax
f010277b:	e8 81 e2 ff ff       	call   f0100a01 <check_va2pa>
f0102780:	39 c6                	cmp    %eax,%esi
f0102782:	74 24                	je     f01027a8 <mem_init+0x1609>
f0102784:	c7 44 24 0c 3c 48 10 	movl   $0xf010483c,0xc(%esp)
f010278b:	f0 
f010278c:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102793:	f0 
f0102794:	c7 44 24 04 ac 02 00 	movl   $0x2ac,0x4(%esp)
f010279b:	00 
f010279c:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01027a3:	e8 ec d8 ff ff       	call   f0100094 <_panic>
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027a8:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01027ae:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01027b1:	72 c0                	jb     f0102773 <mem_init+0x15d4>
f01027b3:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01027b8:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01027be:	89 f2                	mov    %esi,%edx
f01027c0:	89 f8                	mov    %edi,%eax
f01027c2:	e8 3a e2 ff ff       	call   f0100a01 <check_va2pa>
f01027c7:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f01027ca:	39 d0                	cmp    %edx,%eax
f01027cc:	74 24                	je     f01027f2 <mem_init+0x1653>
f01027ce:	c7 44 24 0c 64 48 10 	movl   $0xf0104864,0xc(%esp)
f01027d5:	f0 
f01027d6:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01027dd:	f0 
f01027de:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f01027e5:	00 
f01027e6:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01027ed:	e8 a2 d8 ff ff       	call   f0100094 <_panic>
f01027f2:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01027f8:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01027fe:	75 be                	jne    f01027be <mem_init+0x161f>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102800:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102805:	89 f8                	mov    %edi,%eax
f0102807:	e8 f5 e1 ff ff       	call   f0100a01 <check_va2pa>
f010280c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010280f:	75 0a                	jne    f010281b <mem_init+0x167c>
f0102811:	b8 00 00 00 00       	mov    $0x0,%eax
f0102816:	e9 f0 00 00 00       	jmp    f010290b <mem_init+0x176c>
f010281b:	c7 44 24 0c ac 48 10 	movl   $0xf01048ac,0xc(%esp)
f0102822:	f0 
f0102823:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f010282a:	f0 
f010282b:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
f0102832:	00 
f0102833:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010283a:	e8 55 d8 ff ff       	call   f0100094 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010283f:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f0102844:	72 3c                	jb     f0102882 <mem_init+0x16e3>
f0102846:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f010284b:	76 07                	jbe    f0102854 <mem_init+0x16b5>
f010284d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102852:	75 2e                	jne    f0102882 <mem_init+0x16e3>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102854:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102858:	0f 85 aa 00 00 00    	jne    f0102908 <mem_init+0x1769>
f010285e:	c7 44 24 0c 75 4c 10 	movl   $0xf0104c75,0xc(%esp)
f0102865:	f0 
f0102866:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f010286d:	f0 
f010286e:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f0102875:	00 
f0102876:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010287d:	e8 12 d8 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102882:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102887:	76 55                	jbe    f01028de <mem_init+0x173f>
				assert(pgdir[i] & PTE_P);
f0102889:	8b 14 87             	mov    (%edi,%eax,4),%edx
f010288c:	f6 c2 01             	test   $0x1,%dl
f010288f:	75 24                	jne    f01028b5 <mem_init+0x1716>
f0102891:	c7 44 24 0c 75 4c 10 	movl   $0xf0104c75,0xc(%esp)
f0102898:	f0 
f0102899:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01028a0:	f0 
f01028a1:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
f01028a8:	00 
f01028a9:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01028b0:	e8 df d7 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f01028b5:	f6 c2 02             	test   $0x2,%dl
f01028b8:	75 4e                	jne    f0102908 <mem_init+0x1769>
f01028ba:	c7 44 24 0c 86 4c 10 	movl   $0xf0104c86,0xc(%esp)
f01028c1:	f0 
f01028c2:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01028c9:	f0 
f01028ca:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f01028d1:	00 
f01028d2:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01028d9:	e8 b6 d7 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f01028de:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01028e2:	74 24                	je     f0102908 <mem_init+0x1769>
f01028e4:	c7 44 24 0c 97 4c 10 	movl   $0xf0104c97,0xc(%esp)
f01028eb:	f0 
f01028ec:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01028f3:	f0 
f01028f4:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f01028fb:	00 
f01028fc:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102903:	e8 8c d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102908:	83 c0 01             	add    $0x1,%eax
f010290b:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102910:	0f 85 29 ff ff ff    	jne    f010283f <mem_init+0x16a0>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102916:	c7 04 24 dc 48 10 f0 	movl   $0xf01048dc,(%esp)
f010291d:	e8 e5 03 00 00       	call   f0102d07 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102922:	a1 68 79 11 f0       	mov    0xf0117968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102927:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010292c:	77 20                	ja     f010294e <mem_init+0x17af>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010292e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102932:	c7 44 24 08 c4 43 10 	movl   $0xf01043c4,0x8(%esp)
f0102939:	f0 
f010293a:	c7 44 24 04 eb 00 00 	movl   $0xeb,0x4(%esp)
f0102941:	00 
f0102942:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102949:	e8 46 d7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010294e:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102953:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102956:	b8 00 00 00 00       	mov    $0x0,%eax
f010295b:	e8 10 e1 ff ff       	call   f0100a70 <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102960:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102963:	83 e0 f3             	and    $0xfffffff3,%eax
f0102966:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f010296b:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010296e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102975:	e8 e7 e4 ff ff       	call   f0100e61 <page_alloc>
f010297a:	89 c3                	mov    %eax,%ebx
f010297c:	85 c0                	test   %eax,%eax
f010297e:	75 24                	jne    f01029a4 <mem_init+0x1805>
f0102980:	c7 44 24 0c 88 4a 10 	movl   $0xf0104a88,0xc(%esp)
f0102987:	f0 
f0102988:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f010298f:	f0 
f0102990:	c7 44 24 04 7e 03 00 	movl   $0x37e,0x4(%esp)
f0102997:	00 
f0102998:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f010299f:	e8 f0 d6 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01029a4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01029ab:	e8 b1 e4 ff ff       	call   f0100e61 <page_alloc>
f01029b0:	89 c7                	mov    %eax,%edi
f01029b2:	85 c0                	test   %eax,%eax
f01029b4:	75 24                	jne    f01029da <mem_init+0x183b>
f01029b6:	c7 44 24 0c 9e 4a 10 	movl   $0xf0104a9e,0xc(%esp)
f01029bd:	f0 
f01029be:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01029c5:	f0 
f01029c6:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f01029cd:	00 
f01029ce:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f01029d5:	e8 ba d6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01029da:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01029e1:	e8 7b e4 ff ff       	call   f0100e61 <page_alloc>
f01029e6:	89 c6                	mov    %eax,%esi
f01029e8:	85 c0                	test   %eax,%eax
f01029ea:	75 24                	jne    f0102a10 <mem_init+0x1871>
f01029ec:	c7 44 24 0c b4 4a 10 	movl   $0xf0104ab4,0xc(%esp)
f01029f3:	f0 
f01029f4:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f01029fb:	f0 
f01029fc:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0102a03:	00 
f0102a04:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102a0b:	e8 84 d6 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102a10:	89 1c 24             	mov    %ebx,(%esp)
f0102a13:	e8 ce e4 ff ff       	call   f0100ee6 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102a18:	89 f8                	mov    %edi,%eax
f0102a1a:	e8 9d df ff ff       	call   f01009bc <page2kva>
f0102a1f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a26:	00 
f0102a27:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102a2e:	00 
f0102a2f:	89 04 24             	mov    %eax,(%esp)
f0102a32:	e8 30 0e 00 00       	call   f0103867 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a37:	89 f0                	mov    %esi,%eax
f0102a39:	e8 7e df ff ff       	call   f01009bc <page2kva>
f0102a3e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a45:	00 
f0102a46:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102a4d:	00 
f0102a4e:	89 04 24             	mov    %eax,(%esp)
f0102a51:	e8 11 0e 00 00       	call   f0103867 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a56:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a5d:	00 
f0102a5e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a65:	00 
f0102a66:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102a6a:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102a6f:	89 04 24             	mov    %eax,(%esp)
f0102a72:	e8 b9 e6 ff ff       	call   f0101130 <page_insert>
	assert(pp1->pp_ref == 1);
f0102a77:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a7c:	74 24                	je     f0102aa2 <mem_init+0x1903>
f0102a7e:	c7 44 24 0c 85 4b 10 	movl   $0xf0104b85,0xc(%esp)
f0102a85:	f0 
f0102a86:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102a8d:	f0 
f0102a8e:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f0102a95:	00 
f0102a96:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102a9d:	e8 f2 d5 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102aa2:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102aa9:	01 01 01 
f0102aac:	74 24                	je     f0102ad2 <mem_init+0x1933>
f0102aae:	c7 44 24 0c fc 48 10 	movl   $0xf01048fc,0xc(%esp)
f0102ab5:	f0 
f0102ab6:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102abd:	f0 
f0102abe:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f0102ac5:	00 
f0102ac6:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102acd:	e8 c2 d5 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102ad2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102ad9:	00 
f0102ada:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ae1:	00 
f0102ae2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102ae6:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102aeb:	89 04 24             	mov    %eax,(%esp)
f0102aee:	e8 3d e6 ff ff       	call   f0101130 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102af3:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102afa:	02 02 02 
f0102afd:	74 24                	je     f0102b23 <mem_init+0x1984>
f0102aff:	c7 44 24 0c 20 49 10 	movl   $0xf0104920,0xc(%esp)
f0102b06:	f0 
f0102b07:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102b0e:	f0 
f0102b0f:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0102b16:	00 
f0102b17:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102b1e:	e8 71 d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102b23:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b28:	74 24                	je     f0102b4e <mem_init+0x19af>
f0102b2a:	c7 44 24 0c a7 4b 10 	movl   $0xf0104ba7,0xc(%esp)
f0102b31:	f0 
f0102b32:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102b39:	f0 
f0102b3a:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0102b41:	00 
f0102b42:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102b49:	e8 46 d5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102b4e:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b53:	74 24                	je     f0102b79 <mem_init+0x19da>
f0102b55:	c7 44 24 0c 1c 4c 10 	movl   $0xf0104c1c,0xc(%esp)
f0102b5c:	f0 
f0102b5d:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102b64:	f0 
f0102b65:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f0102b6c:	00 
f0102b6d:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102b74:	e8 1b d5 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b79:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b80:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102b83:	89 f0                	mov    %esi,%eax
f0102b85:	e8 32 de ff ff       	call   f01009bc <page2kva>
f0102b8a:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102b90:	74 24                	je     f0102bb6 <mem_init+0x1a17>
f0102b92:	c7 44 24 0c 44 49 10 	movl   $0xf0104944,0xc(%esp)
f0102b99:	f0 
f0102b9a:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102ba1:	f0 
f0102ba2:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0102ba9:	00 
f0102baa:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102bb1:	e8 de d4 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102bb6:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102bbd:	00 
f0102bbe:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102bc3:	89 04 24             	mov    %eax,(%esp)
f0102bc6:	e8 1f e5 ff ff       	call   f01010ea <page_remove>
	assert(pp2->pp_ref == 0);
f0102bcb:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102bd0:	74 24                	je     f0102bf6 <mem_init+0x1a57>
f0102bd2:	c7 44 24 0c 0b 4c 10 	movl   $0xf0104c0b,0xc(%esp)
f0102bd9:	f0 
f0102bda:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102be1:	f0 
f0102be2:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0102be9:	00 
f0102bea:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102bf1:	e8 9e d4 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102bf6:	a1 68 79 11 f0       	mov    0xf0117968,%eax
f0102bfb:	8b 08                	mov    (%eax),%ecx
f0102bfd:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c03:	89 da                	mov    %ebx,%edx
f0102c05:	2b 15 6c 79 11 f0    	sub    0xf011796c,%edx
f0102c0b:	c1 fa 03             	sar    $0x3,%edx
f0102c0e:	c1 e2 0c             	shl    $0xc,%edx
f0102c11:	39 d1                	cmp    %edx,%ecx
f0102c13:	74 24                	je     f0102c39 <mem_init+0x1a9a>
f0102c15:	c7 44 24 0c c0 44 10 	movl   $0xf01044c0,0xc(%esp)
f0102c1c:	f0 
f0102c1d:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102c24:	f0 
f0102c25:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f0102c2c:	00 
f0102c2d:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102c34:	e8 5b d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102c39:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102c3f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c44:	74 24                	je     f0102c6a <mem_init+0x1acb>
f0102c46:	c7 44 24 0c 96 4b 10 	movl   $0xf0104b96,0xc(%esp)
f0102c4d:	f0 
f0102c4e:	c7 44 24 08 c2 49 10 	movl   $0xf01049c2,0x8(%esp)
f0102c55:	f0 
f0102c56:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102c5d:	00 
f0102c5e:	c7 04 24 aa 49 10 f0 	movl   $0xf01049aa,(%esp)
f0102c65:	e8 2a d4 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102c6a:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102c70:	89 1c 24             	mov    %ebx,(%esp)
f0102c73:	e8 6e e2 ff ff       	call   f0100ee6 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102c78:	c7 04 24 70 49 10 f0 	movl   $0xf0104970,(%esp)
f0102c7f:	e8 83 00 00 00       	call   f0102d07 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102c84:	83 c4 4c             	add    $0x4c,%esp
f0102c87:	5b                   	pop    %ebx
f0102c88:	5e                   	pop    %esi
f0102c89:	5f                   	pop    %edi
f0102c8a:	5d                   	pop    %ebp
f0102c8b:	c3                   	ret    

f0102c8c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102c8c:	55                   	push   %ebp
f0102c8d:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102c8f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c92:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102c95:	5d                   	pop    %ebp
f0102c96:	c3                   	ret    

f0102c97 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102c97:	55                   	push   %ebp
f0102c98:	89 e5                	mov    %esp,%ebp
f0102c9a:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102c9e:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ca3:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102ca4:	b2 71                	mov    $0x71,%dl
f0102ca6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102ca7:	0f b6 c0             	movzbl %al,%eax
}
f0102caa:	5d                   	pop    %ebp
f0102cab:	c3                   	ret    

f0102cac <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102cac:	55                   	push   %ebp
f0102cad:	89 e5                	mov    %esp,%ebp
f0102caf:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102cb3:	ba 70 00 00 00       	mov    $0x70,%edx
f0102cb8:	ee                   	out    %al,(%dx)
f0102cb9:	b2 71                	mov    $0x71,%dl
f0102cbb:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cbe:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102cbf:	5d                   	pop    %ebp
f0102cc0:	c3                   	ret    

f0102cc1 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102cc1:	55                   	push   %ebp
f0102cc2:	89 e5                	mov    %esp,%ebp
f0102cc4:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102cc7:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cca:	89 04 24             	mov    %eax,(%esp)
f0102ccd:	e8 2f d9 ff ff       	call   f0100601 <cputchar>
	*cnt++;
}
f0102cd2:	c9                   	leave  
f0102cd3:	c3                   	ret    

f0102cd4 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102cd4:	55                   	push   %ebp
f0102cd5:	89 e5                	mov    %esp,%ebp
f0102cd7:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102cda:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102ce1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ce4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ce8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ceb:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102cef:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102cf2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102cf6:	c7 04 24 c1 2c 10 f0 	movl   $0xf0102cc1,(%esp)
f0102cfd:	e8 ac 04 00 00       	call   f01031ae <vprintfmt>

	return cnt;
}
f0102d02:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d05:	c9                   	leave  
f0102d06:	c3                   	ret    

f0102d07 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102d07:	55                   	push   %ebp
f0102d08:	89 e5                	mov    %esp,%ebp
f0102d0a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;
	
	va_start(ap, fmt);
f0102d0d:	8d 45 0c             	lea    0xc(%ebp),%eax

	cnt = vcprintf(fmt, ap);
f0102d10:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d14:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d17:	89 04 24             	mov    %eax,(%esp)
f0102d1a:	e8 b5 ff ff ff       	call   f0102cd4 <vcprintf>

	va_end(ap);

	return cnt;
}
f0102d1f:	c9                   	leave  
f0102d20:	c3                   	ret    

f0102d21 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102d21:	55                   	push   %ebp
f0102d22:	89 e5                	mov    %esp,%ebp
f0102d24:	57                   	push   %edi
f0102d25:	56                   	push   %esi
f0102d26:	53                   	push   %ebx
f0102d27:	83 ec 10             	sub    $0x10,%esp
f0102d2a:	89 c6                	mov    %eax,%esi
f0102d2c:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102d2f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102d32:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102d35:	8b 1a                	mov    (%edx),%ebx
f0102d37:	8b 01                	mov    (%ecx),%eax
f0102d39:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102d3c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102d43:	eb 77                	jmp    f0102dbc <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102d45:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102d48:	01 d8                	add    %ebx,%eax
f0102d4a:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102d4f:	99                   	cltd   
f0102d50:	f7 f9                	idiv   %ecx
f0102d52:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d54:	eb 01                	jmp    f0102d57 <stab_binsearch+0x36>
			m--;
f0102d56:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d57:	39 d9                	cmp    %ebx,%ecx
f0102d59:	7c 1d                	jl     f0102d78 <stab_binsearch+0x57>
f0102d5b:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102d5e:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102d63:	39 fa                	cmp    %edi,%edx
f0102d65:	75 ef                	jne    f0102d56 <stab_binsearch+0x35>
f0102d67:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102d6a:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102d6d:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102d71:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102d74:	73 18                	jae    f0102d8e <stab_binsearch+0x6d>
f0102d76:	eb 05                	jmp    f0102d7d <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102d78:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102d7b:	eb 3f                	jmp    f0102dbc <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102d7d:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102d80:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0102d82:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102d85:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102d8c:	eb 2e                	jmp    f0102dbc <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102d8e:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102d91:	73 15                	jae    f0102da8 <stab_binsearch+0x87>
			*region_right = m - 1;
f0102d93:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102d96:	48                   	dec    %eax
f0102d97:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102d9a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102d9d:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102d9f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102da6:	eb 14                	jmp    f0102dbc <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102da8:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102dab:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0102dae:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0102db0:	ff 45 0c             	incl   0xc(%ebp)
f0102db3:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102db5:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102dbc:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102dbf:	7e 84                	jle    f0102d45 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102dc1:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102dc5:	75 0d                	jne    f0102dd4 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102dc7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102dca:	8b 00                	mov    (%eax),%eax
f0102dcc:	48                   	dec    %eax
f0102dcd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0102dd0:	89 07                	mov    %eax,(%edi)
f0102dd2:	eb 22                	jmp    f0102df6 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102dd4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102dd7:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102dd9:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0102ddc:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102dde:	eb 01                	jmp    f0102de1 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102de0:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102de1:	39 c1                	cmp    %eax,%ecx
f0102de3:	7d 0c                	jge    f0102df1 <stab_binsearch+0xd0>
f0102de5:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0102de8:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102ded:	39 fa                	cmp    %edi,%edx
f0102def:	75 ef                	jne    f0102de0 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102df1:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0102df4:	89 07                	mov    %eax,(%edi)
	}
}
f0102df6:	83 c4 10             	add    $0x10,%esp
f0102df9:	5b                   	pop    %ebx
f0102dfa:	5e                   	pop    %esi
f0102dfb:	5f                   	pop    %edi
f0102dfc:	5d                   	pop    %ebp
f0102dfd:	c3                   	ret    

f0102dfe <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102dfe:	55                   	push   %ebp
f0102dff:	89 e5                	mov    %esp,%ebp
f0102e01:	57                   	push   %edi
f0102e02:	56                   	push   %esi
f0102e03:	53                   	push   %ebx
f0102e04:	83 ec 3c             	sub    $0x3c,%esp
f0102e07:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e0a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102e0d:	c7 03 a5 4c 10 f0    	movl   $0xf0104ca5,(%ebx)
	info->eip_line = 0;
f0102e13:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102e1a:	c7 43 08 a5 4c 10 f0 	movl   $0xf0104ca5,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102e21:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102e28:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102e2b:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102e32:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e38:	76 12                	jbe    f0102e4c <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e3a:	b8 1d c9 10 f0       	mov    $0xf010c91d,%eax
f0102e3f:	3d 79 ab 10 f0       	cmp    $0xf010ab79,%eax
f0102e44:	0f 86 cd 01 00 00    	jbe    f0103017 <debuginfo_eip+0x219>
f0102e4a:	eb 1c                	jmp    f0102e68 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102e4c:	c7 44 24 08 af 4c 10 	movl   $0xf0104caf,0x8(%esp)
f0102e53:	f0 
f0102e54:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102e5b:	00 
f0102e5c:	c7 04 24 bc 4c 10 f0 	movl   $0xf0104cbc,(%esp)
f0102e63:	e8 2c d2 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e68:	80 3d 1c c9 10 f0 00 	cmpb   $0x0,0xf010c91c
f0102e6f:	0f 85 a9 01 00 00    	jne    f010301e <debuginfo_eip+0x220>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102e75:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102e7c:	b8 78 ab 10 f0       	mov    $0xf010ab78,%eax
f0102e81:	2d d8 4e 10 f0       	sub    $0xf0104ed8,%eax
f0102e86:	c1 f8 02             	sar    $0x2,%eax
f0102e89:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102e8f:	83 e8 01             	sub    $0x1,%eax
f0102e92:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102e95:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102e99:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102ea0:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102ea3:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102ea6:	b8 d8 4e 10 f0       	mov    $0xf0104ed8,%eax
f0102eab:	e8 71 fe ff ff       	call   f0102d21 <stab_binsearch>
	if (lfile == 0)
f0102eb0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102eb3:	85 c0                	test   %eax,%eax
f0102eb5:	0f 84 6a 01 00 00    	je     f0103025 <debuginfo_eip+0x227>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102ebb:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0102ebe:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ec1:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102ec4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102ec8:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102ecf:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102ed2:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102ed5:	b8 d8 4e 10 f0       	mov    $0xf0104ed8,%eax
f0102eda:	e8 42 fe ff ff       	call   f0102d21 <stab_binsearch>

	if (lfun <= rfun) {
f0102edf:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102ee2:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102ee5:	39 d0                	cmp    %edx,%eax
f0102ee7:	7f 3d                	jg     f0102f26 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102ee9:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0102eec:	8d b9 d8 4e 10 f0    	lea    -0xfefb128(%ecx),%edi
f0102ef2:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0102ef5:	8b 89 d8 4e 10 f0    	mov    -0xfefb128(%ecx),%ecx
f0102efb:	bf 1d c9 10 f0       	mov    $0xf010c91d,%edi
f0102f00:	81 ef 79 ab 10 f0    	sub    $0xf010ab79,%edi
f0102f06:	39 f9                	cmp    %edi,%ecx
f0102f08:	73 09                	jae    f0102f13 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102f0a:	81 c1 79 ab 10 f0    	add    $0xf010ab79,%ecx
f0102f10:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102f13:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102f16:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102f19:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0102f1c:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0102f1e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0102f21:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102f24:	eb 0f                	jmp    f0102f35 <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102f26:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102f29:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f2c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0102f2f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f32:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102f35:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102f3c:	00 
f0102f3d:	8b 43 08             	mov    0x8(%ebx),%eax
f0102f40:	89 04 24             	mov    %eax,(%esp)
f0102f43:	e8 03 09 00 00       	call   f010384b <strfind>
f0102f48:	2b 43 08             	sub    0x8(%ebx),%eax
f0102f4b:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0102f4e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f52:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0102f59:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0102f5c:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0102f5f:	b8 d8 4e 10 f0       	mov    $0xf0104ed8,%eax
f0102f64:	e8 b8 fd ff ff       	call   f0102d21 <stab_binsearch>
	if(lline <= rline){
f0102f69:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f6c:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0102f6f:	0f 8f b7 00 00 00    	jg     f010302c <debuginfo_eip+0x22e>
		info->eip_line = stabs[lline].n_desc;
f0102f75:	6b c0 0c             	imul   $0xc,%eax,%eax
f0102f78:	0f b7 80 de 4e 10 f0 	movzwl -0xfefb122(%eax),%eax
f0102f7f:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102f85:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102f88:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f8b:	6b d0 0c             	imul   $0xc,%eax,%edx
f0102f8e:	81 c2 d8 4e 10 f0    	add    $0xf0104ed8,%edx
f0102f94:	eb 06                	jmp    f0102f9c <debuginfo_eip+0x19e>
f0102f96:	83 e8 01             	sub    $0x1,%eax
f0102f99:	83 ea 0c             	sub    $0xc,%edx
f0102f9c:	89 c6                	mov    %eax,%esi
f0102f9e:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0102fa1:	7f 33                	jg     f0102fd6 <debuginfo_eip+0x1d8>
	       && stabs[lline].n_type != N_SOL
f0102fa3:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0102fa7:	80 f9 84             	cmp    $0x84,%cl
f0102faa:	74 0b                	je     f0102fb7 <debuginfo_eip+0x1b9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102fac:	80 f9 64             	cmp    $0x64,%cl
f0102faf:	75 e5                	jne    f0102f96 <debuginfo_eip+0x198>
f0102fb1:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0102fb5:	74 df                	je     f0102f96 <debuginfo_eip+0x198>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102fb7:	6b f6 0c             	imul   $0xc,%esi,%esi
f0102fba:	8b 86 d8 4e 10 f0    	mov    -0xfefb128(%esi),%eax
f0102fc0:	ba 1d c9 10 f0       	mov    $0xf010c91d,%edx
f0102fc5:	81 ea 79 ab 10 f0    	sub    $0xf010ab79,%edx
f0102fcb:	39 d0                	cmp    %edx,%eax
f0102fcd:	73 07                	jae    f0102fd6 <debuginfo_eip+0x1d8>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102fcf:	05 79 ab 10 f0       	add    $0xf010ab79,%eax
f0102fd4:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102fd6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102fd9:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102fdc:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102fe1:	39 ca                	cmp    %ecx,%edx
f0102fe3:	7d 53                	jge    f0103038 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
f0102fe5:	8d 42 01             	lea    0x1(%edx),%eax
f0102fe8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102feb:	89 c2                	mov    %eax,%edx
f0102fed:	6b c0 0c             	imul   $0xc,%eax,%eax
f0102ff0:	05 d8 4e 10 f0       	add    $0xf0104ed8,%eax
f0102ff5:	89 ce                	mov    %ecx,%esi
f0102ff7:	eb 04                	jmp    f0102ffd <debuginfo_eip+0x1ff>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102ff9:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102ffd:	39 d6                	cmp    %edx,%esi
f0102fff:	7e 32                	jle    f0103033 <debuginfo_eip+0x235>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103001:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0103005:	83 c2 01             	add    $0x1,%edx
f0103008:	83 c0 0c             	add    $0xc,%eax
f010300b:	80 f9 a0             	cmp    $0xa0,%cl
f010300e:	74 e9                	je     f0102ff9 <debuginfo_eip+0x1fb>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103010:	b8 00 00 00 00       	mov    $0x0,%eax
f0103015:	eb 21                	jmp    f0103038 <debuginfo_eip+0x23a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103017:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010301c:	eb 1a                	jmp    f0103038 <debuginfo_eip+0x23a>
f010301e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103023:	eb 13                	jmp    f0103038 <debuginfo_eip+0x23a>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103025:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010302a:	eb 0c                	jmp    f0103038 <debuginfo_eip+0x23a>

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
	if(lline <= rline){
		info->eip_line = stabs[lline].n_desc;
	}else {
		return -1;
f010302c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103031:	eb 05                	jmp    f0103038 <debuginfo_eip+0x23a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103033:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103038:	83 c4 3c             	add    $0x3c,%esp
f010303b:	5b                   	pop    %ebx
f010303c:	5e                   	pop    %esi
f010303d:	5f                   	pop    %edi
f010303e:	5d                   	pop    %ebp
f010303f:	c3                   	ret    

f0103040 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103040:	55                   	push   %ebp
f0103041:	89 e5                	mov    %esp,%ebp
f0103043:	57                   	push   %edi
f0103044:	56                   	push   %esi
f0103045:	53                   	push   %ebx
f0103046:	83 ec 3c             	sub    $0x3c,%esp
f0103049:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010304c:	89 d7                	mov    %edx,%edi
f010304e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103051:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103054:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103057:	89 c3                	mov    %eax,%ebx
f0103059:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010305c:	8b 45 10             	mov    0x10(%ebp),%eax
f010305f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103062:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103067:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010306a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010306d:	39 d9                	cmp    %ebx,%ecx
f010306f:	72 05                	jb     f0103076 <printnum+0x36>
f0103071:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103074:	77 69                	ja     f01030df <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103076:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0103079:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010307d:	83 ee 01             	sub    $0x1,%esi
f0103080:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103084:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103088:	8b 44 24 08          	mov    0x8(%esp),%eax
f010308c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103090:	89 c3                	mov    %eax,%ebx
f0103092:	89 d6                	mov    %edx,%esi
f0103094:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103097:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010309a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010309e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01030a2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030a5:	89 04 24             	mov    %eax,(%esp)
f01030a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030ab:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030af:	e8 bc 09 00 00       	call   f0103a70 <__udivdi3>
f01030b4:	89 d9                	mov    %ebx,%ecx
f01030b6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01030ba:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01030be:	89 04 24             	mov    %eax,(%esp)
f01030c1:	89 54 24 04          	mov    %edx,0x4(%esp)
f01030c5:	89 fa                	mov    %edi,%edx
f01030c7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030ca:	e8 71 ff ff ff       	call   f0103040 <printnum>
f01030cf:	eb 1b                	jmp    f01030ec <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01030d1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030d5:	8b 45 18             	mov    0x18(%ebp),%eax
f01030d8:	89 04 24             	mov    %eax,(%esp)
f01030db:	ff d3                	call   *%ebx
f01030dd:	eb 03                	jmp    f01030e2 <printnum+0xa2>
f01030df:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01030e2:	83 ee 01             	sub    $0x1,%esi
f01030e5:	85 f6                	test   %esi,%esi
f01030e7:	7f e8                	jg     f01030d1 <printnum+0x91>
f01030e9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01030ec:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030f0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01030f4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01030f7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01030fa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01030fe:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103102:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103105:	89 04 24             	mov    %eax,(%esp)
f0103108:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010310b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010310f:	e8 8c 0a 00 00       	call   f0103ba0 <__umoddi3>
f0103114:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103118:	0f be 80 ca 4c 10 f0 	movsbl -0xfefb336(%eax),%eax
f010311f:	89 04 24             	mov    %eax,(%esp)
f0103122:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103125:	ff d0                	call   *%eax
}
f0103127:	83 c4 3c             	add    $0x3c,%esp
f010312a:	5b                   	pop    %ebx
f010312b:	5e                   	pop    %esi
f010312c:	5f                   	pop    %edi
f010312d:	5d                   	pop    %ebp
f010312e:	c3                   	ret    

f010312f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010312f:	55                   	push   %ebp
f0103130:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103132:	83 fa 01             	cmp    $0x1,%edx
f0103135:	7e 0e                	jle    f0103145 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103137:	8b 10                	mov    (%eax),%edx
f0103139:	8d 4a 08             	lea    0x8(%edx),%ecx
f010313c:	89 08                	mov    %ecx,(%eax)
f010313e:	8b 02                	mov    (%edx),%eax
f0103140:	8b 52 04             	mov    0x4(%edx),%edx
f0103143:	eb 22                	jmp    f0103167 <getuint+0x38>
	else if (lflag)
f0103145:	85 d2                	test   %edx,%edx
f0103147:	74 10                	je     f0103159 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103149:	8b 10                	mov    (%eax),%edx
f010314b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010314e:	89 08                	mov    %ecx,(%eax)
f0103150:	8b 02                	mov    (%edx),%eax
f0103152:	ba 00 00 00 00       	mov    $0x0,%edx
f0103157:	eb 0e                	jmp    f0103167 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103159:	8b 10                	mov    (%eax),%edx
f010315b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010315e:	89 08                	mov    %ecx,(%eax)
f0103160:	8b 02                	mov    (%edx),%eax
f0103162:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103167:	5d                   	pop    %ebp
f0103168:	c3                   	ret    

f0103169 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103169:	55                   	push   %ebp
f010316a:	89 e5                	mov    %esp,%ebp
f010316c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010316f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103173:	8b 10                	mov    (%eax),%edx
f0103175:	3b 50 04             	cmp    0x4(%eax),%edx
f0103178:	73 0a                	jae    f0103184 <sprintputch+0x1b>
		*b->buf++ = ch;
f010317a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010317d:	89 08                	mov    %ecx,(%eax)
f010317f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103182:	88 02                	mov    %al,(%edx)
}
f0103184:	5d                   	pop    %ebp
f0103185:	c3                   	ret    

f0103186 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103186:	55                   	push   %ebp
f0103187:	89 e5                	mov    %esp,%ebp
f0103189:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010318c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010318f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103193:	8b 45 10             	mov    0x10(%ebp),%eax
f0103196:	89 44 24 08          	mov    %eax,0x8(%esp)
f010319a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010319d:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01031a4:	89 04 24             	mov    %eax,(%esp)
f01031a7:	e8 02 00 00 00       	call   f01031ae <vprintfmt>
	va_end(ap);
}
f01031ac:	c9                   	leave  
f01031ad:	c3                   	ret    

f01031ae <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01031ae:	55                   	push   %ebp
f01031af:	89 e5                	mov    %esp,%ebp
f01031b1:	57                   	push   %edi
f01031b2:	56                   	push   %esi
f01031b3:	53                   	push   %ebx
f01031b4:	83 ec 3c             	sub    $0x3c,%esp
f01031b7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01031ba:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01031bd:	eb 14                	jmp    f01031d3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01031bf:	85 c0                	test   %eax,%eax
f01031c1:	0f 84 b3 03 00 00    	je     f010357a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f01031c7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031cb:	89 04 24             	mov    %eax,(%esp)
f01031ce:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01031d1:	89 f3                	mov    %esi,%ebx
f01031d3:	8d 73 01             	lea    0x1(%ebx),%esi
f01031d6:	0f b6 03             	movzbl (%ebx),%eax
f01031d9:	83 f8 25             	cmp    $0x25,%eax
f01031dc:	75 e1                	jne    f01031bf <vprintfmt+0x11>
f01031de:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f01031e2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01031e9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f01031f0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01031f7:	ba 00 00 00 00       	mov    $0x0,%edx
f01031fc:	eb 1d                	jmp    f010321b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031fe:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103200:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103204:	eb 15                	jmp    f010321b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103206:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103208:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010320c:	eb 0d                	jmp    f010321b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010320e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103211:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103214:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010321b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010321e:	0f b6 0e             	movzbl (%esi),%ecx
f0103221:	0f b6 c1             	movzbl %cl,%eax
f0103224:	83 e9 23             	sub    $0x23,%ecx
f0103227:	80 f9 55             	cmp    $0x55,%cl
f010322a:	0f 87 2a 03 00 00    	ja     f010355a <vprintfmt+0x3ac>
f0103230:	0f b6 c9             	movzbl %cl,%ecx
f0103233:	ff 24 8d 54 4d 10 f0 	jmp    *-0xfefb2ac(,%ecx,4)
f010323a:	89 de                	mov    %ebx,%esi
f010323c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103241:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0103244:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0103248:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010324b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010324e:	83 fb 09             	cmp    $0x9,%ebx
f0103251:	77 36                	ja     f0103289 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103253:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103256:	eb e9                	jmp    f0103241 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103258:	8b 45 14             	mov    0x14(%ebp),%eax
f010325b:	8d 48 04             	lea    0x4(%eax),%ecx
f010325e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0103261:	8b 00                	mov    (%eax),%eax
f0103263:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103266:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103268:	eb 22                	jmp    f010328c <vprintfmt+0xde>
f010326a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010326d:	85 c9                	test   %ecx,%ecx
f010326f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103274:	0f 49 c1             	cmovns %ecx,%eax
f0103277:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010327a:	89 de                	mov    %ebx,%esi
f010327c:	eb 9d                	jmp    f010321b <vprintfmt+0x6d>
f010327e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103280:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0103287:	eb 92                	jmp    f010321b <vprintfmt+0x6d>
f0103289:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f010328c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103290:	79 89                	jns    f010321b <vprintfmt+0x6d>
f0103292:	e9 77 ff ff ff       	jmp    f010320e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103297:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010329a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010329c:	e9 7a ff ff ff       	jmp    f010321b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01032a1:	8b 45 14             	mov    0x14(%ebp),%eax
f01032a4:	8d 50 04             	lea    0x4(%eax),%edx
f01032a7:	89 55 14             	mov    %edx,0x14(%ebp)
f01032aa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032ae:	8b 00                	mov    (%eax),%eax
f01032b0:	89 04 24             	mov    %eax,(%esp)
f01032b3:	ff 55 08             	call   *0x8(%ebp)
			break;
f01032b6:	e9 18 ff ff ff       	jmp    f01031d3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01032bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01032be:	8d 50 04             	lea    0x4(%eax),%edx
f01032c1:	89 55 14             	mov    %edx,0x14(%ebp)
f01032c4:	8b 00                	mov    (%eax),%eax
f01032c6:	99                   	cltd   
f01032c7:	31 d0                	xor    %edx,%eax
f01032c9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01032cb:	83 f8 06             	cmp    $0x6,%eax
f01032ce:	7f 0b                	jg     f01032db <vprintfmt+0x12d>
f01032d0:	8b 14 85 ac 4e 10 f0 	mov    -0xfefb154(,%eax,4),%edx
f01032d7:	85 d2                	test   %edx,%edx
f01032d9:	75 20                	jne    f01032fb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f01032db:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032df:	c7 44 24 08 e2 4c 10 	movl   $0xf0104ce2,0x8(%esp)
f01032e6:	f0 
f01032e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01032ee:	89 04 24             	mov    %eax,(%esp)
f01032f1:	e8 90 fe ff ff       	call   f0103186 <printfmt>
f01032f6:	e9 d8 fe ff ff       	jmp    f01031d3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f01032fb:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01032ff:	c7 44 24 08 d4 49 10 	movl   $0xf01049d4,0x8(%esp)
f0103306:	f0 
f0103307:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010330b:	8b 45 08             	mov    0x8(%ebp),%eax
f010330e:	89 04 24             	mov    %eax,(%esp)
f0103311:	e8 70 fe ff ff       	call   f0103186 <printfmt>
f0103316:	e9 b8 fe ff ff       	jmp    f01031d3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010331b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010331e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103321:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103324:	8b 45 14             	mov    0x14(%ebp),%eax
f0103327:	8d 50 04             	lea    0x4(%eax),%edx
f010332a:	89 55 14             	mov    %edx,0x14(%ebp)
f010332d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010332f:	85 f6                	test   %esi,%esi
f0103331:	b8 db 4c 10 f0       	mov    $0xf0104cdb,%eax
f0103336:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0103339:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010333d:	0f 84 97 00 00 00    	je     f01033da <vprintfmt+0x22c>
f0103343:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103347:	0f 8e 9b 00 00 00    	jle    f01033e8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010334d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103351:	89 34 24             	mov    %esi,(%esp)
f0103354:	e8 9f 03 00 00       	call   f01036f8 <strnlen>
f0103359:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010335c:	29 c2                	sub    %eax,%edx
f010335e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0103361:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103365:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103368:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010336b:	8b 75 08             	mov    0x8(%ebp),%esi
f010336e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0103371:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103373:	eb 0f                	jmp    f0103384 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0103375:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103379:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010337c:	89 04 24             	mov    %eax,(%esp)
f010337f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103381:	83 eb 01             	sub    $0x1,%ebx
f0103384:	85 db                	test   %ebx,%ebx
f0103386:	7f ed                	jg     f0103375 <vprintfmt+0x1c7>
f0103388:	8b 75 d8             	mov    -0x28(%ebp),%esi
f010338b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010338e:	85 d2                	test   %edx,%edx
f0103390:	b8 00 00 00 00       	mov    $0x0,%eax
f0103395:	0f 49 c2             	cmovns %edx,%eax
f0103398:	29 c2                	sub    %eax,%edx
f010339a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010339d:	89 d7                	mov    %edx,%edi
f010339f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01033a2:	eb 50                	jmp    f01033f4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01033a4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01033a8:	74 1e                	je     f01033c8 <vprintfmt+0x21a>
f01033aa:	0f be d2             	movsbl %dl,%edx
f01033ad:	83 ea 20             	sub    $0x20,%edx
f01033b0:	83 fa 5e             	cmp    $0x5e,%edx
f01033b3:	76 13                	jbe    f01033c8 <vprintfmt+0x21a>
					putch('?', putdat);
f01033b5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033bc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01033c3:	ff 55 08             	call   *0x8(%ebp)
f01033c6:	eb 0d                	jmp    f01033d5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f01033c8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01033cb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01033cf:	89 04 24             	mov    %eax,(%esp)
f01033d2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01033d5:	83 ef 01             	sub    $0x1,%edi
f01033d8:	eb 1a                	jmp    f01033f4 <vprintfmt+0x246>
f01033da:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01033dd:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01033e0:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01033e3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01033e6:	eb 0c                	jmp    f01033f4 <vprintfmt+0x246>
f01033e8:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01033eb:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01033ee:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01033f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01033f4:	83 c6 01             	add    $0x1,%esi
f01033f7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01033fb:	0f be c2             	movsbl %dl,%eax
f01033fe:	85 c0                	test   %eax,%eax
f0103400:	74 27                	je     f0103429 <vprintfmt+0x27b>
f0103402:	85 db                	test   %ebx,%ebx
f0103404:	78 9e                	js     f01033a4 <vprintfmt+0x1f6>
f0103406:	83 eb 01             	sub    $0x1,%ebx
f0103409:	79 99                	jns    f01033a4 <vprintfmt+0x1f6>
f010340b:	89 f8                	mov    %edi,%eax
f010340d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103410:	8b 75 08             	mov    0x8(%ebp),%esi
f0103413:	89 c3                	mov    %eax,%ebx
f0103415:	eb 1a                	jmp    f0103431 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103417:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010341b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103422:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103424:	83 eb 01             	sub    $0x1,%ebx
f0103427:	eb 08                	jmp    f0103431 <vprintfmt+0x283>
f0103429:	89 fb                	mov    %edi,%ebx
f010342b:	8b 75 08             	mov    0x8(%ebp),%esi
f010342e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103431:	85 db                	test   %ebx,%ebx
f0103433:	7f e2                	jg     f0103417 <vprintfmt+0x269>
f0103435:	89 75 08             	mov    %esi,0x8(%ebp)
f0103438:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010343b:	e9 93 fd ff ff       	jmp    f01031d3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103440:	83 fa 01             	cmp    $0x1,%edx
f0103443:	7e 16                	jle    f010345b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0103445:	8b 45 14             	mov    0x14(%ebp),%eax
f0103448:	8d 50 08             	lea    0x8(%eax),%edx
f010344b:	89 55 14             	mov    %edx,0x14(%ebp)
f010344e:	8b 50 04             	mov    0x4(%eax),%edx
f0103451:	8b 00                	mov    (%eax),%eax
f0103453:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103456:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103459:	eb 32                	jmp    f010348d <vprintfmt+0x2df>
	else if (lflag)
f010345b:	85 d2                	test   %edx,%edx
f010345d:	74 18                	je     f0103477 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010345f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103462:	8d 50 04             	lea    0x4(%eax),%edx
f0103465:	89 55 14             	mov    %edx,0x14(%ebp)
f0103468:	8b 30                	mov    (%eax),%esi
f010346a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010346d:	89 f0                	mov    %esi,%eax
f010346f:	c1 f8 1f             	sar    $0x1f,%eax
f0103472:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103475:	eb 16                	jmp    f010348d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0103477:	8b 45 14             	mov    0x14(%ebp),%eax
f010347a:	8d 50 04             	lea    0x4(%eax),%edx
f010347d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103480:	8b 30                	mov    (%eax),%esi
f0103482:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0103485:	89 f0                	mov    %esi,%eax
f0103487:	c1 f8 1f             	sar    $0x1f,%eax
f010348a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010348d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103490:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103493:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103498:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010349c:	0f 89 80 00 00 00    	jns    f0103522 <vprintfmt+0x374>
				putch('-', putdat);
f01034a2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034a6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01034ad:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01034b0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01034b3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01034b6:	f7 d8                	neg    %eax
f01034b8:	83 d2 00             	adc    $0x0,%edx
f01034bb:	f7 da                	neg    %edx
			}
			base = 10;
f01034bd:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01034c2:	eb 5e                	jmp    f0103522 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01034c4:	8d 45 14             	lea    0x14(%ebp),%eax
f01034c7:	e8 63 fc ff ff       	call   f010312f <getuint>
			base = 10;
f01034cc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01034d1:	eb 4f                	jmp    f0103522 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01034d3:	8d 45 14             	lea    0x14(%ebp),%eax
f01034d6:	e8 54 fc ff ff       	call   f010312f <getuint>
			base = 8;
f01034db:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01034e0:	eb 40                	jmp    f0103522 <vprintfmt+0x374>
		//	putch('X', putdat);
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01034e2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034e6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01034ed:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01034f0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034f4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01034fb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01034fe:	8b 45 14             	mov    0x14(%ebp),%eax
f0103501:	8d 50 04             	lea    0x4(%eax),%edx
f0103504:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103507:	8b 00                	mov    (%eax),%eax
f0103509:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010350e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0103513:	eb 0d                	jmp    f0103522 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103515:	8d 45 14             	lea    0x14(%ebp),%eax
f0103518:	e8 12 fc ff ff       	call   f010312f <getuint>
			base = 16;
f010351d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103522:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0103526:	89 74 24 10          	mov    %esi,0x10(%esp)
f010352a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010352d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103531:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103535:	89 04 24             	mov    %eax,(%esp)
f0103538:	89 54 24 04          	mov    %edx,0x4(%esp)
f010353c:	89 fa                	mov    %edi,%edx
f010353e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103541:	e8 fa fa ff ff       	call   f0103040 <printnum>
			break;
f0103546:	e9 88 fc ff ff       	jmp    f01031d3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010354b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010354f:	89 04 24             	mov    %eax,(%esp)
f0103552:	ff 55 08             	call   *0x8(%ebp)
			break;
f0103555:	e9 79 fc ff ff       	jmp    f01031d3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010355a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010355e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103565:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103568:	89 f3                	mov    %esi,%ebx
f010356a:	eb 03                	jmp    f010356f <vprintfmt+0x3c1>
f010356c:	83 eb 01             	sub    $0x1,%ebx
f010356f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0103573:	75 f7                	jne    f010356c <vprintfmt+0x3be>
f0103575:	e9 59 fc ff ff       	jmp    f01031d3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010357a:	83 c4 3c             	add    $0x3c,%esp
f010357d:	5b                   	pop    %ebx
f010357e:	5e                   	pop    %esi
f010357f:	5f                   	pop    %edi
f0103580:	5d                   	pop    %ebp
f0103581:	c3                   	ret    

f0103582 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103582:	55                   	push   %ebp
f0103583:	89 e5                	mov    %esp,%ebp
f0103585:	83 ec 28             	sub    $0x28,%esp
f0103588:	8b 45 08             	mov    0x8(%ebp),%eax
f010358b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010358e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103591:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103595:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103598:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010359f:	85 c0                	test   %eax,%eax
f01035a1:	74 30                	je     f01035d3 <vsnprintf+0x51>
f01035a3:	85 d2                	test   %edx,%edx
f01035a5:	7e 2c                	jle    f01035d3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01035a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01035aa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035ae:	8b 45 10             	mov    0x10(%ebp),%eax
f01035b1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035b5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01035b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035bc:	c7 04 24 69 31 10 f0 	movl   $0xf0103169,(%esp)
f01035c3:	e8 e6 fb ff ff       	call   f01031ae <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01035c8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01035cb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01035ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01035d1:	eb 05                	jmp    f01035d8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01035d3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01035d8:	c9                   	leave  
f01035d9:	c3                   	ret    

f01035da <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01035da:	55                   	push   %ebp
f01035db:	89 e5                	mov    %esp,%ebp
f01035dd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01035e0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01035e3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01035e7:	8b 45 10             	mov    0x10(%ebp),%eax
f01035ea:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035ee:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01035f8:	89 04 24             	mov    %eax,(%esp)
f01035fb:	e8 82 ff ff ff       	call   f0103582 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103600:	c9                   	leave  
f0103601:	c3                   	ret    
f0103602:	66 90                	xchg   %ax,%ax
f0103604:	66 90                	xchg   %ax,%ax
f0103606:	66 90                	xchg   %ax,%ax
f0103608:	66 90                	xchg   %ax,%ax
f010360a:	66 90                	xchg   %ax,%ax
f010360c:	66 90                	xchg   %ax,%ax
f010360e:	66 90                	xchg   %ax,%ax

f0103610 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103610:	55                   	push   %ebp
f0103611:	89 e5                	mov    %esp,%ebp
f0103613:	57                   	push   %edi
f0103614:	56                   	push   %esi
f0103615:	53                   	push   %ebx
f0103616:	83 ec 1c             	sub    $0x1c,%esp
f0103619:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010361c:	85 c0                	test   %eax,%eax
f010361e:	74 10                	je     f0103630 <readline+0x20>
		cprintf("%s", prompt);
f0103620:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103624:	c7 04 24 d4 49 10 f0 	movl   $0xf01049d4,(%esp)
f010362b:	e8 d7 f6 ff ff       	call   f0102d07 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103630:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103637:	e8 e6 cf ff ff       	call   f0100622 <iscons>
f010363c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010363e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103643:	e8 c9 cf ff ff       	call   f0100611 <getchar>
f0103648:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010364a:	85 c0                	test   %eax,%eax
f010364c:	79 17                	jns    f0103665 <readline+0x55>
			cprintf("read error: %e\n", c);
f010364e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103652:	c7 04 24 c8 4e 10 f0 	movl   $0xf0104ec8,(%esp)
f0103659:	e8 a9 f6 ff ff       	call   f0102d07 <cprintf>
			return NULL;
f010365e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103663:	eb 6d                	jmp    f01036d2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103665:	83 f8 7f             	cmp    $0x7f,%eax
f0103668:	74 05                	je     f010366f <readline+0x5f>
f010366a:	83 f8 08             	cmp    $0x8,%eax
f010366d:	75 19                	jne    f0103688 <readline+0x78>
f010366f:	85 f6                	test   %esi,%esi
f0103671:	7e 15                	jle    f0103688 <readline+0x78>
			if (echoing)
f0103673:	85 ff                	test   %edi,%edi
f0103675:	74 0c                	je     f0103683 <readline+0x73>
				cputchar('\b');
f0103677:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010367e:	e8 7e cf ff ff       	call   f0100601 <cputchar>
			i--;
f0103683:	83 ee 01             	sub    $0x1,%esi
f0103686:	eb bb                	jmp    f0103643 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103688:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010368e:	7f 1c                	jg     f01036ac <readline+0x9c>
f0103690:	83 fb 1f             	cmp    $0x1f,%ebx
f0103693:	7e 17                	jle    f01036ac <readline+0x9c>
			if (echoing)
f0103695:	85 ff                	test   %edi,%edi
f0103697:	74 08                	je     f01036a1 <readline+0x91>
				cputchar(c);
f0103699:	89 1c 24             	mov    %ebx,(%esp)
f010369c:	e8 60 cf ff ff       	call   f0100601 <cputchar>
			buf[i++] = c;
f01036a1:	88 9e 60 75 11 f0    	mov    %bl,-0xfee8aa0(%esi)
f01036a7:	8d 76 01             	lea    0x1(%esi),%esi
f01036aa:	eb 97                	jmp    f0103643 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01036ac:	83 fb 0d             	cmp    $0xd,%ebx
f01036af:	74 05                	je     f01036b6 <readline+0xa6>
f01036b1:	83 fb 0a             	cmp    $0xa,%ebx
f01036b4:	75 8d                	jne    f0103643 <readline+0x33>
			if (echoing)
f01036b6:	85 ff                	test   %edi,%edi
f01036b8:	74 0c                	je     f01036c6 <readline+0xb6>
				cputchar('\n');
f01036ba:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01036c1:	e8 3b cf ff ff       	call   f0100601 <cputchar>
			buf[i] = 0;
f01036c6:	c6 86 60 75 11 f0 00 	movb   $0x0,-0xfee8aa0(%esi)
			return buf;
f01036cd:	b8 60 75 11 f0       	mov    $0xf0117560,%eax
		}
	}
}
f01036d2:	83 c4 1c             	add    $0x1c,%esp
f01036d5:	5b                   	pop    %ebx
f01036d6:	5e                   	pop    %esi
f01036d7:	5f                   	pop    %edi
f01036d8:	5d                   	pop    %ebp
f01036d9:	c3                   	ret    
f01036da:	66 90                	xchg   %ax,%ax
f01036dc:	66 90                	xchg   %ax,%ax
f01036de:	66 90                	xchg   %ax,%ax

f01036e0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01036e0:	55                   	push   %ebp
f01036e1:	89 e5                	mov    %esp,%ebp
f01036e3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01036e6:	b8 00 00 00 00       	mov    $0x0,%eax
f01036eb:	eb 03                	jmp    f01036f0 <strlen+0x10>
		n++;
f01036ed:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01036f0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01036f4:	75 f7                	jne    f01036ed <strlen+0xd>
		n++;
	return n;
}
f01036f6:	5d                   	pop    %ebp
f01036f7:	c3                   	ret    

f01036f8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01036f8:	55                   	push   %ebp
f01036f9:	89 e5                	mov    %esp,%ebp
f01036fb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01036fe:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103701:	b8 00 00 00 00       	mov    $0x0,%eax
f0103706:	eb 03                	jmp    f010370b <strnlen+0x13>
		n++;
f0103708:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010370b:	39 d0                	cmp    %edx,%eax
f010370d:	74 06                	je     f0103715 <strnlen+0x1d>
f010370f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103713:	75 f3                	jne    f0103708 <strnlen+0x10>
		n++;
	return n;
}
f0103715:	5d                   	pop    %ebp
f0103716:	c3                   	ret    

f0103717 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103717:	55                   	push   %ebp
f0103718:	89 e5                	mov    %esp,%ebp
f010371a:	53                   	push   %ebx
f010371b:	8b 45 08             	mov    0x8(%ebp),%eax
f010371e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103721:	89 c2                	mov    %eax,%edx
f0103723:	83 c2 01             	add    $0x1,%edx
f0103726:	83 c1 01             	add    $0x1,%ecx
f0103729:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010372d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0103730:	84 db                	test   %bl,%bl
f0103732:	75 ef                	jne    f0103723 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103734:	5b                   	pop    %ebx
f0103735:	5d                   	pop    %ebp
f0103736:	c3                   	ret    

f0103737 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103737:	55                   	push   %ebp
f0103738:	89 e5                	mov    %esp,%ebp
f010373a:	53                   	push   %ebx
f010373b:	83 ec 08             	sub    $0x8,%esp
f010373e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103741:	89 1c 24             	mov    %ebx,(%esp)
f0103744:	e8 97 ff ff ff       	call   f01036e0 <strlen>
	strcpy(dst + len, src);
f0103749:	8b 55 0c             	mov    0xc(%ebp),%edx
f010374c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103750:	01 d8                	add    %ebx,%eax
f0103752:	89 04 24             	mov    %eax,(%esp)
f0103755:	e8 bd ff ff ff       	call   f0103717 <strcpy>
	return dst;
}
f010375a:	89 d8                	mov    %ebx,%eax
f010375c:	83 c4 08             	add    $0x8,%esp
f010375f:	5b                   	pop    %ebx
f0103760:	5d                   	pop    %ebp
f0103761:	c3                   	ret    

f0103762 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103762:	55                   	push   %ebp
f0103763:	89 e5                	mov    %esp,%ebp
f0103765:	56                   	push   %esi
f0103766:	53                   	push   %ebx
f0103767:	8b 75 08             	mov    0x8(%ebp),%esi
f010376a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010376d:	89 f3                	mov    %esi,%ebx
f010376f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103772:	89 f2                	mov    %esi,%edx
f0103774:	eb 0f                	jmp    f0103785 <strncpy+0x23>
		*dst++ = *src;
f0103776:	83 c2 01             	add    $0x1,%edx
f0103779:	0f b6 01             	movzbl (%ecx),%eax
f010377c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010377f:	80 39 01             	cmpb   $0x1,(%ecx)
f0103782:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103785:	39 da                	cmp    %ebx,%edx
f0103787:	75 ed                	jne    f0103776 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103789:	89 f0                	mov    %esi,%eax
f010378b:	5b                   	pop    %ebx
f010378c:	5e                   	pop    %esi
f010378d:	5d                   	pop    %ebp
f010378e:	c3                   	ret    

f010378f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010378f:	55                   	push   %ebp
f0103790:	89 e5                	mov    %esp,%ebp
f0103792:	56                   	push   %esi
f0103793:	53                   	push   %ebx
f0103794:	8b 75 08             	mov    0x8(%ebp),%esi
f0103797:	8b 55 0c             	mov    0xc(%ebp),%edx
f010379a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010379d:	89 f0                	mov    %esi,%eax
f010379f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01037a3:	85 c9                	test   %ecx,%ecx
f01037a5:	75 0b                	jne    f01037b2 <strlcpy+0x23>
f01037a7:	eb 1d                	jmp    f01037c6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01037a9:	83 c0 01             	add    $0x1,%eax
f01037ac:	83 c2 01             	add    $0x1,%edx
f01037af:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01037b2:	39 d8                	cmp    %ebx,%eax
f01037b4:	74 0b                	je     f01037c1 <strlcpy+0x32>
f01037b6:	0f b6 0a             	movzbl (%edx),%ecx
f01037b9:	84 c9                	test   %cl,%cl
f01037bb:	75 ec                	jne    f01037a9 <strlcpy+0x1a>
f01037bd:	89 c2                	mov    %eax,%edx
f01037bf:	eb 02                	jmp    f01037c3 <strlcpy+0x34>
f01037c1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01037c3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01037c6:	29 f0                	sub    %esi,%eax
}
f01037c8:	5b                   	pop    %ebx
f01037c9:	5e                   	pop    %esi
f01037ca:	5d                   	pop    %ebp
f01037cb:	c3                   	ret    

f01037cc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01037cc:	55                   	push   %ebp
f01037cd:	89 e5                	mov    %esp,%ebp
f01037cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01037d2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01037d5:	eb 06                	jmp    f01037dd <strcmp+0x11>
		p++, q++;
f01037d7:	83 c1 01             	add    $0x1,%ecx
f01037da:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01037dd:	0f b6 01             	movzbl (%ecx),%eax
f01037e0:	84 c0                	test   %al,%al
f01037e2:	74 04                	je     f01037e8 <strcmp+0x1c>
f01037e4:	3a 02                	cmp    (%edx),%al
f01037e6:	74 ef                	je     f01037d7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01037e8:	0f b6 c0             	movzbl %al,%eax
f01037eb:	0f b6 12             	movzbl (%edx),%edx
f01037ee:	29 d0                	sub    %edx,%eax
}
f01037f0:	5d                   	pop    %ebp
f01037f1:	c3                   	ret    

f01037f2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01037f2:	55                   	push   %ebp
f01037f3:	89 e5                	mov    %esp,%ebp
f01037f5:	53                   	push   %ebx
f01037f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01037f9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01037fc:	89 c3                	mov    %eax,%ebx
f01037fe:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0103801:	eb 06                	jmp    f0103809 <strncmp+0x17>
		n--, p++, q++;
f0103803:	83 c0 01             	add    $0x1,%eax
f0103806:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103809:	39 d8                	cmp    %ebx,%eax
f010380b:	74 15                	je     f0103822 <strncmp+0x30>
f010380d:	0f b6 08             	movzbl (%eax),%ecx
f0103810:	84 c9                	test   %cl,%cl
f0103812:	74 04                	je     f0103818 <strncmp+0x26>
f0103814:	3a 0a                	cmp    (%edx),%cl
f0103816:	74 eb                	je     f0103803 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103818:	0f b6 00             	movzbl (%eax),%eax
f010381b:	0f b6 12             	movzbl (%edx),%edx
f010381e:	29 d0                	sub    %edx,%eax
f0103820:	eb 05                	jmp    f0103827 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103822:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103827:	5b                   	pop    %ebx
f0103828:	5d                   	pop    %ebp
f0103829:	c3                   	ret    

f010382a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010382a:	55                   	push   %ebp
f010382b:	89 e5                	mov    %esp,%ebp
f010382d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103830:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103834:	eb 07                	jmp    f010383d <strchr+0x13>
		if (*s == c)
f0103836:	38 ca                	cmp    %cl,%dl
f0103838:	74 0f                	je     f0103849 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010383a:	83 c0 01             	add    $0x1,%eax
f010383d:	0f b6 10             	movzbl (%eax),%edx
f0103840:	84 d2                	test   %dl,%dl
f0103842:	75 f2                	jne    f0103836 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0103844:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103849:	5d                   	pop    %ebp
f010384a:	c3                   	ret    

f010384b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010384b:	55                   	push   %ebp
f010384c:	89 e5                	mov    %esp,%ebp
f010384e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103851:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103855:	eb 07                	jmp    f010385e <strfind+0x13>
		if (*s == c)
f0103857:	38 ca                	cmp    %cl,%dl
f0103859:	74 0a                	je     f0103865 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010385b:	83 c0 01             	add    $0x1,%eax
f010385e:	0f b6 10             	movzbl (%eax),%edx
f0103861:	84 d2                	test   %dl,%dl
f0103863:	75 f2                	jne    f0103857 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0103865:	5d                   	pop    %ebp
f0103866:	c3                   	ret    

f0103867 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103867:	55                   	push   %ebp
f0103868:	89 e5                	mov    %esp,%ebp
f010386a:	57                   	push   %edi
f010386b:	56                   	push   %esi
f010386c:	53                   	push   %ebx
f010386d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103870:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103873:	85 c9                	test   %ecx,%ecx
f0103875:	74 36                	je     f01038ad <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103877:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010387d:	75 28                	jne    f01038a7 <memset+0x40>
f010387f:	f6 c1 03             	test   $0x3,%cl
f0103882:	75 23                	jne    f01038a7 <memset+0x40>
		c &= 0xFF;
f0103884:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103888:	89 d3                	mov    %edx,%ebx
f010388a:	c1 e3 08             	shl    $0x8,%ebx
f010388d:	89 d6                	mov    %edx,%esi
f010388f:	c1 e6 18             	shl    $0x18,%esi
f0103892:	89 d0                	mov    %edx,%eax
f0103894:	c1 e0 10             	shl    $0x10,%eax
f0103897:	09 f0                	or     %esi,%eax
f0103899:	09 c2                	or     %eax,%edx
f010389b:	89 d0                	mov    %edx,%eax
f010389d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010389f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01038a2:	fc                   	cld    
f01038a3:	f3 ab                	rep stos %eax,%es:(%edi)
f01038a5:	eb 06                	jmp    f01038ad <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01038a7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038aa:	fc                   	cld    
f01038ab:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01038ad:	89 f8                	mov    %edi,%eax
f01038af:	5b                   	pop    %ebx
f01038b0:	5e                   	pop    %esi
f01038b1:	5f                   	pop    %edi
f01038b2:	5d                   	pop    %ebp
f01038b3:	c3                   	ret    

f01038b4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01038b4:	55                   	push   %ebp
f01038b5:	89 e5                	mov    %esp,%ebp
f01038b7:	57                   	push   %edi
f01038b8:	56                   	push   %esi
f01038b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01038bc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01038bf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01038c2:	39 c6                	cmp    %eax,%esi
f01038c4:	73 35                	jae    f01038fb <memmove+0x47>
f01038c6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01038c9:	39 d0                	cmp    %edx,%eax
f01038cb:	73 2e                	jae    f01038fb <memmove+0x47>
		s += n;
		d += n;
f01038cd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01038d0:	89 d6                	mov    %edx,%esi
f01038d2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01038d4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01038da:	75 13                	jne    f01038ef <memmove+0x3b>
f01038dc:	f6 c1 03             	test   $0x3,%cl
f01038df:	75 0e                	jne    f01038ef <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01038e1:	83 ef 04             	sub    $0x4,%edi
f01038e4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01038e7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01038ea:	fd                   	std    
f01038eb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01038ed:	eb 09                	jmp    f01038f8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01038ef:	83 ef 01             	sub    $0x1,%edi
f01038f2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01038f5:	fd                   	std    
f01038f6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01038f8:	fc                   	cld    
f01038f9:	eb 1d                	jmp    f0103918 <memmove+0x64>
f01038fb:	89 f2                	mov    %esi,%edx
f01038fd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01038ff:	f6 c2 03             	test   $0x3,%dl
f0103902:	75 0f                	jne    f0103913 <memmove+0x5f>
f0103904:	f6 c1 03             	test   $0x3,%cl
f0103907:	75 0a                	jne    f0103913 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103909:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010390c:	89 c7                	mov    %eax,%edi
f010390e:	fc                   	cld    
f010390f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103911:	eb 05                	jmp    f0103918 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103913:	89 c7                	mov    %eax,%edi
f0103915:	fc                   	cld    
f0103916:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103918:	5e                   	pop    %esi
f0103919:	5f                   	pop    %edi
f010391a:	5d                   	pop    %ebp
f010391b:	c3                   	ret    

f010391c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010391c:	55                   	push   %ebp
f010391d:	89 e5                	mov    %esp,%ebp
f010391f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103922:	8b 45 10             	mov    0x10(%ebp),%eax
f0103925:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103929:	8b 45 0c             	mov    0xc(%ebp),%eax
f010392c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103930:	8b 45 08             	mov    0x8(%ebp),%eax
f0103933:	89 04 24             	mov    %eax,(%esp)
f0103936:	e8 79 ff ff ff       	call   f01038b4 <memmove>
}
f010393b:	c9                   	leave  
f010393c:	c3                   	ret    

f010393d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010393d:	55                   	push   %ebp
f010393e:	89 e5                	mov    %esp,%ebp
f0103940:	56                   	push   %esi
f0103941:	53                   	push   %ebx
f0103942:	8b 55 08             	mov    0x8(%ebp),%edx
f0103945:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103948:	89 d6                	mov    %edx,%esi
f010394a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010394d:	eb 1a                	jmp    f0103969 <memcmp+0x2c>
		if (*s1 != *s2)
f010394f:	0f b6 02             	movzbl (%edx),%eax
f0103952:	0f b6 19             	movzbl (%ecx),%ebx
f0103955:	38 d8                	cmp    %bl,%al
f0103957:	74 0a                	je     f0103963 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0103959:	0f b6 c0             	movzbl %al,%eax
f010395c:	0f b6 db             	movzbl %bl,%ebx
f010395f:	29 d8                	sub    %ebx,%eax
f0103961:	eb 0f                	jmp    f0103972 <memcmp+0x35>
		s1++, s2++;
f0103963:	83 c2 01             	add    $0x1,%edx
f0103966:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103969:	39 f2                	cmp    %esi,%edx
f010396b:	75 e2                	jne    f010394f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010396d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103972:	5b                   	pop    %ebx
f0103973:	5e                   	pop    %esi
f0103974:	5d                   	pop    %ebp
f0103975:	c3                   	ret    

f0103976 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103976:	55                   	push   %ebp
f0103977:	89 e5                	mov    %esp,%ebp
f0103979:	8b 45 08             	mov    0x8(%ebp),%eax
f010397c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010397f:	89 c2                	mov    %eax,%edx
f0103981:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103984:	eb 07                	jmp    f010398d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103986:	38 08                	cmp    %cl,(%eax)
f0103988:	74 07                	je     f0103991 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010398a:	83 c0 01             	add    $0x1,%eax
f010398d:	39 d0                	cmp    %edx,%eax
f010398f:	72 f5                	jb     f0103986 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103991:	5d                   	pop    %ebp
f0103992:	c3                   	ret    

f0103993 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103993:	55                   	push   %ebp
f0103994:	89 e5                	mov    %esp,%ebp
f0103996:	57                   	push   %edi
f0103997:	56                   	push   %esi
f0103998:	53                   	push   %ebx
f0103999:	8b 55 08             	mov    0x8(%ebp),%edx
f010399c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010399f:	eb 03                	jmp    f01039a4 <strtol+0x11>
		s++;
f01039a1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01039a4:	0f b6 0a             	movzbl (%edx),%ecx
f01039a7:	80 f9 09             	cmp    $0x9,%cl
f01039aa:	74 f5                	je     f01039a1 <strtol+0xe>
f01039ac:	80 f9 20             	cmp    $0x20,%cl
f01039af:	74 f0                	je     f01039a1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01039b1:	80 f9 2b             	cmp    $0x2b,%cl
f01039b4:	75 0a                	jne    f01039c0 <strtol+0x2d>
		s++;
f01039b6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01039b9:	bf 00 00 00 00       	mov    $0x0,%edi
f01039be:	eb 11                	jmp    f01039d1 <strtol+0x3e>
f01039c0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01039c5:	80 f9 2d             	cmp    $0x2d,%cl
f01039c8:	75 07                	jne    f01039d1 <strtol+0x3e>
		s++, neg = 1;
f01039ca:	8d 52 01             	lea    0x1(%edx),%edx
f01039cd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01039d1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01039d6:	75 15                	jne    f01039ed <strtol+0x5a>
f01039d8:	80 3a 30             	cmpb   $0x30,(%edx)
f01039db:	75 10                	jne    f01039ed <strtol+0x5a>
f01039dd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01039e1:	75 0a                	jne    f01039ed <strtol+0x5a>
		s += 2, base = 16;
f01039e3:	83 c2 02             	add    $0x2,%edx
f01039e6:	b8 10 00 00 00       	mov    $0x10,%eax
f01039eb:	eb 10                	jmp    f01039fd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01039ed:	85 c0                	test   %eax,%eax
f01039ef:	75 0c                	jne    f01039fd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01039f1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01039f3:	80 3a 30             	cmpb   $0x30,(%edx)
f01039f6:	75 05                	jne    f01039fd <strtol+0x6a>
		s++, base = 8;
f01039f8:	83 c2 01             	add    $0x1,%edx
f01039fb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01039fd:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103a02:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103a05:	0f b6 0a             	movzbl (%edx),%ecx
f0103a08:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103a0b:	89 f0                	mov    %esi,%eax
f0103a0d:	3c 09                	cmp    $0x9,%al
f0103a0f:	77 08                	ja     f0103a19 <strtol+0x86>
			dig = *s - '0';
f0103a11:	0f be c9             	movsbl %cl,%ecx
f0103a14:	83 e9 30             	sub    $0x30,%ecx
f0103a17:	eb 20                	jmp    f0103a39 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0103a19:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103a1c:	89 f0                	mov    %esi,%eax
f0103a1e:	3c 19                	cmp    $0x19,%al
f0103a20:	77 08                	ja     f0103a2a <strtol+0x97>
			dig = *s - 'a' + 10;
f0103a22:	0f be c9             	movsbl %cl,%ecx
f0103a25:	83 e9 57             	sub    $0x57,%ecx
f0103a28:	eb 0f                	jmp    f0103a39 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0103a2a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103a2d:	89 f0                	mov    %esi,%eax
f0103a2f:	3c 19                	cmp    $0x19,%al
f0103a31:	77 16                	ja     f0103a49 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0103a33:	0f be c9             	movsbl %cl,%ecx
f0103a36:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103a39:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0103a3c:	7d 0f                	jge    f0103a4d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0103a3e:	83 c2 01             	add    $0x1,%edx
f0103a41:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0103a45:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0103a47:	eb bc                	jmp    f0103a05 <strtol+0x72>
f0103a49:	89 d8                	mov    %ebx,%eax
f0103a4b:	eb 02                	jmp    f0103a4f <strtol+0xbc>
f0103a4d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0103a4f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103a53:	74 05                	je     f0103a5a <strtol+0xc7>
		*endptr = (char *) s;
f0103a55:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a58:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0103a5a:	f7 d8                	neg    %eax
f0103a5c:	85 ff                	test   %edi,%edi
f0103a5e:	0f 44 c3             	cmove  %ebx,%eax
}
f0103a61:	5b                   	pop    %ebx
f0103a62:	5e                   	pop    %esi
f0103a63:	5f                   	pop    %edi
f0103a64:	5d                   	pop    %ebp
f0103a65:	c3                   	ret    
f0103a66:	66 90                	xchg   %ax,%ax
f0103a68:	66 90                	xchg   %ax,%ax
f0103a6a:	66 90                	xchg   %ax,%ax
f0103a6c:	66 90                	xchg   %ax,%ax
f0103a6e:	66 90                	xchg   %ax,%ax

f0103a70 <__udivdi3>:
f0103a70:	55                   	push   %ebp
f0103a71:	57                   	push   %edi
f0103a72:	56                   	push   %esi
f0103a73:	83 ec 0c             	sub    $0xc,%esp
f0103a76:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103a7a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0103a7e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0103a82:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103a86:	85 c0                	test   %eax,%eax
f0103a88:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103a8c:	89 ea                	mov    %ebp,%edx
f0103a8e:	89 0c 24             	mov    %ecx,(%esp)
f0103a91:	75 2d                	jne    f0103ac0 <__udivdi3+0x50>
f0103a93:	39 e9                	cmp    %ebp,%ecx
f0103a95:	77 61                	ja     f0103af8 <__udivdi3+0x88>
f0103a97:	85 c9                	test   %ecx,%ecx
f0103a99:	89 ce                	mov    %ecx,%esi
f0103a9b:	75 0b                	jne    f0103aa8 <__udivdi3+0x38>
f0103a9d:	b8 01 00 00 00       	mov    $0x1,%eax
f0103aa2:	31 d2                	xor    %edx,%edx
f0103aa4:	f7 f1                	div    %ecx
f0103aa6:	89 c6                	mov    %eax,%esi
f0103aa8:	31 d2                	xor    %edx,%edx
f0103aaa:	89 e8                	mov    %ebp,%eax
f0103aac:	f7 f6                	div    %esi
f0103aae:	89 c5                	mov    %eax,%ebp
f0103ab0:	89 f8                	mov    %edi,%eax
f0103ab2:	f7 f6                	div    %esi
f0103ab4:	89 ea                	mov    %ebp,%edx
f0103ab6:	83 c4 0c             	add    $0xc,%esp
f0103ab9:	5e                   	pop    %esi
f0103aba:	5f                   	pop    %edi
f0103abb:	5d                   	pop    %ebp
f0103abc:	c3                   	ret    
f0103abd:	8d 76 00             	lea    0x0(%esi),%esi
f0103ac0:	39 e8                	cmp    %ebp,%eax
f0103ac2:	77 24                	ja     f0103ae8 <__udivdi3+0x78>
f0103ac4:	0f bd e8             	bsr    %eax,%ebp
f0103ac7:	83 f5 1f             	xor    $0x1f,%ebp
f0103aca:	75 3c                	jne    f0103b08 <__udivdi3+0x98>
f0103acc:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103ad0:	39 34 24             	cmp    %esi,(%esp)
f0103ad3:	0f 86 9f 00 00 00    	jbe    f0103b78 <__udivdi3+0x108>
f0103ad9:	39 d0                	cmp    %edx,%eax
f0103adb:	0f 82 97 00 00 00    	jb     f0103b78 <__udivdi3+0x108>
f0103ae1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103ae8:	31 d2                	xor    %edx,%edx
f0103aea:	31 c0                	xor    %eax,%eax
f0103aec:	83 c4 0c             	add    $0xc,%esp
f0103aef:	5e                   	pop    %esi
f0103af0:	5f                   	pop    %edi
f0103af1:	5d                   	pop    %ebp
f0103af2:	c3                   	ret    
f0103af3:	90                   	nop
f0103af4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103af8:	89 f8                	mov    %edi,%eax
f0103afa:	f7 f1                	div    %ecx
f0103afc:	31 d2                	xor    %edx,%edx
f0103afe:	83 c4 0c             	add    $0xc,%esp
f0103b01:	5e                   	pop    %esi
f0103b02:	5f                   	pop    %edi
f0103b03:	5d                   	pop    %ebp
f0103b04:	c3                   	ret    
f0103b05:	8d 76 00             	lea    0x0(%esi),%esi
f0103b08:	89 e9                	mov    %ebp,%ecx
f0103b0a:	8b 3c 24             	mov    (%esp),%edi
f0103b0d:	d3 e0                	shl    %cl,%eax
f0103b0f:	89 c6                	mov    %eax,%esi
f0103b11:	b8 20 00 00 00       	mov    $0x20,%eax
f0103b16:	29 e8                	sub    %ebp,%eax
f0103b18:	89 c1                	mov    %eax,%ecx
f0103b1a:	d3 ef                	shr    %cl,%edi
f0103b1c:	89 e9                	mov    %ebp,%ecx
f0103b1e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103b22:	8b 3c 24             	mov    (%esp),%edi
f0103b25:	09 74 24 08          	or     %esi,0x8(%esp)
f0103b29:	89 d6                	mov    %edx,%esi
f0103b2b:	d3 e7                	shl    %cl,%edi
f0103b2d:	89 c1                	mov    %eax,%ecx
f0103b2f:	89 3c 24             	mov    %edi,(%esp)
f0103b32:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103b36:	d3 ee                	shr    %cl,%esi
f0103b38:	89 e9                	mov    %ebp,%ecx
f0103b3a:	d3 e2                	shl    %cl,%edx
f0103b3c:	89 c1                	mov    %eax,%ecx
f0103b3e:	d3 ef                	shr    %cl,%edi
f0103b40:	09 d7                	or     %edx,%edi
f0103b42:	89 f2                	mov    %esi,%edx
f0103b44:	89 f8                	mov    %edi,%eax
f0103b46:	f7 74 24 08          	divl   0x8(%esp)
f0103b4a:	89 d6                	mov    %edx,%esi
f0103b4c:	89 c7                	mov    %eax,%edi
f0103b4e:	f7 24 24             	mull   (%esp)
f0103b51:	39 d6                	cmp    %edx,%esi
f0103b53:	89 14 24             	mov    %edx,(%esp)
f0103b56:	72 30                	jb     f0103b88 <__udivdi3+0x118>
f0103b58:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103b5c:	89 e9                	mov    %ebp,%ecx
f0103b5e:	d3 e2                	shl    %cl,%edx
f0103b60:	39 c2                	cmp    %eax,%edx
f0103b62:	73 05                	jae    f0103b69 <__udivdi3+0xf9>
f0103b64:	3b 34 24             	cmp    (%esp),%esi
f0103b67:	74 1f                	je     f0103b88 <__udivdi3+0x118>
f0103b69:	89 f8                	mov    %edi,%eax
f0103b6b:	31 d2                	xor    %edx,%edx
f0103b6d:	e9 7a ff ff ff       	jmp    f0103aec <__udivdi3+0x7c>
f0103b72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103b78:	31 d2                	xor    %edx,%edx
f0103b7a:	b8 01 00 00 00       	mov    $0x1,%eax
f0103b7f:	e9 68 ff ff ff       	jmp    f0103aec <__udivdi3+0x7c>
f0103b84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103b88:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103b8b:	31 d2                	xor    %edx,%edx
f0103b8d:	83 c4 0c             	add    $0xc,%esp
f0103b90:	5e                   	pop    %esi
f0103b91:	5f                   	pop    %edi
f0103b92:	5d                   	pop    %ebp
f0103b93:	c3                   	ret    
f0103b94:	66 90                	xchg   %ax,%ax
f0103b96:	66 90                	xchg   %ax,%ax
f0103b98:	66 90                	xchg   %ax,%ax
f0103b9a:	66 90                	xchg   %ax,%ax
f0103b9c:	66 90                	xchg   %ax,%ax
f0103b9e:	66 90                	xchg   %ax,%ax

f0103ba0 <__umoddi3>:
f0103ba0:	55                   	push   %ebp
f0103ba1:	57                   	push   %edi
f0103ba2:	56                   	push   %esi
f0103ba3:	83 ec 14             	sub    $0x14,%esp
f0103ba6:	8b 44 24 28          	mov    0x28(%esp),%eax
f0103baa:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0103bae:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0103bb2:	89 c7                	mov    %eax,%edi
f0103bb4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bb8:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103bbc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0103bc0:	89 34 24             	mov    %esi,(%esp)
f0103bc3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103bc7:	85 c0                	test   %eax,%eax
f0103bc9:	89 c2                	mov    %eax,%edx
f0103bcb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103bcf:	75 17                	jne    f0103be8 <__umoddi3+0x48>
f0103bd1:	39 fe                	cmp    %edi,%esi
f0103bd3:	76 4b                	jbe    f0103c20 <__umoddi3+0x80>
f0103bd5:	89 c8                	mov    %ecx,%eax
f0103bd7:	89 fa                	mov    %edi,%edx
f0103bd9:	f7 f6                	div    %esi
f0103bdb:	89 d0                	mov    %edx,%eax
f0103bdd:	31 d2                	xor    %edx,%edx
f0103bdf:	83 c4 14             	add    $0x14,%esp
f0103be2:	5e                   	pop    %esi
f0103be3:	5f                   	pop    %edi
f0103be4:	5d                   	pop    %ebp
f0103be5:	c3                   	ret    
f0103be6:	66 90                	xchg   %ax,%ax
f0103be8:	39 f8                	cmp    %edi,%eax
f0103bea:	77 54                	ja     f0103c40 <__umoddi3+0xa0>
f0103bec:	0f bd e8             	bsr    %eax,%ebp
f0103bef:	83 f5 1f             	xor    $0x1f,%ebp
f0103bf2:	75 5c                	jne    f0103c50 <__umoddi3+0xb0>
f0103bf4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103bf8:	39 3c 24             	cmp    %edi,(%esp)
f0103bfb:	0f 87 e7 00 00 00    	ja     f0103ce8 <__umoddi3+0x148>
f0103c01:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103c05:	29 f1                	sub    %esi,%ecx
f0103c07:	19 c7                	sbb    %eax,%edi
f0103c09:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103c0d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c11:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103c15:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0103c19:	83 c4 14             	add    $0x14,%esp
f0103c1c:	5e                   	pop    %esi
f0103c1d:	5f                   	pop    %edi
f0103c1e:	5d                   	pop    %ebp
f0103c1f:	c3                   	ret    
f0103c20:	85 f6                	test   %esi,%esi
f0103c22:	89 f5                	mov    %esi,%ebp
f0103c24:	75 0b                	jne    f0103c31 <__umoddi3+0x91>
f0103c26:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c2b:	31 d2                	xor    %edx,%edx
f0103c2d:	f7 f6                	div    %esi
f0103c2f:	89 c5                	mov    %eax,%ebp
f0103c31:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103c35:	31 d2                	xor    %edx,%edx
f0103c37:	f7 f5                	div    %ebp
f0103c39:	89 c8                	mov    %ecx,%eax
f0103c3b:	f7 f5                	div    %ebp
f0103c3d:	eb 9c                	jmp    f0103bdb <__umoddi3+0x3b>
f0103c3f:	90                   	nop
f0103c40:	89 c8                	mov    %ecx,%eax
f0103c42:	89 fa                	mov    %edi,%edx
f0103c44:	83 c4 14             	add    $0x14,%esp
f0103c47:	5e                   	pop    %esi
f0103c48:	5f                   	pop    %edi
f0103c49:	5d                   	pop    %ebp
f0103c4a:	c3                   	ret    
f0103c4b:	90                   	nop
f0103c4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103c50:	8b 04 24             	mov    (%esp),%eax
f0103c53:	be 20 00 00 00       	mov    $0x20,%esi
f0103c58:	89 e9                	mov    %ebp,%ecx
f0103c5a:	29 ee                	sub    %ebp,%esi
f0103c5c:	d3 e2                	shl    %cl,%edx
f0103c5e:	89 f1                	mov    %esi,%ecx
f0103c60:	d3 e8                	shr    %cl,%eax
f0103c62:	89 e9                	mov    %ebp,%ecx
f0103c64:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c68:	8b 04 24             	mov    (%esp),%eax
f0103c6b:	09 54 24 04          	or     %edx,0x4(%esp)
f0103c6f:	89 fa                	mov    %edi,%edx
f0103c71:	d3 e0                	shl    %cl,%eax
f0103c73:	89 f1                	mov    %esi,%ecx
f0103c75:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c79:	8b 44 24 10          	mov    0x10(%esp),%eax
f0103c7d:	d3 ea                	shr    %cl,%edx
f0103c7f:	89 e9                	mov    %ebp,%ecx
f0103c81:	d3 e7                	shl    %cl,%edi
f0103c83:	89 f1                	mov    %esi,%ecx
f0103c85:	d3 e8                	shr    %cl,%eax
f0103c87:	89 e9                	mov    %ebp,%ecx
f0103c89:	09 f8                	or     %edi,%eax
f0103c8b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0103c8f:	f7 74 24 04          	divl   0x4(%esp)
f0103c93:	d3 e7                	shl    %cl,%edi
f0103c95:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103c99:	89 d7                	mov    %edx,%edi
f0103c9b:	f7 64 24 08          	mull   0x8(%esp)
f0103c9f:	39 d7                	cmp    %edx,%edi
f0103ca1:	89 c1                	mov    %eax,%ecx
f0103ca3:	89 14 24             	mov    %edx,(%esp)
f0103ca6:	72 2c                	jb     f0103cd4 <__umoddi3+0x134>
f0103ca8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0103cac:	72 22                	jb     f0103cd0 <__umoddi3+0x130>
f0103cae:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103cb2:	29 c8                	sub    %ecx,%eax
f0103cb4:	19 d7                	sbb    %edx,%edi
f0103cb6:	89 e9                	mov    %ebp,%ecx
f0103cb8:	89 fa                	mov    %edi,%edx
f0103cba:	d3 e8                	shr    %cl,%eax
f0103cbc:	89 f1                	mov    %esi,%ecx
f0103cbe:	d3 e2                	shl    %cl,%edx
f0103cc0:	89 e9                	mov    %ebp,%ecx
f0103cc2:	d3 ef                	shr    %cl,%edi
f0103cc4:	09 d0                	or     %edx,%eax
f0103cc6:	89 fa                	mov    %edi,%edx
f0103cc8:	83 c4 14             	add    $0x14,%esp
f0103ccb:	5e                   	pop    %esi
f0103ccc:	5f                   	pop    %edi
f0103ccd:	5d                   	pop    %ebp
f0103cce:	c3                   	ret    
f0103ccf:	90                   	nop
f0103cd0:	39 d7                	cmp    %edx,%edi
f0103cd2:	75 da                	jne    f0103cae <__umoddi3+0x10e>
f0103cd4:	8b 14 24             	mov    (%esp),%edx
f0103cd7:	89 c1                	mov    %eax,%ecx
f0103cd9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0103cdd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0103ce1:	eb cb                	jmp    f0103cae <__umoddi3+0x10e>
f0103ce3:	90                   	nop
f0103ce4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103ce8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0103cec:	0f 82 0f ff ff ff    	jb     f0103c01 <__umoddi3+0x61>
f0103cf2:	e9 1a ff ff ff       	jmp    f0103c11 <__umoddi3+0x71>
