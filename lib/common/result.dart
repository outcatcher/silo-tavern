/// A generic result type that represents either success or failure of an operation
sealed class Result<T> {
  const Result();

  /// Creates a successful result with a value
  factory Result.success(T value) = Success<T>;

  /// Creates a failed result with an error message
  factory Result.failure(String error) = Failure<T>;

  /// Whether the result represents a successful operation
  bool get isSuccess => this is Success<T>;

  /// Whether the result represents a failed operation
  bool get isFailure => this is Failure<T>;

  /// Gets the value if successful, or null if failed
  T? get value => this is Success<T> ? (this as Success<T>).value : null;

  /// Gets the error message if failed, or null if successful
  String? get error => this is Failure<T> ? (this as Failure<T>).error : null;
}

/// Represents a successful operation result
class Success<T> extends Result<T> {
  @override
  final T value;

  const Success(this.value);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}

/// Represents a failed operation result
class Failure<T> extends Result<T> {
  @override
  final String error;

  const Failure(this.error);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure<T> && error == other.error;
  }

  @override
  int get hashCode => error.hashCode;
}

/// Extension methods for Result<T> to enable functional programming patterns
extension ResultExtensions<T> on Result<T> {
  /// Maps a Result<T> to Result<U> by applying a function to the value
  Result<U> map<U>(U Function(T) transform) {
    if (this is Success<T>) {
      return Result.success(transform((this as Success<T>).value));
    } else {
      return Result.failure((this as Failure<T>).error);
    }
  }

  /// Chains Result operations together
  Result<U> flatMap<U>(Result<U> Function(T) transform) {
    if (this is Success<T>) {
      return transform((this as Success<T>).value);
    } else {
      return Result.failure((this as Failure<T>).error);
    }
  }

  /// Provides a default value in case of failure
  T orElse(T defaultValue) {
    if (this is Success<T>) {
      return (this as Success<T>).value;
    } else {
      return defaultValue;
    }
  }

  /// Performs a side effect if successful
  Result<T> onSuccess(void Function(T) action) {
    if (this is Success<T>) {
      action((this as Success<T>).value);
    }
    return this;
  }

  /// Performs a side effect if failed
  Result<T> onFailure(void Function(String) action) {
    if (this is Failure<T>) {
      action((this as Failure<T>).error);
    }
    return this;
  }
}
