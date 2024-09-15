//BYTE FUNCS
import 'dart:developer';

int byteArrayToInt(List<int> byteArray) {
  if (byteArray.length != 2) {
    //throw ArgumentError('Массив должен содержать ровно два байта.');
    log(byteArray.toString());
    return 0;
  }
  return (byteArray[1] << 8) | byteArray[0];
}

// Преобразование int в массив из двух байт
List<int> intToByteArray(int value) {
  if (value < 0 || value > 65535) {
    throw ArgumentError('Значение должно быть в диапазоне от 0 до 65535.');
  }
  return [value & 0xFF, value >> 8];
}
