# platform_shims.py
import sys

if sys.platform.startswith('win'):
    import msvcrt
    def getch(): return msvcrt.getch()
    def kbhit(): return msvcrt.kbhit()
    HAS_READLINE = False
else:
    import tty
    import termios
    import select
    def getch():
        fd = sys.stdin.fileno()
        old = termios.tcgetattr(fd)
        try:
            tty.setraw(fd)
            ch = sys.stdin.read(1)
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old)
        return ch.encode()
    def kbhit():
        dr, _, _ = select.select([sys.stdin], [], [], 0)
        return dr != []
    try:
        import readline
        HAS_READLINE = True
    except ImportError:
        HAS_READLINE = False
