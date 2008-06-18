#
# Copyright (c) 2006- Facebook
# Distributed under the Thrift Software License
#
# See accompanying file LICENSE or visit the Thrift site at:
# http://developers.facebook.com/thrift/
#
# Author: Mark Slee <mcslee@facebook.com>
#
require 'thrift/protocol'

module Thrift
  class BinaryProtocol < Protocol
    VERSION_MASK = 0xffff0000
    VERSION_1 = 0x80010000

    def initialize(trans)
      super(trans)
    end

    def write_message_begin(name, type, seqid)
      writeI32(VERSION_1 | type)
      writeString(name)
      writeI32(seqid)
    end

    def write_field_begin(name, type, id)
      writeByte(type)
      writeI16(id)
    end

    def write_field_stop()
      writeByte(Thrift::Types::STOP)
    end

    def write_map_begin(ktype, vtype, size)
      writeByte(ktype)
      writeByte(vtype)
      writeI32(size)
    end

    def write_list_begin(etype, size)
      writeByte(etype)
      writeI32(size)
    end

    def write_set_begin(etype, size)
      writeByte(etype)
      writeI32(size)
    end

    def write_bool(bool)
      if (bool)
        writeByte(1)
      else
        writeByte(0)
      end
    end

    def write_byte(byte)
      trans.write([byte].pack('n')[1..1])
    end

    def write_i16(i16)
      trans.write([i16].pack('n'))
    end

    def write_i32(i32)
      trans.write([i32].pack('N'))
    end

    def write_i64(i64)
      hi = i64 >> 32
      lo = i64 & 0xffffffff
      trans.write([hi, lo].pack('N2'))
    end

    def write_double(dub)
      trans.write([dub].pack('G'))
    end

    def write_string(str)
      writeI32(str.length)
      trans.write(str)
    end

    def read_message_begin()
      version = readI32()
      if (version & VERSION_MASK != VERSION_1)
        raise ProtocolException.new(ProtocolException::BAD_VERSION, 'Missing version identifier')
      end
      type = version & 0x000000ff
      name = readString()
      seqid = readI32()
      return name, type, seqid
    end

    def read_field_begin()
      type = readByte()
      if (type === Types::STOP)
        return nil, type, 0
      end
      id = readI16()
      return nil, type, id
    end

    def read_map_begin()
      ktype = readByte()
      vtype = readByte()
      size = readI32()
      return ktype, vtype, size
    end

    def read_list_begin()
      etype = readByte()
      size = readI32()
      return etype, size
    end

    def read_set_begin()
      etype = readByte()
      size = readI32()
      return etype, size
    end

    def read_bool()
      byte = readByte()
      return byte != 0
    end

    def read_byte()
      dat = trans.readAll(1)
      val = dat[0]
      if (val > 0x7f)
        val = 0 - ((val - 1) ^ 0xff)
      end
      return val
    end

    def read_i16()
      dat = trans.readAll(2)
      val, = dat.unpack('n')
      if (val > 0x7fff)
        val = 0 - ((val - 1) ^ 0xffff)
      end
      return val
    end

    def read_i32()
      dat = trans.readAll(4)
      val, = dat.unpack('N')
      if (val > 0x7fffffff)
        val = 0 - ((val - 1) ^ 0xffffffff)
      end
      return val
    end

    def read_i64()
      dat = trans.readAll(8)
      hi, lo = dat.unpack('N2')
      if (hi > 0x7fffffff)
        hi = hi ^ 0xffffffff
        lo = lo ^ 0xffffffff
        return 0 - hi*4294967296 - lo - 1
      else
        return hi*4294967296 + lo
      end
    end

    def read_double()
      dat = trans.readAll(8)
      val, = dat.unpack('G')
      return val
    end

    def read_string()
      sz = readI32()
      dat = trans.readAll(sz)
      return dat
    end

  end
  deprecate_class! :TBinaryProtocol => BinaryProtocol
end

class TBinaryProtocolFactory < TProtocolFactory
  def getProtocol(trans)
    return TBinaryProtocol.new(trans)
  end
end

