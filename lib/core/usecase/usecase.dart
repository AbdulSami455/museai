// This use case handles one focused action in shared app behavior.

abstract class Usecase<R, Params> {
  Future<R> call({Params? params});
}
