def read_u16_le(buf, off):
    return buf[off] | (buf[off+1] << 8)

def write_u16_le(buf, off, val):
    buf[off] = val & 0xFF
    buf[off+1] = (val >> 8) & 0xFF

def read_u32_le(buf, off):
    return (buf[off] |
           (buf[off+1] << 8) |
           (buf[off+2] << 16) |
           (buf[off+3] << 24))
