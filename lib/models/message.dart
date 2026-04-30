class Message {
  Message({
    required this.toId,
    required this.msg,
    required this.read,
    required this.type,
    required this.fromId,
    required this.sent,
    this.reaction = '',
    this.repliedTo = '',
  });
  late String toId;
  late String msg;
  late String read;
  late Type type;
  late String fromId;
  late String sent;
  late String reaction;
  late String repliedTo;

  Message.fromJson(Map<String, dynamic> json) {
    toId = json['toId']?.toString() ?? '';
    msg = json['msg']?.toString() ?? '';
    read = json['read']?.toString() ?? '';
    type = json['type'].toString() == Type.image.name ? Type.image : Type.text;
    fromId = json['fromId']?.toString() ?? '';
    sent = json['sent']?.toString() ?? '';
    reaction = json['reaction']?.toString() ?? '';
    repliedTo = json['repliedTo']?.toString() ?? '';
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['toId'] = toId;
    data['msg'] = msg;
    data['read'] = read;
    data['type'] = type.name;
    data['fromId'] = fromId;
    data['sent'] = sent;
    data['reaction'] = reaction;
    data['repliedTo'] = repliedTo;
    return data;
  }
}

enum Type { text, image }
