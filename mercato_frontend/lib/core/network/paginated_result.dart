class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int totalPages;

  const PaginatedResult({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory PaginatedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final List rawItems = json['data'] ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>?;
    return PaginatedResult(
      items: rawItems.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      page: pagination?['page'] ?? 1,
      totalPages: pagination?['totalPages'] ?? 1,
    );
  }
}
