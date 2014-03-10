require 'base64'
require 'zlib'
module Idol
  class Encryptor
    def self.keys
      @@keys ||= begin
        Encryptor.new(
          1861290038,
          2612094982,
          2875677899,
          4119137992
        ).decrypt(Idol.config.encrypted_keys).split(",").map!(&:to_i)
      end
    end

    def initialize(*keys)
      @keys = keys.empty? ? Encryptor.keys : keys
    end

    def encrypt(string)
      encode_internal(encrypt_internal(deflate_internal(string)))
    end

    def decrypt(string)
      inflate_internal(decrypt_internal(decode_internal(string)))
    end

    private

    def encode_internal(encrypted)
      prefix = "#{encrypted.length}|".unpack("c*")
      to_encode = (prefix + encrypted).pack("c*")
      Base64.encode64(to_encode).gsub("\n", '')
    end

    def decode_internal(string)
      decoded = Base64.decode64(string).unpack('c*')
      index = decoded.index(124)
      raise Idol::DecodeError.new "Incorrect decoded input, no length and separator found." unless index
      
      encrypted_length = decoded.length - index + 1
      decoded[index + 1, encrypted_length]
    end

    def deflate_internal(string)
      deflated = Zlib::Deflate.deflate(string).unpack('c*')
      prefix = "AUTN:".unpack('c*')
      prefix + deflated
    end

    def inflate_internal(bytes)
      prefix = "AUTN:".unpack('c*')
      stripped = bytes[prefix.length, bytes.length - prefix.length]
      Zlib::Inflate.inflate(stripped.pack('c*'))
    end

    def encrypt_internal(bytes)
      buffer = bytes.length % 4 == 0 ? bytes : pad_byte_array(bytes)
     
      qqqqq = 6 + 208 / buffer.length
      
      ppppp = buffer.length - 4
      
      zzzzz = valid_byte(buffer[ppppp + 3]) << 24 | valid_byte(buffer[ppppp + 2]) << 16 | valid_byte(buffer[ppppp + 1]) << 8 | valid_byte(buffer[ppppp])
      
      sum = 0
      delta = 2654435769
      
      while (qqqqq > 0) do
        qqqqq -= 1
        sum += 2654435769
        sum -= 4294967296 if sum >= 4294967296
        
        eeeee = sum >> 2 & 0x3
        
        ppppp = 0
        begin
          temp1 = zzzzz << 4 ^ zzzzz >> 5
          temp1 %= 4294967296 if temp1 >= 4294967296

          temp1 += zzzzz
          temp1 -= 4294967296 if temp1 >= 4294967296

          temp2 = @keys[ppppp >> 2 & 0x3 ^ eeeee] + sum
          temp2 -= 4294967296 if temp2 >= 4294967296

          buffer_entry = valid_byte(buffer[ppppp + 3]) << 24 | valid_byte(buffer[ppppp + 2]) << 16 | valid_byte(buffer[ppppp + 1]) << 8 | valid_byte(buffer[ppppp])
          buffer_entry += (temp1 ^ temp2)
          buffer_entry -= 4294967296 if buffer_entry >= 4294967296

          buffer[ppppp + 3] = to_byte(buffer_entry >> 24)
          buffer[ppppp + 2] = to_byte(buffer_entry >> 16 & 0xFF)
          buffer[ppppp + 1] = to_byte(buffer_entry >> 8 & 0xFF)
          buffer[ppppp] = to_byte(buffer_entry & 0xFF)
          
          zzzzz = buffer_entry

          ppppp += 4
        end while ppppp  < buffer.length
      end
      buffer
    end

    def decrypt_internal(bytes)
      delta = 2654435769
      qqqqq = 6 + 208 / bytes.length
      sum = qqqqq * 2654435769

      raise Idol::DecodeError.new("The input is the wrong length, it's not divisible by four.") if bytes.length % 4 != 0
    
      while sum != 0 do
        eeeee = sum >> 2 & 0x3
 
        ppppp = bytes.length - 4
        begin
          rrrrr = if ppppp > 0
            ppppp - 4
          else
            bytes.length - 4
          end

          zzzzz = valid_byte(bytes[rrrrr + 3]) << 24 | valid_byte(bytes[rrrrr + 2]) << 16 | valid_byte(bytes[rrrrr + 1]) << 8 | valid_byte(bytes[rrrrr])
         
          temp = zzzzz << 4 ^ zzzzz >> 5
          temp %= 4294967296 if temp >= 4294967296

          temp += zzzzz
          temp -= 4294967296 if temp >= 4294967296

          temp2 = @keys[ppppp >> 2 & 0x3 ^ eeeee] + sum
          temp2 -= 4294967296 if temp2 >= 4294967296

          buffer_entry = valid_byte(bytes[ppppp + 3]) << 24 | valid_byte(bytes[ppppp + 2]) << 16 | valid_byte(bytes[ppppp + 1]) << 8 | valid_byte(bytes[ppppp])
          if (temp ^ temp2) > buffer_entry
            buffer_entry += 4294967296 - (temp ^ temp2)
          else
            buffer_entry -= (temp ^ temp2)
          end

          bytes[ppppp + 3] = to_byte(buffer_entry >> 24)
          bytes[ppppp + 2] = to_byte(buffer_entry >> 16 & 0xFF)
          bytes[ppppp + 1] = to_byte(buffer_entry >> 8 & 0xFF)
          bytes[ppppp] = to_byte(buffer_entry & 0xFF)

          ppppp -= 4
        end while ppppp >= 0
         
        if 2654435769 > sum
          sum += 1640531527
        else
          sum -= 2654435769
        end
      end
     
      bytes
    end

    def pad_byte_array(bytes)
      length = 4 - bytes.length % 4
      bytes.fill(0, bytes.length, length)
    end

    def valid_byte(byte)
      byte < 0 ? byte + 256 : byte
    end

    def to_byte(int)
      [int].pack("N").unpack('cccc').last
    end
  end
end