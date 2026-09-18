/// Union sederhana untuk merepresentasikan 4 kondisi UI:
/// initial -> loading -> (data | empty | error)
///
/// Kita BELUM pakai `freezed` di sini secara sengaja. Stage 1 fokus ke
/// routing & UI, dan kita ingin `flutter run` langsung jalan TANPA perlu
/// `build_runner` dulu. Freezed baru masuk di Stage 2 saat model data
/// (Campaign, UserProgress-style) butuh serialization JSON/Map.
sealed class ViewState<T> {
  const ViewState();
}

class ViewInitial<T> extends ViewState<T> {
  const ViewInitial();
}

class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();
}

class ViewLoaded<T> extends ViewState<T> {
  final T data;
  const ViewLoaded(this.data);
}

/// Loaded tapi datanya kosong (mis. campaign list kosong dari smart contract).
class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty();
}

class ViewError<T> extends ViewState<T> {
  final String message;
  const ViewError(this.message);
}
