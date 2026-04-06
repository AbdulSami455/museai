abstract class Usecase<R, Params> {
  Future<R> call({Params? params});
}