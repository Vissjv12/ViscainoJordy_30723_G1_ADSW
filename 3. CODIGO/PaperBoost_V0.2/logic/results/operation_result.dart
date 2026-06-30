class OperationResult<T> {
  const OperationResult._({
    required this.isSuccess,
    required this.message,
    this.data,
  });

  final bool isSuccess;
  final String message;
  final T? data;

  factory OperationResult.success({
    required String message,
    T? data,
  }) {
    return OperationResult<T>._(
      isSuccess: true,
      message: message,
      data: data,
    );
  }

  factory OperationResult.failure({
    required String message,
  }) {
    return OperationResult<T>._(
      isSuccess: false,
      message: message,
    );
  }
}