class Failure {
  Failure(this.message);

  final String message;
}

class FirebaseFailure extends Failure {
  FirebaseFailure(message, this.code) : super(message);

  final String code;
}
