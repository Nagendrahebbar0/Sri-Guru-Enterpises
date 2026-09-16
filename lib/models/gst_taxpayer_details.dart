// ============================================================
// FILE: gst_taxpayer_details.dart
// PURPOSE:
// Stores GST taxpayer information fetched/verified from the
// official GST Search Taxpayer portal.
//
// IMPORTANT:
// The app does not bypass or solve CAPTCHA. The user verifies
// the GSTIN on the official GST portal and can import the
// displayed text into the app.
// ============================================================

class GstTaxpayerDetails {
  final String gstin;
  final String legalName;
  final String tradeName;
  final String address;
  final String state;
  final String pinCode;
  final String status;
  final String registrationDate;
  final String taxpayerType;

  const GstTaxpayerDetails({
    required this.gstin,
    required this.legalName,
    required this.tradeName,
    required this.address,
    required this.state,
    required this.pinCode,
    required this.status,
    required this.registrationDate,
    required this.taxpayerType,
  });

  GstTaxpayerDetails copyWith({
    String? gstin,
    String? legalName,
    String? tradeName,
    String? address,
    String? state,
    String? pinCode,
    String? status,
    String? registrationDate,
    String? taxpayerType,
  }) {
    return GstTaxpayerDetails(
      gstin: gstin ?? this.gstin,
      legalName: legalName ?? this.legalName,
      tradeName: tradeName ?? this.tradeName,
      address: address ?? this.address,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      status: status ?? this.status,
      registrationDate: registrationDate ?? this.registrationDate,
      taxpayerType: taxpayerType ?? this.taxpayerType,
    );
  }
}
