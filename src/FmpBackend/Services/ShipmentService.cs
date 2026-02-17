using FmpBackend.Dtos;
using FmpBackend.Models;
using FmpBackend.Repositories;

namespace FmpBackend.Services;

public class ShipmentService
{

   public ShipmentService()
{
}


    public async Task<Shipment> CreateShipmentAsync(
    CreateShipmentRequest request,
    Guid userId,
    Guid senderOrgId)
{
    Console.WriteLine("=== Incoming Shipment Request ===");

    Console.WriteLine($"UserId: {userId}");
    Console.WriteLine($"SenderOrgId: {senderOrgId}");
    Console.WriteLine($"ReceiverOrgId: {request.ReceiverOrganizationId}");
    Console.WriteLine($"PickupAddressId: {request.PickupAddressId}");
    Console.WriteLine($"DropAddressId: {request.DropAddressId}");

    Console.WriteLine($"CargoType: {request.CargoType}");
    Console.WriteLine($"CargoDescription: {request.CargoDescription}");
    Console.WriteLine($"CargoWeightKg: {request.CargoWeightKg}");

    Console.WriteLine($"RequiresRefrigeration: {request.RequiresRefrigeration}");
    Console.WriteLine($"RequiresInsurance: {request.RequiresInsurance}");
    Console.WriteLine($"IsUrgent: {request.IsUrgent}");

    Console.WriteLine($"AgreedPrice: {request.AgreedPrice}");
    Console.WriteLine($"LoadingCharges: {request.LoadingCharges}");
    Console.WriteLine($"UnloadingCharges: {request.UnloadingCharges}");
    Console.WriteLine($"OtherCharges: {request.OtherCharges}");

    Console.WriteLine("=================================");

    // Return dummy shipment for now
    return new Shipment
    {
        Id = Guid.NewGuid(),
        ShipmentNumber = "SHP-TEST-000001",
        Status = "debug_mode"
    };
}


}
