part of wad;

/**
 * Replacement for ByteData. Adds getString and makes endianness be little endian.
 */
class WadByteData {
  static Endianness ENDIANNESS = Endianness.LITTLE_ENDIAN;
  
  ByteData data;
  int lengthInBytes;
  int offsetInBytes = 0;
  
  WadByteData(this.data) {
    this.lengthInBytes = data.lengthInBytes;
  }

  WadByteData.view(this.data, int offset, [int length = -1]) {
    this.offsetInBytes = offset;
    this.lengthInBytes = length>=0?length:(data.lengthInBytes-offset);
  }
  
  int getInt8(int o) => data.getInt8(offsetInBytes+o);
  int getUint8(int o) => data.getUint8(offsetInBytes+o);
  int getInt16(int o) => data.getInt16(offsetInBytes+o, ENDIANNESS);
  int getUint16(int o) => data.getUint16(offsetInBytes+o, ENDIANNESS);
  int getInt32(int o) => data.getInt32(offsetInBytes+o, ENDIANNESS);
  int getUint32(int o) => data.getUint32(offsetInBytes+o, ENDIANNESS);
  int getInt64(int o) => data.getInt64(offsetInBytes+o, ENDIANNESS);
  int getUint64(int o) => data.getUint64(offsetInBytes+o, ENDIANNESS);
  double getFloat32(int o) => data.getFloat32(offsetInBytes+o, ENDIANNESS);
  double getFloat64(int o) => data.getFloat64(offsetInBytes+o, ENDIANNESS);

  String getString(int o, int length) {
    List<int> stringValues = new List<int>();
    for (int i = 0; i < length; i++) {
      int val = data.getUint8(offsetInBytes + o + i);
      if (val == 0) break; // Null terminated
  
      stringValues.add(val);
    }
    return new String.fromCharCodes(stringValues).toUpperCase();
  }
}