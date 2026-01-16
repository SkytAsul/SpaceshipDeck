import 'package:commons/commons.dart';
import 'package:protobuf/protobuf.dart' as pb;
import 'package:fixnum/fixnum.dart';

extension ProtobufEnumList<T extends pb.ProtobufEnum> on List<T> {
  T findItem(String commonPrefix, String itemName) {
    return singleWhere(
      (pbItem) => pbItem.name.substring(commonPrefix.length) == itemName,
    );
  }
}

extension ProtobufTimestamp on DateTime {
  Timestamp toProtobuf() {
    int us = microsecondsSinceEpoch;
    int s = (us / 1_000_000).toInt();
    int ns = millisecond * 1_000_000 + microsecond * 1_000;
    return Timestamp(seconds: Int64(s), nanos: ns);
  }
}
