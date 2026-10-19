/// 调用厂商余额接口所需的鉴权材料。
///
/// 仅作为请求期间的临时载体，不落盘；持久化由 data 层的安全存储负责。
class ApiCredentials {
  const ApiCredentials({required this.apiKey});

  final String apiKey;

  @override
  String toString() => 'ApiCredentials(apiKey: ***)';
}
