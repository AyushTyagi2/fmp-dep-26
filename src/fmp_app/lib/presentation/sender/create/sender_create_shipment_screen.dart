import 'package:flutter/material.dart';
import 'widgets/cargo.dart';
import 'widgets/date.dart';
import 'widgets/insurance.dart';
import 'widgets/pricing.dart';
import '../models/shipment_draft.dart';
import '../../../data/datasources/shipment_remote_datasource.dart';
import '../../../data/repositories/shipment_repository.dart';
import '../../../data/models/shipment/create_shipment_request.dart';
import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';




class SenderCreateShipmentScreen extends StatefulWidget {
  const SenderCreateShipmentScreen({super.key});

  @override
  State<SenderCreateShipmentScreen> createState() =>
      _SenderCreateShipmentScreenState();
}

class _SenderCreateShipmentScreenState
    extends State<SenderCreateShipmentScreen> {

  final ShipmentDraft draft = ShipmentDraft();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  void _submit() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    isLoading = true;
  });

  try {
    // 🔹 Convert Draft → Request
    // 🔥 TEMP TESTING VALUES
    draft.receiverOrganizationId =
        "50d2194e-a86b-4aba-919a-e01fba1c0c39";

    // Replace these with REAL address GUIDs from your DB
    draft.pickupAddressId =
        "8b4f5a1e-8f90-4c31-9c76-123456789abc";

    draft.dropAddressId =
        "8b4f5a1e-8f90-4c31-9c76-123456789abb";

    final request = draft.toRequest();
    print("REQUEST BODY: ${request.toJson()}");  // 👈 ADD THIS
    // 🔹 Setup API
    final apiClient = ApiClient();

    // If you have JWT stored somewhere, set it here:
    // apiClient.setAuthToken(AppSession.token);

    final remote =
        ShipmentRemoteDataSource(apiClient.dio);

    final repository =
        ShipmentRepository(remote);



    await repository.createShipment(request);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Shipment created successfully"),
      ),
    );

  } catch (e) {
    print("Error submitting shipment: $e");
  if (e is DioException) {
    print("STATUS: ${e.response?.statusCode}");
    print("DATA: ${e.response?.data}");
  } else {
    print("Error: $e");
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Failed to create shipment"),
      ),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Shipment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CargoDetailsSection(draft: draft),
              const SizedBox(height: 24),

              PickupDeliverySection(draft: draft),
              const SizedBox(height: 24),

              HandlingComplianceSection(draft: draft),
              const SizedBox(height: 24),

              PricingSection(draft: draft),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit Shipment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
