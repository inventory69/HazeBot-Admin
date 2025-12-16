/// Result returned from post editor (create/edit)
class PostEditorResult {
  final bool success;
  final String? message;
  final String? error;

  const PostEditorResult({
    required this.success,
    this.message,
    this.error,
  });

  /// Create success result
  factory PostEditorResult.success({String? message}) {
    return PostEditorResult(
      success: true,
      message: message,
    );
  }

  /// Create error result
  factory PostEditorResult.error({required String error}) {
    return PostEditorResult(
      success: false,
      error: error,
    );
  }
}
