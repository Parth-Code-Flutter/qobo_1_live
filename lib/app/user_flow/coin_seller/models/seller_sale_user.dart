/// Nested `user` on a seller portal sale row.
class SellerSaleUser {
  const SellerSaleUser({
    required this.id,
    required this.name,
    required this.email,
    this.displayPicture,
  });

  final String id;
  final String name;
  final String email;
  final String? displayPicture;

  factory SellerSaleUser.fromJson(Map<String, dynamic> json) {
    final picture = json['displayPicture'] ??
        json['display_picture'] ??
        json['avatar'] ??
        json['profilePicture'];
    final pictureStr = picture?.toString().trim();
    return SellerSaleUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayPicture: (pictureStr == null ||
              pictureStr.isEmpty ||
              pictureStr == 'null')
          ? null
          : pictureStr,
    );
  }

  factory SellerSaleUser.empty() => const SellerSaleUser(
        id: '',
        name: '',
        email: '',
      );
}
